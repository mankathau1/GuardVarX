package responders

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

const (
	MissionStatusAssigned  = "ASSIGNED"
	MissionStatusAccepted  = "ACCEPTED"
	MissionStatusEnRoute   = "EN_ROUTE"
	MissionStatusArrived   = "ARRIVED"
	MissionStatusCompleted = "COMPLETED"
	MissionStatusCancelled = "CANCELLED"
)

var (
	ErrMissionNotFound = errors.New("mission not found")
	ErrUnauthorized    = errors.New("unauthorized mission update")
)

type Mission struct {
	ID          string     `json:"id"`
	IncidentID  string     `json:"incident_id"`
	ResponderID string     `json:"responder_id"`
	Status      string     `json:"status"`
	ETAMinutes  int        `json:"eta_minutes"`
	AcceptedAt  *time.Time `json:"accepted_at,omitempty"`
	ArrivedAt   *time.Time `json:"arrived_at,omitempty"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}

type ResponderProfile struct {
	UserID             string    `json:"user_id"`
	VerificationStatus string    `json:"verification_status"`
	Skills             []string  `json:"skills"`
	IsActive           bool      `json:"is_active"`
	LastLatitude       float64   `json:"last_latitude"`
	LastLongitude      float64   `json:"last_longitude"`
	LastLocationAt     time.Time `json:"last_location_at"`
}

type Repository interface {
	CreateMission(ctx context.Context, m *Mission) error
	GetMissionByID(ctx context.Context, id string) (*Mission, error)
	ListMissionsByIncident(ctx context.Context, incidentID string) ([]Mission, error)
	UpdateMissionStatus(ctx context.Context, id, responderID, status string) error
	UpdateAvailability(ctx context.Context, p *ResponderProfile) error
}

type MemoryRepository struct {
	mu       sync.RWMutex
	missions map[string]*Mission
	profiles map[string]*ResponderProfile
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		missions: make(map[string]*Mission),
		profiles: make(map[string]*ResponderProfile),
	}
}

func (m *MemoryRepository) CreateMission(ctx context.Context, ms *Mission) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if ms.ID == "" {
		ms.ID = "msn_" + uuid.New().String()
	}
	ms.CreatedAt = time.Now().UTC()
	now := ms.CreatedAt
	ms.AcceptedAt = &now
	m.missions[ms.ID] = ms
	return nil
}

func (m *MemoryRepository) GetMissionByID(ctx context.Context, id string) (*Mission, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	ms, ok := m.missions[id]
	if !ok {
		return nil, ErrMissionNotFound
	}
	cpy := *ms
	return &cpy, nil
}

func (m *MemoryRepository) ListMissionsByIncident(ctx context.Context, incidentID string) ([]Mission, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	var list []Mission
	for _, ms := range m.missions {
		if ms.IncidentID == incidentID {
			list = append(list, *ms)
		}
	}
	return list, nil
}

func (m *MemoryRepository) UpdateMissionStatus(ctx context.Context, id, responderID, status string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	ms, ok := m.missions[id]
	if !ok {
		return ErrMissionNotFound
	}
	if ms.ResponderID != responderID {
		return ErrUnauthorized
	}

	now := time.Now().UTC()
	ms.Status = status
	if status == MissionStatusArrived {
		ms.ArrivedAt = &now
	} else if status == MissionStatusCompleted {
		ms.CompletedAt = &now
	}
	return nil
}

func (m *MemoryRepository) UpdateAvailability(ctx context.Context, p *ResponderProfile) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	p.LastLocationAt = time.Now().UTC()
	m.profiles[p.UserID] = p
	return nil
}

type PostgresRepository struct {
	db *storage.Database
}

func NewPostgresRepository(db *storage.Database) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (p *PostgresRepository) CreateMission(ctx context.Context, ms *Mission) error {
	if ms.ID == "" {
		ms.ID = "msn_" + uuid.New().String()
	}
	now := time.Now().UTC()
	ms.AcceptedAt = &now
	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO missions (id, incident_id, responder_id, status, eta_minutes, accepted_at, created_at)
		VALUES ($1, $2, $3, $4, $5, NOW(), NOW())`,
		ms.ID, ms.IncidentID, ms.ResponderID, ms.Status, ms.ETAMinutes)
	return err
}

func (p *PostgresRepository) GetMissionByID(ctx context.Context, id string) (*Mission, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, incident_id, responder_id, status, eta_minutes, accepted_at, arrived_at, completed_at, created_at
		FROM missions WHERE id = $1`, id)
	var ms Mission
	if err := row.Scan(&ms.ID, &ms.IncidentID, &ms.ResponderID, &ms.Status, &ms.ETAMinutes,
		&ms.AcceptedAt, &ms.ArrivedAt, &ms.CompletedAt, &ms.CreatedAt); err != nil {
		return nil, ErrMissionNotFound
	}
	return &ms, nil
}

func (p *PostgresRepository) ListMissionsByIncident(ctx context.Context, incidentID string) ([]Mission, error) {
	rows, err := p.db.Pool.Query(ctx, `
		SELECT id, incident_id, responder_id, status, eta_minutes, accepted_at, arrived_at, completed_at, created_at
		FROM missions WHERE incident_id = $1`, incidentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []Mission
	for rows.Next() {
		var ms Mission
		if err := rows.Scan(&ms.ID, &ms.IncidentID, &ms.ResponderID, &ms.Status, &ms.ETAMinutes,
			&ms.AcceptedAt, &ms.ArrivedAt, &ms.CompletedAt, &ms.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, ms)
	}
	return list, nil
}

func (p *PostgresRepository) UpdateMissionStatus(ctx context.Context, id, responderID, status string) error {
	ms, err := p.GetMissionByID(ctx, id)
	if err != nil {
		return err
	}
	if ms.ResponderID != responderID {
		return ErrUnauthorized
	}

	query := `UPDATE missions SET status = $2 WHERE id = $1`
	if status == MissionStatusArrived {
		query = `UPDATE missions SET status = $2, arrived_at = NOW() WHERE id = $1`
	} else if status == MissionStatusCompleted {
		query = `UPDATE missions SET status = $2, completed_at = NOW() WHERE id = $1`
	}

	_, err = p.db.Pool.Exec(ctx, query, id, status)
	return err
}

func (p *PostgresRepository) UpdateAvailability(ctx context.Context, prof *ResponderProfile) error {
	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO responder_profiles (user_id, verification_status, skills, is_active, last_latitude, last_longitude, last_location_at)
		VALUES ($1, $2, $3, $4, $5, $6, NOW())
		ON CONFLICT (user_id) 
		DO UPDATE SET is_active = EXCLUDED.is_active, last_latitude = EXCLUDED.last_latitude, last_longitude = EXCLUDED.last_longitude, last_location_at = NOW()`,
		prof.UserID, prof.VerificationStatus, prof.Skills, prof.IsActive, prof.LastLatitude, prof.LastLongitude)
	return err
}
