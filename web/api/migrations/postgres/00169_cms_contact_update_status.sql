-- +goose Up
-- CMS Contact Submissions · SP para actualizar el estado de un mensaje
-- (pending → read → archived). Desbloquea los botones "Marcar leído" y
-- "Archivar" del inbox admin en `appdev.zentto.net/cms/contact-submissions`.
--
-- Estados aceptados:
--   pending  (default al insertar)
--   read     (admin marcó como leído)
--   archived (admin lo archivó, sale de la inbox visible por default)

-- ── CHECK constraint sobre Status (idempotente) ──────────────────────────────
ALTER TABLE cms."ContactSubmission"
    DROP CONSTRAINT IF EXISTS ck_cms_contactsubmission_status;
ALTER TABLE cms."ContactSubmission"
    ADD CONSTRAINT ck_cms_contactsubmission_status
    CHECK ("Status" IN ('pending', 'read', 'archived'));

-- ── usp_cms_contact_update_status ────────────────────────────────────────────
-- +goose StatementBegin
CREATE OR REPLACE FUNCTION usp_cms_contact_update_status(
    p_submission_id INTEGER,
    p_company_id    INTEGER,
    p_status        VARCHAR
)
RETURNS TABLE("ok" BOOLEAN, "mensaje" VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows INTEGER;
BEGIN
    IF p_status IS NULL OR p_status NOT IN ('pending', 'read', 'archived') THEN
        RETURN QUERY SELECT FALSE, 'invalid_status'::VARCHAR;
        RETURN;
    END IF;

    UPDATE cms."ContactSubmission"
    SET "Status" = p_status
    WHERE "ContactSubmissionId" = p_submission_id
      AND "CompanyId" = p_company_id;

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows = 0 THEN
        RETURN QUERY SELECT FALSE, 'submission_not_found'::VARCHAR;
    ELSE
        RETURN QUERY SELECT TRUE, 'status_updated'::VARCHAR;
    END IF;
END;
$$;
-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_cms_contact_update_status(INTEGER, INTEGER, VARCHAR);
ALTER TABLE cms."ContactSubmission"
    DROP CONSTRAINT IF EXISTS ck_cms_contactsubmission_status;
