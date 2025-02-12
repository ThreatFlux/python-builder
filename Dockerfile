# Stage 0: Python base builder - Builds Python from source
FROM alpine:3.21.1 AS python-builder

# Build arguments
ARG PYTHON_VERSION=3.13.2
ARG BUILD_DATE
ARG VERSION

# Install build dependencies
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    build-base \
    zlib-dev \
    openssl-dev \
    libffi-dev \
    bzip2-dev \
    xz-dev \
    sqlite-dev \
    ncurses-dev \
    readline-dev \
    tk-dev \
    ca-certificates \
    wget \
    tar \
    # Download and build Python
    && wget https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --prefix=/usr \
                  --enable-shared \
                  --with-system-expat \
                  --with-system-ffi \
                  --with-ensurepip=install \
                  --enable-loadable-sqlite-extensions \
    && make -j$(nproc) \
    && make install \
    # Cleanup
    && cd .. \
    && rm -rf Python-${PYTHON_VERSION}* \
    && pip3 install --no-cache-dir pip setuptools wheel

# Stage 1: Base runtime image
FROM alpine:3.21.1 AS python-base

# Build arguments
ARG USER=python_builder
ARG UID=10001

# Copy Python from builder
COPY --from=python-builder /usr /usr

# Install runtime dependencies and setup user
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    libstdc++ \
    libgcc \
    libffi \
    expat \
    sqlite-libs \
    ca-certificates \
    # Create non-root user
    && addgroup -g ${UID} ${USER} \
    && adduser -u ${UID} -G ${USER} -s /bin/sh -D ${USER} \
    # Setup workspace
    && mkdir -p /workspace \
    && chown -R ${USER}:${USER} /workspace \
    # Setup Python environment
    && mkdir -p /home/${USER}/.local \
    && chown -R ${USER}:${USER} /home/${USER}

# Set environment variables
ENV PATH="/home/${USER}/.local/bin:${PATH}" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    LD_LIBRARY_PATH="/usr/lib"

# Stage 2: Development image
FROM python-base AS development

# Install development tools with explicit version for curl
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    git \
    curl>=3.3.3-r0 \
    bash \
    make \
    vim

# Switch to non-root user
USER ${USER}

# Set working directory
WORKDIR /workspace

# Stage 3: Builder image (for compiling dependencies)
FROM python-base AS builder

# Install build essentials
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    gcc \
    musl-dev \
    python3-dev \
    postgresql-dev

# Switch to non-root user
USER ${USER}

# Set working directory
WORKDIR /workspace

# Stage 4: Test image
FROM python-base AS test

# Install test dependencies
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    py3-pytest \
    py3-coverage

# Switch to non-root user
USER ${USER}

# Set working directory
WORKDIR /workspace

# Stage 5: Production image
FROM python-base AS production

# Build arguments for metadata
ARG BUILD_DATE
ARG VERSION

# Add metadata
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.authors="wyattroersma@gmail.com" \
      org.opencontainers.image.url="https://github.com/threatflux/python-builder" \
      org.opencontainers.image.documentation="https://github.com/threatflux/python-builder" \
      org.opencontainers.image.source="https://github.com/threatflux/python-builder" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.vendor="ThreatFlux" \
      org.opencontainers.image.title="python-builder" \
      org.opencontainers.image.description="ThreatFlux Python builder base image"

# Switch to non-root user
USER ${USER}

# Set working directory
WORKDIR /workspace

# Verify installation
RUN python3 --version && pip3 --version

# Health check
HEALTHCHECK --interval=5m --timeout=3s \
    CMD python3 -c "print('healthy')" || exit 1