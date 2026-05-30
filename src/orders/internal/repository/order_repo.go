package repository

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/cloudstore/order-service/internal/model"
	_ "github.com/lib/pq"
)

type OrderRepository interface {
	Create(ctx context.Context, order *model.Order) error
	GetByID(ctx context.Context, id string) (*model.Order, error)
	List(ctx context.Context) ([]model.Order, error)
	Ping(ctx context.Context) error
	Close()
}

type PostgresRepo struct {
	db *sql.DB
}

func NewPostgresRepo(databaseURL string) (*PostgresRepo, error) {
	db, err := sql.Open("postgres", databaseURL)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Create orders table if not exists
	_, err = db.Exec(`
		CREATE TABLE IF NOT EXISTS orders (
			id VARCHAR(36) PRIMARY KEY,
			product_id VARCHAR(36) NOT NULL,
			quantity INTEGER NOT NULL,
			status VARCHAR(20) NOT NULL DEFAULT 'pending',
			created_at TIMESTAMP NOT NULL DEFAULT NOW(),
			updated_at TIMESTAMP NOT NULL DEFAULT NOW()
		)
	`)
	if err != nil {
		return nil, fmt.Errorf("failed to create table: %w", err)
	}

	return &PostgresRepo{db: db}, nil
}

func (r *PostgresRepo) Create(ctx context.Context, order *model.Order) error {
	_, err := r.db.ExecContext(ctx,
		"INSERT INTO orders (id, product_id, quantity, status, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6)",
		order.ID, order.ProductID, order.Quantity, order.Status, order.CreatedAt, order.UpdatedAt,
	)
	return err
}

func (r *PostgresRepo) GetByID(ctx context.Context, id string) (*model.Order, error) {
	order := &model.Order{}
	err := r.db.QueryRowContext(ctx,
		"SELECT id, product_id, quantity, status, created_at, updated_at FROM orders WHERE id = $1", id,
	).Scan(&order.ID, &order.ProductID, &order.Quantity, &order.Status, &order.CreatedAt, &order.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return order, nil
}

func (r *PostgresRepo) List(ctx context.Context) ([]model.Order, error) {
	rows, err := r.db.QueryContext(ctx, "SELECT id, product_id, quantity, status, created_at, updated_at FROM orders ORDER BY created_at DESC LIMIT 50")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var orders []model.Order
	for rows.Next() {
		var o model.Order
		if err := rows.Scan(&o.ID, &o.ProductID, &o.Quantity, &o.Status, &o.CreatedAt, &o.UpdatedAt); err != nil {
			return nil, err
		}
		orders = append(orders, o)
	}
	return orders, nil
}

func (r *PostgresRepo) Ping(ctx context.Context) error {
	return r.db.PingContext(ctx)
}

func (r *PostgresRepo) Close() {
	r.db.Close()
}
