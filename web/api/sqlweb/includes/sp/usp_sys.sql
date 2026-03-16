/*
 * ============================================================================
 *  Archivo : usp_sys.sql
 *  Esquema : sys (procedimientos de sistema)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-14
 *
 *  Descripcion:
 *    Procedimientos almacenados de diagnostico y utilidades del sistema.
 *    - usp_Sys_HealthCheck       : Verificacion rapida de salud del servidor.
 *    - usp_Sys_GetTableColumns   : Devuelve columnas de una tabla dada.
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Sys_HealthCheck
--  Descripcion : Devuelve un registro con estado OK, hora del servidor y nombre
--                de la base de datos. Util para monitoreo y health-checks de la API.
--  Parametros  : Ninguno.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sys_HealthCheck
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        1            AS ok,
        SYSUTCDATETIME()    AS serverTime,
        DB_NAME()    AS dbName;
END;
GO

-- =============================================================================
--  SP 2: usp_Sys_GetTableColumns
--  Descripcion : Devuelve la lista de columnas de una tabla especificada,
--                consultando INFORMATION_SCHEMA.COLUMNS.
--  Parametros  :
--    @SchemaName  NVARCHAR(20)  - Esquema de la tabla (ej. 'dbo', 'cfg').
--    @TableName   NVARCHAR(128) - Nombre de la tabla.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_Sys_GetTableColumns
    @SchemaName  NVARCHAR(20),
    @TableName   NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COLUMN_NAME
    FROM   INFORMATION_SCHEMA.COLUMNS
    WHERE  TABLE_SCHEMA = @SchemaName
      AND  TABLE_NAME   = @TableName
    ORDER BY ORDINAL_POSITION;
END;
GO
