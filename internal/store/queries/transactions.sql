-- name: CreateTransaction :one
INSERT INTO transactions (
    user_id, account_id, category_id, kind, amount, currency,
    description, occurred_at, transfer_account_id
) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- name: ListTransactions :many
SELECT * FROM transactions
WHERE user_id = $1
ORDER BY occurred_at DESC, created_at DESC
LIMIT $2 OFFSET $3;

-- name: GetTransaction :one
SELECT * FROM transactions WHERE id = $1 AND user_id = $2;

-- name: DeleteTransaction :exec
DELETE FROM transactions WHERE id = $1 AND user_id = $2;
