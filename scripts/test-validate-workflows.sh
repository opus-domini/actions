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

# Each Go runtime must use the same reviewed compiler image, including the
# weekly vulnerability scan's generic Go runtime.
for runtime in go go-node go-release; do
  assert_rejected "stale-go-image-${runtime}" "images/${runtime}/Dockerfile" \
    's|^ARG GO_IMAGE=.*|ARG GO_IMAGE=golang:1.27.2-bookworm@sha256:5cf287a799e6b94384bad13d16b14904c531f51ba65792237e122ce42b392f61|' \
    'argument GO_IMAGE must match images/versions.env'
done

assert_rejected unpinned-secondary-image images/go-node/Dockerfile \
  's/^(ARG NODE_IMAGE=.*)@sha256:[0-9a-f]+$/\1/' \
  'argument NODE_IMAGE must pin its image by digest'
assert_rejected divergent-secondary-image images/go-node/Dockerfile \
  's/^(ARG NODE_IMAGE=.*@sha256:).*/\10000000000000000000000000000000000000000000000000000000000000000/' \
  'argument NODE_IMAGE must match images/versions.env'
assert_rejected divergent-bake-image images/docker-bake.hcl \
  's/node:[^"]+/node:invalid/' \
  'Bake argument NODE_IMAGE must match images/versions.env'
assert_rejected unpinned-node-ci-image images/node/Dockerfile \
  's/^(ARG NODE_CI_IMAGE=.*)@sha256:[0-9a-f]+$/\1/' \
  'argument NODE_CI_IMAGE must pin its image by digest'
assert_rejected divergent-node-ci-vite-plus images/node/Dockerfile \
  's/^ARG VITE_PLUS_VERSION=.*/ARG VITE_PLUS_VERSION=0.0.0/' \
  'argument VITE_PLUS_VERSION must match images/versions.env'
assert_rejected divergent-node-ci-npm images/node/Dockerfile \
  's/^ARG NPM_CI_VERSION=.*/ARG NPM_CI_VERSION=0.0.0/' \
  'argument NPM_CI_VERSION must match images/versions.env'
assert_rejected missing-node-runtime-marker .github/workflows/runner-smoke.yml \
  's|ductor.invalid/runtime/node:v1|ductor.invalid/runtime/node:v2|' \
  'job node-runner must contain: image: ductor.invalid/runtime/node:v1'
assert_rejected missing-node-input .github/workflows/runner-smoke.yml \
  's/description: Select the Node CI runtime/description: Mutated node runtime/' \
  'must contain: description: Select the Node CI runtime'
assert_rejected divergent-dockerfile-tool images/go-release/Dockerfile \
  's/^ARG NPM_VERSION=.*/ARG NPM_VERSION=0.0.0/' \
  'argument NPM_VERSION must match images/versions.env'
for runtime in go go-node; do
  assert_rejected "unbounded-govulncheck-${runtime}" "images/${runtime}/Dockerfile" \
    '/^ENV GOMAXPROCS=2 GOFLAGS=-p=2$/d' \
    'must bound the govulncheck build stage'
  assert_rejected "divergent-govulncheck-cpus-${runtime}" "images/${runtime}/Dockerfile" \
    's/^ENV GOMAXPROCS=2 GOFLAGS=-p=2$/ENV GOMAXPROCS=3 GOFLAGS=-p=2/' \
    'must bound the govulncheck build stage'
  assert_rejected "divergent-govulncheck-programs-${runtime}" "images/${runtime}/Dockerfile" \
    's/^ENV GOMAXPROCS=2 GOFLAGS=-p=2$/ENV GOMAXPROCS=2 GOFLAGS=-p=3/' \
    'must bound the govulncheck build stage'
  assert_rejected "misplaced-govulncheck-budget-${runtime}" "images/${runtime}/Dockerfile" \
    '/^ENV GOMAXPROCS=2 GOFLAGS=-p=2$/d; /^FROM [$][{]GO_IMAGE[}]$/a ENV GOMAXPROCS=2 GOFLAGS=-p=2' \
    'must bound the govulncheck build stage'
done
assert_rejected divergent-hosted-npm .github/workflows/ci.yml \
  's/NPM_VERSION: .*/NPM_VERSION: 0.0.0/' \
  'job full-hosted must contain: NPM_VERSION:'
assert_rejected divergent-hosted-node .github/workflows/ci.yml \
  's/node-version: .*/node-version: "0.0.0"/' \
  'job full-hosted must contain: node-version:'
assert_rejected divergent-validator-go .github/workflows/validate.yml \
  's/go-version: .*/go-version: 0.0.0/' \
  'must contain: go-version:'

assert_rejected confined-string-selection .github/workflows/ci.yml \
  '/^      confined:$/,/^      frontend:$/s/type: boolean/type: string/' \
  'CI must expose only a default-false boolean confined selection'
assert_rejected confined-default-selection .github/workflows/ci.yml \
  '/^      confined:$/,/^      frontend:$/s/default: false/default: true/' \
  'CI must expose only a default-false boolean confined selection'
assert_rejected arbitrary-command-input .github/workflows/ci.yml \
  '/^      frontend:$/i\      command:\n        type: string\n        default: ci-fast' \
  'CI inputs must retain the finite reviewed capabilities'
assert_rejected confined-missing-selection .github/workflows/ci.yml \
  '/^  core-gates:$/,/^  omarchy-qml:$/s/inputs[.]confined && //' \
  'confined job core-gates must retain the exact private event trust guard'
assert_rejected confined-public-routing .github/workflows/ci.yml \
  '/^  core-gates:$/,/^  omarchy-qml:$/s/github[.]event[.]repository[.]private && //' \
  'confined job core-gates must retain the exact private event trust guard'
assert_rejected confined-fork-routing .github/workflows/ci.yml \
  '/^  core-gates:$/,/^  omarchy-qml:$/s/github[.]event[.]pull_request[.]head[.]repo[.]full_name == github[.]repository/true/' \
  'confined job core-gates must retain the exact private event trust guard'
assert_rejected confined-nondefault-base .github/workflows/ci.yml \
  '/^  core-gates:$/,/^  omarchy-qml:$/s/github[.]event[.]pull_request[.]base[.]ref == github[.]event[.]repository[.]default_branch/true/' \
  'confined job core-gates must retain the exact private event trust guard'
assert_rejected generic-trusted-confined-overlap .github/workflows/ci.yml \
  '/^  full-trusted:$/,/^  core-gates:$/s/!inputs[.]confined && //' \
  'generic trusted routing must exclude confined selection only'
assert_rejected hosted-pull-request-routing .github/workflows/ci.yml \
  "/^  full-hosted:\$/,/^  full-trusted:\$/s/if: .*\$/if: \${{ !inputs.confined }}/" \
  'hosted pull request routing must remain unchanged'
assert_rejected hosted-dynamic-name .github/workflows/ci.yml \
  "/^  full-hosted:\$/,/^  full-trusted:\$/s/^    name: full-hosted\$/    name: \${{ inputs.confined \&\& 'hosted-unselected' || 'full-hosted' }}/" \
  'hosted CI must retain the exact static full-hosted name'
assert_rejected confined-aggregate-name-overlap .github/workflows/ci.yml \
  "/^  confined-complete:\$/,\$s/^    name: full-confined\$/    name: full-hosted/" \
  'confined aggregate must retain the exact static full-confined name'
assert_rejected confined-runtime .github/workflows/ci.yml \
  's|ductor.invalid/runtime/zadok-ci:v1|ductor.invalid/runtime/go-node:v1|' \
  'job core-gates must contain: image: ductor.invalid/runtime/zadok-ci:v1'
assert_rejected confined-core-deadline .github/workflows/ci.yml \
  '/^  core-gates:$/,/^  omarchy-qml:$/s/timeout-minutes: 60/timeout-minutes: 59/' \
  'job core-gates must contain: timeout-minutes: 60'
assert_rejected confined-core-budget .github/workflows/ci.yml \
  's/DUCTOR_JOB_TIMEOUT_SECONDS: "3600"/DUCTOR_JOB_TIMEOUT_SECONDS: "3599"/' \
  'job core-gates must contain: DUCTOR_JOB_TIMEOUT_SECONDS: "3600"'
assert_rejected confined-qml-deadline .github/workflows/ci.yml \
  '/^  omarchy-qml:$/,/^  confined-complete:$/s/timeout-minutes: 10/timeout-minutes: 9/' \
  'job omarchy-qml must contain: timeout-minutes: 10'
assert_rejected confined-aggregate-deadline .github/workflows/ci.yml \
  "/^  confined-complete:\$/,\$s/timeout-minutes: 5/timeout-minutes: 4/" \
  'job confined-complete must contain: timeout-minutes: 5'
assert_rejected confined-extra-container-environment .github/workflows/ci.yml \
  '/DUCTOR_JOB_TIMEOUT_SECONDS: "3600"/a\        GOMAXPROCS: "3"' \
  'confined job core-gates must retain only its exact runtime and container environment'
assert_rejected confined-extra-container-options .github/workflows/ci.yml \
  '/DUCTOR_JOB_TIMEOUT_SECONDS: "3600"/a\      options: --privileged' \
  'job core-gates must not contain: options:'
assert_rejected confined-core-cpus .github/workflows/ci.yml \
  's/GOMAXPROCS: "2"/GOMAXPROCS: "3"/' \
  'confined core must preserve its exact Go budget and gate environment'
assert_rejected confined-fail-fast .github/workflows/ci.yml \
  's/fail-fast: false/fail-fast: true/' \
  'confined core matrix must retain both complete fixed gates without fail-fast'
assert_rejected confined-fast-target .github/workflows/ci.yml \
  's/target: ci-full-checks/target: ci-fast/' \
  'confined core matrix must retain both complete fixed gates without fail-fast'
assert_rejected confined-missing-runtime-check .github/workflows/ci.yml \
  's|run: scripts/ci-runtime-check.sh core|run: true|' \
  'confined core must invoke only its checked-out runtime check and fixed core gate'
assert_rejected confined-bypassed-core-script .github/workflows/ci.yml \
  's|run: bash scripts/ci-core-gate.sh .*|run: make ci-coverage|' \
  'confined core must invoke only its checked-out runtime check and fixed core gate'
assert_rejected confined-persisted-checkout-credentials .github/workflows/ci.yml \
  '/^  core-gates:$/,/^  omarchy-qml:$/s/persist-credentials: false/persist-credentials: true/' \
  'job core-gates must contain: persist-credentials: false'
assert_rejected confined-skipped-aggregate .github/workflows/ci.yml \
  "/^  confined-complete:\$/,\$s/always[(][)] && //" \
  'confined job confined-complete must retain the exact private event trust guard'
assert_rejected confined-missing-qml-prerequisite .github/workflows/ci.yml \
  's/needs: \[core-gates, omarchy-qml\]/needs: [core-gates]/' \
  'job confined-complete must contain: needs: [core-gates, omarchy-qml]'
assert_rejected confined-qml-result-bypass .github/workflows/ci.yml \
  "s/test \"\\\$QML_RESULT\" = success/test \"\\\$QML_RESULT\" = skipped/" \
  "job confined-complete must contain: test \"\$QML_RESULT\" = success"
assert_rejected confined-secret-forwarding .github/workflows/ci.yml \
  "/CI_TARGET: /a\\          CODECOV_TOKEN: \${{ secrets.codecov-token }}" \
  'job core-gates must not contain: secrets.'
assert_rejected confined-extra-job .github/workflows/ci.yml \
  '/^jobs:$/a\  extra:\n    runs-on: ubuntu-latest\n    steps:\n      - run: true' \
  'CI must retain exactly the generic and four confined executions'
assert_rejected confined-concurrency-removal .github/workflows/ci.yml \
  's/^  group: ci-/  group: other-/' \
  'must contain: group: ci-'

assert_rejected release-ci-wait-budget .github/workflows/release.yml \
  's/SECONDS \+ 9000/SECONDS + 8999/' \
  'job release-gate must contain: deadline=$((SECONDS + 9000))'
assert_rejected release-ci-wait-job-deadline .github/workflows/release.yml \
  '/^  release-gate:$/,/^  release-please:$/s/timeout-minutes: 155/timeout-minutes: 154/' \
  'job release-gate must contain: timeout-minutes: 155'
assert_rejected release-ci-wait-runtime-deadline .github/workflows/release.yml \
  's/DUCTOR_JOB_TIMEOUT_SECONDS: "9300"/DUCTOR_JOB_TIMEOUT_SECONDS: "9299"/' \
  'job release-gate must contain: DUCTOR_JOB_TIMEOUT_SECONDS: "9300"'
assert_rejected release-ci-wait-timeout-message .github/workflows/release.yml \
  's/within 150 minutes[.]/within 30 minutes./' \
  'job release-gate must contain: was found within 150 minutes.'
