package storage

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"github.com/guardvarx/backend/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Database struct {
	Pool *pgxpool.Pool
}

func NewDatabase(ctx context.Context, cfg *config.Config) (*Database, error) {
	poolCfg, err := pgxpool.ParseConfig(cfg.DatabaseURL())
	if err != nil {
		return nil, fmt.Errorf("failed to parse database config: %w", err)
	}

	poolCfg.MaxConns = cfg.DBMaxConns
	poolCfg.MinConns = cfg.DBMinConns
	poolCfg.MaxConnLifetime = cfg.DBMaxConnLifetime

	connCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(connCtx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to postgres: %w", err)
	}

	if err := pool.Ping(connCtx); err != nil {
		slog.Warn("PostgreSQL ping failed, operating in offline/mock storage mode", "error", err)
		return &Database{Pool: nil}, nil
	}

	slog.Info("PostgreSQL connection established successfully", "host", cfg.DBHost, "database", cfg.DBName)
	return &Database{Pool: pool}, nil
}

func (d *Database) Close() {
	if d.Pool != nil {
		d.Pool.Close()
	}
}

func (d *Database) IsReady(ctx context.Context) bool {
	if d.Pool == nil {
		return false
	}
	ctxTimeout, cancel := context.WithTimeout(ctx, 2*time.Second)
	defer cancel()
	return d.Pool.Ping(ctxTimeout) == nil
}
