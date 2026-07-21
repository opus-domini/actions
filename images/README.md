# Trusted CI runtime images

These images are the public, host-agnostic toolchains consumed by Ductor. They
contain no runner inventory, credentials, host paths, repository source, or
workflow policy. Ductor owns the private mapping from logical runtime IDs to
immutable digests, pools, trust domains, mounts, and resource limits.

| Image | Capability |
| --- | --- |
| `ghcr.io/opus-domini/ci-go` | Go CI, golangci-lint, govulncheck |
| `ghcr.io/opus-domini/ci-go-node` | Go CI plus Node and npm |
| `ghcr.io/opus-domini/ci-go-release` | Go, Node, npm, GoReleaser, Syft, Cosign |

`versions.env` is the reviewed version and upstream-image pin ledger.
`docker-bake.hcl` is the canonical local build entry point:

```bash
set -a
. images/versions.env
set +a
docker buildx bake --file images/docker-bake.hcl --print
docker buildx bake --file images/docker-bake.hcl
```

The publisher runs only on GitHub-hosted Linux, builds `linux/amd64`, emits
provenance and an SBOM, pushes by content digest, and signs that digest with the
workflow OIDC identity. Package visibility is changed to public only after a
layer/content audit; changing a package to public is treated as irreversible.

Jobs never select mutable tags. A Ductor catalog update records the emitted
digest, verifies the keyless identity and attestations, then prewarms a drained
pool. Registry access is not part of job execution.
