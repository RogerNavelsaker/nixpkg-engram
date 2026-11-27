#!/usr/bin/env bash
# Sync flake.nix version + per-system sha256 hashMap from the latest GitHub release.
# Env: UPSTREAM (owner/repo), BIN (asset prefix), CHECKSUMS (asset name template; %v = version)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
UPSTREAM=Gentleman-Programming/engram; BIN=engram; CHECKSUMS=checksums.txt
tag=$(gh api "repos/$UPSTREAM/releases/latest" --jq .tag_name)
version=${tag#v}
current=$(grep -oE '^\s*version = "[^"]+"' flake.nix | head -n1 | sed -E 's/.*"([^"]+)"/\1/')
[ "$current" != "$version" ] || { echo "already at $version"; exit 0; }
sums=$(curl -fsSL "https://github.com/$UPSTREAM/releases/download/$tag/${CHECKSUMS//%v/$version}")
declare -A target=( [x86_64-linux]=linux_amd64 [aarch64-linux]=linux_arm64 [x86_64-darwin]=darwin_amd64 [aarch64-darwin]=darwin_arm64 )
for system in "${!target[@]}"; do
  sum=$(printf '%s\n' "$sums" | awk -v f="${BIN}_${version}_${target[$system]}.tar.gz" '$2==f {print $1}')
  [ -n "$sum" ] || { echo "no checksum for $system in $tag" >&2; exit 1; }
  sed -i -E "s|(\"$system\" = \")[0-9a-f]{64}(\";)|\1$sum\2|" flake.nix
done
sed -i -E "0,/^(\s*version = \")[^\"]+(\";)/s||\1$version\2|" flake.nix
echo "synced $UPSTREAM $version"
