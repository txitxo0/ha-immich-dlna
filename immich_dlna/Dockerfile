ARG BUILD_FROM=python:3.12-slim
ARG IMMICH_DLNA_REF=6c919e6ee98d0c2c3155600db792e3f49f5c7759
FROM ${BUILD_FROM}
ARG IMMICH_DLNA_REF=6c919e6ee98d0c2c3155600db792e3f49f5c7759

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# uv runtime copied from the astral-sh image (fixed version)
COPY --from=ghcr.io/astral-sh/uv:0.10.4 /uv /uvx /bin/

# Fetch upstream source at a fixed commit and extract into /tmp
ADD https://github.com/SemaiCZE/immich-dlna/archive/${IMMICH_DLNA_REF}.tar.gz /tmp/immich.tar.gz
RUN apt-get update && apt-get install -y --no-install-recommends jq ca-certificates \
    && python -c "import tarfile; archive = tarfile.open('/tmp/immich.tar.gz'); archive.extractall('/tmp', filter='data'); archive.close()" \
    && mv /tmp/immich-dlna-*/* /app/ \
    && rm -rf /tmp/immich* \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies, then the upstream project, using its locked dependencies.
RUN uv sync --frozen --no-dev --no-install-project
RUN uv sync --frozen --no-dev

ENV PATH="/app/.venv/bin:${PATH}"

EXPOSE 8200

# Copy run script and make it the entrypoint
COPY run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

CMD ["/usr/local/bin/run.sh"]
