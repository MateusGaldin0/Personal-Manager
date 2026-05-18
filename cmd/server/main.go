// Command server starts the Personal Manager HTTP API.
package main

import (
	"log"
	"net/http"
)

func main() {
	// http.NewServeMux is Go's built-in HTTP router. Since Go 1.22 it
	// understands method + path patterns like "GET /healthz", so you can
	// go a long way before needing any third-party router.
	mux := http.NewServeMux()

	mux.HandleFunc("GET /healthz", handleHealth)
	mux.HandleFunc("GET /version", handleVersion)
	// TODO(you): register a "GET /version" route here that points at
	// handleVersion (defined below). It's one line — copy the shape of
	// the line above.

	const addr = ":8080"
	log.Printf("personal-manager listening on http://localhost%s", addr)

	// ListenAndServe blocks forever; it only returns when something goes
	// wrong. In Go, errors are ordinary return values you check — there
	// are no exceptions. log.Fatalf prints and exits with status 1.
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatalf("server stopped: %v", err)
	}
}

// handleHealth reports that the server is up. A handler in Go is just a
// function with this exact signature: (http.ResponseWriter, *http.Request).
func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"status":"ok"}`))
}

// handleVersion should respond with the app version as JSON:
//
//	{"version":"0.1.0"}
//
// TODO(you): implement the body. Look at handleHealth for the pattern —
// set the Content-Type header, then write the JSON bytes.
func handleVersion(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"version":"0.1.0"}`))
}
