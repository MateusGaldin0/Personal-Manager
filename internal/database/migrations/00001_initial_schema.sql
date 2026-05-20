-- +goose Up
-- Initial finance schema: users, accounts, categories, transactions, budgets.
-- Multi-tenant by design: every domain row carries user_id and cascades on delete.

CREATE EXTENSION IF NOT EXISTS citext;

-- ---------------------------------------------------------------------------
-- users
-- ---------------------------------------------------------------------------
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           CITEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    display_name    TEXT,
    base_currency   CHAR(3) NOT NULL DEFAULT 'BRL',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- accounts (checking, savings, credit cards, cash, investments, loans)
-- ---------------------------------------------------------------------------
CREATE TYPE account_type AS ENUM (
    'checking', 'savings', 'credit_card', 'cash', 'investment', 'loan', 'other'
);

CREATE TABLE accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    type            account_type NOT NULL,
    currency        CHAR(3) NOT NULL,
    initial_balance NUMERIC(19,4) NOT NULL DEFAULT 0,
    archived_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX accounts_user_id_idx ON accounts(user_id);

-- ---------------------------------------------------------------------------
-- categories (hierarchical: e.g. "Food" > "Groceries")
-- ---------------------------------------------------------------------------
CREATE TYPE category_kind AS ENUM ('income', 'expense');

CREATE TABLE categories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    kind        category_kind NOT NULL,
    parent_id   UUID REFERENCES categories(id) ON DELETE SET NULL,
    color       TEXT,
    icon        TEXT,
    archived_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX categories_user_id_idx ON categories(user_id);

-- ---------------------------------------------------------------------------
-- transactions
-- Amount is always positive; the kind (income / expense / transfer) provides
-- the semantics. transfer_account_id is the destination account for transfers.
-- external_id / external_source are for future bank-sync (Pluggy) imports.
-- ---------------------------------------------------------------------------
CREATE TYPE transaction_kind AS ENUM ('income', 'expense', 'transfer');

CREATE TABLE transactions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    account_id          UUID NOT NULL REFERENCES accounts(id) ON DELETE RESTRICT,
    category_id         UUID REFERENCES categories(id) ON DELETE SET NULL,
    kind                transaction_kind NOT NULL,
    amount              NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency            CHAR(3) NOT NULL,
    description         TEXT,
    occurred_at         TIMESTAMPTZ NOT NULL,
    transfer_account_id UUID REFERENCES accounts(id) ON DELETE RESTRICT,
    external_id         TEXT,
    external_source     TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK ((kind = 'transfer') = (transfer_account_id IS NOT NULL)),
    CHECK (transfer_account_id IS NULL OR transfer_account_id <> account_id)
);
CREATE INDEX transactions_user_id_occurred_at_idx
    ON transactions(user_id, occurred_at DESC);
CREATE INDEX transactions_account_id_idx ON transactions(account_id);
CREATE UNIQUE INDEX transactions_external_unique_idx
    ON transactions(external_source, external_id)
    WHERE external_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- budgets (per category, per calendar month, in the category's currency)
-- ---------------------------------------------------------------------------
CREATE TABLE budgets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id     UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    amount          NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency        CHAR(3) NOT NULL,
    period_start    DATE NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, category_id, period_start),
    CHECK (EXTRACT(DAY FROM period_start) = 1)
);
CREATE INDEX budgets_user_id_period_idx ON budgets(user_id, period_start);

-- +goose Down
DROP TABLE IF EXISTS budgets;
DROP TABLE IF EXISTS transactions;
DROP TYPE  IF EXISTS transaction_kind;
DROP TABLE IF EXISTS categories;
DROP TYPE  IF EXISTS category_kind;
DROP TABLE IF EXISTS accounts;
DROP TYPE  IF EXISTS account_type;
DROP TABLE IF EXISTS users;
