-- name: ListAccounts :many
SELECT * FROM accounts
WHERE user_id = $1 AND archived_at IS NULL
ORDER BY created_at;

-- name: GetAccount :one
SELECT * FROM accounts WHERE id = $1 AND user_id = $2;
