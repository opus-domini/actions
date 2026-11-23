# syntax=docker/dockerfile:1.12

ARG GO_IMAGE=golang:1.27.4-bookworm@sha256:4fa7c968ba93f1635670522dbb01a2c78150443e1385746924566079f36570ea
ARG GOLANGCI_LINT_IMAGE=golangci/golangci-lint:v2.15.0@sha256:fbfcfd12a6f8d7f1b97b3362ca80fc2a244d46863148c73cb88e7793af96c481

FROM ${GOLANGCI_LINT_IMAGE} AS golangci

FROM ${GO_IMAGE} AS govulncheck
ARG GOVULNCHECK_VERSION=1.10.0
ENV GOMAXPROCS=2 GOFLAGS=-p=2
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
