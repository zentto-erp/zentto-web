-- ============================================================
-- sys_notificaciones.sql
-- Tablas y funciones para notificaciones, tareas y mensajes del sistema
-- Tablas: public."Sys_Notificaciones", public."Sys_Tareas", public."Sys_Mensajes"
-- Funciones SP: usp_Sys_Notificacion_List/MarkRead, usp_Sys_Tarea_List/Toggle,
--               usp_Sys_Mensaje_List/MarkRead
-- ============================================================

-- Tables (idempotent)
CREATE TABLE IF NOT EXISTS public."Sys_Notificaciones" (
    "Id"             SERIAL PRIMARY KEY,
    "Tipo"           VARCHAR(30) NOT NULL DEFAULT 'INFO',
    "Titulo"         VARCHAR(200) NOT NULL,
    "Mensaje"        TEXT,
    "Leido"          BOOLEAN NOT NULL DEFAULT FALSE,
    "UsuarioId"      VARCHAR(50) NULL,
    "FechaCreacion"  TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "RutaNavegacion" VARCHAR(500) NULL
);

CREATE TABLE IF NOT EXISTS public."Sys_Tareas" (
    "Id"               SERIAL PRIMARY KEY,
    "Titulo"           VARCHAR(200) NOT NULL,
    "Descripcion"      TEXT NULL,
    "Progreso"         INT NOT NULL DEFAULT 0,
    "Color"            VARCHAR(30) NULL DEFAULT 'blue',
    "AsignadoA"        VARCHAR(50) NULL,
    "FechaVencimiento" DATE NULL,
    "Completado"       BOOLEAN NOT NULL DEFAULT FALSE,
    "FechaCreacion"    TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE TABLE IF NOT EXISTS public."Sys_Mensajes" (
    "Id"              SERIAL PRIMARY KEY,
    "RemitenteId"     VARCHAR(50) NOT NULL,
    "RemitenteNombre" VARCHAR(150) NOT NULL,
    "DestinatarioId"  VARCHAR(50) NOT NULL,
    "Asunto"          VARCHAR(200) NOT NULL,
    "Cuerpo"          TEXT NULL,
    "Leido"           BOOLEAN NOT NULL DEFAULT FALSE,
    "FechaEnvio"      TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

-- usp_Sys_Notificacion_List
DROP FUNCTION IF EXISTS usp_sys_notificacion_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_notificacion_list(
    p_usuario_id VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Id"             INTEGER,
    "Tipo"           VARCHAR,
    "Titulo"         VARCHAR,
    "Mensaje"        TEXT,
    "Leido"          BOOLEAN,
    "FechaCreacion"  TIMESTAMP,
    "RutaNavegacion" VARCHAR
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT n."Id", n."Tipo", n."Titulo", n."Mensaje",
           n."Leido", n."FechaCreacion", n."RutaNavegacion"
    FROM "Sys_Notificaciones" n
    WHERE n."UsuarioId" IS NULL OR n."UsuarioId" = p_usuario_id
    ORDER BY n."FechaCreacion" DESC
    LIMIT 50;
END;
$$;

-- usp_Sys_Notificacion_MarkRead
DROP FUNCTION IF EXISTS usp_sys_notificacion_markread(text) CASCADE;
DROP FUNCTION IF EXISTS usp_sys_notificacion_markread(character varying) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_notificacion_markread(
    p_ids_csv VARCHAR
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "Sys_Notificaciones"
    SET "Leido" = TRUE
    WHERE "Id" = ANY(
        SELECT UNNEST(string_to_array(p_ids_csv, ','))::INT
    );
END;
$$;

-- usp_Sys_Tarea_List
DROP FUNCTION IF EXISTS usp_sys_tarea_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_tarea_list(
    p_asignado_a VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Id"               INTEGER,
    "Titulo"           VARCHAR,
    "Descripcion"      TEXT,
    "Progreso"         INTEGER,
    "Color"            VARCHAR,
    "AsignadoA"        VARCHAR,
    "FechaVencimiento" DATE,
    "Completado"       BOOLEAN,
    "FechaCreacion"    TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT t."Id", t."Titulo", t."Descripcion", t."Progreso",
           t."Color", t."AsignadoA", t."FechaVencimiento",
           t."Completado", t."FechaCreacion"
    FROM "Sys_Tareas" t
    WHERE (t."AsignadoA" IS NULL OR t."AsignadoA" = p_asignado_a)
      AND t."Completado" = FALSE
    ORDER BY t."FechaCreacion" DESC
    LIMIT 50;
END;
$$;

-- usp_Sys_Tarea_Toggle
DROP FUNCTION IF EXISTS usp_sys_tarea_toggle(integer, boolean, integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_tarea_toggle(
    p_id        INT,
    p_completado BOOLEAN,
    p_progress  INT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "Sys_Tareas"
    SET "Completado" = p_completado,
        "Progreso"   = p_progress
    WHERE "Id" = p_id;
END;
$$;

-- usp_Sys_Mensaje_List
-- NOTE: "Cuerpo" column is TEXT in public."Sys_Mensajes", return type must match
DROP FUNCTION IF EXISTS usp_sys_mensaje_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_mensaje_list(
    p_destinatario_id VARCHAR
)
RETURNS TABLE (
    "Id"              INTEGER,
    "RemitenteId"     VARCHAR,
    "RemitenteNombre" VARCHAR,
    "Asunto"          VARCHAR,
    "Cuerpo"          TEXT,
    "Leido"           BOOLEAN,
    "FechaEnvio"      TIMESTAMP
) LANGUAGE plpgsql AS $$
BEGIN
    RETURN QUERY
    SELECT m."Id", m."RemitenteId", m."RemitenteNombre",
           m."Asunto", m."Cuerpo", m."Leido", m."FechaEnvio"
    FROM "Sys_Mensajes" m
    WHERE m."DestinatarioId" = p_destinatario_id
    ORDER BY m."FechaEnvio" DESC
    LIMIT 50;
END;
$$;

-- usp_Sys_Mensaje_MarkRead
DROP FUNCTION IF EXISTS usp_sys_mensaje_markread(integer) CASCADE;
CREATE OR REPLACE FUNCTION usp_sys_mensaje_markread(
    p_id INT
)
RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    UPDATE "Sys_Mensajes"
    SET "Leido" = TRUE
    WHERE "Id" = p_id;
END;
$$;
