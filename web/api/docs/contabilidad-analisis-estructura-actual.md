# Analisis de estructura actual para contabilidad general

Fecha de analisis: 2026-02-15
Base analizada: `sanjose` en `DELLXEONE31545` (SQL Server 2012 SP4)

## 1. Hallazgos clave

- Existe tabla `Cuentas` (catalogo contable base), pero sin motor de asientos ni mayor.
- Existe tabla `Centro_Costo`, pero no hay relacion sistematica desde transacciones auxiliares.
- No existen tablas contables nucleares:
  - `AsientoContable`
  - `AsientoContableDetalle`
  - `PeriodoContable`
  - `AjusteContable`
  - `ActivoFijoContable`
  - `DepreciacionContable`
- Las tablas operativas principales (`DocumentosVenta`, `DocumentosCompra`, `p_cobrar`, `P_Pagar`, `MovInvent`, `Abonos`, `pagos`, `Pagosc`) no traen enlace contable uniforme (`Asiento_Id`, `Cod_Cuenta`, `Centro_Costo`).

## 2. Estado actual de auxiliares contables

- `Cuentas`: disponible con `COD_CUENTA`, `DESCRIPCION`, `TIPO`, `grupo`, `LINEA`, `USO`, `Nivel`.
- `Centro_Costo`: disponible con `Codigo`, `Descripcion`.
- `Detalle_FormaPagoFacturas` tiene columna `Cuenta` pero aislada, sin trazabilidad de asiento.

## 3. Brechas para contabilidad general

- Falta trazabilidad transaccional auxiliar -> asiento.
- Falta estructura de libro diario y mayor.
- Falta estructura de ajustes y depreciacion periodica.
- Falta base para estado de resultados y balance general desde asientos aprobados.

## 4. Implementacion propuesta (backend)

Se agregaron en esta fase:

1. Script de estructura y enlaces:
- `sql/contabilidad/create_contabilidad_general.sql`

2. Script de procedimientos:
- `sql/contabilidad/sp_contabilidad_general.sql`

3. API REST contable:
- `src/modules/contabilidad/routes.ts`
- `src/modules/contabilidad/service.ts`
- registro en `src/app.ts`

## 5. Cobertura funcional de esta fase

- Creacion/listado/consulta/anulacion de asientos.
- Ajustes contables.
- Depreciacion automatica por periodo (lineal).
- Reportes:
  - libro mayor
  - mayor analitico
  - balance de comprobacion
  - estado de resultados
  - balance general
- Seed de plan de cuentas base (estructura universal adaptable a Venezuela).
- Enlaces contables agregables a tablas operativas existentes sin romper estructura actual.

## 6. Siguiente fase recomendada

- Crear SPs de contabilizacion automatica por modulo:
  - facturacion
  - compras
  - CxC/CxP
  - bancos
  - inventario
- Hacer posting automatico al aprobar cada transaccion (`Asiento_Id`) usando `ConfiguracionContableAuxiliar`.
- Cierre mensual y apertura automatica de periodos.

