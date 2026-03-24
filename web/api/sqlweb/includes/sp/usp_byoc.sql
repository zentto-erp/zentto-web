-- ============================================================
-- usp_byoc.sql — Stored Procedures BYOC Deploy Jobs + Onboarding Tokens
-- Motor: SQL Server
-- Paridad: web/api/sqlweb-pg/includes/sp/usp_byoc.sql
-- ============================================================

-- ============================================================
-- SP: crear job
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_byoc_job_create
  @CompanyId     BIGINT,
  @Provider      NVARCHAR(30),
  @DeployConfig  NVARCHAR(MAX) = NULL,
  @Resultado     INT OUTPUT,
  @Mensaje       NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @JobId BIGINT;

  BEGIN TRY
    INSERT INTO sys.ByocDeployJob (CompanyId, Provider, Status, DeployConfig, StartedAt)
    VALUES (@CompanyId, @Provider, 'PENDING', @DeployConfig, GETUTCDATE());

    SET @JobId    = SCOPE_IDENTITY();
    SET @Resultado = @JobId;
    SET @Mensaje   = 'OK';

    SELECT @JobId AS JobId, 1 AS ok;
  END TRY
  BEGIN CATCH
    SET @Resultado = -1;
    SET @Mensaje   = ERROR_MESSAGE();
  END CATCH;
END;
GO

-- ============================================================
-- SP: actualizar status del job
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_byoc_job_update_status
  @JobId       BIGINT,
  @Status      NVARCHAR(20),
  @ServerIp    NVARCHAR(45)  = NULL,
  @TenantUrl   NVARCHAR(255) = NULL,
  @LogAppend   NVARCHAR(MAX) = NULL,
  @ErrorMsg    NVARCHAR(MAX) = NULL,
  @Resultado   INT OUTPUT,
  @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    UPDATE sys.ByocDeployJob
    SET Status       = @Status,
        ServerIp     = ISNULL(@ServerIp, ServerIp),
        TenantUrl    = ISNULL(@TenantUrl, TenantUrl),
        LogOutput    = CASE WHEN @LogAppend IS NOT NULL
                           THEN ISNULL(LogOutput, '') + CHAR(10) + @LogAppend
                           ELSE LogOutput END,
        ErrorMessage = ISNULL(@ErrorMsg, ErrorMessage),
        CompletedAt  = CASE WHEN @Status IN ('DONE', 'FAILED') THEN GETUTCDATE() ELSE CompletedAt END
    WHERE JobId = @JobId;

    SET @Resultado = 1;
    SET @Mensaje   = 'OK';
    SELECT 1 AS ok;
  END TRY
  BEGIN CATCH
    SET @Resultado = -1;
    SET @Mensaje   = ERROR_MESSAGE();
  END CATCH;
END;
GO

-- ============================================================
-- SP: obtener job
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_byoc_job_get
  @JobId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    j.JobId, j.CompanyId, j.Provider, j.Status,
    j.ServerIp, j.TenantUrl, j.LogOutput, j.ErrorMessage,
    j.StartedAt, j.CompletedAt, j.CreatedAt
  FROM sys.ByocDeployJob j
  WHERE j.JobId = @JobId;
END;
GO

-- ============================================================
-- SP: listar jobs de un tenant
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_byoc_job_list
  @CompanyId BIGINT
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    j.JobId, j.Provider, j.Status,
    j.ServerIp, j.TenantUrl, j.CreatedAt
  FROM sys.ByocDeployJob j
  WHERE j.CompanyId = @CompanyId
  ORDER BY j.CreatedAt DESC;
END;
GO

-- ============================================================
-- SP: crear token de onboarding
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_onboarding_token_create
  @CompanyId   BIGINT,
  @Token       NVARCHAR(64),
  @DeployType  NVARCHAR(20)  = 'byoc',
  @TtlHours    INT           = 72,
  @Resultado   INT OUTPUT,
  @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @TokenId BIGINT;

  BEGIN TRY
    INSERT INTO sys.OnboardingToken (CompanyId, Token, DeployType, ExpiresAt)
    VALUES (@CompanyId, @Token, @DeployType, DATEADD(HOUR, @TtlHours, GETUTCDATE()));

    SET @TokenId   = SCOPE_IDENTITY();
    SET @Resultado = @TokenId;
    SET @Mensaje   = 'OK';

    SELECT @TokenId AS TokenId, 1 AS ok;
  END TRY
  BEGIN CATCH
    SET @Resultado = -1;
    SET @Mensaje   = ERROR_MESSAGE();
  END CATCH;
END;
GO

-- ============================================================
-- SP: validar y consumir token de onboarding
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_onboarding_token_validate
  @Token     NVARCHAR(64),
  @Resultado INT OUTPUT,
  @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE
    @CompanyId  BIGINT,
    @DeployType NVARCHAR(20),
    @ExpiresAt  DATETIME2,
    @UsedAt     DATETIME2;

  BEGIN TRY
    SELECT
      @CompanyId  = CompanyId,
      @DeployType = DeployType,
      @ExpiresAt  = ExpiresAt,
      @UsedAt     = UsedAt
    FROM sys.OnboardingToken
    WHERE Token = @Token;

    IF @CompanyId IS NULL
    BEGIN
      SET @Resultado = 0; SET @Mensaje = 'token_not_found';
      SELECT 0 AS CompanyId, N'' AS DeployType, 0 AS ok, N'token_not_found' AS reason;
      RETURN;
    END;

    IF @UsedAt IS NOT NULL
    BEGIN
      SET @Resultado = 0; SET @Mensaje = 'token_already_used';
      SELECT 0 AS CompanyId, N'' AS DeployType, 0 AS ok, N'token_already_used' AS reason;
      RETURN;
    END;

    IF @ExpiresAt < GETUTCDATE()
    BEGIN
      SET @Resultado = 0; SET @Mensaje = 'token_expired';
      SELECT 0 AS CompanyId, N'' AS DeployType, 0 AS ok, N'token_expired' AS reason;
      RETURN;
    END;

    UPDATE sys.OnboardingToken SET UsedAt = GETUTCDATE() WHERE Token = @Token;

    SET @Resultado = 1; SET @Mensaje = 'OK';
    SELECT @CompanyId AS CompanyId, @DeployType AS DeployType, 1 AS ok, N'' AS reason;
  END TRY
  BEGIN CATCH
    SET @Resultado = -1;
    SET @Mensaje   = ERROR_MESSAGE();
  END CATCH;
END;
GO
