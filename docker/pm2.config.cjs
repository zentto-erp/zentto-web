/**
 * PM2 Ecosystem — Zentto Frontend (16 micro-apps)
 * Ports: shell=3000, contabilidad=3001, nomina=3002, pos=3003
 *        bancos=3004, inventario=3005, ventas=3006, compras=3007
 *        restaurante=3008, ecommerce=3009, auditoria=3010
 *        logistica=3011, crm=3012, manufactura=3013, flota=3014
 *        shipping=3015
 *
 * Las variables NEXT_PUBLIC_* se bakean en build-time via Dockerfile ARGs.
 * Las variables sin NEXT_PUBLIC_ se pasan aqui para SSR/runtime.
 * AUTH_* se inyectan via env_file en docker-compose.prod.yml.
 */

// Runtime env vars (heredadas del contenedor via docker-compose env_file)
const runtimeEnv = {
  NODE_ENV: 'production',
  BACKEND_URL: process.env.BACKEND_URL || process.env.API_URL || 'https://api.zentto.net',
  API_URL: process.env.API_URL || process.env.BACKEND_URL || 'https://api.zentto.net',
  AUTH_SECRET: process.env.AUTH_SECRET,
  AUTH_TRUST_HOST: process.env.AUTH_TRUST_HOST || 'true',
};

// Shell-specific: hereda AUTH_SECRET, AUTH_TRUST_HOST, NEXTAUTH_URL del contenedor
const shellEnv = {
  ...runtimeEnv,
  AUTH_SECRET: process.env.AUTH_SECRET,
  AUTH_TRUST_HOST: process.env.AUTH_TRUST_HOST || 'true',
  NEXTAUTH_URL: process.env.NEXTAUTH_URL || 'https://zentto.net',
};

module.exports = {
  apps: [
    { name: 'shell',         script: 'node_modules/.bin/next', args: 'start -p 3000', cwd: '/app/apps/shell',         env: shellEnv },
    { name: 'contabilidad',  script: 'node_modules/.bin/next', args: 'start -p 3001', cwd: '/app/apps/contabilidad',  env: runtimeEnv },
    { name: 'nomina',        script: 'node_modules/.bin/next', args: 'start -p 3002', cwd: '/app/apps/nomina',        env: runtimeEnv },
    { name: 'pos',           script: 'node_modules/.bin/next', args: 'start -p 3003', cwd: '/app/apps/pos',           env: { ...runtimeEnv, NEXT_BASE_PATH: '/pos',          SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'bancos',        script: 'node_modules/.bin/next', args: 'start -p 3004', cwd: '/app/apps/bancos',        env: runtimeEnv },
    { name: 'inventario',    script: 'node_modules/.bin/next', args: 'start -p 3005', cwd: '/app/apps/inventario',    env: runtimeEnv },
    { name: 'ventas',        script: 'node_modules/.bin/next', args: 'start -p 3006', cwd: '/app/apps/ventas',        env: { ...runtimeEnv, NEXT_BASE_PATH: '/ventas',       SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'compras',       script: 'node_modules/.bin/next', args: 'start -p 3007', cwd: '/app/apps/compras',       env: runtimeEnv },
    { name: 'restaurante',   script: 'node_modules/.bin/next', args: 'start -p 3008', cwd: '/app/apps/restaurante',   env: { ...runtimeEnv, NEXT_BASE_PATH: '/restaurante',  SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'ecommerce',     script: 'node_modules/.bin/next', args: 'start -p 3009', cwd: '/app/apps/ecommerce',     env: { ...runtimeEnv, NEXT_BASE_PATH: '/ecommerce',    SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'auditoria',     script: 'node_modules/.bin/next', args: 'start -p 3010', cwd: '/app/apps/auditoria',     env: { ...runtimeEnv, NEXT_BASE_PATH: '/auditoria',    SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'logistica',     script: 'node_modules/.bin/next', args: 'start -p 3011', cwd: '/app/apps/logistica',     env: { ...runtimeEnv, NEXT_BASE_PATH: '/logistica',    SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'crm',           script: 'node_modules/.bin/next', args: 'start -p 3012', cwd: '/app/apps/crm',           env: { ...runtimeEnv, NEXT_BASE_PATH: '/crm',          SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'manufactura',   script: 'node_modules/.bin/next', args: 'start -p 3013', cwd: '/app/apps/manufactura',   env: { ...runtimeEnv, NEXT_BASE_PATH: '/manufactura',  SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'flota',         script: 'node_modules/.bin/next', args: 'start -p 3014', cwd: '/app/apps/flota',         env: { ...runtimeEnv, NEXT_BASE_PATH: '/flota',        SHELL_URL: 'http://127.0.0.1:3000' } },
    { name: 'shipping',      script: 'node_modules/.bin/next', args: 'start -p 3015', cwd: '/app/apps/shipping',      env: { ...runtimeEnv, NEXT_BASE_PATH: '/shipping',     SHELL_URL: 'http://127.0.0.1:3000' } },
  ],
};
