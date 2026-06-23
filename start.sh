#!/bin/bash
set -e

if [ -z "$GITHUB_REPO_URL" ]; then
  echo "ERROR: GITHUB_REPO_URL is required"
  exit 1
fi

if [ -z "$RUNNER_TOKEN" ]; then
  echo "ERROR: RUNNER_TOKEN is required"
  exit 1
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
  ./config.sh remove --unattended --token "$RUNNER_TOKEN"
}

trap cleanup EXIT

echo "Starting runner..."
./run.sh