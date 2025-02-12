# ThreatFlux Python Builder

A secure, optimized Python 3.13.2 builder base image for ThreatFlux projects. Built on Alpine Linux for minimal size and maximum security.

## Overview

This repository contains a multi-stage Dockerfile and supporting infrastructure for ThreatFlux's Python builder image. The image is designed to provide a consistent, secure build environment for Python projects with different stages for development, testing, and production use.

## Features

- Python 3.13.2 support (Released February 4th, 2025)
- Based on Alpine Linux 3.21.1
- Multi-stage build support:
  - Development environment
  - Test environment
  - Production environment
  - Dependency builder
- Security-focused configuration
- Non-root user setup
- Minimal build dependencies
- Built-in test environment
- Automated builds via GitHub Actions
- Published to both DockerHub and GitHub Container Registry

## Quick Start

### Pull the image

From DockerHub:
```bash
docker pull threatflux/python-builder:latest
```

From GitHub Container Registry:
```bash
docker pull ghcr.io/threatflux/python-builder:latest
```

### Available Build Stages

The image provides several build stages for different use cases:

1. `python-builder`: Base Python compilation stage
2. `python-base`: Common runtime environment (Alpine Linux 3.21.1 based)
3. `development`: Development environment with additional tools (git, curl, bash, make, vim)
4. `builder`: For compiling dependencies (includes gcc, musl-dev, python3-dev, postgresql-dev)
5. `test`: Testing environment with pytest and coverage
6. `production`: Minimal production image

### Build Times

Approximate build times on standard hardware:
- Full build: ~100 seconds
- Python compilation: ~72 seconds
- Final image size: Optimized for minimal footprint

### Usage Examples

#### Development Environment

```dockerfile
# Use the development stage
FROM threatflux/python-builder:latest AS development

# Copy your application
COPY . .

# Install dependencies
RUN pip install --user -r requirements.txt

CMD ["python", "app.py"]
```

#### Production Environment

```dockerfile
# Multi-stage build example
FROM threatflux/python-builder:latest AS builder

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Production stage
FROM threatflux/python-builder:latest AS production

# Copy only the installed packages from builder
COPY --from=builder /home/python_builder/.local /home/python_builder/.local

# Copy application
COPY . .

CMD ["gunicorn", "app:app"]
```

#### Test Environment

```dockerfile
FROM threatflux/python-builder:latest AS test

# Copy application and tests
COPY . .

# Install dependencies
RUN pip install --user -r requirements.txt -r requirements-test.txt

# Run tests
CMD ["pytest", "--cov=app", "tests/"]
```

## Development

### Prerequisites

- Docker
- Make
- Git

### Building

```bash
# Build all stages
make build

# Build specific stage
docker build --target development -t myapp:dev .

# Run tests
make test

# Push to registries
make push       # Docker Hub
make push-ghcr  # GitHub Container Registry

# Clean build
docker build --no-cache . -t threatflux/python-builder
```

### Environment Variables

The following environment variables are set by default:

```bash
PYTHONUNBUFFERED=1
PYTHONDONTWRITEBYTECODE=1
PIP_NO_CACHE_DIR=1
LD_LIBRARY_PATH="/usr/lib"
```

### Security Features

- Non-root user (python_builder, UID: 10001)
- Minimal base image (Alpine Linux 3.21.1)
- Multi-stage builds for reduced attack surface
- Regular security updates
- Limited system dependencies
- Proper shared library configuration

## Best Practices

1. Always specify a version tag in production:
```dockerfile
FROM threatflux/python-builder:1.0.0
```

2. Use multi-stage builds to minimize final image size:
```dockerfile
# Build stage
FROM threatflux/python-builder:latest AS builder
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Production stage
FROM threatflux/python-builder:latest AS production
COPY --from=builder /home/python_builder/.local /home/python_builder/.local
COPY . .
```

3. Leverage the built-in test stage for CI/CD:
```bash
docker build --target test -t myapp:test .
docker run myapp:test
```

## Version Information

- Python Version: 3.13.2 (Released February 4th, 2025)
- Alpine Linux Version: 3.21.1
- Latest Build Test: Successful (Build time: ~100s)
- Base Image Size: Optimized (<100MB for production)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[MIT License](LICENSE)

## Support

For support, please open an issue in the GitHub repository.