-- 14_patch_cms_contact_update_status.sql
-- CMS Contact Submissions · CHECK constraint + SP update status.
-- Equivalente T-SQL de la migración goose 00169.
USE zentto_dev;
GO

-- ── CHECK constraint (idempotente) ───────────────────────────────────────────
IF EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE name = 'ck_cms_contactsubmission_status'
      AND parent_object_id = OBJECT_ID('cms.ContactSubmission')
)
    ALTER TABLE cms.[ContactSubmission] DROP CONSTRAINT ck_cms_contactsubmission_status;
GO

ALTER TABLE cms.[ContactSubmission]
    ADD CONSTRAINT ck_cms_contactsubmission_status
    CHECK (Status IN ('pending', 'read', 'archived'));
GO
