# checkov:skip=CKV_DOCKER_2:Healthcheck instructions have not been added to container images
#This image is an example base image for this template and can be replaced to fit user needs
FROM public.ecr.aws/ubuntu/ubuntu@sha256:424997752d9e0b47a7f14757558c4fe128ee6a1abad1af52cd96a660e00438fe

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Analytical Platform (analytical-platform@digital.justice.gov.uk)"\
      org.opencontainers.image.title="{image title}" \
      org.opencontainers.image.description="{decription}" \
      org.opencontainers.image.url="{your repo url}"

ENV CONTAINER_USER="analyticalplatform" \
    CONTAINER_UID="1000" \
    CONTAINER_GROUP="analyticalplatform" \
    CONTAINER_GID="1000" \
    DEBIAN_FRONTEND="noninteractive"

# User
RUN groupadd \
      --gid ${CONTAINER_GID} \
      ${CONTAINER_GROUP} \
    && useradd \
         --uid ${CONTAINER_UID} \
         --gid ${CONTAINER_GROUP} \
         --create-home \
         --shell /bin/bash \
         ${CONTAINER_USER}

# Base
RUN apt-get update --yes \
    && apt-get install --yes \
         "apt-transport-https=2.4.11" \
         "curl=7.81.0-1ubuntu1.15" \
         "git=1:2.34.1-1ubuntu1.10" \
         "gpg=2.2.27-3ubuntu2.1" \
         "python3.10=3.10.12-1~22.04.3" \
         "python3-pip=22.0.2+dfsg-1ubuntu0.4" \
         "unzip=6.0-26ubuntu3.2" \
    && apt-get clean --yes \
    && rm --force --recursive /var/lib/apt/lists/*

USER ${CONTAINER_USER}

WORKDIR /home/${CONTAINER_USER}

