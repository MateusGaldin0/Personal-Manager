// Package finance is the finance module of Personal Manager.
// It owns HTTP routes for transactions, accounts, categories, and budgets.
package finance

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/MateusGaldin0/personal-manager/internal/store"
)

// devUserID is the seed user inserted by migration 00002_dev_seed.sql.
// Every request is treated as this user until real auth lands.
var devUserID = uuid.MustParse("00000000-0000-0000-0000-000000000001")

// Server holds dependencies for the finance HTTP handlers.
type Server struct {
	q *store.Queries
}

// New builds a finance Server backed by the given Postgres pool.
func New(pool *pgxpool.Pool) *Server {
	return &Server{q: store.New(pool)}
}

// Register mounts the finance routes onto the given mux.
func (s *Server) Register(mux *http.ServeMux) {
	mux.HandleFunc("POST /api/transactions", s.createTransaction)
	mux.HandleFunc("GET /api/transactions", s.listTransactions)
}

// userIDFromRequest returns the user ID for the current request.
// TODO: replace with real session lookup once auth lands.
func userIDFromRequest(r *http.Request) uuid.UUID {
	return devUserID
}

// --- response helpers ------------------------------------------------------

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		log.Printf("encode response: %v", err)
	}
}

type errorBody struct {
	Error string `json:"error"`
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, errorBody{Error: msg})
}
