-- =============================================
-- Tabla "CierreMensualInventario": guarda el cierre de cada mes por producto - PostgreSQL
-- El cierre de enero es el inventario inicial de febrero (y asi cada mes).
-- Traducido de SQL Server a PostgreSQL
-- =============================================

CREATE TABLE IF NOT EXISTS "CierreMensualInventario" (
    "Periodo"       VARCHAR(10) NOT NULL,     -- MM/YYYY (ej. 01/2026)
    "Codigo"        VARCHAR(60) NOT NULL,     -- Codigo del articulo
    "Descripcion"   VARCHAR(255),
    "CantidadFinal" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "MontoFinal"    DOUBLE PRECISION NOT NULL DEFAULT 0,
    "CostoUnitario" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "FechaCierre"   TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "PK_CierreMensualInventario" PRIMARY KEY ("Periodo", "Codigo")
);

CREATE INDEX IF NOT EXISTS "IX_CierreMensualInventario_Periodo"
    ON "CierreMensualInventario"("Periodo");
