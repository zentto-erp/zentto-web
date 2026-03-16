# Zentto Modular Frontend Skeleton

Arquitectura recomendada: modular monolith con monorepo.

## Estructura
- `apps/shell`: app Next.js con autenticacion comun y host de modulos.
- `packages/shared-auth`: auth/rbac comun.
- `packages/shared-ui`: componentes y layout comun.
- `packages/shared-api`: cliente API comun.
- `packages/module-contabilidad`: modulo contabilidad.
- `packages/module-nomina`: modulo nomina.

## Comandos
Desde `web/modular-frontend`:
- `npm install --legacy-peer-deps`
- `npm run dev:shell`

## Notas
- Este skeleton no rompe `web/frontend` actual.
- La habilitacion de modulos se controla por `enabledModules` en shared-auth.
