SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  DECLARE @CompanyEsId INT;
  DECLARE @BranchEsId INT;
  DECLARE @DefaultCompanyId INT;
  DECLARE @DefaultBranchId INT;
  DECLARE @DefaultBranchEsId INT;

  SELECT @CompanyEsId = CompanyId
  FROM cfg.Company
  WHERE CompanyCode = N'SPAIN01';

  IF @CompanyEsId IS NULL
  BEGIN
    INSERT INTO cfg.Company (
      CompanyCode,
      LegalName,
      TradeName,
      FiscalCountryCode,
      FiscalId,
      BaseCurrency,
      IsActive,
      IsDeleted
    )
    VALUES (
      N'SPAIN01',
      N'Contabilidad Iberica, S.L.',
      N'DatqBox Spain',
      'ES',
      N'B12345678',
      'EUR',
      1,
      0
    );

    SET @CompanyEsId = SCOPE_IDENTITY();
  END;

  SELECT @BranchEsId = BranchId
  FROM cfg.Branch
  WHERE CompanyId = @CompanyEsId
    AND BranchCode = N'MAIN';

  IF @BranchEsId IS NULL
  BEGIN
    INSERT INTO cfg.Branch (
      CompanyId,
      BranchCode,
      BranchName,
      AddressLine,
      Phone,
      IsActive,
      IsDeleted
    )
    VALUES (
      @CompanyEsId,
      N'MAIN',
      N'Madrid Centro',
      N'Calle Alcala 1, Madrid',
      N'+34 910000000',
      1,
      0
    );

    SET @BranchEsId = SCOPE_IDENTITY();
  END;
  ELSE IF COL_LENGTH('cfg.Branch', 'CountryCode') IS NOT NULL
  BEGIN
    EXEC sp_executesql
      N'UPDATE cfg.Branch SET CountryCode = @CountryCode WHERE BranchId = @BranchId;',
      N'@CountryCode CHAR(2), @BranchId INT',
      @CountryCode = 'ES',
      @BranchId = @BranchEsId;
  END;

  IF @BranchEsId IS NOT NULL
     AND COL_LENGTH('cfg.Branch', 'CountryCode') IS NOT NULL
  BEGIN
    EXEC sp_executesql
      N'UPDATE cfg.Branch SET CountryCode = @CountryCode WHERE BranchId = @BranchId;',
      N'@CountryCode CHAR(2), @BranchId INT',
      @CountryCode = 'ES',
      @BranchId = @BranchEsId;
  END;

  SELECT TOP (1) @DefaultCompanyId = CompanyId
  FROM cfg.Company
  WHERE CompanyCode = N'DEFAULT';

  SELECT TOP (1) @DefaultBranchId = BranchId
  FROM cfg.Branch
  WHERE CompanyId = @DefaultCompanyId
    AND BranchCode = N'MAIN';

  IF @DefaultCompanyId IS NOT NULL
  BEGIN
    SELECT TOP (1) @DefaultBranchEsId = BranchId
    FROM cfg.Branch
    WHERE CompanyId = @DefaultCompanyId
      AND BranchCode = N'ES01';

    IF @DefaultBranchEsId IS NULL
    BEGIN
      INSERT INTO cfg.Branch (
        CompanyId,
        BranchCode,
        BranchName,
        AddressLine,
        Phone,
        IsActive,
        IsDeleted
      )
      VALUES (
        @DefaultCompanyId,
        N'ES01',
        N'Sucursal Espana',
        N'Calle Gran Via 10, Madrid',
        N'+34 910000001',
        1,
        0
      );

      SET @DefaultBranchEsId = SCOPE_IDENTITY();
    END;

    IF @DefaultBranchEsId IS NOT NULL
       AND COL_LENGTH('cfg.Branch', 'CountryCode') IS NOT NULL
    BEGIN
      EXEC sp_executesql
        N'UPDATE cfg.Branch SET CountryCode = @CountryCode WHERE BranchId = @BranchId;',
        N'@CountryCode CHAR(2), @BranchId INT',
        @CountryCode = 'ES',
        @BranchId = @DefaultBranchEsId;
    END;
  END;

  IF OBJECT_ID(N'sec.UserCompanyAccess', N'U') IS NOT NULL
  BEGIN
    MERGE sec.UserCompanyAccess AS tgt
    USING (
      SELECT N'SUP' AS CodUsuario, @CompanyEsId AS CompanyId, @BranchEsId AS BranchId, CAST(0 AS bit) AS IsDefault
      UNION ALL
      SELECT N'OPERADOR', @CompanyEsId, @BranchEsId, CAST(0 AS bit)
      UNION ALL
      SELECT N'SUP', @DefaultCompanyId, @DefaultBranchEsId, CAST(0 AS bit)
      WHERE @DefaultCompanyId IS NOT NULL AND @DefaultBranchEsId IS NOT NULL
      UNION ALL
      SELECT N'OPERADOR', @DefaultCompanyId, @DefaultBranchEsId, CAST(0 AS bit)
      WHERE @DefaultCompanyId IS NOT NULL AND @DefaultBranchEsId IS NOT NULL
      UNION ALL
      SELECT N'OPERADOR', @DefaultCompanyId, @DefaultBranchId, CAST(1 AS bit)
      WHERE @DefaultCompanyId IS NOT NULL AND @DefaultBranchId IS NOT NULL
    ) AS src
      ON tgt.CodUsuario = src.CodUsuario
     AND tgt.CompanyId = src.CompanyId
     AND tgt.BranchId = src.BranchId
    WHEN MATCHED THEN
      UPDATE SET
        IsActive = 1,
        IsDefault = src.IsDefault,
        UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (CodUsuario, CompanyId, BranchId, IsDefault, IsActive)
      VALUES (src.CodUsuario, src.CompanyId, src.BranchId, src.IsDefault, 1);
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;
  THROW;
END CATCH;
