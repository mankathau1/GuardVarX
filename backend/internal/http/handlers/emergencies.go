package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/guardvarx/backend/internal/audit"
	"github.com/guardvarx/backend/internal/contacts"
	"github.com/guardvarx/backend/internal/emergencies"
	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/notifications"
	"github.com/guardvarx/backend/internal/users"
	"github.com/guardvarx/backend/internal/websocket"
)

type EmergenciesHandler struct {
	repo         emergencies.Repository
	contactsRepo contacts.Repository
	usersRepo    users.Repository
	fcm          notifications.Dispatcher
	wsHub        *websocket.Hub
	auditor      audit.Logger
}

func NewEmergenciesHandler(
	repo emergencies.Repository,
	contactsRepo contacts.Repository,
	usersRepo users.Repository,
	fcm notifications.Dispatcher,
	wsHub *websocket.Hub,
	auditor audit.Logger,
) *EmergenciesHandler {
	return &EmergenciesHandler{
		repo:         repo,
		contactsRepo: contactsRepo,
		usersRepo:    usersRepo,
		fcm:          fcm,
		wsHub:        wsHub,
		auditor:      auditor,
	}
}

func (h *EmergenciesHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	idempotencyKey := r.Header.Get("Idempotency-Key")

	var inc emergencies.Incident
	if err := json.NewDecoder(r.Body).Decode(&inc); err != nil {
		writeError(w, r, http.StatusBadRequest, "INVALID_BODY", "Invalid JSON payload")
		return
	}

	if inc.EmergencyType == "" || inc.Latitude == 0 || inc.Longitude == 0 {
		writeError(w, r, http.StatusBadRequest, "MISSING_FIELDS", "emergency_type, latitude and longitude are required")
		return
	}

	if inc.LocationTimestamp.IsZero() {
		inc.LocationTimestamp = time.Now().UTC()
	}
	inc.SenderID = userID
	if idempotencyKey != "" {
		inc.IdempotencyKey = idempotencyKey
	}

	if err := h.repo.Create(r.Context(), &inc); err != nil {
		writeError(w, r, http.StatusInternalServerError, "CREATION_FAILED", "Failed to record emergency incident")
		return
	}

	// Fetch trusted contacts to notify
	notifiedCount := 0
	if h.contactsRepo != nil {
		trustedList, _ := h.contactsRepo.ListByUserID(r.Context(), userID)
		var tokens []string
		for _, tc := range trustedList {
			if tc.CanReceiveSOS && h.usersRepo != nil {
				// Query devices if available
				devices, _ := h.usersRepo.GetDevicesByUserID(r.Context(), tc.UserID)
				for _, d := range devices {
					if d.FCMToken != "" {
						tokens = append(tokens, d.FCMToken)
					}
				}
			}
		}

		if len(tokens) > 0 && h.fcm != nil {
			_ = h.repo.UpdateStatus(r.Context(), inc.IncidentID, emergencies.StateContactNotificationRequested, "system", nil)
			count, _ := h.fcm.SendEmergencyAlert(r.Context(), tokens, inc.IncidentID, "GuardVarX User", inc.EmergencyType, inc.Latitude, inc.Longitude)
			notifiedCount = count
		}
	}

	// Broadcast via WebSocket
	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("incident:"+inc.IncidentID, "incident_created", inc)
	}

	if h.auditor != nil {
		h.auditor.Log(r.Context(), userID, "EMERGENCY_CREATED", "emergency_incidents", inc.IncidentID, r.RemoteAddr, r.UserAgent())
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"incident_id":            inc.IncidentID,
		"status":                 inc.Status,
		"server_timestamp":       inc.CreatedAt,
		"receipt_id":             inc.ReceiptID,
		"contacts_notified_count": notifiedCount,
	})
}

func (h *EmergenciesHandler) Get(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	inc, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		writeError(w, r, http.StatusNotFound, "NOT_FOUND", "Emergency incident not found")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(inc)
}

func (h *EmergenciesHandler) Cancel(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	id := chi.URLParam(r, "id")

	var req struct {
		Reason string `json:"reason"`
		PIN    string `json:"pin"`
	}
	_ = json.NewDecoder(r.Body).Decode(&req)

	if err := h.repo.Cancel(r.Context(), id, userID, req.Reason); err != nil {
		writeError(w, r, http.StatusBadRequest, "CANCEL_FAILED", err.Error())
		return
	}

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("incident:"+id, "incident_cancelled", map[string]string{
			"incident_id": id,
			"status":      emergencies.StateCancelled,
			"reason":      req.Reason,
		})
	}

	if h.auditor != nil {
		h.auditor.Log(r.Context(), userID, "EMERGENCY_CANCELLED", "emergency_incidents", id, r.RemoteAddr, r.UserAgent())
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"incident_id": id,
		"status":      emergencies.StateCancelled,
		"cancelled_at": time.Now().UTC(),
	})
}

func (h *EmergenciesHandler) Resolve(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	id := chi.URLParam(r, "id")

	if err := h.repo.Resolve(r.Context(), id, userID); err != nil {
		writeError(w, r, http.StatusBadRequest, "RESOLVE_FAILED", err.Error())
		return
	}

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("incident:"+id, "incident_resolved", map[string]string{
			"incident_id": id,
			"status":      emergencies.StateResolved,
		})
	}

	if h.auditor != nil {
		h.auditor.Log(r.Context(), userID, "EMERGENCY_RESOLVED", "emergency_incidents", id, r.RemoteAddr, r.UserAgent())
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"incident_id": id,
		"status":      emergencies.StateResolved,
		"resolved_at": time.Now().UTC(),
	})
}

func (h *EmergenciesHandler) Acknowledge(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	var ack emergencies.DeliveryAck
	_ = json.NewDecoder(r.Body).Decode(&ack)

	ack.IncidentID = id
	if ack.DeliveryChannel == "" {
		ack.DeliveryChannel = "MANUAL_APP"
	}

	if err := h.repo.AddAcknowledgement(r.Context(), &ack); err != nil {
		writeError(w, r, http.StatusInternalServerError, "ACK_FAILED", "Failed to record acknowledgement")
		return
	}

	_ = h.repo.UpdateStatus(r.Context(), id, emergencies.StateContactAcknowledged, ack.ContactID, nil)

	if h.wsHub != nil {
		h.wsHub.BroadcastToTopic("incident:"+id, "contact_acknowledged", ack)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(ack)
}

func (h *EmergenciesHandler) ListAcks(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	acks, err := h.repo.ListAcks(r.Context(), id)
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "LIST_FAILED", "Could not fetch acknowledgements")
		return
	}
	if acks == nil {
		acks = []emergencies.DeliveryAck{}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(acks)
}
