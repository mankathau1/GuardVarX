package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/users"
)

type UsersHandler struct {
	repo users.Repository
}

func NewUsersHandler(repo users.Repository) *UsersHandler {
	return &UsersHandler{repo: repo}
}

func (h *UsersHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	user, err := h.repo.GetByID(r.Context(), userID)
	if err != nil {
		// If user doesn't exist yet, auto-provision profile from UID
		user = &users.User{
			ID:          userID,
			FirebaseUID: userID,
			DisplayName: "GuardVarX User",
			Role:        middleware.GetUserRole(r.Context()),
		}
		_ = h.repo.Create(r.Context(), user)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(user)
}

func (h *UsersHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var req struct {
		DisplayName string `json:"display_name"`
		Phone       string `json:"phone"`
		Email       string `json:"email"`
		AvatarURL   string `json:"avatar_url"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, r, http.StatusBadRequest, "INVALID_BODY", "Invalid JSON payload")
		return
	}

	user, err := h.repo.GetByID(r.Context(), userID)
	if err != nil {
		user = &users.User{
			ID:          userID,
			FirebaseUID: userID,
			Role:        "STANDARD_USER",
		}
		_ = h.repo.Create(r.Context(), user)
	}

	if req.DisplayName != "" {
		user.DisplayName = req.DisplayName
	}
	if req.Phone != "" {
		user.Phone = req.Phone
	}
	if req.Email != "" {
		user.Email = req.Email
	}
	if req.AvatarURL != "" {
		user.AvatarURL = req.AvatarURL
	}

	if err := h.repo.Update(r.Context(), user); err != nil {
		writeError(w, r, http.StatusInternalServerError, "UPDATE_FAILED", "Failed to update user profile")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(user)
}

func (h *UsersHandler) DeleteMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	if err := h.repo.Delete(r.Context(), userID); err != nil {
		writeError(w, r, http.StatusInternalServerError, "DELETE_FAILED", "Failed to delete account")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *UsersHandler) RegisterDevice(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var req struct {
		DeviceID  string `json:"device_id"`
		FCMToken  string `json:"fcm_token"`
		Platform  string `json:"platform"`
		Model     string `json:"model"`
		OSVersion string `json:"os_version"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.DeviceID == "" || req.FCMToken == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_REQUEST", "device_id and fcm_token are required")
		return
	}

	dev := &users.Device{
		UserID:    userID,
		DeviceID:  req.DeviceID,
		FCMToken:  req.FCMToken,
		Platform:  req.Platform,
		Model:     req.Model,
		OSVersion: req.OSVersion,
	}

	if err := h.repo.RegisterDevice(r.Context(), dev); err != nil {
		writeError(w, r, http.StatusInternalServerError, "DEVICE_REG_FAILED", "Could not register device")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"status":    "registered",
		"device_id": req.DeviceID,
	})
}

func writeError(w http.ResponseWriter, r *http.Request, status int, code, msg string) {
	w.Header().Set("Content-Type", "application/problem+json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]any{
			"code":       code,
			"message":    msg,
			"request_id": middleware.GetRequestID(r.Context()),
		},
	})
}
