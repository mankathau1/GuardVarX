package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/safe_walk"
	"github.com/guardvarx/backend/internal/websocket"
)

type SafeWalkHandler struct {
	repo  safe_walk.Repository
	wsHub *websocket.Hub
}

func NewSafeWalkHandler(repo safe_walk.Repository, wsHub *websocket.Hub) *SafeWalkHandler {
	return &SafeWalkHandler{repo: repo, wsHub: wsHub}
}

func (h *SafeWalkHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var s safe_walk.Session
	if err := json.NewDecoder(r.Body).Decode(&s); err != nil || s.DestinationName == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_REQUEST", "destination_name is required")
		return
	}

	s.UserID = userID
	if s.ExpectedDurationMinutes <= 0 {
		s.ExpectedDurationMinutes = 30
	}
	if s.CheckinIntervalMinutes <= 0 {
		s.CheckinIntervalMinutes = 10
	}

	if err := h.repo.Create(r.Context(), &s); err != nil {
		writeError(w, r, http.StatusInternalServerError, "CREATION_FAILED", "Failed to start Safe Walk")
		return
	}

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("user:"+userID, "safe_walk_started", s)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(s)
}

func (h *SafeWalkHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	s, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "NOT_FOUND", "Safe Walk session not found")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(s)
}

func (h *SafeWalkHandler) GetActive(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	s, err := h.repo.GetActiveByUserID(r.Context(), userID)
	if err != nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{"active": false})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{"active": true, "session": s})
}

func (h *SafeWalkHandler) Checkin(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	id := chi.URLParam(r, "id")

	var req struct {
		Latitude  float64 `json:"latitude"`
		Longitude float64 `json:"longitude"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)

	s, err := h.repo.Checkin(r.Context(), id, userID, req.Latitude, req.Longitude)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "CHECKIN_FAILED", err.Error())
		return
	}

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("user:"+userID, "safe_walk_checkin", s)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(s)
}

func (h *SafeWalkHandler) Complete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	id := chi.URLParam(r, "id")

	s, err := h.repo.Complete(r.Context(), id, userID)
	if err != nil {
		writeError(w, r, http.StatusBadRequest, "COMPLETE_FAILED", err.Error())
		return
	}

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("user:"+userID, "safe_walk_completed", s)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(s)
}
