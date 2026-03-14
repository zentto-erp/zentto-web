# Estado de migracion canonica API + BD

Fecha de actualizacion: 2026-03-14

## Cambios aplicados

- `documentos-venta` opera solo en `dbo.DocumentosVenta`, `dbo.DocumentosVentaDetalle`, `dbo.DocumentosVentaPago`.
- `documentos-compra` opera solo en `dbo.DocumentosCompra`, `dbo.DocumentosCompraDetalle`, `dbo.DocumentosCompraPago`.
- `cxc` opera en `[master].Customer`, `ar.ReceivableDocument`, `ar.ReceivableApplication`.
- `cxp` opera en `[master].Supplier`, `ap.PayableDocument`, `ap.PayableApplication`.
- `clientes` opera en `[master].Customer` (sin fallback legacy).
- `proveedores` opera en `[master].Supplier` (sin fallback legacy).
- `inventario` + cache operan en `[master].Product` (sin fallback legacy).
- `p-cobrar` opera en `ar.ReceivableDocument` + `[master].Customer`.
- `cuentas-por-pagar` opera en `ap.PayableDocument` + `[master].Supplier`.
- `cuentas` opera en `acct.Account` (sin `usp_Cuentas_*`).
- `empleados` opera en `[master].Employee` (sin `usp_Empleados_*`).
- `contabilidad` (asientos/reportes) opera directo en `acct.JournalEntry` y `acct.JournalEntryLine` (sin `usp_Contabilidad_*`).
- `cotizaciones-tx` dejo de usar `sp_emitir_cotizacion_tx`; ahora usa `documentos-venta` canonico.
- SP `dbo.usp_CxC_AplicarCobro` publicado desde `sp_cxc_aplicar_cobro_v2.sql`.
- SP `dbo.usp_CxP_AplicarPago` publicado desde `sp_cxp_aplicar_pago_v2.sql`.
- Seed `seed_account_plan.sql` publicado contra `acct.Account`.
- `drop_documentos_legacy_tables.sql` ejecutado (tablas ya ausentes en esta BD).
- `drop_legacy_master_tables.sql` ejecutado:
  - `Clientes`, `Proveedores`, `Inventario`, `Empleados`, `Asientos`, `Asientos_Detalle`,
    `Cuentas`, `TasasDiarias`, `P_Cobrar`, `P_Cobrarc`, `P_Pagar`.
- `add_audit_and_normalized_views_documentos_unificado.sql` ejecutado:
  - Auditoria agregada en `dbo.DocumentosVenta*` y `dbo.DocumentosCompra*`:
    `CreatedAt`, `UpdatedAt`, `CreatedByUserId`, `UpdatedByUserId`, `IsDeleted`, `DeletedAt`, `DeletedByUserId`, `RowVer`.
  - Vistas normalizadas publicadas en schema `doc`:
    `doc.SalesDocument`, `doc.SalesDocumentLine`, `doc.SalesDocumentPayment`,
    `doc.PurchaseDocument`, `doc.PurchaseDocumentLine`, `doc.PurchaseDocumentPayment`.
- Nomina legacy migrada a canonico en scripts `sp_nomina_*.sql`:
  - Ya no dependen de tablas legacy (`Empleados`, `Nomina`, `DtllNom`, `Vacacion`, `DtllVacacion`, `DtllLiquidacion`, `ConcNom`, `ConstanteNomina`).
  - Base de cÃ¡lculo en `hr.PayrollCalcVariable` + `hr.PayrollConstant` + `hr.PayrollConcept`.
  - Procesamiento y consultas en `hr.PayrollRun`/`hr.PayrollRunLine`, `hr.VacationProcess*`, `hr.SettlementProcess*`, `[master].Employee`.
  - PublicaciÃ³n ejecutada con `sql/sp_nomina_run_all.sql` en `DatqBoxWeb`.
  - `sql/nomina/sp_nomina_copiar_conceptos_desde_legal.sql` migrado a `hr.PayrollConcept` (sin `ConcNom`).

## Verificaciones ejecutadas

- Build TypeScript: `npm run build` OK.
- Smoke de servicios canonicos contra `DatqBoxWeb` (`DB_SERVER=DELLXEONE31545`) OK:
  - `listClientes`, `listProveedores`, `inventario-cache.search`
  - `listEmpleadosSP`, `pCobrarService.list`, `listCuentasPorPagar`
  - `listDocumentosVenta`, `listDocumentosCompra`, `cxc.listDocumentos`, `cxp.listDocumentos`
  - `crearAsiento` + `anularAsiento` en `acct.*` (post-drop legacy) OK
- Esquema SQL validado para:
  - `[master].Customer`, `[master].Supplier`, `[master].Product`
  - `[master].Employee`
  - `ar.ReceivableDocument`, `ap.PayableDocument`
  - `acct.Account`, `acct.JournalEntry`, `acct.JournalEntryLine`
  - `hr.PayrollType`, `hr.PayrollConstant`, `hr.PayrollConcept`, `hr.PayrollRun`, `hr.PayrollRunLine`,
    `hr.VacationProcess`, `hr.VacationProcessLine`, `hr.SettlementProcess`, `hr.SettlementProcessLine`, `hr.PayrollCalcVariable`
- Smoke SQL nÃ³mina OK:
  - `sp_Nomina_Constantes_List`
  - `sp_Nomina_Conceptos_List`
  - `sp_Nomina_ProcesarNomina` (sin empleados activos en esta BD: ejecuciÃ³n correcta, 0 procesados/0 errores)

## Pendiente (siguiente fase)

- Revisar y retirar SP/views legacy no usados que quedaron en BD para reducir deuda tecnica (ya no son requeridos por la API).
- Actualizar `contracts/openapi.yaml` para reflejar 100% los endpoints canonicos activos.

