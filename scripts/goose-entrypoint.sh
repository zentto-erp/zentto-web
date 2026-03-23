#!/usr/bin/env bash
set -euo pipefail

echo "╔══════════════════════════════════════════╗"
echo "║  Zentto API — Starting                    ║"
echo "╚══════════════════════════════════════════╝"

# Las migraciones se ejecutan en CI/CD (goose-deploy-all.sh) como superuser.
# El container solo arranca la API — no ejecuta migraciones.
echo "→ Migraciones ejecutadas por CI/CD (goose-deploy-all.sh)"
echo "→ Iniciando API..."

exec node dist/index.js
