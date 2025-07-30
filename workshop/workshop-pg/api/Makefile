.PHONY: help build run test clean docker-up docker-down migrate

# Variables
APP_NAME=order-api
GO_FILES=$(shell find . -name "*.go" -type f)

help: ## Show this help
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

build: ## Build the application
	go build -o bin/$(APP_NAME) main.go

run: ## Run the application
	go run main.go

test: ## Run tests
	go test -v ./...

clean: ## Clean build artifacts
	rm -rf bin/

docker-up: ## Start PostgreSQL with Docker Compose
	docker-compose up -d

docker-down: ## Stop PostgreSQL Docker containers
	docker-compose down

docker-logs: ## Show PostgreSQL logs
	docker-compose logs -f postgres

migrate: ## Run database migrations manually
	@echo "Make sure PostgreSQL is running..."
	@echo "Running migrations..."
	psql -h localhost -U postgres -d workshop_db -f migrations/001_init.sql

deps: ## Download dependencies
	go mod tidy
	go mod download

format: ## Format Go code
	go fmt ./...

lint: ## Run golangci-lint
	golangci-lint run

dev: docker-up ## Start development environment
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	@echo "Running migrations..."
	@make migrate || true
	@echo "Starting the application..."
	@make run

production-build: ## Build for production
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/$(APP_NAME) main.go

# Database management
db-reset: ## Reset database (WARNING: This will delete all data)
	docker-compose down -v
	docker-compose up -d
	@sleep 5
	@make migrate

db-shell: ## Connect to database shell
	docker exec -it workshop_postgres psql -U postgres -d workshop_db
