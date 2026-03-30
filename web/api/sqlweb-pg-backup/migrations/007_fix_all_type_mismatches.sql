-- ============================================================
-- 007_fix_all_type_mismatches.sql
-- Corrige desajustes de tipos entre funciones y tablas reales.
-- Generado automÃƒÂ¡ticamente comparando pg_proc vs information_schema.
-- ============================================================
-- Total de desajustes reales corregidos: 27 funciones / 37 columnas
-- Falsos positivos descartados: 10 (valores calculados o tipo correcto en tabla fuente)
-- ============================================================

-- ============================================================
-- 1. sp_get_movimiento_bancario_by_id
-- Desajuste: id integer -> bigint (fin.BankMovement.BankMovementId = bigint)
--            BankAccountId integer -> bigint (fin.BankAccount.BankAccountId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.sp_get_movimiento_bancario_by_id(integer) CASCADE;

CREATE OR REPLACE FUNCTION public.sp_get_movimiento_bancario_by_id(p_movimiento_id integer)
 RETURNS TABLE(
   id                       bigint,
   "BankAccountId"          bigint,
   "Fecha"                  timestamp without time zone,
   "Tipo"                   character varying,
   "MovementSign"           character varying,
   "Monto"                  numeric,
   "NetAmount"              numeric,
   "Nro_Ref"                character varying,
   "Beneficiario"           character varying,
   "Concepto"               character varying,
   "Categoria"              character varying,
   "Documento_Relacionado"  character varying,
   "Tipo_Doc_Rel"           character varying,
   "Saldo"                  numeric,
   "IsReconciled"           boolean,
   "CreatedAt"              timestamp without time zone,
   "Nro_Cta"                character varying,
   "CuentaDescripcion"      character varying,
   "SaldoActual"            numeric,
   "BancoNombre"            character varying
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        m."BankMovementId"::BIGINT,
        m."BankAccountId"::BIGINT,
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
$function$;

-- ============================================================
-- 2. usp_acct_reporttemplate_render
-- Desajuste: TemplateContent/HeaderJson/FooterJson character varying -> text
--            (acct.ReportTemplate: TemplateContent=text, HeaderJson=text, FooterJson=text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_acct_reporttemplate_render(integer, integer, date, date, date) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_acct_reporttemplate_render(
    p_company_id           integer,
    p_report_template_id   integer,
    p_fecha_desde          date DEFAULT NULL::date,
    p_fecha_hasta          date DEFAULT NULL::date,
    p_fecha_corte          date DEFAULT NULL::date
)
 RETURNS TABLE(
   "ReportTemplateId"  integer,
   "CountryCode"       character,
   "ReportCode"        character varying,
   "ReportName"        character varying,
   "LegalFramework"    character varying,
   "LegalReference"    character varying,
   "TemplateContent"   text,
   "HeaderJson"        text,
   "FooterJson"        text
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "ReportTemplateId", "CountryCode", "ReportCode", "ReportName",
           "LegalFramework", "LegalReference", "TemplateContent",
           "HeaderJson", "FooterJson"
    FROM acct."ReportTemplate"
    WHERE "ReportTemplateId" = p_report_template_id
      AND "CompanyId"        = p_company_id;
END;
$function$;

-- ============================================================
-- 3. usp_audit_fiscalrecord_list
-- Desajuste: FiscalRecordId integer -> bigint (fiscal.Record.FiscalRecordId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_audit_fiscalrecord_list(integer, integer, date, date, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_audit_fiscalrecord_list(
    p_company_id   integer,
    p_branch_id    integer,
    p_fecha_desde  date    DEFAULT NULL::date,
    p_fecha_hasta  date    DEFAULT NULL::date,
    p_page         integer DEFAULT 1,
    p_limit        integer DEFAULT 50
)
 RETURNS TABLE(
   "TotalCount"      bigint,
   "FiscalRecordId"  bigint,
   "InvoiceId"       integer,
   "InvoiceNumber"   character varying,
   "InvoiceDate"     date,
   "InvoiceType"     character varying,
   "RecordHash"      character varying,
   "SentToAuthority" boolean,
   "AuthorityStatus" character varying,
   "CountryCode"     character varying,
   "CreatedAt"       timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_page   INT := GREATEST(p_page, 1);
    v_limit  INT := GREATEST(LEAST(p_limit, 500), 1);
    v_offset INT := (v_page - 1) * v_limit;
    v_total  BIGINT;
    v_table_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'fiscal' AND table_name = 'Record'
    ) INTO v_table_exists;

    IF NOT v_table_exists THEN
        RETURN;
    END IF;

    EXECUTE format(
        'SELECT COUNT(*) FROM fiscal."Record" WHERE "CompanyId" = $1 AND "BranchId" = $2'
        || CASE WHEN p_fecha_desde IS NOT NULL THEN ' AND "CreatedAt"::DATE >= $3' ELSE '' END
        || CASE WHEN p_fecha_hasta IS NOT NULL THEN ' AND "CreatedAt"::DATE <= $4' ELSE '' END
    )
    INTO v_total
    USING p_company_id, p_branch_id, p_fecha_desde, p_fecha_hasta;

    RETURN QUERY EXECUTE format(
        'SELECT $5::BIGINT AS "TotalCount",'
        || ' "FiscalRecordId"::BIGINT, "InvoiceId", "InvoiceNumber"::VARCHAR(50),'
        || ' "InvoiceDate"::DATE, "InvoiceType"::VARCHAR(20),'
        || ' "RecordHash"::VARCHAR(64), "SentToAuthority"::BOOLEAN,'
        || ' "AuthorityStatus"::VARCHAR(50), "CountryCode"::VARCHAR(3), "CreatedAt"'
        || ' FROM fiscal."Record"'
        || ' WHERE "CompanyId" = $1 AND "BranchId" = $2'
        || CASE WHEN p_fecha_desde IS NOT NULL THEN ' AND "CreatedAt"::DATE >= $3' ELSE '' END
        || CASE WHEN p_fecha_hasta IS NOT NULL THEN ' AND "CreatedAt"::DATE <= $4' ELSE '' END
        || ' ORDER BY "CreatedAt" DESC'
        || ' LIMIT $6 OFFSET $7'
    )
    USING p_company_id, p_branch_id, p_fecha_desde, p_fecha_hasta, v_total, v_limit, v_offset;
END;
$function$;

-- ============================================================
-- 4. usp_audit_log_getbyid
-- Desajuste: OldValues/NewValues character varying -> text
--            (audit.AuditLog.OldValues=text, NewValues=text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_audit_log_getbyid(bigint) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_audit_log_getbyid(p_audit_log_id bigint)
 RETURNS TABLE(
   "AuditLogId"  bigint,
   "CompanyId"   integer,
   "BranchId"    integer,
   "UserId"      integer,
   "UserName"    character varying,
   "ModuleName"  character varying,
   "EntityName"  character varying,
   "EntityId"    character varying,
   "ActionType"  character varying,
   "Summary"     character varying,
   "OldValues"   text,
   "NewValues"   text,
   "IpAddress"   character varying,
   "CreatedAt"   timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."AuditLogId",
           a."CompanyId",
           a."BranchId",
           a."UserId",
           a."UserName",
           a."ModuleName",
           a."EntityName",
           a."EntityId",
           a."ActionType",
           a."Summary",
           a."OldValues",
           a."NewValues",
           a."IpAddress",
           a."CreatedAt"
    FROM   audit."AuditLog" a
    WHERE  a."AuditLogId" = p_audit_log_id;
END;
$function$;

-- ============================================================
-- 5. usp_bank_movement_create
-- Desajuste: movementId integer -> bigint (fin.BankMovement.BankMovementId = bigint)
-- Nota: "Resultado" integer y "Mensaje" varchar son intencionales (write function pattern)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_bank_movement_create(bigint, character varying, smallint, numeric, numeric, character varying, character varying, character varying, character varying, character varying, character varying, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_bank_movement_create(
    p_bank_account_id      bigint,
    p_movement_type        character varying,
    p_movement_sign        smallint,
    p_amount               numeric,
    p_net_amount           numeric,
    p_reference_no         character varying DEFAULT NULL::character varying,
    p_beneficiary          character varying DEFAULT NULL::character varying,
    p_concept              character varying DEFAULT NULL::character varying,
    p_category_code        character varying DEFAULT NULL::character varying,
    p_related_document_no  character varying DEFAULT NULL::character varying,
    p_related_document_type character varying DEFAULT NULL::character varying,
    p_created_by_user_id   integer           DEFAULT NULL::integer
)
 RETURNS TABLE(
   "Resultado"   integer,
   "Mensaje"     character varying,
   "movementId"  bigint,
   "newBalance"  numeric
 )
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_balance   NUMERIC(18,2);
    v_current_available NUMERIC(18,2);
    v_new_balance       NUMERIC(18,2);
    v_new_available     NUMERIC(18,2);
    v_movement_id       BIGINT;
BEGIN
    SELECT "Balance","AvailableBalance" INTO v_current_balance,v_current_available
    FROM fin."BankAccount" WHERE "BankAccountId"=p_bank_account_id FOR UPDATE;

    v_new_balance    := ROUND(v_current_balance+p_net_amount,2);
    v_new_available  := ROUND(COALESCE(v_current_available,v_current_balance)+p_net_amount,2);

    UPDATE fin."BankAccount"
    SET "Balance"=v_new_balance,"AvailableBalance"=v_new_available,
        "UpdatedAt"=NOW() AT TIME ZONE 'UTC'
    WHERE "BankAccountId"=p_bank_account_id;

    INSERT INTO fin."BankMovement" (
        "BankAccountId","MovementDate","MovementType","MovementSign",
        "Amount","NetAmount","ReferenceNo","Beneficiary","Concept","CategoryCode",
        "RelatedDocumentNo","RelatedDocumentType","BalanceAfter","CreatedByUserId"
    )
    VALUES (
        p_bank_account_id,NOW() AT TIME ZONE 'UTC',p_movement_type,p_movement_sign,
        p_amount,p_net_amount,p_reference_no,p_beneficiary,p_concept,p_category_code,
        p_related_document_no,p_related_document_type,v_new_balance,p_created_by_user_id
    )
    RETURNING "BankMovementId" INTO v_movement_id;

    RETURN QUERY SELECT 1, v_new_balance::TEXT::VARCHAR(500), v_movement_id, v_new_balance;
END;
$function$;

-- ============================================================
-- 6. usp_cfg_entityimage_link
-- Desajuste: entityImageId integer -> bigint, mediaAssetId integer -> bigint
--            (cfg.EntityImage.EntityImageId=bigint, cfg.EntityImage.MediaAssetId=bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_link(integer, integer, character varying, integer, integer, character varying, integer, boolean, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_cfg_entityimage_link(
    p_company_id     integer,
    p_branch_id      integer,
    p_entity_type    character varying,
    p_entity_id      integer,
    p_media_asset_id integer,
    p_role_code      character varying DEFAULT NULL::character varying,
    p_sort_order     integer           DEFAULT 0,
    p_is_primary     boolean           DEFAULT false,
    p_actor_user_id  integer           DEFAULT NULL::integer
)
 RETURNS TABLE(
   "entityImageId"  bigint,
   "entityType"     character varying,
   "entityId"       integer,
   "mediaAssetId"   bigint,
   "roleCode"       character varying,
   "sortOrder"      integer,
   "isPrimary"      boolean,
   "publicUrl"      character varying,
   "mimeType"       character varying
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_is_primary THEN
        UPDATE cfg."EntityImage"
        SET "IsPrimary" = FALSE,
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedByUserId" = p_actor_user_id
        WHERE "CompanyId" = p_company_id AND "BranchId" = p_branch_id
          AND "EntityType" = p_entity_type AND "EntityId" = p_entity_id
          AND "IsDeleted" = FALSE AND "IsActive" = TRUE;
    END IF;

    INSERT INTO cfg."EntityImage" (
        "CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId",
        "RoleCode", "SortOrder", "IsPrimary", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_branch_id, p_entity_type, p_entity_id, p_media_asset_id,
        p_role_code, p_sort_order, p_is_primary, p_actor_user_id, p_actor_user_id
    )
    ON CONFLICT ("CompanyId", "BranchId", "EntityType", "EntityId", "MediaAssetId")
    DO UPDATE SET
        "RoleCode"  = EXCLUDED."RoleCode",
        "SortOrder" = EXCLUDED."SortOrder",
        "IsPrimary" = CASE WHEN p_is_primary THEN TRUE ELSE cfg."EntityImage"."IsPrimary" END,
        "IsActive"  = TRUE,
        "IsDeleted" = FALSE,
        "UpdatedAt" = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserId" = p_actor_user_id;

    RETURN QUERY
    SELECT ei."EntityImageId"::BIGINT, ei."EntityType", ei."EntityId",
           ei."MediaAssetId"::BIGINT, ei."RoleCode", ei."SortOrder",
           ei."IsPrimary", ma."PublicUrl", ma."MimeType"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId" = p_company_id AND ei."BranchId" = p_branch_id
      AND ei."EntityType" = p_entity_type AND ei."EntityId" = p_entity_id
      AND ei."MediaAssetId" = p_media_asset_id
      AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
      AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY ei."EntityImageId" DESC LIMIT 1;
END;
$function$;

-- ============================================================
-- 7. usp_cfg_entityimage_list
-- Desajuste: entityImageId integer -> bigint, mediaAssetId integer -> bigint
--            (cfg.EntityImage.EntityImageId=bigint, cfg.EntityImage.MediaAssetId=bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_cfg_entityimage_list(integer, integer, character varying, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_cfg_entityimage_list(
    p_company_id  integer,
    p_branch_id   integer,
    p_entity_type character varying,
    p_entity_id   integer
)
 RETURNS TABLE(
   "entityImageId"    bigint,
   "entityType"       character varying,
   "entityId"         integer,
   "mediaAssetId"     bigint,
   "roleCode"         character varying,
   "sortOrder"        integer,
   "isPrimary"        boolean,
   "publicUrl"        character varying,
   "originalFileName" character varying,
   "mimeType"         character varying,
   "fileSizeBytes"    bigint,
   "altText"          character varying,
   "createdAt"        timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ei."EntityImageId"::BIGINT, ei."EntityType", ei."EntityId",
           ei."MediaAssetId"::BIGINT, ei."RoleCode", ei."SortOrder",
           ei."IsPrimary", ma."PublicUrl", ma."OriginalFileName", ma."MimeType",
           ma."FileSizeBytes", ma."AltText", ma."CreatedAt"
    FROM cfg."EntityImage" ei
    INNER JOIN cfg."MediaAsset" ma ON ma."MediaAssetId" = ei."MediaAssetId"
    WHERE ei."CompanyId" = p_company_id AND ei."BranchId" = p_branch_id
      AND ei."EntityType" = p_entity_type AND ei."EntityId" = p_entity_id
      AND ei."IsDeleted" = FALSE AND ei."IsActive" = TRUE
      AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY CASE WHEN ei."IsPrimary" THEN 0 ELSE 1 END, ei."SortOrder", ei."EntityImageId";
END;
$function$;

-- ============================================================
-- 8. usp_cfg_fiscal_getlatestrecord
-- Desajuste: XmlContent/DigitalSignature/AuthorityResponse character varying -> text
--            (fiscal.Record: XmlContent=text, DigitalSignature=text, AuthorityResponse=text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_cfg_fiscal_getlatestrecord(integer, integer, character varying) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_cfg_fiscal_getlatestrecord(
    p_empresa_id   integer,
    p_sucursal_id  integer,
    p_country_code character varying
)
 RETURNS TABLE(
   "Id"                  bigint,
   "InvoiceId"           integer,
   "CountryCode"         character varying,
   "InvoiceType"         character varying,
   "XmlContent"          text,
   "RecordHash"          character varying,
   "PreviousRecordHash"  character varying,
   "DigitalSignature"    text,
   "QRCodeData"          character varying,
   "SentToAuthority"     boolean,
   "AuthorityResponse"   text,
   "CreatedAt"           timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        fr."FiscalRecordId", fr."InvoiceId", fr."CountryCode"::VARCHAR,
        fr."InvoiceType", fr."XmlContent",
        fr."RecordHash", fr."PreviousRecordHash",
        fr."DigitalSignature", fr."QRCodeData",
        fr."SentToAuthority", fr."AuthorityResponse",
        fr."CreatedAt"
    FROM fiscal."Record" fr
    WHERE fr."CompanyId"   = p_empresa_id
      AND fr."BranchId"    = p_sucursal_id
      AND fr."CountryCode" = p_country_code
    ORDER BY fr."FiscalRecordId" DESC
    LIMIT 1;
END;
$function$;

-- ============================================================
-- 9. usp_cfg_mediaasset_getbyid
-- Desajuste: mediaAssetId integer -> bigint (cfg.MediaAsset.MediaAssetId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_getbyid(integer, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_cfg_mediaasset_getbyid(
    p_company_id     integer,
    p_branch_id      integer,
    p_media_asset_id integer
)
 RETURNS TABLE(
   "mediaAssetId"     bigint,
   "storageKey"       character varying,
   "publicUrl"        character varying,
   "mimeType"         character varying,
   "originalFileName" character varying,
   "fileSizeBytes"    bigint,
   "isActive"         boolean,
   "isDeleted"        boolean
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ma."MediaAssetId"::BIGINT, ma."StorageKey", ma."PublicUrl", ma."MimeType",
           ma."OriginalFileName", ma."FileSizeBytes", ma."IsActive", ma."IsDeleted"
    FROM cfg."MediaAsset" ma
    WHERE ma."CompanyId" = p_company_id AND ma."BranchId" = p_branch_id
      AND ma."MediaAssetId" = p_media_asset_id
    LIMIT 1;
END;
$function$;

-- ============================================================
-- 10. usp_cfg_mediaasset_getbystoragekey
-- Desajuste: mediaAssetId integer -> bigint (cfg.MediaAsset.MediaAssetId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_getbystoragekey(integer, integer, character varying) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_cfg_mediaasset_getbystoragekey(
    p_company_id  integer,
    p_branch_id   integer,
    p_storage_key character varying
)
 RETURNS TABLE(
   "mediaAssetId" bigint
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ma."MediaAssetId"::BIGINT
    FROM cfg."MediaAsset" ma
    WHERE ma."CompanyId" = p_company_id AND ma."BranchId" = p_branch_id
      AND ma."StorageKey" = p_storage_key
      AND ma."IsDeleted" = FALSE AND ma."IsActive" = TRUE
    ORDER BY ma."MediaAssetId" DESC LIMIT 1;
END;
$function$;

-- ============================================================
-- 11. usp_cfg_mediaasset_insert
-- Desajuste: mediaAssetId integer -> bigint (cfg.MediaAsset.MediaAssetId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_cfg_mediaasset_insert(integer, integer, character varying, character varying, character varying, character varying, character varying, bigint, character varying, character varying, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_cfg_mediaasset_insert(
    p_company_id        integer,
    p_branch_id         integer,
    p_storage_key       character varying,
    p_public_url        character varying,
    p_original_file_name character varying DEFAULT NULL::character varying,
    p_mime_type         character varying  DEFAULT NULL::character varying,
    p_file_extension    character varying  DEFAULT NULL::character varying,
    p_file_size_bytes   bigint             DEFAULT 0,
    p_checksum_sha256   character varying  DEFAULT NULL::character varying,
    p_alt_text          character varying  DEFAULT NULL::character varying,
    p_actor_user_id     integer            DEFAULT NULL::integer
)
 RETURNS TABLE(
   "mediaAssetId" bigint
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    INSERT INTO cfg."MediaAsset" (
        "CompanyId", "BranchId", "StorageProvider", "StorageKey", "PublicUrl",
        "OriginalFileName", "MimeType", "FileExtension", "FileSizeBytes",
        "ChecksumSha256", "AltText", "CreatedByUserId", "UpdatedByUserId"
    )
    VALUES (
        p_company_id, p_branch_id, 'LOCAL', p_storage_key, p_public_url,
        p_original_file_name, p_mime_type, p_file_extension, p_file_size_bytes,
        p_checksum_sha256, p_alt_text, p_actor_user_id, p_actor_user_id
    )
    RETURNING "MediaAssetId"::BIGINT;
END;
$function$;

-- ============================================================
-- 12. usp_fiscal_export_declaration
-- Desajuste: AuthorityResponse character varying -> text
--            (fiscal.TaxDeclaration.AuthorityResponse = text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_fiscal_export_declaration(integer, bigint) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_fiscal_export_declaration(
    p_company_id     integer,
    p_declaration_id bigint
)
 RETURNS TABLE(
   "DeclarationId"       bigint,
   "CompanyId"           integer,
   "BranchId"            integer,
   "CountryCode"         character varying,
   "DeclarationType"     character varying,
   "PeriodCode"          character varying,
   "PeriodStart"         date,
   "PeriodEnd"           date,
   "SalesBase"           numeric,
   "SalesTax"            numeric,
   "PurchasesBase"       numeric,
   "PurchasesTax"        numeric,
   "TaxableBase"         numeric,
   "TaxAmount"           numeric,
   "WithholdingsCredit"  numeric,
   "PreviousBalance"     numeric,
   "NetPayable"          numeric,
   "Status"              character varying,
   "SubmittedAt"         timestamp without time zone,
   "SubmittedFile"       character varying,
   "AuthorityResponse"   text,
   "PaidAt"              timestamp without time zone,
   "PaymentReference"    character varying,
   "JournalEntryId"      bigint,
   "Notes"               character varying,
   "CreatedBy"           character varying,
   "UpdatedBy"           character varying,
   "CreatedAt"           timestamp without time zone,
   "UpdatedAt"           timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT "DeclarationId", "CompanyId", "BranchId", "CountryCode",
           "DeclarationType", "PeriodCode", "PeriodStart", "PeriodEnd",
           "SalesBase", "SalesTax", "PurchasesBase", "PurchasesTax",
           "TaxableBase", "TaxAmount", "WithholdingsCredit",
           "PreviousBalance", "NetPayable", "Status",
           "SubmittedAt", "SubmittedFile", "AuthorityResponse",
           "PaidAt", "PaymentReference", "JournalEntryId", "Notes",
           "CreatedBy", "UpdatedBy", "CreatedAt", "UpdatedAt"
    FROM fiscal."TaxDeclaration"
    WHERE "CompanyId"     = p_company_id
      AND "DeclarationId" = p_declaration_id;
END;
$function$;

-- ============================================================
-- 13. usp_hr_committee_getmeetings
-- Desajuste: TopicsSummary/ActionItems character varying -> text
--            (hr.SafetyCommitteeMeeting: TopicsSummary=text, ActionItems=text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_hr_committee_getmeetings(integer, integer, date, date, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_hr_committee_getmeetings(
    p_safety_committee_id integer,
    p_company_id          integer,
    p_from_date           date    DEFAULT NULL::date,
    p_to_date             date    DEFAULT NULL::date,
    p_page                integer DEFAULT 1,
    p_limit               integer DEFAULT 50
)
 RETURNS TABLE(
   p_total_count        bigint,
   "MeetingId"          integer,
   "SafetyCommitteeId"  integer,
   "MeetingDate"        date,
   "MinutesUrl"         character varying,
   "TopicsSummary"      text,
   "ActionItems"        text,
   "CreatedAt"          timestamp without time zone,
   "CommitteeName"      character varying
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF p_page  < 1   THEN p_page  := 1;   END IF;
    IF p_limit < 1   THEN p_limit := 50;  END IF;
    IF p_limit > 500 THEN p_limit := 500; END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."SafetyCommittee"
        WHERE "SafetyCommitteeId" = p_safety_committee_id AND "CompanyId" = p_company_id
    ) THEN
        RETURN;
    END IF;

    RETURN QUERY
    SELECT
        COUNT(*) OVER()         AS p_total_count,
        m."MeetingId",
        m."SafetyCommitteeId",
        m."MeetingDate",
        m."MinutesUrl",
        m."TopicsSummary",
        m."ActionItems",
        m."CreatedAt",
        sc."CommitteeName"
    FROM hr."SafetyCommitteeMeeting" m
    INNER JOIN hr."SafetyCommittee" sc ON sc."SafetyCommitteeId" = m."SafetyCommitteeId"
    WHERE m."SafetyCommitteeId" = p_safety_committee_id
      AND (p_from_date IS NULL OR m."MeetingDate" >= p_from_date)
      AND (p_to_date   IS NULL OR m."MeetingDate" <= p_to_date)
    ORDER BY m."MeetingDate" DESC
    LIMIT p_limit OFFSET (p_page - 1) * p_limit;
END;
$function$;

-- ============================================================
-- 14. usp_hr_documenttemplate_get
-- Desajuste: ContentMD character varying -> text
--            (hr.DocumentTemplate.ContentMD = text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_hr_documenttemplate_get(integer, character varying) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_get(
    p_company_id    integer,
    p_template_code character varying
)
 RETURNS TABLE(
   "TemplateId"    integer,
   "TemplateCode"  character varying,
   "TemplateName"  character varying,
   "TemplateType"  character varying,
   "CountryCode"   character,
   "PayrollCode"   character varying,
   "ContentMD"     text,
   "IsDefault"     boolean,
   "IsSystem"      boolean,
   "IsActive"      boolean,
   "CreatedAt"     timestamp without time zone,
   "UpdatedAt"     timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId",
        t."TemplateCode",
        t."TemplateName",
        t."TemplateType",
        t."CountryCode",
        t."PayrollCode",
        t."ContentMD",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."CreatedAt",
        t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId"    = p_company_id
      AND t."TemplateCode" = p_template_code;
END;
$function$;

-- ============================================================
-- 15. usp_hr_payroll_getdraftsummary
-- Desajuste: BatchId integer -> bigint (hr.PayrollBatch.BatchId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getdraftsummary(integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary(p_batch_id integer)
 RETURNS TABLE(
   "BatchId"            bigint,
   "CompanyId"          integer,
   "BranchId"           integer,
   "PayrollCode"        character varying,
   "FromDate"           date,
   "ToDate"             date,
   "Status"             character varying,
   "TotalEmployees"     integer,
   "TotalGross"         numeric,
   "TotalDeductions"    numeric,
   "TotalNet"           numeric,
   "CreatedBy"          integer,
   "CreatedAt"          timestamp without time zone,
   "ApprovedBy"         integer,
   "ApprovedAt"         timestamp without time zone,
   "PrevBatchId"        integer,
   "PrevTotalGross"     numeric,
   "PrevTotalDeductions" numeric,
   "PrevTotalNet"       numeric,
   "NetChangePercent"   numeric
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY SELECT * FROM public.usp_hr_payroll_getdraftsummary_header(p_batch_id);
END;
$function$;

-- ============================================================
-- 16. usp_hr_payroll_getdraftsummary_header
-- Desajuste: BatchId integer -> bigint (hr.PayrollBatch.BatchId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_hr_payroll_getdraftsummary_header(integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_hr_payroll_getdraftsummary_header(p_batch_id integer)
 RETURNS TABLE(
   "BatchId"            bigint,
   "CompanyId"          integer,
   "BranchId"           integer,
   "PayrollCode"        character varying,
   "FromDate"           date,
   "ToDate"             date,
   "Status"             character varying,
   "TotalEmployees"     integer,
   "TotalGross"         numeric,
   "TotalDeductions"    numeric,
   "TotalNet"           numeric,
   "CreatedBy"          integer,
   "CreatedAt"          timestamp without time zone,
   "ApprovedBy"         integer,
   "ApprovedAt"         timestamp without time zone,
   "PrevBatchId"        integer,
   "PrevTotalGross"     numeric,
   "PrevTotalDeductions" numeric,
   "PrevTotalNet"       numeric,
   "NetChangePercent"   numeric
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH "BatchAgg" AS (
        SELECT
            bl."BatchId",
            COUNT(DISTINCT bl."EmployeeCode")::INTEGER AS "TotalEmployees",
            COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total" ELSE 0 END), 0) AS "TotalGross",
            COALESCE(SUM(CASE WHEN bl."ConceptType" = 'DEDUCCION' THEN bl."Total" ELSE 0 END), 0) AS "TotalDeductions",
            COALESCE(SUM(CASE WHEN bl."ConceptType" IN ('ASIGNACION', 'BONO') THEN bl."Total"
                              WHEN bl."ConceptType" = 'DEDUCCION' THEN -bl."Total"
                              ELSE 0 END), 0) AS "TotalNet"
        FROM hr."PayrollBatchLine" bl
        WHERE bl."BatchId" = p_batch_id
        GROUP BY bl."BatchId"
    )
    SELECT
        b."BatchId"::BIGINT,
        b."CompanyId",
        1::INTEGER                  AS "BranchId",
        b."PayrollCode",
        b."FromDate",
        b."ToDate",
        b."Status",
        COALESCE(ba."TotalEmployees", 0),
        COALESCE(ba."TotalGross", 0),
        COALESCE(ba."TotalDeductions", 0),
        COALESCE(ba."TotalNet", 0),
        b."CreatedByUserId"         AS "CreatedBy",
        b."CreatedAt",
        b."UpdatedByUserId"         AS "ApprovedBy",
        NULL::TIMESTAMP             AS "ApprovedAt",
        NULL::INTEGER               AS "PrevBatchId",
        0::NUMERIC                  AS "PrevTotalGross",
        0::NUMERIC                  AS "PrevTotalDeductions",
        0::NUMERIC                  AS "PrevTotalNet",
        0::NUMERIC                  AS "NetChangePercent"
    FROM hr."PayrollBatch" b
    LEFT JOIN "BatchAgg" ba ON ba."BatchId" = b."BatchId"
    WHERE b."BatchId" = p_batch_id
      AND b."IsDeleted" = FALSE;
END;
$function$;

-- ============================================================
-- 17. usp_inventario_getbycodigo
-- Desajuste: ProductId integer -> bigint (master.Product.ProductId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_inventario_getbycodigo(character varying) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_inventario_getbycodigo(p_codigo character varying)
 RETURNS TABLE(
   "ProductId"          bigint,
   "ProductCode"        character varying,
   "Referencia"         character varying,
   "Categoria"          character varying,
   "Marca"              character varying,
   "Tipo"               character varying,
   "Unidad"             character varying,
   "Clase"              character varying,
   "ProductName"        character varying,
   "StockQty"           double precision,
   "VENTA"              double precision,
   "MINIMO"             double precision,
   "MAXIMO"             double precision,
   "CostPrice"          double precision,
   "SalesPrice"         double precision,
   "PORCENTAJE"         double precision,
   "UBICACION"          character varying,
   "Co_Usuario"         character varying,
   "Linea"              character varying,
   "N_PARTE"            character varying,
   "Barra"              character varying,
   "IsService"          boolean,
   "IsActive"           boolean,
   "CompanyId"          integer,
   "CODIGO"             character varying,
   "DESCRIPCION"        character varying,
   "EXISTENCIA"         double precision,
   "PRECIO"             double precision,
   "COSTO"              double precision,
   "Servicio"           boolean,
   "DescripcionCompleta" character varying
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p."ProductId"::BIGINT,
        p."ProductCode",
        p."Referencia",
        p."Categoria",
        p."Marca",
        p."Tipo",
        p."Unidad",
        p."Clase",
        p."ProductName",
        p."StockQty",
        p."VENTA",
        p."MINIMO",
        p."MAXIMO",
        p."CostPrice",
        p."SalesPrice",
        p."PORCENTAJE",
        p."UBICACION",
        p."Co_Usuario",
        p."Linea",
        p."N_PARTE",
        p."Barra",
        p."IsService",
        p."IsActive",
        p."CompanyId",
        p."ProductCode"        AS "CODIGO",
        p."ProductName"        AS "DESCRIPCION",
        p."StockQty"           AS "EXISTENCIA",
        p."SalesPrice"         AS "PRECIO",
        p."CostPrice"          AS "COSTO",
        p."IsService"          AS "Servicio",
        TRIM(BOTH FROM
            COALESCE(RTRIM(p."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(p."Tipo", '')) <> '' THEN ' ' || RTRIM(p."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."ProductName", '')) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Marca", '')) <> '' THEN ' ' || RTRIM(p."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Clase", '')) <> '' THEN ' ' || RTRIM(p."Clase") ELSE '' END
        )                      AS "DescripcionCompleta"
    FROM master."Product" p
    WHERE p."ProductCode" = p_codigo
      AND COALESCE(p."IsDeleted", FALSE) = FALSE;
END;
$function$;

-- ============================================================
-- 18. usp_inventario_list
-- Desajuste: ProductId integer -> bigint (master.Product.ProductId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_inventario_list(character varying, character varying, character varying, character varying, character varying, character varying, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_inventario_list(
    p_search    character varying DEFAULT NULL::character varying,
    p_categoria character varying DEFAULT NULL::character varying,
    p_marca     character varying DEFAULT NULL::character varying,
    p_linea     character varying DEFAULT NULL::character varying,
    p_tipo      character varying DEFAULT NULL::character varying,
    p_clase     character varying DEFAULT NULL::character varying,
    p_page      integer           DEFAULT 1,
    p_limit     integer           DEFAULT 50
)
 RETURNS TABLE(
   "TotalCount"         bigint,
   "ProductId"          bigint,
   "ProductCode"        character varying,
   "Referencia"         character varying,
   "Categoria"          character varying,
   "Marca"              character varying,
   "Tipo"               character varying,
   "Unidad"             character varying,
   "Clase"              character varying,
   "ProductName"        character varying,
   "StockQty"           double precision,
   "VENTA"              double precision,
   "MINIMO"             double precision,
   "MAXIMO"             double precision,
   "CostPrice"          double precision,
   "SalesPrice"         double precision,
   "PORCENTAJE"         double precision,
   "UBICACION"          character varying,
   "Co_Usuario"         character varying,
   "Linea"              character varying,
   "N_PARTE"            character varying,
   "Barra"              character varying,
   "IsService"          boolean,
   "IsActive"           boolean,
   "CompanyId"          integer,
   "CODIGO"             character varying,
   "DESCRIPCION"        character varying,
   "EXISTENCIA"         double precision,
   "PRECIO"             double precision,
   "COSTO"              double precision,
   "Servicio"           boolean,
   "DescripcionCompleta" character varying
 )
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1  THEN v_limit := 50;  END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM master."Product"
    WHERE COALESCE("IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR
           "ProductCode" LIKE v_search OR "Referencia" LIKE v_search OR
           "ProductName" LIKE v_search OR "Categoria" LIKE v_search OR
           "Tipo" LIKE v_search OR "Marca" LIKE v_search OR
           "Clase" LIKE v_search OR "Linea" LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR "Categoria" = p_categoria)
      AND (p_marca IS NULL OR TRIM(p_marca) = '' OR "Marca" = p_marca)
      AND (p_linea IS NULL OR TRIM(p_linea) = '' OR "Linea" = p_linea)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR "Tipo" = p_tipo)
      AND (p_clase IS NULL OR TRIM(p_clase) = '' OR "Clase" = p_clase);

    RETURN QUERY
    SELECT
        v_total                     AS "TotalCount",
        p."ProductId"::BIGINT,
        p."ProductCode",
        p."Referencia",
        p."Categoria",
        p."Marca",
        p."Tipo",
        p."Unidad",
        p."Clase",
        p."ProductName",
        p."StockQty",
        p."VENTA",
        p."MINIMO",
        p."MAXIMO",
        p."CostPrice",
        p."SalesPrice",
        p."PORCENTAJE",
        p."UBICACION",
        p."Co_Usuario",
        p."Linea",
        p."N_PARTE",
        p."Barra",
        p."IsService",
        p."IsActive",
        p."CompanyId",
        p."ProductCode"             AS "CODIGO",
        p."ProductName"             AS "DESCRIPCION",
        p."StockQty"                AS "EXISTENCIA",
        p."SalesPrice"              AS "PRECIO",
        p."CostPrice"               AS "COSTO",
        p."IsService"               AS "Servicio",
        TRIM(BOTH FROM
            COALESCE(RTRIM(p."Categoria"), '') ||
            CASE WHEN RTRIM(COALESCE(p."Tipo", '')) <> '' THEN ' ' || RTRIM(p."Tipo") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."ProductName", '')) <> '' THEN ' ' || RTRIM(p."ProductName") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Marca", '')) <> '' THEN ' ' || RTRIM(p."Marca") ELSE '' END ||
            CASE WHEN RTRIM(COALESCE(p."Clase", '')) <> '' THEN ' ' || RTRIM(p."Clase") ELSE '' END
        )                           AS "DescripcionCompleta"
    FROM master."Product" p
    WHERE COALESCE(p."IsDeleted", FALSE) = FALSE
      AND (v_search IS NULL OR
           p."ProductCode" LIKE v_search OR p."Referencia" LIKE v_search OR
           p."ProductName" LIKE v_search OR p."Categoria" LIKE v_search OR
           p."Tipo" LIKE v_search OR p."Marca" LIKE v_search OR
           p."Clase" LIKE v_search OR p."Linea" LIKE v_search)
      AND (p_categoria IS NULL OR TRIM(p_categoria) = '' OR p."Categoria" = p_categoria)
      AND (p_marca IS NULL OR TRIM(p_marca) = '' OR p."Marca" = p_marca)
      AND (p_linea IS NULL OR TRIM(p_linea) = '' OR p."Linea" = p_linea)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR p."Tipo" = p_tipo)
      AND (p_clase IS NULL OR TRIM(p_clase) = '' OR p."Clase" = p_clase)
    ORDER BY p."ProductCode"
    LIMIT v_limit OFFSET v_offset;
END;
$function$;

-- ============================================================
-- 19. usp_pay_companyconfig_listbycompany
-- Desajuste: ExtraConfig character varying -> text
--            (pay.CompanyPaymentConfig.ExtraConfig = text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_pay_companyconfig_listbycompany(integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_pay_companyconfig_listbycompany(
    p_company_id integer,
    p_branch_id  integer DEFAULT NULL::integer
)
 RETURNS TABLE(
   "Id"               integer,
   "EmpresaId"        integer,
   "SucursalId"       integer,
   "CountryCode"      character varying,
   "ProviderId"       integer,
   "ProviderCode"     character varying,
   "ProviderName"     character varying,
   "ProviderType"     character varying,
   "Environment"      character varying,
   "ClientId"         character varying,
   "ClientSecret"     character varying,
   "MerchantId"       character varying,
   "TerminalId"       character varying,
   "IntegratorId"     character varying,
   "CertificatePath"  character varying,
   "ExtraConfig"      text,
   "AutoCapture"      boolean,
   "AllowRefunds"     boolean,
   "MaxRefundDays"    integer,
   "IsActive"         boolean,
   "CreatedAt"        timestamp without time zone,
   "UpdatedAt"        timestamp without time zone
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT cc."Id", cc."EmpresaId", cc."SucursalId", cc."CountryCode"::VARCHAR,
           cc."ProviderId", p."Code"::VARCHAR, p."Name"::VARCHAR, p."ProviderType"::VARCHAR,
           cc."Environment"::VARCHAR, cc."ClientId"::VARCHAR, cc."ClientSecret"::VARCHAR,
           cc."MerchantId"::VARCHAR, cc."TerminalId"::VARCHAR, cc."IntegratorId"::VARCHAR,
           cc."CertificatePath"::VARCHAR, cc."ExtraConfig",
           cc."AutoCapture", cc."AllowRefunds", cc."MaxRefundDays",
           cc."IsActive", cc."CreatedAt", cc."UpdatedAt"
    FROM pay."CompanyPaymentConfig" cc
    INNER JOIN pay."PaymentProviders" p ON p."Id" = cc."ProviderId"
    WHERE cc."EmpresaId" = p_company_id
      AND (p_branch_id IS NULL OR cc."SucursalId" = p_branch_id)
    ORDER BY p."Name";
END;
$function$;

-- ============================================================
-- 20. usp_rest_admin_compralinea_delete
-- Desajuste: ingredientProductId integer -> bigint
--            (rest.MenuRecipe/PurchaseLine.IngredientProductId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_rest_admin_compralinea_delete(integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_delete(
    p_compra_id  integer,
    p_detalle_id integer
)
 RETURNS TABLE(
   "ingredientProductId" bigint,
   quantity              numeric
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pl."IngredientProductId"::BIGINT, pl."Quantity"
    FROM rest."PurchaseLine" pl
    WHERE pl."PurchaseLineId" = p_detalle_id
      AND pl."PurchaseId" = p_compra_id
    LIMIT 1;

    DELETE FROM rest."PurchaseLine"
    WHERE "PurchaseLineId" = p_detalle_id
      AND "PurchaseId" = p_compra_id;
END;
$function$;

-- ============================================================
-- 21. usp_rest_admin_compralinea_getprev
-- Desajuste: ingredientProductId integer -> bigint
--            (rest.PurchaseLine.IngredientProductId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_rest_admin_compralinea_getprev(integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_rest_admin_compralinea_getprev(
    p_id         integer,
    p_compra_id  integer
)
 RETURNS TABLE(
   "ingredientProductId" bigint,
   quantity              numeric
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT pl."IngredientProductId"::BIGINT, pl."Quantity"
    FROM rest."PurchaseLine" pl
    WHERE pl."PurchaseLineId" = p_id
      AND pl."PurchaseId" = p_compra_id
    LIMIT 1;
END;
$function$;

-- ============================================================
-- 22. usp_rest_orderticketline_getbyid
-- Desajuste: productId integer -> bigint
--            (rest.OrderTicketLine.ProductId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_rest_orderticketline_getbyid(integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_rest_orderticketline_getbyid(
    p_pedido_id integer,
    p_item_id   integer
)
 RETURNS TABLE(
   "itemId"      integer,
   "lineNumber"  integer,
   "countryCode" character varying,
   "productId"   bigint,
   "productCode" character varying,
   nombre        character varying,
   cantidad      numeric,
   "unitPrice"   numeric,
   "taxCode"     character varying,
   "taxRate"     numeric,
   "netAmount"   numeric,
   "taxAmount"   numeric,
   "totalAmount" numeric
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ol."OrderTicketLineId", ol."LineNumber", ol."CountryCode"::VARCHAR,
           ol."ProductId"::BIGINT,
           ol."ProductCode", ol."ProductName", ol."Quantity", ol."UnitPrice",
           ol."TaxCode", ol."TaxRate", ol."NetAmount", ol."TaxAmount", ol."TotalAmount"
    FROM rest."OrderTicketLine" ol
    WHERE ol."OrderTicketId" = p_pedido_id
      AND ol."OrderTicketLineId" = p_item_id
    LIMIT 1;
END;
$function$;

-- ============================================================
-- 23. usp_sec_supervisor_override_consume
-- Desajuste: overrideId integer -> bigint
--            (sec.SupervisorOverride.OverrideId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_override_consume(integer, character varying, character varying, character varying, integer, integer, integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_override_consume(
    p_override_id         integer,
    p_module_code         character varying,
    p_action_code         character varying,
    p_consumed_by_user    character varying DEFAULT NULL::character varying,
    p_source_document_id  integer           DEFAULT NULL::integer,
    p_source_line_id      integer           DEFAULT NULL::integer,
    p_reversal_line_id    integer           DEFAULT NULL::integer
)
 RETURNS TABLE(
   "overrideId" bigint
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    UPDATE sec."SupervisorOverride"
    SET "Status"             = 'CONSUMED',
        "ConsumedAtUtc"      = NOW() AT TIME ZONE 'UTC',
        "ConsumedByUserCode" = p_consumed_by_user,
        "SourceDocumentId"   = p_source_document_id,
        "SourceLineId"       = p_source_line_id,
        "ReversalLineId"     = p_reversal_line_id
    WHERE "OverrideId" = p_override_id
      AND "Status" = 'APPROVED'
      AND UPPER("ModuleCode")::character varying = p_module_code
      AND UPPER("ActionCode")::character varying = p_action_code
    RETURNING "OverrideId"::BIGINT;
END;
$function$;

-- ============================================================
-- 24. usp_sec_supervisor_override_create
-- Desajuste: overrideId integer -> bigint
--            (sec.SupervisorOverride.OverrideId = bigint)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_override_create(character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, text) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_override_create(
    p_module_code           character varying,
    p_action_code           character varying,
    p_status                character varying,
    p_company_id            integer           DEFAULT NULL::integer,
    p_branch_id             integer           DEFAULT NULL::integer,
    p_requested_by_user     character varying DEFAULT NULL::character varying,
    p_supervisor_user_code  character varying DEFAULT NULL::character varying,
    p_reason                character varying DEFAULT NULL::character varying,
    p_payload_json          text              DEFAULT NULL::text
)
 RETURNS TABLE(
   "overrideId" bigint
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    INSERT INTO sec."SupervisorOverride" (
        "ModuleCode", "ActionCode", "Status",
        "CompanyId", "BranchId",
        "RequestedByUserCode", "SupervisorUserCode",
        "Reason", "PayloadJson", "ApprovedAtUtc"
    )
    VALUES (
        p_module_code, p_action_code, p_status,
        p_company_id, p_branch_id,
        p_requested_by_user, p_supervisor_user_code,
        p_reason, p_payload_json, NOW() AT TIME ZONE 'UTC'
    )
    RETURNING "OverrideId"::BIGINT;
END;
$function$;

-- ============================================================
-- 25. usp_sec_user_getavatar
-- Desajuste: Avatar character varying -> text
--            (sec.User.Avatar = text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_sec_user_getavatar(character varying) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_sec_user_getavatar(p_cod_usuario character varying)
 RETURNS TABLE(
   "Avatar" text
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."Avatar"
    FROM   sec."User" u
    WHERE  u."UserCode" = p_cod_usuario
    LIMIT 1;
END;
$function$;

-- ============================================================
-- 26. usp_store_industrytemplate_listattributes
-- Desajuste: listOptions character varying -> text
--            (store.IndustryTemplateAttribute.ListOptions = text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_store_industrytemplate_listattributes(integer) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_store_industrytemplate_listattributes(
    p_company_id integer DEFAULT 1
)
 RETURNS TABLE(
   "templateCode"  character varying,
   key             character varying,
   label           character varying,
   "dataType"      character varying,
   "isRequired"    boolean,
   "defaultValue"  character varying,
   "listOptions"   text,
   "displayGroup"  character varying,
   "sortOrder"     integer
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        ita."TemplateCode"   AS "templateCode",
        ita."AttributeKey"   AS "key",
        ita."AttributeLabel" AS "label",
        ita."DataType"       AS "dataType",
        ita."IsRequired"     AS "isRequired",
        ita."DefaultValue"   AS "defaultValue",
        ita."ListOptions"    AS "listOptions",
        ita."DisplayGroup"   AS "displayGroup",
        ita."SortOrder"      AS "sortOrder"
    FROM store."IndustryTemplateAttribute" ita
    WHERE ita."CompanyId" = p_company_id
      AND ita."IsDeleted" = FALSE
      AND ita."IsActive"  = TRUE
    ORDER BY ita."TemplateCode", ita."SortOrder";
END;
$function$;

-- ============================================================
-- 27. usp_usuarios_getbycodigo
-- Desajuste: Avatar character varying -> text
--            (sec.User.Avatar = text)
-- ============================================================
DROP FUNCTION IF EXISTS public.usp_usuarios_getbycodigo(character varying) CASCADE;

CREATE OR REPLACE FUNCTION public.usp_usuarios_getbycodigo(p_cod_usuario character varying)
 RETURNS TABLE(
   "Cod_Usuario"   character varying,
   "Password"      character varying,
   "Nombre"        character varying,
   "Tipo"          character varying,
   "Updates"       boolean,
   "Addnews"       boolean,
   "Deletes"       boolean,
   "Creador"       boolean,
   "Cambiar"       boolean,
   "PrecioMinimo"  boolean,
   "Credito"       boolean,
   "IsAdmin"       boolean,
   "Avatar"        text
 )
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        u."UserCode"       AS "Cod_Usuario",
        u."PasswordHash"   AS "Password",
        u."UserName"       AS "Nombre",
        u."UserType"       AS "Tipo",
        u."CanUpdate"      AS "Updates",
        u."CanCreate"      AS "Addnews",
        u."CanDelete"      AS "Deletes",
        u."IsCreator"      AS "Creador",
        u."CanChangePwd"   AS "Cambiar",
        u."CanChangePrice" AS "PrecioMinimo",
        u."CanGiveCredit"  AS "Credito",
        u."IsAdmin",
        u."Avatar"
    FROM sec."User" u
    WHERE u."UserCode" = p_cod_usuario AND u."IsDeleted" = FALSE;
END;
$function$;

-- ============================================================
-- FIN DE MIGRACIÃƒâ€œN
-- ============================================================
