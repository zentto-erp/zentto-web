-- ============================================================
-- DatqBoxWeb PostgreSQL - 10_canonical_documents.sql
-- Limpieza de tablas legacy dbo.Documentos*,
-- creacion de sec."UserModuleAccess" y vista de compatibilidad
-- Fuente: 21_canonical_document_tables.sql
-- ============================================================

BEGIN;

-- ============================================================
-- SECCION 1: LIMPIEZA DE TABLAS public."Documentos*" LEGACY
-- En PG, si existen como tablas fisicas, se eliminan
-- (reemplazadas por doc.*)
-- ============================================================

-- Solo eliminar si existen como tablas (no vistas)
DROP TABLE IF EXISTS public."DocumentosVentaDetalle"  CASCADE;
DROP TABLE IF EXISTS public."DocumentosVentaPago"     CASCADE;
DROP TABLE IF EXISTS public."DocumentosVenta"         CASCADE;
DROP TABLE IF EXISTS public."DocumentosCompraDetalle" CASCADE;
DROP TABLE IF EXISTS public."DocumentosCompraPago"    CASCADE;
DROP TABLE IF EXISTS public."DocumentosCompra"        CASCADE;

-- ============================================================
-- SECCION 2: sec."UserModuleAccess" (permisos de modulos)
-- ============================================================

CREATE TABLE IF NOT EXISTS sec."UserModuleAccess" (
  "AccessId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "UserCode"    VARCHAR(20)  NOT NULL,
  "ModuleCode"  VARCHAR(60)  NOT NULL,
  "IsAllowed"   BOOLEAN      NOT NULL DEFAULT TRUE,
  "CreatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"   TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  CONSTRAINT "UQ_UserModuleAccess" UNIQUE ("UserCode", "ModuleCode")
);

-- ============================================================
-- Migrar datos de public."AccesoUsuarios" (tabla) -> sec."UserModuleAccess"
-- Solo si public."AccesoUsuarios" existe como tabla
-- ============================================================
DO $$
BEGIN
  -- Verificar si "AccesoUsuarios" existe como tabla (no vista)
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'AccesoUsuarios'
      AND table_type = 'BASE TABLE'
  ) THEN
    INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed", "CreatedAt", "UpdatedAt")
    SELECT "Cod_Usuario", "Modulo", "Permitido", (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    FROM public."AccesoUsuarios" a
    WHERE NOT EXISTS (
      SELECT 1 FROM sec."UserModuleAccess" m
      WHERE m."UserCode" = a."Cod_Usuario" AND m."ModuleCode" = a."Modulo"
    );

    DROP TABLE public."AccesoUsuarios";
  END IF;
END $$;

-- ============================================================
-- Vista de compatibilidad: public."AccesoUsuarios" -> sec."UserModuleAccess"
-- ============================================================
CREATE OR REPLACE VIEW public."AccesoUsuarios" AS
  SELECT
    "UserCode"   AS "Cod_Usuario",
    "ModuleCode" AS "Modulo",
    "IsAllowed"  AS "Permitido",
    "CreatedAt",
    "UpdatedAt"
  FROM sec."UserModuleAccess";

COMMIT;
