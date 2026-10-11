package emergencies

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

// Delivery and incident states
const (
	StateCreated                      = "CREATED"
	StateLocalSaved                   = "LOCAL_SAVED"
	StateQueued                       = "QUEUED"
	StateSending                      = "SENDING"
	StateRelaying                     = "RELAYING"
	StateServerReceived               = "SERVER_RECEIVED"
	StateContactNotificationRequested = "CONTACT_NOTIFICATION_REQUESTED"
	StateContactAcknowledged          = "CONTACT_ACKNOWLEDGED"
	StateHelperAccepted               = "HELPER_ACCEPTED"
	StateHelperEnRoute                = "HELPER_EN_ROUTE"
	StateHelperArrived                = "HELPER_ARRIVED"
	StateResolved                     = "RESOLVED"
	StateCancelled                    = "CANCELLED"
	StateExpired                      = "EXPIRED"
	StateFailed                       = "FAILED"
	StateNoRoute                      = "NO_ROUTE"
)

var (
	ErrIncidentNotFound        = errors.New("incident not found")
	ErrInvalidStateTransition  = errors.New("invalid incident state transition")
	ErrUnauthorized            = errors.New("unauthorized incident modification")
	ErrDuplicateIdempotencyKey = errors.New("duplicate idempotency key")
)

type Incident struct {
	IncidentID        string    `json:"incident_id"`
	IdempotencyKey    string    `json:"idempotency_key,omitempty"`
	SenderID          string    `json:"sender_id"`
	EmergencyType     string    `json:"emergency_type"`
	Message           string    `json:"message,omitempty"`
	Status            string    `json:"status"`
	Latitude          float64   `json:"latitude"`
	Longitude         float64   `json:"longitude"`
	AccuracyMeters    float64   `json:"accuracy_meters"`
	LocationTimestamp time.Time `json:"location_timestamp"`
	Priority          string    `json:"priority"`
	ProtocolVersion   int       `json:"protocol_version"`
	ReceiptID         string    `json:"receipt_id"`
	CancelledReason   string    `json:"cancelled_reason,omitempty"`
	CancelledAt       *time.Time`json:"cancelled_at,omitempty"`
	ResolvedAt        *time.Time`json:"resolved_at,omitempty"`
	ExpiresAt         time.Time `json:"expires_at"`
	CreatedAt         time.Time `json:"created_at"`
	UpdatedAt         time.Time `json:"updated_at"`
}

type IncidentEvent struct {
	ID             string         `json:"id"`
	IncidentID     string         `json:"incident_id"`
	PreviousStatus string         `json:"previous_status"`
	NewStatus      string         `json:"new_status"`
	ActorID        string         `json:"actor_id"`
	Metadata       map[string]any `json:"metadata,omitempty"`
	CreatedAt      time.Time      `json:"created_at"`
}

type DeliveryAck struct {
	ID              string    `json:"id"`
	IncidentID      string    `json:"incident_id"`
	ContactID       string    `json:"contact_id,omitempty"`
	RecipientPhone  string    `json:"recipient_phone,omitempty"`
	DeliveryChannel string    `json:"delivery_channel"`
	AcknowledgedAt  time.Time `json:"acknowledged_at"`
}

// IsValidTransition strictly enforces the delivery state machine
func IsValidTransition(from, to string) bool {
	if from == to {
		return true
	}
	// Terminal states cannot transition
	if from == StateResolved || from == StateCancelled || from == StateExpired {
		return false
	}

	validTransitions := map[string][]string{
		StateCreated:                      {StateLocalSaved, StateQueued, StateSending, StateRelaying, StateServerReceived, StateCancelled},
		StateLocalSaved:                   {StateQueued, StateSending, StateRelaying, StateCancelled},
		StateQueued:                       {StateSending, StateRelaying, StateFailed, StateNoRoute, StateCancelled},
		StateSending:                      {StateServerReceived, StateFailed, StateCancelled},
		StateRelaying:                     {StateServerReceived, StateNoRoute, StateFailed, StateCancelled},
		StateServerReceived:               {StateContactNotificationRequested, StateContactAcknowledged, StateHelperAccepted, StateResolved, StateCancelled, StateExpired},
		StateContactNotificationRequested: {StateContactAcknowledged, StateHelperAccepted, StateResolved, StateCancelled, StateExpired},
		StateContactAcknowledged:          {StateHelperAccepted, StateResolved, StateCancelled, StateExpired},
		StateHelperAccepted:               {StateHelperEnRoute, StateResolved, StateCancelled, StateExpired},
		StateHelperEnRoute:                {StateHelperArrived, StateResolved, StateCancelled, StateExpired},
		StateHelperArrived:                {StateResolved, StateCancelled, StateExpired},
		StateFailed:                       {StateQueued, StateSending, StateCancelled},
		StateNoRoute:                      {StateQueued, StateRelaying, StateCancelled},
	}

	allowed, ok := validTransitions[from]
	if !ok {
		return false
	}
	for _, s := range allowed {
		if s == to {
			return true
		}
	}
	return false
}

type Repository interface {
	Create(ctx context.Context, inc *Incident) error
	GetByID(ctx context.Context, incidentID string) (*Incident, error)
	GetByIdempotencyKey(ctx context.Context, key string) (*Incident, error)
	UpdateStatus(ctx context.Context, incidentID, newStatus, actorID string, meta map[string]any) error
	Cancel(ctx context.Context, incidentID, userID, reason string) error
	Resolve(ctx context.Context, incidentID, userID string) error
	AddAcknowledgement(ctx context.Context, ack *DeliveryAck) error
	ListAcks(ctx context.Context, incidentID string) ([]DeliveryAck, error)
	ListEvents(ctx context.Context, incidentID string) ([]IncidentEvent, error)
}

// MemoryRepository for testing and mock mode
type MemoryRepository struct {
	mu           sync.RWMutex
	incidents    map[string]*Incident
	byKey        map[string]string
	events       map[string][]IncidentEvent
	acks         map[string][]DeliveryAck
}

func NewMemoryRepository() *MemoryRepository {
	return &MemoryRepository{
		incidents: make(map[string]*Incident),
		byKey:     make(map[string]string),
		events:    make(map[string][]IncidentEvent),
		acks:      make(map[string][]DeliveryAck),
	}
}

func (m *MemoryRepository) Create(ctx context.Context, inc *Incident) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if inc.IdempotencyKey != "" {
		if existingID, exists := m.byKey[inc.IdempotencyKey]; exists {
			*inc = *m.incidents[existingID]
			return nil
		}
	}

	if inc.IncidentID == "" {
		inc.IncidentID = "inc_" + uuid.New().String()
	}
	inc.ReceiptID = "rcpt_" + uuid.New().String()
	inc.Status = StateServerReceived
	inc.CreatedAt = time.Now().UTC()
	inc.UpdatedAt = time.Now().UTC()
	if inc.ExpiresAt.IsZero() {
		inc.ExpiresAt = inc.CreatedAt.Add(24 * time.Hour)
	}

	m.incidents[inc.IncidentID] = inc
	if inc.IdempotencyKey != "" {
		m.byKey[inc.IdempotencyKey] = inc.IncidentID
	}

	// Record initial creation event
	ev := IncidentEvent{
		ID:         "ev_" + uuid.New().String(),
		IncidentID: inc.IncidentID,
		NewStatus:  StateServerReceived,
		ActorID:    inc.SenderID,
		CreatedAt:  time.Now().UTC(),
	}
	m.events[inc.IncidentID] = append(m.events[inc.IncidentID], ev)

	return nil
}

func (m *MemoryRepository) GetByID(ctx context.Context, incidentID string) (*Incident, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	inc, ok := m.incidents[incidentID]
	if !ok {
		return nil, ErrIncidentNotFound
	}
	cpy := *inc
	return &cpy, nil
}

func (m *MemoryRepository) GetByIdempotencyKey(ctx context.Context, key string) (*Incident, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	id, ok := m.byKey[key]
	if !ok {
		return nil, ErrIncidentNotFound
	}
	return m.GetByID(ctx, id)
}

func (m *MemoryRepository) UpdateStatus(ctx context.Context, incidentID, newStatus, actorID string, meta map[string]any) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	inc, ok := m.incidents[incidentID]
	if !ok {
		return ErrIncidentNotFound
	}

	if !IsValidTransition(inc.Status, newStatus) {
		return fmt.Errorf("%w: cannot transition from %s to %s", ErrInvalidStateTransition, inc.Status, newStatus)
	}

	prev := inc.Status
	inc.Status = newStatus
	inc.UpdatedAt = time.Now().UTC()

	ev := IncidentEvent{
		ID:             "ev_" + uuid.New().String(),
		IncidentID:     incidentID,
		PreviousStatus: prev,
		NewStatus:      newStatus,
		ActorID:        actorID,
		Metadata:       meta,
		CreatedAt:      time.Now().UTC(),
	}
	m.events[incidentID] = append(m.events[incidentID], ev)
	return nil
}

func (m *MemoryRepository) Cancel(ctx context.Context, incidentID, userID, reason string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	inc, ok := m.incidents[incidentID]
	if !ok {
		return ErrIncidentNotFound
	}
	if inc.SenderID != userID && userID != "admin" {
		return ErrUnauthorized
	}
	if !IsValidTransition(inc.Status, StateCancelled) {
		return fmt.Errorf("%w: cannot cancel incident in %s state", ErrInvalidStateTransition, inc.Status)
	}

	now := time.Now().UTC()
	inc.Status = StateCancelled
	inc.CancelledReason = reason
	inc.CancelledAt = &now
	inc.UpdatedAt = now

	ev := IncidentEvent{
		ID:         "ev_" + uuid.New().String(),
		IncidentID: incidentID,
		NewStatus:  StateCancelled,
		ActorID:    userID,
		Metadata:   map[string]any{"reason": reason},
		CreatedAt:  now,
	}
	m.events[incidentID] = append(m.events[incidentID], ev)
	return nil
}

func (m *MemoryRepository) Resolve(ctx context.Context, incidentID, userID string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	inc, ok := m.incidents[incidentID]
	if !ok {
		return ErrIncidentNotFound
	}
	if !IsValidTransition(inc.Status, StateResolved) {
		return fmt.Errorf("%w: cannot resolve incident in %s state", ErrInvalidStateTransition, inc.Status)
	}

	now := time.Now().UTC()
	inc.Status = StateResolved
	inc.ResolvedAt = &now
	inc.UpdatedAt = now

	ev := IncidentEvent{
		ID:         "ev_" + uuid.New().String(),
		IncidentID: incidentID,
		NewStatus:  StateResolved,
		ActorID:    userID,
		CreatedAt:  now,
	}
	m.events[incidentID] = append(m.events[incidentID], ev)
	return nil
}

func (m *MemoryRepository) AddAcknowledgement(ctx context.Context, ack *DeliveryAck) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if ack.ID == "" {
		ack.ID = "ack_" + uuid.New().String()
	}
	ack.AcknowledgedAt = time.Now().UTC()
	m.acks[ack.IncidentID] = append(m.acks[ack.IncidentID], *ack)
	return nil
}

func (m *MemoryRepository) ListAcks(ctx context.Context, incidentID string) ([]DeliveryAck, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return append([]DeliveryAck(nil), m.acks[incidentID]...), nil
}

func (m *MemoryRepository) ListEvents(ctx context.Context, incidentID string) ([]IncidentEvent, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return append([]IncidentEvent(nil), m.events[incidentID]...), nil
}

// PostgresRepository implementation
type PostgresRepository struct {
	db *storage.Database
}

func NewPostgresRepository(db *storage.Database) *PostgresRepository {
	return &PostgresRepository{db: db}
}

func (p *PostgresRepository) Create(ctx context.Context, inc *Incident) error {
	if inc.IncidentID == "" {
		inc.IncidentID = "inc_" + uuid.New().String()
	}
	inc.ReceiptID = "rcpt_" + uuid.New().String()
	inc.Status = StateServerReceived
	if inc.ExpiresAt.IsZero() {
		inc.ExpiresAt = time.Now().UTC().Add(24 * time.Hour)
	}

	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO emergency_incidents (
			incident_id, idempotency_key, sender_id, emergency_type, message, status,
			latitude, longitude, accuracy_meters, location_timestamp, priority, protocol_version,
			receipt_id, expires_at, created_at, updated_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, NOW(), NOW())
		ON CONFLICT (idempotency_key) DO NOTHING`,
		inc.IncidentID, inc.IdempotencyKey, inc.SenderID, inc.EmergencyType, inc.Message, inc.Status,
		inc.Latitude, inc.Longitude, inc.AccuracyMeters, inc.LocationTimestamp, inc.Priority, inc.ProtocolVersion,
		inc.ReceiptID, inc.ExpiresAt)
	return err
}

func (p *PostgresRepository) GetByID(ctx context.Context, incidentID string) (*Incident, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT incident_id, COALESCE(idempotency_key, ''), sender_id, emergency_type, COALESCE(message, ''),
		       status, latitude, longitude, accuracy_meters, location_timestamp, priority, protocol_version,
		       receipt_id, COALESCE(cancelled_reason, ''), cancelled_at, resolved_at, expires_at, created_at, updated_at
		FROM emergency_incidents WHERE incident_id = $1`, incidentID)
	var inc Incident
	err := row.Scan(&inc.IncidentID, &inc.IdempotencyKey, &inc.SenderID, &inc.EmergencyType, &inc.Message,
		&inc.Status, &inc.Latitude, &inc.Longitude, &inc.AccuracyMeters, &inc.LocationTimestamp, &inc.Priority,
		&inc.ProtocolVersion, &inc.ReceiptID, &inc.CancelledReason, &inc.CancelledAt, &inc.ResolvedAt,
		&inc.ExpiresAt, &inc.CreatedAt, &inc.UpdatedAt)
	if err != nil {
		return nil, ErrIncidentNotFound
	}
	return &inc, nil
}

func (p *PostgresRepository) GetByIdempotencyKey(ctx context.Context, key string) (*Incident, error) {
	row := p.db.Pool.QueryRow(ctx, `
		SELECT incident_id, COALESCE(idempotency_key, ''), sender_id, emergency_type, COALESCE(message, ''),
		       status, latitude, longitude, accuracy_meters, location_timestamp, priority, protocol_version,
		       receipt_id, COALESCE(cancelled_reason, ''), cancelled_at, resolved_at, expires_at, created_at, updated_at
		FROM emergency_incidents WHERE idempotency_key = $1`, key)
	var inc Incident
	err := row.Scan(&inc.IncidentID, &inc.IdempotencyKey, &inc.SenderID, &inc.EmergencyType, &inc.Message,
		&inc.Status, &inc.Latitude, &inc.Longitude, &inc.AccuracyMeters, &inc.LocationTimestamp, &inc.Priority,
		&inc.ProtocolVersion, &inc.ReceiptID, &inc.CancelledReason, &inc.CancelledAt, &inc.ResolvedAt,
		&inc.ExpiresAt, &inc.CreatedAt, &inc.UpdatedAt)
	if err != nil {
		return nil, ErrIncidentNotFound
	}
	return &inc, nil
}

func (p *PostgresRepository) UpdateStatus(ctx context.Context, incidentID, newStatus, actorID string, meta map[string]any) error {
	inc, err := p.GetByID(ctx, incidentID)
	if err != nil {
		return err
	}
	if !IsValidTransition(inc.Status, newStatus) {
		return fmt.Errorf("%w: cannot transition from %s to %s", ErrInvalidStateTransition, inc.Status, newStatus)
	}

	_, err = p.db.Pool.Exec(ctx, `
		UPDATE emergency_incidents SET status = $2, updated_at = NOW() WHERE incident_id = $1`,
		incidentID, newStatus)
	if err != nil {
		return err
	}

	_, _ = p.db.Pool.Exec(ctx, `
		INSERT INTO incident_events (id, incident_id, previous_status, new_status, actor_id, created_at)
		VALUES ($1, $2, $3, $4, $5, NOW())`,
		"ev_"+uuid.New().String(), incidentID, inc.Status, newStatus, actorID)
	return nil
}

func (p *PostgresRepository) Cancel(ctx context.Context, incidentID, userID, reason string) error {
	inc, err := p.GetByID(ctx, incidentID)
	if err != nil {
		return err
	}
	if inc.SenderID != userID && userID != "admin" {
		return ErrUnauthorized
	}
	if !IsValidTransition(inc.Status, StateCancelled) {
		return fmt.Errorf("%w: cannot cancel incident in %s state", ErrInvalidStateTransition, inc.Status)
	}

	_, err = p.db.Pool.Exec(ctx, `
		UPDATE emergency_incidents 
		SET status = $2, cancelled_reason = $3, cancelled_at = NOW(), updated_at = NOW()
		WHERE incident_id = $1`,
		incidentID, StateCancelled, reason)
	return err
}

func (p *PostgresRepository) Resolve(ctx context.Context, incidentID, userID string) error {
	inc, err := p.GetByID(ctx, incidentID)
	if err != nil {
		return err
	}
	if !IsValidTransition(inc.Status, StateResolved) {
		return fmt.Errorf("%w: cannot resolve incident in %s state", ErrInvalidStateTransition, inc.Status)
	}

	_, err = p.db.Pool.Exec(ctx, `
		UPDATE emergency_incidents 
		SET status = $2, resolved_at = NOW(), updated_at = NOW()
		WHERE incident_id = $1`,
		incidentID, StateResolved)
	return err
}

func (p *PostgresRepository) AddAcknowledgement(ctx context.Context, ack *DeliveryAck) error {
	if ack.ID == "" {
		ack.ID = "ack_" + uuid.New().String()
	}
	_, err := p.db.Pool.Exec(ctx, `
		INSERT INTO delivery_acknowledgements (id, incident_id, contact_id, recipient_phone, delivery_channel, acknowledged_at)
		VALUES ($1, $2, $3, $4, $5, NOW())`,
		ack.ID, ack.IncidentID, ack.ContactID, ack.RecipientPhone, ack.DeliveryChannel)
	return err
}

func (p *PostgresRepository) ListAcks(ctx context.Context, incidentID string) ([]DeliveryAck, error) {
	rows, err := p.db.Pool.Query(ctx, `
		SELECT id, incident_id, contact_id, recipient_phone, delivery_channel, acknowledged_at
		FROM delivery_acknowledgements WHERE incident_id = $1`, incidentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var acks []DeliveryAck
	for rows.Next() {
		var a DeliveryAck
		if err := rows.Scan(&a.ID, &a.IncidentID, &a.ContactID, &a.RecipientPhone, &a.DeliveryChannel, &a.AcknowledgedAt); err != nil {
			return nil, err
		}
		acks = append(acks, a)
	}
	return acks, nil
}

func (p *PostgresRepository) ListEvents(ctx context.Context, incidentID string) ([]IncidentEvent, error) {
	rows, err := p.db.Pool.Query(ctx, `
		SELECT id, incident_id, previous_status, new_status, actor_id, created_at
		FROM incident_events WHERE incident_id = $1 ORDER BY created_at ASC`, incidentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []IncidentEvent
	for rows.Next() {
		var ev IncidentEvent
		if err := rows.Scan(&ev.ID, &ev.IncidentID, &ev.PreviousStatus, &ev.NewStatus, &ev.ActorID, &ev.CreatedAt); err != nil {
			return nil, err
		}
		events = append(events, ev)
	}
	return events, nil
}
