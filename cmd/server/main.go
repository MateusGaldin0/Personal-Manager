// Command server runs the Personal Manager HTTP API.
package main

import (
	"context"
	"log"
	"net/http"
	"os"

	"github.com/MateusGaldin0/personal-manager/internal/database"
	"github.com/MateusGaldin0/personal-manager/internal/finance"
)

const defaultDatabaseURL = "postgres://pm:pm_dev_password@localhost:5434/personal_manager"

func main() {
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = defaultDatabaseURL
	}

	pool, err := database.Connect(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("database: %v", err)
	}
	defer pool.Close()
	log.Println("database: connected")

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", handleHealth)
	mux.HandleFunc("GET /version", handleVersion)
	finance.New(pool).Register(mux)

	const addr = ":8080"
	log.Printf("personal-manager listening on http://localhost%s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("server stopped: %v", err)
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"ok"}`))
}

func handleVersion(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"version":"0.1.0"}`))
}
