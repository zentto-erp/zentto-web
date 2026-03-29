#!/usr/bin/env bash
# install-hooks.sh — Instala git hooks para CI/CD automático con repos privados
# Uso: bash scripts/install-hooks.sh
# Requiere: gh CLI autenticado (gh auth login)

set -e

HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
REPO="zentto-erp/zentto-web"

cat > "$HOOKS_DIR/pre-push" << 'HOOK'
#!/usr/bin/env bash
# pre-push hook — hace el repo público antes de push para CI/CD gratuito
# El workflow de deploy lo vuelve privado automáticamente al terminar

REPO="zentto-erp/zentto-web"

# Obtener token del gh CLI (ya autenticado)
TOKEN=$(gh auth token 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "ℹ [pre-push] gh CLI no autenticado — skip auto-public"
  exit 0
fi

# Verificar si ya es público
IS_PRIVATE=$(curl -s -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO" | python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('private','true'))" 2>/dev/null)

if [ "$IS_PRIVATE" = "False" ] || [ "$IS_PRIVATE" = "false" ]; then
  echo "ℹ [pre-push] Repo ya es público — CI/CD correrá gratis"
  exit 0
fi

echo "→ [pre-push] Haciendo repo público para CI/CD gratuito..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
  -H "Authorization: token $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$REPO" \
  -d '{"private":false}')

if [ "$STATUS" = "200" ]; then
  echo "✓ [pre-push] Repo público — GitHub Actions usará minutos gratuitos"
  echo "  El deploy lo volverá privado al finalizar automáticamente"
else
  echo "⚠ [pre-push] No se pudo hacer público (status $STATUS) — CI/CD puede fallar si no hay minutos"
fi

exit 0
HOOK

chmod +x "$HOOKS_DIR/pre-push"
echo "✓ Hook pre-push instalado en $HOOKS_DIR/pre-push"
echo "  Ahora cada 'git push' hace el repo público automáticamente"
echo "  El deploy lo vuelve privado al terminar"
