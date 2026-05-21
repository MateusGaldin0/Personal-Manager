package finance

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"

	"github.com/MateusGaldin0/personal-manager/internal/store"
)

// createTransactionRequest is the JSON shape clients send to POST /api/transactions.
// Amount is a decimal serialized as a JSON string ("12.50") to avoid float64 loss.
type createTransactionRequest struct {
	AccountID         uuid.UUID       `json:"accountId"`
	CategoryID        *uuid.UUID      `json:"categoryId"`
	Kind              string          `json:"kind"`
	Amount            decimal.Decimal `json:"amount"`
	Currency          string          `json:"currency"`
	Description       *string         `json:"description"`
	OccurredAt        time.Time       `json:"occurredAt"`
	TransferAccountID *uuid.UUID      `json:"transferAccountId"`
}

func (s *Server) createTransaction(w http.ResponseWriter, r *http.Request) {
	var req createTransactionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		return
	}

	// Light shape validation; DB constraints handle business rules.
	if req.AccountID == uuid.Nil {
		writeError(w, http.StatusBadRequest, "accountId is required")
		return
	}
	if !req.Amount.IsPositive() {
		writeError(w, http.StatusBadRequest, "amount must be positive")
		return
	}
	if req.Currency == "" {
		writeError(w, http.StatusBadRequest, "currency is required")
		return
	}
	if req.OccurredAt.IsZero() {
		req.OccurredAt = time.Now().UTC()
	}

	tx, err := s.q.CreateTransaction(r.Context(), store.CreateTransactionParams{
		UserID:            userIDFromRequest(r),
		AccountID:         req.AccountID,
		CategoryID:        req.CategoryID,
		Kind:              store.TransactionKind(req.Kind),
		Amount:            req.Amount,
		Currency:          req.Currency,
		Description:       req.Description,
		OccurredAt:        req.OccurredAt,
		TransferAccountID: req.TransferAccountID,
	})
	if err != nil {
		log.Printf("create transaction: %v", err)
		writeError(w, http.StatusInternalServerError, "failed to create transaction")
		return
	}

	writeJSON(w, http.StatusCreated, tx)
}

func (s *Server) listTransactions(w http.ResponseWriter, r *http.Request) {
	limit := int32(50)
	if v := r.URL.Query().Get("limit"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 && n <= 500 {
			limit = int32(n)
		}
	}
	offset := int32(0)
	if v := r.URL.Query().Get("offset"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n >= 0 {
			offset = int32(n)
		}
	}

	txns, err := s.q.ListTransactions(r.Context(), store.ListTransactionsParams{
		UserID: userIDFromRequest(r),
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		log.Printf("list transactions: %v", err)
		writeError(w, http.StatusInternalServerError, "failed to list transactions")
		return
	}

	if txns == nil {
		txns = []store.Transaction{} // ensure JSON `[]` not `null`
	}
	writeJSON(w, http.StatusOK, txns)
}
