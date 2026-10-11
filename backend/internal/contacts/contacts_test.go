package contacts

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestContactsRepository_CRUD(t *testing.T) {
	ctx := context.Background()
	repo := NewMemoryRepository()

	c := &TrustedContact{
		UserID:          "usr_user1",
		Name:            "Papa",
		Phone:           "+919811122233",
		Relationship:    "Father",
		CanReceiveSOS:   true,
		CanViewSafeWalk: true,
		PriorityOrder:   1,
	}

	// 1. Create
	err := repo.Create(ctx, c)
	require.NoError(t, err)
	assert.NotEmpty(t, c.ID)

	// 2. List
	list, err := repo.ListByUserID(ctx, "usr_user1")
	require.NoError(t, err)
	assert.Len(t, list, 1)
	assert.Equal(t, "Papa", list[0].Name)

	// 3. Unauthorized delete
	err = repo.Delete(ctx, c.ID, "usr_stranger")
	assert.ErrorIs(t, err, ErrUnauthorized)

	// 4. Authorized delete
	err = repo.Delete(ctx, c.ID, "usr_user1")
	require.NoError(t, err)

	listAfter, err := repo.ListByUserID(ctx, "usr_user1")
	require.NoError(t, err)
	assert.Empty(t, listAfter)
}
