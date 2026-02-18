# 04 - Modular Frontend (Monorepo)

## Ubicación

- Raíz: `web/modular-frontend`
- App host: `apps/shell`
- Paquetes: `packages/*`

## Objetivo

Permitir evolución por módulos de negocio sin acoplar toda la app en un único frontend monolítico.

## Paquetes detectados

- `shared-auth`
- `shared-ui`
- `shared-api`
- `module-admin`
- `module-bancos`
- `module-contabilidad`
- `module-nomina`

## Scripts

Desde `web/modular-frontend`:

- `npm run dev:shell`
- `npm run build:shell`
- `npm run start:shell`

## Estrategia de convivencia

- El `web/frontend` sigue siendo la referencia operativa principal.
- `modular-frontend` se usa para migrar capacidades por dominio sin interrupción.
- Compartir auth, UI y cliente API evita duplicación de lógica transversal.
