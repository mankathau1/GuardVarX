package emergencies

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestStateTransitions(t *testing.T) {
	// Valid transitions
	assert.True(t, IsValidTransition(StateCreated, StateLocalSaved))
	assert.True(t, IsValidTransition(StateLocalSaved, StateQueued))
	assert.True(t, IsValidTransition(StateQueued, StateSending))
	assert.True(t, IsValidTransition(StateSending, StateServerReceived))
	assert.True(t, IsValidTransition(StateServerReceived, StateContactNotificationRequested))
	assert.True(t, IsValidTransition(StateContactNotificationRequested, StateContactAcknowledged))
	assert.True(t, IsValidTransition(StateContactAcknowledged, StateResolved))
	assert.True(t, IsValidTransition(StateServerReceived, StateCancelled))

	// Invalid transitions
	assert.False(t, IsValidTransition(StateResolved, StateCreated), "Cannot transition out of terminal state RESOLVED")
	assert.False(t, IsValidTransition(StateCancelled, StateResolved), "Cannot resolve cancelled incident")
	assert.False(t, IsValidTransition(StateExpired, StateSending), "Cannot send expired incident")
	assert.False(t, IsValidTransition(StateCreated, StateResolved), "Cannot directly jump from CREATED to RESOLVED")
}

func TestEmergencyRepository_Lifecycle(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryRepository()

	// 1. Create incident
	inc := &Incident{
		IncidentID:        "inc_test_1",
		IdempotencyKey:    "idem_key_12345",
		SenderID:          "usr_alice",
		EmergencyType:     "PERSONAL_THREAT",
		Message:           "Need help",
		Latitude:          28.5355,
		Longitude:         77.3910,
		AccuracyMeters:    12.0,
		LocationTimestamp: time.Now().UTC(),
		Priority:          "HIGH",
	}

	err := repo.Create(ctx, inc)
	require.NoError(t, err)
	assert.Equal(t, StateServerReceived, inc.Status)
	assert.NotEmpty(t, inc.ReceiptID)

	// 2. Test Idempotency: duplicate creation returns existing incident
	dupInc := &Incident{
		IdempotencyKey: "idem_key_12345",
		SenderID:       "usr_alice",
		EmergencyType:  "PERSONAL_THREAT",
	}
	err = repo.Create(ctx, dupInc)
	require.NoError(t, err)
	assert.Equal(t, "inc_test_1", dupInc.IncidentID)
	assert.Equal(t, inc.ReceiptID, dupInc.ReceiptID)

	// 3. Update status to CONTACT_NOTIFICATION_REQUESTED
	err = repo.UpdateStatus(ctx, inc.IncidentID, StateContactNotificationRequested, "system", nil)
	require.NoError(t, err)

	fetched, err := repo.GetByID(ctx, inc.IncidentID)
	require.NoError(t, err)
	assert.Equal(t, StateContactNotificationRequested, fetched.Status)

	// 4. Record acknowledgement
	ack := &DeliveryAck{
		IncidentID:      inc.IncidentID,
		ContactID:       "tc_brother",
		RecipientPhone:  "+919876543210",
		DeliveryChannel: "FCM",
	}
	err = repo.AddAcknowledgement(ctx, ack)
	require.NoError(t, err)

	acks, err := repo.ListAcks(ctx, inc.IncidentID)
	require.NoError(t, err)
	assert.Len(t, acks, 1)
	assert.Equal(t, "tc_brother", acks[0].ContactID)

	// 5. Test events recorded
	events, err := repo.ListEvents(ctx, inc.IncidentID)
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(events), 2)

	// 6. Resolve incident
	err = repo.Resolve(ctx, inc.IncidentID, "usr_alice")
	require.NoError(t, err)

	resolved, err := repo.GetByID(ctx, inc.IncidentID)
	require.NoError(t, err)
	assert.Equal(t, StateResolved, resolved.Status)
	assert.NotNil(t, resolved.ResolvedAt)
}

func TestEmergencyRepository_Cancellation(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryRepository()

	inc := &Incident{
		IncidentID:        "inc_cancel_test",
		SenderID:          "usr_bob",
		EmergencyType:     "ACCIDENT",
		Latitude:          12.9716,
		Longitude:         77.5946,
		LocationTimestamp: time.Now().UTC(),
	}

	err := repo.Create(ctx, inc)
	require.NoError(t, err)

	// Unauthorized user cannot cancel
	err = repo.Cancel(ctx, inc.IncidentID, "usr_eve", "Accidental")
	assert.ErrorIs(t, err, ErrUnauthorized)

	// Authorized sender can cancel
	err = repo.Cancel(ctx, inc.IncidentID, "usr_bob", "Accidental press")
	require.NoError(t, err)

	cancelled, err := repo.GetByID(ctx, inc.IncidentID)
	require.NoError(t, err)
	assert.Equal(t, StateCancelled, cancelled.Status)
	assert.Equal(t, "Accidental press", cancelled.CancelledReason)

	// Cannot resolve cancelled incident
	err = repo.Resolve(ctx, inc.IncidentID, "usr_bob")
	assert.ErrorIs(t, err, ErrInvalidStateTransition)
}
