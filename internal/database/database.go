// Package database manages the Personal Manager PostgreSQL connection.
package database

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Connect opens a pooled connection to PostgreSQL and verifies it is
// reachable. The caller owns the returned pool and must Close it
// (typically with `defer pool.Close()` right after a successful call).
func Connect(ctx context.Context, url string) (*pgxpool.Pool, error) {
	// A connection *pool* keeps a handful of database connections open
	// and reuses them. Opening a fresh connection for every query would
	// be far too slow once the app has real traffic.
	pool, err := pgxpool.New(ctx, url)
	if err != nil {
		// %w "wraps" err: the caller gets our context ("creating
		// connection pool: ...") AND can still unwrap the original
		// cause. This is how Go builds an error trail — no stack traces.
		return nil, fmt.Errorf("creating connection pool: %w", err)
	}

	// pgxpool.New is lazy — it hasn't actually contacted the database
	// yet. Ping forces a real round-trip, so a wrong URL or a down
	// database fails loudly at startup, not on the first user request.
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel() // release the timeout's resources on every return path.

	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("pinging database: %w", err)
	}

	return pool, nil
}
