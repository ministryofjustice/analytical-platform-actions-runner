.PHONY: test build run scan ct

IMAGE_NAME ?= ghcr.io/ministryofjustice/analytical-platform-actions-runner
IMAGE_TAG  ?= local

ct:
	ct lint --charts chart

scan: build
	trivy image --vuln-type os,library --severity CRITICAL --exit-code 1 $(IMAGE_NAME)

run: build
	docker run --rm -it --entrypoint /bin/bash $(IMAGE_NAME):$(IMAGE_TAG)

test: build
	container-structure-test test --platform linux/amd64 --config test/container-structure-test.yml --image $(IMAGE_NAME):$(IMAGE_TAG)

build:
	@ARCH=`uname --machine`; \
	case $$ARCH in \
	aarch64 | arm64) \
		echo "Building on $$ARCH architecture"; \
		docker build --platform linux/amd64 --file Dockerfile --tag $(IMAGE_NAME):$(IMAGE_TAG) . ;; \
	*) \
		echo "Building on $$ARCH architecture"; \
		docker build --file Dockerfile --tag $(IMAGE_NAME):$(IMAGE_TAG) . ;; \
	esac
