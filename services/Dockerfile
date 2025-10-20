FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install --no-cache-dir uv==0.7.13

WORKDIR /app

COPY . .

# Install dependencies
RUN uv sync --frozen

EXPOSE 8080

# Use python directly instead of uv run
CMD ["sh", "-c", "python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-8080}"]
