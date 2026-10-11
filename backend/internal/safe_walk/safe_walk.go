package safe_walk

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

const (
	StatusActive    = "ACTIVE"
	StatusWarning   = "WARNING"
	StatusCompleted = "COMPLETED"
	StatusCancelled = "CANCELLED"
	StatusExpired   = "EXPIRED"
)

var (
	ErrSessionNotFound = errors.New("safe walk session not found")
	ErrUnauthorized    = errors.New("unauthorized access to safe walk session")
)

type Session struct {
	ID                     string     `json:"id"`
	UserID                 string     `json:"user_id"`
	Status                 string     `json:"status"`
	DestinationName        string     `json:"destination_name"`
	DestinationLatitude    float64    `json:"destination_latitude"`
	DestinationLongitude   float64    `json:"destination_longitude"`
	CurrentLatitude        float64    `json:"current_latitude"`
	CurrentLongitude       float64    `json:"current_longitude"`
	ExpectedDurationMinutes int        `json:"expected_duration_minutes"`
	CheckinIntervalMinutes int        `json:"checkin_interval_minutes"`
	LastCheckinAt          time.Time  `json:"last_checkin_at"`
	NextCheckinDue         time.Time  `json:"next_checkin_due"`
	TrustedContactIDs      []string   `json:"trusted_contact_ids"`
	CompletedAt            *time.Time `json:"completed_at,omitempty"`
	CreatedAt              time.Time  `json:"created_at"`
}

type Repository interface {
	Create(ctx context.Context, s *Session) error
	GetByID(ctx context.Context, id string) (*Session, error)
	GetActiveByUserID(ctx context.Context, userID string) (*Session, error)
	Checkin(ctx context.Context, id, userID string, lat, lng float64) (*Session, error)
	Complete(ctx context.Context, id, userID string) (*Session, error)
	Cancel(ctx context.Context, id, userID string) (*Session, error)
	CheckOverdueSessions(ctx context.Context) ([]Session, error)
}

type MemoryRepository struct {
	mu       sync.RWMutex
	sessions map[string]*Session
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		sessions: make(map[string]*Session),
	}
}

func (m *MemoryRepository) Create(ctx context.Context, s *Session) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if s.ID == "" {
		s.ID = "sw_" + uuid.New().String()
	}
	s.Status = StatusActive
	s.CreatedAt = time.Now().UTC()
	s.LastCheckinAt = s.CreatedAt
	s.NextCheckinDue = s.CreatedAt.Add(time.Duration(s.CheckinIntervalMinutes) * time.Minute)
	m.sessions[s.ID] = s
	return nil
}

func (m *MemoryRepository) GetByID(ctx context.Context, id string) (*Session, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	s, ok := m.sessions[id]
	if !ok {
		return nil, ErrSessionNotFound
	}
	cpy := *s
	return &cpy, nil
}

func (m *MemoryRepository) GetActiveByUserID(ctx context.Context, userID string) (*Session, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	for _, s := range m.sessions {
		if s.UserID == userID && (s.Status == StatusActive || s.Status == StatusWarning) {
			cpy := *s
			return &cpy, nil
		}
	}
	return nil, ErrSessionNotFound
}

func (m *MemoryRepository) Checkin(ctx context.Context, id, userID string, lat, lng float64) (*Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[id]
	if !ok {
		return nil, ErrSessionNotFound
	}
	if s.UserID != userID {
		return nil, ErrUnauthorized
	}

	now := time.Now().UTC()
	s.CurrentLatitude = lat
	s.CurrentLongitude = lng
	s.LastCheckinAt = now
	s.NextCheckinDue = now.Add(time.Duration(s.CheckinIntervalMinutes) * time.Minute)
	s.Status = StatusActive

	cpy := *s
	return &cpy, nil
}

func (m *MemoryRepository) Complete(ctx context.Context, id, userID string) (*Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[id]
	if !ok {
		return nil, ErrSessionNotFound
	}
	if s.UserID != userID {
		return nil, ErrUnauthorized
	}

	now := time.Now().UTC()
	s.Status = StatusCompleted
	s.CompletedAt = &now

	cpy := *s
	return &cpy, nil
}

func (m *MemoryRepository) Cancel(ctx context.Context, id, userID string) (*Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[id]
	if !ok {
		return nil, ErrSessionNotFound
	}
	if s.UserID != userID {
		return nil, ErrUnauthorized
	}

	s.Status = StatusCancelled
	cpy := *s
	return &cpy, nil
}

func (m *MemoryRepository) CheckOverdueSessions(ctx context.Context) ([]Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	now := time.Now().UTC()
	var escalated []Session
	for _, s := range m.sessions {
		if s.Status == StatusActive && now.After(s.NextCheckinDue) {
			s.Status = StatusWarning
			escalated = append(escalated, *s)
		}
	}
	return escalated, nil
}

type PostgresRepository struct {
	db *storage.Database
}

func NewPostgresRepository(db *storage.Database) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (p *PostgresRepository) Create(ctx context.Context, s *Session) error {
	if s.ID == "" {
		s.ID = "sw_" + uuid.New().String()
	}
	s.Status = StatusActive
	s.CreatedAt = time.Now().UTC()
	s.LastCheckinAt = s.CreatedAt
	s.NextCheckinDue = s.CreatedAt.Add(time.Duration(s.CheckinIntervalMinutes) * time.Minute)

	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO safe_walk_sessions (
			id, user_id, status, destination_name, destination_latitude, destination_longitude,
			current_latitude, current_longitude, expected_duration_minutes, checkin_interval_minutes,
			last_checkin_at, next_checkin_due, trusted_contact_ids, created_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())`,
		s.ID, s.UserID, s.Status, s.DestinationName, s.DestinationLatitude, s.DestinationLongitude,
		s.CurrentLatitude, s.CurrentLongitude, s.ExpectedDurationMinutes, s.CheckinIntervalMinutes,
		s.LastCheckinAt, s.NextCheckinDue, s.TrustedContactIDs)
	return err
}

func (p *PostgresRepository) GetByID(ctx context.Context, id string) (*Session, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, user_id, status, destination_name, destination_latitude, destination_longitude,
		       COALESCE(current_latitude, 0), COALESCE(current_longitude, 0),
		       expected_duration_minutes, checkin_interval_minutes,
		       last_checkin_at, next_checkin_due, COALESCE(trusted_contact_ids, '{}'), completed_at, created_at
		FROM safe_walk_sessions WHERE id = $1`, id)
	var s Session
	err := row.Scan(&s.ID, &s.UserID, &s.Status, &s.DestinationName, &s.DestinationLatitude, &s.DestinationLongitude,
		&s.CurrentLatitude, &s.CurrentLongitude, &s.ExpectedDurationMinutes, &s.CheckinIntervalMinutes,
		&s.LastCheckinAt, &s.NextCheckinDue, &s.TrustedContactIDs, &s.CompletedAt, &s.CreatedAt)
	if err != nil {
		return nil, ErrSessionNotFound
	}
	return &s, nil
}

func (p *PostgresRepository) GetActiveByUserID(ctx context.Context, userID string) (*Session, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, user_id, status, destination_name, destination_latitude, destination_longitude,
		       COALESCE(current_latitude, 0), COALESCE(current_longitude, 0),
		       expected_duration_minutes, checkin_interval_minutes,
		       last_checkin_at, next_checkin_due, COALESCE(trusted_contact_ids, '{}'), completed_at, created_at
		FROM safe_walk_sessions 
		WHERE user_id = $1 AND status IN ('ACTIVE', 'WARNING') 
		ORDER BY created_at DESC LIMIT 1`, userID)
	var s Session
	err := row.Scan(&s.ID, &s.UserID, &s.Status, &s.DestinationName, &s.DestinationLatitude, &s.DestinationLongitude,
		&s.CurrentLatitude, &s.CurrentLongitude, &s.ExpectedDurationMinutes, &s.CheckinIntervalMinutes,
		&s.LastCheckinAt, &s.NextCheckinDue, &s.TrustedContactIDs, &s.CompletedAt, &s.CreatedAt)
	if err != nil {
		return nil, ErrSessionNotFound
	}
	return &s, nil
}

func (p *PostgresRepository) Checkin(ctx context.Context, id, userID string, lat, lng float64) (*Session, error) {
	s, err := p.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if s.UserID != userID {
		return nil, ErrUnauthorized
	}

	nextDue := time.Now().UTC().Add(time.Duration(s.CheckinIntervalMinutes) * time.Minute)
	_, err = p.db.Pool.Exec(ctx, `
		UPDATE safe_walk_sessions
		SET current_latitude = $2, current_longitude = $3, last_checkin_at = NOW(), next_checkin_due = $4, status = 'ACTIVE'
		WHERE id = $1`, id, lat, lng, nextDue)
	if err != nil {
		return nil, err
	}
	return p.GetByID(ctx, id)
}

func (p *PostgresRepository) Complete(ctx context.Context, id, userID string) (*Session, error) {
	s, err := p.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if s.UserID != userID {
		return nil, ErrUnauthorized
	}

	_, err = p.db.Pool.Exec(ctx, `
		UPDATE safe_walk_sessions SET status = 'COMPLETED', completed_at = NOW() WHERE id = $1`, id)
	if err != nil {
		return nil, err
	}
	return p.GetByID(ctx, id)
}

func (p *PostgresRepository) Cancel(ctx context.Context, id, userID string) (*Session, error) {
	s, err := p.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if s.UserID != userID {
		return nil, ErrUnauthorized
	}

	_, err = p.db.Pool.Exec(ctx, `
		UPDATE safe_walk_sessions SET status = 'CANCELLED' WHERE id = $1`, id)
	if err != nil {
		return nil, err
	}
	return p.GetByID(ctx, id)
}

func (p *PostgresRepository) CheckOverdueSessions(ctx context.Context) ([]Session, error) {
	rows, err := p.db.Pool.Query(ctx, `
		UPDATE safe_walk_sessions 
		SET status = 'WARNING'
		WHERE status = 'ACTIVE' AND next_checkin_due < NOW()
		RETURNING id, user_id, status, destination_name, destination_latitude, destination_longitude,
		          COALESCE(current_latitude, 0), COALESCE(current_longitude, 0),
		          expected_duration_minutes, checkin_interval_minutes,
		          last_checkin_at, next_checkin_due, COALESCE(trusted_contact_ids, '{}'), completed_at, created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var escalated []Session
	for rows.Next() {
		var s Session
		if err := rows.Scan(&s.ID, &s.UserID, &s.Status, &s.DestinationName, &s.DestinationLatitude, &s.DestinationLongitude,
			&s.CurrentLatitude, &s.CurrentLongitude, &s.ExpectedDurationMinutes, &s.CheckinIntervalMinutes,
			&s.LastCheckinAt, &s.NextCheckinDue, &s.TrustedContactIDs, &s.CompletedAt, &s.CreatedAt); err != nil {
			return nil, err
		}
		escalated = append(escalated, s)
	}
	return escalated, nil
}
