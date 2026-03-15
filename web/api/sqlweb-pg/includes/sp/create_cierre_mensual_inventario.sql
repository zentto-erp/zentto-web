-- ============================================================
-- DatqBoxWeb PostgreSQL - create_cierre_mensual_inventario.sql
-- Tabla CierreMensualInventario: guarda el cierre de cada mes
-- por producto. El cierre de enero es el inventario inicial
-- de febrero (y asi cada mes).
-- ============================================================

CREATE TABLE IF NOT EXISTS public."CierreMensualInventario" (
    "Periodo"       VARCHAR(10) NOT NULL,
    "Codigo"        VARCHAR(60) NOT NULL,
    "Descripcion"   VARCHAR(255) NULL,
    "CantidadFinal" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "MontoFinal"    DOUBLE PRECISION NOT NULL DEFAULT 0,
    "CostoUnitario" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "FechaCierre"   TIMESTAMP NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_CierreMensualInventario" PRIMARY KEY ("Periodo", "Codigo")
);

CREATE INDEX IF NOT EXISTS "IX_CierreMensualInventario_Periodo"
    ON public."CierreMensualInventario" ("Periodo");
