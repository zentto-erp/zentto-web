-- ============================================================
-- DatqBoxWeb PostgreSQL - run_all.sql
-- Script maestro de despliegue
-- Ejecutar: psql -U postgres -d datqboxweb -f run_all.sql
-- ============================================================

\echo ''
\echo '╔══════════════════════════════════════════════════════╗'
\echo '║  DatqBoxWeb PostgreSQL - Deployment Script          ║'
\echo '╚══════════════════════════════════════════════════════╝'
\echo ''

-- ====================================================================
-- FASE 1: Base de datos (ejecutar manualmente la primera vez)
-- psql -U postgres -f 00_create_database.sql
-- ====================================================================

-- ====================================================================
-- FASE 2: DDL - Tablas y schemas
-- ====================================================================
\echo '[01/17] Core Foundation (schemas + sec/cfg)...'
\i 01_core_foundation.sql

\echo '[02/17] Master Data (customer, supplier, employee, product)...'
\i 02_master_data.sql

\echo '[03/17] Accounting Core (account, journal entry)...'
\i 03_accounting_core.sql

\echo '[04/17] Operations Core (ar, ap, fiscal, pos, rest)...'
\i 04_operations_core.sql

\echo '[04b/17] Auth Security Hardening (sec.AuthIdentity, sec.AuthToken)...'
\i 005_auth_security_hardening.sql

\echo '[05/17] API Compat Bridge (legacy tables)...'
\i 05_api_compat_bridge.sql

\echo '[06/17] Seed Reference Data (fiscal config, tax rates)...'
\i 06_seed_reference_data.sql

\echo '[07/17] POS & Restaurant Extensions...'
\i 07_pos_rest_extensions.sql

\echo '[08/17] Finance & HR Extensions...'
\i 08_fin_hr_extensions.sql

\echo '[09/17] Canonical Maestros...'
\i 09_canonical_maestros.sql

\echo '[10/17] Canonical Documents...'
\i 10_canonical_documents.sql

\echo '[11/17] Canonical Usuarios & Fiscal...'
\i 11_canonical_usuarios_fiscal.sql

\echo '[12/17] Payment & Ecommerce tables...'
\i 12_payment_ecommerce.sql

\echo '--- Inventory Advanced (Serials, Lots, WMS) ---'
\i 09_inventory_advanced.sql

\echo '--- Logistics (Receipts, Returns, Delivery Notes) ---'
\i 10_logistics.sql

\echo '--- CRM Pipeline ---'
\i 11_crm.sql

-- ====================================================================
-- FASE 3: Triggers y Fulltext
-- ====================================================================
\echo '[13/17] Triggers (row_ver, updated_at)...'
\i 13_triggers.sql

\echo '[14/17] Fulltext Search (tsvector + GIN)...'
\i 14_fulltext_search.sql

-- ====================================================================
-- FASE 4: Seed data
-- ====================================================================
\echo '[15/17] Seed Contabilidad...'
\i 15_seed_contabilidad.sql

\echo '[16/17] Seed Nomina...'
\i 16_seed_nomina.sql

\echo '[17/17] Seed Ecommerce...'
\i 17_seed_ecommerce.sql

-- ====================================================================
-- FASE 5: Funciones (stored procedures → PG functions)
-- ====================================================================
\echo ''
\echo '--- DDL: Documentos Unificado Tables (pre-requisito para funciones) ---'
\i includes/sp/create_documentos_unificado.sql

\echo '--- Funciones Helper ---'
\i includes/sp/00_pg_helpers.sql

\echo '--- Funciones Sistema ---'
\i includes/sp/usp_sys.sql

\echo '--- Funciones Configuracion ---'
\i includes/sp/usp_cfg.sql

\echo '--- Funciones Configuracion Paises ---'
\i includes/sp/sp_cfg_country.sql

\echo '--- Configuracion Estados y Lookups ---'
\i includes/sp/sp_cfg_state_lookup.sql

\echo '--- Funciones Seguridad ---'
\i includes/sp/usp_sec.sql

\echo '--- Funciones Balance Maestros ---'
\i includes/sp/usp_master_balance.sql

\echo '--- Funciones Documentos Venta ---'
\i includes/sp/usp_doc_sales.sql

\echo '--- Funciones Documentos Compra ---'
\i includes/sp/usp_doc_purchase.sql

\echo '--- Funciones Cuentas por Cobrar ---'
\i includes/sp/usp_ar.sql

\echo '--- Funciones Cuentas por Pagar ---'
\i includes/sp/usp_ap.sql

\echo '--- Funciones Contabilidad ---'
\i includes/sp/usp_acct.sql

\echo '--- Funciones Contabilidad Avanzada ---'
\i includes/sp/usp_acct_advanced.sql

\echo '--- Funciones Contabilidad Patrimonio ---'
\i includes/sp/usp_acct_equity.sql

\echo '--- Activos Fijos Tables (pre-requisito para funciones) ---'
\i includes/sp/create_activos_fijos.sql

\echo '--- Funciones Contabilidad Activos Fijos ---'
\i includes/sp/usp_acct_fixedassets.sql

\echo '--- Funciones Contabilidad Inflacion ---'
\i includes/sp/usp_acct_inflation.sql

\echo '--- Funciones Contabilidad Plantillas ---'
\i includes/sp/usp_acct_templates.sql

\echo '--- Funciones Fiscal Tributaria ---'
\i includes/sp/usp_fiscal_tributaria.sql

\echo '--- Funciones Retenciones Fiscales ---'
\i includes/sp/usp_fiscal_retenciones.sql

\echo '--- Funciones Miscelaneas ---'
\i includes/sp/usp_misc.sql

\echo '--- ALTER: BankMovement.JournalEntryId ---'
\i includes/sp/alter_bank_movement_journal.sql

\echo '--- Funciones Operaciones ---'
\i includes/sp/usp_ops.sql

\echo '--- Funciones Utilidades ---'
\i includes/sp/usp_util.sql

\echo '--- Funciones Restaurante Admin ---'
\i includes/sp/usp_rest_admin.sql

\echo '--- Funciones Restaurante Recetas ---'
\i includes/sp/usp_rest_recipe.sql

\echo '--- Funciones Auditoria ---'
\i includes/sp/usp_audit.sql

\echo '--- Funciones Ecommerce ---'
\i includes/sp/usp_ecommerce.sql

\echo '--- Funciones Ecommerce Variants ---'
\i includes/sp/usp_ecommerce_variants.sql

\echo '--- Funciones CRUD Bancos ---'
\i includes/sp/sp_crud_bancos.sql

\echo '--- Funciones CRUD Almacen ---'
\i includes/sp/sp_crud_almacen.sql

\echo '--- Funciones CRUD Clientes ---'
\i includes/sp/sp_crud_clientes.sql

\echo '--- Funciones CRUD Categorias ---'
\i includes/sp/sp_crud_categorias.sql

\echo '--- Funciones CRUD Centro Costo ---'
\i includes/sp/sp_crud_centro_costo.sql

\echo '--- Funciones CRUD Clases ---'
\i includes/sp/sp_crud_clases.sql

\echo '--- Funciones CRUD Compras ---'
\i includes/sp/sp_crud_compras.sql

\echo '--- Funciones CRUD Cotizacion ---'
\i includes/sp/sp_crud_cotizacion.sql

\echo '--- Funciones CRUD Cuentas ---'
\i includes/sp/sp_crud_cuentas.sql

\echo '--- Funciones CRUD Empleados ---'
\i includes/sp/sp_crud_empleados.sql

\echo '--- Funciones CRUD Empresa ---'
\i includes/sp/sp_crud_empresa.sql

\echo '--- Funciones CRUD Facturas ---'
\i includes/sp/sp_crud_facturas.sql

\echo '--- Funciones CRUD Feriados ---'
\i includes/sp/sp_crud_feriados.sql

\echo '--- Funciones CRUD Grupos ---'
\i includes/sp/sp_crud_grupos.sql

\echo '--- Funciones CRUD Inventario ---'
\i includes/sp/sp_crud_inventario.sql

\echo '--- Funciones CRUD Lineas ---'
\i includes/sp/sp_crud_lineas.sql

\echo '--- Funciones CRUD Marcas ---'
\i includes/sp/sp_crud_marcas.sql

\echo '--- Funciones CRUD Moneda ---'
\i includes/sp/sp_crud_moneda.sql

\echo '--- Funciones CRUD Pedidos ---'
\i includes/sp/sp_crud_pedidos.sql

\echo '--- Funciones CRUD Proveedores ---'
\i includes/sp/sp_crud_proveedores.sql

\echo '--- Funciones CRUD Tipos ---'
\i includes/sp/sp_crud_tipos.sql

\echo '--- Funciones CRUD Unidades ---'
\i includes/sp/sp_crud_unidades.sql

\echo '--- Funciones CRUD Usuarios ---'
\i includes/sp/sp_crud_usuarios.sql

\echo '--- Funciones CRUD Vehiculos ---'
\i includes/sp/sp_crud_vehiculos.sql

\echo '--- Funciones CRUD Vendedores ---'
\i includes/sp/sp_crud_vendedores.sql

\echo '--- Funciones Documentos Unificado TX ---'
\i includes/sp/sp_documentos_unificado_tx.sql

\echo '--- Funciones Emitir Documento Venta TX ---'
\i includes/sp/sp_emitir_documento_venta_tx.sql

\echo '--- Funciones Emitir Documento Compra TX ---'
\i includes/sp/sp_emitir_documento_compra_tx.sql

\echo '--- Funciones Emitir Factura TX ---'
\i includes/sp/sp_emitir_factura_tx.sql

\echo '--- Funciones Emitir Pedido TX ---'
\i includes/sp/sp_emitir_pedido_tx.sql

\echo '--- Funciones Emitir Presupuesto TX ---'
\i includes/sp/sp_emitir_presupuesto_tx.sql

\echo '--- Funciones Emitir Cotizacion TX ---'
\i includes/sp/sp_emitir_cotizacion_tx.sql

\echo '--- Funciones Emitir Compra TX ---'
\i includes/sp/sp_emitir_compra_tx.sql

\echo '--- Funciones Anular Documento Venta TX ---'
\i includes/sp/sp_anular_documento_venta_tx.sql

\echo '--- Funciones Anular Documento Compra TX ---'
\i includes/sp/sp_anular_documento_compra_tx.sql

\echo '--- Funciones Anular Factura TX ---'
\i includes/sp/sp_anular_factura_tx.sql

\echo '--- Funciones Anular Pedido TX ---'
\i includes/sp/sp_anular_pedido_tx.sql

\echo '--- Funciones Anular Presupuesto TX ---'
\i includes/sp/sp_anular_presupuesto_tx.sql

\echo '--- Funciones Anular Compra TX ---'
\i includes/sp/sp_anular_compra_tx.sql

\echo '--- Funciones Lista Documentos Venta ---'
\i includes/sp/sp_documentos_venta_list.sql

\echo '--- Funciones Lista Documentos Compra ---'
\i includes/sp/sp_documentos_compra_list.sql

\echo '--- Funciones Contabilidad General ---'
\i includes/sp/sp_contabilidad_general.sql

\echo '--- Funciones CxC Cobro ---'
\i includes/sp/sp_cxc_aplicar_cobro_v2.sql

\echo '--- Funciones CxP Pago ---'
\i includes/sp/sp_cxp_aplicar_pago_v2.sql

\echo '--- Funciones Nomina Sistema ---'
\i includes/sp/sp_nomina_sistema.sql

\echo '--- Funciones Nomina Calculo ---'
\i includes/sp/sp_nomina_calculo.sql

\echo '--- Funciones Nomina Regimen ---'
\i includes/sp/sp_nomina_calculo_regimen.sql

\echo '--- Funciones Nomina Concepto Legal CRUD ---'
\i includes/sp/sp_nomina_conceptolegal_crud.sql

\echo '--- Funciones Nomina Concepto Legal Adapter ---'
\i includes/sp/sp_nomina_conceptolegal_adapter.sql

\echo '--- Funciones Nomina Constantes Convenios ---'
\i includes/sp/sp_nomina_constantes_convenios.sql

\echo '--- Funciones Nomina Constantes Venezuela ---'
\i includes/sp/sp_nomina_constantes_venezuela.sql

\echo '--- Funciones Nomina Consultas ---'
\i includes/sp/sp_nomina_consultas.sql

\echo '--- Funciones Nomina Vacaciones ---'
\i includes/sp/sp_nomina_vacaciones_liquidacion.sql

\echo '--- Funciones Nomina Venezuela ---'
\i includes/sp/sp_nomina_venezuela_install.sql

\echo '--- Funciones Nomina Batch ---'
\i includes/sp/sp_nomina_batch.sql

\echo '--- Funciones Nomina Documentos ---'
\i includes/sp/sp_nomina_documentos.sql

\echo '--- Funciones RRHH Beneficios ---'
\i includes/sp/sp_rrhh_beneficios.sql

\echo '--- Funciones RRHH Obligaciones Legales ---'
\i includes/sp/sp_rrhh_obligaciones_legales.sql

\echo '--- Funciones RRHH Salud Ocupacional ---'
\i includes/sp/sp_rrhh_salud_ocupacional.sql

\echo '--- Funciones Vacaciones ---'
\i includes/sp/sp_vacation_request.sql

\echo '--- Funciones Caja Chica ---'
\i includes/sp/usp_fin_pettycash.sql

\echo '--- Funciones XML Compat ---'
\i includes/sp/usp_xml_compat.sql

\echo '--- Dispositivos Push ---'
\i includes/sp/usp_sys_device.sql

\echo '--- Notificaciones ---'
\i includes/sp/sys_notificaciones.sql

\echo '--- Seeds Account Plan ---'
\i includes/sp/seed_account_plan.sql

\echo '--- Seeds Contabilidad ---'
\i includes/sp/seed_contabilidad.sql

\echo '--- Settings Table ---'
\i includes/sp/settings_table.sql

\echo '--- Payment Gateway Tables ---'
\i includes/sp/payment_gateway_tables.sql

\echo '--- Tablas HR RRHH (Salud, Beneficios, Comités) ---'
\i includes/sp/create_hr_rrhh_tables.sql

\echo '--- Cierre Mensual Inventario ---'
\i includes/sp/create_cierre_mensual_inventario.sql

\echo '--- Contabilidad General Tables ---'
\i includes/sp/create_contabilidad_general.sql


\echo '--- Fiscal Tributaria Tables ---'
\i includes/sp/create_fiscal_tributaria.sql

\echo '--- Retenciones Fiscales Schema ---'
\i 18_fiscal_retenciones_schema.sql

\echo '--- Tablas Legales Contabilidad ---'
\i includes/sp/acct_legal_tables.sql

\echo '--- Balance Compat ---'
\i includes/sp/balance_compat.sql

\echo '--- Fiscal Multipais Base ---'
\i includes/sp/001_fiscal_multipais_base.sql

\echo '--- Governance Baseline ---'
\i includes/sp/00_governance_baseline.sql

\echo '--- Indices Inventario Cierre ---'
\i includes/sp/add_indexes_inventario_cierre.sql

\echo '--- Vacation Request Tables ---'
\i includes/sp/create_vacation_request.sql

\echo '--- Supervisor Biometric Credentials ---'
\i includes/sp/create_supervisor_biometric_credentials.sql

\echo '--- Supervisor Override Controls ---'
\i includes/sp/create_supervisor_override_controls.sql

\echo '--- Alter Employee Position Company Address ---'
\i includes/sp/alter_employee_position_company_address.sql

\echo '--- Seed Constantes y Conceptos Legal ---'
\i includes/sp/seed_constantes_y_conceptos_legal.sql

\echo '--- Seed Gananciales y Deducciones ---'
\i includes/sp/seed_gananciales_y_deducciones_completo.sql

\echo '--- Seed Restaurante Componentes Recetas ---'
\i includes/sp/seed_restaurante_componentes_recetas.sql

\echo '--- Seed Restaurante Menu Extra ---'
\i includes/sp/seed_restaurante_menu_extra.sql

\echo '--- Seed Nomina Completo (batches, vacaciones, salud ocupacional) ---'
\i includes/sp/seed_nomina_completo.sql

\echo '--- Seed Nomina Completo P2 (capacitacion, ahorro, obligaciones) ---'
\i includes/sp/seed_nomina_completo_p2.sql

\echo '--- Seed RRHH Completo (utilidades, prestaciones, caja ahorro) ---'
\i includes/sp/seed_rrhh_completo.sql

\echo '--- Seed Plantillas de Reportes Contables ---'
\i includes/sp/seed_report_templates.sql

\echo '--- Seed Demo Contabilidad ---'
\i includes/sp/seed_contabilidad_demo.sql

\echo '--- Seed Demo Clientes y Documentos ---'
\i includes/sp/seed_demo_clientes_documentos.sql

\echo '--- Seed Demo Ecommerce y POS ---'
\i includes/sp/seed_demo_ecommerce_pos.sql

\echo '--- Seed Demo Finanzas y Contabilidad ---'
\i includes/sp/seed_demo_finanzas_contabilidad.sql

\echo '--- Seed Demo Inventario Avanzado ---'
\i includes/sp/seed_demo_inventario_avanzado.sql

\echo '--- Seed Demo Logistica ---'
\i includes/sp/seed_demo_logistica.sql

\echo '--- Seed Demo CRM ---'
\i includes/sp/seed_demo_crm.sql

\echo '--- Seed Demo Manufactura ---'
\i includes/sp/seed_demo_manufactura.sql

\echo '--- Seed Demo Flota ---'
\i includes/sp/seed_demo_flota.sql

\echo '--- Seed Demo RBAC ---'
\i includes/sp/seed_demo_rbac.sql

\echo '--- Funciones Flota ---'
\i includes/sp/usp_fleet.sql

\echo '--- Funciones RBAC (Permisos Granulares) ---'
\i includes/sp/usp_rbac.sql

\echo '--- Funciones Inventario Avanzado ---'
\i includes/sp/usp_inv.sql

\echo '--- Funciones Logistica ---'
\i includes/sp/usp_logistics.sql

\echo '--- Funciones CRM ---'
\i includes/sp/usp_crm.sql
\i includes/sp/usp_crm_analytics.sql
\i includes/sp/usp_crm_scoring.sql
\i includes/sp/usp_crm_automation.sql
\i includes/sp/usp_crm_reports.sql

\echo '--- Funciones Compras Analytics ---'
\i includes/sp/usp_purchases_analytics.sql

\echo '--- Funciones Ventas Analytics ---'
\i includes/sp/usp_sales_analytics.sql

\echo '--- Funciones Manufactura ---'
\i includes/sp/usp_mfg.sql

\echo '--- Funciones Flota ---'
\i includes/sp/usp_fleet.sql

\echo '--- Funciones RBAC Permisos ---'
\i includes/sp/usp_rbac.sql

\echo '--- Seed Usuarios Demo (admin, gerente, cajero / pass: Admin123!) ---'
\i includes/sp/seed_demo_users.sql

\echo '--- Seed Live Data (exportado desde SQL Server) ---'
\i includes/sp/seed_live_data.sql

-- ====================================================================
-- FASE 6: Corrección de tipos de retorno (character varying vs text)
-- Los archivos includes/sp/ crean funciones con tipos que pueden
-- generar mismatch en PG 15+. Esta fase los reemplaza con las
-- versiones corregidas (NULLIF/UPPER/COALESCE con casts explícitos).
-- ====================================================================
\echo ''
\echo '╔══════════════════════════════════════════════════════╗'
\echo '║  FASE 6: Funciones con tipos corregidos (PG 15+)    ║'
\echo '╚══════════════════════════════════════════════════════╝'

\echo '[F6-01] Seguridad...'
\i 01_sec.sql

\echo '[F6-02] Configuracion...'
\i 02_cfg.sql

\echo '[F6-03] RRHH / Nomina...'
\i 03_hr.sql

\echo '[F6-04] Inventario...'
\i 04_inventario.sql

\echo '[F6-05] Maestros (clientes, proveedores, etc.)...'
\i 05_master.sql

\echo '[F6-06] Documentos (ventas, compras)...'
\i 06_doc.sql

\echo '[F6-07] Contabilidad...'
\i 07_acct.sql

\echo '[F6-08] Finanzas (bancos, CxC, CxP)...'
\i 08_fin.sql

\echo '[F6-09] POS / Restaurante...'
\i 09_pos.sql

\echo '[F6-10] Fiscal / Auditoria...'
\i 10_fiscal.sql

\echo '[F6-11] Pagos...'
\i 11_pay.sql

\echo '--- Funciones Pagos (overrides 11_pay.sql con tipos correctos) ---'
\i includes/sp/usp_pay.sql

\echo '[F6-12] Sistema...'
\i 12_sys.sql

\echo '[F6-13] Otros...'
\i 13_otros.sql

-- ====================================================================
-- FASE 6.5: Correcciones de column ambiguity y type mismatch
-- Estos fixes sobreescriben funciones con errores de:
--   - "column reference X is ambiguous" (sin alias de tabla)
--   - "structure of query does not match" (TEXT vs VARCHAR)
-- Se aplican DESPUES de todas las fases para garantizar que queden
-- las versiones correctas en produccion.
-- ====================================================================
\echo '[F6.5] Aplicando correcciones de ambiguedad y tipos...'
\i fixes/fix_all_ambiguity.sql
\i fixes/fix_account_list.sql
\i fixes/fix_acct_crud.sql
\i fixes/fix_nomina_rrhh.sql
\i fixes/fix_nomina_rrhh_p2.sql
\i fixes/fix_nomina_rrhh_p3.sql
\i fixes/fix_nomina_rrhh_p4.sql
\i fixes/fix_nomina_rrhh_p5.sql
\i fixes/fix_nomina_rrhh_p6.sql
\i fixes/fix_nomina_rrhh_p7.sql
\i fixes/fix_nomina_rrhh_p8.sql
\i fixes/fix_nomina_rrhh_p9.sql
\i fixes/fix_clientes_pg.sql
\i fixes/fix_proveedores_pg.sql
\i fixes/fix_empleados_pg.sql
\i fixes/fix_categorias_marcas_unidades_pg.sql
\i fixes/fix_costcenter_period_list.sql
\i fixes/fix_costcenter_crud.sql
\i fixes/fix_inventario_movimientos_pg.sql
\i fixes/fix_remaining_ambiguous.sql
\i fixes/fix_period_userid.sql
\i fixes/fix_recurringentry_getdue.sql
\i fixes/fix_budget_functions.sql
\i fixes/fix_budget_v2.sql
\i fixes/fix_budget_no_annualtotal.sql
\i fixes/fix_recurringentry_crud.sql
\i fixes/fix_recurringentry_get.sql
\i fixes/fix_recurringentry_execute.sql
\i fixes/fix_timestamp_type_mismatches.sql
\i fixes/fix_inv_movement_types.sql
\i fixes/fix_bank_reconciliation_timestamps.sql
\i fixes/fix_bigint_and_char_mismatches.sql
\i fixes/fix_cfg_appsetting_types.sql

-- ====================================================================
-- FASE 6.9: Multi-tenant — columnas y SPs de provisioning
-- ====================================================================
\echo ''
\echo '--- Multi-tenant: ALTER cfg.Company ---'
\i includes/sp/alter_cfg_company_tenant.sql
\echo '--- SP usp_Cfg_Tenant_Provision ---'
\i includes/sp/usp_cfg_tenant_provision.sql
\echo '--- SP usp_Cfg_Tenant_GetInfo ---'
\i includes/sp/usp_cfg_tenant_getinfo.sql

-- ====================================================================
-- FASE 6.10: Billing / Subscription (SaaS Paddle)
-- ====================================================================
\echo ''
\echo '--- Billing: tablas + SPs ---'
\i includes/sp/usp_sys_billing.sql
\echo '--- SP usp_Cfg_Tenant_ResolveSubdomain ---'
\i includes/sp/usp_cfg_tenant_resolve.sql
\echo '--- SP usp_sys_Subscription_CheckAccess ---'
\i includes/sp/usp_sys_subscription_check.sql

-- ====================================================================
-- FASE 7: Permisos de aplicacion
-- ====================================================================
\echo ''
\echo '--- Permisos zentto_app en todos los schemas ---'
GRANT USAGE ON SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store TO zentto_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store GRANT ALL ON TABLES TO zentto_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store GRANT ALL ON SEQUENCES TO zentto_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA acct, ap, ar, audit, cfg, doc, fin, fiscal, hr, master, pay, pos, public, rest, sec, store GRANT EXECUTE ON FUNCTIONS TO zentto_app;

-- ====================================================================
-- FASE 7.5: Landing / Leads
-- ====================================================================
\echo 'Creando tabla Lead...'
\i includes/sp/ddl_sys_Lead.sql
\echo 'Creando funcion usp_sys_lead_upsert...'
\i includes/sp/usp_sys_Lead_Upsert.sql

-- ====================================================================
-- FASE 8: Migraciones post-despliegue
-- Aplican correcciones incrementales sobre los SPs ya creados.
-- Cada migración es idempotente (ON CONFLICT DO NOTHING).
-- ====================================================================
\echo ''
\echo '--- Migraciones post-despliegue ---'
\echo '  [001] POS BIGINT overload fixes'
\i migrations/001_pos_bigint_overload_fixes.sql
\echo '  [002] Product ecommerce columns'
\i migrations/002_product_ecommerce_columns.sql
\echo '  [003] cfg.AppSetting fiscal port type'
\i migrations/003_cfg_appsetting_fiscal_port.sql
\echo '  [004] Drop remaining overloads'
\i migrations/004_drop_remaining_overloads.sql
\echo '  [005] Drop prod overloads'
\i migrations/005_drop_prod_overloads.sql
\echo '  [006] Fix waitticketline_getitems bigint'
\i migrations/006_fix_waitticketline_getitems_bigint.sql
\echo '  [007] Fix all type mismatches (27 funciones)'
\i migrations/007_fix_all_type_mismatches.sql
\echo '  [008] Fix TIMESTAMPTZ → TIMESTAMP (sin zona)'
\i migrations/008_fix_timestamptz_to_timestamp.sql
\echo '  [009] Fix parámetros BIGINT entidades (batch_id, product_id, movimiento_id)'
\i migrations/009_fix_bigint_entity_params.sql
\echo '  [010] Fix parámetros BIGINT en acct, ops, rest_admin (sale_ticket, order_ticket, customer, product, supplier)'
\i migrations/010_fix_bigint_params_acct_ops_rest.sql
\echo '  [011] Fix overloads duplicados y parámetros BIGINT restantes (pettycash, hr, acct, rest_admin)'
\i migrations/011_fix_overloads_bigint_remaining.sql
\echo '  [012] Fix TEXT→VARCHAR en HR/RRHH + restaurar public.* pettycash'
\i migrations/012_fix_text_varchar_hr_pettycash.sql
\echo '  [013] Fix TIMESTAMPTZ→TIMESTAMP en funciones public.* pettycash'
\i migrations/013_fix_timestamptz_pettycash.sql
\echo '  [014] Fix ambiguedad OperationType en usp_doc_salesdocument_list'
\i migrations/014_fix_salesdocument_list_ambiguous.sql
\echo '  [015] Fix bpchar CurrencyCode en usp_ar_application_listbycontext'
\i migrations/015_fix_abonos_currencycode_bpchar.sql
\echo '  [016] Fix bpchar CountryCode en usp_pay_companyconfig_listbycompany'
\i migrations/016_fix_pay_companyconfig_countrycode.sql
\echo '  [017] Fix ambiguedad + columnas reales en usp_doc_purchasedocument_list'
\i migrations/017_fix_purchasedocument_list_columns.sql
\echo '  [019] Re-despliegue usp_acct_advanced y usp_acct_fixedassets'
\i migrations/019_redeploy_acct_advanced_fixedassets.sql
\echo '  [020] Crear usp_Cfg_Scope_GetDefault'
\i migrations/020_add_cfg_scope_getdefault.sql
\echo '  [021] Limpiar columnas canónicas en usp_Proveedores_List/GetByCodigo'
\i migrations/021_fix_proveedores_clean_columns.sql
\echo '  [022] Fix BIGINT en funciones restaurante (DiningTable, MenuProduct, Purchase, etc.)'
\i migrations/022_fix_rest_bigint_return_types.sql
\echo '  [023] Fix ORDER BY seguro en mesas + metadata functions para CRUD admin PG'
\i migrations/023_fix_mesas_order_and_metadata.sql
\echo '  [024] Fix BIGINT en GET producto + seed mesas/ambientes'
\i migrations/024_fix_producto_get_bigint_and_seed_mesas.sql
\echo '  [025] Fix BIGINT en 14 funciones OrderTicket/OrderTicketLine'
\i migrations/025_fix_orderticket_bigint.sql
\echo '  [026] Fix posicionX/Y INT + ::VARCHAR casts CountryCode en 8 funciones restaurante'
\i migrations/026_fix_diningtable_position_and_countrycode_casts.sql
\echo '  [027] Fix overloads duplicados en usp_rest_orderticketline_insert'
\i migrations/027_fix_orderticketline_insert_overloads.sql
\echo '  [028] ADD columnas auditoría OrderTicket.UpdatedAt + OrderTicketLine.CreatedAt/UpdatedAt'
\i migrations/028_fix_orderticketline_insert_no_audit_cols.sql
\echo '  [029] Fix SPs contabilidad avanzada (periodos, centros-costo, recurrentes, presupuestos)'
\i migrations/029_fix_acct_advanced_all_sps.sql

-- ====================================================================
-- FASE 8: Inventario Avanzado + Logistica
-- ====================================================================
\echo ''
\echo '--- Inventario Avanzado (inv.*) ---'
\i includes/sp/usp_inv.sql
\i includes/sp/usp_inv_integracion.sql

\echo '--- Logistica (logistics.*) ---'
\i includes/sp/usp_logistics.sql

\echo '--- Shipping Portal (logistics.Shipping*) ---'
\i includes/sp/usp_shipping.sql

-- ====================================================================
-- FASE 9: Verificacion
-- ====================================================================
\echo ''
\echo '╔══════════════════════════════════════════════════════╗'
\echo '║  Verificacion de objetos                            ║'
\echo '╚══════════════════════════════════════════════════════╝'
\i tools/verify_migration.sql

\echo ''
\echo '=== DatqBoxWeb PostgreSQL deployment COMPLETO ==='
\echo ''
