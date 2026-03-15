-- =============================================
-- Stored Procedures: Vacation Request Workflow
-- Depends on: hr.VacationRequest, hr.VacationRequestDay, master.Employee, hr.VacationProcess
-- Compatible con: SQL Server 2012+
-- =============================================

-- =============================================================
-- 1) usp_HR_VacationRequest_Create
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_Create')
    DROP PROCEDURE usp_HR_VacationRequest_Create
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE usp_HR_VacationRequest_Create
    @CompanyId      INT,
    @BranchId       INT,
    @EmployeeCode   NVARCHAR(60),
    @StartDate      DATE,
    @EndDate        DATE,
    @TotalDays      INT,
    @IsPartial      BIT,
    @Notes          NVARCHAR(500),
    @Days           NVARCHAR(MAX)   -- CSV: date1|type1;date2|type2;...  OR XML
AS
BEGIN
    SET NOCOUNT ON;

    IF @EndDate < @StartDate
    BEGIN RAISERROR('La fecha fin no puede ser anterior a la fecha inicio.', 16, 1); RETURN; END

    IF @TotalDays <= 0
    BEGIN RAISERROR('El total de dias debe ser mayor a cero.', 16, 1); RETURN; END

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO hr.VacationRequest (
            CompanyId, BranchId, EmployeeCode,
            StartDate, EndDate, TotalDays,
            IsPartial, Notes
        )
        VALUES (
            @CompanyId, @BranchId, @EmployeeCode,
            @StartDate, @EndDate, @TotalDays,
            @IsPartial, @Notes
        );

        DECLARE @RequestId BIGINT = SCOPE_IDENTITY();

        -- Parse days from XML format: <days><d dt="2026-03-16" tp="COMPLETO"/></days>
        IF @Days IS NOT NULL AND @Days <> '' AND LEFT(LTRIM(@Days), 1) = '<'
        BEGIN
            DECLARE @xml XML = CAST(@Days AS XML);
            INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType)
            SELECT @RequestId,
                   x.d.value('@dt', 'DATE'),
                   ISNULL(x.d.value('@tp', 'NVARCHAR(20)'), 'COMPLETO')
            FROM @xml.nodes('/days/d') AS x(d);
        END
        ELSE IF @Days IS NOT NULL AND @Days <> ''
        BEGIN
            -- Parse CSV format: 2026-03-16|COMPLETO;2026-03-17|COMPLETO
            DECLARE @DaysCursor TABLE (item NVARCHAR(200));
            DECLARE @pos INT = 1, @end INT, @item NVARCHAR(200);
            DECLARE @input NVARCHAR(MAX) = @Days + ';';

            WHILE @pos <= LEN(@input)
            BEGIN
                SET @end = CHARINDEX(';', @input, @pos);
                IF @end = 0 SET @end = LEN(@input) + 1;
                SET @item = LTRIM(RTRIM(SUBSTRING(@input, @pos, @end - @pos)));
                IF LEN(@item) > 0
                    INSERT INTO @DaysCursor (item) VALUES (@item);
                SET @pos = @end + 1;
            END

            INSERT INTO hr.VacationRequestDay (RequestId, SelectedDate, DayType)
            SELECT @RequestId,
                   CAST(LEFT(item, 10) AS DATE),
                   CASE WHEN CHARINDEX('|', item) > 0
                        THEN SUBSTRING(item, CHARINDEX('|', item) + 1, 20)
                        ELSE 'COMPLETO' END
            FROM @DaysCursor
            WHERE LEN(item) >= 10;
        END

        COMMIT TRANSACTION;

        SELECT @RequestId AS RequestId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END
GO

-- =============================================================
-- 2) usp_HR_VacationRequest_List
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_List')
    DROP PROCEDURE usp_HR_VacationRequest_List
GO

CREATE PROCEDURE usp_HR_VacationRequest_List
    @CompanyId      INT,
    @EmployeeCode   NVARCHAR(60) = NULL,
    @Status         NVARCHAR(20) = NULL,
    @Offset         INT = 0,
    @Limit          INT = 50,
    @TotalCount     INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM hr.VacationRequest vr
    WHERE vr.CompanyId = @CompanyId
      AND (@EmployeeCode IS NULL OR vr.EmployeeCode = @EmployeeCode)
      AND (@Status IS NULL OR vr.Status = @Status);

    SELECT
        vr.RequestId,
        vr.EmployeeCode,
        ISNULL(e.EmployeeName, vr.EmployeeCode) AS EmployeeName,
        CONVERT(NVARCHAR(10), vr.RequestDate, 120) AS RequestDate,
        CONVERT(NVARCHAR(10), vr.StartDate, 120) AS StartDate,
        CONVERT(NVARCHAR(10), vr.EndDate, 120) AS EndDate,
        vr.TotalDays,
        vr.IsPartial,
        vr.Status,
        vr.ApprovedBy,
        vr.Notes,
        vr.RejectionReason,
        vr.CreatedAt
    FROM hr.VacationRequest vr
    LEFT JOIN master.Employee e
        ON e.CompanyId = vr.CompanyId
       AND e.EmployeeCode = vr.EmployeeCode
    WHERE vr.CompanyId = @CompanyId
      AND (@EmployeeCode IS NULL OR vr.EmployeeCode = @EmployeeCode)
      AND (@Status IS NULL OR vr.Status = @Status)
    ORDER BY vr.RequestDate DESC, vr.RequestId DESC
    OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

-- =============================================================
-- 3) usp_HR_VacationRequest_Get
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_Get')
    DROP PROCEDURE usp_HR_VacationRequest_Get
GO

CREATE PROCEDURE usp_HR_VacationRequest_Get
    @RequestId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        vr.RequestId,
        vr.CompanyId,
        vr.BranchId,
        vr.EmployeeCode,
        ISNULL(e.EmployeeName, vr.EmployeeCode) AS EmployeeName,
        CONVERT(NVARCHAR(10), vr.RequestDate, 120) AS RequestDate,
        CONVERT(NVARCHAR(10), vr.StartDate, 120) AS StartDate,
        CONVERT(NVARCHAR(10), vr.EndDate, 120) AS EndDate,
        vr.TotalDays,
        vr.IsPartial,
        vr.Status,
        vr.Notes,
        vr.ApprovedBy,
        vr.ApprovalDate,
        vr.RejectionReason,
        vr.VacationId,
        vr.CreatedAt,
        vr.UpdatedAt
    FROM hr.VacationRequest vr
    LEFT JOIN master.Employee e
        ON e.CompanyId = vr.CompanyId
       AND e.EmployeeCode = vr.EmployeeCode
    WHERE vr.RequestId = @RequestId;

    SELECT
        d.DayId,
        d.RequestId,
        CONVERT(NVARCHAR(10), d.SelectedDate, 120) AS SelectedDate,
        d.DayType
    FROM hr.VacationRequestDay d
    WHERE d.RequestId = @RequestId
    ORDER BY d.SelectedDate;
END
GO

-- =============================================================
-- 4) usp_HR_VacationRequest_Approve
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_Approve')
    DROP PROCEDURE usp_HR_VacationRequest_Approve
GO

CREATE PROCEDURE usp_HR_VacationRequest_Approve
    @RequestId  BIGINT,
    @ApprovedBy NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = @RequestId AND Status = 'PENDIENTE')
    BEGIN RAISERROR('Solo se pueden aprobar solicitudes en estado PENDIENTE.', 16, 1); RETURN; END

    UPDATE hr.VacationRequest
    SET Status       = 'APROBADA',
        ApprovedBy   = @ApprovedBy,
        ApprovalDate = SYSUTCDATETIME(),
        UpdatedAt    = SYSUTCDATETIME()
    WHERE RequestId = @RequestId AND Status = 'PENDIENTE';

    SELECT @RequestId AS RequestId, 'APROBADA' AS Status;
END
GO

-- =============================================================
-- 5) usp_HR_VacationRequest_Reject
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_Reject')
    DROP PROCEDURE usp_HR_VacationRequest_Reject
GO

CREATE PROCEDURE usp_HR_VacationRequest_Reject
    @RequestId       BIGINT,
    @ApprovedBy      NVARCHAR(60),
    @RejectionReason NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = @RequestId AND Status = 'PENDIENTE')
    BEGIN RAISERROR('Solo se pueden rechazar solicitudes en estado PENDIENTE.', 16, 1); RETURN; END

    UPDATE hr.VacationRequest
    SET Status          = 'RECHAZADA',
        ApprovedBy      = @ApprovedBy,
        ApprovalDate    = SYSUTCDATETIME(),
        RejectionReason = @RejectionReason,
        UpdatedAt       = SYSUTCDATETIME()
    WHERE RequestId = @RequestId AND Status = 'PENDIENTE';

    SELECT @RequestId AS RequestId, 'RECHAZADA' AS Status;
END
GO

-- =============================================================
-- 6) usp_HR_VacationRequest_Cancel
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_Cancel')
    DROP PROCEDURE usp_HR_VacationRequest_Cancel
GO

CREATE PROCEDURE usp_HR_VacationRequest_Cancel
    @RequestId  BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = @RequestId AND Status = 'PENDIENTE')
    BEGIN RAISERROR('Solo se pueden cancelar solicitudes en estado PENDIENTE.', 16, 1); RETURN; END

    UPDATE hr.VacationRequest
    SET Status    = 'CANCELADA',
        UpdatedAt = SYSUTCDATETIME()
    WHERE RequestId = @RequestId AND Status = 'PENDIENTE';

    SELECT @RequestId AS RequestId, 'CANCELADA' AS Status;
END
GO

-- =============================================================
-- 7) usp_HR_VacationRequest_Process
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_Process')
    DROP PROCEDURE usp_HR_VacationRequest_Process
GO

CREATE PROCEDURE usp_HR_VacationRequest_Process
    @RequestId  BIGINT,
    @VacationId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM hr.VacationRequest WHERE RequestId = @RequestId AND Status = 'APROBADA')
    BEGIN RAISERROR('Solo se pueden procesar solicitudes en estado APROBADA.', 16, 1); RETURN; END

    UPDATE hr.VacationRequest
    SET Status     = 'PROCESADA',
        VacationId = @VacationId,
        UpdatedAt  = SYSUTCDATETIME()
    WHERE RequestId = @RequestId AND Status = 'APROBADA';

    SELECT @RequestId AS RequestId, 'PROCESADA' AS Status, @VacationId AS VacationId;
END
GO

-- =============================================================
-- 8) usp_HR_VacationRequest_GetAvailableDays
-- =============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'usp_HR_VacationRequest_GetAvailableDays')
    DROP PROCEDURE usp_HR_VacationRequest_GetAvailableDays
GO

CREATE PROCEDURE usp_HR_VacationRequest_GetAvailableDays
    @CompanyId      INT,
    @EmployeeCode   NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @HireDate        DATE;
    DECLARE @AnosServicio    INT;
    DECLARE @DiasBase        INT = 15;
    DECLARE @DiasAdicionales INT;
    DECLARE @DiasDisponibles INT;
    DECLARE @DiasTomados     INT;
    DECLARE @DiasPendientes  INT;

    SELECT @HireDate = e.HireDate
    FROM master.Employee e
    WHERE e.CompanyId = @CompanyId
      AND e.EmployeeCode = @EmployeeCode
      AND ISNULL(e.IsDeleted, 0) = 0;

    IF @HireDate IS NULL
    BEGIN
        -- Si no hay fecha de ingreso, retornar valores por defecto
        SELECT
            @DiasBase AS DiasBase,
            0 AS AnosServicio,
            0 AS DiasAdicionales,
            @DiasBase AS DiasDisponibles,
            0 AS DiasTomados,
            0 AS DiasPendientes,
            @DiasBase AS DiasSaldo;
        RETURN;
    END

    SET @AnosServicio = DATEDIFF(YEAR, @HireDate, SYSUTCDATETIME());
    IF DATEADD(YEAR, @AnosServicio, @HireDate) > SYSUTCDATETIME()
        SET @AnosServicio = @AnosServicio - 1;
    IF @AnosServicio < 0
        SET @AnosServicio = 0;

    SET @DiasAdicionales = @AnosServicio;
    SET @DiasDisponibles = @DiasBase + @DiasAdicionales;

    -- Dias ya procesados (disfrutados) en el año actual
    -- VacationProcess no tiene TotalDays, calculamos con DATEDIFF
    SELECT @DiasTomados = ISNULL(SUM(DATEDIFF(DAY, vp.StartDate, vp.EndDate) + 1), 0)
    FROM hr.VacationProcess vp
    WHERE vp.CompanyId = @CompanyId
      AND vp.EmployeeCode = @EmployeeCode
      AND YEAR(vp.StartDate) = YEAR(SYSUTCDATETIME());

    -- Dias en solicitudes pendientes o aprobadas
    SELECT @DiasPendientes = ISNULL(SUM(vr.TotalDays), 0)
    FROM hr.VacationRequest vr
    WHERE vr.CompanyId = @CompanyId
      AND vr.EmployeeCode = @EmployeeCode
      AND vr.Status IN ('PENDIENTE', 'APROBADA');

    SELECT
        @DiasBase           AS DiasBase,
        @AnosServicio       AS AnosServicio,
        @DiasAdicionales    AS DiasAdicionales,
        @DiasDisponibles    AS DiasDisponibles,
        @DiasTomados        AS DiasTomados,
        @DiasPendientes     AS DiasPendientes,
        (@DiasDisponibles - ISNULL(@DiasTomados, 0) - ISNULL(@DiasPendientes, 0)) AS DiasSaldo;
END
GO
