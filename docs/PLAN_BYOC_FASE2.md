# Zentto BYOC — Plan Fase 2: Deploy en Entorno Propio del Cliente

**Versión:** 1.0
**Autor:** Claude (Zentto AI Architect)
**Fecha:** 2026-03-24
**Estado:** PLAN APROBADO — listo para implementar

---

## Visión

Cuando un cliente elige **"Deploy en mi propio entorno"** al suscribirse, en lugar de recibir un subdominio `acmecorp.zentto.net`, es guiado por un wizard interactivo que:

1. Recoge sus credenciales cloud (AWS, GCP, Azure, DigitalOcean, Hetzner, VPS propio)
2. Despliega automáticamente Zentto en su infraestructura
3. Configura su dominio propio
4. Entrega el sistema listo sin intervención manual

**Frase guía:** *"Tú eliges dónde vive tu data. Nosotros lo instalamos."*

---

## Flujo Completo (Happy Path)

```
CHECKOUT PADDLE
└─ Cliente selecciona plan "Enterprise" o "Self-Hosted"
   └─ custom_data: { deployType: "byoc", provider: "aws" }
       │
       ▼
WEBHOOK subscription.created
└─ Detecta deployType=byoc
└─ Crea tenant en BD master (igual que SaaS)
└─ Redirige al WIZARD DE ONBOARDING
       │
       ▼
WIZARD (Frontend — app.zentto.net/onboarding/:token)
  Paso 1: Elige proveedor cloud
  Paso 2: Ingresa credenciales (formulario seguro)
  Paso 3: Elige región / tamaño de servidor
  Paso 4: Confirma dominio propio (ej: erp.miempresa.com)
  Paso 5: Lanza deploy → progreso en tiempo real (SSE/WebSocket)
  Paso 6: ✅ Sistema listo — email con URL + credenciales
       │
       ▼
ZENTTO DEPLOY ENGINE (API)
└─ Recibe orden de deploy con credenciales del cliente
└─ Provisiona servidor en su cloud
└─ Instala Docker + Zentto via SSH
└─ Configura PostgreSQL, SSL, Nginx
└─ Ejecuta goose migrations + seeds
└─ Registra endpoint en sys.TenantDatabase
```

---

## Arquitectura de Componentes

### 1. Frontend — Wizard BYOC

**Ruta:** `app.zentto.net/onboarding/[token]`
**App Next.js:** `web/modular-frontend/apps/shell/src/app/(onboarding)/`

**Páginas:**
```
/onboarding/[token]              → Bienvenida + plan confirmado
/onboarding/[token]/provider     → Selector de proveedor cloud
/onboarding/[token]/credentials  → Formulario de credenciales (cifrado)
/onboarding/[token]/configure    → Región, tamaño, dominio propio
/onboarding/[token]/deploy       → Progreso en tiempo real
/onboarding/[token]/complete     → Éxito + siguiente paso
```

**UI del selector de proveedor:**
```
┌─────────────────────────────────────────────────────┐
│  ¿Dónde quieres alojar Zentto?                      │
│                                                     │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐ │
│  │ AWS  │  │ GCP  │  │Azure │  │ DO   │  │Hetzn.│ │
│  └──────┘  └──────┘  └──────┘  └──────┘  └──────┘ │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │ 🖥️  Mi propio VPS (IP + SSH)               │   │
│  └──────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

### 2. Backend — Deploy Engine API

**Módulo:** `web/api/src/modules/byoc/`

**Archivos a crear:**
```
byoc/
├── byoc.routes.ts          → REST endpoints
├── byoc.service.ts         → Orquestador principal
├── byoc.types.ts           → Tipos TypeScript
├── providers/
│   ├── aws.provider.ts     → AWS EC2 via SDK
│   ├── gcp.provider.ts     → GCP Compute Engine via SDK
│   ├── azure.provider.ts   → Azure VMs via SDK
│   ├── digitalocean.provider.ts → DO Droplets via API
│   ├── hetzner.provider.ts → Hetzner Cloud via API
│   └── ssh.provider.ts     → VPS propio via SSH directo
└── deployer/
    ├── ssh-deployer.ts     → Deploy via SSH (todos los providers usan esto)
    ├── docker-setup.sh     → Script de instalación Docker en servidor
    └── zentto-install.sh   → Script de instalación Zentto completo
```

**Endpoints:**
```
POST /v1/byoc/start           → Inicia wizard (valida token de onboarding)
POST /v1/byoc/validate-creds  → Valida credenciales antes de deploy
POST /v1/byoc/deploy          → Lanza deploy (proceso async)
GET  /v1/byoc/status/:jobId   → Estado del deploy (SSE stream)
POST /v1/byoc/domain          → Configura dominio propio post-deploy
```

---

### 3. Credenciales por Proveedor

#### AWS
```typescript
{
  provider: "aws",
  region: "us-east-1",
  instanceType: "t3.medium",    // 2vCPU 4GB
  credentials: {
    accessKeyId: "AKIA...",
    secretAccessKey: "...",
    // O: roleArn para AssumeRole (más seguro)
  }
}
```
**SDK:** `@aws-sdk/client-ec2`
**Acción:** Lanza EC2 instance, asigna Elastic IP, crea Security Group

#### GCP
```typescript
{
  provider: "gcp",
  zone: "us-central1-a",
  machineType: "e2-medium",
  credentials: {
    serviceAccountJson: "{...}"   // JSON de service account
  }
}
```
**SDK:** `@google-cloud/compute`

#### Azure
```typescript
{
  provider: "azure",
  region: "eastus",
  vmSize: "Standard_B2s",
  credentials: {
    tenantId: "...",
    clientId: "...",
    clientSecret: "...",
    subscriptionId: "..."
  }
}
```
**SDK:** `@azure/arm-compute`

#### DigitalOcean
```typescript
{
  provider: "digitalocean",
  region: "nyc3",
  size: "s-2vcpu-4gb",
  credentials: {
    apiToken: "dop_v1_..."
  }
}
```
**API:** REST `https://api.digitalocean.com/v2/droplets`

#### Hetzner
```typescript
{
  provider: "hetzner",
  location: "nbg1",
  serverType: "cx22",
  credentials: {
    apiToken: "..."
  }
}
```
**API:** REST `https://api.hetzner.cloud/v1/servers`

#### VPS Propio (SSH directo)
```typescript
{
  provider: "ssh",
  credentials: {
    host: "203.0.113.1",
    port: 22,
    username: "root",
    privateKey: "-----BEGIN RSA PRIVATE KEY-----..."
    // O: password (menos recomendado)
  }
}
```

---

### 4. SSH Deployer — Instalación en el Servidor

Una vez que hay un servidor (sea de AWS, DO, Hetzner o VPS propio), el proceso es idéntico para todos via SSH:

```bash
# zentto-install.sh — se ejecuta en el servidor del cliente
#!/bin/bash
set -e

# 1. Sistema base
apt-get update -qq
apt-get install -y -qq curl git nginx certbot python3-certbot-nginx

# 2. Docker
curl -fsSL https://get.docker.com | bash
usermod -aG docker $USER

# 3. PostgreSQL
apt-get install -y -qq postgresql-16
createuser zentto_app
createdb zentto_prod -O zentto_app
psql -c "ALTER USER zentto_app WITH PASSWORD '${PG_PASSWORD}'"

# 4. Zentto via Docker
mkdir -p /opt/zentto
cat > /opt/zentto/.env.api << EOF
DB_TYPE=postgres
PG_HOST=172.18.0.1
PG_PORT=5432
PG_USER=zentto_app
PG_PASSWORD=${PG_PASSWORD}
PG_DATABASE=zentto_prod
JWT_SECRET=${JWT_SECRET}
NOTIFY_BASE_URL=https://notify.zentto.net
NOTIFY_API_KEY=${NOTIFY_API_KEY}
EOF

docker compose -f docker-compose.prod.yml up -d

# 5. SSL con Let's Encrypt
certbot --nginx -d ${DOMAIN} --non-interactive --agree-tos -m ${EMAIL}

# 6. Goose migrations
goose -dir /app/migrations/postgres postgres "${DB_URL}" up

echo "✅ Zentto instalado en ${DOMAIN}"
```

**Implementación en Node.js** via `node-ssh` o `ssh2`:
```typescript
// ssh-deployer.ts
import { NodeSSH } from 'node-ssh';

export async function deployToServer(config: SshDeployConfig, onProgress: (msg: string) => void) {
  const ssh = new NodeSSH();
  await ssh.connect({ host, username, privateKey });

  // Stream output en tiempo real via SSE al frontend
  await ssh.execCommand('bash zentto-install.sh', {
    onStdout: (chunk) => onProgress(chunk.toString()),
    onStderr: (chunk) => onProgress(`[err] ${chunk.toString()}`),
  });
}
```

---

### 5. Progreso en Tiempo Real (SSE)

**Endpoint:** `GET /v1/byoc/status/:jobId`

```typescript
// Server-Sent Events para el wizard
res.setHeader('Content-Type', 'text/event-stream');
res.setHeader('Cache-Control', 'no-cache');

deployJob.on('progress', (msg) => {
  res.write(`data: ${JSON.stringify({ step: msg })}\n\n`);
});
deployJob.on('done', () => {
  res.write(`data: ${JSON.stringify({ done: true, url: tenantUrl })}\n\n`);
  res.end();
});
```

**Frontend (wizard paso 5):**
```typescript
const es = new EventSource(`/api/v1/byoc/status/${jobId}`);
es.onmessage = (e) => {
  const { step, done, url } = JSON.parse(e.data);
  appendToLog(step);
  if (done) router.push(`/onboarding/${token}/complete?url=${url}`);
};
```

---

### 6. Dominio Propio del Cliente

El cliente ingresa `erp.miempresa.com`. Le damos instrucciones precisas:

**Opción A — CNAME (recomendada):**
```
erp.miempresa.com  CNAME  acmecorp.zentto.net
```
→ Zentto maneja el SSL via Cloudflare

**Opción B — A record (deploy propio):**
```
erp.miempresa.com  A  203.0.113.1   ← IP del servidor del cliente
```
→ El script instala certbot en el servidor del cliente

**Verificación DNS automática:**
```typescript
// Verificar que el DNS propagó antes de continuar
await waitForDns(domain, expectedIp, { timeout: 600_000, interval: 10_000 });
```

---

### 7. Seguridad de Credenciales del Cliente

**Problema:** Las credenciales cloud del cliente son muy sensibles.

**Solución:**
1. **Cifrado en tránsito:** HTTPS siempre
2. **Cifrado en reposo:** Las credenciales se cifran con `AES-256-GCM` antes de almacenar
3. **Almacenamiento mínimo:** Solo durante el deploy (< 30 min). Se eliminan al completar.
4. **Tabla:** `sys.ByocDeployJob` — columna `CredentialsEnc` (encrypted), TTL 1 hora
5. **Mejor práctica por proveedor:**
   - AWS: IAM Role temporal con permisos mínimos (EC2:RunInstances, EC2:DescribeInstances)
   - GCP: Service Account con roles `Compute Instance Admin (v1)`
   - DO/Hetzner: Token de solo escritura en droplets/servers

**Schema SQL:**
```sql
CREATE TABLE sys."ByocDeployJob" (
  "JobId"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"      BIGINT NOT NULL,
  "Provider"       VARCHAR(30) NOT NULL,   -- aws, gcp, azure, do, hetzner, ssh
  "Status"         VARCHAR(20) DEFAULT 'PENDING',  -- PENDING, RUNNING, DONE, FAILED
  "CredentialsEnc" TEXT,                   -- AES-256-GCM, TTL 1h, nullable post-deploy
  "DeployConfig"   JSONB,                  -- region, size, domain, etc.
  "ServerIp"       VARCHAR(45),
  "TenantUrl"      VARCHAR(255),
  "LogOutput"      TEXT,
  "ErrorMessage"   TEXT,
  "StartedAt"      TIMESTAMP,
  "CompletedAt"    TIMESTAMP,
  "CreatedAt"      TIMESTAMP DEFAULT NOW()
);
```

---

### 8. Integración con Zentto Notify

Al completar el deploy, se envía email automático con:
- URL del sistema (`erp.miempresa.com` o IP)
- Usuario admin + contraseña temporal
- Link a documentación de primeros pasos
- Instrucciones para cambiar la contraseña

---

## Prioridades de Implementación

| Prioridad | Componente | Estimado | Descripción |
|-----------|-----------|---------|-------------|
| P0 | SSH + VPS propio | 2 días | El más universal — cubre el 80% |
| P0 | Wizard frontend (6 pasos) | 3 días | UI del flujo completo |
| P0 | SSE progress stream | 1 día | Feedback en tiempo real |
| P1 | Hetzner provider | 1 día | API simple, REST |
| P1 | DigitalOcean provider | 1 día | API simple, REST |
| P1 | Dominio propio + DNS verify | 1 día | Verificación automática |
| P2 | AWS provider | 2 días | SDK más complejo |
| P2 | GCP provider | 2 días | SDK más complejo |
| P3 | Azure provider | 2 días | SDK más complejo |

**MVP viable en:** P0 + P1 = ~8 días de desarrollo

---

## Nuevas Variables de Entorno Requeridas

```env
# Cifrado de credenciales BYOC
BYOC_ENCRYPTION_KEY=32-bytes-hex-key   # AES-256-GCM key

# SSH key par despliegues (Zentto genera una por job)
# Se crea dinámicamente — no hace falta configurar aquí
```

---

## Goose Migration Necesaria

`web/api/migrations/postgres/00026_byoc_deploy_jobs.sql`

```sql
-- +goose Up
CREATE TABLE IF NOT EXISTS sys."ByocDeployJob" (
  -- (ver schema arriba)
);
CREATE INDEX ON sys."ByocDeployJob" ("CompanyId");
CREATE INDEX ON sys."ByocDeployJob" ("Status") WHERE "Status" IN ('PENDING','RUNNING');

-- +goose Down
DROP TABLE IF EXISTS sys."ByocDeployJob";
```

---

## Resumen para Agentes

Al implementar esta Fase 2, los agentes deben:

1. **Developer A (Backend):** Crear módulo `web/api/src/modules/byoc/` — routes, service, tipos, providers (SSH primero)
2. **Developer B (Frontend):** Crear wizard en `web/modular-frontend/apps/shell/src/app/(onboarding)/` con los 6 pasos
3. **SQL Specialist:** Migración `00026_byoc_deploy_jobs.sql` en ambos engines (PG + SQL Server)
4. **DevOps:** `zentto-install.sh` — script de instalación limpia en servidor nuevo
5. **QA:** Test E2E del flujo completo contra un VPS Hetzner de prueba

**Nota crítica:** Las credenciales cloud NUNCA se loggean, NUNCA van a Kafka/Elasticsearch, se eliminan de BD apenas completa el deploy. Solo se mantiene el `ServerIp` y `TenantUrl` resultantes.

---

## Sueño Final

```
Cliente paga → elige AWS → pega sus keys → espera 8 minutos
→ recibe email con https://erp.miempresa.com
→ inicia sesión
→ cambia contraseña
→ empieza a facturar

Sin intervención humana de Zentto.
Sin tocar servidores.
Sin configuración manual.
```

Esto es lo que hace que Zentto compita con SAP Business One, Odoo Cloud, y Dynamics 365 — pero con un click.
