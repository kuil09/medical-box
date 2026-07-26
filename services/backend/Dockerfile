FROM python:3.13-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080

WORKDIR /app

RUN pip install --no-cache-dir uv==0.7.20

COPY pyproject.toml uv.lock* ./
RUN uv sync --frozen --no-dev --no-install-project

COPY src ./src
RUN uv sync --frozen --no-dev

COPY alembic.ini ./
COPY migrations ./migrations

EXPOSE 8080

CMD ["uv", "run", "--no-sync", "uvicorn", "medical_box_api.main:app", "--host", "0.0.0.0", "--port", "8080", "--no-access-log"]
