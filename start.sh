#!/bin/bash
set -e

if [ -z "$GITHUB_REPO_URL" ]; then
  echo "ERROR: GITHUB_REPO_URL is required"
  exit 1
fi

if [ -z "$RUNNER_TOKEN" ]; then
  if [ -z "$GITHUB_PAT" ] || [ -z "$GITHUB_OWNER" ] || [ -z "$GITHUB_REPO" ]; then
    echo "ERROR: RUNNER_TOKEN is missing, and GITHUB_PAT/GITHUB_OWNER/GITHUB_REPO are not set"
    exit 1
  fi

  echo "Requesting fresh runner registration token from GitHub..."

RUNNER_TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token")

RUNNER_TOKEN=$(echo "$RUNNER_TOKEN_RESPONSE" | jq -r .token)

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
  echo "ERROR: Failed to get runner registration token"
  echo "$RUNNER_TOKEN_RESPONSE"
  exit 1
 fi
fi



RUNNER_VERSION="2.317.0"

cd /home/runner

echo "Downloading GitHub Actions runner..."

curl -o actions-runner-linux-arm64.tar.gz -L \
"https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-arm64-${RUNNER_VERSION}.tar.gz"

tar xzf actions-runner-linux-arm64.tar.gz
rm actions-runner-linux-arm64.tar.gz

echo "Configuring runner..."

./config.sh \
  --url "$GITHUB_REPO_URL" \
  --token "$RUNNER_TOKEN" \
  --name "${RUNNER_NAME:-platform-ci-runner}" \
  --labels "${RUNNER_LABELS:-self-hosted,platform-runner}" \
  --runnergroup "${RUNNER_GROUP:-Default}" \
  --unattended \
  --replace

cleanup() {
  echo "Removing runner registration..."
  ./config.sh remove --token "$RUNNER_TOKEN" || true
}
trap cleanup EXIT

echo "Starting runner..."
./run.sh