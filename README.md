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

## Local commands

```bash
make up
make down
make health
make test
make inject-failure
make recover-failure
```

## .env.example

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=commerce
POSTGRES_USER=opsone
POSTGRES_PASSWORD=opsone
DATABASE_URL=postgresql://opsone:opsone@localhost:5432/commerce
```