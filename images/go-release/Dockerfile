# syntax=docker/dockerfile:1.12

ARG GO_IMAGE=golang:1.27.1-bookworm@sha256:648f440f42a0958804efb24df176f806f9d353b41f1c0627f666428e40310f6b
ARG NODE_IMAGE=node:26.8.1-bookworm-slim@sha256:367679cf9792759492a486e4aa4b421764d71a9546a6dae8aab81a99eb797b3e
ARG GORELEASER_IMAGE=goreleaser/goreleaser:v2.18.1@sha256:92b918cc587dce6321b5fafc57ba93942a38592a7fbdb6cc3e300418b9f03a7e
ARG SYFT_IMAGE=anchore/syft:v1.51.1@sha256:95fe0835e5bebc6f8b1f8acef68d47d63d594ef4c0f25c097ff853b23cbac74c

FROM ${NODE_IMAGE} AS node
ARG NPM_VERSION=12.0.2
RUN npm install --global "npm@${NPM_VERSION}" \
    && npm cache clean --force

FROM ${GORELEASER_IMAGE} AS goreleaser
FROM ${SYFT_IMAGE} AS syft

FROM ${GO_IMAGE}
ARG REVISION=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG GH_VERSION=2.23.0+dfsg1-1
ARG JQ_VERSION=1.6-2.1+deb12u2
ARG LIBONIG_VERSION=6.9.8-1
ARG SOURCE_DATE_EPOCH=0
ARG VERSION=dev

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      "gh=${GH_VERSION}" \
      "jq=${JQ_VERSION}" \
      "libjq1=${JQ_VERSION}" \
      "libonig5=${LIBONIG_VERSION}" \
    && rm -rf /var/lib/apt/lists/*
COPY --from=node /usr/local/ /usr/local/
COPY --from=goreleaser /usr/bin/goreleaser /usr/local/bin/goreleaser
COPY --from=syft /syft /usr/local/bin/syft
ADD --checksum=sha256:4629c757b7618056f8ddd7e2625ae9fdd94c0372a65049520bc7d9df9efc7f71 \
    https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-linux-amd64 \
    /usr/local/bin/cosign
RUN chmod 0755 /usr/local/bin/cosign

LABEL org.opencontainers.image.title="Opus Domini Go release runtime" \
      org.opencontainers.image.description="Pinned Go release toolchain for trusted Ductor workloads" \
      org.opencontainers.image.source="https://github.com/opus-domini/actions" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.opus-domini.source-date-epoch="${SOURCE_DATE_EPOCH}"

ENV CI=true \
    GOCACHE=/cache/go-build \
    GOMODCACHE=/cache/go-mod \
    npm_config_cache=/cache/npm \
    GOTMPDIR=/tmp/go \
    HOME=/home/ductor

WORKDIR /workspace
ENTRYPOINT []
CMD ["goreleaser", "--version"]
