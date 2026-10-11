package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/guardvarx/backend/internal/contacts"
	"github.com/guardvarx/backend/internal/http/middleware"
)

type ContactsHandler struct {
	repo contacts.Repository
}

func NewContactsHandler(repo contacts.Repository) *ContactsHandler {
	return &ContactsHandler{repo: repo}
}

func (h *ContactsHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	list, err := h.repo.ListByUserID(r.Context(), userID)
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "LIST_FAILED", "Failed to retrieve trusted contacts")
		return
	}
	if list == nil {
		list = []contacts.TrustedContact{}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(list)
}

func (h *ContactsHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var c contacts.TrustedContact
	if err := json.NewDecoder(r.Body).Decode(&c); err != nil || c.Name == "" || c.Phone == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_REQUEST", "Name and phone are required")
		return
	}

	c.UserID = userID
	if err := h.repo.Create(r.Context(), &c); err != nil {
		writeError(w, r, http.StatusInternalServerError, "CREATE_FAILED", "Could not create contact")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(c)
}

func (h *ContactsHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	id := chi.URLParam(r, "id")
	if id == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_ID", "Contact ID is required")
		return
	}

	if err := h.repo.Delete(r.Context(), id, userID); err != nil {
		writeError(w, r, http.StatusNotFound, "NOT_FOUND", "Contact not found or unauthorized")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
