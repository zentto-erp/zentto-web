-- =============================================================================
-- usp_acct_fixedassets.sql
-- Procedimientos de Activos Fijos (Fixed Assets)
-- Operaciones sobre acct.FixedAsset, acct.FixedAssetCategory,
-- acct.FixedAssetDepreciation, acct.FixedAssetImprovement,
-- acct.FixedAssetRevaluation.
--
-- Procedimientos incluidos:
--   1.  usp_Acct_FixedAssetCategory_List            - Listado paginado de categorias
--   2.  usp_Acct_FixedAssetCategory_Get             - Detalle de una categoria
--   3.  usp_Acct_FixedAssetCategory_Upsert          - Crear o actualizar categoria
--   4.  usp_Acct_FixedAsset_List                    - Listado paginado de activos fijos
--   5.  usp_Acct_FixedAsset_Get                     - Detalle de un activo fijo
--   6.  usp_Acct_FixedAsset_Insert                  - Registrar activo fijo
--   7.  usp_Acct_FixedAsset_Update                  - Actualizar activo fijo
--   8.  usp_Acct_FixedAsset_Dispose                 - Desincorporar activo fijo
--   9.  usp_Acct_FixedAsset_CalculateDepreciation   - Calcular depreciacion mensual
--   10. usp_Acct_FixedAsset_DepreciationHistory     - Historial de depreciacion
--   11. usp_Acct_FixedAsset_AddImprovement          - Registrar mejora a activo
--   12. usp_Acct_FixedAsset_Revalue                 - Revaluacion de activo
--   13. usp_Acct_FixedAsset_Report_Book             - Libro de activos fijos
--   14. usp_Acct_FixedAsset_Report_DepreciationSchedule - Proyeccion de depreciacion
--   15. usp_Acct_FixedAsset_Report_ByCategory       - Resumen por categoria
--
-- Dependencias:
--   - acct.FixedAssetCategory
--   - acct.FixedAsset
--   - acct.FixedAssetDepreciation
--   - acct.FixedAssetImprovement
--   - acct.FixedAssetRevaluation
--   - acct.Account
--
-- Fecha creacion: 2026-03-16
-- =============================================================================
USE DatqBoxWeb;
GO

-- =============================================================================
-- 1. usp_Acct_FixedAssetCategory_List
--    Listado paginado de categorias de activos fijos.
--    Permite filtrar por codigo o nombre.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAssetCategory_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAssetCategory_List;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAssetCategory_List
    @CompanyId                INT,
    @Search                   NVARCHAR(100)  = NULL,
    @Page                     INT            = 1,
    @Limit                    INT            = 50,
    @TotalCount               INT            OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM acct.FixedAssetCategory
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND (@Search IS NULL
           OR CategoryCode LIKE '%' + @Search + '%'
           OR CategoryName LIKE '%' + @Search + '%');

    -- Retornar pagina solicitada
    SELECT
        CategoryId,
        CategoryCode,
        CategoryName,
        DefaultUsefulLifeMonths,
        DefaultDepreciationMethod,
        DefaultResidualPercent,
        DefaultAssetAccountCode,
        DefaultDeprecAccountCode,
        DefaultExpenseAccountCode,
        CountryCode
    FROM acct.FixedAssetCategory
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND (@Search IS NULL
           OR CategoryCode LIKE '%' + @Search + '%'
           OR CategoryName LIKE '%' + @Search + '%')
    ORDER BY CategoryCode
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 2. usp_Acct_FixedAssetCategory_Get
--    Detalle de una categoria de activo fijo.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAssetCategory_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAssetCategory_Get;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAssetCategory_Get
    @CompanyId      INT,
    @CategoryCode   NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 *
    FROM acct.FixedAssetCategory
    WHERE CompanyId    = @CompanyId
      AND CategoryCode = @CategoryCode
      AND IsDeleted    = 0;
END;
GO

-- =============================================================================
-- 3. usp_Acct_FixedAssetCategory_Upsert
--    Crear o actualizar una categoria de activo fijo.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAssetCategory_Upsert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAssetCategory_Upsert;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAssetCategory_Upsert
    @CompanyId                    INT,
    @CategoryCode                 NVARCHAR(20),
    @CategoryName                 NVARCHAR(200),
    @DefaultUsefulLifeMonths      INT,
    @DefaultDepreciationMethod    NVARCHAR(20)    = 'STRAIGHT_LINE',
    @DefaultResidualPercent       DECIMAL(5,2)    = 0,
    @DefaultAssetAccountCode      NVARCHAR(20)    = NULL,
    @DefaultDeprecAccountCode     NVARCHAR(20)    = NULL,
    @DefaultExpenseAccountCode    NVARCHAR(20)    = NULL,
    @CountryCode                  NVARCHAR(2)     = NULL,
    @Resultado                    INT             OUTPUT,
    @Mensaje                      NVARCHAR(500)   OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = '';

    IF EXISTS (
        SELECT 1 FROM acct.FixedAssetCategory
        WHERE CompanyId    = @CompanyId
          AND CategoryCode = @CategoryCode
          AND IsDeleted    = 0
    )
    BEGIN
        -- Actualizar categoria existente
        UPDATE acct.FixedAssetCategory
        SET CategoryName              = @CategoryName,
            DefaultUsefulLifeMonths   = @DefaultUsefulLifeMonths,
            DefaultDepreciationMethod = @DefaultDepreciationMethod,
            DefaultResidualPercent    = @DefaultResidualPercent,
            DefaultAssetAccountCode   = @DefaultAssetAccountCode,
            DefaultDeprecAccountCode  = @DefaultDeprecAccountCode,
            DefaultExpenseAccountCode = @DefaultExpenseAccountCode,
            CountryCode               = @CountryCode
        WHERE CompanyId    = @CompanyId
          AND CategoryCode = @CategoryCode
          AND IsDeleted    = 0;
    END
    ELSE
    BEGIN
        -- Insertar nueva categoria
        INSERT INTO acct.FixedAssetCategory (
            CompanyId, CategoryCode, CategoryName,
            DefaultUsefulLifeMonths, DefaultDepreciationMethod, DefaultResidualPercent,
            DefaultAssetAccountCode, DefaultDeprecAccountCode, DefaultExpenseAccountCode,
            CountryCode, IsDeleted, CreatedAt
        )
        VALUES (
            @CompanyId, @CategoryCode, @CategoryName,
            @DefaultUsefulLifeMonths, @DefaultDepreciationMethod, @DefaultResidualPercent,
            @DefaultAssetAccountCode, @DefaultDeprecAccountCode, @DefaultExpenseAccountCode,
            @CountryCode, 0, SYSUTCDATETIME()
        );
    END;

    SET @Resultado = 1;
    SET @Mensaje   = 'Categoria guardada';
END;
GO

-- =============================================================================
-- 4. usp_Acct_FixedAsset_List
--    Listado paginado de activos fijos con valor en libros calculado.
--    Permite filtrar por categoria, estado, centro de costo y busqueda.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_List', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_List;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_List
    @CompanyId        INT,
    @BranchId         INT              = NULL,
    @CategoryCode     NVARCHAR(20)     = NULL,
    @Status           NVARCHAR(20)     = NULL,
    @CostCenterCode   NVARCHAR(20)     = NULL,
    @Search           NVARCHAR(100)    = NULL,
    @Page             INT              = 1,
    @Limit            INT              = 50,
    @TotalCount       INT              OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM acct.FixedAsset a
    INNER JOIN acct.FixedAssetCategory c ON a.CategoryId = c.CategoryId
    WHERE a.CompanyId = @CompanyId
      AND a.IsDeleted = 0
      AND (@BranchId       IS NULL OR a.BranchId       = @BranchId)
      AND (@CategoryCode   IS NULL OR c.CategoryCode   = @CategoryCode)
      AND (@Status         IS NULL OR a.Status          = @Status)
      AND (@CostCenterCode IS NULL OR a.CostCenterCode = @CostCenterCode)
      AND (@Search IS NULL
           OR a.AssetCode   LIKE '%' + @Search + '%'
           OR a.Description LIKE '%' + @Search + '%');

    -- Retornar pagina solicitada
    SELECT
        a.AssetId,
        a.AssetCode,
        a.Description,
        a.BranchId,
        c.CategoryId,
        c.CategoryCode,
        c.CategoryName,
        a.AcquisitionDate,
        a.AcquisitionCost,
        a.ResidualValue,
        a.UsefulLifeMonths,
        a.DepreciationMethod,
        a.Status,
        a.CostCenterCode,
        a.Location,
        a.SerialNumber,
        a.CurrencyCode,
        AccumulatedDepreciation = ISNULL((
            SELECT SUM(Amount)
            FROM acct.FixedAssetDepreciation
            WHERE AssetId = a.AssetId
        ), 0),
        BookValue = a.AcquisitionCost
            - ISNULL((SELECT SUM(Amount) FROM acct.FixedAssetDepreciation WHERE AssetId = a.AssetId), 0)
            + ISNULL((SELECT SUM(Amount) FROM acct.FixedAssetImprovement WHERE AssetId = a.AssetId), 0)
    FROM acct.FixedAsset a
    INNER JOIN acct.FixedAssetCategory c ON a.CategoryId = c.CategoryId
    WHERE a.CompanyId = @CompanyId
      AND a.IsDeleted = 0
      AND (@BranchId       IS NULL OR a.BranchId       = @BranchId)
      AND (@CategoryCode   IS NULL OR c.CategoryCode   = @CategoryCode)
      AND (@Status         IS NULL OR a.Status          = @Status)
      AND (@CostCenterCode IS NULL OR a.CostCenterCode = @CostCenterCode)
      AND (@Search IS NULL
           OR a.AssetCode   LIKE '%' + @Search + '%'
           OR a.Description LIKE '%' + @Search + '%')
    ORDER BY a.AssetCode
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 5. usp_Acct_FixedAsset_Get
--    Detalle completo de un activo fijo con valor en libros calculado.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Get', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Get;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Get
    @CompanyId   INT,
    @AssetId     BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.*,
        c.CategoryCode,
        c.CategoryName,
        AccumulatedDepreciation = ISNULL((
            SELECT SUM(Amount)
            FROM acct.FixedAssetDepreciation
            WHERE AssetId = a.AssetId
        ), 0),
        BookValue = a.AcquisitionCost
            - ISNULL((SELECT SUM(Amount) FROM acct.FixedAssetDepreciation WHERE AssetId = a.AssetId), 0)
            + ISNULL((SELECT SUM(Amount) FROM acct.FixedAssetImprovement WHERE AssetId = a.AssetId), 0)
    FROM acct.FixedAsset a
    INNER JOIN acct.FixedAssetCategory c ON a.CategoryId = c.CategoryId
    WHERE a.CompanyId = @CompanyId
      AND a.AssetId   = @AssetId
      AND a.IsDeleted  = 0;
END;
GO

-- =============================================================================
-- 6. usp_Acct_FixedAsset_Insert
--    Registrar un nuevo activo fijo.
--    Valida unicidad de AssetCode dentro de la empresa.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Insert', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Insert;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Insert
    @CompanyId            INT,
    @BranchId             INT,
    @AssetCode            NVARCHAR(40),
    @Description          NVARCHAR(250),
    @CategoryId           INT,
    @AcquisitionDate      DATE,
    @AcquisitionCost      DECIMAL(18,2),
    @ResidualValue        DECIMAL(18,2)    = 0,
    @UsefulLifeMonths     INT,
    @DepreciationMethod   NVARCHAR(20)     = 'STRAIGHT_LINE',
    @AssetAccountCode     NVARCHAR(20),
    @DeprecAccountCode    NVARCHAR(20),
    @ExpenseAccountCode   NVARCHAR(20),
    @CostCenterCode       NVARCHAR(20)     = NULL,
    @Location             NVARCHAR(200)    = NULL,
    @SerialNumber         NVARCHAR(100)    = NULL,
    @UnitsCapacity        INT              = NULL,
    @CurrencyCode         NVARCHAR(3)      = 'VES',
    @CodUsuario           NVARCHAR(40),
    @AssetId              BIGINT           OUTPUT,
    @Resultado            INT              OUTPUT,
    @Mensaje              NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @AssetId   = 0;
    SET @Resultado = 0;
    SET @Mensaje   = '';

    -- Validar unicidad de AssetCode
    IF EXISTS (
        SELECT 1 FROM acct.FixedAsset
        WHERE CompanyId = @CompanyId
          AND AssetCode = @AssetCode
          AND IsDeleted = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = 'El codigo de activo ya existe en esta empresa';
        RETURN;
    END;

    -- Insertar activo fijo
    INSERT INTO acct.FixedAsset (
        CompanyId, BranchId, AssetCode, Description, CategoryId,
        AcquisitionDate, AcquisitionCost, ResidualValue, UsefulLifeMonths,
        DepreciationMethod, AssetAccountCode, DeprecAccountCode, ExpenseAccountCode,
        CostCenterCode, Location, SerialNumber, UnitsCapacity,
        CurrencyCode, Status, IsDeleted, CreatedAt, CreatedBy
    )
    VALUES (
        @CompanyId, @BranchId, @AssetCode, @Description, @CategoryId,
        @AcquisitionDate, @AcquisitionCost, @ResidualValue, @UsefulLifeMonths,
        @DepreciationMethod, @AssetAccountCode, @DeprecAccountCode, @ExpenseAccountCode,
        @CostCenterCode, @Location, @SerialNumber, @UnitsCapacity,
        @CurrencyCode, 'ACTIVE', 0, SYSUTCDATETIME(), @CodUsuario
    );

    SET @AssetId   = SCOPE_IDENTITY();
    SET @Resultado = 1;
    SET @Mensaje   = 'Activo fijo registrado';
END;
GO

-- =============================================================================
-- 7. usp_Acct_FixedAsset_Update
--    Actualizar campos editables de un activo fijo.
--    Solo actualiza campos no nulos (patron ISNULL).
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Update', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Update;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Update
    @CompanyId        INT,
    @AssetId          BIGINT,
    @Description      NVARCHAR(250)    = NULL,
    @Location         NVARCHAR(200)    = NULL,
    @SerialNumber     NVARCHAR(100)    = NULL,
    @CostCenterCode   NVARCHAR(20)     = NULL,
    @CurrencyCode     NVARCHAR(3)      = NULL,
    @CodUsuario       NVARCHAR(40),
    @Resultado        INT              OUTPUT,
    @Mensaje          NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = '';

    -- Validar que el activo existe
    IF NOT EXISTS (
        SELECT 1 FROM acct.FixedAsset
        WHERE CompanyId = @CompanyId
          AND AssetId   = @AssetId
          AND IsDeleted = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = 'Activo fijo no encontrado';
        RETURN;
    END;

    -- Actualizar solo campos proporcionados
    UPDATE acct.FixedAsset
    SET Description    = ISNULL(@Description,    Description),
        Location       = ISNULL(@Location,       Location),
        SerialNumber   = ISNULL(@SerialNumber,   SerialNumber),
        CostCenterCode = ISNULL(@CostCenterCode, CostCenterCode),
        CurrencyCode   = ISNULL(@CurrencyCode,   CurrencyCode),
        UpdatedAt      = SYSUTCDATETIME(),
        UpdatedBy      = @CodUsuario
    WHERE CompanyId = @CompanyId
      AND AssetId   = @AssetId
      AND IsDeleted = 0;

    SET @Resultado = 1;
    SET @Mensaje   = 'Activo fijo actualizado';
END;
GO

-- =============================================================================
-- 8. usp_Acct_FixedAsset_Dispose
--    Desincorporar un activo fijo (cambiar estado a DISPOSED).
--    Valida que el activo este en estado ACTIVE.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Dispose', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Dispose;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Dispose
    @CompanyId        INT,
    @AssetId          BIGINT,
    @DisposalDate     DATE,
    @DisposalAmount   DECIMAL(18,2)    = 0,
    @DisposalReason   NVARCHAR(500)    = NULL,
    @CodUsuario       NVARCHAR(40),
    @Resultado        INT              OUTPUT,
    @Mensaje          NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = '';

    -- Validar que el activo existe y esta activo
    IF NOT EXISTS (
        SELECT 1 FROM acct.FixedAsset
        WHERE CompanyId = @CompanyId
          AND AssetId   = @AssetId
          AND Status    = 'ACTIVE'
          AND IsDeleted = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = 'Activo fijo no encontrado o no esta activo';
        RETURN;
    END;

    -- Desincorporar activo
    UPDATE acct.FixedAsset
    SET Status          = 'DISPOSED',
        DisposalDate    = @DisposalDate,
        DisposalAmount  = @DisposalAmount,
        DisposalReason  = @DisposalReason,
        UpdatedAt       = SYSUTCDATETIME(),
        UpdatedBy       = @CodUsuario
    WHERE CompanyId = @CompanyId
      AND AssetId   = @AssetId
      AND IsDeleted = 0;

    SET @Resultado = 1;
    SET @Mensaje   = 'Activo desincorporado';
END;
GO

-- =============================================================================
-- 9. usp_Acct_FixedAsset_CalculateDepreciation
--    Calcular depreciacion mensual para activos fijos de una empresa/sucursal.
--    Soporta metodos STRAIGHT_LINE y DOUBLE_DECLINING.
--    @Preview = 1 solo devuelve preview sin insertar registros.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_CalculateDepreciation', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_CalculateDepreciation;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_CalculateDepreciation
    @CompanyId          INT,
    @BranchId           INT,
    @PeriodCode         NVARCHAR(7),
    @CostCenterCode     NVARCHAR(20)     = NULL,
    @Preview            BIT              = 0,
    @CodUsuario         NVARCHAR(40),
    @Resultado          INT              OUTPUT,
    @Mensaje            NVARCHAR(500)    OUTPUT,
    @EntriesGenerated   INT              OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado        = 0;
    SET @Mensaje          = '';
    SET @EntriesGenerated = 0;

    -- Calcular inicio y fin del periodo desde @PeriodCode (YYYY-MM)
    DECLARE @PeriodStart DATE;
    DECLARE @PeriodEnd   DATE;

    SET @PeriodStart = CAST(@PeriodCode + '-01' AS DATE);
    SET @PeriodEnd   = EOMONTH(@PeriodStart);

    -- Tabla temporal para calculo de depreciacion
    CREATE TABLE #DepreciationCalc (
        AssetId             BIGINT,
        AssetCode           NVARCHAR(40),
        Description         NVARCHAR(250),
        AcquisitionCost     DECIMAL(18,2),
        ResidualValue       DECIMAL(18,2),
        UsefulLifeMonths    INT,
        DepreciationMethod  NVARCHAR(20),
        ExpenseAccountCode  NVARCHAR(20),
        DeprecAccountCode   NVARCHAR(20),
        PreviousAccum       DECIMAL(18,2),
        MonthsDepreciated   INT,
        CalcAmount          DECIMAL(18,2),
        NewAccum            DECIMAL(18,2),
        NewBookValue        DECIMAL(18,2)
    );

    -- Insertar activos elegibles para depreciacion
    INSERT INTO #DepreciationCalc (
        AssetId, AssetCode, Description, AcquisitionCost, ResidualValue,
        UsefulLifeMonths, DepreciationMethod, ExpenseAccountCode, DeprecAccountCode,
        PreviousAccum, MonthsDepreciated, CalcAmount, NewAccum, NewBookValue
    )
    SELECT
        a.AssetId,
        a.AssetCode,
        a.Description,
        a.AcquisitionCost,
        a.ResidualValue,
        a.UsefulLifeMonths,
        a.DepreciationMethod,
        a.ExpenseAccountCode,
        a.DeprecAccountCode,
        ISNULL((SELECT SUM(Amount) FROM acct.FixedAssetDepreciation WHERE AssetId = a.AssetId), 0),
        ISNULL((SELECT COUNT(*) FROM acct.FixedAssetDepreciation WHERE AssetId = a.AssetId), 0),
        0, -- CalcAmount se calcula despues
        0, -- NewAccum se calcula despues
        0  -- NewBookValue se calcula despues
    FROM acct.FixedAsset a
    WHERE a.CompanyId = @CompanyId
      AND a.BranchId  = @BranchId
      AND a.Status    = 'ACTIVE'
      AND a.IsDeleted = 0
      AND a.DepreciationMethod <> 'NONE'
      AND a.AcquisitionDate <= @PeriodEnd
      AND NOT EXISTS (
          SELECT 1 FROM acct.FixedAssetDepreciation d
          WHERE d.AssetId    = a.AssetId
            AND d.PeriodCode = @PeriodCode
      )
      AND (@CostCenterCode IS NULL OR a.CostCenterCode = @CostCenterCode);

    -- Calcular monto de depreciacion por metodo
    -- STRAIGHT_LINE: (Costo - Residual) / VidaUtil
    UPDATE #DepreciationCalc
    SET CalcAmount = ROUND((AcquisitionCost - ResidualValue) / UsefulLifeMonths, 2)
    WHERE DepreciationMethod = 'STRAIGHT_LINE'
      AND UsefulLifeMonths > 0;

    -- DOUBLE_DECLINING: (2 / VidaUtil) * (Costo - DeprecAcumulada)
    UPDATE #DepreciationCalc
    SET CalcAmount = ROUND((2.0 / UsefulLifeMonths) * (AcquisitionCost - PreviousAccum), 2)
    WHERE DepreciationMethod = 'DOUBLE_DECLINING'
      AND UsefulLifeMonths > 0;

    -- Aplicar tope: no depreciar por debajo del valor residual
    UPDATE #DepreciationCalc
    SET CalcAmount = AcquisitionCost - ResidualValue - PreviousAccum
    WHERE PreviousAccum + CalcAmount > AcquisitionCost - ResidualValue;

    -- Eliminar filas donde no hay monto a depreciar
    DELETE FROM #DepreciationCalc
    WHERE CalcAmount <= 0;

    -- Calcular nuevos acumulados y valor en libros
    UPDATE #DepreciationCalc
    SET NewAccum    = PreviousAccum + CalcAmount,
        NewBookValue = AcquisitionCost - (PreviousAccum + CalcAmount);

    -- Si es preview, solo retornar sin insertar
    IF @Preview = 1
    BEGIN
        SELECT
            AssetId, AssetCode, Description, AcquisitionCost, ResidualValue,
            UsefulLifeMonths, DepreciationMethod, PreviousAccum, MonthsDepreciated,
            CalcAmount, NewAccum, NewBookValue
        FROM #DepreciationCalc
        ORDER BY AssetCode;

        SELECT @EntriesGenerated = COUNT(*) FROM #DepreciationCalc;
        SET @Resultado = 1;
        SET @Mensaje   = 'Preview de depreciacion: ' + CAST(@EntriesGenerated AS NVARCHAR(10)) + ' asientos';

        DROP TABLE #DepreciationCalc;
        RETURN;
    END;

    -- Insertar registros de depreciacion
    INSERT INTO acct.FixedAssetDepreciation (
        AssetId, PeriodCode, DepreciationDate, Amount,
        AccumulatedDepreciation, BookValue, Status,
        CreatedAt
    )
    SELECT
        AssetId,
        @PeriodCode,
        @PeriodEnd,
        CalcAmount,
        NewAccum,
        NewBookValue,
        'POSTED',
        SYSUTCDATETIME()
    FROM #DepreciationCalc;

    SELECT @EntriesGenerated = @@ROWCOUNT;

    -- Retornar detalle de lo generado
    SELECT
        AssetId, AssetCode, Description, AcquisitionCost, ResidualValue,
        UsefulLifeMonths, DepreciationMethod, PreviousAccum, MonthsDepreciated,
        CalcAmount, NewAccum, NewBookValue
    FROM #DepreciationCalc
    ORDER BY AssetCode;

    SET @Resultado = 1;
    SET @Mensaje   = 'Depreciacion generada: ' + CAST(@EntriesGenerated AS NVARCHAR(10)) + ' asientos';

    DROP TABLE #DepreciationCalc;
END;
GO

-- =============================================================================
-- 10. usp_Acct_FixedAsset_DepreciationHistory
--     Historial de depreciacion de un activo fijo, paginado.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_DepreciationHistory', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_DepreciationHistory;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_DepreciationHistory
    @CompanyId    INT,
    @AssetId      BIGINT,
    @Page         INT    = 1,
    @Limit        INT    = 50,
    @TotalCount   INT    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parametros de paginacion
    IF @Page < 1 SET @Page = 1;
    IF @Limit < 1 SET @Limit = 50;
    IF @Limit > 500 SET @Limit = 500;

    -- Contar registros totales
    SELECT @TotalCount = COUNT(*)
    FROM acct.FixedAssetDepreciation d
    INNER JOIN acct.FixedAsset a ON d.AssetId = a.AssetId
    WHERE a.CompanyId = @CompanyId
      AND d.AssetId   = @AssetId;

    -- Retornar pagina solicitada
    SELECT
        d.DepreciationId,
        d.AssetId,
        d.PeriodCode,
        d.DepreciationDate,
        d.Amount,
        d.AccumulatedDepreciation,
        d.BookValue,
        d.JournalEntryId,
        d.Status,
        d.CreatedAt
    FROM acct.FixedAssetDepreciation d
    INNER JOIN acct.FixedAsset a ON d.AssetId = a.AssetId
    WHERE a.CompanyId = @CompanyId
      AND d.AssetId   = @AssetId
    ORDER BY d.PeriodCode DESC
    OFFSET (@Page - 1) * @Limit ROWS
    FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
-- 11. usp_Acct_FixedAsset_AddImprovement
--     Registrar una mejora/adicion a un activo fijo.
--     Aumenta el costo de adquisicion y opcionalmente la vida util.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_AddImprovement', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_AddImprovement;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_AddImprovement
    @CompanyId            INT,
    @AssetId              BIGINT,
    @ImprovementDate      DATE,
    @Description          NVARCHAR(500),
    @Amount               DECIMAL(18,2),
    @AdditionalLifeMonths INT              = 0,
    @CodUsuario           NVARCHAR(40),
    @Resultado            INT              OUTPUT,
    @Mensaje              NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = '';

    -- Validar que el activo existe y esta activo
    IF NOT EXISTS (
        SELECT 1 FROM acct.FixedAsset
        WHERE CompanyId = @CompanyId
          AND AssetId   = @AssetId
          AND Status    = 'ACTIVE'
          AND IsDeleted = 0
    )
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = 'Activo fijo no encontrado o no esta activo';
        RETURN;
    END;

    -- Registrar mejora
    INSERT INTO acct.FixedAssetImprovement (
        AssetId, ImprovementDate, Description, Amount,
        AdditionalLifeMonths, CreatedAt, CreatedBy
    )
    VALUES (
        @AssetId, @ImprovementDate, @Description, @Amount,
        @AdditionalLifeMonths, SYSUTCDATETIME(), @CodUsuario
    );

    -- Actualizar costo y vida util del activo
    UPDATE acct.FixedAsset
    SET AcquisitionCost  = AcquisitionCost + @Amount,
        UsefulLifeMonths = UsefulLifeMonths + @AdditionalLifeMonths,
        UpdatedAt        = SYSUTCDATETIME(),
        UpdatedBy        = @CodUsuario
    WHERE CompanyId = @CompanyId
      AND AssetId   = @AssetId
      AND IsDeleted = 0;

    SET @Resultado = 1;
    SET @Mensaje   = 'Mejora registrada';
END;
GO

-- =============================================================================
-- 12. usp_Acct_FixedAsset_Revalue
--     Revaluacion de un activo fijo por indice multiplicador.
--     Actualiza costo de adquisicion y registra en tabla de revaluaciones.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Revalue', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Revalue;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Revalue
    @CompanyId          INT,
    @AssetId            BIGINT,
    @RevaluationDate    DATE,
    @IndexFactor        DECIMAL(12,6),
    @CountryCode        NVARCHAR(2),
    @CodUsuario         NVARCHAR(40),
    @Resultado          INT              OUTPUT,
    @Mensaje            NVARCHAR(500)    OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @Resultado = 0;
    SET @Mensaje   = '';

    -- Obtener valores actuales
    DECLARE @OldCost         DECIMAL(18,2);
    DECLARE @OldAccumDeprec  DECIMAL(18,2);
    DECLARE @NewCost         DECIMAL(18,2);
    DECLARE @NewAccumDeprec  DECIMAL(18,2);

    SELECT @OldCost = AcquisitionCost
    FROM acct.FixedAsset
    WHERE CompanyId = @CompanyId
      AND AssetId   = @AssetId
      AND IsDeleted = 0;

    IF @OldCost IS NULL
    BEGIN
        SET @Resultado = 0;
        SET @Mensaje   = 'Activo fijo no encontrado';
        RETURN;
    END;

    -- Calcular depreciacion acumulada actual
    SELECT @OldAccumDeprec = ISNULL(SUM(Amount), 0)
    FROM acct.FixedAssetDepreciation
    WHERE AssetId = @AssetId;

    -- Calcular nuevos valores
    SET @NewCost        = ROUND(@OldCost * @IndexFactor, 2);
    SET @NewAccumDeprec = ROUND(@OldAccumDeprec * @IndexFactor, 2);

    -- Registrar revaluacion
    INSERT INTO acct.FixedAssetRevaluation (
        AssetId, RevaluationDate,
        PreviousCost, NewCost, PreviousAccumDeprec, NewAccumDeprec,
        IndexFactor, CountryCode, CreatedBy, CreatedAt
    )
    VALUES (
        @AssetId, @RevaluationDate,
        @OldCost, @NewCost, @OldAccumDeprec, @NewAccumDeprec,
        @IndexFactor, @CountryCode, @CodUsuario, SYSUTCDATETIME()
    );

    -- Actualizar costo del activo
    UPDATE acct.FixedAsset
    SET AcquisitionCost = @NewCost,
        UpdatedAt       = SYSUTCDATETIME(),
        UpdatedBy       = @CodUsuario
    WHERE CompanyId = @CompanyId
      AND AssetId   = @AssetId
      AND IsDeleted = 0;

    SET @Resultado = 1;
    SET @Mensaje   = 'Revaluacion aplicada';
END;
GO

-- =============================================================================
-- 13. usp_Acct_FixedAsset_Report_Book
--     Libro de activos fijos a una fecha de corte.
--     Incluye activos ACTIVE y FULLY_DEPRECIATED.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Report_Book', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Report_Book;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Report_Book
    @CompanyId      INT,
    @BranchId       INT,
    @FechaCorte     DATE,
    @CategoryCode   NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.AssetCode,
        a.Description,
        c.CategoryName,
        a.AcquisitionDate,
        a.AcquisitionCost,
        AccumulatedDepreciation = ISNULL((
            SELECT SUM(d.Amount)
            FROM acct.FixedAssetDepreciation d
            WHERE d.AssetId          = a.AssetId
              AND d.DepreciationDate <= @FechaCorte
        ), 0),
        BookValue = a.AcquisitionCost - ISNULL((
            SELECT SUM(d.Amount)
            FROM acct.FixedAssetDepreciation d
            WHERE d.AssetId          = a.AssetId
              AND d.DepreciationDate <= @FechaCorte
        ), 0),
        a.Status
    FROM acct.FixedAsset a
    INNER JOIN acct.FixedAssetCategory c ON a.CategoryId = c.CategoryId
    WHERE a.CompanyId = @CompanyId
      AND a.BranchId  = @BranchId
      AND a.IsDeleted = 0
      AND a.AcquisitionDate <= @FechaCorte
      AND a.Status IN ('ACTIVE', 'FULLY_DEPRECIATED')
      AND (@CategoryCode IS NULL OR c.CategoryCode = @CategoryCode)
    ORDER BY c.CategoryName, a.AssetCode;
END;
GO

-- =============================================================================
-- 14. usp_Acct_FixedAsset_Report_DepreciationSchedule
--     Proyeccion de depreciacion mensual para un activo fijo.
--     Genera tabla de meses desde fecha de adquisicion hasta fin de vida util.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Report_DepreciationSchedule', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Report_DepreciationSchedule;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Report_DepreciationSchedule
    @CompanyId   INT,
    @AssetId     BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener datos del activo
    DECLARE @AcquisitionDate    DATE;
    DECLARE @AcquisitionCost    DECIMAL(18,2);
    DECLARE @ResidualValue      DECIMAL(18,2);
    DECLARE @UsefulLifeMonths   INT;
    DECLARE @DepreciationMethod NVARCHAR(20);
    DECLARE @AssetCode          NVARCHAR(40);
    DECLARE @Description        NVARCHAR(250);

    SELECT
        @AcquisitionDate    = AcquisitionDate,
        @AcquisitionCost    = AcquisitionCost,
        @ResidualValue      = ResidualValue,
        @UsefulLifeMonths   = UsefulLifeMonths,
        @DepreciationMethod = DepreciationMethod,
        @AssetCode          = AssetCode,
        @Description        = Description
    FROM acct.FixedAsset
    WHERE CompanyId = @CompanyId
      AND AssetId   = @AssetId
      AND IsDeleted = 0;

    IF @AcquisitionDate IS NULL
        RETURN;

    -- Generar tabla de numeros con CTE recursivo
    ;WITH Numbers AS (
        SELECT 1 AS N
        UNION ALL
        SELECT N + 1 FROM Numbers WHERE N < @UsefulLifeMonths
    ),
    Schedule AS (
        SELECT
            N                                                        AS MonthNumber,
            DATEADD(MONTH, N, @AcquisitionDate)                      AS DepreciationDate,
            LEFT(CONVERT(NVARCHAR(10), DATEADD(MONTH, N, @AcquisitionDate), 120), 7) AS PeriodCode,
            CASE
                WHEN @DepreciationMethod = 'STRAIGHT_LINE' THEN
                    ROUND((@AcquisitionCost - @ResidualValue) / @UsefulLifeMonths, 2)
                WHEN @DepreciationMethod = 'DOUBLE_DECLINING' THEN
                    CASE
                        WHEN @AcquisitionCost - (2.0 / @UsefulLifeMonths) *
                            (SELECT ISNULL(SUM(
                                CASE
                                    WHEN n2.N < N THEN
                                        -- Simplified: for schedule we use straight line approximation
                                        ROUND((@AcquisitionCost - @ResidualValue) / @UsefulLifeMonths, 2)
                                    ELSE 0
                                END
                            ), 0) FROM Numbers n2 WHERE n2.N < N) >= @ResidualValue
                        THEN ROUND((2.0 / @UsefulLifeMonths) * (
                            @AcquisitionCost - (
                                SELECT ISNULL(SUM(
                                    ROUND((@AcquisitionCost - @ResidualValue) / @UsefulLifeMonths, 2)
                                ), 0) FROM Numbers n2 WHERE n2.N < N
                            )
                        ), 2)
                        ELSE 0
                    END
                ELSE 0
            END AS MonthlyAmount
        FROM Numbers
    )
    SELECT
        @AssetCode                                                       AS AssetCode,
        @Description                                                     AS Description,
        s.MonthNumber,
        s.PeriodCode,
        s.DepreciationDate,
        CASE
            WHEN s.MonthlyAmount > @AcquisitionCost - @ResidualValue -
                ISNULL((SELECT SUM(s2.MonthlyAmount) FROM Schedule s2 WHERE s2.MonthNumber < s.MonthNumber), 0)
            THEN @AcquisitionCost - @ResidualValue -
                ISNULL((SELECT SUM(s2.MonthlyAmount) FROM Schedule s2 WHERE s2.MonthNumber < s.MonthNumber), 0)
            WHEN @AcquisitionCost - @ResidualValue -
                ISNULL((SELECT SUM(s2.MonthlyAmount) FROM Schedule s2 WHERE s2.MonthNumber < s.MonthNumber), 0) <= 0
            THEN 0
            ELSE s.MonthlyAmount
        END                                                              AS MonthlyAmount,
        ISNULL((SELECT SUM(s2.MonthlyAmount) FROM Schedule s2 WHERE s2.MonthNumber <= s.MonthNumber), 0) AS AccumulatedDepreciation,
        @AcquisitionCost - ISNULL((SELECT SUM(s2.MonthlyAmount) FROM Schedule s2 WHERE s2.MonthNumber <= s.MonthNumber), 0) AS BookValue
    FROM Schedule s
    ORDER BY s.MonthNumber
    OPTION (MAXRECURSION 1000);
END;
GO

-- =============================================================================
-- 15. usp_Acct_FixedAsset_Report_ByCategory
--     Resumen de activos fijos agrupados por categoria a una fecha de corte.
-- =============================================================================
IF OBJECT_ID('dbo.usp_Acct_FixedAsset_Report_ByCategory', 'P') IS NOT NULL DROP PROCEDURE dbo.usp_Acct_FixedAsset_Report_ByCategory;
GO
CREATE PROCEDURE dbo.usp_Acct_FixedAsset_Report_ByCategory
    @CompanyId    INT,
    @BranchId     INT,
    @FechaCorte   DATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Precalcular depreciacion acumulada por activo a la fecha de corte
    ;WITH AssetDeprec AS (
        SELECT
            a.AssetId,
            a.CategoryId,
            a.AcquisitionCost,
            ISNULL((
                SELECT SUM(d.Amount)
                FROM acct.FixedAssetDepreciation d
                WHERE d.AssetId          = a.AssetId
                  AND d.DepreciationDate <= @FechaCorte
            ), 0) AS AccumDepreciation
        FROM acct.FixedAsset a
        WHERE a.CompanyId = @CompanyId
          AND a.BranchId  = @BranchId
          AND a.IsDeleted = 0
          AND a.AcquisitionDate <= @FechaCorte
    )
    SELECT
        c.CategoryCode,
        c.CategoryName,
        COUNT(ad.AssetId)               AS AssetCount,
        SUM(ad.AcquisitionCost)         AS TotalAcquisitionCost,
        SUM(ad.AccumDepreciation)       AS TotalAccumulatedDepreciation,
        SUM(ad.AcquisitionCost - ad.AccumDepreciation) AS TotalBookValue
    FROM AssetDeprec ad
    INNER JOIN acct.FixedAssetCategory c ON ad.CategoryId = c.CategoryId
    GROUP BY c.CategoryCode, c.CategoryName
    ORDER BY c.CategoryCode;
END;
GO
