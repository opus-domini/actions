# Opus Domini Actions

Public reusable workflows for Opus Domini repositories.

## CI contract

| Caller event | Accepted target | Execution | CI target |
| --- | --- | --- | --- |
| Pull request | Branch accepted by the caller | Hosted for public, fork, or explicitly hosted workloads; trusted otherwise | `make ci-fast` |
| Push | Default branch | Trusted | `make ci-full` |
| Schedule | Default branch | Trusted | `make ci-full` |
| Manual dispatch | Default branch | Trusted | `make ci-full` |

Push, schedule, and manual dispatch are accepted only on the default branch.
Pull requests never execute `make ci-full` through the reusable CI workflow.

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

The publication job bootstraps release-only tools and invokes the GoReleaser
action exactly once. CI is not repeated during publication.

All third-party actions are pinned to immutable commit SHAs.

## Trusted runtime images

The reusable trusted workflows consume public OCI runtimes built by this
repository. The image publisher itself always runs on GitHub-hosted Linux and
publishes only `linux/amd64` images with provenance, SBOM, and a keyless
signature over the immutable digest. Version pins and rebuild instructions live
in [`images/README.md`](images/README.md).

Runtime images contain toolchains only. Listener inventory, cache locations,
credentials, host paths, trust policy, and the selected image digest remain
private Ductor configuration and are never published here.
