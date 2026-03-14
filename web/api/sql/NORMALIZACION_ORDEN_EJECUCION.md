# Orden de ejecucion de normalizacion (DatqBoxWeb)

## Estado objetivo

- API y BD operando sobre tablas canonicas.
- Sin dependencia de tablas legacy de documentos.
- CxC/CxP sobre `ar.Receivable*` y `ap.Payable*`.
- Plan de cuentas en `acct.Account`.
- Maestros clave (`Customer`, `Supplier`, `Product`) en schema `master`.

## Fases y scripts

| Fase | Script | Resultado esperado |
|------|--------|--------------------|
| 1 | `create_documentos_unificado.sql` | Crea `DocumentosVenta/Compra` + detalle/pagos en `dbo`. |
| 1 | `migrate_to_documentos_unificado.sql` | Migra datos desde tablas legacy a unificado. |
| 1 | `drop_documentos_legacy_tables.sql` | Elimina `Facturas/Compras/Pedidos/Cotizacion/Presupuestos/Ordenes/NOTA*` y detalles (si existen). |
| 2 | `sp_cxc_aplicar_cobro_v2.sql` | `usp_CxC_AplicarCobro` sobre `[master].Customer` + `ar.Receivable*`. |
| 2 | `sp_cxp_aplicar_pago_v2.sql` | `usp_CxP_AplicarPago` sobre `[master].Supplier` + `ap.Payable*`. |
| 3 | `seed_account_plan.sql` | Carga/actualiza plan contable en `acct.Account` por compania. |
| 4 | `drop_legacy_master_tables.sql` | Elimina tablas maestras legacy (`Clientes`, `Proveedores`, `Inventario`, `Empleados`, `Asientos`, `Cuentas`, `TasasDiarias`, `P_Cobrar*`, `P_Pagar`). |

## Validaciones rapidas

```sql
-- 1) SPs canonicos
SELECT name FROM sys.procedures
WHERE name IN ('usp_CxC_AplicarCobro','usp_CxP_AplicarPago');

-- 2) Sin tablas legacy de documentos
SELECT t.name
FROM sys.tables t
WHERE t.name IN (
  'Facturas','Detalle_facturas','Cotizacion','Detalle_Cotizacion','Pedidos','Detalle_Pedidos',
  'Presupuestos','Detalle_Presupuestos','Ordenes','Detalle_Ordenes','Compras','Detalle_Compras',
  'NOTACREDITO','Detalle_notacredito','NOTADEBITO','Detalle_notadebito'
);

-- 3) Plan contable canonico
SELECT COUNT(1) AS accountRows
FROM acct.Account;
```

## Estado API aplicado

Migrado a modelo canonico:

- `documentos-venta`, `documentos-compra`
- `cxc`, `cxp`
- `clientes`, `proveedores`, `inventario`
- `p-cobrar`, `cuentas-por-pagar`
- `cuentas` (sobre `acct.Account`)

## Siguiente fase

- Migrar o retirar endpoints secundarios que aun dependan de SP legacy antes del DROP de tablas maestras restantes.
- Completar migracion de contabilidad transaccional si se requiere retiro total de legado contable.
