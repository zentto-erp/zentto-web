-- ============================================================
-- run-functions.sql — Re-crea TODAS las funciones PG (CREATE OR REPLACE)
-- Se ejecuta en cada deploy después de goose + seeds
-- Idempotente: CREATE OR REPLACE no borra datos
-- ============================================================

\echo ''
\echo '============================================================'
\echo '  Zentto — Recrear TODAS las funciones PostgreSQL'
\echo '============================================================'
\echo ''

-- ============================================================
-- PASO 0: Eliminar sobrecargas duplicadas (nuclear cleanup)
-- Si una función tiene >1 sobrecarga con mismo nombre, borra TODAS
-- para que el CREATE OR REPLACE de abajo las recree limpiamente.
-- Esto previene el error "function is not unique" en producción.
-- ============================================================
\echo '[00] Nuclear: eliminando sobrecargas duplicadas...'
DO $cleanup$
DECLARE
  _func_name TEXT;
  _oid OID;
  _dropped INT := 0;
BEGIN
  -- Encontrar funciones con más de 1 sobrecarga en public
  FOR _func_name IN
    SELECT p.proname
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname LIKE 'usp_%'
    GROUP BY p.proname
    HAVING COUNT(*) > 1
  LOOP
    -- Borrar TODAS las sobrecargas de esta función
    FOR _oid IN
      SELECT p.oid
      FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = _func_name
    LOOP
      EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
      _dropped := _dropped + 1;
    END LOOP;
    RAISE NOTICE 'Dropped all overloads of: %', _func_name;
  END LOOP;
  IF _dropped > 0 THEN
    RAISE NOTICE 'Total functions dropped: %', _dropped;
  ELSE
    RAISE NOTICE 'No duplicate overloads found — all clean';
  END IF;
END $cleanup$;

\echo '[01] usp_sys.sql'
\i includes/sp/usp_sys.sql

\echo '[02] usp_cfg.sql'
\i includes/sp/usp_cfg.sql

\echo '[03] sp_cfg_country.sql'
\i includes/sp/sp_cfg_country.sql

\echo '[04] sp_cfg_state_lookup.sql'
\i includes/sp/sp_cfg_state_lookup.sql

\echo '[05] usp_sec.sql'
\i includes/sp/usp_sec.sql

\echo '[06] usp_master_balance.sql'
\i includes/sp/usp_master_balance.sql

\echo '[07] usp_doc_sales.sql'
\i includes/sp/usp_doc_sales.sql

\echo '[07b] usp_sales_analytics.sql'
\i includes/sp/usp_sales_analytics.sql

\echo '[08] usp_doc_purchase.sql'
\i includes/sp/usp_doc_purchase.sql

\echo '[08b] usp_purchases_analytics.sql'
\i includes/sp/usp_purchases_analytics.sql

\echo '[09] usp_ar.sql'
\i includes/sp/usp_ar.sql

\echo '[10] usp_ap.sql'
\i includes/sp/usp_ap.sql

\echo '[11] usp_acct.sql'
\i includes/sp/usp_acct.sql

\echo '[12] usp_acct_advanced.sql'
\i includes/sp/usp_acct_advanced.sql

\echo '[13] usp_acct_equity.sql'
\i includes/sp/usp_acct_equity.sql

\echo '[14] usp_acct_fixedassets.sql'
\i includes/sp/usp_acct_fixedassets.sql

\echo '[15] usp_acct_inflation.sql'
\i includes/sp/usp_acct_inflation.sql

\echo '[16] usp_acct_templates.sql'
\i includes/sp/usp_acct_templates.sql

\echo '[17] usp_fiscal_tributaria.sql'
\i includes/sp/usp_fiscal_tributaria.sql

\echo '[18] usp_fiscal_retenciones.sql'
\i includes/sp/usp_fiscal_retenciones.sql

\echo '[19] usp_pay.sql'
\i includes/sp/usp_pay.sql

\echo '[20] usp_misc.sql'
\i includes/sp/usp_misc.sql

\echo '[21] usp_ops.sql'
\i includes/sp/usp_ops.sql

\echo '[22] usp_util.sql'
\i includes/sp/usp_util.sql

\echo '[23] usp_ecommerce.sql'
\i includes/sp/usp_ecommerce.sql

\echo '[24] usp_ecommerce_variants.sql'
\i includes/sp/usp_ecommerce_variants.sql

\echo '[25] usp_audit.sql'
\i includes/sp/usp_audit.sql

\echo '[26] usp_inv.sql'
\i includes/sp/usp_inv.sql

\echo '[27] usp_logistics.sql'
\i includes/sp/usp_logistics.sql

\echo '[27b] usp_logistics_analytics.sql'
\i includes/sp/usp_logistics_analytics.sql

\echo '[27c] usp_shipping.sql'
\i includes/sp/usp_shipping.sql

\echo '[28] usp_crm.sql'
\i includes/sp/usp_crm.sql

\echo '[29] usp_crm_callcenter.sql'
\i includes/sp/usp_crm_callcenter.sql

\echo '[29b] usp_crm_analytics.sql'
\i includes/sp/usp_crm_analytics.sql

\echo '[29c] usp_crm_scoring.sql'
\i includes/sp/usp_crm_scoring.sql

\echo '[29d] usp_crm_automation.sql'
\i includes/sp/usp_crm_automation.sql

\echo '[29e] usp_crm_reports.sql'
\i includes/sp/usp_crm_reports.sql

\echo '[30] usp_mfg.sql'
\i includes/sp/usp_mfg.sql

\echo '[30b] usp_mfg_analytics.sql'
\i includes/sp/usp_mfg_analytics.sql

\echo '[31] usp_fleet.sql'
\i includes/sp/usp_fleet.sql

\echo '[31b] usp_fleet_analytics.sql'
\i includes/sp/usp_fleet_analytics.sql

\echo '[32] usp_rbac.sql'
\i includes/sp/usp_rbac.sql

\echo '[33] usp_fin_pettycash.sql'
\i includes/sp/usp_fin_pettycash.sql

\echo '[34] usp_rest_admin.sql'
\i includes/sp/usp_rest_admin.sql

\echo '[35] usp_rest_recipe.sql'
\i includes/sp/usp_rest_recipe.sql

\echo '[36] sp_crud_bancos.sql'
\i includes/sp/sp_crud_bancos.sql

\echo '[37] sp_crud_almacen.sql'
\i includes/sp/sp_crud_almacen.sql

\echo '[38] sp_crud_clientes.sql'
\i includes/sp/sp_crud_clientes.sql

\echo '[39] sp_crud_categorias.sql'
\i includes/sp/sp_crud_categorias.sql

\echo '[40] sp_crud_centro_costo.sql'
\i includes/sp/sp_crud_centro_costo.sql

\echo '[41] sp_crud_clases.sql'
\i includes/sp/sp_crud_clases.sql

\echo '[42] sp_crud_compras.sql'
\i includes/sp/sp_crud_compras.sql

\echo '[43] sp_crud_cotizacion.sql'
\i includes/sp/sp_crud_cotizacion.sql

\echo '[44] sp_crud_cuentas.sql'
\i includes/sp/sp_crud_cuentas.sql

\echo '[45] sp_crud_empleados.sql'
\i includes/sp/sp_crud_empleados.sql

\echo '[46] sp_crud_empresa.sql'
\i includes/sp/sp_crud_empresa.sql

\echo '[47] sp_crud_facturas.sql'
\i includes/sp/sp_crud_facturas.sql

\echo '[48] sp_crud_grupos.sql'
\i includes/sp/sp_crud_grupos.sql

\echo '[49] sp_crud_inventario.sql'
\i includes/sp/sp_crud_inventario.sql

\echo '[50] sp_crud_lineas.sql'
\i includes/sp/sp_crud_lineas.sql

\echo '[51] sp_crud_marcas.sql'
\i includes/sp/sp_crud_marcas.sql

\echo '[52] sp_crud_moneda.sql'
\i includes/sp/sp_crud_moneda.sql

\echo '[53] sp_crud_pedidos.sql'
\i includes/sp/sp_crud_pedidos.sql

\echo '[54] sp_crud_proveedores.sql'
\i includes/sp/sp_crud_proveedores.sql

\echo '[55] sp_crud_tipos.sql'
\i includes/sp/sp_crud_tipos.sql

\echo '[56] sp_crud_unidades.sql'
\i includes/sp/sp_crud_unidades.sql

\echo '[57] sp_crud_usuarios.sql'
\i includes/sp/sp_crud_usuarios.sql

\echo '[58] sp_crud_vendedores.sql'
\i includes/sp/sp_crud_vendedores.sql

\echo '[59] sp_contabilidad_general.sql'
\i includes/sp/sp_contabilidad_general.sql

\echo '[60] sp_bancos_conciliacion.sql'
\i includes/sp/sp_bancos_conciliacion.sql

\echo '[61] sp_pos_restaurante.sql'
\i includes/sp/sp_pos_restaurante.sql

\echo '[62] sp_pos_ventas_espera.sql'
\i includes/sp/sp_pos_ventas_espera.sql

\echo '[63] sp_restaurante_admin.sql'
\i includes/sp/sp_restaurante_admin.sql

\echo '[64] sp_nomina_sistema.sql'
\i includes/sp/sp_nomina_sistema.sql

\echo '[65] sp_nomina_calculo.sql'
\i includes/sp/sp_nomina_calculo.sql

\echo '[66] sp_nomina_batch.sql'
\i includes/sp/sp_nomina_batch.sql

\echo '[67] sp_nomina_consultas.sql'
\i includes/sp/sp_nomina_consultas.sql

\echo '[68] sp_nomina_documentos.sql'
\i includes/sp/sp_nomina_documentos.sql

\echo '[69] sp_nomina_vacaciones_liquidacion.sql'
\i includes/sp/sp_nomina_vacaciones_liquidacion.sql

\echo '[70] sp_rrhh_beneficios.sql'
\i includes/sp/sp_rrhh_beneficios.sql

\echo '[71] sp_rrhh_obligaciones_legales.sql'
\i includes/sp/sp_rrhh_obligaciones_legales.sql

\echo '[72] sp_rrhh_salud_ocupacional.sql'
\i includes/sp/sp_rrhh_salud_ocupacional.sql

\echo '[73] sp_documentos_venta_list.sql'
\i includes/sp/sp_documentos_venta_list.sql

\echo '[74] sp_documentos_compra_list.sql'
\i includes/sp/sp_documentos_compra_list.sql

\echo '[75] sp_emitir_factura_tx.sql'
\i includes/sp/sp_emitir_factura_tx.sql

\echo '[76] sp_emitir_documento_venta_tx.sql'
\i includes/sp/sp_emitir_documento_venta_tx.sql

\echo '[77] sp_emitir_documento_compra_tx.sql'
\i includes/sp/sp_emitir_documento_compra_tx.sql

\echo '[78] sp_documentos_unificado_tx.sql'
\i includes/sp/sp_documentos_unificado_tx.sql

\echo '[BYOC] Funciones de deploy en entorno propio...'
\i includes/sp/usp_byoc.sql

\echo '[PLAN MODULES + LICENSE] Módulos por plan y control de licencias...'
\i includes/sp/usp_cfg_plan_modules.sql
\i includes/sp/usp_sys_license.sql
\i includes/sp/usp_sys_backoffice.sql
\i includes/sp/usp_sys_resource.sql
\echo '[BACKUP] usp_sys_backup.sql'
\i includes/sp/usp_sys_backup.sql

\echo '[79] sp_anular_factura_tx.sql'
\i includes/sp/sp_anular_factura_tx.sql

\echo '[80] sp_anular_documento_venta_tx.sql'
\i includes/sp/sp_anular_documento_venta_tx.sql

\echo '[81] sp_anular_documento_compra_tx.sql'
\i includes/sp/sp_anular_documento_compra_tx.sql

\echo '[82] sp_cxc_aplicar_cobro_v2.sql'
\i includes/sp/sp_cxc_aplicar_cobro_v2.sql

\echo '[83] sp_cxp_aplicar_pago_v2.sql'
\i includes/sp/sp_cxp_aplicar_pago_v2.sql

\echo '[84] usp_sys_billing.sql'
\i includes/sp/usp_sys_billing.sql

\echo '[85] usp_sys_device.sql'
\i includes/sp/usp_sys_device.sql

\echo '[86] usp_sys_subscription_check.sql'
\i includes/sp/usp_sys_subscription_check.sql

\echo '[87] usp_cfg_tenant_provision.sql'
\i includes/sp/usp_cfg_tenant_provision.sql

\echo '[88] usp_cfg_tenant_resolve.sql'
\i includes/sp/usp_cfg_tenant_resolve.sql

\echo '[89] sp_nomina_conceptolegal_crud.sql'
\i includes/sp/sp_nomina_conceptolegal_crud.sql

\echo '[90] usp_xml_compat.sql'
\i includes/sp/usp_xml_compat.sql

\echo '[91] 00_pg_helpers.sql'
\i includes/sp/00_pg_helpers.sql

\echo '[92] balance_compat.sql'
\i includes/sp/balance_compat.sql

\echo '[93] sp_nomina_conceptolegal_adapter.sql'
\i includes/sp/sp_nomina_conceptolegal_adapter.sql

\echo '[94] sp_nomina_calculo_regimen.sql'
\i includes/sp/sp_nomina_calculo_regimen.sql

\echo '[95] sp_nomina_venezuela_install.sql'
\i includes/sp/sp_nomina_venezuela_install.sql

\echo '[96] sp_crud_feriados.sql'
\i includes/sp/sp_crud_feriados.sql

\echo '[97] sp_crud_vehiculos.sql'
\i includes/sp/sp_crud_vehiculos.sql

\echo '[98] sys_alertas.sql'
\i includes/sp/sys_alertas.sql

\echo '[99] sys_notificaciones.sql'
\i includes/sp/sys_notificaciones.sql

\echo '[100] usp_cfg_tenant_getinfo.sql'
\i includes/sp/usp_cfg_tenant_getinfo.sql

\echo '[101] usp_inv_integracion.sql'
\i includes/sp/usp_inv_integracion.sql

\echo '[102] usp_mfg_integracion.sql'
\i includes/sp/usp_mfg_integracion.sql

\echo '[103] usp_sys_Lead_Upsert.sql'
\i includes/sp/usp_sys_Lead_Upsert.sql

\echo '[104] sp_vacation_request.sql'
\i includes/sp/sp_vacation_request.sql

\echo '[105] sp_emitir_compra_tx.sql'
\i includes/sp/sp_emitir_compra_tx.sql

\echo '[106] sp_emitir_cotizacion_tx.sql'
\i includes/sp/sp_emitir_cotizacion_tx.sql

\echo '[107] sp_emitir_pedido_tx.sql'
\i includes/sp/sp_emitir_pedido_tx.sql

\echo '[108] sp_emitir_presupuesto_tx.sql'
\i includes/sp/sp_emitir_presupuesto_tx.sql

\echo '[109] sp_anular_compra_tx.sql'
\i includes/sp/sp_anular_compra_tx.sql

\echo '[110] sp_anular_pedido_tx.sql'
\i includes/sp/sp_anular_pedido_tx.sql

\echo '[111] sp_anular_presupuesto_tx.sql'
\i includes/sp/sp_anular_presupuesto_tx.sql

\echo '[112] sp_restaurante_compra_xml.sql'
\i includes/sp/sp_restaurante_compra_xml.sql

\echo '[113] sp_crud_clientes.sql'
\i includes/sp/sp_crud_clientes.sql

\echo '[114] sp_CerrarMesInventario.sql'
\i includes/sp/sp_CerrarMesInventario.sql

\echo '[115] sp_MovUnidades.sql'
\i includes/sp/sp_MovUnidades.sql

\echo '[116] sp_MovUnidadesMes.sql'
\i includes/sp/sp_MovUnidadesMes.sql

\echo ''
\echo '============================================================'
\echo '  Todas las funciones recreadas'
\echo '============================================================'
\echo ''
