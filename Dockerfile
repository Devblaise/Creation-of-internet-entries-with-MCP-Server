# ── Stage 1: build & install dependencies ──────────────────
FROM python:3.12-slim AS builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy dependency files first (better layer caching)
COPY pyproject.toml uv.lock ./

# Install dependencies into the project virtual environment
RUN uv sync --frozen --no-dev --no-install-project

# Copy the rest of the application
COPY . .

# Install the project itself
RUN uv sync --frozen --no-dev

# ── Stage 2: runtime ───────────────────────────────────────
FROM python:3.12-slim

WORKDIR /app

# Copy the entire app with its .venv from builder
COPY --from=builder /app /app

# Place the virtual environment on PATH
ENV PATH="/app/.venv/bin:$PATH"

# Expose the FastAPI dashboard port
EXPOSE 8000

# Default: run the FastAPI dashboard
# Override with: docker run ... <image> uv run mcp dev src/server.py
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
