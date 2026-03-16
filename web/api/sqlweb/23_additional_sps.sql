SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

USE DatqBoxWeb;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/*
  SPs adicionales requeridos por API: CRUD faltantes, documentos,
  CxC/CxP canonicos, inventario cierre, POS/restaurante, gobernanza.
*/

-- CRUD maestros faltantes
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_bancos.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_feriados.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_moneda.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_crud_vehiculos.sql

-- Documentos: emitir/anular standalone
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_factura_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_anular_factura_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_pedido_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_anular_pedido_tx.sql

-- Documentos unificados
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_documento_venta_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_emitir_documento_compra_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_anular_documento_venta_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_anular_documento_compra_tx.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_documentos_venta_list.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_documentos_compra_list.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_documentos_unificado_tx.sql

-- CxC / CxP canonicos (v2)
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_cxc_aplicar_cobro_v2.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_cxp_aplicar_pago_v2.sql

-- Bancos
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_bancos_conciliacion.sql

-- Inventario cierre mensual
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_CerrarMesInventario.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_MovUnidades.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_MovUnidadesMes.sql

-- POS y restaurante
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_pos_restaurante.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_pos_ventas_espera.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_restaurante_admin.sql
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sp_restaurante_compra_xml.sql

-- Notificaciones
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\sys_notificaciones.sql

-- Gobernanza (usp_Governance_CaptureSnapshot)
:r D:\DatqBoxWorkspace\DatqBoxWeb\web\api\sqlweb\includes\sp\00_governance_baseline.sql
GO
