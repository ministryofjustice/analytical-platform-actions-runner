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

## Managing Software Versions

This repository includes a Copilot prompt for maintenance in [`.github/prompts/`](.github/prompts/). To run it, open Copilot Chat in Visual Studio Code and type `/maintenance`. The prompt updates the Ubuntu base image digest and the pinned APT package versions in the [Dockerfile](./Dockerfile) and prepares a single pull request.

### Ubuntu

Dependabot is configured to do this in [`.github/dependabot.yml`](.github/dependabot.yml), but if you need to get the digest, do the following

```bash
docker pull --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

docker image inspect --format='{{ index .RepoDigests 0 }}' public.ecr.aws/ubuntu/ubuntu:24.04
```

### APT Packages

The latest versions of the APT packages can be obtained by visiting `https://packages.ubuntu.com/noble/${PACKAGE}` (for example [jq](https://packages.ubuntu.com/noble/jq)).

Alternatively, if you are not running in a dev container, you can run the following

```bash
docker run -it --rm --platform linux/amd64 public.ecr.aws/ubuntu/ubuntu:24.04

apt-get update

apt-cache policy ${PACKAGE} # for example curl, git or gpg
```

### GitHub Action Runner

Releases for GitHub Actions Runner are maintained on [GitHub](https://github.com/actions/runner/releases). Check here for the latest release and update `ACTIONS_RUNNER_VERSION` and `ACTIONS_RUNNER_PKG_SHA` accordingly.

`ACTIONS_RUNNER_PKG_SHA` is found under **SHA-256 Checksums** in the new version release notes. Use the checksum for `actions-runner-linux-x64-{VERSION_NUMBER}.tar.gz`

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

## Release Process

Once the `Dockerfile` and `test/container-structure-test.yml` have been patched (see [Managing Software Versions](#managing-software-versions)) and merged, cut a new release as follows:

1. Merge any open Dependabot pull requests in this repository.
2. Update and merge [`chart/Chart.yaml`](./chart/Chart.yaml) (`version` and `appVersion`) and [`chart/values.yaml`](./chart/values.yaml) (`image.tag`) with the intended new release tag, **before** creating the release.
   - Determine this tag first. It should match `ACTIONS_RUNNER_VERSION` pinned in the `Dockerfile`, unless a [release](https://github.com/ministryofjustice/analytical-platform-actions-runner/releases) already exists for that version, in which case append or increment a `-N` suffix (for example `2.337.0-1`, `2.337.0-2`).
3. Create a new [release](https://github.com/ministryofjustice/analytical-platform-actions-runner/releases) using that same tag, from the commit containing the merged chart changes.
   - [`chart-release.yml`](.github/workflows/chart-release.yml) and [`container-release.yml`](.github/workflows/container-release.yml) both trigger on tag push and package from that tagged commit, so the chart must already be updated and merged before the tag is created, or the old chart will be published against the new tag.
4. Update the images used in the [Modernisation Platform environments](https://github.com/ministryofjustice/modernisation-platform-environments) repository with the new release tag.
5. Deploy to the relevant Modernisation Platform environments.

## Maintenance

Maintenance of this component is scheduled in this [workflow](https://github.com/ministryofjustice/analytical-platform/blob/main/.github/workflows/schedule-issue-actions-runner.yml), which generates a maintenance ticket as per this [example](https://github.com/ministryofjustice/analytical-platform/issues/5906).
