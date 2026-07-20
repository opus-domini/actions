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

Publication accepts only a merged Release Please pull request targeting the
default branch from the same repository. Before any release mutation, a hosted,
read-only verifier checks the merge commit and waits up to 30 minutes for the
exact reusable CI push run at that commit to finish successfully. A missing,
failed, cancelled, mismatched, or timed-out run blocks publication.

The publication job bootstraps release-only tools and invokes the GoReleaser
action exactly once. CI is not repeated during publication.

All third-party actions are pinned to immutable commit SHAs.
