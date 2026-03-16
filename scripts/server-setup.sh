#!/bin/bash
# ── Zentto Server Setup ────────────────────────────────────────────────────────
# Ejecutar como root en el servidor Hetzner CX33 (Ubuntu 22.04+)
# Servidor: zentto-server | IP: 178.104.56.185
#
# Uso:  curl -sSL https://raw.githubusercontent.com/zentto-erp/zentto-web/main/scripts/server-setup.sh | bash
# O:    bash server-setup.sh

set -e
echo "=== Zentto Server Setup ==="

# ── 1. Actualizar sistema ──────────────────────────────────────────────────────
apt-get update -y && apt-get upgrade -y

# ── 2. Instalar Docker ─────────────────────────────────────────────────────────
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker
    systemctl start docker
else
    echo "Docker ya instalado: $(docker --version)"
fi

# ── 3. Instalar Nginx + Certbot ────────────────────────────────────────────────
apt-get install -y nginx certbot python3-certbot-nginx

# ── 4. Crear directorio de la app ─────────────────────────────────────────────
mkdir -p /opt/zentto
mkdir -p /opt/zentto/logs

# ── 5. Crear volumen Docker para media ────────────────────────────────────────
docker volume create zentto_api_storage || true

# ── 6. Agregar clave SSH de GitHub Actions ─────────────────────────────────────
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Clave pública generada para GitHub Actions CI/CD
GITHUB_ACTIONS_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWlNSU2CgN7CR56ABA8FfdVL+EULga8yRkC53CfKXyE github-actions-zentto"

if ! grep -qF "$GITHUB_ACTIONS_PUBKEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "$GITHUB_ACTIONS_PUBKEY" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "✓ Clave SSH de GitHub Actions agregada"
else
    echo "✓ Clave SSH ya existe"
fi

# ── 7. Nginx config para zentto.net ───────────────────────────────────────────
cat > /etc/nginx/sites-available/zentto << 'NGINXCONF'
# zentto.net → Frontend shell
server {
    listen 80;
    server_name zentto.net www.zentto.net;
    client_max_body_size 20M;

    location / {
        proxy_pass         http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection 'upgrade';
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}

# api.zentto.net → API Node
server {
    listen 80;
    server_name api.zentto.net;
    client_max_body_size 20M;

    location / {
        proxy_pass         http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
NGINXCONF

ln -sf /etc/nginx/sites-available/zentto /etc/nginx/sites-enabled/zentto
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "✓ Nginx configurado"

# ── 8. SSL con Let's Encrypt ─────────────────────────────────────────────────
echo ""
echo "Para activar SSL ejecuta:"
echo "  certbot --nginx -d zentto.net -d www.zentto.net -d api.zentto.net --non-interactive --agree-tos -m admin@zentto.net"
echo ""

# ── 9. Firewall UFW ────────────────────────────────────────────────────────────
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw --force enable
    echo "✓ Firewall configurado (22, 80, 443)"
fi

echo ""
echo "============================================="
echo "  Zentto Server Setup COMPLETADO"
echo "  IP: 178.104.56.185"
echo "  Docker: $(docker --version)"
echo "  Nginx: $(nginx -v 2>&1)"
echo ""
echo "  Próximo paso: ejecutar el primer deploy"
echo "  cd /opt/zentto && docker compose -f docker-compose.prod.yml up -d"
echo "============================================="
