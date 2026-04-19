-- +goose Up
-- PR3: Reserva atómica de stock — elimina oversell en ecommerce/POS/comandas
-- Usa pg_advisory_xact_lock para garantizar atomicidad sin deadlocks.

-- =============================================================================
-- 1. Tabla inv.StockReservation
-- =============================================================================
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS inv."StockReservation" (
    "ReservationId"   BIGSERIAL     PRIMARY KEY,
    "CompanyId"       INTEGER       NOT NULL,
    "ProductCode"     VARCHAR(80)   NOT NULL,
    "Quantity"        NUMERIC(18,4) NOT NULL CHECK ("Quantity" > 0),
    "ReferenceType"   VARCHAR(30)   NOT NULL,   -- CART, POS_TICKET, RESERVATION, ORDER
    "ReferenceId"     VARCHAR(60),              -- cart_id, ticket_id, session_id, order_id
    "ExpiresAt"       TIMESTAMP     NOT NULL,   -- UTC
    "IsCommitted"     BOOLEAN       DEFAULT FALSE NOT NULL,
    "IsReleased"      BOOLEAN       DEFAULT FALSE NOT NULL,
    "CommittedAt"     TIMESTAMP,
    "ReleasedAt"      TIMESTAMP,
    "CreatedByUserId" INTEGER,
    "CreatedAt"       TIMESTAMP     DEFAULT (NOW() AT TIME ZONE 'UTC') NOT NULL,
    CONSTRAINT "UQ_inv_StockReservation_Ref"
        UNIQUE ("CompanyId", "ReferenceType", "ReferenceId", "ProductCode")
);
-- +goose StatementEnd

-- +goose StatementBegin
CREATE INDEX IF NOT EXISTS "ix_inv_StockReservation_active"
    ON inv."StockReservation" ("CompanyId", "ProductCode")
    WHERE "IsCommitted" = FALSE AND "IsReleased" = FALSE;

CREATE INDEX IF NOT EXISTS "ix_inv_StockReservation_expiry"
    ON inv."StockReservation" ("ExpiresAt")
    WHERE "IsCommitted" = FALSE AND "IsReleased" = FALSE;
-- +goose StatementEnd

-- =============================================================================
-- 2. Función: stock disponible (considera reservas activas no vencidas)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_stock_available(
    p_company_id   INTEGER,
    p_product_code VARCHAR
) RETURNS TABLE(
    "ProductCode"        VARCHAR,
    "StockQty"           NUMERIC,
    "StockQtyReserved"   NUMERIC,
    "StockQtyAvailable"  NUMERIC
) LANGUAGE plpgsql AS $$
DECLARE
    v_stock_qty     NUMERIC := 0;
    v_reserved_qty  NUMERIC := 0;
BEGIN
    SELECT COALESCE("StockQty", 0) INTO v_stock_qty
    FROM master."Product"
    WHERE "ProductCode" = p_product_code
      AND "CompanyId"   = p_company_id
    LIMIT 1;

    SELECT COALESCE(SUM(r."Quantity"), 0) INTO v_reserved_qty
    FROM inv."StockReservation" r
    WHERE r."CompanyId"    = p_company_id
      AND r."ProductCode"  = p_product_code
      AND r."IsCommitted"  = FALSE
      AND r."IsReleased"   = FALSE
      AND r."ExpiresAt"    > (NOW() AT TIME ZONE 'UTC');

    RETURN QUERY SELECT
        p_product_code::VARCHAR,
        v_stock_qty,
        v_reserved_qty,
        GREATEST(v_stock_qty - v_reserved_qty, 0);
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 3. Función: reservar stock de forma atómica
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_stock_reserve(
    p_company_id      INTEGER,
    p_product_code    VARCHAR,
    p_quantity        NUMERIC,
    p_reference_type  VARCHAR(30),
    p_reference_id    VARCHAR(60),
    p_ttl_minutes     INTEGER  DEFAULT 30,
    p_user_id         INTEGER  DEFAULT NULL
) RETURNS TABLE(
    "ok"            BOOLEAN,
    "ReservationId" BIGINT,
    "mensaje"       VARCHAR,
    "Disponible"    NUMERIC
) LANGUAGE plpgsql AS $$
DECLARE
    v_product_id   BIGINT;
    v_stock_qty    NUMERIC := 0;
    v_reserved_qty NUMERIC := 0;
    v_available    NUMERIC;
    v_resv_id      BIGINT;
    v_lock_key     BIGINT;
    v_expires_at   TIMESTAMP;
BEGIN
    -- Hash del product_code para advisory lock (evita deadlocks)
    v_lock_key := ('x' || SUBSTR(MD5(p_company_id::TEXT || '_' || p_product_code), 1, 16))::BIT(64)::BIGINT;
    PERFORM pg_advisory_xact_lock(v_lock_key);

    -- Verificar que el producto existe
    SELECT "ProductId", COALESCE("StockQty", 0)
    INTO v_product_id, v_stock_qty
    FROM master."Product"
    WHERE "ProductCode" = p_product_code
      AND "CompanyId"   = p_company_id
    LIMIT 1;

    IF v_product_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 0::BIGINT, 'Producto no encontrado'::VARCHAR, 0::NUMERIC;
        RETURN;
    END IF;

    -- Sumar reservas activas no vencidas
    SELECT COALESCE(SUM(r."Quantity"), 0) INTO v_reserved_qty
    FROM inv."StockReservation" r
    WHERE r."CompanyId"    = p_company_id
      AND r."ProductCode"  = p_product_code
      AND r."IsCommitted"  = FALSE
      AND r."IsReleased"   = FALSE
      AND r."ExpiresAt"    > (NOW() AT TIME ZONE 'UTC');

    v_available := GREATEST(v_stock_qty - v_reserved_qty, 0);

    IF v_available < p_quantity THEN
        RETURN QUERY SELECT
            FALSE,
            0::BIGINT,
            ('Stock insuficiente. Disponible: ' || v_available::TEXT)::VARCHAR,
            v_available;
        RETURN;
    END IF;

    v_expires_at := (NOW() AT TIME ZONE 'UTC') + (p_ttl_minutes || ' minutes')::INTERVAL;

    -- Insertar o actualizar reserva (idempotente por UQ constraint)
    INSERT INTO inv."StockReservation" (
        "CompanyId", "ProductCode", "Quantity",
        "ReferenceType", "ReferenceId", "ExpiresAt", "CreatedByUserId"
    ) VALUES (
        p_company_id, p_product_code, p_quantity,
        p_reference_type, p_reference_id, v_expires_at, p_user_id
    )
    ON CONFLICT ("CompanyId", "ReferenceType", "ReferenceId", "ProductCode")
    DO UPDATE SET
        "Quantity"    = p_quantity,
        "ExpiresAt"   = v_expires_at,
        "IsReleased"  = FALSE,
        "IsCommitted" = FALSE,
        "ReleasedAt"  = NULL
    RETURNING "ReservationId" INTO v_resv_id;

    RETURN QUERY SELECT
        TRUE,
        v_resv_id,
        'Reserva creada'::VARCHAR,
        v_available - p_quantity;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 4. Función: liberar reserva
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_stock_release(
    p_reservation_id BIGINT,
    p_company_id     INTEGER
) RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE inv."StockReservation"
    SET "IsReleased" = TRUE,
        "ReleasedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "ReservationId" = p_reservation_id
      AND "CompanyId"     = p_company_id
      AND "IsCommitted"   = FALSE
      AND "IsReleased"    = FALSE;

    IF FOUND THEN
        RETURN QUERY SELECT TRUE, 'Reserva liberada'::VARCHAR;
    ELSE
        RETURN QUERY SELECT FALSE, 'Reserva no encontrada o ya procesada'::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 5. Función: confirmar reserva (convierte en movimiento real)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_stock_commit(
    p_reservation_id BIGINT,
    p_company_id     INTEGER,
    p_unit_cost      NUMERIC  DEFAULT 0,
    p_user_id        INTEGER  DEFAULT NULL
) RETURNS TABLE("ok" BOOLEAN, "MovementId" BIGINT, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_resv         inv."StockReservation"%ROWTYPE;
    v_product_name VARCHAR(250);
    v_mov_id       BIGINT;
BEGIN
    SELECT r.* INTO v_resv
    FROM inv."StockReservation" r
    WHERE r."ReservationId" = p_reservation_id
      AND r."CompanyId"     = p_company_id
      AND r."IsCommitted"   = FALSE
      AND r."IsReleased"    = FALSE
    FOR UPDATE;

    IF v_resv."ReservationId" IS NULL THEN
        RETURN QUERY SELECT FALSE, 0::BIGINT, 'Reserva no encontrada o ya procesada'::VARCHAR;
        RETURN;
    END IF;

    -- Obtener nombre del producto
    SELECT "ProductName" INTO v_product_name
    FROM master."Product"
    WHERE "ProductCode" = v_resv."ProductCode"
      AND "CompanyId"   = p_company_id
    LIMIT 1;

    -- Insertar movimiento de salida
    INSERT INTO master."InventoryMovement" (
        "CompanyId", "ProductCode", "ProductName",
        "MovementType", "Quantity", "UnitCost", "TotalCost",
        "DocumentRef", "Notes", "CreatedByUserId",
        "SourceDocumentType", "SourceDocumentId"
    ) VALUES (
        p_company_id,
        v_resv."ProductCode",
        COALESCE(v_product_name, v_resv."ProductCode"),
        'SALIDA',
        v_resv."Quantity",
        COALESCE(p_unit_cost, 0),
        v_resv."Quantity" * COALESCE(p_unit_cost, 0),
        v_resv."ReferenceId",
        'Confirmación de reserva ' || p_reservation_id::TEXT,
        COALESCE(p_user_id, v_resv."CreatedByUserId"),
        v_resv."ReferenceType",
        p_reservation_id
    )
    RETURNING "MovementId" INTO v_mov_id;

    -- Decrementar stock en master.Product
    UPDATE master."Product"
    SET "StockQty" = GREATEST(COALESCE("StockQty", 0) - v_resv."Quantity", 0)
    WHERE "ProductCode" = v_resv."ProductCode"
      AND "CompanyId"   = p_company_id;

    -- Marcar reserva como confirmada
    UPDATE inv."StockReservation"
    SET "IsCommitted" = TRUE,
        "CommittedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "ReservationId" = p_reservation_id;

    RETURN QUERY SELECT TRUE, v_mov_id, 'Stock confirmado'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- =============================================================================
-- 6. Función: cleanup de reservas expiradas (para cron job)
-- =============================================================================
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION public.usp_inv_stock_cleanup_expired()
RETURNS TABLE("released_count" INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE inv."StockReservation"
    SET "IsReleased" = TRUE,
        "ReleasedAt" = (NOW() AT TIME ZONE 'UTC')
    WHERE "IsCommitted" = FALSE
      AND "IsReleased"  = FALSE
      AND "ExpiresAt"   < (NOW() AT TIME ZONE 'UTC');

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN QUERY SELECT v_count;
END;
$$;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP FUNCTION IF EXISTS public.usp_inv_stock_cleanup_expired();
DROP FUNCTION IF EXISTS public.usp_inv_stock_commit(BIGINT, INTEGER, NUMERIC, INTEGER);
DROP FUNCTION IF EXISTS public.usp_inv_stock_release(BIGINT, INTEGER);
DROP FUNCTION IF EXISTS public.usp_inv_stock_reserve(INTEGER, VARCHAR, NUMERIC, VARCHAR, VARCHAR, INTEGER, INTEGER);
DROP FUNCTION IF EXISTS public.usp_inv_stock_available(INTEGER, VARCHAR);
DROP TABLE IF EXISTS inv."StockReservation";
-- +goose StatementEnd
