-- name: ListCategories :many
SELECT * FROM categories
WHERE user_id = $1 AND archived_at IS NULL
ORDER BY kind, name;

-- name: GetCategory :one
SELECT * FROM categories WHERE id = $1 AND user_id = $2;
