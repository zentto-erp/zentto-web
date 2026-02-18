# 02 - API Node + Express + TypeScript

## Ubicación

- Raíz API: `web/api`
- Entry points: `src/index.ts`, `src/app.ts`
- Módulos: `src/modules/*`
- Contrato: `web/contracts/openapi.yaml` y `web/api/contracts/openapi.yaml`

## Stack

- Node.js + Express
- TypeScript
- SQL Server via `mssql`
- JWT para autenticación
- Zod para validación
- Redis opcional (`ioredis`)

## Scripts

Desde `web/api`:

- `npm run dev`
- `npm run build`
- `npm run start`

## Módulos de negocio detectados

Incluye, entre otros:

- Clientes, Proveedores, Inventario, Compras, Facturas
- Bancos, Cuentas, CxC, CxP, Pagos, Abonos
- Contabilidad, Nómina, Empleados
- Pedidos, Cotizaciones, Notas, Ordenes, Presupuestos
- CRUD/meta y módulos shared

## Integración SQL Server

Variables en `.env` (no versionar valores sensibles):

- `DB_SERVER`
- `DB_DATABASE`
- `DB_USER`
- `DB_PASSWORD`
- `DB_ENCRYPT`
- `DB_TRUST_CERT`

## Reglas recomendadas

- Siempre parametrizar queries.
- Mantener contratos API-documentados antes de cambios en frontend.
- Cualquier cambio de esquema debe dejar script SQL verificable en `DatQBox DB/` o carpeta acordada de migraciones.
