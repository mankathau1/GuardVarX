package contacts

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

var (
	ErrContactNotFound = errors.New("trusted contact not found")
	ErrUnauthorized    = errors.New("unauthorized access to contact")
)

type TrustedContact struct {
	ID              string    `json:"id"`
	UserID          string    `json:"user_id"`
	Name            string    `json:"name"`
	Phone           string    `json:"phone"`
	Relationship    string    `json:"relationship"`
	IsConfirmed     bool      `json:"is_confirmed"`
	CanViewSafeWalk bool      `json:"can_view_safe_walk"`
	CanReceiveSOS   bool      `json:"can_receive_sos"`
	PriorityOrder   int       `json:"priority_order"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type Repository interface {
	ListByUserID(ctx context.Context, userID string) ([]TrustedContact, error)
	GetByID(ctx context.Context, id string) (*TrustedContact, error)
	Create(ctx context.Context, c *TrustedContact) error
	Update(ctx context.Context, c *TrustedContact) error
	Delete(ctx context.Context, id, userID string) error
}

type MemoryRepository struct {
	mu       sync.RWMutex
	contacts map[string]*TrustedContact
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		contacts: make(map[string]*TrustedContact),
	}
}

func (m *MemoryRepository) ListByUserID(ctx context.Context, userID string) ([]TrustedContact, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	var list []TrustedContact
	for _, c := range m.contacts {
		if c.UserID == userID {
			list = append(list, *c)
		}
	}
	return list, nil
}

func (m *MemoryRepository) GetByID(ctx context.Context, id string) (*TrustedContact, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	c, ok := m.contacts[id]
	if !ok {
		return nil, ErrContactNotFound
	}
	cpy := *c
	return &cpy, nil
}

func (m *MemoryRepository) Create(ctx context.Context, c *TrustedContact) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if c.ID == "" {
		c.ID = "tc_" + uuid.New().String()
	}
	c.CreatedAt = time.Now().UTC()
	c.UpdatedAt = time.Now().UTC()
	m.contacts[c.ID] = c
	return nil
}

func (m *MemoryRepository) Update(ctx context.Context, c *TrustedContact) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.contacts[c.ID]
	if !ok {
		return ErrContactNotFound
	}
	if existing.UserID != c.UserID {
		return ErrUnauthorized
	}
	c.UpdatedAt = time.Now().UTC()
	c.CreatedAt = existing.CreatedAt
	m.contacts[c.ID] = c
	return nil
}

func (m *MemoryRepository) Delete(ctx context.Context, id, userID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	c, ok := m.contacts[id]
	if !ok {
		return ErrContactNotFound
	}
	if c.UserID != userID {
		return ErrUnauthorized
	}
	delete(m.contacts, id)
	return nil
}

type PostgresRepository struct {
	db *storage.Database
}

func NewPostgresRepository(db *storage.Database) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (p *PostgresRepository) ListByUserID(ctx context.Context, userID string) ([]TrustedContact, error) {
	rows, err := p.db.Pool.Query(ctx, `
		SELECT id, user_id, name, phone, relationship, is_confirmed, can_view_safe_walk, can_receive_sos, priority_order, created_at, updated_at
		FROM trusted_contacts WHERE user_id = $1 ORDER BY priority_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []TrustedContact
	for rows.Next() {
		var c TrustedContact
		if err := rows.Scan(&c.ID, &c.UserID, &c.Name, &c.Phone, &c.Relationship, &c.IsConfirmed,
			&c.CanViewSafeWalk, &c.CanReceiveSOS, &c.PriorityOrder, &c.CreatedAt, &c.UpdatedAt); err != nil {
			return nil, err
		}
		list = append(list, c)
	}
	return list, nil
}

func (p *PostgresRepository) GetByID(ctx context.Context, id string) (*TrustedContact, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, user_id, name, phone, relationship, is_confirmed, can_view_safe_walk, can_receive_sos, priority_order, created_at, updated_at
		FROM trusted_contacts WHERE id = $1`, id)
	var c TrustedContact
	if err := row.Scan(&c.ID, &c.UserID, &c.Name, &c.Phone, &c.Relationship, &c.IsConfirmed,
		&c.CanViewSafeWalk, &c.CanReceiveSOS, &c.PriorityOrder, &c.CreatedAt, &c.UpdatedAt); err != nil {
		return nil, ErrContactNotFound
	}
	return &c, nil
}

func (p *PostgresRepository) Create(ctx context.Context, c *TrustedContact) error {
	if c.ID == "" {
		c.ID = "tc_" + uuid.New().String()
	}
	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO trusted_contacts (id, user_id, name, phone, relationship, is_confirmed, can_view_safe_walk, can_receive_sos, priority_order, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())`,
		c.ID, c.UserID, c.Name, c.Phone, c.Relationship, c.IsConfirmed, c.CanViewSafeWalk, c.CanReceiveSOS, c.PriorityOrder)
	return err
}

func (p *PostgresRepository) Update(ctx context.Context, c *TrustedContact) error {
	_, err := p.db.Pool.Exec(ctx, `
		UPDATE trusted_contacts
		SET name = $2, phone = $3, relationship = $4, is_confirmed = $5, can_view_safe_walk = $6, can_receive_sos = $7, priority_order = $8, updated_at = NOW()
		WHERE id = $1 AND user_id = $9`,
		c.ID, c.Name, c.Phone, c.Relationship, c.IsConfirmed, c.CanViewSafeWalk, c.CanReceiveSOS, c.PriorityOrder, c.UserID)
	return err
}

func (p *PostgresRepository) Delete(ctx context.Context, id, userID string) error {
	_, err := p.db.Pool.Exec(ctx, `DELETE FROM trusted_contacts WHERE id = $1 AND user_id = $2`, id, userID)
	return err
}
