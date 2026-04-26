#!/usr/bin/env bash
# Bootstrap del script central de security-precheck (zentto-infra/scripts/security/).
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="${REPO_ROOT}/.zentto/security/scripts"
BRANCH="${ZENTTO_INFRA_BRANCH:-develop}"
BASE_URL="https://raw.githubusercontent.com/zentto-erp/zentto-infra/${BRANCH}/scripts/security"
mkdir -p "$SCRIPT_DIR"
for f in security-precheck.cjs security-aggregate.cjs; do
  if [ ! -f "$SCRIPT_DIR/$f" ] || [ "${ZENTTO_FORCE_UPDATE:-0}" = "1" ]; then
    echo "[bootstrap] downloading $f from zentto-infra@${BRANCH}..."
    curl -sSL "$BASE_URL/$f" -o "$SCRIPT_DIR/$f"
  fi
done
exec node "$SCRIPT_DIR/security-precheck.cjs" "$@"
