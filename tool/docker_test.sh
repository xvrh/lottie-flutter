#!/usr/bin/env bash
# Run the package tests inside a pinned, self-built Flutter Linux image so that
# golden files are reproducible regardless of the host OS or local Flutter
# version. This mirrors the CI environment exactly (same Dockerfile, same arch).
#
#   tool/docker_test.sh                   # run all tests
#   tool/docker_test.sh --update-goldens  # (re)generate the golden files
#   tool/docker_test.sh test/golden_test.dart --update-goldens
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="lottie-flutter-ci"

docker build --platform linux/amd64 -t "$IMAGE" "$ROOT/tool/ci"

exec docker run --rm -i \
  --platform linux/amd64 \
  -v "$ROOT":/app \
  -w /app \
  "$IMAGE" \
  bash -c "flutter pub get && flutter test ${*:-}"
