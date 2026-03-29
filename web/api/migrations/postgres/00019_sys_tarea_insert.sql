-- +goose Up
-- +goose StatementBegin
-- FunciÃ³n para insertar tareas desde el Kafka notification consumer
-- Con deduplicaciÃ³n: no crear si ya existe tarea con mismo tÃ­tulo no completada

CREATE OR REPLACE FUNCTION usp_sys_tarea_insert(
    p_titulo VARCHAR(200),
    p_descripcion TEXT DEFAULT NULL,
    p_color VARCHAR(30) DEFAULT 'blue',
    p_asignado_a VARCHAR(50) DEFAULT NULL,
    p_fecha_vencimiento DATE DEFAULT NULL
)
RETURNS TABLE("Id" INT, "Mensaje" VARCHAR) LANGUAGE plpgsql AS $$
BEGIN
    -- DeduplicaciÃ³n: no crear si ya existe tarea con mismo tÃ­tulo no completada
    IF EXISTS (
        SELECT 1 FROM "Sys_Tareas"
        WHERE "Titulo" = p_titulo
          AND "Completado" = FALSE
    ) THEN
        RETURN QUERY SELECT 0, 'duplicado_tarea_activa'::VARCHAR;
        RETURN;
    END IF;

    RETURN QUERY
    INSERT INTO "Sys_Tareas" ("Titulo", "Descripcion", "Color", "AsignadoA", "FechaVencimiento")
    VALUES (p_titulo, p_descripcion, p_color, p_asignado_a, p_fecha_vencimiento)
    RETURNING "Sys_Tareas"."Id", 'ok'::VARCHAR;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_sys_tarea_insert(VARCHAR, TEXT, VARCHAR, VARCHAR, DATE);
