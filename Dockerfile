#checkov:skip=CKV_DOCKER_2:actions/runner does not provider a mechanism for checking the health of the service
FROM public.ecr.aws/ubuntu/ubuntu@sha256:676f54056adb852b7fc9b42db4bc82fbd8fbab4bdc5027b1c30e0d53393ab602

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
    ACTIONS_RUNNER_VERSION="2.315.0" \
    ACTIONS_RUNNER_PKG_SHA="6362646b67613c6981db76f4d25e68e463a9af2cc8d16e31bfeabe39153606a0"

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
  "apt-transport-https=2.4.12" \
  "ca-certificates=20230311ubuntu0.22.04.1" \
  "curl=7.81.0-1ubuntu1.16" \
  "git=1:2.34.1-1ubuntu1.10" \
  "jq=1.6-2.1ubuntu3" \
  "libicu-dev=70.1-2" \
  "lsb-release=11.1.0ubuntu4"

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
