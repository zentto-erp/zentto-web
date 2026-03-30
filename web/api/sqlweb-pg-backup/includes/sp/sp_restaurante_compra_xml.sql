-- SP Compra Restaurante con JSONB (traducido de XML SQL Server a JSONB PostgreSQL)

CREATE OR REPLACE FUNCTION usp_rest_compra_crear(
    p_proveedor_id   VARCHAR(12) DEFAULT NULL,
    p_observaciones  VARCHAR(500) DEFAULT NULL,
    p_cod_usuario    VARCHAR(10) DEFAULT NULL,
    p_detalle_json   JSONB DEFAULT '[]'::JSONB
)
RETURNS TABLE(
    "CompraId" INT
) LANGUAGE plpgsql AS $$
DECLARE
    v_compra_id  INT;
    v_num_compra VARCHAR(20);
    v_seq        INT;
BEGIN
    SELECT COALESCE(MAX("Id"), 0) + 1 INTO v_seq FROM "RestauranteCompras";
    v_num_compra := 'RC-' || REPLACE(TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM'), '-',''::VARCHAR) || '-' || LPAD(v_seq::TEXT, 4, '0');

    INSERT INTO "RestauranteCompras" ("NumCompra", "ProveedorId", "Estado", "Observaciones", "CodUsuario")
    VALUES (v_num_compra, p_proveedor_id, 'pendiente', p_observaciones, p_cod_usuario)
    RETURNING "Id" INTO v_compra_id;

    INSERT INTO "RestauranteComprasDetalle" ("CompraId", "InventarioId", "Descripcion", "Cantidad", "PrecioUnit", "Subtotal", "IVA")
    SELECT
        v_compra_id,
        (item->>'invId')::VARCHAR(15),
        (item->>'desc')::VARCHAR(200),
        (item->>'cant')::NUMERIC(10,3),
        (item->>'precio')::NUMERIC(18,2),
        (item->>'cant')::NUMERIC(10,3) * (item->>'precio')::NUMERIC(18,2),
        COALESCE((item->>'iva')::NUMERIC(5,2), 16)
    FROM jsonb_array_elements(p_detalle_json) AS item;

    UPDATE "RestauranteCompras" SET
        "Subtotal" = (SELECT COALESCE(SUM("Subtotal"), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "IVA" = (SELECT COALESCE(SUM("Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id),
        "Total" = (SELECT COALESCE(SUM("Subtotal" + "Subtotal" * "IVA" / 100), 0) FROM "RestauranteComprasDetalle" WHERE "CompraId" = v_compra_id)
    WHERE "Id" = v_compra_id;

    RETURN QUERY SELECT v_compra_id;

EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION '%', SQLERRM;
END;
$$;
