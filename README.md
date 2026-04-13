# Todo-Cold-Start

A tiny Todo app used as the working project for the Mault Production Readiness Kit.

## Stack

- **Backend:** Python 3.12, FastAPI, pydantic-settings, in-memory storage
- **Frontend:** Vanilla TypeScript compiled with `tsc`, served by nginx
- **Containerization:** Docker multi-stage builds (backend + frontend), `docker-compose.yml` for local dev
- **CI:** GitHub Actions — `lint` (ruff, tsc --noEmit) and `test` (pytest with ≥80% coverage)

## Run locally

```bash
docker compose up -d
open http://localhost:5500
```

## CI Status

![CI](https://github.com/farshanak/Todo-Cold-Start/actions/workflows/ci.yml/badge.svg)
