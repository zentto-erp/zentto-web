-- ============================================================
-- usp_Cfg_Tenant_Provision — SQL Server
-- ============================================================
USE DatqBoxWeb;
GO
CREATE OR ALTER PROCEDURE dbo.usp_Cfg_Tenant_Provision
  @CompanyCode           NVARCHAR(20),
  @LegalName             NVARCHAR(200),
  @OwnerEmail            NVARCHAR(150),
  @CountryCode           CHAR(2),
  @BaseCurrency          CHAR(3),
  @AdminUserCode         NVARCHAR(40),
  @AdminPasswordHash     NVARCHAR(255),
  @Plan                  NVARCHAR(30)  = N'STARTER',
  @PaddleSubscriptionId  NVARCHAR(100) = NULL,
  @Resultado             INT           OUTPUT,
  @Mensaje               NVARCHAR(500) OUTPUT,
  @CompanyId             INT           OUTPUT,
  @UserId                INT           OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0; SET @Mensaje = N''; SET @CompanyId = 0; SET @UserId = 0;

  DECLARE @SystemId INT = 1;
  SELECT TOP 1 @SystemId = UserId FROM sec.[User] WHERE UserCode = 'SYSTEM';

  -- 0. Validar unicidad
  IF EXISTS (SELECT 1 FROM cfg.Company WHERE LOWER(OwnerEmail) = LOWER(@OwnerEmail) AND IsDeleted = 0) BEGIN
    SET @Resultado = 0; SET @Mensaje = N'EMAIL_ALREADY_EXISTS'; RETURN;
  END
  IF EXISTS (SELECT 1 FROM cfg.Company WHERE UPPER(CompanyCode) = UPPER(@CompanyCode) AND IsDeleted = 0) BEGIN
    SET @Resultado = 0; SET @Mensaje = N'COMPANY_CODE_ALREADY_EXISTS'; RETURN;
  END

  BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. cfg.Company
    INSERT INTO cfg.Company (
      CompanyCode, LegalName, FiscalCountryCode, BaseCurrency,
      IsActive, Plan, TenantStatus, OwnerEmail, ProvisionedAt,
      PaddleSubscriptionId, CreatedByUserId, UpdatedByUserId
    ) VALUES (
      UPPER(@CompanyCode), @LegalName, UPPER(@CountryCode), UPPER(@BaseCurrency),
      1, UPPER(@Plan), N'ACTIVE', LOWER(@OwnerEmail), SYSUTCDATETIME(),
      @PaddleSubscriptionId, @SystemId, @SystemId
    );
    SET @CompanyId = SCOPE_IDENTITY();

    -- 2. cfg.Branch
    DECLARE @BranchId INT;
    INSERT INTO cfg.Branch (
      CompanyId, BranchCode, BranchName,
      IsActive, CreatedByUserId, UpdatedByUserId
    ) VALUES (@CompanyId, N'MAIN', N'Principal', 1, @SystemId, @SystemId);
    SET @BranchId = SCOPE_IDENTITY();

    -- 3. sec.User admin
    IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = UPPER(@AdminUserCode))
    BEGIN
      INSERT INTO sec.[User] (
        UserCode, UserName, PasswordHash, Email,
        IsAdmin, IsActive, UserType, [Role],
        CanUpdate, CanCreate, CanDelete, IsCreator,
        CanChangePwd, CanChangePrice, CanGiveCredit,
        CompanyId, DisplayName, CreatedByUserId, UpdatedByUserId
      ) VALUES (
        UPPER(@AdminUserCode), @LegalName,
        @AdminPasswordHash, LOWER(@OwnerEmail),
        1, 1, N'ADMIN', N'admin',
        1, 1, 1, 1, 1, 0, 0,
        @CompanyId, N'Administrador', @SystemId, @SystemId
      );
      SET @UserId = SCOPE_IDENTITY();
    END ELSE BEGIN
      SELECT @UserId = UserId FROM sec.[User] WHERE UserCode = UPPER(@AdminUserCode);
    END

    -- 4. UserCompanyAccess
    IF NOT EXISTS (SELECT 1 FROM sec.UserCompanyAccess WHERE CodUsuario = UPPER(@AdminUserCode) AND CompanyId = @CompanyId AND BranchId = @BranchId)
      INSERT INTO sec.UserCompanyAccess (CodUsuario, CompanyId, BranchId, IsActive, IsDefault)
      VALUES (UPPER(@AdminUserCode), @CompanyId, @BranchId, 1, 1);
    ELSE
      UPDATE sec.UserCompanyAccess SET IsActive = 1, IsDefault = 1, UpdatedAt = SYSUTCDATETIME()
      WHERE CodUsuario = UPPER(@AdminUserCode) AND CompanyId = @CompanyId AND BranchId = @BranchId;

    -- 5. ExchangeRateDaily seed
    IF NOT EXISTS (SELECT 1 FROM cfg.ExchangeRateDaily WHERE CurrencyCode = UPPER(@BaseCurrency) AND CAST(RateDate AS DATE) = CAST(GETUTCDATE() AS DATE))
      INSERT INTO cfg.ExchangeRateDaily (CurrencyCode, RateToBase, RateDate, SourceName, CreatedByUserId)
      VALUES (UPPER(@BaseCurrency), 1.000000, CAST(GETUTCDATE() AS DATE), N'PROVISION_SEED', @SystemId);

    COMMIT TRANSACTION;
    SET @Resultado = 1; SET @Mensaje = N'TENANT_PROVISIONED';

  END TRY
  BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @Resultado = 0; SET @Mensaje = ERROR_MESSAGE();
  END CATCH;
END;
GO
