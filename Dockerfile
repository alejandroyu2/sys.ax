FROM python:3.12-slim@sha256:ccc7089399c8bb65dd1fb3ed6d55efa538a3f5e7fca3f5988ac3b5b87e593bf0 AS builder
WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim@sha256:ccc7089399c8bb65dd1fb3ed6d55efa538a3f5e7fca3f5988ac3b5b87e593bf0
RUN adduser --disabled-password --no-create-home app \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /install /usr/local
WORKDIR /app
COPY --chown=app:app . .
RUN pip uninstall -y pip setuptools 2>/dev/null; rm -rf /usr/local/bin/pip* \
    && chmod -R a-w /app /usr/local \
    && rm -f /bin/sh /usr/bin/sh /bin/bash /usr/bin/bash 2>/dev/null || true
USER app
HEALTHCHECK --interval=30s --timeout=3s --retries=2 \
  CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8080/')"]
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080", "--timeout-keep-alive", "5", "--limit-concurrency", "100", "--no-server-header"]
