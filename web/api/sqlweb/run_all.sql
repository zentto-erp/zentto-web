:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\00_create_database_datqboxweb.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\01_core_foundation.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\02_master_data.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\03_accounting_core.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\04_operations_core.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\05_api_compat_bridge.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\06_seed_reference_data.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\07_pos_rest_extensions.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\08_fin_hr_rest_admin_extensions.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\10_legacy_api_sps_compat.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\11_legacy_cleanup_upsize_ts.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\12_seed_smoke_test_data.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\13_auth_compat_and_seed.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\14_rest_order_ticket_audit_compat.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\15_inventario_id_compat.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\16_sistema_tables_seed.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\17_media_assets.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\18_media_asset_key_length_fix.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\001_user_company_access.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\003_branch_country_support.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\004_country_timezone_support.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\005_auth_security_hardening.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\002_seed_multicompany_demo.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\19_canonical_maestros_and_missing.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\20_rebuild_maestros_sps.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\21_canonical_document_tables.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\22_canonical_usuarios_fiscal.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\23_additional_sps.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\24_nomina_sps.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\25_contabilidad_sps.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\26_fiscal_tables.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\27_seeds_additional.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\28_extra_tables.sql

-- ====================================================================
-- Stored Procedures: API REST -> SP (sin SQL directo en TypeScript)
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_sys.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_cfg.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_sec.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_master_balance.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_doc_sales.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_doc_purchase.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_ar.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_ap.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_acct.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_pay.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_misc.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\alter_bank_movement_journal.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_ops.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_util.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_rest_admin.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_audit.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_bancos_conciliacion.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_bancos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_fin_pettycash.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_ecommerce.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\29_fiscal_retenciones_schema.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\09_inventory_advanced.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\10_logistics.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\11_crm.sql

-- ====================================================================
-- RRHH: Beneficios, Obligaciones Legales, Salud Ocupacional
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_cfg_country.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_rrhh_beneficios.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_rrhh_obligaciones_legales.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_rrhh_salud_ocupacional.sql

-- ====================================================================
-- Nómina: Sistema de cálculo, Constantes, Convenios, Documentos Legales
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_nomina_sistema.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_nomina_calculo.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_nomina_constantes_venezuela.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_nomina_constantes_convenios.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_nomina_documentos.sql

-- ====================================================================
-- Contabilidad Legal: Inflacion, Patrimonio, Plantillas Reportes
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\acct_legal_tables.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_acct_inflation.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_acct_templates.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_acct_equity.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_report_templates.sql

-- ====================================================================
-- Activos Fijos: Tablas canonicas + Seed categorias
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_activos_fijos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_acct_fixedassets.sql

-- ====================================================================
-- Gestion Fiscal/Tributaria: Declaraciones, Libros, Retenciones
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\create_fiscal_tributaria.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\usp_fiscal_tributaria.sql

-- ====================================================================
-- Seeds Demo: Datos completos para demos y pruebas
-- ====================================================================
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_contabilidad_demo.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_demo_clientes_documentos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_demo_finanzas_contabilidad.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\seed_demo_ecommerce_pos.sql
