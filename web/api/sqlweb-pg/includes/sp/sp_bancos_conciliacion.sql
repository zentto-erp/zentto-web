-- ============================================================
-- DatqBoxWeb PostgreSQL - sp_bancos_conciliacion.sql
-- Sistema de conciliacion bancaria: tablas y funciones
-- ============================================================

/*
  Sistema de Conciliacion Bancaria (PostgreSQL 14+)
  Traducido de: web/api/sqlweb/includes/sp/sp_bancos_conciliacion.sql
  XML -> JSONB para importacion de extractos.
  Multiple result sets del SP original se dividen en funciones separadas.
  BEGIN TRAN/COMMIT/ROLLBACK eliminados (auto-transaccional en funciones PG).
*/

-- =============================================
-- 1. TABLA: ExtractoBancario (Importar datos del banco)
-- =============================================
CREATE TABLE IF NOT EXISTS "ExtractoBancario" (
    "ID" SERIAL PRIMARY KEY,
    "Nro_Cta" VARCHAR(20) NOT NULL,
    "Fecha" TIMESTAMP NOT NULL,
    "Descripcion" VARCHAR(255) NULL,
    "Referencia" VARCHAR(50) NULL,
    "Tipo" VARCHAR(10) NULL,              -- DEBITO/CREDITO
    "Monto" NUMERIC(18,2) NOT NULL,
    "Saldo" NUMERIC(18,2) NULL,
    "Conciliado" BOOLEAN NULL DEFAULT FALSE,
    "Fecha_Conciliacion" TIMESTAMP NULL,
    "MovCuentas_ID" INT NULL,              -- Vinculo a MovCuentas si existe
    "Co_Usuario" VARCHAR(60) NULL DEFAULT 'API',
    "Fecha_Reg" TIMESTAMP NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_Extracto_NroCta" ON "ExtractoBancario"("Nro_Cta", "Fecha");
CREATE INDEX IF NOT EXISTS "IX_Extracto_Conciliado" ON "ExtractoBancario"("Conciliado");
CREATE INDEX IF NOT EXISTS "IX_Extracto_Ref" ON "ExtractoBancario"("Referencia");

-- =============================================
-- 2. TABLA: ConciliacionBancaria
-- =============================================
CREATE TABLE IF NOT EXISTS "ConciliacionBancaria" (
    "ID" SERIAL PRIMARY KEY,
    "Nro_Cta" VARCHAR(20) NOT NULL,
    "Fecha_Desde" TIMESTAMP NOT NULL,
    "Fecha_Hasta" TIMESTAMP NOT NULL,
    "Saldo_Inicial_Sistema" NUMERIC(18,2) NULL DEFAULT 0,
    "Saldo_Final_Sistema" NUMERIC(18,2) NULL DEFAULT 0,
    "Saldo_Inicial_Banco" NUMERIC(18,2) NULL DEFAULT 0,
    "Saldo_Final_Banco" NUMERIC(18,2) NULL DEFAULT 0,
    "Diferencia" NUMERIC(18,2) NULL DEFAULT 0,
    "Estado" VARCHAR(20) NULL DEFAULT 'PENDIENTE', -- PENDIENTE, CONCILIADO, AJUSTADO
    "Observaciones" VARCHAR(500) NULL,
    "Co_Usuario" VARCHAR(60) NULL DEFAULT 'API',
    "Fecha_Creacion" TIMESTAMP NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "Fecha_Cierre" TIMESTAMP NULL
);

CREATE INDEX IF NOT EXISTS "IX_Conciliacion_NroCta" ON "ConciliacionBancaria"("Nro_Cta", "Fecha_Desde");

-- =============================================
-- 3. TABLA: ConciliacionDetalle
-- =============================================
CREATE TABLE IF NOT EXISTS "ConciliacionDetalle" (
    "ID" SERIAL PRIMARY KEY,
    "Conciliacion_ID" INT NOT NULL,
    "Tipo_Origen" VARCHAR(20) NOT NULL,   -- SISTEMA, BANCO, AJUSTE
    "MovCuentas_ID" INT NULL,              -- Si es de sistema
    "Extracto_ID" INT NULL,                -- Si es del banco
    "Fecha" TIMESTAMP NULL,
    "Descripcion" VARCHAR(255) NULL,
    "Referencia" VARCHAR(50) NULL,
    "Debito" NUMERIC(18,2) NULL DEFAULT 0,
    "Credito" NUMERIC(18,2) NULL DEFAULT 0,
    "Conciliado" BOOLEAN NULL DEFAULT FALSE,
    "Tipo_Ajuste" VARCHAR(20) NULL,       -- NOTA_CREDITO, NOTA_DEBITO, AJUSTE
    "Co_Usuario" VARCHAR(60) NULL DEFAULT 'API'
);

CREATE INDEX IF NOT EXISTS "IX_ConcDet_Conciliacion" ON "ConciliacionDetalle"("Conciliacion_ID");

-- =============================================
-- 4. Funcion: Generar movimiento bancario desde pago/cobro
-- Original: sp_GenerarMovimientoBancario
-- SCOPE_IDENTITY() -> RETURNING INTO
-- =============================================
DROP FUNCTION IF EXISTS sp_generar_movimiento_bancario(VARCHAR, VARCHAR, VARCHAR, VARCHAR, NUMERIC, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_generar_movimiento_bancario(
    p_nro_cta                VARCHAR(20),
    p_tipo                   VARCHAR(10),     -- PCH, DEP, NCR, NDB
    p_nro_ref                VARCHAR(30),
    p_beneficiario           VARCHAR(255),
    p_monto                  NUMERIC(18,2),
    p_concepto               VARCHAR(100),
    p_categoria              VARCHAR(50) DEFAULT NULL,
    p_co_usuario             VARCHAR(60) DEFAULT 'API',
    p_documento_relacionado  VARCHAR(60) DEFAULT NULL,
    p_tipo_doc_rel           VARCHAR(20) DEFAULT NULL
)
RETURNS TABLE (
    "ok"            BOOLEAN,
    "movimientoId"  INT,
    "saldoNuevo"    NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_gastos       NUMERIC(18,2) := 0;
    v_ingresos     NUMERIC(18,2) := 0;
    v_saldo_actual NUMERIC(18,2);
    v_mov_id       INT;
    v_debe         NUMERIC(18,2);
    v_haber        NUMERIC(18,2);
    v_banco        VARCHAR(100);
BEGIN
    -- Validar cuenta existe
    IF NOT EXISTS (SELECT 1 FROM "CuentasBank" WHERE "Nro_Cta" = p_nro_cta) THEN
        RAISE EXCEPTION 'cuenta_bancaria_no_existe';
    END IF;

    -- Determinar si es gasto o ingreso segun tipo
    -- PCH (cheque), NDB (nota debito) = Gasto
    -- DEP (deposito), NCR (nota credito) = Ingreso
    IF p_tipo IN ('PCH', 'NDB', 'IDB') THEN
        v_gastos := p_monto;
    ELSIF p_tipo IN ('DEP', 'NCR') THEN
        v_ingresos := p_monto;
    END IF;

    -- Obtener saldo actual
    SELECT COALESCE("Saldo", 0) INTO v_saldo_actual
    FROM "CuentasBank"
    WHERE "Nro_Cta" = p_nro_cta;

    -- Calcular nuevo saldo
    v_saldo_actual := v_saldo_actual + v_ingresos - v_gastos;

    -- Insertar en MovCuentas
    INSERT INTO "MovCuentas" (
        "Nro_Cta", "Fecha", "Tipo", "Nro_Ref", "Beneficiario", "Categoria",
        "Gastos", "Ingresos", "Saldo_Dia", "Saldo", "Confirmada",
        "Co_Usuario", "Concepto", "Fecha_Banco"
    )
    VALUES (
        p_nro_cta, NOW() AT TIME ZONE 'UTC', p_tipo, p_nro_ref, p_beneficiario, p_categoria,
        v_gastos, v_ingresos, v_saldo_actual, v_saldo_actual, FALSE,
        p_co_usuario, p_concepto, NULL
    )
    RETURNING "id" INTO v_mov_id;

    -- Actualizar saldo en CuentasBank
    UPDATE "CuentasBank" SET
        "Saldo" = v_saldo_actual,
        "Saldo_Disponible" = v_saldo_actual
    WHERE "Nro_Cta" = p_nro_cta;

    -- Si hay documento relacionado, insertar en Movimiento_Cuenta para control contable
    IF p_documento_relacionado IS NOT NULL THEN
        v_debe  := CASE WHEN v_gastos > 0 THEN v_gastos ELSE 0 END;
        v_haber := CASE WHEN v_ingresos > 0 THEN v_ingresos ELSE 0 END;

        SELECT "Banco" INTO v_banco FROM "CuentasBank" WHERE "Nro_Cta" = p_nro_cta;

        INSERT INTO "Movimiento_Cuenta" (
            "COD_CUENTA", "COD_OPER", "FECHA", "DEBE", "HABER",
            "COD_USUARIO", "DESCRIPCION", "CONCEPTO", "Banco", "Cheque"
        )
        VALUES (
            p_nro_cta, p_tipo_doc_rel, NOW() AT TIME ZONE 'UTC', v_debe, v_haber,
            p_co_usuario, p_concepto, p_documento_relacionado, v_banco, p_nro_ref
        );
    END IF;

    RETURN QUERY SELECT TRUE, v_mov_id, v_saldo_actual;
END;
$$;

-- =============================================
-- 5. Funcion: Crear conciliacion bancaria
-- Original: sp_CrearConciliacion
-- TOP 1 ... ORDER BY -> ORDER BY ... LIMIT 1
-- SCOPE_IDENTITY() -> RETURNING INTO
-- =============================================
DROP FUNCTION IF EXISTS sp_crear_conciliacion(VARCHAR, TIMESTAMP, TIMESTAMP, VARCHAR);

CREATE OR REPLACE FUNCTION sp_crear_conciliacion(
    p_nro_cta      VARCHAR(20),
    p_fecha_desde  TIMESTAMP,
    p_fecha_hasta  TIMESTAMP,
    p_co_usuario   VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "conciliacionId" INT,
    "saldoInicial"   NUMERIC(18,2),
    "saldoFinal"     NUMERIC(18,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo_inicial   NUMERIC(18,2) := 0;
    v_saldo_final     NUMERIC(18,2) := 0;
    v_conciliacion_id INT;
BEGIN
    -- Obtener saldo inicial (al inicio del periodo)
    SELECT COALESCE("Saldo", 0) INTO v_saldo_inicial
    FROM "MovCuentas"
    WHERE "Nro_Cta" = p_nro_cta AND "Fecha" < p_fecha_desde
    ORDER BY "Fecha" DESC, "id" DESC
    LIMIT 1;

    -- Si no hay movimientos previos, tomar saldo apertura de CuentasBank
    IF v_saldo_inicial IS NULL THEN
        SELECT COALESCE("Saldo_Apertura", 0) INTO v_saldo_inicial
        FROM "CuentasBank"
        WHERE "Nro_Cta" = p_nro_cta;
    END IF;

    -- Obtener saldo final (movimientos hasta fecha hasta)
    SELECT COALESCE("Saldo", 0) INTO v_saldo_final
    FROM "MovCuentas"
    WHERE "Nro_Cta" = p_nro_cta AND "Fecha" <= p_fecha_hasta
    ORDER BY "Fecha" DESC, "id" DESC
    LIMIT 1;

    IF v_saldo_final IS NULL THEN
        v_saldo_final := v_saldo_inicial;
    END IF;

    -- Crear conciliacion
    INSERT INTO "ConciliacionBancaria" (
        "Nro_Cta", "Fecha_Desde", "Fecha_Hasta",
        "Saldo_Inicial_Sistema", "Saldo_Final_Sistema",
        "Estado", "Co_Usuario", "Fecha_Creacion"
    )
    VALUES (
        p_nro_cta, p_fecha_desde, p_fecha_hasta,
        v_saldo_inicial, v_saldo_final, 'PENDIENTE', p_co_usuario, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "ID" INTO v_conciliacion_id;

    -- Insertar movimientos del sistema no conciliados
    INSERT INTO "ConciliacionDetalle" (
        "Conciliacion_ID", "Tipo_Origen", "MovCuentas_ID",
        "Fecha", "Descripcion", "Referencia", "Debito", "Credito", "Conciliado"
    )
    SELECT
        v_conciliacion_id, 'SISTEMA', "id", "Fecha", "Concepto", "Nro_Ref",
        COALESCE("Gastos", 0), COALESCE("Ingresos", 0), "Confirmada"
    FROM "MovCuentas"
    WHERE "Nro_Cta" = p_nro_cta
      AND "Fecha" BETWEEN p_fecha_desde AND p_fecha_hasta
      AND "Confirmada" = FALSE;  -- Solo no conciliados

    RETURN QUERY SELECT v_conciliacion_id, v_saldo_inicial, v_saldo_final;
END;
$$;

-- =============================================
-- 6. Funcion: Importar extracto bancario
-- Original: sp_ImportarExtracto
-- XML -> JSONB (jsonb_array_elements reemplaza @xml.nodes)
-- =============================================
DROP FUNCTION IF EXISTS sp_importar_extracto(JSONB, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_importar_extracto(
    p_extracto_json  JSONB,       -- JSON array con datos del extracto
    p_nro_cta        VARCHAR(20),
    p_co_usuario     VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"                  BOOLEAN,
    "registrosImportados" INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_count INT := 0;
BEGIN
    INSERT INTO "ExtractoBancario" (
        "Nro_Cta", "Fecha", "Descripcion", "Referencia", "Tipo", "Monto", "Saldo", "Conciliado", "Co_Usuario"
    )
    SELECT
        p_nro_cta,
        CASE WHEN (elem->>'Fecha') IS NOT NULL
             THEN (elem->>'Fecha')::TIMESTAMP
             ELSE NOW() AT TIME ZONE 'UTC' END,
        NULLIF(elem->>'Descripcion', ''),
        NULLIF(elem->>'Referencia', ''),
        NULLIF(elem->>'Tipo', ''),                -- DEBITO/CREDITO
        CASE WHEN (elem->>'Monto') IS NOT NULL
             THEN (elem->>'Monto')::NUMERIC(18,2)
             ELSE 0 END,
        CASE WHEN (elem->>'Saldo') IS NOT NULL
             THEN (elem->>'Saldo')::NUMERIC(18,2)
             ELSE NULL END,
        FALSE,  -- No conciliado
        p_co_usuario
    FROM jsonb_array_elements(p_extracto_json) AS elem;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN QUERY SELECT TRUE, v_count;
END;
$$;

-- =============================================
-- 7. Funcion: Conciliar movimientos
-- Original: sp_ConciliarMovimientos
-- =============================================
DROP FUNCTION IF EXISTS sp_conciliar_movimientos(INT, INT, INT, VARCHAR);

CREATE OR REPLACE FUNCTION sp_conciliar_movimientos(
    p_conciliacion_id       INT,
    p_movimiento_sistema_id INT,      -- ID de ConciliacionDetalle (Tipo_Origen = SISTEMA)
    p_extracto_id           INT DEFAULT NULL,  -- ID de ExtractoBancario (opcional, para match manual)
    p_co_usuario            VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"      BOOLEAN,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_mov_cuentas_id   INT;
    v_sistema_debito   NUMERIC(18,2);
    v_sistema_credito  NUMERIC(18,2);
    v_banco_debito     NUMERIC(18,2);
    v_banco_credito    NUMERIC(18,2);
BEGIN
    -- Marcar como conciliado en detalle
    UPDATE "ConciliacionDetalle" SET
        "Conciliado" = TRUE,
        "Extracto_ID" = p_extracto_id
    WHERE "ID" = p_movimiento_sistema_id AND "Conciliacion_ID" = p_conciliacion_id;

    -- Obtener MovCuentas_ID
    SELECT "MovCuentas_ID" INTO v_mov_cuentas_id
    FROM "ConciliacionDetalle"
    WHERE "ID" = p_movimiento_sistema_id;

    -- Marcar MovCuentas como confirmado
    UPDATE "MovCuentas" SET "Confirmada" = TRUE
    WHERE "id" = v_mov_cuentas_id;

    -- Si hay extracto, marcarlo como conciliado
    IF p_extracto_id IS NOT NULL THEN
        UPDATE "ExtractoBancario" SET
            "Conciliado" = TRUE,
            "Fecha_Conciliacion" = NOW() AT TIME ZONE 'UTC',
            "MovCuentas_ID" = v_mov_cuentas_id
        WHERE "ID" = p_extracto_id;
    END IF;

    -- Recalcular diferencia
    SELECT SUM("Debito"), SUM("Credito")
    INTO v_sistema_debito, v_sistema_credito
    FROM "ConciliacionDetalle"
    WHERE "Conciliacion_ID" = p_conciliacion_id
      AND "Tipo_Origen" = 'SISTEMA'
      AND "Conciliado" = TRUE;

    SELECT
        SUM(CASE WHEN e."Tipo" = 'DEBITO' THEN e."Monto" ELSE 0 END),
        SUM(CASE WHEN e."Tipo" = 'CREDITO' THEN e."Monto" ELSE 0 END)
    INTO v_banco_debito, v_banco_credito
    FROM "ExtractoBancario" e
    INNER JOIN "ConciliacionDetalle" d ON e."ID" = d."Extracto_ID"
    WHERE d."Conciliacion_ID" = p_conciliacion_id AND d."Conciliado" = TRUE;

    -- Actualizar conciliacion
    UPDATE "ConciliacionBancaria" SET
        "Diferencia" = (COALESCE(v_sistema_credito, 0) - COALESCE(v_sistema_debito, 0)) -
                       (COALESCE(v_banco_credito, 0) - COALESCE(v_banco_debito, 0))
    WHERE "ID" = p_conciliacion_id;

    RETURN QUERY SELECT TRUE, 'Movimiento conciliado'::VARCHAR;
END;
$$;

-- =============================================
-- 8. Funcion: Generar ajuste bancario (Nota Credito/Debito)
-- Original: sp_GenerarAjusteBancario
-- Llama internamente a sp_generar_movimiento_bancario
-- =============================================
DROP FUNCTION IF EXISTS sp_generar_ajuste_bancario(INT, VARCHAR, NUMERIC, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_generar_ajuste_bancario(
    p_conciliacion_id  INT,
    p_tipo_ajuste      VARCHAR(20),       -- NOTA_CREDITO, NOTA_DEBITO
    p_monto            NUMERIC(18,2),
    p_descripcion      VARCHAR(255),
    p_co_usuario       VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"      BOOLEAN,
    "mensaje" VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nro_cta   VARCHAR(20);
    v_tipo_mov  VARCHAR(10);
    v_debito    NUMERIC(18,2) := 0;
    v_credito   NUMERIC(18,2) := 0;
BEGIN
    SELECT "Nro_Cta" INTO v_nro_cta
    FROM "ConciliacionBancaria"
    WHERE "ID" = p_conciliacion_id;

    IF v_nro_cta IS NULL THEN
        RAISE EXCEPTION 'conciliacion_no_existe';
    END IF;

    -- Determinar tipo
    IF p_tipo_ajuste = 'NOTA_CREDITO' THEN
        v_tipo_mov := 'NCR';
        v_credito  := p_monto;
    ELSIF p_tipo_ajuste = 'NOTA_DEBITO' THEN
        v_tipo_mov := 'NDB';
        v_debito   := p_monto;
    ELSE
        RAISE EXCEPTION 'tipo_ajuste_invalido';
    END IF;

    -- Generar movimiento bancario
    PERFORM sp_generar_movimiento_bancario(
        p_nro_cta               := v_nro_cta,
        p_tipo                  := v_tipo_mov,
        p_nro_ref               := 'AJUSTE-' || p_conciliacion_id::TEXT,
        p_beneficiario          := 'AJUSTE CONCILIACION',
        p_monto                 := p_monto,
        p_concepto              := p_descripcion,
        p_co_usuario            := p_co_usuario
    );

    -- Insertar en detalle de conciliacion como ajuste
    INSERT INTO "ConciliacionDetalle" (
        "Conciliacion_ID", "Tipo_Origen", "Fecha", "Descripcion",
        "Referencia", "Debito", "Credito", "Conciliado", "Tipo_Ajuste", "Co_Usuario"
    )
    VALUES (
        p_conciliacion_id, 'AJUSTE', NOW() AT TIME ZONE 'UTC', p_descripcion,
        'AJUSTE-' || p_conciliacion_id::TEXT, v_debito, v_credito, TRUE, p_tipo_ajuste, p_co_usuario
    );

    RETURN QUERY SELECT TRUE, 'Ajuste generado'::VARCHAR;
END;
$$;

-- =============================================
-- 9. Funcion: Cerrar conciliacion
-- Original: sp_CerrarConciliacion
-- =============================================
DROP FUNCTION IF EXISTS sp_cerrar_conciliacion(INT, NUMERIC, VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION sp_cerrar_conciliacion(
    p_conciliacion_id    INT,
    p_saldo_final_banco  NUMERIC(18,2),
    p_observaciones      VARCHAR(500) DEFAULT NULL,
    p_co_usuario         VARCHAR(60) DEFAULT 'API'
)
RETURNS TABLE (
    "ok"         BOOLEAN,
    "diferencia" NUMERIC(18,2),
    "estado"     VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saldo_final_sistema NUMERIC(18,2);
    v_diferencia          NUMERIC(18,2);
    v_estado              VARCHAR(20);
BEGIN
    SELECT "Saldo_Final_Sistema" INTO v_saldo_final_sistema
    FROM "ConciliacionBancaria"
    WHERE "ID" = p_conciliacion_id;

    v_diferencia := v_saldo_final_sistema - p_saldo_final_banco;
    v_estado := CASE WHEN ABS(v_diferencia) < 0.01 THEN 'CONCILIADO' ELSE 'DIFERENCIA' END;

    UPDATE "ConciliacionBancaria" SET
        "Saldo_Final_Banco" = p_saldo_final_banco,
        "Diferencia" = v_diferencia,
        "Observaciones" = p_observaciones,
        "Estado" = v_estado,
        "Fecha_Cierre" = NOW() AT TIME ZONE 'UTC',
        "Co_Usuario" = p_co_usuario
    WHERE "ID" = p_conciliacion_id;

    RETURN QUERY SELECT TRUE, v_diferencia, v_estado;
END;
$$;

-- =============================================
-- 10. Funcion: Listar conciliaciones (paginado)
-- Original: sp_Conciliacion_List
-- OFFSET FETCH -> LIMIT OFFSET
-- @TotalCount OUTPUT -> "TotalCount" BIGINT en RETURNS TABLE
-- =============================================
DROP FUNCTION IF EXISTS sp_conciliacion_list(VARCHAR, VARCHAR, INT, INT);

CREATE OR REPLACE FUNCTION sp_conciliacion_list(
    p_nro_cta  VARCHAR(20) DEFAULT NULL,
    p_estado   VARCHAR(20) DEFAULT NULL,
    p_page     INT DEFAULT 1,
    p_limit    INT DEFAULT 50
)
RETURNS TABLE (
    "TotalCount"            BIGINT,
    "ID"                    INT,
    "Nro_Cta"               VARCHAR,
    "Fecha_Desde"           TIMESTAMP,
    "Fecha_Hasta"           TIMESTAMP,
    "Saldo_Inicial_Sistema" NUMERIC,
    "Saldo_Final_Sistema"   NUMERIC,
    "Saldo_Inicial_Banco"   NUMERIC,
    "Saldo_Final_Banco"     NUMERIC,
    "Diferencia"            NUMERIC,
    "Estado"                VARCHAR,
    "Observaciones"         VARCHAR,
    "Co_Usuario"            VARCHAR,
    "Fecha_Creacion"        TIMESTAMP,
    "Fecha_Cierre"          TIMESTAMP,
    "Banco"                 VARCHAR,
    "Pendientes"            BIGINT,
    "Conciliados"           BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset INT := (p_page - 1) * p_limit;
    v_total  BIGINT;
BEGIN
    SELECT COUNT(1) INTO v_total
    FROM "ConciliacionBancaria"
    WHERE (p_nro_cta IS NULL OR "Nro_Cta" = p_nro_cta)
      AND (p_estado IS NULL OR "Estado" = p_estado);

    RETURN QUERY
    SELECT
        v_total,
        c."ID", c."Nro_Cta", c."Fecha_Desde", c."Fecha_Hasta",
        c."Saldo_Inicial_Sistema", c."Saldo_Final_Sistema",
        c."Saldo_Inicial_Banco", c."Saldo_Final_Banco",
        c."Diferencia", c."Estado", c."Observaciones",
        c."Co_Usuario", c."Fecha_Creacion", c."Fecha_Cierre",
        b."Banco",
        (SELECT COUNT(1) FROM "ConciliacionDetalle" d WHERE d."Conciliacion_ID" = c."ID" AND d."Conciliado" = FALSE),
        (SELECT COUNT(1) FROM "ConciliacionDetalle" d WHERE d."Conciliacion_ID" = c."ID" AND d."Conciliado" = TRUE)
    FROM "ConciliacionBancaria" c
    LEFT JOIN "CuentasBank" b ON b."Nro_Cta" = c."Nro_Cta"
    WHERE (p_nro_cta IS NULL OR c."Nro_Cta" = p_nro_cta)
      AND (p_estado IS NULL OR c."Estado" = p_estado)
    ORDER BY c."Fecha_Creacion" DESC
    LIMIT p_limit OFFSET v_offset;
END;
$$;

-- =============================================
-- 11. Funcion: Obtener detalle de conciliacion - cabecera
-- Original: sp_Conciliacion_Get (result set 1)
-- PG no puede retornar multiple result sets en una sola funcion,
-- se divide en funciones separadas.
-- =============================================
DROP FUNCTION IF EXISTS sp_conciliacion_get_header(INT);

CREATE OR REPLACE FUNCTION sp_conciliacion_get_header(
    p_conciliacion_id INT
)
RETURNS TABLE (
    "ID"                    INT,
    "Nro_Cta"               VARCHAR,
    "Fecha_Desde"           TIMESTAMP,
    "Fecha_Hasta"           TIMESTAMP,
    "Saldo_Inicial_Sistema" NUMERIC,
    "Saldo_Final_Sistema"   NUMERIC,
    "Saldo_Inicial_Banco"   NUMERIC,
    "Saldo_Final_Banco"     NUMERIC,
    "Diferencia"            NUMERIC,
    "Estado"                VARCHAR,
    "Observaciones"         VARCHAR,
    "Banco"                 VARCHAR,
    "Descripcion"           VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c."ID", c."Nro_Cta", c."Fecha_Desde", c."Fecha_Hasta",
        c."Saldo_Inicial_Sistema", c."Saldo_Final_Sistema",
        c."Saldo_Inicial_Banco", c."Saldo_Final_Banco",
        c."Diferencia", c."Estado", c."Observaciones",
        b."Banco", b."Descripcion"
    FROM "ConciliacionBancaria" c
    LEFT JOIN "CuentasBank" b ON b."Nro_Cta" = c."Nro_Cta"
    WHERE c."ID" = p_conciliacion_id;
END;
$$;

-- =============================================
-- 12. Funcion: Obtener detalle de conciliacion - movimientos sistema
-- Original: sp_Conciliacion_Get (result set 2)
-- =============================================
DROP FUNCTION IF EXISTS sp_conciliacion_get_detalle_sistema(INT);

CREATE OR REPLACE FUNCTION sp_conciliacion_get_detalle_sistema(
    p_conciliacion_id INT
)
RETURNS TABLE (
    "ID"              INT,
    "Conciliacion_ID" INT,
    "Tipo_Origen"     VARCHAR,
    "MovCuentas_ID"   INT,
    "Extracto_ID"     INT,
    "Fecha"           TIMESTAMP,
    "Descripcion"     VARCHAR,
    "Referencia"      VARCHAR,
    "Debito"          NUMERIC,
    "Credito"         NUMERIC,
    "Conciliado"      BOOLEAN,
    "Nro_Ref"         VARCHAR,
    "MovFecha"        TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d."ID", d."Conciliacion_ID", d."Tipo_Origen", d."MovCuentas_ID",
        d."Extracto_ID", d."Fecha", d."Descripcion", d."Referencia",
        d."Debito", d."Credito", d."Conciliado",
        m."Nro_Ref", m."Fecha" AS "MovFecha"
    FROM "ConciliacionDetalle" d
    LEFT JOIN "MovCuentas" m ON m."id" = d."MovCuentas_ID"
    WHERE d."Conciliacion_ID" = p_conciliacion_id AND d."Tipo_Origen" = 'SISTEMA'
    ORDER BY d."Fecha";
END;
$$;

-- =============================================
-- 13. Funcion: Obtener extracto no conciliado para una conciliacion
-- Original: sp_Conciliacion_Get (result set 3)
-- =============================================
DROP FUNCTION IF EXISTS sp_conciliacion_get_extracto_pendiente(INT);

CREATE OR REPLACE FUNCTION sp_conciliacion_get_extracto_pendiente(
    p_conciliacion_id INT
)
RETURNS TABLE (
    "ID"          INT,
    "Nro_Cta"     VARCHAR,
    "Fecha"       TIMESTAMP,
    "Descripcion" VARCHAR,
    "Referencia"  VARCHAR,
    "Tipo"        VARCHAR,
    "Monto"       NUMERIC,
    "Saldo"       NUMERIC,
    "Conciliado"  BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_nro_cta     VARCHAR(20);
    v_fecha_desde TIMESTAMP;
    v_fecha_hasta TIMESTAMP;
BEGIN
    SELECT cb."Nro_Cta", cb."Fecha_Desde", cb."Fecha_Hasta"
    INTO v_nro_cta, v_fecha_desde, v_fecha_hasta
    FROM "ConciliacionBancaria" cb
    WHERE cb."ID" = p_conciliacion_id;

    RETURN QUERY
    SELECT
        e."ID", e."Nro_Cta", e."Fecha", e."Descripcion", e."Referencia",
        e."Tipo", e."Monto", e."Saldo", e."Conciliado"
    FROM "ExtractoBancario" e
    WHERE e."Nro_Cta" = v_nro_cta
      AND e."Conciliado" = FALSE
      AND e."Fecha" BETWEEN v_fecha_desde AND v_fecha_hasta
    ORDER BY e."Fecha";
END;
$$;

-- =============================================
-- 14. Funcion: Obtener movimiento bancario por ID
-- Original: sp_GetMovimientoBancarioById
-- Usa tablas canonicas fin.BankMovement, fin.BankAccount, fin.Bank
-- =============================================
DROP FUNCTION IF EXISTS sp_get_movimiento_bancario_by_id(INT);

CREATE OR REPLACE FUNCTION sp_get_movimiento_bancario_by_id(
    p_movimiento_id INT
)
RETURNS TABLE (
    "id"                    INT,
    "BankAccountId"         INT,
    "Fecha"                 TIMESTAMP,
    "Tipo"                  VARCHAR,
    "MovementSign"          VARCHAR,
    "Monto"                 NUMERIC,
    "NetAmount"             NUMERIC,
    "Nro_Ref"               VARCHAR,
    "Beneficiario"          VARCHAR,
    "Concepto"              VARCHAR,
    "Categoria"             VARCHAR,
    "Documento_Relacionado" VARCHAR,
    "Tipo_Doc_Rel"          VARCHAR,
    "Saldo"                 NUMERIC,
    "IsReconciled"          BOOLEAN,
    "CreatedAt"             TIMESTAMP,
    "Nro_Cta"               VARCHAR,
    "CuentaDescripcion"     VARCHAR,
    "SaldoActual"           NUMERIC,
    "BancoNombre"           VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m."BankMovementId",
        m."BankAccountId",
        m."MovementDate",
        m."MovementType",
        m."MovementSign",
        m."Amount",
        m."NetAmount",
        m."ReferenceNo",
        m."Beneficiary",
        m."Concept",
        m."CategoryCode",
        m."RelatedDocumentNo",
        m."RelatedDocumentType",
        m."BalanceAfter",
        m."IsReconciled",
        m."CreatedAt",
        a."AccountNumber",
        a."AccountName",
        a."Balance",
        b."BankName"
    FROM fin."BankMovement" m
    INNER JOIN fin."BankAccount" a ON a."BankAccountId" = m."BankAccountId"
    LEFT JOIN fin."Bank" b ON b."BankId" = a."BankId"
    WHERE m."BankMovementId" = p_movimiento_id;
END;
$$;
