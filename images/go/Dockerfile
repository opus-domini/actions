# syntax=docker/dockerfile:1.12

ARG GO_IMAGE=golang:1.26.5-bookworm@sha256:1ecb7edf62a0408027bd5729dfd6b1b8766e578e8df93995b225dfd0944eb651
ARG GOLANGCI_LINT_IMAGE=golangci/golangci-lint:v2.12.2@sha256:5cceeef04e53efe1470638d4b4b4f5ceefd574955ab3941b2d9a68a8c9ad5240

FROM ${GOLANGCI_LINT_IMAGE} AS golangci

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

COPY --from=golangci /usr/bin/golangci-lint /usr/local/bin/golangci-lint
COPY --from=govulncheck /out/govulncheck /usr/local/bin/govulncheck

LABEL org.opencontainers.image.title="Opus Domini Go CI runtime" \
      org.opencontainers.image.description="Pinned Go CI toolchain for trusted Ductor workloads" \
      org.opencontainers.image.source="https://github.com/opus-domini/actions" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      io.opus-domini.source-date-epoch="${SOURCE_DATE_EPOCH}"

ENV CI=true \
    GOCACHE=/cache/go-build \
    GOMODCACHE=/cache/go-mod \
    GOLANGCI_LINT_CACHE=/cache/golangci-lint \
    GOTMPDIR=/tmp/go \
    HOME=/home/ductor

WORKDIR /workspace
ENTRYPOINT []
CMD ["go", "version"]
