#!/bin/bash
# Sincroniza .env.development a .env.local de todas las micro-apps
# Uso: npm run env:sync  (o bash scripts/sync-env.sh)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
SOURCE="$ROOT/.env.development"

if [ ! -f "$SOURCE" ]; then
  echo "ERROR: No se encontro $SOURCE"
  exit 1
fi

echo "Sincronizando .env.development → .env.local en todas las apps..."

# Root
cp "$SOURCE" "$ROOT/.env.local"
echo "  ✓ raiz (.env.local)"

# Apps
for app in "$ROOT"/apps/*/; do
  if [ -d "$app" ]; then
    cp "$SOURCE" "$app/.env.local"
    echo "  ✓ $(basename "$app")"
  fi
done

echo ""
echo "Listo. Todas las apps apuntan a la misma configuracion."
echo "Edita .env.development y vuelve a ejecutar para sincronizar."
