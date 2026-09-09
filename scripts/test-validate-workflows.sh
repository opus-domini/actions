#!/usr/bin/env bash

set -euo pipefail

test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

assert_rejected() {
  local name="$1"
  local file="$2"
  local mutation="$3"
  local expected="$4"
  local case_root="${test_root}/${name}"

  mkdir "$case_root"
  cp -R .github images scripts README.md "$case_root/"
  sed -i -E "$mutation" "${case_root}/${file}"
  if cmp -s "$file" "${case_root}/${file}"; then
    printf 'test mutation did not change %s\n' "$file" >&2
    exit 1
  fi
  if (cd "$case_root" && bash scripts/validate-workflows.sh) \
    >"${case_root}/validation.log" 2>&1; then
    printf 'validator accepted %s\n' "$name" >&2
    exit 1
  fi
  if ! grep -Fq "$expected" "${case_root}/validation.log"; then
    cat "${case_root}/validation.log" >&2
    printf 'validator rejected %s for an unexpected reason\n' "$name" >&2
    exit 1
  fi
  printf 'rejected %s\n' "$name"
}

assert_rejected unpinned-secondary-image images/go-node/Dockerfile \
  's/^(ARG NODE_IMAGE=.*)@sha256:[0-9a-f]+$/\1/' \
  'argument NODE_IMAGE must pin its image by digest'
assert_rejected divergent-secondary-image images/go-node/Dockerfile \
  's/^(ARG NODE_IMAGE=.*@sha256:).*/\10000000000000000000000000000000000000000000000000000000000000000/' \
  'argument NODE_IMAGE must match images/versions.env'
assert_rejected divergent-bake-image images/docker-bake.hcl \
  's/node:[^"]+/node:invalid/' \
  'Bake argument NODE_IMAGE must match images/versions.env'
assert_rejected divergent-dockerfile-tool images/go-release/Dockerfile \
  's/^ARG NPM_VERSION=.*/ARG NPM_VERSION=0.0.0/' \
  'argument NPM_VERSION must match images/versions.env'
assert_rejected divergent-hosted-npm .github/workflows/ci.yml \
  's/NPM_VERSION: .*/NPM_VERSION: 0.0.0/' \
  'job full-hosted must contain: NPM_VERSION:'
assert_rejected divergent-hosted-node .github/workflows/ci.yml \
  's/node-version: .*/node-version: "0.0.0"/' \
  'job full-hosted must contain: node-version:'
assert_rejected divergent-validator-go .github/workflows/validate.yml \
  's/go-version: .*/go-version: 0.0.0/' \
  'must contain: go-version:'
