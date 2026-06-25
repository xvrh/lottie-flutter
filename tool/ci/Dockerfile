# Self-contained, pinned Flutter environment for reproducible golden tests.
# Depends only on first-party sources (Debian + the Flutter git repo), so there
# is no reliance on third-party prebuilt images.
#
# Built for the host architecture: locally on Apple Silicon it builds arm64, and
# CI runs on arm64 (ubuntu-24.04-arm) too. Keeping both sides native arm64
# avoids the QEMU-emulation rendering drift that breaks golden comparisons.
# Flutter ships no arm64 Linux SDK tarball, so we clone the pinned tag and let
# `flutter precache` fetch the matching engine artifacts for the architecture.
#
# Used both in CI and locally via `tool/docker_test.sh`, so the environment that
# generates the goldens is the one that verifies them.
FROM debian:bookworm-slim

ARG FLUTTER_VERSION=3.44.1

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/* \
 && git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
 && git config --global --add safe.directory '*' \
 && flutter --version \
 && flutter precache --universal --linux

WORKDIR /app
