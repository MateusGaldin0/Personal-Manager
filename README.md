# Personal Manager

A central hub for productivity hackers — work, routines, finance, reading,
habits, and goals, all in one app.

This repo doubles as a Go learning project. It's built as a **modular
monolith**: one deployable binary and one database, with each domain
(habits, tasks, finance, …) living in its own self-contained package under
`internal/`.

## Stack

- **Language:** Go 1.26
- **HTTP:** standard library `net/http` (no framework)
- **Database:** PostgreSQL (introduced in Phase 1)

## Layout

- `cmd/server/` — the runnable program (the `main` package)
- `internal/`   — application code. Packages under `internal/` can't be
                  imported by other repositories, which keeps the API
                  surface private by default.

## Roadmap

- [x] **Phase 0** — project skeleton + running HTTP server
- [ ] **Phase 1** — PostgreSQL, migrations, `users` table
- [ ] **Phase 2** — auth (signup / login)
- [ ] **Phase 3** — first feature module: Habits
- [ ] **Phase 4** — second module: Tasks (proves the modular pattern)
- [ ] **Later** — finance, reading tracker, goals, routines

## Run

```sh
go run ./cmd/server
# in another terminal:
curl localhost:8080/healthz
```
