-- =============================================
-- FUNCTION: dbo.fn_EvaluarExpr (SQL_SCALAR_FUNCTION)
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE FUNCTION dbo.fn_EvaluarExpr (@Expr NVARCHAR(MAX))
RETURNS DECIMAL(18,6)
AS
BEGIN
  RETURN TRY_CONVERT(DECIMAL(18,6), @Expr);
END

GO
 
 
-- =============================================
-- FUNCTION: dbo.fn_Nomina_ContarDomingos (SQL_SCALAR_FUNCTION)
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE FUNCTION dbo.fn_Nomina_ContarDomingos(
  @FechaDesde DATE,
  @FechaHasta DATE
)
RETURNS INT
AS
BEGIN
  DECLARE @Actual DATE = @FechaDesde;
  DECLARE @Domingos INT = 0;

  WHILE (@Actual <= @FechaHasta)
  BEGIN
    IF DATEPART(WEEKDAY, @Actual) = 1 SET @Domingos = @Domingos + 1;
    SET @Actual = DATEADD(DAY, 1, @Actual);
  END

  RETURN @Domingos;
END

GO
 
 
-- =============================================
-- FUNCTION: dbo.fn_Nomina_ContarFeriados (SQL_SCALAR_FUNCTION)
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE FUNCTION dbo.fn_Nomina_ContarFeriados(
  @FechaDesde DATE,
  @FechaHasta DATE
)
RETURNS INT
AS
BEGIN
  -- En DatqBoxWeb canónico no se depende de dbo.Feriados legacy.
  -- Se deja en 0 y puede ser reemplazado por catálogo canónico si se incorpora.
  RETURN 0;
END

GO
 
 
-- =============================================
-- FUNCTION: dbo.fn_Nomina_ContarLunes (SQL_SCALAR_FUNCTION)
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE FUNCTION dbo.fn_Nomina_ContarLunes(
  @FechaDesde DATE,
  @FechaHasta DATE
)
RETURNS INT
AS
BEGIN
  DECLARE @Actual DATE = @FechaDesde;
  DECLARE @Lunes INT = 0;

  WHILE (@Actual <= @FechaHasta)
  BEGIN
    -- (DATEDIFF(DAY, '2000-01-03', @Actual) % 7) = 0 identifica lunes
    -- independientemente del valor de DATEFIRST.
    IF (DATEDIFF(DAY, '2000-01-03', @Actual) % 7) = 0
      SET @Lunes = @Lunes + 1;
    SET @Actual = DATEADD(DAY, 1, @Actual);
  END

  RETURN @Lunes;
END

GO
 
 
-- =============================================
-- FUNCTION: dbo.fn_Nomina_GetVariable (SQL_SCALAR_FUNCTION)
-- =============================================
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE FUNCTION dbo.fn_Nomina_GetVariable (
  @SessionID NVARCHAR(80),
  @Variable NVARCHAR(120)
)
RETURNS DECIMAL(18,6)
AS
BEGIN
  DECLARE @Valor DECIMAL(18,6) = 0;
  SELECT TOP 1 @Valor = Valor
  FROM hr.PayrollCalcVariable
  WHERE SessionID = @SessionID AND Variable = @Variable;

  RETURN ISNULL(@Valor, 0);
END

GO
 
 
