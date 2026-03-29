#!/bin/bash
# ─────────────────────────────────────────────────────────────────────
#  Setup DEV environment on the Zentto production server
#
#  Run once as root on the server:
#    bash <(curl -sSL https://raw.githubusercontent.com/zentto-erp/zentto-web/main/scripts/setup-dev-env.sh)
#
#  Creates: zentto_dev database, /opt/zentto-dev directory, env files
#  Does NOT touch production (zentto_prod, /opt/zentto)
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           Zentto DEV Environment Setup                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# ── 1. Create directories ───────────────────────────────────────────
echo "→ Creating /opt/zentto-dev..."
mkdir -p /opt/zentto-dev/{migrations/postgres,sqlweb-pg,docker,nginx,logs}

# ── 2. Create PostgreSQL dev database ────────────────────────────────
echo "→ Creating zentto_dev database..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = 'zentto_dev'" | grep -q 1 || {
    sudo -u postgres psql -c "CREATE DATABASE zentto_dev OWNER zentto_app;"
    echo "  ✓ Database zentto_dev created"
}

# Install extensions
sudo -u postgres psql -d zentto_dev -c "
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
    CREATE EXTENSION IF NOT EXISTS unaccent;
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";
    CREATE EXTENSION IF NOT EXISTS btree_gin;
"
echo "  ✓ Extensions installed"

# Grant schema access
SCHEMAS="acct ap ar audit cfg doc fin fiscal hr master pay pos public rest sec store inv logistics crm mfg fleet"
for schema in $SCHEMAS; do
    sudo -u postgres psql -d zentto_dev -c "
        CREATE SCHEMA IF NOT EXISTS $schema;
        GRANT ALL ON SCHEMA $schema TO zentto_app;
    " 2>/dev/null || true
done
echo "  ✓ Schemas created and granted"

# ── 3. Allow Docker network to access zentto_dev ────────────────────
echo "→ Configuring pg_hba.conf for zentto_dev..."
PG_HBA=$(sudo -u postgres psql -tc "SHOW hba_file" | xargs)
if ! grep -q "zentto_dev" "$PG_HBA" 2>/dev/null; then
    echo "host    zentto_dev    zentto_app    172.18.0.0/16    scram-sha-256" >> "$PG_HBA"
    sudo -u postgres pg_ctl reload -D "$(sudo -u postgres psql -tc 'SHOW data_directory' | xargs)"
    echo "  ✓ pg_hba.conf updated"
else
    echo "  ✓ pg_hba.conf already configured"
fi

# ── 4. Create env files ─────────────────────────────────────────────
echo "→ Creating .env files..."

if [ ! -f /opt/zentto-dev/.env.api ]; then
    cat > /opt/zentto-dev/.env.api <<'ENVEOF'
# Zentto DEV API Environment
DB_TYPE=postgres
PG_HOST=172.18.0.1
PG_PORT=5432
PG_DATABASE=zentto_dev
PG_USER=zentto_app
PG_PASSWORD=CHANGE_ME
PG_POOL_MIN=2
PG_POOL_MAX=10
PG_SSL=false

PORT=4000
NODE_ENV=development

CORS_ORIGINS=https://dev.zentto.net,https://app.dev.zentto.net
AUTH_PUBLIC_URL=https://dev.zentto.net
STORE_URL=https://app.dev.zentto.net

JWT_SECRET=dev-secret-change-me
JWT_EXPIRES=24h

AUTH_REQUIRE_EMAIL_VERIFICATION=false
AUTH_LOGIN_REQUIRE_CAPTCHA=false
AUTH_EXPOSE_DEBUG_LINKS=true
ENVEOF
    chmod 600 /opt/zentto-dev/.env.api
    echo "  ✓ .env.api created (⚠️ EDIT PG_PASSWORD!)"
else
    echo "  ✓ .env.api already exists"
fi

if [ ! -f /opt/zentto-dev/.env.frontend ]; then
    cat > /opt/zentto-dev/.env.frontend <<'ENVEOF'
AUTH_SECRET=dev-auth-secret-change-me
AUTH_TRUST_HOST=true
NEXTAUTH_URL=https://app.dev.zentto.net
BACKEND_URL=http://zentto-api-dev:4000
API_URL=http://zentto-api-dev:4000
ENVEOF
    chmod 600 /opt/zentto-dev/.env.frontend
    echo "  ✓ .env.frontend created"
else
    echo "  ✓ .env.frontend already exists"
fi

# ── 5. Create Docker volume ─────────────────────────────────────────
echo "→ Creating Docker volume..."
docker volume create zentto_api_storage_dev 2>/dev/null || true
echo "  ✓ Volume zentto_api_storage_dev ready"

# ── 6. UFW rules (same as production — ports 4100, 3100-3115 are internal only) ───
echo "→ Firewall: dev containers use existing Docker subnet rules"

# ── 7. Summary ──────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEV environment ready!                                     ║"
echo "║                                                             ║"
echo "║  Next steps:                                                ║"
echo "║  1. Edit /opt/zentto-dev/.env.api (set PG_PASSWORD)        ║"
echo "║  2. Add DNS records in Cloudflare:                         ║"
echo "║     A  dev.zentto.net      → $(curl -s ifconfig.me)      ║"
echo "║     A  app.dev.zentto.net  → $(curl -s ifconfig.me)      ║"
echo "║     A  api.dev.zentto.net  → $(curl -s ifconfig.me)      ║"
echo "║  3. Run certbot to expand SSL (from GitHub Actions)        ║"
echo "║  4. Push to 'developer' branch to trigger first deploy     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
