SET NOCOUNT ON;
SET XACT_ABORT ON;

/*
  Sincroniza semillas legacy de nomina a tablas canonicas:
  - ConstanteNomina -> NominaConstante
*/

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID(N'dbo.ConstanteNomina', N'U') IS NOT NULL
  BEGIN
    MERGE dbo.NominaConstante AS tgt
    USING (
      SELECT
        Codigo = CAST(c.Codigo AS NVARCHAR(50)),
        Nombre = CAST(c.Nombre AS NVARCHAR(100)),
        Valor = CAST(c.Valor AS DECIMAL(18,6)),
        Origen = CAST(c.Origen AS NVARCHAR(50))
      FROM dbo.ConstanteNomina c
    ) AS src
      ON tgt.Codigo = src.Codigo
    WHEN MATCHED THEN
      UPDATE SET
        tgt.Nombre = src.Nombre,
        tgt.Valor = src.Valor,
        tgt.Origen = src.Origen,
        tgt.IsDeleted = 0,
        tgt.DeletedAt = NULL,
        tgt.DeletedBy = NULL,
        tgt.UpdatedAt = SYSUTCDATETIME(),
        tgt.UpdatedBy = N'SEED_SYNC'
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (Codigo, Nombre, Valor, Origen, CreatedBy, UpdatedBy)
      VALUES (src.Codigo, src.Nombre, src.Valor, src.Origen, N'SEED_SYNC', N'SEED_SYNC');
  END;

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  THROW;
END CATCH;

SELECT
  TotalConstantesLegacy = CASE WHEN OBJECT_ID(N'dbo.ConstanteNomina', N'U') IS NOT NULL THEN (SELECT COUNT(*) FROM dbo.ConstanteNomina) ELSE 0 END,
  TotalConstantesCanonicas = (SELECT COUNT(*) FROM dbo.NominaConstante WHERE IsDeleted = 0),
  TotalConceptosLegales = (SELECT COUNT(*) FROM dbo.NominaConceptoLegal WHERE IsDeleted = 0);
