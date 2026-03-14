# DatqBox Web

## Estructura
- `web/api`: API REST Node.js + TypeScript (Express).
- `web/modular-frontend`: Monorepo micro-frontends (Next.js + MUI).
- `web/api/plugins`: add-ons del backend (estilo SAP).
- `web/contracts`: contrato OpenAPI compartido.

## Workspace
- Desde `web/`:
- `npm run install:all`
- `npm run dev`
- `npm run dev:api`
- `npm run sync:check`
- `npm run ci:quick`

## API (Node)
1. Copia `.env.example` a `.env` y ajusta credenciales.
2. `npm install`
3. `npm run dev`

## Endpoints base
- `POST /v1/auth/login`
- `GET|POST /v1/clientes` + `GET|PUT|DELETE /v1/clientes/:codigo`
- `GET|POST /v1/proveedores` + `GET|PUT|DELETE /v1/proveedores/:codigo`
- `GET|POST /v1/inventario` + `GET|PUT|DELETE /v1/inventario/:codigo`
- `GET /v1/articulos` + `GET /v1/articulos/:codigo`

## Documentos comerciales
- Compras: `GET|POST /v1/compras`, `GET|PUT|DELETE /v1/compras/:numFact`, `GET /v1/compras/:numFact/detalle`, `POST /v1/compras/tx`
- Facturas: `GET /v1/facturas`, `GET /v1/facturas/:numFact`, `GET /v1/facturas/:numFact/detalle`, `POST /v1/facturas/tx`
- Abonos: `GET|POST /v1/abonos`, `GET|PUT|DELETE /v1/abonos/:id`, `GET /v1/abonos/:id/detalle`, `POST /v1/abonos/tx`
- Pagos: `GET|POST /v1/pagos`, `GET|PUT|DELETE /v1/pagos/:id`, `GET /v1/pagos/:id/detalle`, `POST /v1/pagos/tx`
- PagosC: `GET|POST /v1/pagosc`, `GET|PUT|DELETE /v1/pagosc/:id`, `GET /v1/pagosc/:id/detalle`, `POST /v1/pagosc/tx`
- Notas: credito/debito con endpoints `GET|POST`, `GET|PUT|DELETE`, `detalle`, `tx`
- Pedidos: `GET|POST /v1/pedidos`, `GET|PUT|DELETE /v1/pedidos/:numFact`, `GET /v1/pedidos/:numFact/detalle`, `POST /v1/pedidos/tx`
- Cotizaciones: `GET|POST /v1/cotizaciones`, `GET|PUT|DELETE /v1/cotizaciones/:numFact`, `GET /v1/cotizaciones/:numFact/detalle`, `POST /v1/cotizaciones/tx`
- Ordenes: `GET|POST /v1/ordenes`, `GET|PUT|DELETE /v1/ordenes/:numFact`, `GET /v1/ordenes/:numFact/detalle`, `POST /v1/ordenes/tx`
- Presupuestos: `GET|POST /v1/presupuestos`, `GET|PUT|DELETE /v1/presupuestos/:numFact`, `GET /v1/presupuestos/:numFact/detalle`, `POST /v1/presupuestos/tx`

## Cuentas y movimientos
- Ctas por pagar: `GET|POST /v1/cuentas-por-pagar`, `GET|PUT|DELETE /v1/cuentas-por-pagar/:id`
- Ctas por cobrar: `GET|POST /v1/p-cobrar`, `GET|PUT|DELETE /v1/p-cobrar/:id`, y cartera C en `/v1/p-cobrar/c/*`
- AbonosPagos: `GET|POST /v1/abonospagos`, `GET|PUT|DELETE /v1/abonospagos/:id`
- Retenciones: `GET|POST /v1/retenciones`, `GET|PUT|DELETE /v1/retenciones/:codigo`
- MovInvent: `GET|POST /v1/movinvent`, `GET|PUT|DELETE /v1/movinvent/:id`, `GET /v1/movinvent/mes/list`

## Meta y CRUD global
- `GET /v1/meta/schema`
- `GET /v1/meta/relations`
- `GET /v1/crud/tables`
- `GET /v1/crud/:table/describe?schema=dbo`
- `POST /v1/crud/:table/query?schema=dbo`
- `POST /v1/crud/:table`
- `POST /v1/crud/:table/key`
- `GET|PUT|DELETE /v1/crud/:table/:key?schema=dbo`

Compatibilidad modular-frontend:
- Alias disponible en `/api/v1/*` para hooks que ya apuntan a ese prefijo.

## Add-ons (backend)
Coloca add-ons en `web/api/plugins/{addonId}` con:
- `manifest.json`
- `index.mjs` exportando `register(app, ctx)`.

Ejemplo disponible en `web/api/plugins/sample-addon`.
