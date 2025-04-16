# Analytical Platform Actions Runner

[![Ministry of Justice Repository Compliance Badge](https://github-community.service.justice.gov.uk/repository-standards/api/analytical-platform-actions-runner/badge)](https://github-community.service.justice.gov.uk/repository-standards/analytical-platform-actions-runner)

[![Open in Dev Container](https://raw.githubusercontent.com/ministryofjustice/.devcontainer/refs/heads/main/contrib/badge.svg)](https://vscode.dev/redirect?url=vscode://ms-vscode-remote.remote-containers/cloneInVolume?url=https://github.com/ministryofjustice/analytical-platform-actions-runner)

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ministryofjustice/analytical-platform-actions-runner)

This repository contains the code for building the image used by Analytical Platform's self-hosted GitHub Actions runner service

## Running Locally

### Build

```bash
make build
```

### Test

```bash
make test
```

### Run

```bash
make run
```

## Versions

### Ubuntu

Dependabot is configured to do this in [`.github/dependabot.yml`](.github/dependabot.yml), but if you need to get the digest, do the following

```bash
docker pull --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

docker image inspect --format='{{ index .RepoDigests 0 }}' public.ecr.aws/ubuntu/ubuntu:24.04
```

### APT Packages

The latest versions of the APT packages can be obtained by running the following

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

apt-get update

apt-cache policy ${PACKAGE} # for example curl, git or gpg
```

### GitHub Action Runner

Releases for GitHub Actions Runner are maintained on [GitHub](https://github.com/actions/runner/releases).

### Microsoft ODBC driver for SQL Server

The latest version of Microsoft ODBC driver for SQL Server can be obtained by running:

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

apt-get update --yes

apt-get install --yes curl gpg

curl --location --fail-with-body \
  "https://packages.microsoft.com/keys/microsoft.asc" \
  --output microsoft.asc

cat microsoft.asc | gpg --dearmor --output microsoft-prod.gpg

install -D --owner root --group root --mode 644 microsoft-prod.gpg /usr/share/keyrings/microsoft-prod.gpg

echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/mssql-release.list

apt-get update --yes

apt-cache policy msodbcsql18

apt-cache policy mssql-tools18
```

## Maintenance

Maintenance of this component is scheduled in this [workflow](https://github.com/ministryofjustice/analytical-platform/blob/main/.github/workflows/schedule-issue-actions-runner.yml), which generates a maintenance ticket as per this [example](https://github.com/ministryofjustice/analytical-platform/issues/5906).
