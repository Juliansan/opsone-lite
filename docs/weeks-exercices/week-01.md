# Week 1 — OpsOne Lite Foundation

## Theme

**Build the local source system and the first DataOps control.**

Week 1 is deliberately simple. We are not starting with dbt, Airflow, Spark, Kafka, a catalog, dashboards, agents, or cloud infrastructure.

The goal is to create the first stable building block of **OpsOne Lite**: a local operational commerce source system that later weeks can ingest, transform, orchestrate, observe, govern, and cost-analyze.

This week should feel like setting the rails correctly, not building the train station.

---

## Week 1 outcome

By the end of Week 1, the repository should contain:

1. A clean project skeleton.
2. A local Postgres source database running with Docker Compose.
3. A small commerce schema with realistic operational entities.
4. Seed data that creates useful analytical scenarios.
5. A Python source health check.
6. A basic automated test suite.
7. One intentional failure scenario.
8. One architecture decision record.
9. One runbook.
10. One weekly reflection.

The week is successful when you can run one command and prove:

```text
The source database is available.
The schema exists.
The seed data is loaded.
The source contract passes.
The failure scenario is detectable.
The recovery path is documented.
```

---

## What Week 1 is not

Do **not** add these yet:

* dbt project
* Airflow DAGs
* Kafka topics
* Spark jobs
* MinIO / object storage
* DataHub / OpenMetadata
* Terraform
* dashboards
* agents
* semantic layer
* CI/CD pipeline beyond local test commands

We will add each of those when the course has a concrete reason for them.

---

## Mental model

A data platform is only as reliable as its understanding of the systems it consumes.

Before building transformation logic, orchestration, streaming, governance, or observability, we need a source system with:

* known entities,
* known constraints,
* known business rules,
* known failure modes,
* known ownership assumptions,
* known data risks.

Week 1 creates that baseline.

---

## Architecture for Week 1

```text
opsone-lite/
  docker-compose.yml
  Makefile
  pyproject.toml
  .env.example
  README.md

  platform/
    postgres/
      init/
        01_schema.sql
        02_seed.sql
        03_expected_source_checks.sql

  src/
    opsone_lite/
      __init__.py
      config.py
      db.py
      source_health.py

  scripts/
    inject_week_01_failure.sql
    recover_week_01_failure.sql

  tests/
    test_source_contract.py

  docs/
    week-01.md
    adr/
      0001-local-first-source-system.md
    runbooks/
      week-01-source-data-quality-failure.md
```

Notice what is missing: no empty `airflow/`, `spark/`, `kafka/`, or `dbt/` folders yet. We keep the repo extensible, but we do not create premature folders that become junk drawers.

---

## Domain for Week 1: commerce operations

The source system represents a small commerce business.

### Entities

| Entity        | Purpose                      | Why it matters later                            |
| ------------- | ---------------------------- | ----------------------------------------------- |
| `customers`   | People buying products       | PII, segmentation, consent, governance          |
| `products`    | Items sold                   | Product catalog, margins, inventory             |
| `orders`      | Customer orders              | Fact modeling, revenue, operational status      |
| `order_items` | Products inside each order   | Grain, revenue allocation, joins                |
| `payments`    | Payment attempts and results | Reconciliation, payment failures, fraud signals |

### Business questions this source should eventually support

* What is daily revenue?
* Which products generate the most revenue?
* How many orders fail payment?
* Which customers are repeat buyers?
* Which markets have revenue growth?
* Which orders are operationally inconsistent?
* What data quality issues would break executive reporting?

In Week 1 we do **not** answer all of these. We only design the source so those questions become possible later.

---

# Session 1 — Create the repository foundation

## Goal

Create a minimal but professional local project structure.

## Tasks

Create the repository:

```bash
mkdir opsone-lite
cd opsone-lite
mkdir -p platform/postgres/init
mkdir -p src/opsone_lite
mkdir -p scripts
mkdir -p tests
mkdir -p docs/adr
mkdir -p docs/runbooks

touch README.md
touch Makefile
touch pyproject.toml
touch .env.example
touch src/opsone_lite/__init__.py
```

## `README.md`

````markdown
# OpsOne Lite

OpsOne Lite is a local-first DataOps control plane built as a learning lab for modern data platform engineering.

The project evolves week by week from a simple operational source system into a governed, observable, reliable data platform.

## Current scope

Week 1 creates:

- local Postgres source database
- commerce operational schema
- seed data
- source health checks
- local failure scenario
- documentation and runbook

## Not in scope yet

- dbt
- Airflow
- Spark
- Kafka
- catalog / lineage tooling
- dashboards
- cloud deployment

## Local commands

```bash
make up
make down
make health
make test
make inject-failure
make recover-failure
````

````

## `.env.example`

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=commerce
POSTGRES_USER=opsone
POSTGRES_PASSWORD=opsone
DATABASE_URL=postgresql://opsone:opsone@localhost:5432/commerce
````

---

# Session 2 — Add local Postgres

## Goal

Run a reproducible local source database.

## `docker-compose.yml`

```yaml
services:
  postgres:
    image: postgres:16
    container_name: opsone_postgres
    environment:
      POSTGRES_DB: commerce
      POSTGRES_USER: opsone
      POSTGRES_PASSWORD: opsone
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./platform/postgres/init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U opsone -d commerce"]
      interval: 5s
      timeout: 5s
      retries: 10

volumes:
  postgres_data:
```

## `Makefile`

```makefile
.PHONY: up down reset logs health test inject-failure recover-failure psql

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
	docker exec -it opsone_postgres psql -U opsone -d commerce

health:
	python -m opsone_lite.source_health

test:
	pytest -q

inject-failure:
	docker exec -i opsone_postgres psql -U opsone -d commerce < scripts/inject_week_01_failure.sql

recover-failure:
	docker exec -i opsone_postgres psql -U opsone -d commerce < scripts/recover_week_01_failure.sql
```

---

# Session 3 — Create the source schema

## Goal

Create a simple operational schema with enough realism to support future modeling, quality, governance, and observability work.

## `platform/postgres/init/01_schema.sql`

```sql
CREATE SCHEMA IF NOT EXISTS commerce;

CREATE TABLE IF NOT EXISTS commerce.customers (
    customer_id        BIGINT PRIMARY KEY,
    first_name         TEXT NOT NULL,
    last_name          TEXT NOT NULL,
    email              TEXT NOT NULL UNIQUE,
    country_code       CHAR(2) NOT NULL,
    marketing_consent  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.products (
    product_id     BIGINT PRIMARY KEY,
    sku            TEXT NOT NULL UNIQUE,
    product_name   TEXT NOT NULL,
    category       TEXT NOT NULL,
    unit_price     NUMERIC(10, 2) NOT NULL,
    active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.orders (
    order_id       BIGINT PRIMARY KEY,
    customer_id    BIGINT NOT NULL REFERENCES commerce.customers(customer_id),
    order_status   TEXT NOT NULL,
    order_ts       TIMESTAMP NOT NULL,
    country_code   CHAR(2) NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.order_items (
    order_item_id  BIGINT PRIMARY KEY,
    order_id       BIGINT NOT NULL REFERENCES commerce.orders(order_id),
    product_id     BIGINT NOT NULL REFERENCES commerce.products(product_id),
    quantity       INTEGER NOT NULL,
    unit_price     NUMERIC(10, 2) NOT NULL
);

CREATE TABLE IF NOT EXISTS commerce.payments (
    payment_id      BIGINT PRIMARY KEY,
    order_id        BIGINT NOT NULL REFERENCES commerce.orders(order_id),
    payment_status  TEXT NOT NULL,
    payment_method  TEXT NOT NULL,
    amount          NUMERIC(10, 2) NOT NULL,
    payment_ts      TIMESTAMP NOT NULL
);
```

## Design notes

Some constraints are intentionally strict:

* primary keys,
* foreign keys,
* not-null constraints,
* unique emails,
* unique SKUs.

Some rules are intentionally left to the DataOps layer:

* allowed order statuses,
* allowed payment statuses,
* payment amount reconciliation,
* freshness expectations,
* valid country codes beyond length.

That distinction matters. Real platforms cannot rely only on source system constraints. They need independent validation.

---

# Session 4 — Add seed data

## Goal

Load enough data to make the source useful, without creating unnecessary complexity.

## `platform/postgres/init/02_seed.sql`

```sql
INSERT INTO commerce.customers
(customer_id, first_name, last_name, email, country_code, marketing_consent, created_at)
VALUES
(1, 'Ana', 'Garcia', 'ana.garcia@example.com', 'ES', TRUE,  '2026-05-01 09:00:00'),
(2, 'Marc', 'Dubois', 'marc.dubois@example.com', 'FR', FALSE, '2026-05-01 10:00:00'),
(3, 'Sofia', 'Rossi', 'sofia.rossi@example.com', 'IT', TRUE,  '2026-05-02 11:00:00'),
(4, 'Joao', 'Silva', 'joao.silva@example.com', 'PT', TRUE,  '2026-05-02 12:00:00'),
(5, 'Emma', 'Muller', 'emma.muller@example.com', 'DE', FALSE, '2026-05-03 13:00:00')
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO commerce.products
(product_id, sku, product_name, category, unit_price, active, created_at)
VALUES
(101, 'TSHIRT-BLK-M', 'Black T-Shirt M', 'apparel', 19.99, TRUE, '2026-05-01 08:00:00'),
(102, 'TSHIRT-WHT-M', 'White T-Shirt M', 'apparel', 18.99, TRUE, '2026-05-01 08:00:00'),
(103, 'HOODIE-BLK-L', 'Black Hoodie L', 'apparel', 49.99, TRUE, '2026-05-01 08:00:00'),
(104, 'CAP-RED-OS',   'Red Cap',        'accessory', 14.99, TRUE, '2026-05-01 08:00:00')
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO commerce.orders
(order_id, customer_id, order_status, order_ts, country_code)
VALUES
(1001, 1, 'completed', '2026-05-10 09:15:00', 'ES'),
(1002, 2, 'completed', '2026-05-10 10:20:00', 'FR'),
(1003, 3, 'payment_failed', '2026-05-11 12:05:00', 'IT'),
(1004, 1, 'completed', '2026-05-12 14:30:00', 'ES'),
(1005, 4, 'cancelled', '2026-05-12 16:45:00', 'PT')
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO commerce.order_items
(order_item_id, order_id, product_id, quantity, unit_price)
VALUES
(1, 1001, 101, 2, 19.99),
(2, 1001, 104, 1, 14.99),
(3, 1002, 103, 1, 49.99),
(4, 1003, 102, 1, 18.99),
(5, 1004, 101, 1, 19.99),
(6, 1004, 103, 1, 49.99),
(7, 1005, 104, 2, 14.99)
ON CONFLICT (order_item_id) DO NOTHING;

INSERT INTO commerce.payments
(payment_id, order_id, payment_status, payment_method, amount, payment_ts)
VALUES
(5001, 1001, 'paid', 'card', 54.97, '2026-05-10 09:16:00'),
(5002, 1002, 'paid', 'paypal', 49.99, '2026-05-10 10:22:00'),
(5003, 1003, 'failed', 'card', 18.99, '2026-05-11 12:06:00'),
(5004, 1004, 'paid', 'card', 69.98, '2026-05-12 14:32:00'),
(5005, 1005, 'refunded', 'card', 29.98, '2026-05-12 17:00:00')
ON CONFLICT (payment_id) DO NOTHING;
```

---

# Session 5 — Add source health checks

## Goal

Create the first DataOps control before introducing dbt.

This is important: dbt tests will come later, but source validation does not belong only to dbt. A platform engineer should be able to validate source assumptions independently.

## `pyproject.toml`

```toml
[project]
name = "opsone-lite"
version = "0.1.0"
description = "Local-first DataOps control plane learning lab"
requires-python = ">=3.11"
dependencies = [
  "psycopg[binary]>=3.1.18",
  "pydantic-settings>=2.2.1"
]

[project.optional-dependencies]
dev = [
  "pytest>=8.0.0"
]

[tool.pytest.ini_options]
pythonpath = ["src"]
testpaths = ["tests"]
```

Install locally:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## `src/opsone_lite/config.py`

```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://opsone:opsone@localhost:5432/commerce"

    class Config:
        env_file = ".env"
        env_prefix = ""


settings = Settings()
```

## `src/opsone_lite/db.py`

```python
import psycopg

from opsone_lite.config import settings


def get_connection():
    return psycopg.connect(settings.database_url)
```

## `src/opsone_lite/source_health.py`

```python
from dataclasses import dataclass

from opsone_lite.db import get_connection


@dataclass(frozen=True)
class HealthCheckResult:
    name: str
    passed: bool
    observed_value: object
    expected: str


CHECKS = [
    {
        "name": "customers_exist",
        "sql": "select count(*) from commerce.customers",
        "validate": lambda value: value > 0,
        "expected": "at least 1 customer",
    },
    {
        "name": "orders_exist",
        "sql": "select count(*) from commerce.orders",
        "validate": lambda value: value > 0,
        "expected": "at least 1 order",
    },
    {
        "name": "known_order_statuses_only",
        "sql": """
            select count(*)
            from commerce.orders
            where order_status not in ('completed', 'payment_failed', 'cancelled')
        """,
        "validate": lambda value: value == 0,
        "expected": "0 orders outside expected status list",
    },
    {
        "name": "known_payment_statuses_only",
        "sql": """
            select count(*)
            from commerce.payments
            where payment_status not in ('paid', 'failed', 'refunded')
        """,
        "validate": lambda value: value == 0,
        "expected": "0 payments outside expected status list",
    },
    {
        "name": "paid_payments_match_order_items_total",
        "sql": """
            with item_totals as (
                select
                    order_id,
                    round(sum(quantity * unit_price), 2) as item_total
                from commerce.order_items
                group by order_id
            )
            select count(*)
            from commerce.payments p
            join item_totals i on p.order_id = i.order_id
            where p.payment_status = 'paid'
              and p.amount <> i.item_total
        """,
        "validate": lambda value: value == 0,
        "expected": "0 paid payments where amount differs from item total",
    },
]


def run_checks() -> list[HealthCheckResult]:
    results: list[HealthCheckResult] = []

    with get_connection() as conn:
        with conn.cursor() as cur:
            for check in CHECKS:
                cur.execute(check["sql"])
                observed_value = cur.fetchone()[0]
                passed = check["validate"](observed_value)
                results.append(
                    HealthCheckResult(
                        name=check["name"],
                        passed=passed,
                        observed_value=observed_value,
                        expected=check["expected"],
                    )
                )

    return results


def main() -> None:
    results = run_checks()
    failed = [result for result in results if not result.passed]

    for result in results:
        status = "PASS" if result.passed else "FAIL"
        print(
            f"[{status}] {result.name} | "
            f"observed={result.observed_value} | expected={result.expected}"
        )

    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
```

---

# Session 6 — Add automated source contract tests

## Goal

Create tests that prove the source contract is stable enough for later weeks.

## `tests/test_source_contract.py`

```python
from opsone_lite.db import get_connection
from opsone_lite.source_health import run_checks


def test_required_tables_exist():
    expected_tables = {
        "customers",
        "products",
        "orders",
        "order_items",
        "payments",
    }

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select table_name
                from information_schema.tables
                where table_schema = 'commerce'
                """
            )
            actual_tables = {row[0] for row in cur.fetchall()}

    assert expected_tables.issubset(actual_tables)


def test_source_health_checks_pass():
    results = run_checks()
    failed = [result for result in results if not result.passed]

    assert failed == []
```

---

# Failure scenario — Payment reconciliation breaks

## Goal

Inject a controlled defect and prove the system detects it.

The failure should be small, realistic, and recoverable.

## Scenario

A source application bug writes a paid payment amount that does not match the order item total.

This is exactly the kind of issue that can create executive reporting problems later:

* finance dashboard shows wrong revenue,
* order status says completed,
* payment says paid,
* item-level total disagrees with payment amount.

## `scripts/inject_week_01_failure.sql`

```sql
UPDATE commerce.payments
SET amount = amount + 10.00
WHERE payment_id = 5004;
```

## Expected result

After running:

```bash
make inject-failure
make health
```

You should see:

```text
[FAIL] paid_payments_match_order_items_total | observed=1 | expected=0 paid payments where amount differs from item total
```

## `scripts/recover_week_01_failure.sql`

```sql
UPDATE commerce.payments
SET amount = 69.98
WHERE payment_id = 5004;
```

After running:

```bash
make recover-failure
make health
```

All checks should pass again.

---

# Documentation deliverables

## `docs/adr/0001-local-first-source-system.md`

```markdown
# ADR 0001 — Use a local Postgres source system for Week 1

## Status

Accepted

## Context

OpsOne Lite needs a realistic but simple operational source system that can support future work in ingestion, modeling, orchestration, quality, governance, observability, and FinOps.

Starting with cloud infrastructure, Kafka, Airflow, Spark, or catalog tooling would create operational complexity before the source domain is stable.

## Decision

Use local Postgres as the Week 1 operational source system.

The initial domain is commerce operations with customers, products, orders, order items, and payments.

## Consequences

Positive:

- Simple local setup.
- Relational constraints are available.
- Realistic enough for analytical modeling.
- Easy to reset and break intentionally.
- Good foundation for future ingestion patterns.

Negative:

- It does not simulate scale.
- It does not simulate distributed storage.
- It does not cover streaming.
- It does not yet teach orchestration.

## Follow-up decisions

Future ADRs will decide:

- when to introduce dbt,
- when to introduce object storage,
- when to introduce orchestration,
- when to introduce streaming,
- when to introduce governance metadata.
```

## `docs/runbooks/week-01-source-data-quality-failure.md`

````markdown
# Runbook — Week 1 Source Data Quality Failure

## Failure

The source health check fails on:

```text
paid_payments_match_order_items_total
````

## Meaning

At least one payment marked as `paid` has an amount that does not match the sum of its order items.

## Business impact

Revenue reporting may be incorrect.

Order-level and payment-level facts may disagree.

## Detection

Run:

```bash
make health
```

## Diagnosis query

```sql
with item_totals as (
    select
        order_id,
        round(sum(quantity * unit_price), 2) as item_total
    from commerce.order_items
    group by order_id
)
select
    p.payment_id,
    p.order_id,
    p.amount as payment_amount,
    i.item_total,
    p.amount - i.item_total as difference
from commerce.payments p
join item_totals i on p.order_id = i.order_id
where p.payment_status = 'paid'
  and p.amount <> i.item_total;
```

## Recovery

For the Week 1 controlled failure, run:

```bash
make recover-failure
```

Then validate:

```bash
make health
make test
```

## Prevention

Possible future controls:

* dbt generic test
* dbt singular test
* source freshness check
* payment reconciliation model
* anomaly detection
* incident severity classification
* data product SLO

````

## `docs/week-01.md`

```markdown
# Week 1 Reflection — OpsOne Lite Foundation

## What was built?

- Local Postgres source system
- Commerce schema
- Seed data
- Source health checks
- Automated source contract tests
- Controlled failure scenario
- ADR
- Runbook

## What did we intentionally avoid?

- dbt
- Airflow
- Kafka
- Spark
- object storage
- catalog tooling
- dashboards
- agents

## Why did we avoid them?

Because the platform needs a stable source domain before orchestration, transformation, streaming, governance, or observability have real meaning.

## What source assumptions are now explicit?

- Expected tables exist.
- Orders exist.
- Customers exist.
- Order statuses are controlled.
- Payment statuses are controlled.
- Paid payment amounts reconcile with order item totals.

## What failure did we simulate?

A paid payment amount no longer matched the order item total.

## Why does that matter?

Because downstream revenue reporting could become wrong even if the pipeline technically succeeds.

## What should be improved later?

- Add dbt tests for reconciliation.
- Add freshness checks.
- Add source-to-bronze ingestion.
- Add ownership metadata.
- Add severity classification.
- Add incident history.
````

---

# Week 1 acceptance criteria

Week 1 is complete only when all of the following are true:

```bash
make reset
make health
make test
make inject-failure
make health   # must fail
make recover-failure
make health   # must pass
make test      # must pass
```

You should also be able to explain:

1. Why Postgres was chosen first.
2. Which constraints belong in the source system.
3. Which controls belong in the DataOps layer.
4. Why the failure scenario matters to business trust.
5. Why we intentionally avoided dbt, Airflow, Kafka, Spark, and governance tooling in Week 1.

---

# Week 1 review questions

Answer these in `docs/week-01.md` after completing the implementation.

1. What would happen if a pipeline moved this data downstream without reconciliation checks?
2. Which source assumptions are technical constraints, and which are business rules?
3. Which checks should eventually move into dbt?
4. Which checks should remain outside dbt?
5. What would make this source system hard to operate at scale?
6. What is the smallest useful DataOps control we created this week?
7. What did this week teach about platform foundations?

---

# Instructor notes

The purpose of Week 1 is not to impress with tooling.

The purpose is to create a stable foundation and one concrete operational lesson:

> A green pipeline is not the same as trusted data.

That idea will compound through the rest of the course.
