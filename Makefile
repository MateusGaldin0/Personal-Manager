DB_URL          ?= postgres://pm:pm_dev_password@localhost:5434/personal_manager
MIGRATIONS_DIR  := ./internal/database/migrations
GOOSE           := go run github.com/pressly/goose/v3/cmd/goose@latest

.PHONY: run db.up db.down db.psql migrate.up migrate.down migrate.status migrate.create

# --- application -----------------------------------------------------------
run:                   ## Run the API server.
	go run ./cmd/server

# --- database lifecycle ----------------------------------------------------
db.up:                 ## Start the local Postgres container.
	docker compose up -d

db.down:               ## Stop the local Postgres container (data is preserved).
	docker compose down

db.psql:               ## Open a psql shell against the local Postgres.
	psql "$(DB_URL)"

# --- migrations ------------------------------------------------------------
migrate.up:            ## Apply all pending migrations.
	$(GOOSE) -dir $(MIGRATIONS_DIR) postgres "$(DB_URL)" up

migrate.down:          ## Roll back the most recent migration.
	$(GOOSE) -dir $(MIGRATIONS_DIR) postgres "$(DB_URL)" down

migrate.status:        ## Show which migrations have been applied.
	$(GOOSE) -dir $(MIGRATIONS_DIR) postgres "$(DB_URL)" status

migrate.create:        ## Create a new empty migration. Usage: make migrate.create name=add_foo
	@test -n "$(name)" || (echo "usage: make migrate.create name=<snake_case_name>" && exit 1)
	$(GOOSE) -dir $(MIGRATIONS_DIR) create $(name) sql

# --- code generation -------------------------------------------------------
sqlc.gen:              ## Regenerate type-safe Go from internal/store/queries/*.sql.
	go run github.com/sqlc-dev/sqlc/cmd/sqlc@latest generate
