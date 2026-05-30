package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/cloudstore/order-service/internal/model"
	"github.com/cloudstore/order-service/internal/repository"
	"github.com/google/uuid"
	"github.com/gorilla/mux"
)

type OrderHandler struct {
	repo              repository.OrderRepository
	productCatalogURL string
}

func NewOrderHandler(repo repository.OrderRepository, catalogURL string) *OrderHandler {
	return &OrderHandler{repo: repo, productCatalogURL: catalogURL}
}

func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
	var req model.CreateOrderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid request body"})
		return
	}

	if req.ProductID == "" || req.Quantity <= 0 || req.Quantity > 100 {
		respondJSON(w, http.StatusBadRequest, map[string]string{"error": "productId required, quantity must be 1-100"})
		return
	}

	order := model.Order{
		ID:        uuid.New().String(),
		ProductID: req.ProductID,
		Quantity:  req.Quantity,
		Status:    "pending",
		CreatedAt: time.Now().UTC(),
		UpdatedAt: time.Now().UTC(),
	}

	if err := h.repo.Create(r.Context(), &order); err != nil {
		log.Printf("ERROR: failed to create order: %v", err)
		respondJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to create order"})
		return
	}

	log.Printf("INFO: order created id=%s product=%s quantity=%d", order.ID, order.ProductID, order.Quantity)
	respondJSON(w, http.StatusCreated, order)
}

func (h *OrderHandler) GetOrder(w http.ResponseWriter, r *http.Request) {
	id := mux.Vars(r)["id"]

	order, err := h.repo.GetByID(r.Context(), id)
	if err != nil {
		log.Printf("ERROR: failed to get order %s: %v", id, err)
		respondJSON(w, http.StatusNotFound, map[string]string{"error": "order not found"})
		return
	}

	respondJSON(w, http.StatusOK, order)
}

func (h *OrderHandler) ListOrders(w http.ResponseWriter, r *http.Request) {
	orders, err := h.repo.List(r.Context())
	if err != nil {
		log.Printf("ERROR: failed to list orders: %v", err)
		respondJSON(w, http.StatusInternalServerError, map[string]string{"error": "failed to list orders"})
		return
	}

	respondJSON(w, http.StatusOK, orders)
}

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
