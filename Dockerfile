#checkov:skip=CKV_DOCKER_2:actions/runner does not provider a mechanism for checking the health of the service
FROM public.ecr.aws/ubuntu/ubuntu@sha256:4f5ca1c8b7abe2bd1162e629cafbd824c303b98954b1a168526aca6021f8affe

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform" \
      org.opencontainers.image.title="Actions Runner" \
      org.opencontainers.image.description="Actions Runner image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-actions-runner"

ENV CONTAINER_USER="runner" \
    CONTAINER_UID="10000" \
    CONTAINER_GROUP="runner" \
    CONTAINER_GID="10000" \
    CONTAINER_HOME="/actions-runner" \
    DEBIAN_FRONTEND="noninteractive" \
    ACTIONS_RUNNER_VERSION="2.317.0" \
    ACTIONS_RUNNER_PKG_SHA="9e883d210df8c6028aff475475a457d380353f9d01877d51cc01a17b2a91161d"

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

RUN <<EOF
groupadd \
  --gid ${CONTAINER_GID} \
  --system \
  ${CONTAINER_GROUP}

useradd \
  --uid ${CONTAINER_UID} \
  --gid ${CONTAINER_GROUP} \
  --create-home \
  ${CONTAINER_USER}

mkdir --parents ${CONTAINER_HOME}

chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${CONTAINER_HOME}

apt-get update

apt-get install --yes --no-install-recommends \
  "apt-transport-https=2.7.14build2" \
  "ca-certificates=20240203" \
  "curl=8.5.0-2ubuntu10.1" \
  "git=1:2.43.0-1ubuntu7" \
  "jq=1.7.1-3build1" \
  "libicu-dev=74.2-1ubuntu3" \
  "lsb-release=12.0-2" \
  "gcc=4:13.2.0-7ubuntu1" \
  "libsqlite3-dev=3.45.1-1ubuntu2"

apt-get clean

rm -rf /var/lib/apt/lists/*

curl --location "https://github.com/actions/runner/releases/download/v${ACTIONS_RUNNER_VERSION}/actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" \
  --output "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz"

echo "${ACTIONS_RUNNER_PKG_SHA}"  "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" | /usr/bin/sha256sum --check

tar --extract --gzip --file="actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" --directory="${CONTAINER_HOME}"

rm --force "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz"
EOF

COPY --chown=nobody:nobody --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
