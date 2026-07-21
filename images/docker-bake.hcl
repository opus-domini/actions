variable "REGISTRY" {
  default = "ghcr.io/opus-domini"
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
  default = "12.0.1"
}

variable "GOVULNCHECK_VERSION" {
  default = "1.6.0"
}

variable "GO_IMAGE" {
  default = "golang:1.26.5-bookworm@sha256:1ecb7edf62a0408027bd5729dfd6b1b8766e578e8df93995b225dfd0944eb651"
}

variable "NODE_IMAGE" {
  default = "node:26-bookworm-slim@sha256:2d49d876e96237d76de412761cf05dbfe5aee325cc4406a4d41d5824c5bb8beb"
}

variable "GOLANGCI_LINT_IMAGE" {
  default = "golangci/golangci-lint:v2.12.2@sha256:5cceeef04e53efe1470638d4b4b4f5ceefd574955ab3941b2d9a68a8c9ad5240"
}

variable "GORELEASER_IMAGE" {
  default = "goreleaser/goreleaser:v2.17.0@sha256:054eefd282c02233a2556ce2d1a60cd2f51dc565ffc2520dc38b5deb4dd1ad30"
}

variable "SYFT_IMAGE" {
  default = "anchore/syft:v1.46.0@sha256:473a60e3a58e29aca3aedb3e99e787bb4ef273917e44d10fcbea4330a07320bb"
}

variable "COSIGN_IMAGE" {
  default = "ghcr.io/sigstore/cosign/cosign:v3.1.1@sha256:6bbe0d281d955c79f85b325f0f7e651c1bcab5a4fa4ad4903d74955178a3b2eb"
}

group "default" {
  targets = ["go", "go-node", "go-release"]
}

target "common" {
  context    = "images"
  platforms  = ["linux/amd64"]
  provenance = "mode=max"
  sbom       = true
  args = {
    BUILD_DATE          = BUILD_DATE
    GO_IMAGE            = GO_IMAGE
    NODE_IMAGE          = NODE_IMAGE
    GOLANGCI_LINT_IMAGE = GOLANGCI_LINT_IMAGE
    GORELEASER_IMAGE    = GORELEASER_IMAGE
    GOVULNCHECK_VERSION = GOVULNCHECK_VERSION
    NPM_VERSION         = NPM_VERSION
    SYFT_IMAGE          = SYFT_IMAGE
    COSIGN_IMAGE        = COSIGN_IMAGE
    REVISION            = REVISION
    SOURCE_DATE_EPOCH   = SOURCE_DATE_EPOCH
    VERSION             = TAG
  }
}

target "go" {
  inherits   = ["common"]
  dockerfile = "go/Dockerfile"
  tags       = ["${REGISTRY}/ci-go:${TAG}"]
}

target "go-node" {
  inherits   = ["common"]
  dockerfile = "go-node/Dockerfile"
  tags       = ["${REGISTRY}/ci-go-node:${TAG}"]
}

target "go-release" {
  inherits   = ["common"]
  dockerfile = "go-release/Dockerfile"
  tags       = ["${REGISTRY}/ci-go-release:${TAG}"]
}
