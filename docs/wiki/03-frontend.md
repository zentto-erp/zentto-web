# 03 - Frontend Next.js (Actual)

## Ubicación

- App: `web/frontend`
- Rutas: `src/app/(dashboard)/*`
- Componentes: `src/components/*`
- Hooks de datos: `src/hooks/*`
- Utilidades/API client: `src/lib/*`

## Stack

- Next.js (App Router)
- React + TypeScript
- MUI + MUI X
- TanStack Query
- NextAuth
- Zustand

## Scripts

Desde `web/frontend`:

- `npm run dev`
- `npm run build`
- `npm run start`

## Estructura funcional

- Dashboard modular por dominios (`clientes`, `compras`, `inventario`, `facturas`, `bancos`, etc.)
- Componentes reutilizables para tablas/formularios
- Hooks de query/mutation por entidad

## Lineamientos de implementación

- Nuevas pantallas deben reutilizar hooks y componentes existentes antes de crear nuevos.
- Mantener consistencia de rutas `/v1/*` con la API.
- Validaciones de formulario deben centralizarse con Zod/React Hook Form.
