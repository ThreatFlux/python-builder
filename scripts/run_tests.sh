#!/bin/bash
set -euo pipefail

echo "Running container tests..."

# Build test image
echo "Building test image..."
docker build -t python-builder-test .

# Test Python installation
echo "Testing Python installation..."
docker run --rm python-builder-test python3 --version
docker run --rm python-builder-test pip3 --version

# Test user permissions
echo "Testing user permissions..."
docker run --rm python-builder-test whoami | grep "python_builder"

# Test workspace permissions
echo "Testing workspace permissions..."
docker run --rm python-builder-test touch /workspace/test.txt

# Test Python package installation
echo "Testing Python package installation..."
docker run --rm python-builder-test pip3 install --user requests

# Test Python environment
echo "Testing Python environment..."
docker run --rm python-builder-test python3 -c "import sys; print(sys.path)"

# Test SSL support
echo "Testing SSL support..."
docker run --rm python-builder-test python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"

# Test database support
echo "Testing SQLite support..."
docker run --rm python-builder-test python3 -c "import sqlite3; print(sqlite3.sqlite_version)"

# Test different stages
echo "Testing development stage..."
docker build --target development -t python-builder-dev .
docker run --rm python-builder-dev git --version

echo "Testing test stage..."
docker build --target test -t python-builder-test-stage .
docker run --rm python-builder-test-stage pytest --version

echo "All tests passed!"