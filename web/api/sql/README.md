# SQL Scripts - DatqBox API (DatqBoxWeb)

## Objetivo

Este directorio contiene scripts para operar la API sobre el modelo canonico de `DatqBoxWeb`.
La meta es eliminar dependencia de tablas legacy en documentos, CxC/CxP y plan contable.

## Scripts clave

- `create_documentos_unificado.sql`
- `migrate_to_documentos_unificado.sql`
- `drop_documentos_legacy_tables.sql`
- `sp_cxc_aplicar_cobro_v2.sql`
- `sp_cxp_aplicar_pago_v2.sql`
- `seed_account_plan.sql`
- `drop_legacy_master_tables.sql`
- `add_audit_and_normalized_views_documentos_unificado.sql`
- `sp_nomina_run_all.sql`
- `sp_nomina_sistema.sql`
- `sp_nomina_calculo.sql`
- `sp_nomina_calculo_regimen.sql`
- `sp_nomina_conceptolegal_adapter.sql`
- `sp_nomina_vacaciones_liquidacion.sql`
- `sp_nomina_consultas.sql`

## Orden recomendado de ejecucion

1. `create_documentos_unificado.sql`
2. `migrate_to_documentos_unificado.sql`
3. `sp_cxc_aplicar_cobro_v2.sql`
4. `sp_cxp_aplicar_pago_v2.sql`
5. `seed_account_plan.sql`
6. `drop_documentos_legacy_tables.sql`
7. `drop_legacy_master_tables.sql`
8. `add_audit_and_normalized_views_documentos_unificado.sql`
9. `sp_nomina_run_all.sql`

## Validaciones minimas post-ejecucion

```sql
-- SPs canonicos activos
SELECT s.name AS schemaName, o.name AS procName
FROM sys.procedures o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.name IN ('usp_CxC_AplicarCobro', 'usp_CxP_AplicarPago');

-- Plan de cuentas sembrado en modelo canonico
SELECT COUNT(1) AS accountRows
FROM acct.Account a
JOIN cfg.Company c ON c.CompanyId = a.CompanyId
WHERE c.CompanyCode = 'DEFAULT';

-- Confirmar ausencia de tablas de documentos legacy
SELECT s.name AS schemaName, t.name AS tableName
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE t.name IN (
  'Facturas','Detalle_facturas','Cotizacion','Detalle_Cotizacion','Pedidos','Detalle_Pedidos',
  'Presupuestos','Detalle_Presupuestos','Ordenes','Detalle_Ordenes','Compras','Detalle_Compras',
  'NOTACREDITO','Detalle_notacredito','NOTADEBITO','Detalle_notadebito'
);
```

## Estado API (2026-03-14)

Operando en tablas canonicas:

- `/v1/documentos-venta`
- `/v1/documentos-compra`
- `/v1/cxc`
- `/v1/cxp`
- `/v1/clientes`
- `/v1/proveedores`
- `/v1/inventario`
- `/v1/p-cobrar`
- `/v1/cuentas-por-pagar`
- `/v1/cuentas` (sobre `acct.Account`)
- `/v1/nomina` (sobre `hr.Payroll*`, `hr.VacationProcess*`, `hr.SettlementProcess*`, `[master].Employee`)

## Notas

- Evitar publicar credenciales en documentacion.
- Mantener scripts idempotentes para ambientes de desarrollo y QA.
- Para estado detallado, ver `ESTADO_MIGRACION_CANONICA_API_BD.md`.
