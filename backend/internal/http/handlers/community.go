package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/guardvarx/backend/internal/community"
	"github.com/guardvarx/backend/internal/http/middleware"
)

type CommunityHandler struct {
	repo community.Repository
}

func NewCommunityHandler(repo community.Repository) *CommunityHandler {
	return &CommunityHandler{repo: repo}
}

func (h *CommunityHandler) List(w http.ResponseWriter, r *http.Request) {
	lat, _ := strconv.ParseFloat(r.URL.Query().Get("lat"), 64)
	lng, _ := strconv.ParseFloat(r.URL.Query().Get("lng"), 64)
	radius, _ := strconv.ParseFloat(r.URL.Query().Get("radius_km"), 64)
	if radius <= 0 {
		radius = 10.0
	}

	reports, err := h.repo.List(r.Context(), lat, lng, radius)
	if err != nil {
		writeError(w, r, http.StatusInternalServerError, "LIST_FAILED", "Failed to retrieve community reports")
		return
	}
	if reports == nil {
		reports = []community.Report{}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(reports)
}

func (h *CommunityHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.GetUserID(r.Context())
	var rep community.Report
	if err := json.NewDecoder(r.Body).Decode(&rep); err != nil || rep.Title == "" || rep.Category == "" {
		writeError(w, r, http.StatusBadRequest, "INVALID_REQUEST", "title and category are required")
		return
	}

	rep.AuthorID = userID
	if err := h.repo.Create(r.Context(), &rep); err != nil {
		writeError(w, r, http.StatusInternalServerError, "CREATION_FAILED", "Failed to create community report")
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(rep)
}

func (h *CommunityHandler) Upvote(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.repo.Upvote(r.Context(), id); err != nil {
		writeError(w, r, http.StatusNotFound, "NOT_FOUND", "Report not found")
		return
	}
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]string{"status": "upvoted"})
}

func (h *CommunityHandler) Flag(w http.ResponseWriter, r *http.Request) {
	id := chi.URLParam(r, "id")
	if err := h.repo.Flag(r.Context(), id); err != nil {
		writeError(w, r, http.StatusNotFound, "NOT_FOUND", "Report not found")
		return
	}
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]string{"status": "flagged_for_review"})
}
