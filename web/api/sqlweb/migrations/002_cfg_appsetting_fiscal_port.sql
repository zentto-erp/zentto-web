-- ============================================================
-- 002_cfg_appsetting_fiscal_port.sql  (SQL Server)
-- Actualiza el puerto del agente fiscal de 5059 a 7654
-- ============================================================

UPDATE cfg.AppSetting
   SET SettingValue = 'http://localhost:7654'
 WHERE SettingKey = 'impresora.agentUrl'
   AND SettingValue LIKE '%5059%';
GO
