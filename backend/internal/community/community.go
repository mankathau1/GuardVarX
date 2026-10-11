package community

import (
	"context"
	"errors"
	"math"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

var (
	ErrReportNotFound = errors.New("community report not found")
)

type Report struct {
	ID              string    `json:"id"`
	AuthorID        string    `json:"author_id,omitempty"`
	Category        string    `json:"category"`
	Title           string    `json:"title"`
	Description     string    `json:"description"`
	LatitudeFuzzed  float64   `json:"latitude_fuzzed"`
	LongitudeFuzzed float64   `json:"longitude_fuzzed"`
	IsVerified      bool      `json:"is_verified"`
	IsFlagged       bool      `json:"is_flagged"`
	Upvotes         int       `json:"upvotes"`
	ExpiresAt       time.Time `json:"expires_at"`
	CreatedAt       time.Time `json:"created_at"`
}

func FuzzCoordinate(coord float64) float64 {
	// Round to 2 decimal places (~1.1km / 500m area privacy protection)
	return math.Round(coord*100) / 100
}

type Repository interface {
	Create(ctx context.Context, r *Report) error
	List(ctx context.Context, lat, lng, radiusKm float64) ([]Report, error)
	GetByID(ctx context.Context, id string) (*Report, error)
	Upvote(ctx context.Context, id string) error
	Flag(ctx context.Context, id string) error
}

type MemoryRepository struct {
	mu      sync.RWMutex
	reports map[string]*Report
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		reports: make(map[string]*Report),
	}
}

func (m *MemoryRepository) Create(ctx context.Context, r *Report) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if r.ID == "" {
		r.ID = "rep_" + uuid.New().String()
	}
	r.LatitudeFuzzed = FuzzCoordinate(r.LatitudeFuzzed)
	r.LongitudeFuzzed = FuzzCoordinate(r.LongitudeFuzzed)
	r.CreatedAt = time.Now().UTC()
	if r.ExpiresAt.IsZero() {
		r.ExpiresAt = r.CreatedAt.Add(7 * 24 * time.Hour) // 7 days expiration
	}
	m.reports[r.ID] = r
	return nil
}

func (m *MemoryRepository) List(ctx context.Context, lat, lng, radiusKm float64) ([]Report, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	var list []Report
	now := time.Now().UTC()
	for _, r := range m.reports {
		if !r.IsFlagged && now.Before(r.ExpiresAt) {
			list = append(list, *r)
		}
	}
	return list, nil
}

func (m *MemoryRepository) GetByID(ctx context.Context, id string) (*Report, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	r, ok := m.reports[id]
	if !ok {
		return nil, ErrReportNotFound
	}
	cpy := *r
	return &cpy, nil
}

func (m *MemoryRepository) Upvote(ctx context.Context, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	r, ok := m.reports[id]
	if !ok {
		return ErrReportNotFound
	}
	r.Upvotes++
	return nil
}

func (m *MemoryRepository) Flag(ctx context.Context, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	r, ok := m.reports[id]
	if !ok {
		return ErrReportNotFound
	}
	r.IsFlagged = true
	return nil
}

type PostgresRepository struct {
	db *storage.Database
}

func NewPostgresRepository(db *storage.Database) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (p *PostgresRepository) Create(ctx context.Context, r *Report) error {
	if r.ID == "" {
		r.ID = "rep_" + uuid.New().String()
	}
	r.LatitudeFuzzed = FuzzCoordinate(r.LatitudeFuzzed)
	r.LongitudeFuzzed = FuzzCoordinate(r.LongitudeFuzzed)
	if r.ExpiresAt.IsZero() {
		r.ExpiresAt = time.Now().UTC().Add(7 * 24 * time.Hour)
	}

	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO community_reports (id, author_id, category, title, description, latitude_fuzzed, longitude_fuzzed, is_verified, is_flagged, upvotes, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())`,
		r.ID, r.AuthorID, r.Category, r.Title, r.Description, r.LatitudeFuzzed, r.LongitudeFuzzed, r.IsVerified, r.IsFlagged, r.Upvotes, r.ExpiresAt)
	return err
}

func (p *PostgresRepository) List(ctx context.Context, lat, lng, radiusKm float64) ([]Report, error) {
	rows, err := p.db.Pool.Query(ctx, `
		SELECT id, COALESCE(author_id, ''), category, title, description, latitude_fuzzed, longitude_fuzzed, is_verified, is_flagged, upvotes, expires_at, created_at
		FROM community_reports
		WHERE is_flagged = FALSE AND expires_at > NOW()
		ORDER BY created_at DESC LIMIT 50`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []Report
	for rows.Next() {
		var r Report
		if err := rows.Scan(&r.ID, &r.AuthorID, &r.Category, &r.Title, &r.Description,
			&r.LatitudeFuzzed, &r.LongitudeFuzzed, &r.IsVerified, &r.IsFlagged, &r.Upvotes, &r.ExpiresAt, &r.CreatedAt); err != nil {
			return nil, err
		}
		list = append(list, r)
	}
	return list, nil
}

func (p *PostgresRepository) GetByID(ctx context.Context, id string) (*Report, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, COALESCE(author_id, ''), category, title, description, latitude_fuzzed, longitude_fuzzed, is_verified, is_flagged, upvotes, expires_at, created_at
		FROM community_reports WHERE id = $1`, id)
	var r Report
	if err := row.Scan(&r.ID, &r.AuthorID, &r.Category, &r.Title, &r.Description,
		&r.LatitudeFuzzed, &r.LongitudeFuzzed, &r.IsVerified, &r.IsFlagged, &r.Upvotes, &r.ExpiresAt, &r.CreatedAt); err != nil {
		return nil, ErrReportNotFound
	}
	return &r, nil
}

func (p *PostgresRepository) Upvote(ctx context.Context, id string) error {
	_, err := p.db.Pool.Exec(ctx, `UPDATE community_reports SET upvotes = upvotes + 1 WHERE id = $1`, id)
	return err
}

func (p *PostgresRepository) Flag(ctx context.Context, id string) error {
	_, err := p.db.Pool.Exec(ctx, `UPDATE community_reports SET is_flagged = TRUE WHERE id = $1`, id)
	return err
}
