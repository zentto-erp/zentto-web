-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_MovUnidades.sql
-- Rellena MovInventMes desde MovInvent para un periodo.
-- Clasifica cada movimiento en Entradas, Salidas, Autoconsumo, Retiros.
-- Para el reporte "Libro Auxiliar de Entradas y Salidas" (Art. 177 LISR / SENIAT).
-- ============================================================

-- =============================================
-- Inventario inicial del mes = cierre del mes anterior (tabla CierreMensualInventario).
-- Si no hay cierre guardado, se usa el ultimo movimiento en MovInvent antes del periodo
-- y, si hace falta, Inventario (integridad).
-- Uso: SELECT * FROM public.sp_MovUnidades('02/2026');
-- =============================================

DROP FUNCTION IF EXISTS public.sp_MovUnidades(VARCHAR, DATE, DATE, BOOLEAN);

CREATE OR REPLACE FUNCTION public.sp_MovUnidades(
    p_periodo        VARCHAR(10)  DEFAULT NULL,   -- Formato MM/YYYY (ej. 01/2024)
    p_fecha_desde    DATE         DEFAULT NULL,
    p_fecha_hasta    DATE         DEFAULT NULL,
    p_solo_estructura BOOLEAN     DEFAULT FALSE   -- TRUE = solo crea/limpia, no recalcula
)
RETURNS TABLE(
    "FilasInsertadas" INT,
    "Periodo"         VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ini            DATE;
    v_fin            DATE;
    v_ini_dt         TIMESTAMP;
    v_fin_dt         TIMESTAMP;
    v_periodo        VARCHAR(10);
    v_mes            INT;
    v_anio           INT;
    v_inv_inicial    DOUBLE PRECISION;
    v_filas          INT;
BEGIN
    v_periodo := p_periodo;

    IF p_periodo IS NOT NULL THEN
        v_mes    := CAST(LEFT(p_periodo, 2) AS INT);
        v_anio   := CAST(RIGHT(p_periodo, 4) AS INT);
        v_ini    := make_date(v_anio, v_mes, 1);
        v_fin    := (v_ini + INTERVAL '1 month - 1 day')::DATE;
        v_ini_dt := v_ini::TIMESTAMP;
        v_fin_dt := (v_fin + INTERVAL '1 day')::TIMESTAMP;
    ELSIF p_fecha_desde IS NOT NULL AND p_fecha_hasta IS NOT NULL THEN
        v_ini     := p_fecha_desde;
        v_fin     := p_fecha_hasta;
        v_periodo := TO_CHAR(v_ini, 'MM/YYYY');
        v_ini_dt  := v_ini::TIMESTAMP;
        v_fin_dt  := (v_fin + INTERVAL '1 day')::TIMESTAMP;
    ELSE
        RAISE EXCEPTION 'Especificar p_periodo (MM/YYYY) o p_fecha_desde y p_fecha_hasta.';
    END IF;

    -- Eliminar datos del periodo en MovInventMes para refrescar
    DELETE FROM public."MovInventMes" WHERE "Periodo" = v_periodo;

    IF p_solo_estructura THEN
        RETURN QUERY SELECT 0, v_periodo;
        RETURN;
    END IF;

    -- Clasificacion: 1=Entradas, 2=Salidas, 3=AutoConsumo, 4=Retiros
    WITH "MovClasificado" AS (
        SELECT
            m."Fecha"::DATE                      AS "FechaDia",
            COALESCE(m."Codigo", m."Product")    AS "Codigo",
            m."Cantidad",
            COALESCE(m."Precio_Compra", 0)       AS "CostoUnit",
            m."Cantidad" * COALESCE(m."Precio_Compra", 0) AS "Monto",
            CASE
                WHEN UPPER(TRIM(COALESCE(m."Tipo",''::VARCHAR))) = 'INGRESO' THEN 1
                WHEN UPPER(TRIM(COALESCE(m."Tipo",''::VARCHAR))) = 'EGRESO' THEN
                    CASE
                        WHEN m."Motivo" ILIKE '%Autoconsumo%' THEN 3
                        WHEN m."Motivo" ILIKE '%FACT%'
                             OR m."Motivo" ILIKE '%Doc:%'
                             OR m."Motivo" ILIKE '%PEDIDO%'
                             OR m."Motivo" ILIKE '%NOTA_ENTREGA%'
                             OR m."Motivo" ILIKE '%Presup%'
                             OR m."Motivo" ILIKE '%Factura%'
                             OR m."Motivo" ILIKE '%Pedido%' THEN 2
                        ELSE 4
                    END
                WHEN UPPER(TRIM(COALESCE(m."Tipo",''::VARCHAR))) LIKE '%ANULACION%INGRESO%' THEN 1
                WHEN UPPER(TRIM(COALESCE(m."Tipo",''::VARCHAR))) LIKE '%ANULACION%EGRESO%' THEN 1
                ELSE 4
            END AS "Clase"
        FROM public."MovInvent" m
        WHERE m."Fecha" >= v_ini_dt AND m."Fecha" < v_fin_dt
          AND COALESCE(m."Anulada", 0) = 0
          AND (
              (m."Codigo" IS NOT NULL AND TRIM(m."Codigo") <> '')
              OR (m."Product" IS NOT NULL AND TRIM(m."Product") <> '')
          )
    ),
    "AgregadoDia" AS (
        SELECT
            "FechaDia",
            "Codigo",
            SUM(CASE WHEN "Clase" = 1 THEN "Cantidad" ELSE 0 END) AS "EntradasCant",
            SUM(CASE WHEN "Clase" = 1 THEN "Monto"    ELSE 0 END) AS "EntradasMonto",
            SUM(CASE WHEN "Clase" = 2 THEN "Cantidad" ELSE 0 END) AS "SalidasCant",
            SUM(CASE WHEN "Clase" = 2 THEN "Monto"    ELSE 0 END) AS "SalidasMonto",
            SUM(CASE WHEN "Clase" = 3 THEN "Cantidad" ELSE 0 END) AS "AutoConsumoCant",
            SUM(CASE WHEN "Clase" = 3 THEN "Monto"    ELSE 0 END) AS "AutoConsumoMonto",
            SUM(CASE WHEN "Clase" = 4 THEN "Cantidad" ELSE 0 END) AS "RetirosCant",
            SUM(CASE WHEN "Clase" = 4 THEN "Monto"    ELSE 0 END) AS "RetirosMonto"
        FROM "MovClasificado"
        GROUP BY "FechaDia", "Codigo"
    ),
    -- Inventario inicial: (1) CierreMensualInventario mes anterior (2) MovInvent ultimo antes del periodo (3) Inventario
    "PeriodoAnterior" AS (
        SELECT TO_CHAR(v_ini - INTERVAL '1 month', 'MM/YYYY') AS "Periodo"
    ),
    "InicialDesdeCierre" AS (
        SELECT c."Codigo", c."CantidadFinal" AS "InicialCant", c."CostoUnitario" AS "CostoUnit"
        FROM public."CierreMensualInventario" c
        INNER JOIN "PeriodoAnterior" p ON p."Periodo" = c."Periodo"
        WHERE c."CantidadFinal" <> 0
    ),
    "InicialMes" AS (
        SELECT
            COALESCE(m."Codigo", m."Product") AS "Codigo",
            m."cantidad_nueva"                AS "InicialCant",
            COALESCE(m."Precio_Compra", 0)    AS "CostoUnit",
            ROW_NUMBER() OVER (
                PARTITION BY COALESCE(m."Codigo", m."Product")
                ORDER BY m."Fecha" DESC, m."id" DESC
            ) AS rn
        FROM public."MovInvent" m
        WHERE m."Fecha" < v_ini_dt
          AND COALESCE(m."Anulada", 0) = 0
          AND (
              (m."Codigo" IS NOT NULL AND TRIM(m."Codigo") <> '')
              OR (m."Product" IS NOT NULL AND TRIM(m."Product") <> '')
          )
    ),
    "InicialDesdeMov" AS (
        SELECT "Codigo", "InicialCant", "CostoUnit"
        FROM "InicialMes"
        WHERE rn = 1 AND "InicialCant" <> 0
          AND NOT EXISTS (SELECT 1 FROM "InicialDesdeCierre" c WHERE c."Codigo" = "InicialMes"."Codigo")
    ),
    "InicialDesdeInventario" AS (
        SELECT
            i."ProductCode"                                       AS "Codigo",
            COALESCE(i."StockQty", 0)                             AS "InicialCant",
            COALESCE(i."COSTO_REFERENCIA", i."COSTO_PROMEDIO")    AS "CostoUnit"
        FROM master."Product" i
        WHERE COALESCE(i."IsDeleted", FALSE) = FALSE
          AND COALESCE(i."StockQty", 0) > 0
          AND i."ProductCode" IS NOT NULL AND TRIM(i."ProductCode") <> ''
          AND NOT EXISTS (SELECT 1 FROM "InicialDesdeCierre" c WHERE c."Codigo" = i."ProductCode")
          AND NOT EXISTS (SELECT 1 FROM "InicialDesdeMov" m2 WHERE m2."Codigo" = i."ProductCode")
    ),
    "InicialPorProducto" AS (
        SELECT "Codigo", "InicialCant", "CostoUnit" FROM "InicialDesdeCierre"
        UNION ALL
        SELECT "Codigo", "InicialCant", "CostoUnit" FROM "InicialDesdeMov"
        UNION ALL
        SELECT "Codigo", "InicialCant", "CostoUnit" FROM "InicialDesdeInventario"
    ),
    "DiasProducto" AS (
        SELECT "FechaDia", "Codigo" FROM "AgregadoDia"
        UNION
        SELECT v_ini, "Codigo" FROM "InicialPorProducto"
    ),
    "ConInicial" AS (
        SELECT
            d."FechaDia",
            d."Codigo",
            COALESCE(i."InicialCant", 0) AS "InicialCantMes",
            COALESCE(i."CostoUnit", 0)   AS "CostoInicial",
            a."EntradasCant", a."EntradasMonto", a."SalidasCant", a."SalidasMonto",
            a."AutoConsumoCant", a."AutoConsumoMonto", a."RetirosCant", a."RetirosMonto"
        FROM "DiasProducto" d
        LEFT JOIN "InicialPorProducto" i ON i."Codigo" = d."Codigo"
        LEFT JOIN "AgregadoDia" a ON a."FechaDia" = d."FechaDia" AND a."Codigo" = d."Codigo"
    ),
    "ConAcum" AS (
        SELECT
            "FechaDia", "Codigo", "InicialCantMes", "CostoInicial",
            "EntradasCant", "EntradasMonto", "SalidasCant", "SalidasMonto",
            "AutoConsumoCant", "AutoConsumoMonto", "RetirosCant", "RetirosMonto",
            SUM(
                COALESCE("EntradasCant", 0) - COALESCE("SalidasCant", 0)
                - COALESCE("AutoConsumoCant", 0) - COALESCE("RetirosCant", 0)
            ) OVER (PARTITION BY "Codigo" ORDER BY "FechaDia" ROWS UNBOUNDED PRECEDING) AS "Acumulado"
        FROM "ConInicial"
    ),
    "ConSaldo" AS (
        SELECT
            "FechaDia", "Codigo", "InicialCantMes", "CostoInicial",
            "EntradasCant", "EntradasMonto", "SalidasCant", "SalidasMonto",
            "AutoConsumoCant", "AutoConsumoMonto", "RetirosCant", "RetirosMonto",
            "InicialCantMes" + "Acumulado" - (
                COALESCE("EntradasCant", 0) - COALESCE("SalidasCant", 0)
                - COALESCE("AutoConsumoCant", 0) - COALESCE("RetirosCant", 0)
            ) AS "InicialDelDia",
            "InicialCantMes" + "Acumulado" AS "FinalDelDia"
        FROM "ConAcum"
    )
    INSERT INTO public."MovInventMes"
        ("Periodo", "Codigo", "Descripcion", "Costo", "Inicial", "Entradas", "Salidas",
         "AutoConsumo", "Retiros", "Inventario", "Final", "fecha")
    SELECT
        v_periodo,
        s."Codigo",
        COALESCE(inv."ProductName", s."Codigo"),
        COALESCE(s."CostoInicial", 0),
        s."InicialDelDia",
        COALESCE(s."EntradasCant", 0),
        COALESCE(s."SalidasCant", 0),
        COALESCE(s."AutoConsumoCant", 0),
        COALESCE(s."RetirosCant", 0),
        s."FinalDelDia" * COALESCE(s."CostoInicial", 0),
        s."FinalDelDia",
        s."FechaDia"
    FROM "ConSaldo" s
    LEFT JOIN master."Product" inv ON inv."ProductCode" = s."Codigo"
    WHERE COALESCE(inv."IsDeleted", FALSE) = FALSE OR inv."ProductCode" IS NULL;

    -- Fila resumen INVENTARIO INICIAL MES ANTERIOR
    SELECT SUM("Inicial" * "Costo") INTO v_inv_inicial
    FROM public."MovInventMes"
    WHERE "Periodo" = v_periodo AND "fecha" = v_ini AND "Codigo" <> '0000000001';

    INSERT INTO public."MovInventMes"
        ("Periodo", "Codigo", "Descripcion", "Costo", "Inicial", "Entradas", "Salidas",
         "AutoConsumo", "Retiros", "Inventario", "Final", "AjusteIncial", "AjusteFinal", "fecha")
    VALUES (
        v_periodo,
        '0000000001',
        'INVENTARIO INICIAL MES ANTERIOR',
        COALESCE(v_inv_inicial, 0),
        1,
        0, 0, 0, 0,
        COALESCE(v_inv_inicial, 0),
        1,
        NULL, NULL,
        v_ini
    );

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    RETURN QUERY SELECT v_filas, v_periodo;
END;
$$;
