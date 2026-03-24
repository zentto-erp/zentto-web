-- ============================================================
-- usp_sys_license.sql — Licencias Zentto (validate / create / renew / revoke)
-- Motor: SQL Server
-- Paridad: web/api/sqlweb-pg/includes/sp/usp_sys_license.sql
-- ============================================================

-- SP: validar licencia por companyCode + licenseKey
CREATE OR ALTER PROCEDURE dbo.usp_Sys_License_Validate
  @CompanyCode  NVARCHAR(30),
  @LicenseKey   NVARCHAR(64)
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE
    @CompanyId   BIGINT,
    @CompanyName NVARCHAR(200),
    @IsActive    BIT,
    @LicenseId   BIGINT,
    @DbLicKey    NVARCHAR(64),
    @Status      NVARCHAR(20),
    @LicenseType NVARCHAR(20),
    @Plan        NVARCHAR(30),
    @ExpiresAt   DATETIME2,
    @DaysRem     INT,
    @ModulesJson NVARCHAR(MAX);

  -- Buscar empresa
  SELECT @CompanyId = CompanyId, @CompanyName = CompanyName, @IsActive = IsActive
  FROM cfg.Company WHERE CompanyCode = @CompanyCode;

  IF @CompanyId IS NULL
  BEGIN
    SELECT 0 AS ok, 'COMPANY_NOT_FOUND' AS reason, '' AS plan,
           '' AS modules, NULL AS expires_at, NULL AS days_remaining,
           '' AS company_name, '' AS license_type;
    RETURN;
  END

  IF @IsActive = 0
  BEGIN
    SELECT 0 AS ok, 'COMPANY_INACTIVE' AS reason, '' AS plan,
           '' AS modules, NULL AS expires_at, NULL AS days_remaining,
           @CompanyName AS company_name, '' AS license_type;
    RETURN;
  END

  -- Buscar licencia activa
  SELECT TOP 1
    @LicenseId = LicenseId, @DbLicKey = LicenseKey, @Status = Status,
    @LicenseType = LicenseType, @Plan = Plan, @ExpiresAt = ExpiresAt
  FROM sys.License
  WHERE CompanyId = @CompanyId AND Status = 'ACTIVE'
  ORDER BY CreatedAt DESC;

  IF @LicenseId IS NULL
  BEGIN
    SELECT 0 AS ok, 'LICENSE_NOT_FOUND' AS reason, '' AS plan,
           '' AS modules, NULL AS expires_at, NULL AS days_remaining,
           @CompanyName AS company_name, '' AS license_type;
    RETURN;
  END

  -- Verificar key
  IF @DbLicKey <> @LicenseKey
  BEGIN
    SELECT 0 AS ok, 'LICENSE_INVALID_KEY' AS reason, '' AS plan,
           '' AS modules, NULL AS expires_at, NULL AS days_remaining,
           @CompanyName AS company_name, '' AS license_type;
    RETURN;
  END

  -- Verificar suspensión
  IF @Status = 'SUSPENDED'
  BEGIN
    SELECT 0 AS ok, 'LICENSE_SUSPENDED' AS reason, @Plan AS plan,
           '' AS modules, @ExpiresAt AS expires_at, NULL AS days_remaining,
           @CompanyName AS company_name, @LicenseType AS license_type;
    RETURN;
  END

  -- Verificar expiración (solo SUBSCRIPTION y TRIAL)
  IF @LicenseType NOT IN ('LIFETIME','INTERNAL') AND @ExpiresAt IS NOT NULL
  BEGIN
    IF @ExpiresAt < GETUTCDATE()
    BEGIN
      SELECT 0 AS ok, 'LICENSE_EXPIRED' AS reason, @Plan AS plan,
             '' AS modules, @ExpiresAt AS expires_at, 0 AS days_remaining,
             @CompanyName AS company_name, @LicenseType AS license_type;
      RETURN;
    END
  END

  -- Calcular días restantes
  IF @ExpiresAt IS NOT NULL
    SET @DaysRem = DATEDIFF(DAY, GETUTCDATE(), @ExpiresAt);

  -- Obtener módulos del plan como JSON
  SELECT @ModulesJson = '[' +
    STRING_AGG('"' + ModuleCode + '"', ',') WITHIN GROUP (ORDER BY SortOrder)
    + ']'
  FROM cfg.PlanModule
  WHERE PlanCode = @Plan AND IsEnabled = 1;

  SELECT
    1                          AS ok,
    'OK'                       AS reason,
    @Plan                      AS plan,
    ISNULL(@ModulesJson, '[]') AS modules,
    @ExpiresAt                 AS expires_at,
    @DaysRem                   AS days_remaining,
    @CompanyName               AS company_name,
    @LicenseType               AS license_type;
END
GO

-- SP: crear licencia
CREATE OR ALTER PROCEDURE dbo.usp_Sys_License_Create
  @CompanyId    BIGINT,
  @LicenseType  NVARCHAR(20) = 'SUBSCRIPTION',
  @Plan         NVARCHAR(30) = 'STARTER',
  @ExpiresAt    DATETIME2    = NULL,
  @PaddleSubId  NVARCHAR(100) = NULL,
  @ContractRef  NVARCHAR(100) = NULL,
  @MaxUsers     INT           = NULL,
  @Notes        NVARCHAR(MAX) = NULL,
  @LicenseId    BIGINT OUTPUT,
  @LicenseKey   NVARCHAR(64) OUTPUT,
  @Ok           INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  -- Generar license key con NEWID + checksum
  SET @LicenseKey = LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(36)),'-','')
                  + REPLACE(CAST(NEWID() AS NVARCHAR(36)),'-',''), 64);

  INSERT INTO sys.License (
    CompanyId, LicenseType, Plan, LicenseKey, Status,
    StartsAt, ExpiresAt, PaddleSubId, ContractRef, MaxUsers, Notes
  ) VALUES (
    @CompanyId, @LicenseType, @Plan, @LicenseKey, 'ACTIVE',
    GETUTCDATE(), @ExpiresAt, @PaddleSubId, @ContractRef, @MaxUsers, @Notes
  );

  SET @LicenseId = SCOPE_IDENTITY();

  -- Actualizar LicenseKey en cfg.Company
  UPDATE cfg.Company SET LicenseKey = @LicenseKey WHERE CompanyId = @CompanyId;

  -- Aplicar módulos al admin del tenant
  DECLARE @ApplyOk INT, @ApplyMsg NVARCHAR(200), @ApplyCount INT;
  EXEC dbo.usp_Cfg_Plan_ApplyModules
    @CompanyId = @CompanyId,
    @Plan      = @Plan,
    @Ok        = @ApplyOk OUTPUT,
    @Mensaje   = @ApplyMsg OUTPUT,
    @ModulesApplied = @ApplyCount OUTPUT;

  SET @Ok = 1;
END
GO

-- SP: renovar licencia
CREATE OR ALTER PROCEDURE dbo.usp_Sys_License_Renew
  @LicenseId      BIGINT,
  @NewExpiresAt   DATETIME2,
  @Ok             INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE sys.License
  SET ExpiresAt = @NewExpiresAt,
      Status    = 'ACTIVE',
      UpdatedAt = GETUTCDATE()
  WHERE LicenseId = @LicenseId;

  SET @Ok = 1;
END
GO

-- SP: revocar licencia
CREATE OR ALTER PROCEDURE dbo.usp_Sys_License_Revoke
  @LicenseId BIGINT,
  @Reason    NVARCHAR(200) = NULL,
  @Ok        INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  UPDATE sys.License
  SET Status    = 'CANCELLED',
      Notes     = ISNULL(Notes, '') + ISNULL(CHAR(10) + '[REVOKED] ' + @Reason, CHAR(10) + '[REVOKED]'),
      UpdatedAt = GETUTCDATE()
  WHERE LicenseId = @LicenseId;

  SET @Ok = 1;
END
GO
