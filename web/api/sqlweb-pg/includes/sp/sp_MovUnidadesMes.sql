-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_MovUnidadesMes.sql
-- Rellena MovInventMes para un mes (Libro Auxiliar Art. 177 LISR).
-- El inventario inicial del mes = cierre del mes anterior (CierreMensualInventario).
-- Si se indica p_cerrar_mes_anterior = TRUE, antes cierra el mes anterior.
-- ============================================================

-- =============================================
-- Uso: SELECT * FROM public.sp_MovUnidadesMes('02/2026', TRUE);
--      SELECT * FROM public.sp_MovUnidadesMes('01/2026');
-- =============================================

DROP FUNCTION IF EXISTS public.sp_MovUnidadesMes(VARCHAR, BOOLEAN, BOOLEAN);

CREATE OR REPLACE FUNCTION public.sp_MovUnidadesMes(
    p_periodo             VARCHAR(10),       -- MM/YYYY (ej. 02/2026)
    p_cerrar_mes_anterior BOOLEAN DEFAULT TRUE,
    p_refrescar_siguiente BOOLEAN DEFAULT FALSE
)
RETURNS TABLE(
    "FilasInsertadas" INT,
    "Periodo"         VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_mes           INT;
    v_anio          INT;
    v_prev_date     DATE;
    v_prev_periodo  VARCHAR(10);
    v_next_periodo  VARCHAR(10);
    v_result        RECORD;
BEGIN
    IF p_periodo IS NULL OR TRIM(p_periodo) = '' THEN
        RAISE EXCEPTION 'p_periodo es requerido (formato MM/YYYY).';
    END IF;

    v_mes  := CAST(LEFT(p_periodo, 2) AS INT);
    v_anio := CAST(RIGHT(p_periodo, 4) AS INT);

    -- Cerrar mes anterior si se solicita
    IF p_cerrar_mes_anterior THEN
        v_prev_date   := make_date(v_anio, v_mes, 1) - INTERVAL '1 month';
        v_prev_periodo := TO_CHAR(v_prev_date, 'MM/YYYY');

        PERFORM public.sp_CerrarMesInventario(v_prev_periodo);
    END IF;

    -- Ejecutar sp_MovUnidades para el periodo solicitado
    RETURN QUERY SELECT * FROM public.sp_MovUnidades(p_periodo);

    -- Refrescar el mes siguiente si se solicita
    IF p_refrescar_siguiente THEN
        v_next_periodo := TO_CHAR(make_date(v_anio, v_mes, 1) + INTERVAL '1 month', 'MM/YYYY');

        PERFORM public.sp_MovUnidades(v_next_periodo);
    END IF;
END;
$$;
