# Self-contained, pinned Flutter environment for reproducible golden tests.
# Depends only on first-party sources (Debian + the official Flutter SDK
# release), so there is no reliance on third-party prebuilt images.
#
# Used both in CI and locally via `tool/docker_test.sh`, so the environment that
# generates the goldens is byte-for-byte the one that verifies them.
FROM debian:bookworm-slim

ARG FLUTTER_VERSION=3.44.1

ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/* \
 && curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C /opt \
 && git config --global --add safe.directory '*' \
 && flutter --version \
 && flutter precache --universal

WORKDIR /app
