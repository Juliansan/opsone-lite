.PHONY: up down reset factory_reset logs health test inject-failure recover-failure psql

up:
	docker compose up -d

down:
	docker compose down

reset:
	docker compose down -v
	docker compose up -d

logs:
	docker compose logs -f postgres

psql:
	docker exec -it opsone_postgres -U opsone -d commerce

health:
	python -m opsone_lite.source_health

test:
	pytest -q

inject-failure:
	docker exec -i opsone_postgres psql -U opsone -d commerce < scripts/inject_week_01_failure.sql

recover-failure:
	docker exec -i opsone_postgres psql -U opsone -d commerce < scripts/recover_week_01_failure.sql