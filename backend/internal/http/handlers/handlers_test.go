package handlers

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/guardvarx/backend/internal/audit"
	"github.com/guardvarx/backend/internal/community"
	"github.com/guardvarx/backend/internal/contacts"
	"github.com/guardvarx/backend/internal/emergencies"
	"github.com/guardvarx/backend/internal/http/middleware"
	"github.com/guardvarx/backend/internal/notifications"
	"github.com/guardvarx/backend/internal/safe_walk"
	"github.com/guardvarx/backend/internal/users"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func setupTestRouter() http.Handler {
	usersRepo := users.NewMemoryRepository()
	contactsRepo := contacts.NewMemoryRepository()
	emergenciesRepo := emergencies.NewMemoryRepository()
	safeWalkRepo := safe_walk.NewMemoryRepository()
	communityRepo := community.NewMemoryRepository()
	mockFCM := &notifications.MockDispatcher{}
	auditor := audit.NewService(nil)

	authMiddleware := middleware.NewAuthMiddleware(nil, true)

	healthHandler := NewHealthHandler(nil)
	usersHandler := NewUsersHandler(usersRepo)
	contactsHandler := NewContactsHandler(contactsRepo)
	emergenciesHandler := NewEmergenciesHandler(emergenciesRepo, contactsRepo, usersRepo, mockFCM, nil, auditor)
	safeWalkHandler := NewSafeWalkHandler(safeWalkRepo, nil)
	communityHandler := NewCommunityHandler(communityRepo)

	r := chi.NewRouter()
	r.Use(middleware.RequestID)

	r.Get("/health", healthHandler.Health)
	r.Get("/ready", healthHandler.Ready)

	r.Route("/api/v1", func(api chi.Router) {
		api.Use(authMiddleware.RequireAuth)

		api.Get("/me", usersHandler.GetMe)
		api.Get("/trusted-contacts", contactsHandler.List)
		api.Post("/trusted-contacts", contactsHandler.Create)
		api.Post("/emergencies", emergenciesHandler.Create)
		api.Get("/emergencies/{id}", emergenciesHandler.Get)
		api.Post("/emergencies/{id}/cancel", emergenciesHandler.Cancel)
		api.Post("/safe-walks", safeWalkHandler.Create)
		api.Post("/community/reports", communityHandler.Create)
		api.Get("/community/reports", communityHandler.List)
	})

	return r
}

func TestHealthEndpoint(t *testing.T) {
	router := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	var resp map[string]any
	err := json.Unmarshal(rec.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.Equal(t, "healthy", resp["status"])
}

func TestAuthMiddleware_Rejection(t *testing.T) {
	router := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusUnauthorized, rec.Code)
}

func TestAuthMiddleware_MockToken(t *testing.T) {
	router := setupTestRouter()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/me", nil)
	req.Header.Set("Authorization", "Bearer mock_user123_STANDARD_USER")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusOK, rec.Code)
	var resp users.User
	err := json.Unmarshal(rec.Body.Bytes(), &resp)
	require.NoError(t, err)
	assert.Equal(t, "user123", resp.ID)
}

func TestEmergencies_CreateAndFetch(t *testing.T) {
	router := setupTestRouter()

	payload := map[string]any{
		"emergency_type":     "PERSONAL_THREAT",
		"message":            "Suspicious person following me",
		"latitude":           28.7041,
		"longitude":          77.1025,
		"accuracy_meters":    5.0,
		"location_timestamp": time.Now().UTC().Format(time.RFC3339),
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/emergencies", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer mock_victim1")
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusCreated, rec.Code)
	var createdResp map[string]any
	err := json.Unmarshal(rec.Body.Bytes(), &createdResp)
	require.NoError(t, err)
	assert.NotEmpty(t, createdResp["incident_id"])
	assert.Equal(t, emergencies.StateServerReceived, createdResp["status"])

	incidentID := createdResp["incident_id"].(string)

	// Fetch incident
	fetchReq := httptest.NewRequest(http.MethodGet, "/api/v1/emergencies/"+incidentID, nil)
	fetchReq.Header.Set("Authorization", "Bearer mock_victim1")
	fetchRec := httptest.NewRecorder()
	router.ServeHTTP(fetchRec, fetchReq)

	assert.Equal(t, http.StatusOK, fetchRec.Code)
	var fetched emergencies.Incident
	err = json.Unmarshal(fetchRec.Body.Bytes(), &fetched)
	require.NoError(t, err)
	assert.Equal(t, incidentID, fetched.IncidentID)
	assert.Equal(t, "victim1", fetched.SenderID)
}

func TestCommunityReport_CoordinateFuzzing(t *testing.T) {
	router := setupTestRouter()

	payload := map[string]any{
		"category":        "POOR_LIGHTING",
		"title":           "Dark alleyway",
		"description":     "No lights working",
		"latitude_fuzzed": 28.53551234, // Should be rounded to 28.54
		"longitude_fuzzed": 77.39105678, // Should be rounded to 77.39
	}
	body, _ := json.Marshal(payload)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/community/reports", bytes.NewReader(body))
	req.Header.Set("Authorization", "Bearer mock_citizen1")
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	router.ServeHTTP(rec, req)

	assert.Equal(t, http.StatusCreated, rec.Code)
	var rep community.Report
	err := json.Unmarshal(rec.Body.Bytes(), &rep)
	require.NoError(t, err)
	assert.Equal(t, 28.54, rep.LatitudeFuzzed)
	assert.Equal(t, 77.39, rep.LongitudeFuzzed)
}
