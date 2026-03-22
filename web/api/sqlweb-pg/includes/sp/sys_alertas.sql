-- ============================================================
-- Funciones para alertas automáticas y notificaciones del sistema
-- Compatible con PostgreSQL
-- ============================================================

-- Insertar notificación
CREATE OR REPLACE FUNCTION usp_sys_notificacion_insert(
    p_tipo VARCHAR(20),
    p_titulo VARCHAR(100),
    p_mensaje VARCHAR(500),
    p_usuario_id VARCHAR(20) DEFAULT NULL,
    p_ruta_navegacion VARCHAR(200) DEFAULT NULL
)
RETURNS TABLE("Id" INT, "Mensaje" VARCHAR) LANGUAGE plpgsql AS $$
BEGIN
    -- Evitar duplicados recientes (misma alerta en últimas 4 horas)
    IF EXISTS (
        SELECT 1 FROM "Sys_Notificaciones"
        WHERE "Titulo" = p_titulo
          AND ("UsuarioId" = p_usuario_id OR ("UsuarioId" IS NULL AND p_usuario_id IS NULL))
          AND "Leido" = FALSE
          AND "FechaCreacion" > NOW() - INTERVAL '4 hours'
    ) THEN
        RETURN QUERY SELECT 0, 'duplicado_reciente'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY
    INSERT INTO "Sys_Notificaciones" ("Tipo", "Titulo", "Mensaje", "UsuarioId", "RutaNavegacion")
    VALUES (p_tipo, p_titulo, p_mensaje, p_usuario_id, p_ruta_navegacion)
    RETURNING "Sys_Notificaciones"."Id", 'ok'::VARCHAR;
END;
$$;

-- Alerta: Facturas vencidas (CxC)
CREATE OR REPLACE FUNCTION usp_sys_alert_facturasvencidas()
RETURNS TABLE("cantidad" BIGINT, "montoTotal" NUMERIC) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'ar' AND table_name = 'ReceivableDocument') THEN
        RETURN QUERY
        SELECT COUNT(*), COALESCE(SUM("PendingAmount"), 0)
        FROM ar."ReceivableDocument"
        WHERE "Status" IN ('PENDING', 'PARTIAL')
          AND "DueDate" < NOW()
          AND "IsVoided" = 0;
    ELSE
        RETURN QUERY SELECT 0::BIGINT, 0.00::NUMERIC;
    END IF;
END;
$$;

-- Alerta: Stock bajo
CREATE OR REPLACE FUNCTION usp_sys_alert_stockbajo()
RETURNS TABLE("cantidad" BIGINT) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'Articulos') THEN
        RETURN QUERY
        SELECT COUNT(*)
        FROM "Articulos"
        WHERE COALESCE("Existencia", 0) <= COALESCE("StockMinimo", 0)
          AND "StockMinimo" > 0
          AND COALESCE("Inactivo", 0) = 0;
    ELSE
        RETURN QUERY SELECT 0::BIGINT;
    END IF;
END;
$$;

-- Alerta: CxP por vencer (próximos 7 días)
CREATE OR REPLACE FUNCTION usp_sys_alert_cxpporvencer()
RETURNS TABLE("cantidad" BIGINT, "montoTotal" NUMERIC) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'ap' AND table_name = 'PayableDocument') THEN
        RETURN QUERY
        SELECT COUNT(*), COALESCE(SUM("PendingAmount"), 0)
        FROM ap."PayableDocument"
        WHERE "Status" IN ('PENDING', 'PARTIAL')
          AND "DueDate" BETWEEN NOW() AND NOW() + INTERVAL '7 days'
          AND "IsVoided" = 0;
    ELSE
        RETURN QUERY SELECT 0::BIGINT, 0.00::NUMERIC;
    END IF;
END;
$$;

-- Alerta: Conciliación bancaria pendiente
CREATE OR REPLACE FUNCTION usp_sys_alert_conciliacionpendiente()
RETURNS TABLE("cantidad" BIGINT) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'bank' AND table_name = 'BankAccount') THEN
        RETURN QUERY
        SELECT COUNT(*)
        FROM bank."BankAccount" ba
        WHERE ba."IsActive" = TRUE
          AND NOT EXISTS (
              SELECT 1 FROM bank."Reconciliation" r
              WHERE r."BankAccountId" = ba."BankAccountId"
                AND EXTRACT(MONTH FROM r."ClosedAt") = EXTRACT(MONTH FROM NOW())
                AND EXTRACT(YEAR FROM r."ClosedAt") = EXTRACT(YEAR FROM NOW())
                AND r."Status" = 'CERRADA'
          );
    ELSE
        RETURN QUERY SELECT 0::BIGINT;
    END IF;
END;
$$;

-- Alerta: Nómina sin procesar
CREATE OR REPLACE FUNCTION usp_sys_alert_nominapendiente()
RETURNS TABLE("pendiente" INT) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'hr' AND table_name = 'PayrollBatch') THEN
        IF NOT EXISTS (
            SELECT 1 FROM hr."PayrollBatch"
            WHERE EXTRACT(MONTH FROM "CreatedAt") = EXTRACT(MONTH FROM NOW())
              AND EXTRACT(YEAR FROM "CreatedAt") = EXTRACT(YEAR FROM NOW())
              AND "Status" IN ('PROCESADA', 'APROBADA')
        ) THEN
            RETURN QUERY SELECT 1;
        ELSE
            RETURN QUERY SELECT 0;
        END IF;
    ELSE
        RETURN QUERY SELECT 0;
    END IF;
END;
$$;

-- Alerta: Asientos en borrador
CREATE OR REPLACE FUNCTION usp_sys_alert_asientosborrador()
RETURNS TABLE("cantidad" BIGINT) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'acct' AND table_name = 'JournalEntry') THEN
        RETURN QUERY
        SELECT COUNT(*) FROM acct."JournalEntry" WHERE "Status" = 'DRAFT';
    ELSE
        RETURN QUERY SELECT 0::BIGINT;
    END IF;
END;
$$;

-- Alerta: Solicitudes de vacaciones pendientes
CREATE OR REPLACE FUNCTION usp_sys_alert_vacacionespendientes()
RETURNS TABLE("cantidad" BIGINT) LANGUAGE plpgsql AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'hr' AND table_name = 'VacationRequest') THEN
        RETURN QUERY
        SELECT COUNT(*) FROM hr."VacationRequest" WHERE "Status" = 'SOLICITADA';
    ELSE
        RETURN QUERY SELECT 0::BIGINT;
    END IF;
END;
$$;
