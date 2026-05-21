-- +goose Up
-- Dev seed: one user with a default account and starter Brazilian categories.
-- Fixed UUIDs so application code can hard-code references during early dev.
-- Idempotent via ON CONFLICT DO NOTHING. Will be replaced by real signup later.

INSERT INTO users (id, email, password_hash, display_name, base_currency)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'me@personal-manager.local',
    -- bcrypt hash of "password" (cost 10). Placeholder until auth lands.
    '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',
    'Me',
    'BRL'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO accounts (id, user_id, name, type, currency, initial_balance)
VALUES (
    '00000000-0000-0000-0000-000000000101',
    '00000000-0000-0000-0000-000000000001',
    'Conta Corrente',
    'checking',
    'BRL',
    0
) ON CONFLICT (id) DO NOTHING;

INSERT INTO categories (id, user_id, name, kind) VALUES
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', 'Salário',      'income'),
    ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000001', 'Mercado',      'expense'),
    ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000001', 'Restaurantes', 'expense'),
    ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000001', 'Transporte',   'expense'),
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000001', 'Moradia',      'expense'),
    ('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000001', 'Lazer',        'expense')
ON CONFLICT (id) DO NOTHING;

-- +goose Down
DELETE FROM categories WHERE user_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM accounts   WHERE user_id = '00000000-0000-0000-0000-000000000001';
DELETE FROM users      WHERE id      = '00000000-0000-0000-0000-000000000001';
