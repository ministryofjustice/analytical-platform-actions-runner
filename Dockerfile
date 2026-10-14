#checkov:skip=CKV_DOCKER_2: HEALTHCHECK not required - Health checks are implemented downstream of this image

FROM public.ecr.aws/ubuntu/ubuntu:26.04@sha256:99b345756d0ddb56dd7ab9c8d26f6ab41364506c00757a8c5b7ee793ea07fca3


LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)" \
      org.opencontainers.image.title="Actions Runner" \
      org.opencontainers.image.description="Actions Runner image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/analytical-platform-actions-runner"

ENV CONTAINER_USER="runner" \
    CONTAINER_UID="10000" \
    CONTAINER_GROUP="runner" \
    CONTAINER_GID="10000" \
    CONTAINER_HOME="/actions-runner" \
    DEBIAN_FRONTEND="noninteractive" \
    ACTIONS_RUNNER_VERSION="2.335.1" \
    ACTIONS_RUNNER_PKG_SHA="4ef2f25285f0ae4477f1fe1e346db76d2f3ebf03824e2ddd1973a2819bf6c8cf" \
    MICROSOFT_SQL_ODBC_VERSION="18.7.1.1-1" \
    MICROSOFT_SQL_TOOLS_VERSION="18.7.1.1-1" \
    PATH="/opt/mssql-tools18/bin:${PATH}"

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
  "apt-transport-https=3.2.0" \
  "ca-certificates=20260601~26.04.1" \
  "curl=8.18.0-1ubuntu2.8" \
  "gettext=0.23.2-1" \
  "git=1:2.53.0-1ubuntu1" \
  "gcc=4:15.2.0-5ubuntu1" \
  "gpg=2.4.8-4ubuntu3.1" \
  "gzip=1.14-1~exp2ubuntu1.1" \
  "jq=1.8.1-4ubuntu2" \
  "libicu-dev=78.2-2ubuntu1" \
  "libsqlite3-dev=3.46.1-9ubuntu0.3" \
  "libattr1=1:2.5.2-4ubuntu0.1" \
  "attr=1:2.5.2-4ubuntu0.1" \
  "lsb-release=12.1-2build1" \
  "libncursesw6=6.6+20251231-1" \
  "libtinfo6=6.6+20251231-1" \
  "ncurses-base=6.6+20251231-1" \
  "ncurses-bin=6.6+20251231-1"

apt-get clean

rm -rf /var/lib/apt/lists/*

curl --location "https://github.com/actions/runner/releases/download/v${ACTIONS_RUNNER_VERSION}/actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" \
  --output "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz"

echo "${ACTIONS_RUNNER_PKG_SHA}"  "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" | /usr/bin/sha256sum --check

tar --extract --gzip --file="actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" --directory="${CONTAINER_HOME}"

rm --force "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz"
EOF

# Microsoft SQL ODBC and Tools
RUN <<EOF
curl --location --fail-with-body \
  "https://packages.microsoft.com/keys/microsoft-2025.asc" \
  --output microsoft.asc

cat microsoft.asc | gpg --dearmor --output microsoft-prod.gpg

install -D --owner root --group root --mode 644 microsoft-prod.gpg /usr/share/keyrings/microsoft-prod.gpg

source /etc/os-release
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/${VERSION_ID}/prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/mssql-release.list

apt-get update --yes

ACCEPT_EULA=Y apt-get install --yes \
  "msodbcsql18=${MICROSOFT_SQL_ODBC_VERSION}" \
  "mssql-tools18=${MICROSOFT_SQL_TOOLS_VERSION}"

apt-get clean --yes

rm --force --recursive /var/lib/apt/lists/* microsoft.asc microsoft-prod.gpg
EOF

USER ${CONTAINER_USER}
WORKDIR ${CONTAINER_HOME}
COPY --chown=nobody:nogroup --chmod=0755 src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
