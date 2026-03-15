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
\echo '--- Funciones Helper ---'
\i includes/sp/00_pg_helpers.sql

\echo '--- Funciones Sistema ---'
\i includes/sp/usp_sys.sql

\echo '--- Funciones Configuracion ---'
\i includes/sp/usp_cfg.sql

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

\echo '--- Funciones Pagos ---'
\i includes/sp/usp_pay.sql

\echo '--- Funciones Miscelaneas ---'
\i includes/sp/usp_misc.sql

\echo '--- Funciones Operaciones ---'
\i includes/sp/usp_ops.sql

\echo '--- Funciones Utilidades ---'
\i includes/sp/usp_util.sql

\echo '--- Funciones Restaurante Admin ---'
\i includes/sp/usp_rest_admin.sql

\echo '--- Funciones Auditoria ---'
\i includes/sp/usp_audit.sql

\echo '--- Funciones Ecommerce ---'
\i includes/sp/usp_ecommerce.sql

\echo '--- Funciones CRUD Inventario ---'
\i includes/sp/sp_crud_inventario.sql

\echo '--- Funciones CRUD Categorias ---'
\i includes/sp/sp_crud_categorias.sql

\echo '--- Funciones CRUD Usuarios ---'
\i includes/sp/sp_crud_usuarios.sql

\echo '--- Funciones CRUD Vehiculos ---'
\i includes/sp/sp_crud_vehiculos.sql

\echo '--- Funciones CRUD Bancos ---'
\i includes/sp/sp_crud_bancos.sql

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

\echo '--- Funciones Bancos Conciliacion ---'
\i includes/sp/sp_bancos_conciliacion.sql

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

\echo '--- Funciones Nomina Concepto Legal ---'
\i includes/sp/sp_nomina_conceptolegal_adapter.sql

\echo '--- Funciones Nomina Constantes ---'
\i includes/sp/sp_nomina_constantes_convenios.sql

\echo '--- Funciones Nomina Vacaciones ---'
\i includes/sp/sp_nomina_vacaciones_liquidacion.sql

\echo '--- Funciones Nomina Venezuela ---'
\i includes/sp/sp_nomina_venezuela_install.sql

\echo '--- Funciones POS Ventas Espera ---'
\i includes/sp/sp_pos_ventas_espera.sql

\echo '--- Funciones POS Restaurante ---'
\i includes/sp/sp_pos_restaurante.sql

\echo '--- Funciones Restaurante Admin ---'
\i includes/sp/sp_restaurante_admin.sql

\echo '--- Funciones Restaurante Compra ---'
\i includes/sp/sp_restaurante_compra_xml.sql

\echo '--- Funciones Vacaciones ---'
\i includes/sp/sp_vacation_request.sql

\echo '--- Funciones Caja Chica ---'
\i includes/sp/usp_fin_pettycash.sql

\echo '--- Funciones XML Compat ---'
\i includes/sp/usp_xml_compat.sql

\echo '--- Seeds Account Plan ---'
\i includes/sp/seed_account_plan.sql

\echo '--- Seeds Contabilidad ---'
\i includes/sp/seed_contabilidad.sql

\echo '--- Settings Table ---'
\i includes/sp/settings_table.sql

\echo '--- Payment Gateway Tables ---'
\i includes/sp/payment_gateway_tables.sql

\echo '--- Cierre Mensual Inventario ---'
\i includes/sp/create_cierre_mensual_inventario.sql

\echo '--- Contabilidad General Tables ---'
\i includes/sp/create_contabilidad_general.sql

\echo '--- Documentos Unificado Tables ---'
\i includes/sp/create_documentos_unificado.sql

\echo '--- Balance Compat ---'
\i includes/sp/balance_compat.sql

\echo '--- Fiscal Multipais Base ---'
\i includes/sp/001_fiscal_multipais_base.sql

\echo '--- Governance Baseline ---'
\i includes/sp/00_governance_baseline.sql

\echo '--- Indices Inventario Cierre ---'
\i includes/sp/add_indexes_inventario_cierre.sql

\echo '--- Fulltext Inventario ---'
\i includes/sp/fulltext_index_inventario.sql

-- ====================================================================
-- FASE 6: Verificacion
-- ====================================================================
\echo ''
\echo '╔══════════════════════════════════════════════════════╗'
\echo '║  Verificacion de objetos                            ║'
\echo '╚══════════════════════════════════════════════════════╝'
\i tools/verify_migration.sql

\echo ''
\echo '=== DatqBoxWeb PostgreSQL deployment COMPLETO ==='
\echo ''
