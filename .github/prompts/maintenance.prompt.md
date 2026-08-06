---
description: "Update the Ubuntu base image digest, pinned APT package versions, Microsoft ODBC driver for SQL Server versions, and test expectations in the Dockerfile and test files, then open a pull request"
tools:
  [
    "search/codebase",
    "search",
    "edit/editFiles",
    "execute/runInTerminal",
    "execute/getTerminalOutput",
  ]
---

# Maintenance

Perform maintenance on the `Dockerfile` and `test/container-structure-test.yml`. Update the base image digest, the pinned APT package versions, the Microsoft ODBC driver for SQL Server versions, and the corresponding test expectations together, and open a single pull request. Read the current base image, tag, and package list from the `Dockerfile`; do not assume a specific Ubuntu version or package set.

## Objective

In one pull request, for the base image and packages already declared in the `Dockerfile`:

1. Update the pinned base image digest to the latest published digest for the image and tag in the `FROM` line (for `linux/amd64`).
2. Refresh the pinned APT package versions to the latest available for that base image, preserving the current package list.
3. Update the Microsoft ODBC driver for SQL Server versions (`MICROSOFT_SQL_ODBC_VERSION` and `MICROSOFT_SQL_TOOLS_VERSION`) to the latest available versions. First check for updates within the current major version. If no updates are available within the current major version, check the next major version and upgrade if available (with a warning in the PR description).
4. Update the test expectations in `test/container-structure-test.yml` to match the new versions.

Do not assume a specific Ubuntu version or package set. Always read the current values from the `Dockerfile`.

## Required Outcome

1. Create a single maintenance branch.
2. Update the Ubuntu base image digest in the `FROM` line.
3. Update the pinned APT package versions.
4. Update the Microsoft ODBC driver for SQL Server versions to the latest available. If upgrading to a new major version (no updates available for current major version), include a warning in the PR description.
5. Update the test file to reflect the new versions.
6. Commit the changes using Conventional Commits.
7. Push the branch and open a pull request with a clear title and description.

## Execution Steps

1. Create a maintenance branch.

```bash
git checkout -b "chore/maintenance-dockerfile-$(date +%Y%m%d-%H%M%S)"
```

2. Update the base image digest.

- Read the base image reference (`<image>:<tag>`) from the `FROM` line in `Dockerfile`. Use whatever image and tag are currently pinned; do not assume a specific Ubuntu version.
- Pull that exact image for `linux/amd64`.

```bash
IMAGE="$(grep -oP '(?<=^FROM )[^@[:space:]]+' Dockerfile)"
docker pull --platform linux/amd64 "$IMAGE"
```

- Retrieve the current repository digest.

```bash
docker image inspect --format='{{ index .RepoDigests 0 }}' "$IMAGE"
```

- Update the `@sha256:...` digest on the `FROM` line to the new value, keeping the image and tag unchanged.

3. Update the pinned APT package versions.

- Read the list of pinned packages from the `apt-get install` block in `Dockerfile`. Use exactly that set of packages; do not add or remove any.
- Start a temporary container using the same base image and check the candidate versions for those packages.

```bash
docker run --rm --platform linux/amd64 "$IMAGE" \
  bash -c "apt-get update && apt-cache policy <packages-from-dockerfile>"
```

- Update each pinned version in `Dockerfile` to the reported candidate, preserving every package currently listed.

4. Update the Microsoft ODBC driver for SQL Server versions.

- Read the current `MICROSOFT_SQL_ODBC_VERSION` and `MICROSOFT_SQL_TOOLS_VERSION` from the environment variables in `Dockerfile`.
- Extract the current major version number from the package names in the `apt-get install` block (e.g., `msodbcsql18` → major version `18`).
- Start a temporary container using the same base image and check the candidate versions for the current major version.

```bash
# Extract current major version from Dockerfile (e.g., 18 from msodbcsql18)
CURRENT_MAJOR_VERSION="$(grep -oP 'msodbcsql\K\d+' Dockerfile | head -1)"

docker run --rm --platform linux/amd64 "$IMAGE" \
  bash -c "apt-get update --yes && \
  apt-get install --yes curl gpg && \
  curl --location --fail-with-body \
    'https://packages.microsoft.com/keys/microsoft.asc' \
    --output microsoft.asc && \
  cat microsoft.asc | gpg --dearmor --output microsoft-prod.gpg && \
  install -D --owner root --group root --mode 644 microsoft-prod.gpg /usr/share/keyrings/microsoft-prod.gpg && \
  source /etc/os-release && \
  echo \"deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/\${VERSION_ID}/prod \$(lsb_release -cs) main\" > /etc/apt/sources.list.d/mssql-release.list && \
  apt-get update --yes && \
  apt-cache policy msodbcsql${CURRENT_MAJOR_VERSION} && \
  apt-cache policy mssql-tools${CURRENT_MAJOR_VERSION}"
```

- Check if newer patch/minor versions are available for the current major version:
  - **If yes**: Update `MICROSOFT_SQL_ODBC_VERSION` and `MICROSOFT_SQL_TOOLS_VERSION` to the new candidate versions and proceed with the PR.
  - **If no** (current versions are already the latest for this major version): Check for the next major version.

```bash
# Only run this if current major version has no updates available
NEXT_MAJOR_VERSION=$((CURRENT_MAJOR_VERSION + 1))

docker run --rm --platform linux/amd64 "$IMAGE" \
  bash -c "apt-get update --yes && \
  apt-get install --yes curl gpg && \
  curl --location --fail-with-body \
    'https://packages.microsoft.com/keys/microsoft.asc' \
    --output microsoft.asc && \
  cat microsoft.asc | gpg --dearmor --output microsoft-prod.gpg && \
  install -D --owner root --group root --mode 644 microsoft-prod.gpg /usr/share/keyrings/microsoft-prod.gpg && \
  source /etc/os-release && \
  echo \"deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/\${VERSION_ID}/prod \$(lsb_release -cs) main\" > /etc/apt/sources.list.d/mssql-release.list && \
  apt-get update --yes && \
  apt-cache policy msodbcsql${NEXT_MAJOR_VERSION} 2>/dev/null || echo 'Not available' && \
  apt-cache policy mssql-tools${NEXT_MAJOR_VERSION} 2>/dev/null || echo 'Not available'"
```

- If the next major version is available:
  - **Update the Dockerfile** to use the new major version:
    - Change package names (e.g., `msodbcsql18` → `msodbcsql19`)
    - Update `MICROSOFT_SQL_ODBC_VERSION` and `MICROSOFT_SQL_TOOLS_VERSION` to the new versions
    - Update the PATH environment variable (e.g., `/opt/mssql-tools18/bin` → `/opt/mssql-tools19/bin`)
  - **Include a warning section** in the PR description (see below)

- If the next major version is not available, skip this step (no updates needed).

5. Update the test file to reflect the new versions.

- Update `test/container-structure-test.yml` to match the new versions from the `Dockerfile`:
  - Update the `actions-runner` command test `expectedOutput` to match the new `ACTIONS_RUNNER_VERSION`.
  - Update the `sqlcmd` command test `expectedOutput` to match the new `MICROSOFT_SQL_TOOLS_VERSION` (note: the version format in the output may differ slightly from the package version - verify the actual output format).
  - Update the Microsoft ODBC library file path test to match the new `MICROSOFT_SQL_ODBC_VERSION` (the path format is `/opt/microsoft/msodbcsql{MAJOR}/lib64/libmsodbcsql-{MAJOR}.{MINOR}.so.{PATCH}.{BUILD}`).
  - If the major version was upgraded (e.g., from 18 to 19), also update the major version number in the file path (e.g., `/opt/microsoft/msodbcsql18/...` → `/opt/microsoft/msodbcsql19/...`).

6. Confirm the `Dockerfile` still lists the same packages and the same image and tag as before (only digest and versions should differ).

7. Commit the changes to `Dockerfile` and `test/container-structure-test.yml` using [Conventional Commits](https://www.conventionalcommits.org/) (`build` type).

8. Push the branch and open the pull request with the GitHub CLI.

- The `git commit`, `git push`, and `gh` steps need the local Git/GitHub credentials and network access. When the terminal is sandboxed these are hidden, so run these steps with the required access (outside the sandbox) rather than stopping. A sandboxed `gh auth status` may report "not logged in" even when the terminal is authenticated; do not treat that as a blocker.
- Set an explicit PR title: a [Conventional Commits](https://www.conventionalcommits.org/) `build:` summary that matches the commit (for example, `build: update base image digest, apt package versions, and test expectations`). Do not use `gh pr create --fill`, which derives the title from the branch name.
- Write the PR description to a temporary file and pass it with `--body-file` to avoid shell-escaping issues. Use Markdown, for example:
- In the PR description, wrap all SHA values (for example `sha256:...`) in backticks, including both old and new digest values in comparisons.

  ```markdown
  ## Summary

  Updates the `Dockerfile` build dependencies.

  ### Base image

  - `<image>:<tag>` digest: `sha256:<old-sha256>` -> `sha256:<new-sha256>` (image and tag unchanged)

  ### APT packages

  Include this section only when one or more package versions changed.

  | Package | Before  | After   |
  | ------- | ------- | ------- |
  | curl    | `<old>` | `<new>` |

  If no package versions changed, omit the entire `### APT packages` section (including the table) and add a single line in `## Summary`: `APT package versions already up to date.`

  ### Microsoft SQL ODBC and Tools

  Include this section only when one or more Microsoft SQL package versions changed.

  | Package       | Before  | After   |
  | ------------- | ------- | ------- |
  | msodbcsql18   | `<old>` | `<new>` |
  | mssql-tools18 | `<old>` | `<new>` |

  If no Microsoft SQL package versions changed, omit the entire `### Microsoft SQL ODBC and Tools` section (including the table) and add a single line in `## Summary`: `Microsoft SQL package versions already up to date.`

  Note any packages that could not be upgraded and why.

  ### ⚠️ Major Version Upgrade

  Include this section only when Microsoft SQL packages were upgraded to a new major version (e.g., from msodbcsql18 to msodbcsql19).

  Example:
  ```markdown
  ⚠️ **This PR includes a major version upgrade** of Microsoft SQL ODBC and Tools from version 18 to version 19.

  This upgrade was applied because no further updates are available for version 18.

  Major version upgrades may include breaking changes. The following changes were made:
  - Package names updated: `msodbcsql18` → `msodbcsql19`, `mssql-tools18` → `mssql-tools19`
  - PATH updated: `/opt/mssql-tools18/bin` → `/opt/mssql-tools19/bin`
  - Test expectations updated in `test/container-structure-test.yml`

  Please review and test carefully before merging.
  ```

  ### Tests

  Updated `test/container-structure-test.yml` to reflect the new version expectations.

  Building and testing is handled by CI/CD.
  ```

- Create the pull request:

  ```bash
  git push -u origin <branch>
  gh pr create --base main --head <branch> --title "<title>" --body-file <body-file>
  ```

- Report the URL of the created pull request.

## Guardrails

- Keep the base image repository and tag unchanged; derive them from the existing `FROM` line and only update the digest. Do not change the Ubuntu version.
- Keep platform assumption aligned to `linux/amd64`.
- Do not add or remove packages. Update exactly the packages already pinned in the `Dockerfile`.
- Keep all package installs pinned to explicit versions.
- For Microsoft ODBC driver for SQL Server: First check for updates within the current major version. Only upgrade to the next major version if no updates are available for the current major version.
- When upgrading Microsoft SQL packages to a new major version, update all related components (package names, PATH environment variable, and test expectations) and include a warning in the PR description.
- Update the test file (`test/container-structure-test.yml`) to match the new versions in the `Dockerfile`.
- Deliver all updates in the same branch and pull request.
- Use [Conventional Commits](https://www.conventionalcommits.org/) for both the commit message and the PR title (use the `build` type).
