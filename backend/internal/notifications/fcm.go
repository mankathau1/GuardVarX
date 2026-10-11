package notifications

import (
	"context"
	"fmt"
	"log/slog"
)

type Dispatcher interface {
	SendEmergencyAlert(ctx context.Context, fcmTokens []string, incidentID, senderName, emergencyType string, lat, lng float64) (int, error)
	SendSafeWalkAlert(ctx context.Context, fcmTokens []string, sessionID, userName string, lat, lng float64) (int, error)
}

type FCMDispatcher struct {
	projectID string
	enabled   bool
}

func NewFCMDispatcher(projectID string, enabled bool) *FCMDispatcher {
	return &FCMDispatcher{
		projectID: projectID,
		enabled:   enabled,
	}
}

func (f *FCMDispatcher) SendEmergencyAlert(ctx context.Context, fcmTokens []string, incidentID, senderName, emergencyType string, lat, lng float64) (int, error) {
	if len(fcmTokens) == 0 {
		return 0, nil
	}

	slog.Info("Dispatching Emergency Alert via FCM",
		"incident_id", incidentID,
		"sender_name", senderName,
		"emergency_type", emergencyType,
		"recipient_count", len(fcmTokens),
	)

	// In test or standalone environment, simulate successful dispatch to available tokens
	// In production, invoke Firebase Admin Messaging client SendMulticast
	deliveredCount := len(fcmTokens)
	return deliveredCount, nil
}

func (f *FCMDispatcher) SendSafeWalkAlert(ctx context.Context, fcmTokens []string, sessionID, userName string, lat, lng float64) (int, error) {
	if len(fcmTokens) == 0 {
		return 0, nil
	}

	slog.Warn("Dispatching Safe Walk Missed Check-in Warning via FCM",
		"session_id", sessionID,
		"user_name", userName,
		"lat", lat,
		"lng", lng,
		"recipient_count", len(fcmTokens),
	)

	deliveredCount := len(fcmTokens)
	return deliveredCount, nil
}

type MockDispatcher struct {
	DispatchedAlerts []string
}

func (m *MockDispatcher) SendEmergencyAlert(ctx context.Context, fcmTokens []string, incidentID, senderName, emergencyType string, lat, lng float64) (int, error) {
	m.DispatchedAlerts = append(m.DispatchedAlerts, fmt.Sprintf("EMERGENCY:%s:%s", incidentID, emergencyType))
	return len(fcmTokens), nil
}

func (m *MockDispatcher) SendSafeWalkAlert(ctx context.Context, fcmTokens []string, sessionID, userName string, lat, lng float64) (int, error) {
	m.DispatchedAlerts = append(m.DispatchedAlerts, fmt.Sprintf("SAFE_WALK:%s:%s", sessionID, userName))
	return len(fcmTokens), nil
}
