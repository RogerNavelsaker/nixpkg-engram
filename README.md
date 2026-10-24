# nixpkg-engram

Nix packaging for Engram, the persistent memory system for AI coding agents.

## Outputs

- `packages.default` / `packages.engram`: the existing cross-platform Engram CLI 2.2.1.
- `packages.engram-cloud`: Engram Cloud server 3.4.0 for x86_64 and aarch64 Linux.
- `packages.engram-cloud-image`: rootless OCI image locally tagged `agent-services-engram`, published to `ghcr.io/rogernavelsaker/engram`, using an external PostgreSQL database, running as UID/GID 10001 on port 7437.

The CLI and Cloud server versions are intentionally separate: the package default remains 2.2.1, while the server image is pinned to the official 3.4.0 Linux release assets. The image does not bundle PostgreSQL or migrate data.

Runtime configuration requires `ENGRAM_DATABASE_URL`, `ENGRAM_JWT_SECRET`, and `ENGRAM_CLOUD_ALLOWED_PROJECTS`. Supply secrets at runtime; do not put them in the image or Nix derivation.

## Build and verify

```sh
nix flake check --accept-flake-config
nix build .#default .#engram-cloud .#engram-cloud-image --no-link
```

The manual-only `publish.yml` workflow publishes `latest` and a commit-SHA tag to `ghcr.io/rogernavelsaker/engram`. The split itself does not publish or overwrite images.
