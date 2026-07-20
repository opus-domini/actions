#!/usr/bin/env bash

set -euo pipefail

workflows=(
  .github/workflows/ci.yml
  .github/workflows/vulnerability-scan.yml
  .github/workflows/release-pr.yml
  .github/workflows/release.yml
  .github/workflows/runner-smoke.yml
)

fail() {
  printf 'workflow validation failed: %s\n' "$*" >&2
  exit 1
}

job_block() {
  local workflow="$1"
  local job="$2"

  awk -v header="  ${job}:" '
    $0 == header { found = 1 }
    found && $0 != header && $0 ~ /^  [[:alnum:]_-]+:$/ { exit }
    found { print }
    END { if (!found) exit 1 }
  ' "$workflow"
}

assert_job_contains() {
  local workflow="$1"
  local job="$2"
  local expected="$3"
  local block

  block="$(job_block "$workflow" "$job")"
  grep --fixed-strings --quiet -- "$expected" <<<"$block" \
    || fail "${workflow} job ${job} must contain: ${expected}"
}

assert_job_excludes() {
  local workflow="$1"
  local job="$2"
  local forbidden="$3"
  local block

  block="$(job_block "$workflow" "$job")"
  if grep --fixed-strings --quiet -- "$forbidden" <<<"$block"; then
    fail "${workflow} job ${job} must not contain: ${forbidden}"
  fi
}

assert_workflow_contains() {
  local workflow="$1"
  local expected="$2"

  grep --fixed-strings --quiet -- "$expected" "$workflow" \
    || fail "${workflow} must contain: ${expected}"
}

if grep --fixed-strings --quiet 'github.repository_owner' "${workflows[@]}"; then
  fail 'workflows must not route by repository owner'
fi
if grep --extended-regexp --quiet \
  "github\.repository[[:space:]]*(==|!=)[[:space:]]*'[^']+'" \
  "${workflows[@]}"; then
  fail 'workflows must not route by a hard-coded repository name'
fi
if grep --extended-regexp --quiet \
  'RUNNER_NAME|hostname|[0-9]{1,3}(\.[0-9]{1,3}){3}|/(home|var|etc|opt|srv|run|tmp)/' \
  README.md "${workflows[@]}"; then
  fail 'public files must not expose host metadata'
fi
if grep --extended-regexp --quiet \
  '^[[:space:]]{6}(group|labels):' \
  "${workflows[@]}"; then
  fail 'public jobs must route only through runs-on selectors'
fi

while IFS= read -r action_ref; do
  if [[ "$action_ref" == ./* ]]; then
    continue
  fi
  if [[ ! "$action_ref" =~ ^[^@]+@[0-9a-f]{40}$ ]]; then
    fail "third-party action is not pinned to an immutable SHA: ${action_ref}"
  fi
done < <(sed -nE 's/^[[:space:]]*uses:[[:space:]]+([^[:space:]]+).*/\1/p' .github/workflows/*.yml)

ci_workflow=.github/workflows/ci.yml
assert_job_contains "$ci_workflow" full-hosted 'runs-on: ubuntu-latest'
assert_job_contains "$ci_workflow" full-hosted '- name: Fast CI'
assert_job_contains "$ci_workflow" full-hosted "if: \${{ github.event_name == 'pull_request' }}"
assert_job_contains "$ci_workflow" full-hosted 'run: make ci-fast'
assert_job_contains "$ci_workflow" full-hosted '- name: Full CI'
assert_job_contains "$ci_workflow" full-hosted "if: \${{ github.event_name != 'pull_request' }}"
assert_job_contains "$ci_workflow" full-hosted 'run: make ci-full'
assert_job_contains "$ci_workflow" full-trusted 'runs-on: ductor-ci'
assert_workflow_contains "$ci_workflow" 'description: Route every pull request to a GitHub-hosted runner'
assert_workflow_contains "$ci_workflow" "github.event_name != 'pull_request' || github.event.pull_request.base.ref == github.event.repository.default_branch"

route_ci() {
  local event_name="$1"
  local ref="$2"
  local private_repository="$3"
  local same_repository="$4"
  local hosted_pull_requests="$5"
  local default_base="$6"
  local execution=rejected
  local target=none

  if [[ "$event_name" == pull_request ]] \
    && [[ "$hosted_pull_requests" == true \
      || "$private_repository" == false \
      || "$same_repository" == false ]]; then
    execution=hosted
  elif [[ "$event_name" == push \
      || "$event_name" == pull_request \
      || "$event_name" == schedule \
      || "$event_name" == workflow_dispatch ]] \
    && [[ "$event_name" == pull_request || "$ref" == refs/heads/main ]] \
    && [[ "$event_name" != pull_request || "$default_base" == true ]] \
    && [[ "$event_name" != pull_request \
      || ( "$hosted_pull_requests" == false \
        && "$private_repository" == true \
        && "$same_repository" == true ) ]]; then
    execution=persistent-ci
  fi

  if [[ "$execution" != rejected ]]; then
    if [[ "$event_name" == pull_request ]]; then
      target=ci-fast
    else
      target=ci-full
    fi
  fi

  printf '%s:%s\n' "$execution" "$target"
}

test "$(route_ci push refs/heads/main true true true true)" = persistent-ci:ci-full
test "$(route_ci pull_request refs/pull/1/merge true true true true)" = hosted:ci-fast
test "$(route_ci pull_request refs/pull/2/merge true false true true)" = hosted:ci-fast
test "$(route_ci pull_request refs/pull/3/merge true true false true)" = persistent-ci:ci-fast
test "$(route_ci pull_request refs/pull/4/merge false true false true)" = hosted:ci-fast
test "$(route_ci pull_request refs/pull/5/merge false true false false)" = hosted:ci-fast
test "$(route_ci pull_request refs/pull/6/merge true true false false)" = rejected:none
test "$(route_ci schedule refs/heads/main true true true true)" = persistent-ci:ci-full
test "$(route_ci workflow_dispatch refs/heads/main true true true true)" = persistent-ci:ci-full
test "$(route_ci workflow_dispatch refs/heads/feature true true true true)" = rejected:none
test "$(route_ci push refs/heads/feature true true true true)" = rejected:none

vulnerability_workflow=.github/workflows/vulnerability-scan.yml
assert_workflow_contains "$vulnerability_workflow" \
  "(github.event_name == 'schedule' || github.event_name == 'workflow_dispatch') && github.ref == format('refs/heads/{0}', github.event.repository.default_branch)"

release_pr_workflow=.github/workflows/release-pr.yml
assert_job_contains "$release_pr_workflow" classify 'runs-on: ductor-ci'
assert_job_contains "$release_pr_workflow" classify 'permissions:'
assert_job_contains "$release_pr_workflow" classify 'contents: read'
assert_job_contains "$release_pr_workflow" release-please-pr 'runs-on: ductor-release'
assert_job_contains "$release_pr_workflow" release-please-pr 'contents: write'
assert_job_contains "$release_pr_workflow" release-please-pr 'skip-github-release: true'
assert_job_excludes "$release_pr_workflow" classify 'ductor-release'
assert_job_excludes "$release_pr_workflow" classify 'contents: write'

publish_workflow=.github/workflows/release.yml
assert_job_contains "$publish_workflow" release-gate 'runs-on: ubuntu-latest'
assert_job_contains "$publish_workflow" release-gate 'actions: read'
assert_job_contains "$publish_workflow" release-gate 'contents: read'
assert_job_contains "$publish_workflow" release-gate 'deadline=$((SECONDS + 1800))'
assert_job_contains "$publish_workflow" release-gate 'actions/workflows/ci.yml/runs'
assert_job_contains "$publish_workflow" release-gate 'select(.path == ".github/workflows/ci.yml")'
assert_job_contains "$publish_workflow" release-gate 'select(.event == "push")'
assert_job_contains "$publish_workflow" release-gate 'select(.head_sha == $sha)'
assert_job_contains "$publish_workflow" release-gate 'select(.head_branch == $branch)'
assert_job_contains "$publish_workflow" release-gate 'completed)'
assert_job_contains "$publish_workflow" release-gate '[[ "$conclusion" == success ]]'
assert_job_excludes "$publish_workflow" release-gate 'contents: write'
assert_job_excludes "$publish_workflow" release-gate 'make ci-'
assert_job_excludes "$publish_workflow" release-gate 'actions/setup-go@'
assert_job_excludes "$publish_workflow" release-gate 'actions/setup-node@'
assert_job_excludes "$publish_workflow" release-gate 'goreleaser/goreleaser-action@'
assert_job_excludes "$publish_workflow" release-gate 'ductor-ci bootstrap'

assert_job_contains "$publish_workflow" goreleaser 'runs-on: ductor-release'
assert_job_contains "$publish_workflow" goreleaser 'actions/setup-go@'
assert_job_contains "$publish_workflow" goreleaser 'actions/setup-node@'
assert_job_contains "$publish_workflow" goreleaser 'run: ductor-ci bootstrap release'
assert_job_contains "$publish_workflow" goreleaser 'args: release --clean'
assert_job_excludes "$publish_workflow" goreleaser 'make ci-'
assert_job_excludes "$publish_workflow" goreleaser 'sigstore/cosign-installer@'
assert_job_excludes "$publish_workflow" goreleaser 'install-only: true'

goreleaser_invocations="$(job_block "$publish_workflow" goreleaser \
  | awk 'index($0, "uses: goreleaser/goreleaser-action@") { count++ } END { print count + 0 }')"
test "$goreleaser_invocations" -eq 1 \
  || fail 'the publication job must invoke the GoReleaser action exactly once'

if grep --fixed-strings --quiet 'run: make ci-' "$publish_workflow"; then
  fail 'release publication must not repeat CI'
fi
if grep --fixed-strings --quiet 'golangci-lint-version:' "$publish_workflow" \
  || grep --fixed-strings --quiet 'govulncheck-version:' "$publish_workflow"; then
  fail 'release publication must not accept unused CI tool inputs'
fi

ci_verdict() {
  local path="$1"
  local event="$2"
  local sha="$3"
  local branch="$4"
  local status="$5"
  local conclusion="$6"

  if [[ "$path" != .github/workflows/ci.yml \
    || "$event" != push \
    || "$sha" != release-sha \
    || "$branch" != main ]]; then
    printf '%s\n' ignored
    return
  fi

  case "$status" in
    completed)
      if [[ "$conclusion" == success ]]; then
        printf '%s\n' allow
      else
        printf '%s\n' fail
      fi
      ;;
    queued|in_progress|pending|requested|waiting)
      printf '%s\n' wait
      ;;
    *)
      printf '%s\n' fail
      ;;
  esac
}

test "$(ci_verdict .github/workflows/ci.yml push release-sha main in_progress '')" = wait
test "$(ci_verdict .github/workflows/ci.yml push release-sha main completed success)" = allow
test "$(ci_verdict .github/workflows/ci.yml push release-sha main completed failure)" = fail
test "$(ci_verdict .github/workflows/ci.yml push release-sha main completed cancelled)" = fail
test "$(ci_verdict .github/workflows/other.yml push release-sha main completed success)" = ignored
test "$(ci_verdict .github/workflows/ci.yml pull_request release-sha main completed success)" = ignored
test "$(ci_verdict .github/workflows/ci.yml push other-sha main completed success)" = ignored
test "$(ci_verdict .github/workflows/ci.yml push release-sha feature completed success)" = ignored

poll_outcome() {
  local verdict="$1"
  local deadline_reached="$2"

  case "$verdict" in
    allow|fail)
      printf '%s\n' "$verdict"
      ;;
    ignored|wait)
      if [[ "$deadline_reached" == true ]]; then
        printf '%s\n' fail
      else
        printf '%s\n' wait
      fi
      ;;
    *)
      printf '%s\n' fail
      ;;
  esac
}

test "$(poll_outcome wait false)" = wait
test "$(poll_outcome allow false)" = allow
test "$(poll_outcome fail false)" = fail
test "$(poll_outcome ignored false)" = wait
test "$(poll_outcome ignored true)" = fail
test "$(poll_outcome wait true)" = fail

route_release() {
  local event_name="$1"
  local action="$2"
  local merged="$3"
  local default_base="$4"
  local same_base_repository="$5"
  local same_head_repository="$6"
  local release_branch="$7"
  local pending_label="$8"

  if [[ "$event_name" == pull_request \
    && "$action" == closed \
    && "$merged" == true \
    && "$default_base" == true \
    && "$same_base_repository" == true \
    && "$same_head_repository" == true \
    && "$release_branch" == true \
    && "$pending_label" == true ]]; then
    printf '%s\n' verify
  else
    printf '%s\n' rejected
  fi
}

test "$(route_release pull_request closed true true true true true true)" = verify
test "$(route_release pull_request closed true true true false true true)" = rejected
test "$(route_release pull_request closed false true true true true true)" = rejected
test "$(route_release pull_request closed true true true true false true)" = rejected
test "$(route_release pull_request closed true true true true true false)" = rejected

smoke_workflow=.github/workflows/runner-smoke.yml
assert_workflow_contains "$smoke_workflow" 'permissions: {}'
assert_job_contains "$smoke_workflow" ci-runner 'run: ductor-ci bootstrap full'
assert_job_contains "$smoke_workflow" ci-runner 'test "${DUCTOR_TRUST:-}" = ci'
assert_job_contains "$smoke_workflow" release-runner 'COSIGN_VERSION: v3.1.1'
assert_job_contains "$smoke_workflow" release-runner 'run: ductor-ci bootstrap release'
assert_job_contains "$smoke_workflow" release-runner 'test "${DUCTOR_TRUST:-}" = release'
assert_job_contains "$smoke_workflow" release-runner 'for executable in golangci-lint govulncheck; do'
assert_job_excludes "$smoke_workflow" release-runner 'sigstore/cosign-installer@'
assert_job_excludes "$smoke_workflow" release-runner 'golangci-lint govulncheck syft'

if grep --extended-regexp --quiet \
  'actions/checkout|contents:[[:space:]]+write|id-token:|GITHUB_TOKEN|github\.token|run:[[:space:]]+make|/(home|var|run)/|RUNNER_NAME|hostname|docker\.sock' \
  "$smoke_workflow"; then
  fail 'runner smoke must remain checkout-free, read-only, and metadata-free'
fi

grep --fixed-strings --quiet '    - ductor-ci' .github/actionlint.yaml \
  || fail 'actionlint must know the CI selector'
grep --fixed-strings --quiet '    - ductor-release' .github/actionlint.yaml \
  || fail 'actionlint must know the release selector'

printf 'workflow behavior and topology are valid\n'
