-- +goose Up
-- Paridad dual-DB: renombrar columnas de manufactura para que
-- SQL Server y PostgreSQL usen nombres identicos.

-- 1. BillOfMaterials: OutputQuantity ya es el nombre correcto en PG (nada que cambiar)

-- 2. BOMLine: WastePercent ya es el nombre correcto en PG (nada que cambiar)

-- 3. Routing: SetupTimeMinutes / RunTimeMinutes ya son correctos en PG (nada que cambiar)

-- 4. Routing: Notes ya es el nombre correcto en PG (nada que cambiar)

-- Las columnas de PG ya tenian los nombres correctos. Esta migracion
-- solo documenta que se unificaron los nombres en SQL Server para
-- que coincidan con PostgreSQL.

-- Recrear funciones con parametros actualizados
-- (ya reflejado en usp_mfg.sql — se aplica via run_all o re-deploy de SPs)

SELECT 1;

-- +goose Down
SELECT 1;
