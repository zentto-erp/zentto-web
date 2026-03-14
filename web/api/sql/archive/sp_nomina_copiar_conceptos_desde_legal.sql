-- =============================================
-- SP: Copiar conceptos legales canónicos a una nómina destino
-- Fuente y destino: hr.PayrollConcept
-- =============================================

IF OBJECT_ID('dbo.sp_Nomina_CopiarConceptosDesdeLegal', 'P') IS NOT NULL
  DROP PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal;
GO

CREATE PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal
  @CoNomina     NVARCHAR(30),   -- Código nómina destino (PayrollCode)
  @Convencion   NVARCHAR(30),   -- Convención origen (ConventionCode)
  @TipoCalculo  NVARCHAR(30),   -- Tipo cálculo origen (CalculationType)
  @Sobrescribir BIT = 0,        -- 1 = actualiza conceptos existentes
  @Resultado    INT OUTPUT,
  @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET XACT_ABORT ON;

  SET @Resultado = 0;
  SET @Mensaje = N'';

  DECLARE @CompanyId INT = NULL;
  DECLARE @BranchId INT = NULL;
  EXEC dbo.sp_Nomina_GetScope @CompanyId OUTPUT, @BranchId OUTPUT;

  IF @CompanyId IS NULL
  BEGIN
    SET @Resultado = -2;
    SET @Mensaje = N'No se pudo resolver CompanyId en cfg.Company';
    RETURN;
  END;

  IF NOT EXISTS (
    SELECT 1
    FROM hr.PayrollConcept pc
    WHERE pc.CompanyId = @CompanyId
      AND pc.ConventionCode = @Convencion
      AND pc.CalculationType = @TipoCalculo
      AND pc.IsActive = 1
  )
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'No hay conceptos legales en hr.PayrollConcept para Convencion=' + @Convencion + N' y TipoCalculo=' + @TipoCalculo;
    RETURN;
  END;

  BEGIN TRY
    DECLARE @Changes TABLE (ActionName NVARCHAR(10));

    ;WITH SourceRows AS (
      SELECT
        pc.CompanyId,
        @CoNomina AS PayrollCode,
        pc.ConceptCode,
        pc.ConceptName,
        pc.Formula,
        pc.BaseExpression,
        pc.ConceptClass,
        pc.ConceptType,
        pc.UsageType,
        pc.IsBonifiable,
        pc.IsSeniority,
        pc.AccountingAccountCode,
        pc.AppliesFlag,
        pc.DefaultValue,
        pc.ConventionCode,
        pc.CalculationType,
        pc.LotttArticle,
        pc.CcpClause,
        pc.SortOrder,
        pc.IsActive
      FROM hr.PayrollConcept pc
      WHERE pc.CompanyId = @CompanyId
        AND pc.ConventionCode = @Convencion
        AND pc.CalculationType = @TipoCalculo
        AND pc.IsActive = 1
    )
    MERGE hr.PayrollConcept AS target
    USING SourceRows AS src
    ON target.CompanyId = src.CompanyId
       AND target.PayrollCode = src.PayrollCode
       AND target.ConceptCode = src.ConceptCode
       AND ISNULL(target.ConventionCode, N'') = ISNULL(src.ConventionCode, N'')
       AND ISNULL(target.CalculationType, N'') = ISNULL(src.CalculationType, N'')
    WHEN MATCHED AND @Sobrescribir = 1 THEN
      UPDATE SET
        ConceptName = src.ConceptName,
        Formula = src.Formula,
        BaseExpression = src.BaseExpression,
        ConceptClass = src.ConceptClass,
        ConceptType = src.ConceptType,
        UsageType = src.UsageType,
        IsBonifiable = src.IsBonifiable,
        IsSeniority = src.IsSeniority,
        AccountingAccountCode = src.AccountingAccountCode,
        AppliesFlag = src.AppliesFlag,
        DefaultValue = src.DefaultValue,
        LotttArticle = src.LotttArticle,
        CcpClause = src.CcpClause,
        SortOrder = src.SortOrder,
        IsActive = src.IsActive,
        UpdatedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
      INSERT (
        CompanyId, PayrollCode, ConceptCode, ConceptName, Formula, BaseExpression,
        ConceptClass, ConceptType, UsageType, IsBonifiable, IsSeniority,
        AccountingAccountCode, AppliesFlag, DefaultValue, ConventionCode,
        CalculationType, LotttArticle, CcpClause, SortOrder, IsActive,
        CreatedAt, UpdatedAt
      )
      VALUES (
        src.CompanyId, src.PayrollCode, src.ConceptCode, src.ConceptName, src.Formula, src.BaseExpression,
        src.ConceptClass, src.ConceptType, src.UsageType, src.IsBonifiable, src.IsSeniority,
        src.AccountingAccountCode, src.AppliesFlag, src.DefaultValue, src.ConventionCode,
        src.CalculationType, src.LotttArticle, src.CcpClause, src.SortOrder, src.IsActive,
        SYSUTCDATETIME(), SYSUTCDATETIME()
      )
    OUTPUT $action INTO @Changes(ActionName);

    SELECT @Resultado = COUNT(1) FROM @Changes;
    SET @Mensaje = CAST(@Resultado AS NVARCHAR(20)) + N' concepto(s) sincronizados en hr.PayrollConcept para PayrollCode=' + @CoNomina;
  END TRY
  BEGIN CATCH
    SET @Resultado = -99;
    SET @Mensaje = ERROR_MESSAGE();
  END CATCH
END
GO
