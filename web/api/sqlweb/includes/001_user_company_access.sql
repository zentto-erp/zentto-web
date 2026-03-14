SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;

BEGIN TRY
  BEGIN TRAN;

  IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = N'sec'
      AND t.name = N'UserCompanyAccess'
  )
  BEGIN
    CREATE TABLE sec.UserCompanyAccess (
      UserCompanyAccessId BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CodUsuario NVARCHAR(50) NOT NULL,
      CompanyId INT NOT NULL,
      BranchId INT NOT NULL,
      IsDefault BIT NOT NULL CONSTRAINT DF_sec_UserCompanyAccess_IsDefault DEFAULT (0),
      IsActive BIT NOT NULL CONSTRAINT DF_sec_UserCompanyAccess_IsActive DEFAULT (1),
      CreatedAt DATETIME2 NOT NULL CONSTRAINT DF_sec_UserCompanyAccess_CreatedAt DEFAULT (SYSUTCDATETIME()),
      UpdatedAt DATETIME2 NOT NULL CONSTRAINT DF_sec_UserCompanyAccess_UpdatedAt DEFAULT (SYSUTCDATETIME()),
      CreatedByUserId INT NULL,
      UpdatedByUserId INT NULL,
      RowVer ROWVERSION NOT NULL,
      CONSTRAINT FK_sec_UserCompanyAccess_Company
        FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
      CONSTRAINT FK_sec_UserCompanyAccess_Branch
        FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId)
    );

    CREATE UNIQUE INDEX UX_sec_UserCompanyAccess_CodEmpresaSucursal
      ON sec.UserCompanyAccess(CodUsuario, CompanyId, BranchId);

    CREATE UNIQUE INDEX UX_sec_UserCompanyAccess_DefaultPorUsuario
      ON sec.UserCompanyAccess(CodUsuario)
      WHERE IsDefault = 1 AND IsActive = 1;

    CREATE INDEX IX_sec_UserCompanyAccess_CompanyBranch
      ON sec.UserCompanyAccess(CompanyId, BranchId, IsActive);
  END;

  DECLARE @DefaultCompanyId INT = (
    SELECT TOP (1) CompanyId
    FROM cfg.Company
    WHERE CompanyCode = N'DEFAULT'
      AND IsActive = 1
      AND IsDeleted = 0
    ORDER BY CompanyId
  );

  IF @DefaultCompanyId IS NULL
    SET @DefaultCompanyId = (
      SELECT TOP (1) CompanyId
      FROM cfg.Company
      WHERE IsActive = 1
        AND IsDeleted = 0
      ORDER BY CompanyId
    );

  DECLARE @DefaultBranchId INT = (
    SELECT TOP (1) BranchId
    FROM cfg.Branch
    WHERE CompanyId = @DefaultCompanyId
      AND BranchCode = N'MAIN'
      AND IsActive = 1
      AND IsDeleted = 0
    ORDER BY BranchId
  );

  IF @DefaultBranchId IS NULL
    SET @DefaultBranchId = (
      SELECT TOP (1) BranchId
      FROM cfg.Branch
      WHERE CompanyId = @DefaultCompanyId
        AND IsActive = 1
        AND IsDeleted = 0
      ORDER BY BranchId
    );

  IF @DefaultCompanyId IS NOT NULL
     AND @DefaultBranchId IS NOT NULL
  BEGIN
    MERGE sec.UserCompanyAccess AS tgt
    USING (
      SELECT DISTINCT
        u.Cod_Usuario AS CodUsuario,
        @DefaultCompanyId AS CompanyId,
        @DefaultBranchId AS BranchId
      FROM Usuarios u
    ) AS src
      ON tgt.CodUsuario = src.CodUsuario
     AND tgt.CompanyId = src.CompanyId
     AND tgt.BranchId = src.BranchId
    WHEN MATCHED THEN
      UPDATE SET
        IsActive = 1,
        UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (
        CodUsuario,
        CompanyId,
        BranchId,
        IsDefault,
        IsActive
      )
      VALUES (
        src.CodUsuario,
        src.CompanyId,
        src.BranchId,
        1,
        1
      );

    ;WITH ranked AS (
      SELECT
        UserCompanyAccessId,
        ROW_NUMBER() OVER (
          PARTITION BY CodUsuario
          ORDER BY
            CASE WHEN IsDefault = 1 THEN 0 ELSE 1 END,
            UserCompanyAccessId
        ) AS rn
      FROM sec.UserCompanyAccess
      WHERE IsActive = 1
    )
    UPDATE a
    SET
      IsDefault = CASE WHEN r.rn = 1 THEN 1 ELSE 0 END,
      UpdatedAt = SYSUTCDATETIME()
    FROM sec.UserCompanyAccess a
    INNER JOIN ranked r
      ON r.UserCompanyAccessId = a.UserCompanyAccessId;
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0
    ROLLBACK TRAN;

  THROW;
END CATCH;
