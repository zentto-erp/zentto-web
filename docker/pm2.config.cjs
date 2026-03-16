/**
 * PM2 Ecosystem — Zentto Frontend (11 micro-apps)
 * Ports: shell=3000, contabilidad=3001, nomina=3002, pos=3003
 *        bancos=3004, inventario=3005, ventas=3006, compras=3007
 *        restaurante=3008, ecommerce=3009, auditoria=3010
 */
module.exports = {
  apps: [
    { name: 'shell',         script: 'node_modules/.bin/next', args: 'start -p 3000', cwd: '/app/apps/shell',         env: { NODE_ENV: 'production' } },
    { name: 'contabilidad',  script: 'node_modules/.bin/next', args: 'start -p 3001', cwd: '/app/apps/contabilidad',  env: { NODE_ENV: 'production' } },
    { name: 'nomina',        script: 'node_modules/.bin/next', args: 'start -p 3002', cwd: '/app/apps/nomina',        env: { NODE_ENV: 'production' } },
    { name: 'pos',           script: 'node_modules/.bin/next', args: 'start -p 3003', cwd: '/app/apps/pos',           env: { NODE_ENV: 'production' } },
    { name: 'bancos',        script: 'node_modules/.bin/next', args: 'start -p 3004', cwd: '/app/apps/bancos',        env: { NODE_ENV: 'production' } },
    { name: 'inventario',    script: 'node_modules/.bin/next', args: 'start -p 3005', cwd: '/app/apps/inventario',    env: { NODE_ENV: 'production' } },
    { name: 'ventas',        script: 'node_modules/.bin/next', args: 'start -p 3006', cwd: '/app/apps/ventas',        env: { NODE_ENV: 'production' } },
    { name: 'compras',       script: 'node_modules/.bin/next', args: 'start -p 3007', cwd: '/app/apps/compras',       env: { NODE_ENV: 'production' } },
    { name: 'restaurante',   script: 'node_modules/.bin/next', args: 'start -p 3008', cwd: '/app/apps/restaurante',   env: { NODE_ENV: 'production' } },
    { name: 'ecommerce',     script: 'node_modules/.bin/next', args: 'start -p 3009', cwd: '/app/apps/ecommerce',     env: { NODE_ENV: 'production' } },
    { name: 'auditoria',     script: 'node_modules/.bin/next', args: 'start -p 3010', cwd: '/app/apps/auditoria',     env: { NODE_ENV: 'production' } },
  ],
};
