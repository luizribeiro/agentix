#!/usr/bin/env bash
set -euo pipefail

: "${GONDOLIN_GUEST_DIR:?GONDOLIN_GUEST_DIR must be set}"

run() {
  local label="$1"
  shift
  echo "[gondolin-smoke] $label"
  "$@"
}

run "exec /bin/true" \
  timeout "${GONDOLIN_SMOKE_TIMEOUT:-45}s" gondolin exec -- /bin/true

run "exec /bin/sh" \
  timeout "${GONDOLIN_SMOKE_TIMEOUT:-45}s" gondolin exec -- /bin/sh -lc 'echo sh-ok' | grep -qx 'sh-ok'

run "exec /bin/bash" \
  timeout "${GONDOLIN_SMOKE_TIMEOUT:-45}s" gondolin exec -- /bin/bash -lc 'echo bash-ok' | grep -qx 'bash-ok'

echo "[gondolin-smoke] basic exec/shell smoke passed"
