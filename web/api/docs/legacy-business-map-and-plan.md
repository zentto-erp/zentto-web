# DatqBox Legacy Business Logic Map and API Migration Plan

## Objetivo
Trasladar la logica de negocio critica de VB6 (facturacion, cuentas por cobrar/pagar, compras e inventario) a servicios transaccionales en la API Node/TypeScript.

## Fuentes VB6 analizadas
- `DatQBox Admin/DatQBoxAdmin.vbp` (proyecto orquestador; referencia `DatQBox PtoVenta` y `DatQBox Compras`)
- `DatQBox PtoVenta/frmControls.frm` (emision principal y descuento de inventario)
- `DatQBox PtoVenta/FrmDetalleFormaPago.frm` (formas de pago, saldo pendiente, CxC)
- `DatQBox PtoVenta/FrmFacturaPedido.frm` (pedido -> factura y anulacion de pedido)
- `DatQBox Compras/frmPorPagar.frm` (CxP/CxC, pagos/abonos, retenciones, movimiento de cuentas)
- `DatQBox Compras/frmCompras.frm` y `DatQBox Compras/frmComprasAdd.frm` (compras y MovInvent ingreso)

## Hallazgos clave (reglas de negocio reales)

### 1) Facturacion (ventas)
Fuentes:
- `DatQBox PtoVenta/frmControls.frm:3475`
- `DatQBox PtoVenta/frmControls.frm:3619`
- `DatQBox PtoVenta/frmControls.frm:7313`
- `DatQBox PtoVenta/FrmDetalleFormaPago.frm:1035`
- `DatQBox PtoVenta/FrmFacturaPedido.frm:4228`

Secuencia funcional observada:
1. Inserta cabecera en `FACTURAS`.
2. Inserta renglones en `Detalle_Facturas`.
3. Registra formas de pago en `Detalle_FormaPagoFacturas` (o tabla equivalente segun `Tb_Table`).
4. Si hay saldo pendiente, genera CxC en `P_Cobrar` o `P_CobrarC` (`tipo='FACT'`, `debe/pend/saldo`).
5. Descuenta inventario:
- `Inventario.EXISTENCIA = EXISTENCIA - cantidad`
- `Inventario_Aux.CANTIDAD = CANTIDAD - cantidad` cuando `Relacionada=1`
- `Detalle_Inventario.EXISTENCIA_ACTUAL` por lote (consumo FIFO/por almacen)
6. Registra movimiento en `MovInvent` con `TIPO='Egreso'`.
7. Recalcula saldo/aging del cliente (`Saldo_30/60/90/91`).

Nota:
- Existe logica duplicada en `frmControl.frm`, `frmControls.frm` y `frmControlsPOS.frm`.
- Tambien existe flujo inverso (anulacion/reversion) que devuelve existencia y marca `MovInvent.ANULADA`.

### 2) Formas de pago y saldo pendiente (CxC)
Fuente:
- `DatQBox PtoVenta/FrmDetalleFormaPago.frm:1287`
- `DatQBox PtoVenta/FrmDetalleFormaPago.frm:1332`
- `DatQBox PtoVenta/FrmDetalleFormaPago.frm:1428`

Reglas:
1. Borra formas de pago previas por (`NUM_FACT`, `MEMORIA`, `SERIALFISCAL`).
2. Inserta cada item de pago en `Detalle_FormaPago{Tabla}`.
3. Agrega auxiliares para cheque en `DETALLE_DEPOSITO`.
4. Actualiza `FACTURAS`/`COTIZACION`:
- `MONTO_EFECT`, `MONTO_CHEQUE`, `MONTO_TARJETA`, `ABONO`, `SALDO`, `CANCELADA`, `FECHA_REPORTE`.
5. Borra CxC previa del documento (`P_Cobrar`/`P_CobrarC`) y vuelve a generar si `SALDO PENDIENTE > 0`.
6. Recalcula saldos por cliente.

### 3) Cuentas por pagar/cobrar, abonos, pagos y retenciones
Fuente principal:
- `DatQBox Compras/frmPorPagar.frm:3169`
- `DatQBox Compras/frmPorPagar.frm:3319`
- `DatQBox Compras/frmPorPagar.frm:3347`
- `DatQBox Compras/frmPorPagar.frm:5594`
- `DatQBox Compras/frmPorPagar.frm:5613`

Secuencia funcional observada:
1. Inserta asientos de documento/movimiento en `P_Pagar` (proveedores) o `P_Cobrar`/`P_CobrarC` (clientes).
2. Inserta historico de aplicacion en `Abonos` (proveedores) o `Pagos`/`PagosC` (clientes).
3. Inserta detalle de medios de pago:
- `Abonos_Detalle` (proveedores)
- `Pagos_Detalle` (clientes)
4. Inserta `Movimiento_Cuenta` para control de bancos/retenciones/operaciones.
5. Actualiza `Compras`:
- `FECHA_PAGO`, `CANCELADA`, `NRO_COMPROBANTE`, `IVARETENIDO`, `ISRL`, `MONTOISRL`, `CODIGOISLR`, `TasaRetencion`.
6. Actualiza `PEND` en `P_PAGAR` o `P_COBRAR`.
7. Recalcula saldos 30/60/90/91 en `Proveedores`/`Clientes`.

## Modelo de dominio recomendado para API (sin UI)

### Aggregate 1: SalesDocument (Factura)
Incluye:
- header factura
- lines detalle
- payment breakdown
- cxc impact
- inventory impact
- inventory movement log

Operacion atomica:
- `emitFacturaTx(payload)` en una sola transaccion SQL

### Aggregate 2: ReceivableSettlement (CxC)
Incluye:
- aplicacion a `P_Cobrar`/`P_CobrarC`
- inserciones `Pagos`/`PagosC`
- `Pagos_Detalle`
- `Movimiento_Cuenta`
- recalculo de aging

Operacion atomica:
- `applyCobroTx(payload)`

### Aggregate 3: PayableSettlement (CxP)
Incluye:
- `P_Pagar`
- `Abonos`
- `Abonos_Detalle`
- retenciones IVA/ISLR
- `Movimiento_Cuenta`
- update compras + aging proveedor

Operacion atomica:
- `applyPagoProveedorTx(payload)`

### Aggregate 4: PurchaseDocument (Compra)
Incluye:
- cabecera + detalle compras
- incremento inventario
- `MovInvent` ingreso
- cuentas por pagar inicial

Operacion atomica:
- `emitCompraTx(payload)`

## Endpoints transaccionales a construir primero
1. `POST /v1/facturas/emitir-tx`
2. `POST /v1/cxc/aplicar-cobro-tx`
3. `POST /v1/cxp/aplicar-pago-tx`
4. `POST /v1/compras/emitir-tx`
5. `POST /v1/facturas/anular-tx` (reversion inventario + cxc)
6. `POST /v1/compras/anular-tx` (reversion inventario + cxp)

## Plan de ejecucion

### Fase 0 - Congelar reglas actuales
- Extraer y documentar reglas por tabla (hecho base en este documento).
- Definir contrato JSON por operacion transaccional (request/response).

### Fase 1 - Servicios de dominio transaccionales
- Crear modulo `src/modules/domain/` con servicios:
- `sales.service.ts`
- `cxc.service.ts`
- `cxp.service.ts`
- `purchases.service.ts`
- Cada servicio con `BEGIN TRAN/COMMIT/ROLLBACK` (via `mssql.Transaction`).

### Fase 2 - Reglas financieras y saldos
- Portar calculo de `PEND/SALDO` y aging 30/60/90/91.
- Portar retenciones IVA/ISLR y numeracion de comprobantes.
- Portar control de cancelada parcial/total.

### Fase 3 - Inventario y movimientos
- Portar egreso/ingreso `MovInvent`.
- Portar ajuste por lote (`Detalle_Inventario`).
- Portar relacion con `Inventario_Aux` cuando aplica.

### Fase 4 - Endpoints y validaciones
- Exponer endpoints tx.
- Validaciones de negocio previas (saldo, documento duplicado, stock insuficiente, tipo pago, etc.).
- Idempotencia basica por `requestId` para evitar dobles grabaciones.

### Fase 5 - Pruebas de paridad VB6 vs API
- Casos de prueba por escenario:
- Factura contado
- Factura credito con saldo pendiente
- Pago parcial CxC
- Pago proveedor con retenciones
- Compra + impacto inventario
- Anulaciones

## Riesgos y decisiones tecnicas
- Hay codigo duplicado de la misma regla en varios formularios VB6; se debe consolidar en un unico servicio backend.
- Hay SQL concatenado con variaciones por `ProviderDb`; en API usar solo SQL Server parametrizado.
- Sin FK en BD: la API debe imponer integridad logica en capa de dominio.

## Siguiente paso recomendado
Implementar primero `POST /v1/facturas/emitir-tx` (paridad con `frmControls.frm` + `FrmDetalleFormaPago.frm`) porque arrastra CxC e inventario y sirve de patron para los demas procesos.

---

## Migración CRUD a Stored Procedures (no transaccionales)

Los endpoints del contrato que hacen **list/get/create/update/delete** con "query node" (varias llamadas SQL desde Node) se migran a **SP con fallback**:

1. La API intenta ejecutar el SP (una ida a BD, más rápido y parametrizado).
2. Si el SP falla (ej. tabla con columnas distintas, caso no contemplado), se usa el flujo TS actual.
3. La respuesta incluye `executionMode: "sp"` o `"ts_fallback"` para diagnóstico.

**Implementado:**

- **Clientes**: `sp_crud_clientes.sql` (usp_Clientes_List, GetByCodigo, Insert, Update, Delete). Rutas `GET/POST/PUT/DELETE /v1/clientes` y `GET /v1/clientes/:codigo`.

**Pendiente (mismo patrón):** Proveedores, Inventario/Articulos, Facturas (solo list/get), Compras (list/get), Abonos, Pagos, Cuentas por pagar, P_Cobrar, Notas, Pedidos, Cotizaciones, Ordenes, Presupuestos, Retenciones, MovInvent.

Reglas: ver `web/api/sql/README.md`. Compatible SQL Server 2012 (XML para payloads, sin OPENJSON).
