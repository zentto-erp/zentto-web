-- =============================================
-- SP: Copiar conceptos desde NominaConceptoLegal a ConcNom
-- Para una CO_NOMINA dada (ej. tipo de nomina del empleado) y una convencion/tipo de calculo.
-- Permite "aplicar" la base de conocimiento legal a la nomina operativa.
-- =============================================

IF OBJECT_ID('dbo.sp_Nomina_CopiarConceptosDesdeLegal', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal;
GO

CREATE PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal
    @CoNomina     NVARCHAR(15),   -- Codigo de nomina destino (ej. MENSUAL, PETROLERO, CONSTRUCCION)
    @Convencion   NVARCHAR(20),   -- LOT, CCT_PETROLERO, CCT_CONSTRUCCION
    @TipoCalculo  NVARCHAR(20),   -- MENSUAL, VACACIONES, LIQUIDACION, etc.
    @Sobrescribir BIT = 0,        -- 1 = reemplazar concepto si ya existe
    @Resultado    INT OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje = '';

    IF NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal WHERE Convencion = @Convencion AND TipoCalculo = @TipoCalculo)
    BEGIN
        SET @Resultado = -1;
        SET @Mensaje = 'No hay conceptos legales para Convencion=' + @Convencion + ' y TipoCalculo=' + @TipoCalculo;
        RETURN;
    END

    BEGIN TRY
        IF @Sobrescribir = 1
        BEGIN
            DELETE d
            FROM dbo.ConcNom d
            INNER JOIN dbo.NominaConceptoLegal l ON l.CO_CONCEPT = d.CO_CONCEPT AND l.Convencion = @Convencion AND l.TipoCalculo = @TipoCalculo
            WHERE d.CO_NOMINA = @CoNomina;
        END

        INSERT INTO dbo.ConcNom (CO_CONCEPT, CO_NOMINA, NB_CONCEPTO, FORMULA, SOBRE, CLASE, TIPO, USO, BONIFICABLE, Antiguedad, Contable, Aplica, Defecto)
        SELECT
            l.CO_CONCEPT,
            @CoNomina,
            l.NB_CONCEPTO,
            l.FORMULA,
            l.SOBRE,
            NULL,
            l.TIPO,
            NULL,
            l.BONIFICABLE,
            NULL,
            NULL,
            'S',
            NULL
        FROM dbo.NominaConceptoLegal l
        WHERE l.Convencion = @Convencion
          AND l.TipoCalculo = @TipoCalculo
          AND l.Activo = 1
          AND (@Sobrescribir = 0 AND NOT EXISTS (SELECT 1 FROM dbo.ConcNom c WHERE c.CO_CONCEPT = l.CO_CONCEPT AND c.CO_NOMINA = @CoNomina));

        SET @Resultado = @@ROWCOUNT;
        SET @Mensaje = CAST(@Resultado AS NVARCHAR(10)) + ' concepto(s) copiados a CO_NOMINA=' + @CoNomina;
    END TRY
    BEGIN CATCH
        SET @Resultado = -99;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH
END
GO
