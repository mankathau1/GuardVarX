package safe_walk

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSafeWalkSession_Lifecycle(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryRepository()

	session := &Session{
		UserID:                  "usr_priya",
		DestinationName:         "Home, Sector 62",
		DestinationLatitude:     28.6275,
		DestinationLongitude:    77.3649,
		ExpectedDurationMinutes: 25,
		CheckinIntervalMinutes:  10,
		TrustedContactIDs:       []string{"tc_brother"},
	}

	// 1. Create session
	err := repo.Create(ctx, session)
	require.NoError(t, err)
	assert.Equal(t, StatusActive, session.Status)
	assert.NotEmpty(t, session.ID)

	// 2. Fetch active session
	active, err := repo.GetActiveByUserID(ctx, "usr_priya")
	require.NoError(t, err)
	assert.Equal(t, session.ID, active.ID)

	// 3. Perform safe check-in
	updated, err := repo.Checkin(ctx, session.ID, "usr_priya", 28.6000, 77.3500)
	require.NoError(t, err)
	assert.Equal(t, StatusActive, updated.Status)
	assert.Equal(t, 28.6000, updated.CurrentLatitude)

	// Unauthorized check-in fails
	_, err = repo.Checkin(ctx, session.ID, "usr_attacker", 28.6000, 77.3500)
	assert.ErrorIs(t, err, ErrUnauthorized)

	// 4. Complete session
	completed, err := repo.Complete(ctx, session.ID, "usr_priya")
	require.NoError(t, err)
	assert.Equal(t, StatusCompleted, completed.Status)
	assert.NotNil(t, completed.CompletedAt)

	// No active session remains
	_, err = repo.GetActiveByUserID(ctx, "usr_priya")
	assert.ErrorIs(t, err, ErrSessionNotFound)
}

func TestSafeWalk_OverdueEscalation(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryRepository()

	session := &Session{
		UserID:                  "usr_overdue",
		DestinationName:         "Metro Station",
		ExpectedDurationMinutes: 10,
		CheckinIntervalMinutes:  5,
	}

	err := repo.Create(ctx, session)
	require.NoError(t, err)

	// Artificially age the next check-in deadline
	session.NextCheckinDue = time.Now().UTC().Add(-2 * time.Minute)

	escalated, err := repo.CheckOverdueSessions(ctx)
	require.NoError(t, err)
	assert.Len(t, escalated, 1)
	assert.Equal(t, StatusWarning, escalated[0].Status)
}
