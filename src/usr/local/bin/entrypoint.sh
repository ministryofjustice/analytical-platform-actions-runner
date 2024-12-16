#!/usr/bin/env bash
# shellcheck disable=SC2086

set -euo pipefail

ACTIONS_RUNNER_DIRECTORY="/actions-runner"
EPHEMERAL="${EPHEMERAL:-"false"}"
RUNNER_GROUP="${RUNNER_GROUP:-""}"

echo "Runner parameters:"
echo "  Repository: ${GITHUB_REPOSITORY}"
echo "  Runner Name: $(hostname)"
echo "  Runner Labels: ${RUNNER_LABELS}"

echo "Obtaining registration token"
getRegistrationToken=$(
  curl \
    --silent \
    --location \
    --request "POST" \
    --header "X-GitHub-Api-Version: 2022-11-28" \
    --header "Authorization: Bearer ${GITHUB_TOKEN}" \
    https://api.github.com/repos/"${GITHUB_REPOSITORY}"/actions/runners/registration-token | jq -r '.token'
)
export getRegistrationToken

echo "Checking if registration token exists"
if [[ -z "${getRegistrationToken}" ]]; then
  echo "Failed to obtain registration token"
  exit 1
else
  echo "Registration token obtained successfully"
  REPO_TOKEN="${getRegistrationToken}"
fi

if [[ "${EPHEMERAL}" == "true" ]]; then
  EPHEMERAL_FLAG="--ephemeral"
  trap 'echo "Shutting down runner"; exit' SIGINT SIGQUIT SIGTERM INT TERM QUIT
else
  EPHEMERAL_FLAG=""
fi

if [[ -z "${RUNNER_GROUP}" ]]; then
  RUNNER_GROUP_FLAG=""
else
  RUNNER_GROUP_FLAG="--runnergroup ${RUNNER_GROUP}"
fi

echo "Configuring runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" ${EPHEMERAL_FLAG} \
  --unattended \
  --disableupdate \
  --url "https://github.com/${GITHUB_REPOSITORY}" \
  --token "${REPO_TOKEN}" \
  --name "$(hostname)" \
  --labels "${RUNNER_LABELS}" ${RUNNER_GROUP_FLAG}

echo "Starting runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/run.sh"
