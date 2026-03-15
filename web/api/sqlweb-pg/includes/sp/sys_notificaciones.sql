-- ============================================================
-- DatqBoxWeb PostgreSQL - sys_notificaciones.sql
-- Tablas para notificaciones, tareas y mensajes del sistema.
-- ============================================================

-- Tabla: Sys_Notificaciones
CREATE TABLE IF NOT EXISTS public."Sys_Notificaciones" (
    "Id"              SERIAL PRIMARY KEY,
    "Tipo"            VARCHAR(20)  NOT NULL,    -- info, success, warning, error
    "Titulo"          VARCHAR(100) NOT NULL,
    "Mensaje"         VARCHAR(500) NOT NULL,
    "Leido"           BOOLEAN      NOT NULL DEFAULT FALSE,
    "UsuarioId"       VARCHAR(20)  NULL,        -- Si es null es global
    "FechaCreacion"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "RutaNavegacion"  VARCHAR(200) NULL
);

-- Tabla: Sys_Tareas
CREATE TABLE IF NOT EXISTS public."Sys_Tareas" (
    "Id"                SERIAL PRIMARY KEY,
    "Titulo"            VARCHAR(100) NOT NULL,
    "Descripcion"       VARCHAR(500) NULL,
    "Progreso"          INT          NOT NULL DEFAULT 0,    -- 0 al 100
    "Color"             VARCHAR(20)  NOT NULL DEFAULT 'primary',  -- primary, secondary, error, info, success, warning
    "AsignadoA"         VARCHAR(20)  NULL,
    "FechaVencimiento"  TIMESTAMP    NULL,
    "Completado"        BOOLEAN      NOT NULL DEFAULT FALSE,
    "FechaCreacion"     TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- Tabla: Sys_Mensajes
CREATE TABLE IF NOT EXISTS public."Sys_Mensajes" (
    "Id"                SERIAL PRIMARY KEY,
    "RemitenteId"       VARCHAR(20)  NOT NULL,
    "RemitenteNombre"   VARCHAR(100) NOT NULL,
    "DestinatarioId"    VARCHAR(20)  NOT NULL,
    "Asunto"            VARCHAR(100) NOT NULL,
    "Cuerpo"            TEXT         NOT NULL,
    "Leido"             BOOLEAN      NOT NULL DEFAULT FALSE,
    "FechaEnvio"        TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);
