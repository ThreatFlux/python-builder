# Image configuration
IMAGE_NAME := python-builder
DOCKER_REPO := threatflux
VERSION := $(shell git describe --tags --always --dirty)
BUILD_DATE := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

# Docker image tags
LOCAL_TAG := $(IMAGE_NAME):local
LATEST_TAG := $(DOCKER_REPO)/$(IMAGE_NAME):latest
VERSION_TAG := $(DOCKER_REPO)/$(IMAGE_NAME):$(VERSION)

# GitHub Container Registry
GHCR_REPO := ghcr.io/threatflux
GHCR_LATEST_TAG := $(GHCR_REPO)/$(IMAGE_NAME):latest
GHCR_VERSION_TAG := $(GHCR_REPO)/$(IMAGE_NAME):$(VERSION)

# Build arguments
BUILD_ARGS := --build-arg BUILD_DATE=$(BUILD_DATE) \
              --build-arg VERSION=$(VERSION)

.PHONY: all build test clean push push-ghcr

all: build test

# Build the Docker image
build:
	@echo "Building $(LOCAL_TAG)..."
	docker build $(BUILD_ARGS) -t $(LOCAL_TAG) .
	docker tag $(LOCAL_TAG) $(LATEST_TAG)
	docker tag $(LOCAL_TAG) $(VERSION_TAG)
	docker tag $(LOCAL_TAG) $(GHCR_LATEST_TAG)
	docker tag $(LOCAL_TAG) $(GHCR_VERSION_TAG)

# Run tests
test:
	@echo "Running tests..."
	./run_tests.sh

# Run tests with no cache
test-fresh:
	@echo "Running fresh tests (no cache)..."
	docker build --no-cache $(BUILD_ARGS) -t $(LOCAL_TAG) .
	./run_tests.sh

# Push images to Docker Hub
push:
	@echo "Pushing to Docker Hub..."
	docker push $(LATEST_TAG)
	docker push $(VERSION_TAG)

# Push images to GitHub Container Registry
push-ghcr:
	@echo "Pushing to GitHub Container Registry..."
	docker push $(GHCR_LATEST_TAG)
	docker push $(GHCR_VERSION_TAG)

# Clean up local images
clean:
	@echo "Cleaning up local images..."
	docker rmi -f $(LOCAL_TAG) $(LATEST_TAG) $(VERSION_TAG) $(GHCR_LATEST_TAG) $(GHCR_VERSION_TAG) 2>/dev/null || true

# Development targets
.PHONY: dev test-dev prod

# Build development image
dev:
	@echo "Building development image..."
	docker build $(BUILD_ARGS) --target development -t $(LOCAL_TAG)-dev .

# Build test image
test-dev:
	@echo "Building test image..."
	docker build $(BUILD_ARGS) --target test -t $(LOCAL_TAG)-test .

# Build production image
prod:
	@echo "Building production image..."
	docker build $(BUILD_ARGS) --target production -t $(LOCAL_TAG)-prod .