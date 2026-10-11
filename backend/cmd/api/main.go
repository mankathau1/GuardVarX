package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/guardvarx/backend/internal/audit"
	"github.com/guardvarx/backend/internal/community"
	"github.com/guardvarx/backend/internal/config"
	"github.com/guardvarx/backend/internal/contacts"
	"github.com/guardvarx/backend/internal/emergencies"
	"github.com/guardvarx/backend/internal/http/handlers"
	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/notifications"
	"github.com/guardvarx/backend/internal/responders"
	"github.com/guardvarx/backend/internal/safe_walk"
	"github.com/guardvarx/backend/internal/storage"
	"github.com/guardvarx/backend/internal/users"
	"github.com/guardvarx/backend/internal/websocket"
)

func main() {
	// Configure structured slog JSON logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
	slog.SetDefault(logger)

	slog.Info("Starting GuardVarX Emergency Backend API...")

	cfg, err := config.Load()
	if err != nil {
		slog.Error("Failed to load configuration", "error", err)
		os.Exit(1)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Connect to PostgreSQL (gracefully degrades to memory repositories if offline)
	db, err := storage.NewDatabase(ctx, cfg)
	if err != nil {
		slog.Warn("Database initialization warning", "error", err)
	}
	defer db.Close()

	// Repositories initialization
	var usersRepo users.Repository
	var contactsRepo contacts.Repository
	var emergenciesRepo emergencies.Repository
	var safeWalkRepo safe_walk.Repository
	var respondersRepo responders.Repository
	var communityRepo community.Repository

	if db.Pool != nil {
		slog.Info("Using PostgreSQL repositories")
		usersRepo = users.NewPostgresRepository(db)
		contactsRepo = contacts.NewPostgresRepository(db)
		emergenciesRepo = emergencies.NewPostgresRepository(db)
		safeWalkRepo = safe_walk.NewPostgresRepository(db)
		respondersRepo = responders.NewPostgresRepository(db)
		communityRepo = community.NewPostgresRepository(db)
	} else {
		slog.Info("Using In-Memory repositories (Local Development / Testing)")
		usersRepo = users.NewMemoryRepository()
		contactsRepo = contacts.NewMemoryRepository()
		emergenciesRepo = emergencies.NewMemoryRepository()
		safeWalkRepo = safe_walk.NewMemoryRepository()
		respondersRepo = responders.NewMemoryRepository()
		communityRepo = community.NewMemoryRepository()
	}

	// Real-time WebSocket Hub
	wsHub := websocket.NewHub()
	go wsHub.Run()

	// Push notifications dispatcher
	fcmDispatcher := notifications.NewFCMDispatcher(cfg.FirebaseProjectID, true)

	// Audit logger
	auditor := audit.NewService(db)

	// Rate limiter
	rateLimiter := middleware.NewIPRateLimiter(cfg.RateLimitRPS, cfg.RateLimitBurst)

	// Auth middleware
	authMiddleware := middleware.NewAuthMiddleware(
		&middleware.DefaultJwtValidator{SecretKey: []byte("guardvarx-secret-key-development")},
		cfg.AllowMockAuth,
	)

	// HTTP Handlers
	healthHandler := handlers.NewHealthHandler(db)
	usersHandler := handlers.NewUsersHandler(usersRepo)
	contactsHandler := handlers.NewContactsHandler(contactsRepo)
	emergenciesHandler := handlers.NewEmergenciesHandler(emergenciesRepo, contactsRepo, usersRepo, fcmDispatcher, wsHub, auditor)
	safeWalkHandler := handlers.NewSafeWalkHandler(safeWalkRepo, wsHub)
	respondersHandler := handlers.NewRespondersHandler(respondersRepo, wsHub)
	communityHandler := handlers.NewCommunityHandler(communityRepo)
	wsHandler := handlers.NewWSHandler(wsHub)

	// Setup Router
	r := chi.NewRouter()

	// Global Middlewares
	r.Use(middleware.RequestID)
	r.Use(chimw.RealIP)
	r.Use(middleware.StructuredLogger)
	r.Use(chimw.Recoverer)
	r.Use(middleware.NewCORS(cfg.AllowedOrigins))
	r.Use(rateLimiter.Middleware)

	// Health and readiness probes
	r.Get("/health", healthHandler.Health)
	r.Get("/ready", healthHandler.Ready)

	// Version 1 API
	r.Route("/api/v1", func(api chi.Router) {
		// WebSocket connection
		api.Get("/ws", wsHandler.ServeWS)

		// Authenticated Routes
		api.Group(func(auth chi.Router) {
			auth.Use(authMiddleware.RequireAuth)

			// User profiles & devices
			auth.Get("/me", usersHandler.GetMe)
			auth.Put("/me", usersHandler.UpdateMe)
			auth.Delete("/me", usersHandler.DeleteMe)
			auth.Post("/devices", usersHandler.RegisterDevice)

			// Trusted contacts
			auth.Get("/trusted-contacts", contactsHandler.List)
			auth.Post("/trusted-contacts", contactsHandler.Create)
			auth.Delete("/trusted-contacts/{id}", contactsHandler.Delete)

			// Emergencies SOS
			auth.Post("/emergencies", emergenciesHandler.Create)
			auth.Get("/emergencies/{id}", emergenciesHandler.Get)
			auth.Post("/emergencies/{id}/cancel", emergenciesHandler.Cancel)
			auth.Post("/emergencies/{id}/resolve", emergenciesHandler.Resolve)
			auth.Post("/emergencies/{id}/acknowledgements", emergenciesHandler.Acknowledge)
			auth.Get("/emergencies/{id}/acknowledgements", emergenciesHandler.ListAcks)

			// Safe Walk
			auth.Post("/safe-walks", safeWalkHandler.Create)
			auth.Get("/safe-walks/active", safeWalkHandler.GetActive)
			auth.Get("/safe-walks/{id}", safeWalkHandler.Get)
			auth.Post("/safe-walks/{id}/checkin", safeWalkHandler.Checkin)
			auth.Post("/safe-walks/{id}/complete", safeWalkHandler.Complete)

			// Helpers & Missions
			auth.Put("/responders/availability", respondersHandler.UpdateAvailability)
			auth.Post("/missions", respondersHandler.AcceptMission)
			auth.Put("/missions/{id}/status", respondersHandler.UpdateMissionStatus)

			// Community Reports
			auth.Get("/community/reports", communityHandler.List)
			auth.Post("/community/reports", communityHandler.Create)
			auth.Post("/community/reports/{id}/upvote", communityHandler.Upvote)
			auth.Post("/community/reports/{id}/flag", communityHandler.Flag)
		})
	})

	server := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      r,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		slog.Info(fmt.Sprintf("GuardVarX API server listening on :%s", cfg.Port))
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("Server failed to listen and serve", "error", err)
			os.Exit(1)
		}
	}()

	// Graceful shutdown handling
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	slog.Info("Shutting down server gracefully...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		slog.Error("Server forced to shutdown", "error", err)
	}

	slog.Info("GuardVarX API server stopped cleanly.")
}
