package users

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

var (
	ErrUserNotFound = errors.New("user not found")
)

type User struct {
	ID               string    `json:"id"`
	FirebaseUID      string    `json:"firebase_uid"`
	Phone            string    `json:"phone"`
	DisplayName      string    `json:"display_name"`
	Email            string    `json:"email"`
	AvatarURL        string    `json:"avatar_url,omitempty"`
	Role             string    `json:"role"`
	EmergencyPINHash string    `json:"-"`
	DuressPINHash    string    `json:"-"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

type Device struct {
	ID         string    `json:"id"`
	UserID     string    `json:"user_id"`
	DeviceID   string    `json:"device_id"`
	FCMToken   string    `json:"fcm_token"`
	Platform   string    `json:"platform"`
	Model      string    `json:"model"`
	OSVersion  string    `json:"os_version"`
	LastActive time.Time `json:"last_active_at"`
}

type Repository interface {
	GetByID(ctx context.Context, id string) (*User, error)
	GetByFirebaseUID(ctx context.Context, uid string) (*User, error)
	Create(ctx context.Context, u *User) error
	Update(ctx context.Context, u *User) error
	Delete(ctx context.Context, id string) error
	RegisterDevice(ctx context.Context, d *Device) error
	GetDevicesByUserID(ctx context.Context, userID string) ([]Device, error)
}

// MemoryRepository provides robust fallback storage when testing or offline
type MemoryRepository struct {
	mu      sync.RWMutex
	users   map[string]*User
	byUID   map[string]string
	devices map[string][]Device
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		users:   make(map[string]*User),
		byUID:   make(map[string]string),
		devices: make(map[string][]Device),
	}
}

func (m *MemoryRepository) GetByID(ctx context.Context, id string) (*User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	u, ok := m.users[id]
	if !ok {
		return nil, ErrUserNotFound
	}
	cpy := *u
	return &cpy, nil
}

func (m *MemoryRepository) GetByFirebaseUID(ctx context.Context, uid string) (*User, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	id, ok := m.byUID[uid]
	if !ok {
		return nil, ErrUserNotFound
	}
	return m.GetByID(ctx, id)
}

func (m *MemoryRepository) Create(ctx context.Context, u *User) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if u.ID == "" {
		u.ID = "usr_" + uuid.New().String()
	}
	u.CreatedAt = time.Now().UTC()
	u.UpdatedAt = time.Now().UTC()
	m.users[u.ID] = u
	m.byUID[u.FirebaseUID] = u.ID
	return nil
}

func (m *MemoryRepository) Update(ctx context.Context, u *User) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	existing, ok := m.users[u.ID]
	if !ok {
		return ErrUserNotFound
	}
	u.UpdatedAt = time.Now().UTC()
	u.CreatedAt = existing.CreatedAt
	m.users[u.ID] = u
	return nil
}

func (m *MemoryRepository) Delete(ctx context.Context, id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	u, ok := m.users[id]
	if !ok {
		return ErrUserNotFound
	}
	delete(m.byUID, u.FirebaseUID)
	delete(m.users, id)
	delete(m.devices, id)
	return nil
}

func (m *MemoryRepository) RegisterDevice(ctx context.Context, d *Device) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if d.ID == "" {
		d.ID = "dev_" + uuid.New().String()
	}
	d.LastActive = time.Now().UTC()

	list := m.devices[d.UserID]
	updated := false
	for i, dev := range list {
		if dev.DeviceID == d.DeviceID {
			list[i] = *d
			updated = true
			break
		}
	}
	if !updated {
		list = append(list, *d)
	}
	m.devices[d.UserID] = list
	return nil
}

func (m *MemoryRepository) GetDevicesByUserID(ctx context.Context, userID string) ([]Device, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return append([]Device(nil), m.devices[userID]...), nil
}

// PostgresRepository provides PostgreSQL backed persistence
type PostgresRepository struct {
	db *storage.Database
}

func NewPostgresRepository(db *storage.Database) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (p *PostgresRepository) GetByID(ctx context.Context, id string) (*User, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, firebase_uid, phone, display_name, email, avatar_url, role, 
		       COALESCE(emergency_pin_hash, ''), COALESCE(duress_pin_hash, ''), created_at, updated_at
		FROM users WHERE id = $1`, id)
	var u User
	err := row.Scan(&u.ID, &u.FirebaseUID, &u.Phone, &u.DisplayName, &u.Email, &u.AvatarURL, &u.Role,
		&u.EmergencyPINHash, &u.DuressPINHash, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return &u, nil
}

func (p *PostgresRepository) GetByFirebaseUID(ctx context.Context, uid string) (*User, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT id, firebase_uid, phone, display_name, email, avatar_url, role, 
		       COALESCE(emergency_pin_hash, ''), COALESCE(duress_pin_hash, ''), created_at, updated_at
		FROM users WHERE firebase_uid = $1`, uid)
	var u User
	err := row.Scan(&u.ID, &u.FirebaseUID, &u.Phone, &u.DisplayName, &u.Email, &u.AvatarURL, &u.Role,
		&u.EmergencyPINHash, &u.DuressPINHash, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, ErrUserNotFound
	}
	return &u, nil
}

func (p *PostgresRepository) Create(ctx context.Context, u *User) error {
	if u.ID == "" {
		u.ID = "usr_" + uuid.New().String()
	}
	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO users (id, firebase_uid, phone, display_name, email, avatar_url, role, emergency_pin_hash, duress_pin_hash, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())`,
		u.ID, u.FirebaseUID, u.Phone, u.DisplayName, u.Email, u.AvatarURL, u.Role, u.EmergencyPINHash, u.DuressPINHash)
	return err
}

func (p *PostgresRepository) Update(ctx context.Context, u *User) error {
	_, err := p.db.Pool.Exec(ctx, `
		UPDATE users 
		SET display_name = $2, phone = $3, email = $4, avatar_url = $5, role = $6, updated_at = NOW()
		WHERE id = $1`,
		u.ID, u.DisplayName, u.Phone, u.Email, u.AvatarURL, u.Role)
	return err
}

func (p *PostgresRepository) Delete(ctx context.Context, id string) error {
	_, err := p.db.Pool.Exec(ctx, `DELETE FROM users WHERE id = $1`, id)
	return err
}

func (p *PostgresRepository) RegisterDevice(ctx context.Context, d *Device) error {
	if d.ID == "" {
		d.ID = "dev_" + uuid.New().String()
	}
	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO devices (id, user_id, device_id, fcm_token, platform, model, os_version, last_active_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW())
		ON CONFLICT (user_id, device_id) 
		DO UPDATE SET fcm_token = EXCLUDED.fcm_token, model = EXCLUDED.model, os_version = EXCLUDED.os_version, last_active_at = NOW()`,
		d.ID, d.UserID, d.DeviceID, d.FCMToken, d.Platform, d.Model, d.OSVersion)
	return err
}

func (p *PostgresRepository) GetDevicesByUserID(ctx context.Context, userID string) ([]Device, error) {
	rows, err := p.db.Pool.Query(ctx, `
		SELECT id, user_id, device_id, fcm_token, platform, model, os_version, last_active_at
		FROM devices WHERE user_id = $1`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var devices []Device
	for rows.Next() {
		var d Device
		if err := rows.Scan(&d.ID, &d.UserID, &d.DeviceID, &d.FCMToken, &d.Platform, &d.Model, &d.OSVersion, &d.LastActive); err != nil {
			return nil, err
		}
		devices = append(devices, d)
	}
	return devices, nil
}
