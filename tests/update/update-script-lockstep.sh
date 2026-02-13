#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/scripts" "$fixture/packages/gondolin" "$fixture/packages/gondolin-guest-bins"
cp "$repo_root/scripts/update-package.nu" "$fixture/scripts/update-package.nu"
cp "$repo_root/packages/gondolin/default.nix" "$fixture/packages/gondolin/default.nix"
cp "$repo_root/packages/gondolin-guest-bins/default.nix" "$fixture/packages/gondolin-guest-bins/default.nix"
cp "$repo_root/README.md" "$fixture/README.md"

pushd "$fixture" >/dev/null

nu scripts/update-package.nu --check-lockstep >/dev/null

echo "[lockstep-test] forcing mismatch"
sed -i 's/version = ".*";/version = "0.0.0";/' packages/gondolin-guest-bins/default.nix

if nu scripts/update-package.nu --check-lockstep >/dev/null 2>&1; then
  echo "[lockstep-test] expected mismatch detection to fail"
  exit 1
fi

echo "[lockstep-test] running gondolin updater to resync guest-bins"
nu scripts/update-package.nu gondolin >/tmp/update-lockstep.log
cat /tmp/update-lockstep.log

nu scripts/update-package.nu --check-lockstep >/dev/null

echo "[lockstep-test] PASS"

popd >/dev/null
