# Multi-stage Dockerfile for Solent Marks Calculator
# Stage 1: Builder stage (includes tests for CI/CD)
FROM python:3.12-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Copy application files for testing (dev/ only used in CI, not in final image)
COPY app.py .
COPY 2025scra.gpx .
COPY templates ./templates/
COPY dev ./dev/

# Stage 2: Production stage (lean, no tests or dev files)
FROM python:3.12-slim

# Create non-root user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /home/appuser/.local

# Copy application code
COPY --chown=appuser:appuser app.py .
COPY --chown=appuser:appuser gunicorn-docker.conf.py ./gunicorn.conf.py
COPY --chown=appuser:appuser 2025scra.gpx .
COPY --chown=appuser:appuser templates ./templates/

# Set environment variables
ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASK_APP=app.py \
    FLASK_ENV=production

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/').read()" || exit 1

# Run Gunicorn
CMD ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]

