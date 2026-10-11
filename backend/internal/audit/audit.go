package audit

import (
	"context"
	"log/slog"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/guardvarx/backend/internal/storage"
)

type AuditLog struct {
	ID           string    `json:"id"`
	ActorID      string    `json:"actor_id"`
	Action       string    `json:"action"`
	ResourceType string    `json:"resource_type"`
	ResourceID   string    `json:"resource_id"`
	IPAddress    string    `json:"ip_address,omitempty"`
	UserAgent    string    `json:"user_agent,omitempty"`
	CreatedAt    time.Time `json:"created_at"`
}

type Logger interface {
	Log(ctx context.Context, actorID, action, resourceType, resourceID, ip, userAgent string)
}

type Service struct {
	db *storage.Database
	mu sync.Mutex
}

func NewService(db *storage.Database) *Service {
	return &Service{db: db}
}

func (s *Service) Log(ctx context.Context, actorID, action, resourceType, resourceID, ip, userAgent string) {
	logEntry := AuditLog{
		ID:           "aud_" + uuid.New().String(),
		ActorID:      actorID,
		Action:       action,
		ResourceType: resourceType,
		ResourceID:   resourceID,
		IPAddress:    ip,
		UserAgent:    userAgent,
		CreatedAt:    time.Now().UTC(),
	}

	slog.Info("Audit Log",
		"audit_id", logEntry.ID,
		"actor_id", actorID,
		"action", action,
		"resource_type", resourceType,
		"resource_id", resourceID,
	)

	if s.db != nil && s.db.Pool != nil {
		go func() {
			bgCtx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			defer cancel()
			_, _ = s.db.Pool.Exec(bgCtx, `
				INSERT INTO audit_logs (id, actor_id, action, resource_type, resource_id, ip_address, user_agent, created_at)
				VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())`,
				logEntry.ID, logEntry.ActorID, logEntry.Action, logEntry.ResourceType, logEntry.ResourceID, logEntry.IPAddress, logEntry.UserAgent)
		}()
	}
}
