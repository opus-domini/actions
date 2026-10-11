# Opus Domini Actions

Public reusable workflows for Opus Domini repositories.

## CI contract

| Caller event | Accepted target | Execution | CI target |
| --- | --- | --- | --- |
| Pull request | Branch accepted by the caller | Hosted for public, fork, or explicitly hosted workloads; trusted otherwise | `make ci-fast` |
| Push | Default branch | Trusted `go` or `go-node` runtime | `make ci-full` |
| Schedule | Default branch | Trusted `go` or `go-node` runtime | `make ci-full` |
| Manual dispatch | Default branch | Trusted `go` or `go-node` runtime | `make ci-full` |

Push, schedule, and manual dispatch are accepted only on the default branch.
The default CI selection runs `make ci-fast` for pull requests.
GitHub-hosted pull requests remain self-contained: they install the publisher's
reviewed Go, Node, npm, golangci-lint and govulncheck versions on an isolated
hosted runner. Each trusted job declares a logical
`ductor.invalid/runtime/<id>:v1` job container and an exact timeout in seconds.
The runner hook resolves that marker to a compiled local image ID and creates
the sandbox before any step. Steps then execute `make` directly;
`services: true` selects the `go-node-services` runtime,
`frontend: true` selects `go-node`, otherwise CI selects `go`.
Callers choose behavior and capability, never tool versions or image identities.

`confined: true` selects the complete confined gates for a private caller:
`ci-coverage` and `ci-full-checks` run as two fixed core lanes, alongside the
QML check and an aggregate `full-hosted` check. All four jobs use the reviewed
`zadok-ci` runtime; the core, QML and aggregate deadlines are respectively
60, 10 and 5 minutes. The caller owns the runtime-check and core-gate scripts
in its checkout. The core script preserves its gate exit and emits its coverage
evidence before cleanup; no coverage upload action or secret is passed to
these four jobs.

Confined jobs accept the same repository's private pull requests targeting the
default branch, or default-branch push, schedule and manual dispatch events.
Public, fork and explicitly hosted pull requests retain the hosted fast-CI
route and never select these confined jobs. The generic trusted job is skipped
when confined gates are selected. The reusable workflow owns CI concurrency;
callers must not declare the same cancel-in-progress group themselves.

## Release contract

Release PR classification runs on the dedicated release runner with a read-only
token. Creating or updating the Release Please pull request is the only job in
that workflow with write permissions.

Publication normally accepts a merged Release Please pull request targeting the
default branch from the same repository. A caller may also expose a manual
recovery input for the exact current default-branch commit. Recovery derives the
canonical release target from the first-parent commit that last changed the
current manifest version and requires it to be an ancestor of that current head.
Before any release mutation, a read-only verifier on the dedicated release pool
checks the target and waits up to 30 minutes for its exact reusable CI push run to finish
successfully. A stale recovery request or a missing, failed, cancelled,
mismatched, or timed-out CI run blocks publication.

The publication job executes `goreleaser release --clean` exactly once inside
the prewarmed `go-release` job container. GitHub provides the job-scoped token,
repository/ref context and OIDC request variables directly to that sandbox; no
host-side command wrapper or environment forwarding API remains. CI is not
repeated during publication. After a successful manual recovery, a final
metadata job resolves the exact merged Release Please pull request from the
canonical release commit and replaces `autorelease: pending` with
`autorelease: tagged`; failed publication never advances that state.

All third-party actions are pinned to immutable commit SHAs.

## Trusted runtime sources

This repository owns only the host-agnostic Dockerfiles, immutable upstream
pins and local Bake definition for the reusable trusted workflows. It does not
publish runtime packages and contains no remote image-publisher workflow.
Version pins and rebuild instructions live in
[`images/README.md`](images/README.md).

On the private Ductor host, an operator builds one `linux/amd64` image directly
into a dedicated rootless release engine. Root-only Ductor capture then records
the Docker image ID, verifies the reviewed source/revision labels, and streams a
Docker archive into its content-addressed local store. Ductor loads that archive
into each drained target engine and jobs remain strictly no-pull.

Runtime images contain toolchains only. Listener inventory, cache locations,
credentials, host paths, trust policy, captured archives and selected image IDs
remain private Ductor configuration and are never published here. A missing or
divergent local image fails before the project command starts.
