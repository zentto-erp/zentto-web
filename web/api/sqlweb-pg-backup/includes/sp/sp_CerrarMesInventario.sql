-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_CerrarMesInventario.sql
-- Calcula y guarda el cierre de inventario de un mes.
-- Ese cierre serÃ¡ el inventario inicial del mes siguiente.
-- ============================================================

-- =============================================
-- sp_CerrarMesInventario: calcula y guarda el cierre de inventario de un mes.
-- Fuente: MovInvent (que se llena con cada operaciÃ³n de venta/compra/ajuste).
-- Ejecutar al cierre del mes: SELECT * FROM public.sp_CerrarMesInventario('01/2026');
-- =============================================

DROP FUNCTION IF EXISTS public.sp_CerrarMesInventario(VARCHAR);

CREATE OR REPLACE FUNCTION public.sp_CerrarMesInventario(
    p_periodo VARCHAR(10)   -- MM/YYYY (ej. 01/2026)
)
RETURNS TABLE(
    "ProductosCerrados" INT,
    "Periodo"           VARCHAR,
    "FechaCierre"       DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_mes        INT;
    v_anio       INT;
    v_fin        DATE;
    v_fin_dt     TIMESTAMP;
    v_filas      INT;
BEGIN
    v_mes  := CAST(LEFT(p_periodo, 2) AS INT);
    v_anio := CAST(RIGHT(p_periodo, 4) AS INT);
    v_fin  := (make_date(v_anio, v_mes, 1) + INTERVAL '1 month - 1 day')::DATE;
    v_fin_dt := (v_fin + INTERVAL '1 day')::TIMESTAMP;

    -- Verificar que exista la tabla CierreMensualInventario
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'cierremensualinventario'
    ) THEN
        RAISE EXCEPTION 'Crear antes la tabla CierreMensualInventario (create_cierre_mensual_inventario.sql).';
    END IF;

    -- Eliminar datos previos del periodo
    DELETE FROM public."CierreMensualInventario" WHERE "Periodo" = p_periodo;

    -- Ultimo movimiento por producto hasta v_fin
    WITH "UltimoMov" AS (
        SELECT
            COALESCE(m."Codigo", m."Product") AS "Codigo",
            m."cantidad_nueva"                AS "CantidadFinal",
            COALESCE(m."Precio_Compra", 0)    AS "CostoUnitario",
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(m."Codigo", m."Product")
                ORDER BY m."Fecha" DESC, m."id" DESC
            ) AS rn
        FROM public."MovInvent" m
        WHERE m."Fecha" < v_fin_dt
          AND COALESCE(m."Anulada", 0) = 0
          AND (
              (m."Codigo" IS NOT NULL AND TRIM(m."Codigo") <> '')
              OR (m."Product" IS NOT NULL AND TRIM(m."Product") <> '')
          )
    )
    INSERT INTO public."CierreMensualInventario"
        ("Periodo", "Codigo", "Descripcion", "CantidadFinal", "MontoFinal", "CostoUnitario", "FechaCierre")
    SELECT
        p_periodo,
        u."Codigo",
        i."DESCRIPCION",
        u."CantidadFinal",
        u."CantidadFinal" * u."CostoUnitario",
        u."CostoUnitario",
        NOW() AT TIME ZONE 'UTC'
    FROM "UltimoMov" u
    LEFT JOIN public."Inventario" i ON i."CODIGO" = u."Codigo"
    WHERE u.rn = 1 AND u."CantidadFinal" <> 0;

    -- Productos con existencia en Inventario sin movimiento hasta v_fin
    INSERT INTO public."CierreMensualInventario"
        ("Periodo", "Codigo", "Descripcion", "CantidadFinal", "MontoFinal", "CostoUnitario", "FechaCierre")
    SELECT
        p_periodo,
        i."CODIGO",
        i."DESCRIPCION",
        COALESCE(i."EXISTENCIA", 0),
        COALESCE(i."EXISTENCIA", 0) * COALESCE(i."COSTO_REFERENCIA", i."COSTO_PROMEDIO"),
        COALESCE(i."COSTO_REFERENCIA", i."COSTO_PROMEDIO"),
        NOW() AT TIME ZONE 'UTC'
    FROM public."Inventario" i
    WHERE COALESCE(i."EXISTENCIA", 0) > 0
      AND i."CODIGO" IS NOT NULL AND TRIM(i."CODIGO") <> ''
      AND NOT EXISTS (
          SELECT 1 FROM public."CierreMensualInventario" c
          WHERE c."Periodo" = p_periodo AND c."Codigo" = i."CODIGO"
      );

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    RETURN QUERY SELECT v_filas, p_periodo, v_fin;
END;
$$;
