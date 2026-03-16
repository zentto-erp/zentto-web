# Reporte de Comparacion: Base de Datos Real vs Pipeline sqlweb

**Fecha:** 2026-03-14
**Base de datos:** DatqBoxWeb (DELLXEONE31545)
**Pipeline:** `web/api/sqlweb/run_all.sql` (scripts 00-28 + includes)

---

## Resumen Ejecutivo

| Categoria         | En la BD real | Cubiertos por pipeline | Faltantes en pipeline | Solo en pipeline |
|---|---|---|---|---|
| **Tablas**         | 104           | ~96                    | ~8                    | ~4               |
| **Vistas**         | 20            | ~13                    | ~7                    | 1                |
| **Stored Procedures** | 99         | ~93+                   | ~6                    | 60+              |
| **Funciones**      | 4             | 4                      | 0                     | 0                |
| **Triggers**       | 0 (en snapshot) | 3                   | N/A                   | 3                |

---

## 1. Tablas

### 1.1 Tablas cubiertas por el pipeline

#### Schema `sec` (8 tablas en BD)

| Tabla BD                          | Script pipeline                            | Estado     |
|---|---|---|
| sec.User                          | 01_core_foundation.sql + 22_canonical      | CUBIERTA   |
| sec.Role                          | 01_core_foundation.sql                     | CUBIERTA   |
| sec.UserRole                      | 01_core_foundation.sql                     | CUBIERTA   |
| sec.UserCompanyAccess              | includes/001_user_company_access.sql       | CUBIERTA   |
| sec.UserModuleAccess               | 21_canonical_document_tables.sql           | CUBIERTA   |
| sec.AuthIdentity                   | includes/005_auth_security_hardening.sql   | CUBIERTA   |
| sec.AuthToken                      | includes/005_auth_security_hardening.sql   | CUBIERTA   |
| sec.SupervisorBiometricCredential  | includes/sp/create_supervisor_biometric_credentials.sql | CUBIERTA |
| sec.SupervisorOverride             | includes/sp/create_supervisor_override_controls.sql    | CUBIERTA |

#### Schema `cfg` (12 tablas en BD)

| Tabla BD                | Script pipeline                              | Estado     |
|---|---|---|
| cfg.Country             | 01_core_foundation.sql                       | CUBIERTA   |
| cfg.Company             | 01_core_foundation.sql                       | CUBIERTA   |
| cfg.Branch              | 01_core_foundation.sql                       | CUBIERTA   |
| cfg.ExchangeRateDaily   | 01_core_foundation.sql                       | CUBIERTA   |
| cfg.CompanyProfile      | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| cfg.Currency            | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| cfg.DocumentSequence    | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| cfg.Holiday             | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| cfg.ReportTemplate      | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| cfg.EntityImage         | 17_media_assets.sql                          | CUBIERTA   |
| cfg.MediaAsset          | 17_media_assets.sql                          | CUBIERTA   |
| cfg.AppSetting          | includes/sp/settings_table.sql               | CUBIERTA   |

#### Schema `master` (18 tablas en BD)

| Tabla BD                       | Script pipeline                              | Estado     |
|---|---|---|
| master.Customer                | 02_master_data.sql                           | CUBIERTA   |
| master.Supplier                | 02_master_data.sql                           | CUBIERTA   |
| master.Employee                | 02_master_data.sql                           | CUBIERTA   |
| master.Product                 | 02_master_data.sql                           | CUBIERTA   |
| master.Category                | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.Brand                   | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.Warehouse               | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.ProductLine             | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.ProductClass            | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.ProductGroup            | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.ProductType             | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.UnitOfMeasure           | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.Seller                  | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.CostCenter              | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.TaxRetention            | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.InventoryMovement       | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.InventoryPeriodSummary  | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |
| master.SupplierLine            | 19_canonical_maestros_and_missing.sql         | CUBIERTA   |

#### Schema `acct` (5 tablas en BD)

| Tabla BD                   | Script pipeline            | Estado     |
|---|---|---|
| acct.Account               | 03_accounting_core.sql     | CUBIERTA   |
| acct.JournalEntry          | 03_accounting_core.sql     | CUBIERTA   |
| acct.JournalEntryLine      | 03_accounting_core.sql     | CUBIERTA   |
| acct.DocumentLink          | 03_accounting_core.sql     | CUBIERTA   |
| acct.AccountingPolicy      | 03_accounting_core.sql     | CUBIERTA   |

#### Schema `ar` (5 tablas en BD)

| Tabla BD                    | Script pipeline            | Estado     |
|---|---|---|
| ar.ReceivableDocument       | 04_operations_core.sql     | CUBIERTA   |
| ar.ReceivableApplication    | 04_operations_core.sql     | CUBIERTA   |
| ar.SalesDocument            | 04_operations_core.sql     | **VER NOTA DUPLICACION** |
| ar.SalesDocumentLine        | 04_operations_core.sql     | **VER NOTA DUPLICACION** |
| ar.SalesDocumentPayment     | 04_operations_core.sql     | **VER NOTA DUPLICACION** |

> **NOTA:** Las tablas ar.SalesDocument, ar.SalesDocumentLine y ar.SalesDocumentPayment **no se crean en el pipeline actual**. El script `04_operations_core.sql` solo crea ar.ReceivableDocument y ar.ReceivableApplication. Estas tablas en la BD real no tienen origen claro en el pipeline -- posiblemente fueron creadas manualmente o por un script anterior no incluido en run_all.sql.

#### Schema `ap` (5 tablas en BD)

| Tabla BD                     | Script pipeline            | Estado     |
|---|---|---|
| ap.PayableDocument           | 04_operations_core.sql     | CUBIERTA   |
| ap.PayableApplication        | 04_operations_core.sql     | CUBIERTA   |
| ap.PurchaseDocument          | 04_operations_core.sql     | **VER NOTA DUPLICACION** |
| ap.PurchaseDocumentLine      | 04_operations_core.sql     | **VER NOTA DUPLICACION** |
| ap.PurchaseDocumentPayment   | 04_operations_core.sql     | **VER NOTA DUPLICACION** |

> **NOTA:** Igual que ar.*, las tablas ap.PurchaseDocument/Line/Payment no se crean en el pipeline. Solo ap.PayableDocument y ap.PayableApplication estan en el script.

#### Schema `doc` (6 tablas en BD)

| Tabla BD                      | Script pipeline                                    | Estado     |
|---|---|---|
| doc.SalesDocument             | includes/sp/create_documentos_unificado.sql        | CUBIERTA   |
| doc.SalesDocumentLine         | includes/sp/create_documentos_unificado.sql        | CUBIERTA   |
| doc.SalesDocumentPayment      | includes/sp/create_documentos_unificado.sql        | CUBIERTA   |
| doc.PurchaseDocument          | includes/sp/create_documentos_unificado.sql        | CUBIERTA   |
| doc.PurchaseDocumentLine      | includes/sp/create_documentos_unificado.sql        | CUBIERTA   |
| doc.PurchaseDocumentPayment   | includes/sp/create_documentos_unificado.sql        | CUBIERTA   |

#### Schema `fiscal` (4 tablas en BD)

| Tabla BD                   | Script pipeline            | Estado     |
|---|---|---|
| fiscal.CountryConfig       | 04_operations_core.sql     | CUBIERTA   |
| fiscal.TaxRate             | 04_operations_core.sql     | CUBIERTA   |
| fiscal.InvoiceType         | 04_operations_core.sql     | CUBIERTA   |
| fiscal.Record              | 04_operations_core.sql     | CUBIERTA   |

#### Schema `pos` (5 tablas en BD)

| Tabla BD                   | Script pipeline                        | Estado     |
|---|---|---|
| pos.SaleTicket             | 04_operations_core.sql                 | CUBIERTA   |
| pos.SaleTicketLine         | 04_operations_core.sql                 | CUBIERTA   |
| pos.WaitTicket             | 04_operations_core.sql                 | CUBIERTA   |
| pos.WaitTicketLine         | 04_operations_core.sql                 | CUBIERTA   |
| pos.FiscalCorrelative      | 07_pos_rest_extensions.sql             | CUBIERTA   |

#### Schema `rest` (12 tablas en BD)

| Tabla BD                   | Script pipeline                                    | Estado     |
|---|---|---|
| rest.OrderTicket           | 04_operations_core.sql                             | CUBIERTA   |
| rest.OrderTicketLine       | 04_operations_core.sql                             | CUBIERTA   |
| rest.DiningTable           | 07_pos_rest_extensions.sql                         | CUBIERTA   |
| rest.MenuEnvironment       | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.MenuCategory          | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.MenuProduct           | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.MenuComponent         | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.MenuOption            | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.MenuRecipe            | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.Purchase              | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| rest.PurchaseLine          | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |

#### Schema `fin` (6 tablas en BD)

| Tabla BD                       | Script pipeline                        | Estado     |
|---|---|---|
| fin.Bank                       | 08_fin_hr_rest_admin_extensions.sql    | CUBIERTA   |
| fin.BankAccount                | 08_fin_hr_rest_admin_extensions.sql    | CUBIERTA   |
| fin.BankReconciliation         | 08_fin_hr_rest_admin_extensions.sql    | CUBIERTA   |
| fin.BankMovement               | 08_fin_hr_rest_admin_extensions.sql    | CUBIERTA   |
| fin.BankStatementLine          | 08_fin_hr_rest_admin_extensions.sql    | CUBIERTA   |
| fin.BankReconciliationMatch    | 08_fin_hr_rest_admin_extensions.sql    | CUBIERTA   |

#### Schema `hr` (10 tablas en BD)

| Tabla BD                       | Script pipeline                                    | Estado     |
|---|---|---|
| hr.PayrollType                 | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.PayrollConcept              | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.PayrollRun                  | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.PayrollRunLine              | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.PayrollConstant             | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.VacationProcess             | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.VacationProcessLine         | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.SettlementProcess           | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.SettlementProcessLine       | 08_fin_hr_rest_admin_extensions.sql                | CUBIERTA   |
| hr.PayrollCalcVariable         | includes/sp/sp_nomina_sistema.sql                  | CUBIERTA   |

#### Schema `pay` (8 tablas en BD)

| Tabla BD                       | Script pipeline                              | Estado     |
|---|---|---|
| pay.PaymentMethods             | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.PaymentProviders           | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.ProviderCapabilities       | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.CompanyPaymentConfig       | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.AcceptedPaymentMethods     | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.Transactions               | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.ReconciliationBatches      | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |
| pay.CardReaderDevices          | includes/sp/payment_gateway_tables.sql        | CUBIERTA   |

#### Schema `dbo` (6 tablas en BD)

| Tabla BD                          | Script pipeline                              | Estado     |
|---|---|---|
| dbo.Sys_Mensajes                  | 16_sistema_tables_seed.sql                   | CUBIERTA   |
| dbo.Sys_Notificaciones            | 16_sistema_tables_seed.sql                   | CUBIERTA   |
| dbo.Sys_Tareas                    | 16_sistema_tables_seed.sql                   | CUBIERTA   |
| dbo.SchemaGovernanceDecision      | includes/sp/00_governance_baseline.sql        | CUBIERTA   |
| dbo.SchemaGovernanceSnapshot      | includes/sp/00_governance_baseline.sql        | CUBIERTA   |
| dbo.EndpointDependency            | **NO ENCONTRADA EN PIPELINE**                | FALTANTE   |

### 1.2 Tablas FALTANTES en el pipeline (existen en BD pero NO se crean)

| Tabla BD                      | Observacion                                          |
|---|---|
| dbo.EndpointDependency        | Tabla de gobernanza, referenciada en exclusiones de vistas governance pero sin CREATE TABLE en pipeline |
| ar.SalesDocument              | **Duplicado de doc.SalesDocument** - existe en BD pero no hay CREATE TABLE en pipeline |
| ar.SalesDocumentLine          | **Duplicado de doc.SalesDocumentLine** |
| ar.SalesDocumentPayment       | **Duplicado de doc.SalesDocumentPayment** |
| ap.PurchaseDocument           | **Duplicado de doc.PurchaseDocument** |
| ap.PurchaseDocumentLine       | **Duplicado de doc.PurchaseDocumentLine** |
| ap.PurchaseDocumentPayment    | **Duplicado de doc.PurchaseDocumentPayment** |

### 1.3 Tablas creadas SOLO por el pipeline (no en snapshot BD como tablas permanentes)

| Tabla pipeline                 | Script                                          | Observacion                                       |
|---|---|---|
| dbo.Cuentas                    | 05_api_compat_bridge.sql                        | Tabla legacy de contabilidad (bridge)              |
| dbo.Asientos                   | 05_api_compat_bridge.sql                        | Tabla legacy de asientos (bridge)                  |
| dbo.Asientos_Detalle           | 05_api_compat_bridge.sql                        | Tabla legacy de detalle asientos (bridge)          |
| dbo.TasasDiarias               | 05_api_compat_bridge.sql                        | Tabla legacy de tasas de cambio (bridge)           |
| dbo.FiscalCountryConfig        | 05_api_compat_bridge.sql (eliminada por 22)     | Creada y luego eliminada como duplicada de fiscal.*|
| dbo.FiscalTaxRates             | 05_api_compat_bridge.sql (eliminada por 22)     | Creada y luego eliminada                           |
| dbo.FiscalInvoiceTypes         | 05_api_compat_bridge.sql (eliminada por 22)     | Creada y luego eliminada                           |
| dbo.FiscalRecords              | 05_api_compat_bridge.sql (eliminada por 22)     | Creada y luego eliminada                           |
| dbo.AccesoUsuarios             | 13/19 (tabla), luego 21 la elimina y crea VIEW  | Migrada a sec.UserModuleAccess                     |
| dbo.Usuarios                   | 05 (tabla), luego 22 la elimina y crea VIEW     | Migrada a sec.User                                 |
| acct.BankDeposit               | includes/sp/create_documentos_unificado.sql     | Tabla nueva, puede no estar aun en snapshot        |
| master.AlternateStock          | includes/sp/create_documentos_unificado.sql     | Tabla nueva, puede no estar aun en snapshot        |

---

## 2. Vistas

### 2.1 Vistas cubiertas por el pipeline

| Vista BD                                          | Script pipeline                                | Estado     |
|---|---|---|
| dbo.Usuarios                                      | 22_canonical_usuarios_fiscal.sql               | CUBIERTA (VIEW sobre sec.User) |
| dbo.AccesoUsuarios                                | 21_canonical_document_tables.sql               | CUBIERTA (VIEW sobre sec.UserModuleAccess) |
| dbo.vw_ConceptosPorRegimen                        | includes/sp/sp_nomina_conceptolegal_adapter.sql| CUBIERTA   |
| dbo.vw_Governance_AuditCoverage                   | includes/sp/00_governance_baseline.sql         | CUBIERTA   |
| dbo.vw_Governance_DuplicateNameCandidates         | includes/sp/00_governance_baseline.sql         | CUBIERTA   |
| dbo.vw_Governance_TableSimilarityCandidates       | includes/sp/00_governance_baseline.sql         | CUBIERTA   |

### 2.2 Vistas FALTANTES en el pipeline (existen en BD pero NO se crean)

| Vista BD                                          | Observacion                                              |
|---|---|
| dbo.DocumentosVenta                               | Vista de compatibilidad legacy sobre doc.SalesDocument   |
| dbo.DocumentosVentaDetalle                        | Vista legacy sobre doc.SalesDocumentLine                 |
| dbo.DocumentosVentaPago                           | Vista legacy sobre doc.SalesDocumentPayment              |
| dbo.DocumentosCompra                              | Vista legacy sobre doc.PurchaseDocument                  |
| dbo.DocumentosCompraDetalle                       | Vista legacy sobre doc.PurchaseDocumentLine              |
| dbo.DocumentosCompraPago                          | Vista legacy sobre doc.PurchaseDocumentPayment           |
| dbo.vw_Governance_EndpointReadiness               | Vista de gobernanza (requiere dbo.EndpointDependency)    |
| dbo.vw_Governance_EndpointReadinessSummary        | Vista de gobernanza (requiere EndpointReadiness)         |
| doc.SalesDocument (VIEW)                          | Vista en schema doc -- posible alias/sinonimo            |
| doc.SalesDocumentLine (VIEW)                      | Vista en schema doc                                      |
| doc.SalesDocumentPayment (VIEW)                   | Vista en schema doc                                      |
| doc.PurchaseDocument (VIEW)                       | Vista en schema doc                                      |
| doc.PurchaseDocumentLine (VIEW)                   | Vista en schema doc                                      |
| doc.PurchaseDocumentPayment (VIEW)                | Vista en schema doc                                      |

> **NOTA IMPORTANTE:** En el snapshot, doc.SalesDocument etc. aparecen tanto como tablas (104 tablas) como vistas (20 vistas). Esto sugiere que existen las tablas doc.* **y ademas** vistas con el mismo nombre en el schema doc, lo cual es imposible en SQL Server. Lo mas probable es que estas 6 entradas de vistas doc.* sean en realidad vistas de compatibilidad creadas fuera del pipeline, o haya un error de clasificacion en el snapshot.

### 2.3 Vistas creadas SOLO por el pipeline (no en snapshot)

| Vista pipeline      | Script                             | Observacion                    |
|---|---|---|
| dbo.DtllAsiento     | 05_api_compat_bridge.sql           | Vista legacy sobre dbo.Asientos_Detalle |

---

## 3. Stored Procedures

### 3.1 SPs cubiertas por el pipeline

#### CRUD de datos maestros (pipeline crea via scripts 10 y 20)

| SP en BD                          | Script pipeline principal                  |
|---|---|
| usp_Almacen_List/GetByCodigo/Insert/Update/Delete  | sp_crud_almacen.sql / 20_rebuild_maestros_sps.sql |
| usp_Categorias_List/GetByCodigo/Insert/Update/Delete | sp_crud_categorias.sql / 20_rebuild_maestros_sps.sql |
| usp_CentroCosto_List/GetByCodigo/Insert/Update/Delete | sp_crud_centro_costo.sql / 20_rebuild_maestros_sps.sql |
| usp_Clases_List/GetByCodigo/Insert/Update/Delete   | sp_crud_clases.sql / 20_rebuild_maestros_sps.sql |
| usp_Grupos_List/GetByCodigo/Insert/Update/Delete    | sp_crud_grupos.sql / 20_rebuild_maestros_sps.sql |
| usp_Lineas_List/GetByCodigo/Insert/Update/Delete    | sp_crud_lineas.sql / 20_rebuild_maestros_sps.sql |
| usp_Marcas_List/GetByCodigo/Insert/Update/Delete    | sp_crud_marcas.sql / 20_rebuild_maestros_sps.sql |
| usp_Tipos_List/GetByCodigo/Insert/Update/Delete     | sp_crud_tipos.sql / 20_rebuild_maestros_sps.sql |
| usp_Unidades_List/GetById/Insert/Update/Delete      | sp_crud_unidades.sql / 20_rebuild_maestros_sps.sql |
| usp_Vendedores_List/GetByCodigo/Insert/Update/Delete | sp_crud_vendedores.sql / 20_rebuild_maestros_sps.sql |
| usp_Usuarios_List/GetByCodigo/Insert/Update/Delete  | sp_crud_usuarios.sql |
| usp_Empresa_Get/Update                              | sp_crud_empresa.sql / 20_rebuild_maestros_sps.sql |
| usp_CxC_AplicarCobro                                | sp_cxc_aplicar_cobro_v2.sql |
| usp_CxP_AplicarPago                                 | sp_cxp_aplicar_pago_v2.sql |
| usp_Governance_CaptureSnapshot                       | 00_governance_baseline.sql |
| sp_CxC_Documentos_List                               | 05_api_compat_bridge.sql |
| sp_CxP_Documentos_List                               | 05_api_compat_bridge.sql |

#### SPs de nomina (38 en BD, todos cubiertos)

El pipeline crea ~38 SPs de nomina via scripts 24 (sp_nomina_*.sql):

| SP en BD                      | Cubierto |
|---|---|
| sp_Nomina_ProcesarNomina      | Si |
| sp_Nomina_ProcesarEmpleado    | Si |
| sp_Nomina_CalcularConcepto    | Si |
| sp_Nomina_EvaluarFormula      | Si |
| sp_Nomina_List                | Si |
| sp_Nomina_Get                 | Si |
| sp_Nomina_Cerrar              | Si |
| sp_Nomina_Conceptos_List      | Si |
| sp_Nomina_Concepto_Save       | Si |
| sp_Nomina_Constantes_List     | Si |
| sp_Nomina_Constante_Save      | Si |
| sp_Nomina_CargarConstantes    | Si |
| sp_Nomina_PrepararVariablesBase | Si |
| sp_Nomina_SetVariable         | Si |
| sp_Nomina_LimpiarVariables    | Si |
| sp_Nomina_ReemplazarVariables | Si |
| sp_Nomina_GetScope            | Si |
| sp_Nomina_ProcesarVacaciones  | Si |
| sp_Nomina_CalcularDiasVacaciones | Si |
| sp_Nomina_Vacaciones_List     | Si |
| sp_Nomina_Vacaciones_Get      | Si |
| sp_Nomina_CalcularLiquidacion | Si |
| sp_Nomina_Liquidaciones_List  | Si |
| sp_Nomina_GetLiquidacion      | Si |
| sp_Nomina_CalcularAntiguedad  | Si |
| sp_Nomina_CalcularSalariosPromedio | Si |
| sp_Nomina_CargarConstantesRegimen | Si |
| sp_Nomina_PrepararVariablesRegimen | Si |
| sp_Nomina_ProcesarEmpleadoRegimen | Si |
| sp_Nomina_CalcularPrestacionesRegimen | Si |
| sp_Nomina_CalcularUtilidadesRegimen | Si |
| sp_Nomina_CalcularVacacionesRegimen | Si |
| sp_Nomina_ConceptosLegales_List | Si |
| sp_Nomina_ProcesarEmpleadoConceptoLegal | Si |
| sp_Nomina_CargarConstantesDesdeConceptoLegal | Si |
| sp_Nomina_ValidarFormulasConceptoLegal | Si |
| (+ otros de sistema y constantes) | Si |

#### SPs adicionales cubiertos por pipeline (no listados explicitamente en snapshot pero creados)

El pipeline crea numerosos SPs adicionales que no aparecen en el snapshot de la BD. Estos son creados por los scripts en `includes/sp/`:

- SPs de documentos: sp_emitir_factura_tx, sp_anular_factura_tx, sp_emitir_pedido_tx, sp_anular_pedido_tx, sp_emitir_compra_tx, sp_anular_compra_tx, sp_emitir_cotizacion_tx, sp_emitir_presupuesto_tx, sp_anular_presupuesto_tx, sp_emitir_documento_venta_tx, sp_emitir_documento_compra_tx, sp_anular_documento_venta_tx, sp_anular_documento_compra_tx
- SPs de documentos listado: sp_DocumentosVenta_List, sp_DocumentosVenta_Get, sp_DocumentosVenta_Tipos, sp_DocumentosCompra_List, sp_DocumentosCompra_Get
- SPs de bancos: sp_GenerarMovimientoBancario, sp_CrearConciliacion, sp_ImportarExtracto, sp_ConciliarMovimientos, sp_GenerarAjusteBancario, sp_CerrarConciliacion, sp_Conciliacion_List, sp_Conciliacion_Get
- SPs de POS/Restaurante: usp_POS_*, usp_REST_*
- SPs de contabilidad: usp_Contabilidad_*
- SPs de inventario: sp_CerrarMesInventario, sp_MovUnidades, sp_MovUnidadesMes
- SPs CRUD adicionales: usp_Bancos_*, usp_Feriados_*, usp_Moneda_*, usp_Vehiculos_*, usp_Empleados_*, usp_Clientes_*, usp_Proveedores_*, usp_Inventario_*, usp_Cuentas_*, usp_Compras_*, usp_Facturas_*, usp_Pedidos_*, usp_Cotizacion_*
- SPs de sistema: sys_notificaciones (usp_Sys_*)

### 3.2 Scripts de SPs HUERFANOS (en includes/ pero NO referenciados desde run_all.sql)

Los siguientes archivos `.sql` existen en `includes/sp/` pero **no son invocados** por ningun script numerado ni por run_all.sql:

| Archivo                      | Contenido                                          |
|---|---|
| usp_doc_sales.sql            | 6 SPs para doc.SalesDocument (List, Get, GetDetail, GetPayments, Void, InvoiceFromOrder) |
| usp_doc_purchase.sql         | SPs para doc.PurchaseDocument |
| usp_ar.sql                   | 4 SPs de Cuentas por Cobrar (AR_Application_List/Get/Apply/Reverse) |
| usp_ap.sql                   | 4 SPs de Cuentas por Pagar (AP_Application_List/Get/Apply/Reverse) |
| usp_master_balance.sql       | SPs de recalculo de balance cliente/proveedor |
| usp_pay.sql                  | 18 SPs de pasarela de pagos |
| usp_sec.sql                  | SPs de seguridad |
| usp_cfg.sql                  | SPs de configuracion |
| usp_acct.sql                 | 5 SPs de contabilidad (canonicos) |
| usp_sys.sql                  | SPs de sistema |

> **IMPACTO:** Estos scripts fueron preparados pero nunca incorporados a la cadena de ejecucion del pipeline. Sus SPs pueden o no existir en la BD real dependiendo de si fueron ejecutados manualmente.

---

## 4. Funciones

### 4.1 Funciones cubiertas

| Funcion BD                      | Script pipeline                              | Estado     |
|---|---|---|
| dbo.fn_EvaluarExpr              | includes/sp/sp_nomina_sistema.sql            | CUBIERTA   |
| dbo.fn_Nomina_GetVariable       | includes/sp/sp_nomina_sistema.sql            | CUBIERTA   |
| dbo.fn_Nomina_ContarFeriados    | includes/sp/sp_nomina_sistema.sql            | CUBIERTA   |
| dbo.fn_Nomina_ContarDomingos    | includes/sp/sp_nomina_sistema.sql            | CUBIERTA   |

**Todas las 4 funciones de la BD estan cubiertas por el pipeline.**

---

## 5. Observaciones Notables

### 5.1 Arquitectura real de documentos (HALLAZGO CRITICO - verificado)

Tras verificar con `sys.objects`, la arquitectura real es:

```
TABLAS REALES (USER_TABLE):
  ar.SalesDocument          (49 columnas, nombres canonicos en ingles)
  ar.SalesDocumentLine
  ar.SalesDocumentPayment
  ap.PurchaseDocument       (49 columnas, nombres canonicos en ingles)
  ap.PurchaseDocumentLine
  ap.PurchaseDocumentPayment

VISTAS de compatibilidad legacy (VIEW):
  dbo.DocumentosVenta       -> SELECT ... FROM ar.SalesDocument  (alias espanol: NUM_DOC, CODIGO, FECHA, TOTAL...)
  dbo.DocumentosVentaDetalle -> SELECT ... FROM ar.SalesDocumentLine
  dbo.DocumentosVentaPago   -> SELECT ... FROM ar.SalesDocumentPayment
  dbo.DocumentosCompra      -> SELECT ... FROM ap.PurchaseDocument
  dbo.DocumentosCompraDetalle -> SELECT ... FROM ap.PurchaseDocumentLine
  dbo.DocumentosCompraPago  -> SELECT ... FROM ap.PurchaseDocumentPayment

VISTAS alias ingles (VIEW):
  doc.SalesDocument         -> SELECT ... FROM dbo.DocumentosVenta  (alias ingles: DocumentNumber, CustomerCode...)
  doc.SalesDocumentLine     -> SELECT ... FROM dbo.DocumentosVentaDetalle
  doc.SalesDocumentPayment  -> SELECT ... FROM dbo.DocumentosVentaPago
  doc.PurchaseDocument      -> SELECT ... FROM dbo.DocumentosCompra
  doc.PurchaseDocumentLine  -> SELECT ... FROM dbo.DocumentosCompraDetalle
  doc.PurchaseDocumentPayment -> SELECT ... FROM dbo.DocumentosCompraPago
```

**Cadena completa:** `doc.SalesDocument` (VIEW) -> `dbo.DocumentosVenta` (VIEW) -> `ar.SalesDocument` (TABLE)

**Estructura de la tabla real `ar.SalesDocument`:**
```
DocumentId          INT IDENTITY NOT NULL
DocumentNumber      NVARCHAR(60) NOT NULL
SerialType          NVARCHAR(60) NOT NULL
OperationType       NVARCHAR(20) NOT NULL
CustomerCode        NVARCHAR(60) NULL
CustomerName        NVARCHAR(255) NULL
FiscalId            NVARCHAR(20) NULL
DocumentDate        DATETIME NULL
DueDate             DATETIME NULL
DocumentTime        NVARCHAR(20) NULL
SubTotal            DECIMAL(18,4) NULL
TaxableAmount       DECIMAL(18,4) NULL
ExemptAmount        DECIMAL(18,4) NULL
TaxAmount           DECIMAL(18,4) NULL
TaxRate             DECIMAL(8,4) NULL
TotalAmount         DECIMAL(18,4) NULL
DiscountAmount      DECIMAL(18,4) NULL
IsVoided            BIT NULL
IsPaid              NVARCHAR(1) NULL
IsInvoiced          NVARCHAR(1) NULL
IsDelivered         NVARCHAR(1) NULL
OriginDocumentNumber NVARCHAR(60) NULL
OriginDocumentType  NVARCHAR(20) NULL
ControlNumber       NVARCHAR(60) NULL
IsLegal             BIT NULL
IsPrinted           BIT NULL
Notes               NVARCHAR(500) NULL
Concept             NVARCHAR(255) NULL
PaymentTerms        NVARCHAR(255) NULL
ShipToAddress       NVARCHAR(255) NULL
SellerCode          NVARCHAR(60) NULL
DepartmentCode      NVARCHAR(50) NULL
LocationCode        NVARCHAR(100) NULL
CurrencyCode        NVARCHAR(20) NULL
ExchangeRate        DECIMAL(18,6) NULL
UserCode            NVARCHAR(60) NULL
ReportDate          DATETIME NULL
HostName            NVARCHAR(255) NULL
VehiclePlate        NVARCHAR(20) NULL
Mileage             INT NULL
TollAmount          DECIMAL(18,4) NULL
CreatedAt           DATETIME2(0) NOT NULL
UpdatedAt           DATETIME2(0) NOT NULL
CreatedByUserId     INT NULL
UpdatedByUserId     INT NULL
IsDeleted           BIT NOT NULL
DeletedAt           DATETIME2(0) NULL
DeletedByUserId     INT NULL
RowVer              TIMESTAMP NOT NULL
```

### 5.2 Discrepancia CRITICA: Pipeline vs Realidad

| Aspecto | Pipeline (`create_documentos_unificado.sql`) | BD Real |
|---|---|---|
| `doc.SalesDocument` | Creada como **TABLE** | Es una **VIEW** |
| `ar.SalesDocument` | **No existe en pipeline** | Es la **TABLE** real |
| `dbo.DocumentosVenta` | **No existe en pipeline** | Es una **VIEW** de compatibilidad |
| Tipos de datos monetarios | FLOAT | DECIMAL(18,4) |
| PK | `DocumentNumber + SerialType + FiscalMemoryNumber + OperationType` | `DocumentId INT IDENTITY` |

**IMPACTO:** El script `create_documentos_unificado.sql` crea `doc.SalesDocument` como una tabla fisica, pero en la BD real es una VISTA sobre `dbo.DocumentosVenta` que a su vez es una VISTA sobre `ar.SalesDocument`. Los SPs que hacemos INSERT/UPDATE sobre `doc.SalesDocument` pueden fallar si se ejecutan contra la BD real (las vistas encadenadas no son siempre updatable).

**Accion necesaria:** Alinear el pipeline con la realidad:
1. Las tablas reales deben crearse en `ar.*` / `ap.*`
2. Las vistas `dbo.DocumentosVenta*` deben crearse como compatibilidad legacy
3. Las vistas `doc.*` deben crearse como alias ingles sobre `dbo.*`
4. Los SPs deben operar sobre `ar.SalesDocument` (la tabla real), no `doc.SalesDocument` (la vista)

### 5.3 Tablas en la BD no creadas por el pipeline

| Tabla | Diagnostico |
|---|---|
| dbo.EndpointDependency | Tabla de gobernanza sin CREATE TABLE en pipeline |
| ar.SalesDocument/Line/Payment | Tablas REALES de documentos de venta (no creadas por pipeline) |
| ap.PurchaseDocument/Line/Payment | Tablas REALES de documentos de compra (no creadas por pipeline) |

### 5.4 Vistas faltantes en el pipeline

**Vistas de compatibilidad legacy (existen en BD, faltan en pipeline):**
- `dbo.DocumentosVenta` (VIEW sobre ar.SalesDocument con alias espanol)
- `dbo.DocumentosVentaDetalle` (VIEW sobre ar.SalesDocumentLine)
- `dbo.DocumentosVentaPago` (VIEW sobre ar.SalesDocumentPayment)
- `dbo.DocumentosCompra` (VIEW sobre ap.PurchaseDocument)
- `dbo.DocumentosCompraDetalle` (VIEW sobre ap.PurchaseDocumentLine)
- `dbo.DocumentosCompraPago` (VIEW sobre ap.PurchaseDocumentPayment)

**Vistas alias ingles (existen en BD, faltan en pipeline):**
- `doc.SalesDocument` (VIEW sobre dbo.DocumentosVenta)
- `doc.SalesDocumentLine` (VIEW sobre dbo.DocumentosVentaDetalle)
- `doc.SalesDocumentPayment` (VIEW sobre dbo.DocumentosVentaPago)
- `doc.PurchaseDocument` (VIEW sobre dbo.DocumentosCompra)
- `doc.PurchaseDocumentLine` (VIEW sobre dbo.DocumentosCompraDetalle)
- `doc.PurchaseDocumentPayment` (VIEW sobre dbo.DocumentosCompraPago)

**Vistas de gobernanza (existen en BD, faltan en pipeline):**
- `dbo.vw_Governance_EndpointReadiness` (depende de dbo.EndpointDependency)
- `dbo.vw_Governance_EndpointReadinessSummary`

### 5.5 Objetos legacy migrados correctamente

El pipeline migra correctamente:
- **dbo.Usuarios** (tabla) -> sec.User (tabla canonica) + dbo.Usuarios (VIEW + 3 triggers INSTEAD OF)
- **dbo.AccesoUsuarios** (tabla) -> sec.UserModuleAccess (tabla canonica) + dbo.AccesoUsuarios (VIEW)
- **dbo.FiscalCountryConfig/TaxRates/InvoiceTypes/Records** -> eliminadas (reemplazadas por fiscal.*)

### 5.6 Triggers

El pipeline crea 3 triggers INSTEAD OF en dbo.Usuarios (script 22):
- dbo.trg_Usuarios_IOI (INSERT), trg_Usuarios_IOU (UPDATE), trg_Usuarios_IOD (DELETE)

El snapshot muestra 0 triggers. Posiblemente script 22 no se ejecuto en esta BD o los triggers no son de tipo tabla.

### 5.7 Scripts de SPs huerfanos (en includes/ pero NO en run_all.sql)

| Archivo | Contenido | SPs aprox |
|---|---|---|
| usp_doc_sales.sql | SPs para doc.SalesDocument (List, Get, Void, etc.) | 6 |
| usp_doc_purchase.sql | SPs para doc.PurchaseDocument | 6 |
| usp_ar.sql | SPs de Cuentas por Cobrar | 4 |
| usp_ap.sql | SPs de Cuentas por Pagar | 4 |
| usp_master_balance.sql | SPs de recalculo de balance | 2 |
| usp_pay.sql | SPs de pasarela de pagos | 18 |
| usp_sec.sql | SPs de seguridad | ~4 |
| usp_cfg.sql | SPs de configuracion | ~4 |
| usp_acct.sql | SPs de contabilidad canonicos | 5 |
| usp_sys.sql | SPs de sistema | ~4 |

---

## 6. Resumen de Acciones Recomendadas (priorizado)

| # | Accion | Prioridad | Impacto |
|---|---|---|---|
| 1 | **Alinear pipeline con BD real**: tablas en ar.*/ap.*, vistas en dbo.* y doc.* | **CRITICA** | Sin esto, el pipeline genera una BD incompatible con la real |
| 2 | **Actualizar SPs** para operar sobre ar.SalesDocument (tabla) en vez de doc.SalesDocument (vista) | **CRITICA** | Los SPs actuales hacen INSERT/UPDATE sobre vistas encadenadas |
| 3 | Incorporar scripts huerfanos (usp_doc_sales, usp_ar, usp_ap, etc.) a run_all.sql | ALTA | 40+ SPs sin ejecutar |
| 4 | Agregar dbo.EndpointDependency y vistas de gobernanza al pipeline | BAJA | Completitud |
| 5 | Usar DECIMAL(18,4) en vez de FLOAT para montos en SPs | MEDIA | Consistencia con tabla real |

---

*Reporte generado automaticamente. Verificacion contra BD real: 2026-03-14.*
