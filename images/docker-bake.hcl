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
  default = "1.6.0"
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
  default = "golang:1.27.0-bookworm@sha256:484ef6066fa69acb059fdfeda7ba2b8f7391f2ef6abc6f9b8411e669ebd56466"
}

variable "NODE_IMAGE" {
  default = "node:26-bookworm-slim@sha256:2d49d876e96237d76de412761cf05dbfe5aee325cc4406a4d41d5824c5bb8beb"
}

variable "GOLANGCI_LINT_IMAGE" {
  default = "golangci/golangci-lint:v2.13.1@sha256:d371321370bf2907bd13a8f6f8baff0e0ca7438d76fdf636b281eadf7e2305e3"
}

variable "DOCKER_CLI_IMAGE" {
  default = "docker:29.1.5-cli@sha256:05dfa31f4afd64888ef4cc0cbb1ab4d07a4828ef01cd29baa891fecbe50faf49"
}

variable "GORELEASER_IMAGE" {
  default = "goreleaser/goreleaser:v2.17.0@sha256:054eefd282c02233a2556ce2d1a60cd2f51dc565ffc2520dc38b5deb4dd1ad30"
}

variable "SYFT_IMAGE" {
  default = "anchore/syft:v1.46.0@sha256:473a60e3a58e29aca3aedb3e99e787bb4ef273917e44d10fcbea4330a07320bb"
}

variable "POSTGIS_IMAGE" {
  default = "postgis/postgis:18-3.6-alpine@sha256:4f8df0958dd321f520f917be5d0b338802928e4e1ebc4720f774168f4bbc2836"
}

variable "REDIS_IMAGE" {
  default = "redis:8-alpine@sha256:8096655e437712b07503796fb64d81359256cfcff0ab29d95a7da72863786efb"
}

variable "RUSTFS_IMAGE" {
  default = "rustfs/rustfs:latest@sha256:60f4f2f41ce95216f8cac676e69f9d90c0bfec458a3bc7fd7fb9b7c2452ac57a"
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
