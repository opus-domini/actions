# syntax=docker/dockerfile:1.12

ARG GO_IMAGE=golang:1.26.5-bookworm@sha256:1ecb7edf62a0408027bd5729dfd6b1b8766e578e8df93995b225dfd0944eb651
ARG NODE_IMAGE=node:26-bookworm-slim@sha256:2d49d876e96237d76de412761cf05dbfe5aee325cc4406a4d41d5824c5bb8beb
ARG GORELEASER_IMAGE=goreleaser/goreleaser:v2.17.0@sha256:054eefd282c02233a2556ce2d1a60cd2f51dc565ffc2520dc38b5deb4dd1ad30
ARG SYFT_IMAGE=anchore/syft:v1.46.0@sha256:473a60e3a58e29aca3aedb3e99e787bb4ef273917e44d10fcbea4330a07320bb
ARG COSIGN_IMAGE=ghcr.io/sigstore/cosign/cosign:v3.1.1@sha256:6bbe0d281d955c79f85b325f0f7e651c1bcab5a4fa4ad4903d74955178a3b2eb

FROM ${NODE_IMAGE} AS node
ARG NPM_VERSION=12.0.1
RUN npm install --global "npm@${NPM_VERSION}" \
    && npm cache clean --force

FROM ${GORELEASER_IMAGE} AS goreleaser
FROM ${SYFT_IMAGE} AS syft
FROM ${COSIGN_IMAGE} AS cosign

FROM ${GO_IMAGE}
ARG REVISION=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG SOURCE_DATE_EPOCH=0
ARG VERSION=dev

COPY --from=node /usr/local/ /usr/local/
COPY --from=goreleaser /usr/bin/goreleaser /usr/local/bin/goreleaser
COPY --from=syft /syft /usr/local/bin/syft
COPY --from=cosign /ko-app/cosign /usr/local/bin/cosign

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
