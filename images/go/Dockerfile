# syntax=docker/dockerfile:1.12

ARG GO_IMAGE=golang:1.27.1-bookworm@sha256:648f440f42a0958804efb24df176f806f9d353b41f1c0627f666428e40310f6b
ARG GOLANGCI_LINT_IMAGE=golangci/golangci-lint:v2.13.2@sha256:ba07dffad130794ae79ebaa0056809d18c0168f3f846480ffd3eb6c04578b83d

FROM ${GOLANGCI_LINT_IMAGE} AS golangci

FROM ${GO_IMAGE} AS govulncheck
ARG GOVULNCHECK_VERSION=1.7.0
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
