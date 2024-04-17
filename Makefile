IMAGE_NAME = ghcr.io/ministryofjustice/analytical-platform-actions-runner:latest
ARCH = $(shell uname --machine)

define DOCKER_BUILD
	@echo "Building on $(ARCH) architecture";
	@if [ "$(ARCH)" = "aarch64" ] || [ "$(ARCH)" = "arm64" ]; then \
		docker build --platform linux/amd64 --file Dockerfile --tag $(IMAGE_NAME) .; \
	else \
		docker build --file Dockerfile --tag $(IMAGE_NAME) .; \
	fi
endef

define CONTAINER_TEST
	@echo "Testing on $(ARCH) architecture";
	@if [ "$(ARCH)" = "aarch64" ] || [ "$(ARCH)" = "arm64" ]; then \
		container-structure-test test --platform linux/amd64 --config test/container-structure-test.yml --image $(IMAGE_NAME); \
	else \
		container-structure-test test --config test/container-structure-test.yml --image $(IMAGE_NAME); \
	fi
endef

ct:
	ct lint --charts chart

build:
	$(DOCKER_BUILD)

test: build
	$(CONTAINER_TEST)

scan: build
	trivy image --vuln-type os,library --severity CRITICAL --exit-code 1 $(IMAGE_NAME)
