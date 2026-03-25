.PHONY: setup generate run db-up db-down db-reset help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

db-up: ## Start Postgres
	docker compose up -d
	@until docker compose exec postgres pg_isready -U app -d app -q 2>/dev/null; do sleep 1; done
	@echo "  Postgres is ready"

db-down: ## Stop Postgres
	docker compose down

db-reset: db-up ## Reset database and apply schema
	docker exec -i $$(docker compose ps -q postgres) psql -U app -d app < schema.sql
	@echo "  Schema applied"

generate: ## Run bob + kiln plugin to generate code
	set -a && . ./.env && set +a && go run gen/main.go
	go mod tidy

setup: db-reset generate ## Full setup: database + code generation
	@echo ""
	@echo "  Ready. Run: make run"

run: ## Start the server
	set -a && . ./.env && set +a && go run cmd/server/main.go
