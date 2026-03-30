-- ============================================================
-- Migration 030: Fix usp_Fiscal_TaxBook_Populate
-- Reemplaza fuente de datos legacy (dbo."DocumentosVenta"/dbo."DocumentosCompra")
-- por tablas canonicas (ar."SalesDocument" / ap."PurchaseDocument").
-- Motivo: dbo schema no existe en PG; los datos reales estan en ar/ap.
-- ============================================================

DROP FUNCTION IF EXISTS usp_Fiscal_TaxBook_Populate(INTEGER, VARCHAR(10), VARCHAR(7), VARCHAR(2), VARCHAR(40), INTEGER, TEXT) CASCADE;

CREATE OR REPLACE FUNCTION usp_Fiscal_TaxBook_Populate(
    p_company_id   INTEGER,
    p_book_type    VARCHAR(10),
    p_period_code  VARCHAR(7),
    p_country_code VARCHAR(2),
    p_cod_usuario  VARCHAR(40),
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_period_start  DATE;
    v_period_end    DATE;
    v_rows_inserted INTEGER := 0;
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    v_period_start := CAST(p_period_code || '-01' AS DATE);
    v_period_end   := (DATE_TRUNC('month', v_period_start) + INTERVAL '1 month - 1 day')::DATE;

    IF p_book_type NOT IN ('SALES', 'PURCHASE') THEN
        p_resultado := 0;
        p_mensaje   := 'BookType debe ser SALES o PURCHASE';
        RETURN;
    END IF;

    BEGIN
        -- Eliminar entradas existentes para regenerar
        DELETE FROM fiscal."TaxBookEntry"
        WHERE "CompanyId"   = p_company_id
          AND "BookType"    = p_book_type
          AND "PeriodCode"  = p_period_code
          AND "CountryCode" = p_country_code;

        IF p_book_type = 'SALES' THEN
            INSERT INTO fiscal."TaxBookEntry" (
                "CompanyId", "BookType", "PeriodCode", "EntryDate",
                "DocumentNumber", "DocumentType", "ControlNumber",
                "ThirdPartyId", "ThirdPartyName",
                "TaxableBase", "ExemptAmount", "TaxRate", "TaxAmount",
                "WithholdingRate", "WithholdingAmount", "TotalAmount",
                "SourceDocumentId", "SourceModule", "CountryCode", "CreatedAt"
            )
            SELECT
                p_company_id,
                'SALES',
                p_period_code,
                v."DocumentDate"::DATE,
                v."DocumentNumber",
                CASE v."SerialType"
                    WHEN 'FAC'   THEN 'FACTURA'
                    WHEN 'NC'    THEN 'NOTA_CREDITO'
                    WHEN 'ND'    THEN 'NOTA_DEBITO'
                    WHEN 'FACT'  THEN 'FACTURA'
                    ELSE COALESCE(v."SerialType", 'FACTURA')
                END,
                v."ControlNumber",
                v."FiscalId",
                v."CustomerName",
                COALESCE(v."TaxableAmount", 0),
                COALESCE(v."ExemptAmount",  0),
                COALESCE(v."TaxRate",       0),
                COALESCE(v."TaxAmount",     0),
                0,
                0,
                COALESCE(v."TotalAmount",   0),
                v."DocumentId",
                'AR',
                p_country_code,
                (NOW() AT TIME ZONE 'UTC')
            FROM ar."SalesDocument" v
            WHERE v."DocumentDate"::DATE BETWEEN v_period_start AND v_period_end
              AND v."IsVoided"  = FALSE
              AND v."IsDeleted" = FALSE;

            GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

        ELSIF p_book_type = 'PURCHASE' THEN
            INSERT INTO fiscal."TaxBookEntry" (
                "CompanyId", "BookType", "PeriodCode", "EntryDate",
                "DocumentNumber", "DocumentType", "ControlNumber",
                "ThirdPartyId", "ThirdPartyName",
                "TaxableBase", "ExemptAmount", "TaxRate", "TaxAmount",
                "WithholdingRate", "WithholdingAmount", "TotalAmount",
                "SourceDocumentId", "SourceModule", "CountryCode", "CreatedAt"
            )
            SELECT
                p_company_id,
                'PURCHASE',
                p_period_code,
                c."DocumentDate"::DATE,
                c."DocumentNumber",
                CASE c."SerialType"
                    WHEN 'FAC'    THEN 'FACTURA'
                    WHEN 'NC'     THEN 'NOTA_CREDITO'
                    WHEN 'ND'     THEN 'NOTA_DEBITO'
                    WHEN 'COMPRA' THEN 'FACTURA'
                    ELSE COALESCE(c."SerialType", 'FACTURA')
                END,
                c."ControlNumber",
                c."FiscalId",
                c."SupplierName",
                COALESCE(c."TaxableAmount",  0),
                COALESCE(c."ExemptAmount",   0),
                COALESCE(c."TaxRate",        0),
                COALESCE(c."TaxAmount",      0),
                COALESCE(c."RetentionRate",  0),
                COALESCE(c."RetainedTax",    0),
                COALESCE(c."TotalAmount",    0),
                c."DocumentId",
                'AP',
                p_country_code,
                (NOW() AT TIME ZONE 'UTC')
            FROM ap."PurchaseDocument" c
            WHERE c."DocumentDate"::DATE BETWEEN v_period_start AND v_period_end
              AND c."IsVoided"  = FALSE
              AND c."IsDeleted" = FALSE;

            GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;
        END IF;

        p_resultado := 1;
        p_mensaje   := 'Libro fiscal generado: ' || v_rows_inserted::TEXT || ' registros';
    EXCEPTION WHEN OTHERS THEN
        p_resultado := 0;
        p_mensaje   := 'Error: ' || SQLERRM;
    END;
END;
$$;
