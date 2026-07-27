# Trusted CI runtime images

These images are the host-agnostic source definitions consumed by Ductor. They
contain no runner inventory, credentials, host paths, repository source, or
workflow policy. Ductor owns the private mapping from logical runtime IDs to
immutable local image IDs, pools, trust domains, mounts, and resource limits.

| Image | Capability |
| --- | --- |
| `go` | Go CI, golangci-lint, govulncheck |
| `go-node` | Go CI, Node/npm and the Docker CLI client |
| `go-release` | Go, Node, npm, GoReleaser, Syft, Cosign |
| `postgis` | Pinned PostGIS integration-test service |
| `redis` | Pinned Redis integration-test service |
| `rustfs` | Pinned RustFS integration-test service |
| `ryuk` | Pinned Testcontainers resource reaper |

`versions.env` is the reviewed version and upstream-image pin ledger.
`docker-bake.hcl` is the canonical local build entry point:

```bash
set -a
. images/versions.env
set +a
REVISION="$(git rev-parse HEAD)" \
  docker buildx bake --file images/docker-bake.hcl --print
```

The public repository does not publish packages or know private host labels and
paths. On the private Ductor host, an operator builds `linux/amd64` with the
exact source revision as the local tag, then the root-only Ductor capture
command exports that image into its content-addressed artifact store. A Ductor
catalog update records the captured Docker image ID and prewarms a drained pool
with `docker image load`. No registry is part of publication, storage or job
execution.

Trusted reusable workflows declare only logical
`ductor.invalid/runtime/<id>:v1` job-container markers. Those markers are not
registry references: the private runner hook resolves them through Ductor's
closed runtime/pool/trust catalog and starts the already prewarmed image ID.
Workflow steps execute directly inside that sandbox.

The four service images are prewarmed only for the dedicated private
`go-node-services` runtime. Generic runtimes remain unable to reach a container
engine socket. The Docker CLI in `ci-go-node` is inert without that private
runtime's explicitly mounted rootless engine socket.
