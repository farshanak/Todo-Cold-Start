# --- Stage 1: Base ---
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
ENV VENV=/opt/venv PATH="/opt/venv/bin:$PATH"
WORKDIR /app

# --- Stage 2: Dependencies ---
FROM base AS deps
COPY backend/requirements.txt .
RUN python -m venv "$VENV" \
    && pip install --upgrade pip \
    && pip install -r requirements.txt

# --- Stage 3: Development (hot reload via compose bind mount) ---
FROM deps AS development
ENV PYTHONPATH=/app
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# --- Stage 4: Production (non-root, minimal) ---
FROM base AS production
COPY --from=deps /opt/venv /opt/venv
RUN useradd -m -u 1001 appuser
WORKDIR /app
COPY --chown=appuser:appuser backend/main.py backend/config.py ./
ENV PYTHONPATH=/app HOST=0.0.0.0 PORT=8000
EXPOSE 8000
USER appuser
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -fsS http://localhost:8000/health || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
