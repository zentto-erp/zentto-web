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
- `npm run env:sync` - copia `apps/shell/.env.local` a `apps/*/.env.local` y a la raiz local
- `npm run dev:setup` - sincroniza los `.env.local` y levanta todas las micro-apps

## Notas
- Este skeleton no rompe `web/frontend` actual.
- La habilitacion de modulos se controla por `enabledModules` en shared-auth.

## Guia Rapida Para Desarrolladores

### Instruccion unica

Desde `web/modular-frontend` ejecutar:

```bash
npm run dev:setup
```

Ese comando:

- Copia `apps/shell/.env.local` a todas las micro-apps
- Levanta shell + micro-apps en sus puertos locales

### Fuente de verdad del entorno local

- El archivo maestro es `apps/shell/.env.local`
- No editar manualmente los `.env.local` de cada app
- Si cambia el entorno, volver a ejecutar `npm run env:sync`

### Puertos locales

- Shell: `http://localhost:3000`
- Contabilidad: `http://localhost:3001/contabilidad`
- POS: `http://localhost:3002/pos`
- Nómina: `http://localhost:3003/nomina`
- Bancos: `http://localhost:3004/bancos`
- Inventario: `http://localhost:3005/inventario`
- Ventas: `http://localhost:3006/ventas`
- Compras: `http://localhost:3007/compras`
- Restaurante: `http://localhost:3008/restaurante`
- Ecommerce: `http://localhost:3009/ecommerce`
- Auditoría: `http://localhost:3010/auditoria`

### Navegacion entre apps

- Desde el shell, al abrir una app, en desarrollo se navega al puerto real de esa micro-app
- Al hacer click en el logo o la marca dentro de cualquier app, se vuelve al shell en `http://localhost:3000`

### Auth compartida en desarrollo

- El login real vive en `apps/shell`
- Cada micro-app expone su ruta local `/<modulo>/api/auth/*`
- Esa ruta proxyea la autenticacion contra el shell para compartir la sesion

### Assets compartidos

- Si un asset debe verse en varias micro-apps, debe vivir en `apps/shell/public`
- Los componentes compartidos no deben asumir rutas absolutas locales de cada app como `"/logo-blanco.svg"`
- Para assets compartidos en `shared-ui`, usar el helper compartido de assets para resolverlos contra el shell en desarrollo

### Git y secretos

- Los `.env.local` estan ignorados por git
- No subir secretos ni credenciales al repositorio
- Entregar los `.env.local` fuera de git y luego ejecutar `npm run dev:setup`
