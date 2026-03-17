-- usp_sec_auth_consumetoken
DROP FUNCTION IF EXISTS public.usp_sec_auth_consumetoken(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_consumetoken(p_token_hash character varying, p_token_type character varying)
 RETURNS TABLE("UserCode" character varying, "EmailNormalized" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    UPDATE sec."AuthToken"
    SET "ConsumedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE "TokenId" = (
        SELECT "TokenId" FROM sec."AuthToken"
        WHERE "TokenHash" = p_token_hash AND "TokenType" = p_token_type
          AND "ConsumedAtUtc" IS NULL AND "ExpiresAtUtc" >= NOW() AT TIME ZONE 'UTC'
        ORDER BY "TokenId" DESC LIMIT 1
    )
    RETURNING sec."AuthToken"."UserCode", sec."AuthToken"."EmailNormalized";
END;
$function$
;

-- usp_sec_auth_emailexists
DROP FUNCTION IF EXISTS public.usp_sec_auth_emailexists(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_emailexists(p_email_normalized character varying)
 RETURNS TABLE("existsFlag" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS (SELECT 1 FROM sec."AuthIdentity" WHERE "EmailNormalized" = p_email_normalized) THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_sec_auth_getloginsecuritystate
DROP FUNCTION IF EXISTS public.usp_sec_auth_getloginsecuritystate(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_getloginsecuritystate(p_user_code character varying)
 RETURNS TABLE("IsRegistrationPending" boolean, "EmailVerifiedAtUtc" timestamp without time zone, "LockoutUntilUtc" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ai."IsRegistrationPending", ai."EmailVerifiedAtUtc", ai."LockoutUntilUtc"
    FROM sec."AuthIdentity" ai WHERE UPPER(ai."UserCode")::character varying = UPPER(p_user_code)::character varying LIMIT 1;
END;
$function$
;

-- usp_sec_auth_invalidatetokens
DROP FUNCTION IF EXISTS public.usp_sec_auth_invalidatetokens(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_invalidatetokens(p_user_code character varying, p_token_type character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."AuthToken"
    SET "ConsumedAtUtc" = COALESCE("ConsumedAtUtc", NOW() AT TIME ZONE 'UTC')
    WHERE UPPER("UserCode")::character varying = UPPER(p_user_code)::character varying AND "TokenType" = p_token_type AND "ConsumedAtUtc" IS NULL;
END;
$function$
;

-- usp_sec_auth_registerloginfailure
DROP FUNCTION IF EXISTS public.usp_sec_auth_registerloginfailure(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_registerloginfailure(p_user_code character varying, p_ip character varying DEFAULT NULL::character varying, p_max_attempts integer DEFAULT 5, p_lockout_minutes integer DEFAULT 15)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "FailedLoginCount" = COALESCE("FailedLoginCount", 0) + 1,
        "LastFailedLoginAtUtc" = NOW() AT TIME ZONE 'UTC',
        "LastFailedLoginIp" = p_ip,
        "LockoutUntilUtc" = CASE
            WHEN COALESCE("FailedLoginCount", 0) + 1 >= p_max_attempts
              THEN (NOW() AT TIME ZONE 'UTC') + (p_lockout_minutes || ' minutes')::INTERVAL
            ELSE "LockoutUntilUtc"
        END,
        "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode")::character varying = UPPER(p_user_code)::character varying;
END;
$function$
;

-- usp_sec_auth_registerloginsuccess
DROP FUNCTION IF EXISTS public.usp_sec_auth_registerloginsuccess(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_registerloginsuccess(p_user_code character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "FailedLoginCount" = 0, "LastLoginAtUtc" = NOW() AT TIME ZONE 'UTC', "LockoutUntilUtc" = NULL, "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode")::character varying = UPPER(p_user_code)::character varying;
END;
$function$
;

-- usp_sec_auth_registeruser
DROP FUNCTION IF EXISTS public.usp_sec_auth_registeruser(character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_registeruser(p_user_code character varying, p_password_hash character varying, p_nombre character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO "Usuarios" ("Cod_Usuario", "Password", "Nombre", "Tipo", "Updates", "Addnews", "Deletes", "Creador", "Cambiar", "PrecioMinimo", "Credito", "IsAdmin")
    VALUES (p_user_code, p_password_hash, p_nombre, 'USER', TRUE, TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE);
END;
$function$
;

-- usp_sec_auth_resetlockout
DROP FUNCTION IF EXISTS public.usp_sec_auth_resetlockout(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_resetlockout(p_user_code character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "FailedLoginCount" = 0,
        "LockoutUntilUtc" = NULL,
        "PasswordChangedAtUtc" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode")::character varying = UPPER(p_user_code)::character varying;
END;
$function$
;

-- usp_sec_auth_resolvebyidentifier
DROP FUNCTION IF EXISTS public.usp_sec_auth_resolvebyidentifier(character varying, character varying, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_resolvebyidentifier(p_user_code character varying, p_email_normalized character varying, p_is_email boolean)
 RETURNS TABLE("UserCode" character varying, "Email" character varying, "EmailNormalized" character varying, "IsRegistrationPending" boolean, "EmailVerifiedAtUtc" timestamp without time zone)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT ai."UserCode", ai."Email", ai."EmailNormalized", ai."IsRegistrationPending", ai."EmailVerifiedAtUtc"
    FROM sec."AuthIdentity" ai
    WHERE CASE WHEN p_is_email THEN ai."EmailNormalized" = p_email_normalized
               ELSE UPPER(ai."UserCode")::character varying = UPPER(p_user_code)::character varying END
    LIMIT 1;
END;
$function$
;

-- usp_sec_auth_updatepassword
DROP FUNCTION IF EXISTS public.usp_sec_auth_updatepassword(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_updatepassword(p_user_code character varying, p_password_hash character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE "Usuarios" SET "Password" = p_password_hash WHERE UPPER("Cod_Usuario")::character varying = UPPER(p_user_code)::character varying;
END;
$function$
;

-- usp_sec_auth_userexistslegacy
DROP FUNCTION IF EXISTS public.usp_sec_auth_userexistslegacy(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_userexistslegacy(p_user_code character varying)
 RETURNS TABLE("existsFlag" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE WHEN EXISTS (SELECT 1 FROM "Usuarios" WHERE UPPER("Cod_Usuario")::character varying = UPPER(p_user_code)::character varying) THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_sec_auth_verifyemail
DROP FUNCTION IF EXISTS public.usp_sec_auth_verifyemail(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_auth_verifyemail(p_user_code character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."AuthIdentity"
    SET "IsRegistrationPending" = FALSE, "EmailVerifiedAtUtc" = NOW() AT TIME ZONE 'UTC',
        "FailedLoginCount" = 0, "LockoutUntilUtc" = NULL, "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC'
    WHERE UPPER("UserCode")::character varying = UPPER(p_user_code)::character varying;
END;
$function$
;

-- usp_sec_authidentity_upsert
DROP FUNCTION IF EXISTS public.usp_sec_authidentity_upsert(character varying, character varying, character varying, boolean) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_authidentity_upsert(p_user_code character varying, p_email character varying, p_email_normalized character varying, p_pending boolean)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO sec."AuthIdentity" (
        "UserCode", "Email", "EmailNormalized", "EmailVerifiedAtUtc",
        "IsRegistrationPending", "FailedLoginCount", "CreatedAtUtc", "UpdatedAtUtc"
    )
    VALUES (
        p_user_code, p_email, p_email_normalized,
        CASE WHEN p_pending THEN NULL ELSE NOW() AT TIME ZONE 'UTC' END,
        p_pending, 0, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC'
    )
    ON CONFLICT ("UserCode")
    DO UPDATE SET
        "Email" = EXCLUDED."Email",
        "EmailNormalized" = EXCLUDED."EmailNormalized",
        "IsRegistrationPending" = p_pending,
        "EmailVerifiedAtUtc" = CASE WHEN p_pending THEN NULL ELSE COALESCE(sec."AuthIdentity"."EmailVerifiedAtUtc", NOW() AT TIME ZONE 'UTC') END,
        "UpdatedAtUtc" = NOW() AT TIME ZONE 'UTC';
END;
$function$
;

-- usp_sec_authstore_check
DROP FUNCTION IF EXISTS public.usp_sec_authstore_check() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_authstore_check()
 RETURNS TABLE("hasStore" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE
      WHEN EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'sec' AND table_name = 'AuthIdentity')
       AND EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'sec' AND table_name = 'AuthToken')
      THEN 1 ELSE 0 END;
END;
$function$
;

-- usp_sec_authtoken_issue
DROP FUNCTION IF EXISTS public.usp_sec_authtoken_issue(character varying, character varying, character varying, character varying, integer, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_authtoken_issue(p_user_code character varying, p_token_type character varying, p_token_hash character varying, p_email_normalized character varying, p_ttl_minutes integer, p_ip character varying DEFAULT NULL::character varying, p_user_agent character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO sec."AuthToken" ("UserCode", "TokenType", "TokenHash", "EmailNormalized", "ExpiresAtUtc", "MetaIp", "MetaUserAgent")
    VALUES (p_user_code, p_token_type, p_token_hash, p_email_normalized, (NOW() AT TIME ZONE 'UTC') + (p_ttl_minutes || ' minutes')::INTERVAL, p_ip, p_user_agent);
END;
$function$
;

-- usp_sec_supervisor_biometric_deactivate
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_deactivate(character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_deactivate(p_supervisor_user character varying, p_credential_hash character varying, p_actor_user character varying)
 RETURNS TABLE("biometricCredentialId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    UPDATE sec."SupervisorBiometricCredential"
    SET "IsActive"          = FALSE,
        "UpdatedAtUtc"      = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserCode" = p_actor_user
    WHERE "SupervisorUserCode" = p_supervisor_user
      AND "CredentialHash"     = p_credential_hash
      AND "IsActive" = TRUE
    RETURNING "BiometricCredentialId";
END;
$function$
;

-- usp_sec_supervisor_biometric_enroll
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_enroll(character varying, character varying, character varying, character varying, character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_enroll(p_supervisor_user character varying, p_credential_hash character varying, p_credential_id character varying, p_credential_label character varying DEFAULT NULL::character varying, p_device_info character varying DEFAULT NULL::character varying, p_actor_user character varying DEFAULT NULL::character varying)
 RETURNS TABLE("biometricCredentialId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO sec."SupervisorBiometricCredential" (
        "SupervisorUserCode", "CredentialHash", "CredentialId",
        "CredentialLabel", "DeviceInfo", "IsActive",
        "LastValidatedAtUtc", "CreatedAtUtc", "UpdatedAtUtc",
        "CreatedByUserCode", "UpdatedByUserCode"
    )
    VALUES (
        p_supervisor_user, p_credential_hash, p_credential_id,
        p_credential_label, p_device_info, TRUE,
        NULL, NOW() AT TIME ZONE 'UTC', NOW() AT TIME ZONE 'UTC',
        p_actor_user, p_actor_user
    )
    ON CONFLICT ("SupervisorUserCode", "CredentialHash")
    DO UPDATE SET
        "CredentialId"       = EXCLUDED."CredentialId",
        "CredentialLabel"    = EXCLUDED."CredentialLabel",
        "DeviceInfo"         = EXCLUDED."DeviceInfo",
        "IsActive"           = TRUE,
        "UpdatedAtUtc"       = NOW() AT TIME ZONE 'UTC',
        "UpdatedByUserCode"  = p_actor_user;

    RETURN QUERY
    SELECT bc."BiometricCredentialId"
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."SupervisorUserCode" = p_supervisor_user
      AND bc."CredentialHash"     = p_credential_hash
    LIMIT 1;
END;
$function$
;

-- usp_sec_supervisor_biometric_hasactive
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_hasactive(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_hasactive(p_supervisor_user character varying, p_credential_hash character varying)
 RETURNS TABLE("biometricCredentialId" bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT bc."BiometricCredentialId"
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."SupervisorUserCode" = p_supervisor_user
      AND bc."CredentialHash"     = p_credential_hash
      AND bc."IsActive" = TRUE
    LIMIT 1;
END;
$function$
;

-- usp_sec_supervisor_biometric_list
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_list(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_list(p_supervisor_user character varying DEFAULT ''::character varying)
 RETURNS TABLE("biometricCredentialId" bigint, "supervisorUserCode" character varying, "credentialId" character varying, "credentialLabel" character varying, "deviceInfo" character varying, "isActive" boolean, "lastValidatedAtUtc" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        bc."BiometricCredentialId", bc."SupervisorUserCode",
        bc."CredentialId", bc."CredentialLabel",
        bc."DeviceInfo", bc."IsActive",
        TO_CHAR(bc."LastValidatedAtUtc", 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
    FROM sec."SupervisorBiometricCredential" bc
    WHERE bc."IsActive" = TRUE
      AND (p_supervisor_user = '' OR bc."SupervisorUserCode" = p_supervisor_user)
    ORDER BY bc."BiometricCredentialId" DESC;
END;
$function$
;

-- usp_sec_supervisor_biometric_touch
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_biometric_touch(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_biometric_touch(p_supervisor_user character varying, p_credential_hash character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."SupervisorBiometricCredential"
    SET "LastValidatedAtUtc" = NOW() AT TIME ZONE 'UTC',
        "UpdatedAtUtc"       = NOW() AT TIME ZONE 'UTC'
    WHERE "SupervisorUserCode" = p_supervisor_user
      AND "CredentialHash"     = p_credential_hash
      AND "IsActive" = TRUE;
END;
$function$
;

-- usp_sec_supervisor_getrecord
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_getrecord(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_getrecord(p_supervisor_user character varying)
 RETURNS TABLE("codUsuario" character varying, nombre character varying, tipo character varying, "isAdmin" boolean, "canDelete" boolean, "passwordHash" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."Cod_Usuario", u."Nombre", u."Tipo", u."IsAdmin", u."Deletes", u."Password"
    FROM "Usuarios" u
    WHERE UPPER(u."Cod_Usuario")::character varying = p_supervisor_user
    LIMIT 1;
END;
$function$
;

-- usp_sec_supervisor_override_consume
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_override_consume(integer, character varying, character varying, character varying, integer, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_override_consume(p_override_id integer, p_module_code character varying, p_action_code character varying, p_consumed_by_user character varying DEFAULT NULL::character varying, p_source_document_id integer DEFAULT NULL::integer, p_source_line_id integer DEFAULT NULL::integer, p_reversal_line_id integer DEFAULT NULL::integer)
 RETURNS TABLE("overrideId" integer)
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
    RETURNING "OverrideId";
END;
$function$
;

-- usp_sec_supervisor_override_create
DROP FUNCTION IF EXISTS public.usp_sec_supervisor_override_create(character varying, character varying, character varying, integer, integer, character varying, character varying, character varying, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_supervisor_override_create(p_module_code character varying, p_action_code character varying, p_status character varying, p_company_id integer DEFAULT NULL::integer, p_branch_id integer DEFAULT NULL::integer, p_requested_by_user character varying DEFAULT NULL::character varying, p_supervisor_user_code character varying DEFAULT NULL::character varying, p_reason character varying DEFAULT NULL::character varying, p_payload_json text DEFAULT NULL::text)
 RETURNS TABLE("overrideId" integer)
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
    RETURNING "OverrideId";
END;
$function$
;

-- usp_sec_user_authenticate
DROP FUNCTION IF EXISTS public.usp_sec_user_authenticate(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_authenticate(p_cod_usuario character varying)
 RETURNS TABLE("Cod_Usuario" character varying, "Password" character varying, "Nombre" character varying, "Tipo" character varying, "Updates" boolean, "Addnews" boolean, "Deletes" boolean, "Creador" character varying, "Cambiar" boolean, "PrecioMinimo" boolean, "Credito" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."UserCode",
           u."PasswordHash",
           u."UserName",
           u."UserType",
           COALESCE(u."CanUpdate", TRUE),
           COALESCE(u."CanCreate", TRUE),
           COALESCE(u."CanDelete", TRUE),
           u."CreatedByUserId"::VARCHAR,
           COALESCE(u."CanChangePwd", TRUE),
           COALESCE(u."CanChangePrice", TRUE),
           COALESCE(u."CanGiveCredit", TRUE)
    FROM   sec."User" u
    WHERE  u."UserCode"  = p_cod_usuario
      AND  u."IsDeleted" = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_sec_user_checkexists
DROP FUNCTION IF EXISTS public.usp_sec_user_checkexists(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_checkexists(p_cod_usuario character varying)
 RETURNS TABLE("Cod_Usuario" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."UserCode"
    FROM   sec."User" u
    WHERE  u."UserCode" = p_cod_usuario
    LIMIT 1;
END;
$function$
;

-- usp_sec_user_ensuredefaultcompanyaccess
DROP FUNCTION IF EXISTS public.usp_sec_user_ensuredefaultcompanyaccess(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_ensuredefaultcompanyaccess(p_cod_usuario character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_company_id INT;
    v_branch_id  INT;
BEGIN
    -- Buscar empresa DEFAULT y sucursal MAIN
    SELECT c."CompanyId", b."BranchId"
    INTO   v_company_id, v_branch_id
    FROM   cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId"  = c."CompanyId"
       AND b."BranchCode" = 'MAIN'
       AND b."IsActive"   = TRUE
       AND b."IsDeleted"  = FALSE
    WHERE  c."CompanyCode" = 'DEFAULT'
      AND  c."IsActive"    = TRUE
      AND  c."IsDeleted"   = FALSE
    LIMIT 1;

    IF v_company_id IS NULL OR v_branch_id IS NULL THEN
        RETURN;
    END IF;

    -- UPSERT: insertar si no existe
    INSERT INTO sec."UserCompanyAccess"
        ("CodUsuario", "CompanyId", "BranchId", "IsActive", "IsDefault")
    VALUES
        (p_cod_usuario, v_company_id, v_branch_id, TRUE, TRUE)
    ON CONFLICT ("CodUsuario", "CompanyId", "BranchId")
    DO UPDATE SET "IsActive" = TRUE, "IsDefault" = TRUE
    WHERE sec."UserCompanyAccess"."IsActive" = FALSE;
END;
$function$
;

-- usp_sec_user_getavatar
DROP FUNCTION IF EXISTS public.usp_sec_user_getavatar(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_getavatar(p_cod_usuario character varying)
 RETURNS TABLE("Avatar" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."Avatar"
    FROM   sec."User" u
    WHERE  u."UserCode" = p_cod_usuario
    LIMIT 1;
END;
$function$
;

-- usp_sec_user_getcompanyaccesses
DROP FUNCTION IF EXISTS public.usp_sec_user_getcompanyaccesses(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_getcompanyaccesses(p_cod_usuario character varying)
 RETURNS TABLE("companyId" integer, "companyCode" character varying, "companyName" character varying, "branchId" integer, "branchCode" character varying, "branchName" character varying, "countryCode" character varying, "timeZone" character varying, "isDefault" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        a."CompanyId",
        c."CompanyCode",
        COALESCE(NULLIF(c."TradeName", ''::character varying), c."LegalName")::character varying,
        a."BranchId",
        b."BranchCode",
        b."BranchName",
        UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode")::character varying)::character varying,
        COALESCE(
            NULLIF(ct."TimeZoneIana", ''::character varying),
            CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode"))::character varying
                WHEN 'ES' THEN 'Europe/Madrid'
                WHEN 'VE' THEN 'America/Caracas'
                ELSE 'UTC'
            END
        )::character varying,
        a."IsDefault"
    FROM sec."UserCompanyAccess" a
    INNER JOIN cfg."Company" c
        ON c."CompanyId" = a."CompanyId"
       AND c."IsActive"  = TRUE
       AND c."IsDeleted" = FALSE
    INNER JOIN cfg."Branch" b
        ON b."BranchId"  = a."BranchId"
       AND b."CompanyId" = a."CompanyId"
       AND b."IsActive"  = TRUE
       AND b."IsDeleted" = FALSE
    LEFT JOIN cfg."Country" ct
        ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode")::character varying)::character varying
       AND ct."IsActive" = TRUE
    WHERE UPPER(a."CodUsuario")::character varying = UPPER(p_cod_usuario)::character varying
      AND a."IsActive" = TRUE
    ORDER BY
        CASE WHEN a."IsDefault" = TRUE THEN 0 ELSE 1 END,
        a."CompanyId", a."BranchId";

EXCEPTION WHEN OTHERS THEN
    -- Si la tabla no existe, retornar vacío
    RETURN;
END;
$function$
;

-- usp_sec_user_getmoduleaccess
DROP FUNCTION IF EXISTS public.usp_sec_user_getmoduleaccess(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_getmoduleaccess(p_cod_usuario character varying)
 RETURNS TABLE("Cod_Usuario" character varying, "Modulo" character varying, "Permitido" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT a."UserCode", a."ModuleCode", a."IsAllowed"
    FROM   sec."UserModuleAccess" a
    WHERE  a."UserCode" = p_cod_usuario;
END;
$function$
;

-- usp_sec_user_gettype
DROP FUNCTION IF EXISTS public.usp_sec_user_gettype(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_gettype(p_cod_usuario character varying)
 RETURNS TABLE("Cod_Usuario" character varying, "Tipo" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."UserCode", u."UserType"
    FROM   sec."User" u
    WHERE  u."UserCode"  = p_cod_usuario
      AND  u."IsDeleted" = FALSE
    LIMIT 1;
END;
$function$
;

-- usp_sec_user_listcompanyaccesses_default
DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses_default() CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_listcompanyaccesses_default()
 RETURNS TABLE("companyId" integer, "companyCode" character varying, "companyName" character varying, "branchId" integer, "branchCode" character varying, "branchName" character varying, "countryCode" character varying, "timeZone" character varying, "isDefault" boolean)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        c."CompanyId",
        c."CompanyCode",
        COALESCE(NULLIF(c."TradeName", ''::character varying), c."LegalName")::character varying,
        b."BranchId",
        b."BranchCode",
        b."BranchName",
        UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode")::character varying)::character varying,
        COALESCE(
            NULLIF(ct."TimeZoneIana", ''::character varying),
            CASE UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode"))::character varying
                WHEN 'ES' THEN 'Europe/Madrid'
                WHEN 'VE' THEN 'America/Caracas'
                ELSE 'UTC'
            END
        )::character varying,
        (c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN')
    FROM cfg."Company" c
    INNER JOIN cfg."Branch" b
        ON b."CompanyId" = c."CompanyId"
    LEFT JOIN cfg."Country" ct
        ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode", ''::character varying), c."FiscalCountryCode")::character varying)::character varying
       AND ct."IsActive" = TRUE
    WHERE c."IsActive"  = TRUE
      AND c."IsDeleted" = FALSE
      AND b."IsActive"  = TRUE
      AND b."IsDeleted" = FALSE
    ORDER BY
        CASE WHEN c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN'
             THEN 0 ELSE 1 END,
        c."CompanyId", b."BranchId";
END;
$function$
;

-- usp_sec_user_resolvebycode
DROP FUNCTION IF EXISTS public.usp_sec_user_resolvebycode(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_resolvebycode(p_code character varying)
 RETURNS TABLE("userId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."UserId" FROM sec."User" u WHERE UPPER(u."UserCode")::character varying = UPPER(p_code)::character varying ORDER BY u."UserId" LIMIT 1;
END;
$function$
;

-- usp_sec_user_resolvebycodeactive
DROP FUNCTION IF EXISTS public.usp_sec_user_resolvebycodeactive(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_resolvebycodeactive(p_code character varying)
 RETURNS TABLE("userId" integer)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT u."UserId" FROM sec."User" u
    WHERE UPPER(u."UserCode")::character varying = UPPER(p_code)::character varying AND u."IsDeleted" = FALSE AND u."IsActive" = TRUE
    ORDER BY u."UserId" LIMIT 1;
END;
$function$
;

-- usp_sec_user_setavatar
DROP FUNCTION IF EXISTS public.usp_sec_user_setavatar(character varying, text) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_setavatar(p_cod_usuario character varying, p_avatar text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."User"
    SET    "Avatar"    = p_avatar,
           "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
    WHERE  "UserCode" = p_cod_usuario;
END;
$function$
;

-- usp_sec_user_setmoduleaccess
DROP FUNCTION IF EXISTS public.usp_sec_user_setmoduleaccess(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_setmoduleaccess(p_cod_usuario character varying, p_modules_json jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Eliminar permisos actuales
    DELETE FROM sec."UserModuleAccess"
    WHERE  "UserCode" = p_cod_usuario;

    -- Insertar nuevos permisos desde JSONB array
    INSERT INTO sec."UserModuleAccess" ("UserCode", "ModuleCode", "IsAllowed")
    SELECT p_cod_usuario,
           elem->>'modulo',
           COALESCE((elem->>'permitido')::BOOLEAN, FALSE)
    FROM   jsonb_array_elements(p_modules_json) elem;
END;
$function$
;

-- usp_sec_user_updatepassword
DROP FUNCTION IF EXISTS public.usp_sec_user_updatepassword(character varying, character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_sec_user_updatepassword(p_cod_usuario character varying, p_password_hash character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE sec."User"
    SET    "PasswordHash" = p_password_hash,
           "UpdatedAt"    = NOW() AT TIME ZONE 'UTC'
    WHERE  "UserCode"  = p_cod_usuario
      AND  "IsDeleted" = FALSE;
END;
$function$
;

-- usp_usuarios_delete
DROP FUNCTION IF EXISTS public.usp_usuarios_delete(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_usuarios_delete(p_cod_usuario character varying)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Usuario no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE sec."User"
        SET "IsDeleted" = TRUE,
            "IsActive"  = FALSE,
            "DeletedAt" = NOW() AT TIME ZONE 'UTC',
            "UpdatedAt" = NOW() AT TIME ZONE 'UTC'
        WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_usuarios_getbycodigo
DROP FUNCTION IF EXISTS public.usp_usuarios_getbycodigo(character varying) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_usuarios_getbycodigo(p_cod_usuario character varying)
 RETURNS TABLE("Cod_Usuario" character varying, "Password" character varying, "Nombre" character varying, "Tipo" character varying, "Updates" boolean, "Addnews" boolean, "Deletes" boolean, "Creador" boolean, "Cambiar" boolean, "PrecioMinimo" boolean, "Credito" boolean, "IsAdmin" boolean, "Avatar" character varying)
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
$function$
;

-- usp_usuarios_insert
DROP FUNCTION IF EXISTS public.usp_usuarios_insert(jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_usuarios_insert(p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_cod_usuario VARCHAR(50);
BEGIN
    v_cod_usuario := NULLIF(p_row_json->>'Cod_Usuario', ''::character varying);

    IF EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = v_cod_usuario AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Usuario ya existe'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        INSERT INTO sec."User" (
            "UserCode", "PasswordHash", "UserName", "UserType",
            "CanUpdate", "CanCreate", "CanDelete", "IsCreator",
            "CanChangePwd", "CanChangePrice", "CanGiveCredit",
            "IsAdmin", "IsActive", "CreatedAt", "UpdatedAt", "IsDeleted"
        ) VALUES (
            v_cod_usuario,
            NULLIF(p_row_json->>'Password', ''::character varying),
            NULLIF(p_row_json->>'Nombre', ''::character varying),
            COALESCE(NULLIF(p_row_json->>'Tipo', ''::character varying), 'USER')::character varying,
            COALESCE((p_row_json->>'Updates')::BOOLEAN, TRUE),
            COALESCE((p_row_json->>'Addnews')::BOOLEAN, TRUE),
            COALESCE((p_row_json->>'Deletes')::BOOLEAN, FALSE),
            COALESCE((p_row_json->>'Creador')::BOOLEAN, FALSE),
            COALESCE((p_row_json->>'Cambiar')::BOOLEAN, TRUE),
            COALESCE((p_row_json->>'PrecioMinimo')::BOOLEAN, FALSE),
            COALESCE((p_row_json->>'Credito')::BOOLEAN, FALSE),
            COALESCE((p_row_json->>'IsAdmin')::BOOLEAN, FALSE),
            TRUE,
            NOW() AT TIME ZONE 'UTC',
            NOW() AT TIME ZONE 'UTC',
            FALSE
        );

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

-- usp_usuarios_list
DROP FUNCTION IF EXISTS public.usp_usuarios_list(character varying, character varying, integer, integer) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_usuarios_list(p_search character varying DEFAULT NULL::character varying, p_tipo character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_limit integer DEFAULT 50)
 RETURNS TABLE("TotalCount" bigint, "Cod_Usuario" character varying, "Password" character varying, "Nombre" character varying, "Tipo" character varying, "Updates" boolean, "Addnews" boolean, "Deletes" boolean, "Creador" boolean, "Cambiar" boolean, "PrecioMinimo" boolean, "Credito" boolean, "IsAdmin" boolean, "Avatar" character varying)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_offset  INT;
    v_limit   INT;
    v_total   BIGINT;
    v_search  VARCHAR(100);
BEGIN
    v_limit  := COALESCE(NULLIF(p_limit, 0), 50);
    IF v_limit < 1 THEN v_limit := 50; END IF;
    IF v_limit > 500 THEN v_limit := 500; END IF;
    v_offset := (COALESCE(NULLIF(p_page, 0), 1) - 1) * v_limit;
    IF v_offset < 0 THEN v_offset := 0; END IF;

    v_search := NULL;
    IF p_search IS NOT NULL AND TRIM(p_search) <> '' THEN
        v_search := '%' || p_search || '%';
    END IF;

    SELECT COUNT(1) INTO v_total
    FROM sec."User"
    WHERE "IsDeleted" = FALSE
      AND (v_search IS NULL OR "UserCode" LIKE v_search OR "UserName" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR "UserType" = p_tipo);

    RETURN QUERY
    SELECT
        v_total,
        u."UserCode"        AS "Cod_Usuario",
        u."PasswordHash"    AS "Password",
        u."UserName"        AS "Nombre",
        u."UserType"        AS "Tipo",
        u."CanUpdate"       AS "Updates",
        u."CanCreate"       AS "Addnews",
        u."CanDelete"       AS "Deletes",
        u."IsCreator"       AS "Creador",
        u."CanChangePwd"    AS "Cambiar",
        u."CanChangePrice"  AS "PrecioMinimo",
        u."CanGiveCredit"   AS "Credito",
        u."IsAdmin",
        u."Avatar"
    FROM sec."User" u
    WHERE u."IsDeleted" = FALSE
      AND (v_search IS NULL OR u."UserCode" LIKE v_search OR u."UserName" LIKE v_search)
      AND (p_tipo IS NULL OR TRIM(p_tipo) = '' OR u."UserType" = p_tipo)
    ORDER BY u."UserCode"
    LIMIT v_limit OFFSET v_offset;
END;
$function$
;

-- usp_usuarios_update
DROP FUNCTION IF EXISTS public.usp_usuarios_update(character varying, jsonb) CASCADE;
CREATE OR REPLACE FUNCTION public.usp_usuarios_update(p_cod_usuario character varying, p_row_json jsonb)
 RETURNS TABLE("Resultado" integer, "Mensaje" character varying)
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sec."User" WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE) THEN
        RETURN QUERY SELECT -1, 'Usuario no encontrado'::VARCHAR;
        RETURN;
    END IF;

    BEGIN
        UPDATE sec."User" SET
            "PasswordHash"   = COALESCE(NULLIF(p_row_json->>'Password', ''::character varying), "PasswordHash")::character varying,
            "UserName"       = COALESCE(NULLIF(p_row_json->>'Nombre', ''::character varying), "UserName")::character varying,
            "UserType"       = COALESCE(NULLIF(p_row_json->>'Tipo', ''::character varying), "UserType")::character varying,
            "IsAdmin"        = COALESCE((p_row_json->>'IsAdmin')::BOOLEAN, "IsAdmin"),
            "CanUpdate"      = COALESCE((p_row_json->>'Updates')::BOOLEAN, "CanUpdate"),
            "CanCreate"      = COALESCE((p_row_json->>'Addnews')::BOOLEAN, "CanCreate"),
            "CanDelete"      = COALESCE((p_row_json->>'Deletes')::BOOLEAN, "CanDelete"),
            "IsCreator"      = COALESCE((p_row_json->>'Creador')::BOOLEAN, "IsCreator"),
            "CanChangePwd"   = COALESCE((p_row_json->>'Cambiar')::BOOLEAN, "CanChangePwd"),
            "CanChangePrice" = COALESCE((p_row_json->>'PrecioMinimo')::BOOLEAN, "CanChangePrice"),
            "CanGiveCredit"  = COALESCE((p_row_json->>'Credito')::BOOLEAN, "CanGiveCredit"),
            "UpdatedAt"      = NOW() AT TIME ZONE 'UTC'
        WHERE "UserCode" = p_cod_usuario AND "IsDeleted" = FALSE;

        RETURN QUERY SELECT 1, 'OK'::VARCHAR;
    EXCEPTION WHEN OTHERS THEN
        RETURN QUERY SELECT -99, SQLERRM::VARCHAR;
    END;
END;
$function$
;

