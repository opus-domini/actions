variable "IMAGE_PREFIX" {
  default = "ductor.publisher"
}

variable "TAG" {
  default = "local"
}

variable "REVISION" {
  default = "unknown"
}

variable "BUILD_DATE" {
  default = "1970-01-01T00:00:00Z"
}

variable "SOURCE_DATE_EPOCH" {
  default = "0"
}

variable "NPM_VERSION" {
  default = "12.0.2"
}

variable "GOVULNCHECK_VERSION" {
  default = "1.8.0"
}

variable "GH_VERSION" {
  default = "2.23.0+dfsg1-1"
}

variable "JQ_VERSION" {
  default = "1.6-2.1+deb12u2"
}

variable "LIBONIG_VERSION" {
  default = "6.9.8-1"
}

variable "GO_IMAGE" {
  default = "golang:1.27.1-bookworm@sha256:648f440f42a0958804efb24df176f806f9d353b41f1c0627f666428e40310f6b"
}

variable "NODE_IMAGE" {
  default = "node:26.8.1-bookworm-slim@sha256:367679cf9792759492a486e4aa4b421764d71a9546a6dae8aab81a99eb797b3e"
}

variable "GOLANGCI_LINT_IMAGE" {
  default = "golangci/golangci-lint:v2.13.2@sha256:ba07dffad130794ae79ebaa0056809d18c0168f3f846480ffd3eb6c04578b83d"
}

variable "DOCKER_CLI_IMAGE" {
  default = "docker:29.8.0-cli@sha256:eccaacfeed644c7de222ff047483568cb988dde95476fbaaf10ea2d04921bb66"
}

variable "GORELEASER_IMAGE" {
  default = "goreleaser/goreleaser:v2.18.1@sha256:92b918cc587dce6321b5fafc57ba93942a38592a7fbdb6cc3e300418b9f03a7e"
}

variable "SYFT_IMAGE" {
  default = "anchore/syft:v1.51.1@sha256:95fe0835e5bebc6f8b1f8acef68d47d63d594ef4c0f25c097ff853b23cbac74c"
}

variable "POSTGIS_IMAGE" {
  default = "postgis/postgis:18-3.6-alpine@sha256:ffcf0c4b904e41b9779f8098007fb5a9484025319c18c70cf8e1bcebb742b9b7"
}

variable "REDIS_IMAGE" {
  default = "redis:8-alpine@sha256:becdda6c7f4b3fb42e42fd7f120bbf5c54c4caaaf16f26da24e4563d2c1f0576"
}

variable "RUSTFS_IMAGE" {
  default = "rustfs/rustfs:latest@sha256:b7014e0ce2bc703c1316b3ef760e29dfae61fe4a50d1a66fa89638e0f8ea211f"
}

variable "RYUK_IMAGE" {
  default = "testcontainers/ryuk:0.14.0@sha256:7c1a8a9a47c780ed0f983770a662f80deb115d95cce3e2daa3d12115b8cd28f0"
}

group "default" {
  targets = ["go", "go-node", "go-release", "postgis", "redis", "rustfs", "ryuk"]
}

target "common" {
  context    = "images"
  platforms  = ["linux/amd64"]
  args = {
    BUILD_DATE          = BUILD_DATE
    DOCKER_CLI_IMAGE    = DOCKER_CLI_IMAGE
    GO_IMAGE            = GO_IMAGE
    NODE_IMAGE          = NODE_IMAGE
    GOLANGCI_LINT_IMAGE = GOLANGCI_LINT_IMAGE
    GORELEASER_IMAGE    = GORELEASER_IMAGE
    GOVULNCHECK_VERSION = GOVULNCHECK_VERSION
    GH_VERSION          = GH_VERSION
    JQ_VERSION          = JQ_VERSION
    LIBONIG_VERSION     = LIBONIG_VERSION
    NPM_VERSION         = NPM_VERSION
    SYFT_IMAGE          = SYFT_IMAGE
    POSTGIS_IMAGE       = POSTGIS_IMAGE
    REDIS_IMAGE         = REDIS_IMAGE
    REVISION            = REVISION
    SOURCE_DATE_EPOCH   = SOURCE_DATE_EPOCH
    RUSTFS_IMAGE        = RUSTFS_IMAGE
    RYUK_IMAGE          = RYUK_IMAGE
    VERSION             = TAG
  }
}

target "go" {
  inherits   = ["common"]
  dockerfile = "go/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/go:${REVISION}"]
}

target "go-node" {
  inherits   = ["common"]
  dockerfile = "go-node/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/go-node:${REVISION}"]
}

target "go-release" {
  inherits   = ["common"]
  dockerfile = "go-release/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/go-release:${REVISION}"]
}

target "postgis" {
  inherits   = ["common"]
  dockerfile = "postgis/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/postgis:${REVISION}"]
}

target "redis" {
  inherits   = ["common"]
  dockerfile = "redis/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/redis:${REVISION}"]
}

target "rustfs" {
  inherits   = ["common"]
  dockerfile = "rustfs/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/rustfs:${REVISION}"]
}

target "ryuk" {
  inherits   = ["common"]
  dockerfile = "ryuk/Dockerfile"
  tags       = ["${IMAGE_PREFIX}/ryuk:${REVISION}"]
}
