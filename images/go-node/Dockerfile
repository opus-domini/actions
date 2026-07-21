# syntax=docker/dockerfile:1.12

ARG GO_IMAGE=golang:1.26.5-bookworm@sha256:1ecb7edf62a0408027bd5729dfd6b1b8766e578e8df93995b225dfd0944eb651
ARG NODE_IMAGE=node:26-bookworm-slim@sha256:2d49d876e96237d76de412761cf05dbfe5aee325cc4406a4d41d5824c5bb8beb
ARG GOLANGCI_LINT_IMAGE=golangci/golangci-lint:v2.12.2@sha256:5cceeef04e53efe1470638d4b4b4f5ceefd574955ab3941b2d9a68a8c9ad5240
ARG DOCKER_CLI_IMAGE=docker:29.1.5-cli@sha256:05dfa31f4afd64888ef4cc0cbb1ab4d07a4828ef01cd29baa891fecbe50faf49

FROM ${NODE_IMAGE} AS node
ARG NPM_VERSION=12.0.1
RUN npm install --global "npm@${NPM_VERSION}" \
    && npm cache clean --force

FROM ${GOLANGCI_LINT_IMAGE} AS golangci

FROM ${DOCKER_CLI_IMAGE} AS docker-cli

FROM ${GO_IMAGE} AS govulncheck
ARG GOVULNCHECK_VERSION=1.6.0
RUN --mount=type=cache,target=/go/pkg/mod,sharing=locked \
    GOBIN=/out CGO_ENABLED=0 go install \
      "golang.org/x/vuln/cmd/govulncheck@v${GOVULNCHECK_VERSION}"

FROM ${GO_IMAGE}
ARG REVISION=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z
ARG SOURCE_DATE_EPOCH=0
ARG VERSION=dev

COPY --from=node /usr/local/ /usr/local/
COPY --from=golangci /usr/bin/golangci-lint /usr/local/bin/golangci-lint
COPY --from=govulncheck /out/govulncheck /usr/local/bin/govulncheck
COPY --from=docker-cli /usr/local/bin/docker /usr/local/bin/docker

LABEL org.opencontainers.image.title="Opus Domini Go and Node CI runtime" \
      org.opencontainers.image.description="Pinned Go and Node CI toolchain for trusted Ductor workloads" \
      org.opencontainers.image.source="https://github.com/opus-domini/actions" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.opus-domini.source-date-epoch="${SOURCE_DATE_EPOCH}"

ENV CI=true \
    GOCACHE=/cache/go-build \
    GOMODCACHE=/cache/go-mod \
    GOLANGCI_LINT_CACHE=/cache/golangci-lint \
    npm_config_cache=/cache/npm \
    GOTMPDIR=/tmp/go \
    HOME=/home/ductor

WORKDIR /workspace
ENTRYPOINT []
CMD ["node", "--version"]
