/*
 * ============================================================================
 *  Archivo : usp_acct_inflation.sql
 *  Esquema : acct (contabilidad legal - ajuste por inflacion)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-15
 *
 *  Descripcion:
 *    Stored procedures para el modulo de ajuste por inflacion.
 *    Implementa el metodo NGP (Nivel General de Precios) segun:
 *      - BA VEN-NIF 2 (criterios inflacion en estados financieros)
 *      - NIC 29 (informacion financiera en economias hiperinflacionarias)
 *      - DPC-10 (declaracion de principios contables N 10)
 *      - LISLR Art. 173-193 (ajuste fiscal por inflacion)
 *
 *  Procedimientos (11):
 *    usp_Acct_InflationIndex_List, usp_Acct_InflationIndex_Upsert,
 *    usp_Acct_InflationIndex_BulkLoad,
 *    usp_Acct_AccountMonetaryClass_List, usp_Acct_AccountMonetaryClass_Upsert,
 *    usp_Acct_AccountMonetaryClass_AutoClassify,
 *    usp_Acct_Inflation_Calculate, usp_Acct_Inflation_Post,
 *    usp_Acct_Inflation_Void,
 *    usp_Acct_Report_BalanceReexpresado, usp_Acct_Report_REME
 *
 *  Patron : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  SP 1: usp_Acct_InflationIndex_List
--  Descripcion : Lista indices de precios por pais y rango de periodos.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_InflationIndex_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_InflationIndex_List;
GO
CREATE PROCEDURE dbo.usp_Acct_InflationIndex_List
    @CompanyId   INT,
    @CountryCode CHAR(2)       = 'VE',
    @IndexName   NVARCHAR(30)  = 'INPC',
    @YearFrom    SMALLINT      = NULL,
    @YearTo      SMALLINT      = NULL,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.InflationIndex
    WHERE  CompanyId   = @CompanyId
      AND  CountryCode = @CountryCode
      AND  IndexName   = @IndexName
      AND  (@YearFrom IS NULL OR CAST(LEFT(PeriodCode, 4) AS SMALLINT) >= @YearFrom)
      AND  (@YearTo   IS NULL OR CAST(LEFT(PeriodCode, 4) AS SMALLINT) <= @YearTo);

    SELECT InflationIndexId,
           CountryCode,
           IndexName,
           PeriodCode,
           IndexValue,
           SourceReference,
           CreatedAt,
           UpdatedAt
    FROM   acct.InflationIndex
    WHERE  CompanyId   = @CompanyId
      AND  CountryCode = @CountryCode
      AND  IndexName   = @IndexName
      AND  (@YearFrom IS NULL OR CAST(LEFT(PeriodCode, 4) AS SMALLINT) >= @YearFrom)
      AND  (@YearTo   IS NULL OR CAST(LEFT(PeriodCode, 4) AS SMALLINT) <= @YearTo)
    ORDER BY PeriodCode;
END;
GO

-- =============================================================================
--  SP 2: usp_Acct_InflationIndex_Upsert
--  Descripcion : Inserta o actualiza un indice mensual.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_InflationIndex_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_InflationIndex_Upsert;
GO
CREATE PROCEDURE dbo.usp_Acct_InflationIndex_Upsert
    @CompanyId       INT,
    @CountryCode     CHAR(2),
    @IndexName       NVARCHAR(30),
    @PeriodCode      CHAR(6),
    @IndexValue      DECIMAL(18,6),
    @SourceReference NVARCHAR(200) = NULL,
    @Resultado       INT           OUTPUT,
    @Mensaje         NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @IndexValue <= 0
    BEGIN
        SET @Mensaje = N'El valor del indice debe ser mayor a cero.';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM acct.InflationIndex
               WHERE CompanyId = @CompanyId AND CountryCode = @CountryCode
                 AND IndexName = @IndexName AND PeriodCode = @PeriodCode)
    BEGIN
        UPDATE acct.InflationIndex
        SET    IndexValue      = @IndexValue,
               SourceReference = ISNULL(@SourceReference, SourceReference),
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  CompanyId = @CompanyId AND CountryCode = @CountryCode
          AND  IndexName = @IndexName AND PeriodCode = @PeriodCode;

        SET @Resultado = 1;
        SET @Mensaje   = N'Indice actualizado correctamente.';
    END
    ELSE
    BEGIN
        INSERT INTO acct.InflationIndex (CompanyId, CountryCode, IndexName, PeriodCode, IndexValue, SourceReference)
        VALUES (@CompanyId, @CountryCode, @IndexName, @PeriodCode, @IndexValue, @SourceReference);

        SET @Resultado = 1;
        SET @Mensaje   = N'Indice creado correctamente.';
    END;
END;
GO

-- =============================================================================
--  SP 3: usp_Acct_InflationIndex_BulkLoad
--  Descripcion : Carga masiva de indices via OPENJSON.
--  JSON format : [{"periodCode":"202601","indexValue":1234.56,"source":"BCV"}]
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_InflationIndex_BulkLoad', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_InflationIndex_BulkLoad;
GO
CREATE PROCEDURE dbo.usp_Acct_InflationIndex_BulkLoad
    @CompanyId   INT,
    @CountryCode CHAR(2),
    @IndexName   NVARCHAR(30),
    @JsonData    NVARCHAR(MAX),
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @Inserted INT = 0, @Updated INT = 0;

    BEGIN TRY
        BEGIN TRAN;

        -- XML format: <rows><r pc="202601" iv="1234.56" sr="BCV"/></rows>
        DECLARE @hDoc INT;
        EXEC sp_xml_preparedocument @hDoc OUTPUT, @JsonData;

        ;MERGE acct.InflationIndex AS T
        USING (
            SELECT pc AS periodCode, iv AS indexValue, sr AS [source]
            FROM OPENXML(@hDoc, '/rows/r', 1)
            WITH (
                pc CHAR(6)        '@pc',
                iv DECIMAL(18,6)  '@iv',
                sr NVARCHAR(200)  '@sr'
            )
        ) AS S
        ON T.CompanyId = @CompanyId AND T.CountryCode = @CountryCode
           AND T.IndexName = @IndexName AND T.PeriodCode = S.periodCode
        WHEN MATCHED THEN
            UPDATE SET IndexValue = S.indexValue,
                       SourceReference = ISNULL(S.[source], T.SourceReference),
                       UpdatedAt = SYSUTCDATETIME()
        WHEN NOT MATCHED THEN
            INSERT (CompanyId, CountryCode, IndexName, PeriodCode, IndexValue, SourceReference)
            VALUES (@CompanyId, @CountryCode, @IndexName, S.periodCode, S.indexValue, S.[source]);

        SET @Inserted = @@ROWCOUNT;
        EXEC sp_xml_removedocument @hDoc;
        COMMIT;

        SET @Resultado = 1;
        SET @Mensaje   = CONCAT(N'Carga masiva completada: ', @Inserted, N' registros procesados.');
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 4: usp_Acct_AccountMonetaryClass_List
--  Descripcion : Lista la clasificacion monetaria de cuentas contables.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_AccountMonetaryClass_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_AccountMonetaryClass_List;
GO
CREATE PROCEDURE dbo.usp_Acct_AccountMonetaryClass_List
    @CompanyId      INT,
    @Classification NVARCHAR(20) = NULL,
    @Search         NVARCHAR(100) = NULL,
    @TotalCount     INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   acct.AccountMonetaryClass mc
    JOIN   acct.Account a ON a.AccountId = mc.AccountId AND a.CompanyId = mc.CompanyId
    WHERE  mc.CompanyId = @CompanyId
      AND  mc.IsActive = 1
      AND  (@Classification IS NULL OR mc.Classification = @Classification)
      AND  (@Search IS NULL OR a.AccountCode LIKE '%' + @Search + '%' OR a.AccountName LIKE '%' + @Search + '%');

    SELECT mc.AccountMonetaryClassId,
           a.AccountId,
           a.AccountCode,
           a.AccountName,
           a.AccountType,
           a.AccountLevel,
           a.AllowsPosting,
           mc.Classification,
           mc.SubClassification,
           mc.ReexpressionAccountId,
           mc.IsActive,
           mc.UpdatedAt
    FROM   acct.AccountMonetaryClass mc
    JOIN   acct.Account a ON a.AccountId = mc.AccountId AND a.CompanyId = mc.CompanyId
    WHERE  mc.CompanyId = @CompanyId
      AND  mc.IsActive = 1
      AND  (@Classification IS NULL OR mc.Classification = @Classification)
      AND  (@Search IS NULL OR a.AccountCode LIKE '%' + @Search + '%' OR a.AccountName LIKE '%' + @Search + '%')
    ORDER BY a.AccountCode;
END;
GO

-- =============================================================================
--  SP 5: usp_Acct_AccountMonetaryClass_Upsert
--  Descripcion : Clasificar una cuenta como monetaria o no monetaria.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_AccountMonetaryClass_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_AccountMonetaryClass_Upsert;
GO
CREATE PROCEDURE dbo.usp_Acct_AccountMonetaryClass_Upsert
    @CompanyId            INT,
    @AccountId            BIGINT,
    @Classification       NVARCHAR(20),
    @SubClassification    NVARCHAR(40) = NULL,
    @ReexpressionAccountId BIGINT      = NULL,
    @Resultado            INT          OUTPUT,
    @Mensaje              NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    IF @Classification NOT IN ('MONETARY', 'NON_MONETARY')
    BEGIN
        SET @Mensaje = N'Clasificacion invalida. Usar MONETARY o NON_MONETARY.';
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM acct.Account WHERE AccountId = @AccountId AND CompanyId = @CompanyId)
    BEGIN
        SET @Mensaje = N'Cuenta contable no encontrada.';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM acct.AccountMonetaryClass WHERE CompanyId = @CompanyId AND AccountId = @AccountId)
    BEGIN
        UPDATE acct.AccountMonetaryClass
        SET    Classification       = @Classification,
               SubClassification    = @SubClassification,
               ReexpressionAccountId = @ReexpressionAccountId,
               UpdatedAt            = SYSUTCDATETIME()
        WHERE  CompanyId = @CompanyId AND AccountId = @AccountId;
    END
    ELSE
    BEGIN
        INSERT INTO acct.AccountMonetaryClass (CompanyId, AccountId, Classification, SubClassification, ReexpressionAccountId)
        VALUES (@CompanyId, @AccountId, @Classification, @SubClassification, @ReexpressionAccountId);
    END;

    SET @Resultado = 1;
    SET @Mensaje   = N'Clasificacion guardada correctamente.';
END;
GO

-- =============================================================================
--  SP 6: usp_Acct_AccountMonetaryClass_AutoClassify
--  Descripcion : Auto-clasifica cuentas segun tipo contable.
--    Ref DPC-10 parrafos 15-22:
--      MONETARY: Efectivo, CxC, CxP, prestamos, inversiones a valor nominal
--      NON_MONETARY: Inventarios, activos fijos, patrimonio, intangibles
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_AccountMonetaryClass_AutoClassify', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_AccountMonetaryClass_AutoClassify;
GO
CREATE PROCEDURE dbo.usp_Acct_AccountMonetaryClass_AutoClassify
    @CompanyId INT,
    @Resultado INT           OUTPUT,
    @Mensaje   NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @Processed INT = 0;

    -- Auto-clasificar cuentas que permiten posting y no tienen clasificacion
    INSERT INTO acct.AccountMonetaryClass (CompanyId, AccountId, Classification, SubClassification)
    SELECT a.CompanyId,
           a.AccountId,
           CASE
               -- ACTIVOS MONETARIOS: efectivo, bancos, CxC, inversiones temporales
               WHEN a.AccountType = 'A' AND (
                   a.AccountCode LIKE '1.1.01%' OR  -- Caja
                   a.AccountCode LIKE '1.1.02%' OR  -- Bancos
                   a.AccountCode LIKE '1.1.03%' OR  -- Inversiones temporales
                   a.AccountCode LIKE '1.1.04%' OR  -- CxC clientes
                   a.AccountCode LIKE '1.1.05%' OR  -- CxC empleados
                   a.AccountCode LIKE '1.1.06%' OR  -- Anticipos
                   a.AccountName LIKE '%caja%' OR
                   a.AccountName LIKE '%banco%' OR
                   a.AccountName LIKE '%cobrar%'
               ) THEN 'MONETARY'
               -- ACTIVOS NO MONETARIOS: inventario, activos fijos, intangibles
               WHEN a.AccountType = 'A' AND (
                   a.AccountCode LIKE '1.1.07%' OR  -- Inventarios
                   a.AccountCode LIKE '1.2%'    OR  -- Activo no corriente
                   a.AccountName LIKE '%inventar%' OR
                   a.AccountName LIKE '%equipo%' OR
                   a.AccountName LIKE '%terreno%' OR
                   a.AccountName LIKE '%edificio%' OR
                   a.AccountName LIKE '%vehiculo%' OR
                   a.AccountName LIKE '%mobiliario%' OR
                   a.AccountName LIKE '%intangible%'
               ) THEN 'NON_MONETARY'
               -- PASIVOS: generalmente MONETARY (deudas en valor nominal)
               WHEN a.AccountType = 'P' THEN 'MONETARY'
               -- PATRIMONIO: NON_MONETARY (debe reexpresarse)
               WHEN a.AccountType = 'C' THEN 'NON_MONETARY'
               -- INGRESOS y GASTOS: se excluyen del ajuste directo
               -- (se reexpresan implicitamente via resultado monetario)
               WHEN a.AccountType IN ('I', 'G') THEN 'MONETARY'
               -- Default: MONETARY
               ELSE 'MONETARY'
           END,
           CASE
               WHEN a.AccountType = 'A' AND (a.AccountCode LIKE '1.1.01%' OR a.AccountCode LIKE '1.1.02%' OR a.AccountName LIKE '%caja%' OR a.AccountName LIKE '%banco%') THEN 'CASH'
               WHEN a.AccountType = 'A' AND (a.AccountCode LIKE '1.1.04%' OR a.AccountName LIKE '%cobrar%') THEN 'RECEIVABLE'
               WHEN a.AccountType = 'A' AND (a.AccountCode LIKE '1.1.07%' OR a.AccountName LIKE '%inventar%') THEN 'INVENTORY'
               WHEN a.AccountType = 'A' AND a.AccountCode LIKE '1.2%' THEN 'FIXED_ASSET'
               WHEN a.AccountType = 'P' AND (a.AccountName LIKE '%pagar%' OR a.AccountName LIKE '%proveedor%') THEN 'PAYABLE'
               WHEN a.AccountType = 'C' THEN 'EQUITY'
               ELSE NULL
           END
    FROM   acct.Account a
    WHERE  a.CompanyId     = @CompanyId
      AND  a.AllowsPosting = 1
      AND  a.IsActive      = 1
      AND  ISNULL(a.IsDeleted, 0) = 0
      AND  NOT EXISTS (
               SELECT 1 FROM acct.AccountMonetaryClass mc
               WHERE mc.CompanyId = @CompanyId AND mc.AccountId = a.AccountId
           );

    SET @Processed = @@ROWCOUNT;

    SET @Resultado = 1;
    SET @Mensaje   = CONCAT(N'Auto-clasificacion completada: ', @Processed, N' cuentas clasificadas.');
END;
GO

-- =============================================================================
--  SP 7: usp_Acct_Inflation_Calculate
--  Descripcion : Calcula ajuste por inflacion para un periodo usando metodo NGP.
--    Ref: BA VEN-NIF 2, NIC 29 parrafos 11-28
--    Factor = INPC_fin / INPC_base
--    Cada cuenta NON_MONETARY: saldo_ajustado = saldo_historico * factor
--    REME = suma de (ajustes no monetarios) - (variacion real del patrimonio)
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Inflation_Calculate', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Inflation_Calculate;
GO
CREATE PROCEDURE dbo.usp_Acct_Inflation_Calculate
    @CompanyId  INT,
    @BranchId   INT,
    @PeriodCode CHAR(6),
    @FiscalYear SMALLINT,
    @UserId     INT           = NULL,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    -- Validar que no exista ajuste previo activo para este periodo
    IF EXISTS (SELECT 1 FROM acct.InflationAdjustment
               WHERE CompanyId = @CompanyId AND BranchId = @BranchId
                 AND PeriodCode = @PeriodCode AND Status <> 'VOIDED')
    BEGIN
        SET @Mensaje = N'Ya existe un ajuste para este periodo. Anulelo primero.';
        RETURN;
    END;

    -- Obtener INPC base (inicio del anio fiscal) y fin (periodo actual)
    DECLARE @BasePeriod CHAR(6) = CAST(@FiscalYear AS CHAR(4)) + '01';
    DECLARE @BaseIndex  DECIMAL(18,6), @EndIndex DECIMAL(18,6);

    SELECT @BaseIndex = IndexValue
    FROM   acct.InflationIndex
    WHERE  CompanyId = @CompanyId AND CountryCode = 'VE' AND IndexName = 'INPC'
      AND  PeriodCode = @BasePeriod;

    SELECT @EndIndex = IndexValue
    FROM   acct.InflationIndex
    WHERE  CompanyId = @CompanyId AND CountryCode = 'VE' AND IndexName = 'INPC'
      AND  PeriodCode = @PeriodCode;

    IF @BaseIndex IS NULL
    BEGIN
        SET @Mensaje = CONCAT(N'No se encontro el indice INPC para el periodo base ', @BasePeriod);
        RETURN;
    END;
    IF @EndIndex IS NULL
    BEGIN
        SET @Mensaje = CONCAT(N'No se encontro el indice INPC para el periodo ', @PeriodCode);
        RETURN;
    END;
    IF @BaseIndex = 0
    BEGIN
        SET @Mensaje = N'El indice INPC base no puede ser cero.';
        RETURN;
    END;

    DECLARE @Factor DECIMAL(18,8) = @EndIndex / @BaseIndex;
    DECLARE @AccumInflation DECIMAL(18,6) = (@Factor - 1.0) * 100.0;

    -- Obtener fecha de corte del periodo
    DECLARE @FechaCorte DATE;
    SET @FechaCorte = EOMONTH(DATEFROMPARTS(@FiscalYear,
        CAST(RIGHT(@PeriodCode, 2) AS INT), 1));

    BEGIN TRY
        BEGIN TRAN;

        -- Insertar cabecera
        DECLARE @AdjId INT;
        INSERT INTO acct.InflationAdjustment (
            CompanyId, BranchId, CountryCode, PeriodCode, FiscalYear,
            AdjustmentDate, BaseIndexValue, EndIndexValue,
            AccumulatedInflation, ReexpressionFactor, Status, CreatedByUserId
        )
        VALUES (
            @CompanyId, @BranchId, 'VE', @PeriodCode, @FiscalYear,
            @FechaCorte, @BaseIndex, @EndIndex,
            @AccumInflation, @Factor, 'DRAFT', @UserId
        );
        SET @AdjId = SCOPE_IDENTITY();

        -- Calcular saldos historicos y ajustar cuentas no monetarias
        -- El saldo de cada cuenta se calcula como SUM(Debe) - SUM(Haber) para tipo A/G
        -- y SUM(Haber) - SUM(Debe) para tipo P/C/I
        INSERT INTO acct.InflationAdjustmentLine (
            InflationAdjustmentId, AccountId, AccountCode, AccountName,
            Classification, HistoricalBalance, ReexpressionFactor,
            AdjustedBalance, AdjustmentAmount
        )
        SELECT @AdjId,
               a.AccountId,
               a.AccountCode,
               a.AccountName,
               mc.Classification,
               -- Saldo historico
               ISNULL(SUM(
                   CASE WHEN a.AccountType IN ('A','G')
                        THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                        ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                   END
               ), 0) AS HistoricalBalance,
               -- Factor
               CASE WHEN mc.Classification = 'NON_MONETARY' THEN @Factor ELSE 1.0 END,
               -- Saldo ajustado
               CASE WHEN mc.Classification = 'NON_MONETARY'
                    THEN ROUND(ISNULL(SUM(
                         CASE WHEN a.AccountType IN ('A','G')
                              THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                              ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                         END
                    ), 0) * @Factor, 2)
                    ELSE ISNULL(SUM(
                         CASE WHEN a.AccountType IN ('A','G')
                              THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                              ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                         END
                    ), 0)
               END,
               -- Monto del ajuste
               CASE WHEN mc.Classification = 'NON_MONETARY'
                    THEN ROUND(ISNULL(SUM(
                         CASE WHEN a.AccountType IN ('A','G')
                              THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                              ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                         END
                    ), 0) * (@Factor - 1.0), 2)
                    ELSE 0
               END
        FROM   acct.Account a
        JOIN   acct.AccountMonetaryClass mc ON mc.AccountId = a.AccountId AND mc.CompanyId = a.CompanyId
        LEFT JOIN acct.JournalEntryLine jl ON jl.AccountId = a.AccountId
        LEFT JOIN acct.JournalEntry je ON je.JournalEntryId = jl.JournalEntryId
                                      AND je.CompanyId = @CompanyId
                                      AND je.Status = 'APPROVED'
                                      AND je.EntryDate <= @FechaCorte
        WHERE  a.CompanyId     = @CompanyId
          AND  a.AllowsPosting = 1
          AND  a.IsActive      = 1
          AND  mc.IsActive     = 1
        GROUP BY a.AccountId, a.AccountCode, a.AccountName, a.AccountType, mc.Classification
        HAVING ISNULL(SUM(
            CASE WHEN a.AccountType IN ('A','G')
                 THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                 ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
            END
        ), 0) <> 0;

        -- Calcular REME y total de ajustes
        DECLARE @TotalAdj DECIMAL(18,2), @REME DECIMAL(18,2);

        SELECT @TotalAdj = ISNULL(SUM(AdjustmentAmount), 0)
        FROM   acct.InflationAdjustmentLine
        WHERE  InflationAdjustmentId = @AdjId
          AND  Classification = 'NON_MONETARY';

        -- REME = Total ajuste activos no monetarios - Total ajuste pasivos/patrimonio no monetarios
        -- Simplificado: REME es el monto necesario para balancear el ajuste
        SET @REME = -@TotalAdj; -- signo inverso: si ajustes activos > ajustes pasivos = perdida monetaria

        UPDATE acct.InflationAdjustment
        SET    TotalAdjustmentAmount = @TotalAdj,
               TotalMonetaryGainLoss = @REME,
               UpdatedAt = SYSUTCDATETIME()
        WHERE  InflationAdjustmentId = @AdjId;

        COMMIT;

        SET @Resultado = 1;
        SET @Mensaje   = CONCAT(N'Ajuste calculado. Factor: ', FORMAT(@Factor, 'N8'),
                                N', REME: ', FORMAT(@REME, 'N2'),
                                N', Lineas: ', (SELECT COUNT(*) FROM acct.InflationAdjustmentLine WHERE InflationAdjustmentId = @AdjId));

        -- Retornar la cabecera
        SELECT * FROM acct.InflationAdjustment WHERE InflationAdjustmentId = @AdjId;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 8: usp_Acct_Inflation_Post
--  Descripcion : Publica el ajuste generando un asiento contable.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Inflation_Post', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Inflation_Post;
GO
CREATE PROCEDURE dbo.usp_Acct_Inflation_Post
    @CompanyId    INT,
    @AdjustmentId INT,
    @UserId       INT           = NULL,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @Status NVARCHAR(20), @PeriodCode CHAR(6), @AdjDate DATE, @REME DECIMAL(18,2);

    SELECT @Status     = Status,
           @PeriodCode = PeriodCode,
           @AdjDate    = AdjustmentDate,
           @REME       = TotalMonetaryGainLoss
    FROM   acct.InflationAdjustment
    WHERE  InflationAdjustmentId = @AdjustmentId AND CompanyId = @CompanyId;

    IF @Status IS NULL
    BEGIN
        SET @Mensaje = N'Ajuste no encontrado.';
        RETURN;
    END;
    IF @Status <> 'DRAFT'
    BEGIN
        SET @Mensaje = CONCAT(N'Solo se pueden publicar ajustes en estado DRAFT. Estado actual: ', @Status);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        -- Generar numero de asiento
        DECLARE @EntryNumber NVARCHAR(30) = CONCAT('AJI-', FORMAT(SYSUTCDATETIME(), 'yyyyMMddHHmmss'));

        -- Insertar asiento cabecera
        DECLARE @JournalEntryId BIGINT;
        INSERT INTO acct.JournalEntry (
            CompanyId, BranchId, EntryNumber, EntryDate, PeriodCode, EntryType,
            ReferenceNumber,
            Concept, CurrencyCode, ExchangeRate, TotalDebit, TotalCredit,
            Status, SourceModule, SourceDocumentType, SourceDocumentNo
        )
        SELECT CompanyId, BranchId, @EntryNumber, @AdjDate, @PeriodCode, N'AJUSTE_INFLACION',
               NULL,
               CONCAT(N'Ajuste por inflacion periodo ', @PeriodCode, N' - BA VEN-NIF 2 / NIC 29'),
               N'VES', 1.0, 0, 0, N'APPROVED', N'INFLACION', NULL, CAST(@AdjustmentId AS NVARCHAR(30))
        FROM   acct.InflationAdjustment WHERE InflationAdjustmentId = @AdjustmentId;

        SET @JournalEntryId = SCOPE_IDENTITY();

        -- Insertar lineas de detalle: una por cada cuenta no monetaria con ajuste
        DECLARE @LineNum INT = 0;
        DECLARE @TotalDebit DECIMAL(18,2) = 0, @TotalCredit DECIMAL(18,2) = 0;

        INSERT INTO acct.JournalEntryLine (
            JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description,
            DebitAmount, CreditAmount
        )
        SELECT @JournalEntryId,
               ROW_NUMBER() OVER (ORDER BY l.AccountCode),
               l.AccountId,
               l.AccountCode,
               CONCAT(N'Ajuste inflacion - ', l.AccountName),
               CASE WHEN l.AdjustmentAmount > 0 THEN l.AdjustmentAmount ELSE 0 END,
               CASE WHEN l.AdjustmentAmount < 0 THEN ABS(l.AdjustmentAmount) ELSE 0 END
        FROM   acct.InflationAdjustmentLine l
        WHERE  l.InflationAdjustmentId = @AdjustmentId
          AND  l.Classification = 'NON_MONETARY'
          AND  l.AdjustmentAmount <> 0;

        -- Calcular totales
        SELECT @TotalDebit  = ISNULL(SUM(DebitAmount), 0),
               @TotalCredit = ISNULL(SUM(CreditAmount), 0)
        FROM   acct.JournalEntryLine
        WHERE  JournalEntryId = @JournalEntryId;

        -- Agregar linea de REME (resultado monetario) para balancear
        DECLARE @REMEAccountId BIGINT;
        -- Buscar cuenta de resultado monetario (patron: 5.x.xx REME o similar)
        SELECT TOP 1 @REMEAccountId = AccountId
        FROM   acct.Account
        WHERE  CompanyId = @CompanyId
          AND  (AccountName LIKE '%resultado monetario%' OR AccountName LIKE '%REME%' OR AccountCode LIKE '5.4%')
          AND  AllowsPosting = 1;

        IF @REMEAccountId IS NOT NULL
        BEGIN
            DECLARE @REMEDebit DECIMAL(18,2) = 0, @REMECredit DECIMAL(18,2) = 0;
            DECLARE @Diff DECIMAL(18,2) = @TotalDebit - @TotalCredit;

            IF @Diff > 0 SET @REMECredit = @Diff;
            IF @Diff < 0 SET @REMEDebit = ABS(@Diff);

            DECLARE @REMEAccCode NVARCHAR(30);
            SELECT @REMEAccCode = AccountCode FROM acct.Account WHERE AccountId = @REMEAccountId;

            INSERT INTO acct.JournalEntryLine (JournalEntryId, LineNumber, AccountId, AccountCodeSnapshot, Description, DebitAmount, CreditAmount)
            VALUES (@JournalEntryId,
                    (SELECT ISNULL(MAX(LineNumber), 0) + 1 FROM acct.JournalEntryLine WHERE JournalEntryId = @JournalEntryId),
                    @REMEAccountId, @REMEAccCode,
                    N'Resultado Monetario del Ejercicio (REME) - NIC 29',
                    @REMEDebit, @REMECredit);

            SET @TotalDebit  = @TotalDebit + @REMEDebit;
            SET @TotalCredit = @TotalCredit + @REMECredit;
        END;

        -- Actualizar totales del asiento
        UPDATE acct.JournalEntry
        SET    TotalDebit  = @TotalDebit,
               TotalCredit = @TotalCredit
        WHERE  JournalEntryId = @JournalEntryId;

        -- Marcar ajuste como publicado
        UPDATE acct.InflationAdjustment
        SET    Status         = 'POSTED',
               JournalEntryId = @JournalEntryId,
               UpdatedAt      = SYSUTCDATETIME()
        WHERE  InflationAdjustmentId = @AdjustmentId;

        COMMIT;

        SET @Resultado = 1;
        SET @Mensaje   = CONCAT(N'Ajuste publicado. Asiento: ', @EntryNumber,
                                N', Debe: ', FORMAT(@TotalDebit, 'N2'),
                                N', Haber: ', FORMAT(@TotalCredit, 'N2'));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 9: usp_Acct_Inflation_Void
--  Descripcion : Anula un ajuste por inflacion y su asiento asociado.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Inflation_Void', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Inflation_Void;
GO
CREATE PROCEDURE dbo.usp_Acct_Inflation_Void
    @CompanyId    INT,
    @AdjustmentId INT,
    @Motivo       NVARCHAR(200) = NULL,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Resultado = 0;
    SET @Mensaje   = N'';

    DECLARE @Status NVARCHAR(20), @JournalEntryId BIGINT;

    SELECT @Status = Status, @JournalEntryId = JournalEntryId
    FROM   acct.InflationAdjustment
    WHERE  InflationAdjustmentId = @AdjustmentId AND CompanyId = @CompanyId;

    IF @Status IS NULL
    BEGIN
        SET @Mensaje = N'Ajuste no encontrado.';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRAN;

        -- Anular asiento si existe
        IF @JournalEntryId IS NOT NULL
        BEGIN
            UPDATE acct.JournalEntry
            SET    Status = 'VOIDED', UpdatedAt = SYSUTCDATETIME()
            WHERE  JournalEntryId = @JournalEntryId;
        END;

        -- Anular ajuste
        UPDATE acct.InflationAdjustment
        SET    Status = 'VOIDED',
               Notes  = CONCAT(ISNULL(Notes + ' | ', ''), 'ANULADO: ', ISNULL(@Motivo, 'Sin motivo')),
               UpdatedAt = SYSUTCDATETIME()
        WHERE  InflationAdjustmentId = @AdjustmentId;

        COMMIT;

        SET @Resultado = 1;
        SET @Mensaje   = N'Ajuste anulado correctamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  SP 10: usp_Acct_Report_BalanceReexpresado
--  Descripcion : Balance General con columnas historico + reexpresado.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Report_BalanceReexpresado', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Report_BalanceReexpresado;
GO
CREATE PROCEDURE dbo.usp_Acct_Report_BalanceReexpresado
    @CompanyId  INT,
    @BranchId   INT,
    @FechaCorte DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener ajuste mas reciente para el periodo
    DECLARE @PeriodCode CHAR(6) = FORMAT(@FechaCorte, 'yyyyMM');
    DECLARE @Factor DECIMAL(18,8) = 1.0;

    SELECT TOP 1 @Factor = ReexpressionFactor
    FROM   acct.InflationAdjustment
    WHERE  CompanyId = @CompanyId AND BranchId = @BranchId
      AND  PeriodCode <= @PeriodCode AND Status = 'POSTED'
    ORDER BY PeriodCode DESC;

    SELECT a.AccountCode,
           a.AccountName,
           a.AccountType,
           a.AccountLevel,
           -- Saldo historico
           ISNULL(SUM(
               CASE WHEN a.AccountType IN ('A','G')
                    THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                    ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
               END
           ), 0) AS historicalBalance,
           -- Clasificacion
           ISNULL(mc.Classification, 'MONETARY') AS classification,
           -- Saldo reexpresado
           CASE WHEN ISNULL(mc.Classification, 'MONETARY') = 'NON_MONETARY'
                THEN ROUND(ISNULL(SUM(
                     CASE WHEN a.AccountType IN ('A','G')
                          THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                          ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                     END
                ), 0) * @Factor, 2)
                ELSE ISNULL(SUM(
                     CASE WHEN a.AccountType IN ('A','G')
                          THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                          ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                     END
                ), 0)
           END AS adjustedBalance,
           -- Monto del ajuste
           CASE WHEN ISNULL(mc.Classification, 'MONETARY') = 'NON_MONETARY'
                THEN ROUND(ISNULL(SUM(
                     CASE WHEN a.AccountType IN ('A','G')
                          THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
                          ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
                     END
                ), 0) * (@Factor - 1.0), 2)
                ELSE 0
           END AS adjustmentAmount
    FROM   acct.Account a
    LEFT JOIN acct.JournalEntryLine jl ON jl.AccountId = a.AccountId
    LEFT JOIN acct.JournalEntry je ON je.JournalEntryId = jl.JournalEntryId
                                  AND je.CompanyId = @CompanyId
                                  AND je.Status = 'APPROVED'
                                  AND je.EntryDate <= @FechaCorte
    LEFT JOIN acct.AccountMonetaryClass mc ON mc.AccountId = a.AccountId AND mc.CompanyId = a.CompanyId
    WHERE  a.CompanyId = @CompanyId
      AND  a.IsActive  = 1
      AND  ISNULL(a.IsDeleted, 0) = 0
      AND  a.AccountType IN ('A','P','C')
    GROUP BY a.AccountCode, a.AccountName, a.AccountType, a.AccountLevel, mc.Classification
    HAVING ISNULL(SUM(
        CASE WHEN a.AccountType IN ('A','G')
             THEN ISNULL(jl.DebitAmount, 0) - ISNULL(jl.CreditAmount, 0)
             ELSE ISNULL(jl.CreditAmount, 0) - ISNULL(jl.DebitAmount, 0)
        END
    ), 0) <> 0
    ORDER BY a.AccountCode;
END;
GO

-- =============================================================================
--  SP 11: usp_Acct_Report_REME
--  Descripcion : Reporte del Resultado Monetario del Periodo.
--  Ref: BA VEN-NIF 2, NIC 29 parrafos 27-28
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_Report_REME', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_Report_REME;
GO
CREATE PROCEDURE dbo.usp_Acct_Report_REME
    @CompanyId  INT,
    @BranchId   INT,
    @FechaDesde DATE,
    @FechaHasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Retornar ajustes del rango con su detalle
    SELECT ia.InflationAdjustmentId,
           ia.PeriodCode,
           ia.AdjustmentDate,
           ia.BaseIndexValue   AS inpcInicio,
           ia.EndIndexValue    AS inpcFin,
           ia.ReexpressionFactor AS factorReexpresion,
           ia.AccumulatedInflation AS inflacionAcumulada,
           ia.TotalMonetaryGainLoss AS reme,
           ia.TotalAdjustmentAmount AS totalAjustes,
           ia.Status,
           ia.JournalEntryId
    FROM   acct.InflationAdjustment ia
    WHERE  ia.CompanyId = @CompanyId
      AND  ia.BranchId  = @BranchId
      AND  ia.AdjustmentDate BETWEEN @FechaDesde AND @FechaHasta
      AND  ia.Status <> 'VOIDED'
    ORDER BY ia.PeriodCode;

    -- Detalle por cuenta del ultimo ajuste del rango
    DECLARE @LastAdjId INT;
    SELECT TOP 1 @LastAdjId = InflationAdjustmentId
    FROM   acct.InflationAdjustment
    WHERE  CompanyId = @CompanyId AND BranchId = @BranchId
      AND  AdjustmentDate BETWEEN @FechaDesde AND @FechaHasta
      AND  Status <> 'VOIDED'
    ORDER BY PeriodCode DESC;

    IF @LastAdjId IS NOT NULL
    BEGIN
        SELECT l.AccountCode,
               l.AccountName,
               l.Classification,
               l.HistoricalBalance,
               l.ReexpressionFactor,
               l.AdjustedBalance,
               l.AdjustmentAmount
        FROM   acct.InflationAdjustmentLine l
        WHERE  l.InflationAdjustmentId = @LastAdjId
        ORDER BY l.AccountCode;
    END;
END;
GO

PRINT '=== usp_acct_inflation.sql completado: 11 SPs creados ===';
GO
