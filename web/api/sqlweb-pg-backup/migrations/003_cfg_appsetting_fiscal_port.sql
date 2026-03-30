-- ============================================================
-- 003_cfg_appsetting_fiscal_port.sql
-- Actualiza el puerto del agente fiscal de 5059 a 7654
-- en cfg."AppSetting" si existe el registro.
-- ============================================================

UPDATE cfg."AppSetting"
   SET "SettingValue" = 'http://localhost:7654'
 WHERE "SettingKey" = 'impresora.agentUrl'
   AND "SettingValue" LIKE '%5059%';
