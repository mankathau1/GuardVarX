package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/guardvarx/backend/internal/storage"
)

type HealthHandler struct {
	db *storage.Database
}

func NewHealthHandler(db *storage.Database) *HealthHandler {
	return &HealthHandler{db: db}
}

func (h *HealthHandler) Health(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":    "healthy",
		"version":   "1.0.0",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	})
}

func (h *HealthHandler) Ready(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	isDbReady := h.db != nil && h.db.IsReady(r.Context())
	if !isDbReady && h.db != nil && h.db.Pool != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		_ = json.NewEncoder(w).Encode(map[string]any{
			"status":   "unready",
			"database": "disconnected",
		})
		return
	}

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":     "ready",
		"database":   "connected",
		"migrations": "up_to_date",
		"timestamp":  time.Now().UTC().Format(time.RFC3339),
	})
}
