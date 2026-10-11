package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/responders"
	"github.com/guardvarx/backend/internal/websocket"
)

type RespondersHandler struct {
	repo  responders.Repository
	wsHub *websocket.Hub
}

func NewRespondersHandler(repo responders.Repository, wsHub *websocket.Hub) *RespondersHandler {
	return &RespondersHandler{repo: repo, wsHub: wsHub}
}

func (h *RespondersHandler) UpdateAvailability(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var req responders.ResponderProfile
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "INVALID_BODY", "Invalid JSON payload")
		return
	}

	req.UserID = userID
	if err := h.repo.UpdateAvailability(r.Context(), &req); err != nil {
		writeError(w, r, http.StatusInternalServerError, "UPDATE_FAILED", "Failed to update responder availability")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(req)
}

func (h *RespondersHandler) AcceptMission(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var req struct {
		IncidentID string `json:"incident_id"`
		ETAMinutes int    `json:"eta_minutes"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.IncidentID == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_REQUEST", "incident_id is required")
		return
	}

	ms := &responders.Mission{
		IncidentID:  req.IncidentID,
		ResponderID: userID,
		Status:      responders.MissionStatusAccepted,
		ETAMinutes:  req.ETAMinutes,
	}

	if err := h.repo.CreateMission(r.Context(), ms); err != nil {
		writeError(w, r, http.StatusInternalServerError, "MISSION_FAILED", "Failed to accept mission")
		return
	}

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("incident:"+req.IncidentID, "helper_accepted", ms)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(ms)
}

func (h *RespondersHandler) UpdateMissionStatus(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	id := chi.URLParam(r, "id")

	var req struct {
		Status string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Status == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_REQUEST", "status is required")
		return
	}

	if err := h.repo.UpdateMissionStatus(r.Context(), id, userID, req.Status); err != nil {
		writeError(w, r, http.StatusBadRequest, "STATUS_UPDATE_FAILED", err.Error())
		return
	}

	ms, _ := h.repo.GetMissionByID(r.Context(), id)
	if h.wsHub != nil && ms != nil {
		h.wsHub.BroadcastToTopic("incident:"+ms.IncidentID, "mission_status_updated", ms)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"mission_id": id,
		"status":     req.Status,
	})
}
