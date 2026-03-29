/*
 * ============================================================================
 *  Archivo : usp_crm.sql
 *  Esquema : crm (Customer Relationship Management)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Procedimientos almacenados para el modulo CRM.
 *    - Pipelines y Stages
 *    - Leads (prospectos)
 *    - Activities (actividades)
 *    - Dashboard / KPIs
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- =============================================================================
--  usp_CRM_Pipeline_List
--  Lista todos los pipelines de una empresa con conteo de etapas.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Pipeline_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        p.PipelineId,
        p.PipelineCode,
        p.PipelineName,
        p.IsDefault,
        p.IsActive,
        p.CreatedAt,
        p.UpdatedAt,
        (SELECT COUNT(*) FROM crm.PipelineStage s WHERE s.PipelineId = p.PipelineId AND s.IsActive = 1) AS StageCount
    FROM crm.Pipeline p
    WHERE p.CompanyId = @CompanyId
    ORDER BY p.IsDefault DESC, p.PipelineName;
END;
GO

-- =============================================================================
--  usp_CRM_Pipeline_Upsert
--  Inserta o actualiza un pipeline.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Pipeline_Upsert
    @CompanyId    INT,
    @PipelineId   INT           = NULL,
    @PipelineCode NVARCHAR(30),
    @PipelineName NVARCHAR(120),
    @IsDefault    BIT           = 0,
    @IsActive     BIT           = 1,
    @UserId       INT,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        -- Si se marca como default, quitar default a los demas
        IF @IsDefault = 1
        BEGIN
            UPDATE crm.Pipeline SET IsDefault = 0
            WHERE  CompanyId = @CompanyId AND (@PipelineId IS NULL OR PipelineId <> @PipelineId);
        END;

        IF @PipelineId IS NULL
        BEGIN
            -- Verificar duplicado de codigo
            IF EXISTS (SELECT 1 FROM crm.Pipeline WHERE CompanyId = @CompanyId AND PipelineCode = @PipelineCode)
            BEGIN
                SET @Mensaje = N'Ya existe un pipeline con el codigo ' + @PipelineCode;
                RETURN;
            END;

            INSERT INTO crm.Pipeline (CompanyId, PipelineCode, PipelineName, IsDefault, IsActive, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@CompanyId, @PipelineCode, @PipelineName, @IsDefault, @IsActive, @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());

            SET @PipelineId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE crm.Pipeline
            SET    PipelineCode    = @PipelineCode,
                   PipelineName    = @PipelineName,
                   IsDefault       = @IsDefault,
                   IsActive        = @IsActive,
                   UpdatedByUserId = @UserId,
                   UpdatedAt       = SYSUTCDATETIME()
            WHERE  PipelineId = @PipelineId AND CompanyId = @CompanyId;
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Pipeline_GetStages
--  Devuelve las etapas de un pipeline, ordenadas por StageOrder.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Pipeline_GetStages
    @PipelineId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.StageId,
        s.PipelineId,
        s.StageCode,
        s.StageName,
        s.StageOrder,
        s.Probability,
        s.DaysExpected,
        s.Color,
        s.IsClosed,
        s.IsWon,
        s.IsActive
    FROM crm.PipelineStage s
    WHERE s.PipelineId = @PipelineId
    ORDER BY s.StageOrder;
END;
GO

-- =============================================================================
--  usp_CRM_Stage_Upsert
--  Inserta o actualiza una etapa dentro de un pipeline.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Stage_Upsert
    @PipelineId   INT,
    @StageId      INT           = NULL,
    @StageCode    NVARCHAR(30),
    @StageName    NVARCHAR(120),
    @StageOrder   INT,
    @Probability  DECIMAL(5,2)  = 0,
    @DaysExpected INT           = 0,
    @Color        NVARCHAR(20)  = NULL,
    @IsClosed     BIT           = 0,
    @IsWon        BIT           = 0,
    @IsActive     BIT           = 1,
    @UserId       INT,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF @StageId IS NULL
        BEGIN
            INSERT INTO crm.PipelineStage (PipelineId, StageCode, StageName, StageOrder, Probability, DaysExpected, Color, IsClosed, IsWon, IsActive, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@PipelineId, @StageCode, @StageName, @StageOrder, @Probability, @DaysExpected, @Color, @IsClosed, @IsWon, @IsActive, @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());
        END
        ELSE
        BEGIN
            UPDATE crm.PipelineStage
            SET    StageCode       = @StageCode,
                   StageName       = @StageName,
                   StageOrder      = @StageOrder,
                   Probability     = @Probability,
                   DaysExpected    = @DaysExpected,
                   Color           = @Color,
                   IsClosed        = @IsClosed,
                   IsWon           = @IsWon,
                   IsActive        = @IsActive,
                   UpdatedByUserId = @UserId,
                   UpdatedAt       = SYSUTCDATETIME()
            WHERE  StageId = @StageId AND PipelineId = @PipelineId;
        END;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Lead_List
--  Listado paginado de leads con filtros multiples.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Lead_List
    @CompanyId        INT,
    @PipelineId       INT           = NULL,
    @StageId          INT           = NULL,
    @Status           NVARCHAR(20)  = NULL,
    @AssignedToUserId INT           = NULL,
    @Source           NVARCHAR(50)  = NULL,
    @Priority         NVARCHAR(20)  = NULL,
    @Search           NVARCHAR(200) = NULL,
    @Page             INT           = 1,
    @Limit            INT           = 50,
    @TotalCount       INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   crm.Lead l
    WHERE  l.CompanyId = @CompanyId
      AND  (@PipelineId       IS NULL OR l.PipelineId       = @PipelineId)
      AND  (@StageId          IS NULL OR l.StageId          = @StageId)
      AND  (@Status           IS NULL OR l.Status           = @Status)
      AND  (@AssignedToUserId IS NULL OR l.AssignedToUserId = @AssignedToUserId)
      AND  (@Source           IS NULL OR l.Source            = @Source)
      AND  (@Priority         IS NULL OR l.Priority         = @Priority)
      AND  (@Search           IS NULL OR l.ContactName LIKE '%' + @Search + '%'
                                      OR l.CompanyName LIKE '%' + @Search + '%'
                                      OR l.LeadCode    LIKE '%' + @Search + '%'
                                      OR l.Email       LIKE '%' + @Search + '%');

    SELECT
        l.LeadId,
        l.LeadCode,
        l.PipelineId,
        l.StageId,
        s.StageName,
        s.Color        AS StageColor,
        l.ContactName,
        l.CompanyName,
        l.Email,
        l.Phone,
        l.Source,
        l.Status,
        l.AssignedToUserId,
        l.EstimatedValue,
        l.CurrencyCode,
        l.ExpectedCloseDate,
        l.Priority,
        l.Tags,
        l.CreatedAt,
        l.UpdatedAt
    FROM   crm.Lead l
    LEFT JOIN crm.PipelineStage s ON s.StageId = l.StageId
    WHERE  l.CompanyId = @CompanyId
      AND  (@PipelineId       IS NULL OR l.PipelineId       = @PipelineId)
      AND  (@StageId          IS NULL OR l.StageId          = @StageId)
      AND  (@Status           IS NULL OR l.Status           = @Status)
      AND  (@AssignedToUserId IS NULL OR l.AssignedToUserId = @AssignedToUserId)
      AND  (@Source           IS NULL OR l.Source            = @Source)
      AND  (@Priority         IS NULL OR l.Priority         = @Priority)
      AND  (@Search           IS NULL OR l.ContactName LIKE '%' + @Search + '%'
                                      OR l.CompanyName LIKE '%' + @Search + '%'
                                      OR l.LeadCode    LIKE '%' + @Search + '%'
                                      OR l.Email       LIKE '%' + @Search + '%')
    ORDER BY l.CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_CRM_Lead_Get
--  Detalle de un lead con sus actividades e historial.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Lead_Get
    @LeadId INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Recordset 1: Lead header
    SELECT
        l.LeadId, l.LeadCode, l.CompanyId, l.BranchId,
        l.PipelineId, p.PipelineName,
        l.StageId, s.StageName, s.Color AS StageColor,
        l.ContactName, l.CompanyName, l.Email, l.Phone,
        l.Source, l.Status, l.AssignedToUserId,
        l.EstimatedValue, l.CurrencyCode,
        l.ExpectedCloseDate, l.Notes, l.Tags, l.Priority,
        l.LostReason, l.CustomerId,
        l.CreatedAt, l.UpdatedAt
    FROM   crm.Lead l
    LEFT JOIN crm.Pipeline      p ON p.PipelineId = l.PipelineId
    LEFT JOIN crm.PipelineStage s ON s.StageId    = l.StageId
    WHERE  l.LeadId = @LeadId;

    -- Recordset 2: Activities
    SELECT
        a.ActivityId, a.ActivityType, a.Subject, a.Description,
        a.DueDate, a.CompletedAt, a.IsCompleted, a.Priority,
        a.AssignedToUserId, a.CreatedAt
    FROM   crm.Activity a
    WHERE  a.LeadId = @LeadId
    ORDER BY a.DueDate DESC;

    -- Recordset 3: History
    SELECT
        h.HistoryId, h.Action, h.FromStageId, h.ToStageId,
        fs.StageName AS FromStageName, ts.StageName AS ToStageName,
        h.Notes, h.CreatedAt, h.CreatedByUserId
    FROM   crm.LeadHistory h
    LEFT JOIN crm.PipelineStage fs ON fs.StageId = h.FromStageId
    LEFT JOIN crm.PipelineStage ts ON ts.StageId = h.ToStageId
    WHERE  h.LeadId = @LeadId
    ORDER BY h.CreatedAt DESC;
END;
GO

-- =============================================================================
--  usp_CRM_Lead_Create
--  Crea un nuevo lead y genera codigo automatico.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Lead_Create
    @CompanyId        INT,
    @BranchId         INT,
    @PipelineId       INT,
    @StageId          INT,
    @ContactName      NVARCHAR(200),
    @CompanyName      NVARCHAR(200) = NULL,
    @Email            NVARCHAR(200) = NULL,
    @Phone            NVARCHAR(60)  = NULL,
    @Source           NVARCHAR(50),
    @AssignedToUserId INT           = NULL,
    @EstimatedValue   DECIMAL(18,2) = 0,
    @CurrencyCode     NVARCHAR(5)   = 'USD',
    @ExpectedCloseDate DATETIME2    = NULL,
    @Notes            NVARCHAR(MAX) = NULL,
    @Tags             NVARCHAR(500) = NULL,
    @Priority         NVARCHAR(20)  = 'MEDIUM',
    @UserId           INT,
    @Resultado        INT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT,
    @LeadId           INT           OUTPUT,
    @LeadCode         NVARCHAR(30)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @LeadId = 0;

    BEGIN TRY
        -- Generar codigo secuencial: LEAD-000001
        DECLARE @Seq INT;
        SELECT @Seq = ISNULL(MAX(LeadId), 0) + 1 FROM crm.Lead WHERE CompanyId = @CompanyId;
        SET @LeadCode = 'LEAD-' + RIGHT('000000' + CAST(@Seq AS VARCHAR), 6);

        INSERT INTO crm.Lead (
            CompanyId, BranchId, LeadCode, PipelineId, StageId,
            ContactName, CompanyName, Email, Phone, Source,
            AssignedToUserId, EstimatedValue, CurrencyCode,
            ExpectedCloseDate, Notes, Tags, Priority, Status,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        ) VALUES (
            @CompanyId, @BranchId, @LeadCode, @PipelineId, @StageId,
            @ContactName, @CompanyName, @Email, @Phone, @Source,
            @AssignedToUserId, @EstimatedValue, @CurrencyCode,
            @ExpectedCloseDate, @Notes, @Tags, @Priority, 'OPEN',
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @LeadId = SCOPE_IDENTITY();

        -- Registrar en historial
        INSERT INTO crm.LeadHistory (LeadId, Action, ToStageId, Notes, CreatedByUserId, CreatedAt)
        VALUES (@LeadId, 'CREATED', @StageId, N'Lead creado', @UserId, SYSUTCDATETIME());

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Lead_Update
--  Actualiza campos de un lead existente (solo campos no-null se actualizan).
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Lead_Update
    @LeadId           INT,
    @StageId          INT           = NULL,
    @ContactName      NVARCHAR(200) = NULL,
    @CompanyName      NVARCHAR(200) = NULL,
    @Email            NVARCHAR(200) = NULL,
    @Phone            NVARCHAR(60)  = NULL,
    @AssignedToUserId INT           = NULL,
    @EstimatedValue   DECIMAL(18,2) = NULL,
    @ExpectedCloseDate DATETIME2    = NULL,
    @Notes            NVARCHAR(MAX) = NULL,
    @Tags             NVARCHAR(500) = NULL,
    @Priority         NVARCHAR(20)  = NULL,
    @UserId           INT,
    @Resultado        INT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        UPDATE crm.Lead
        SET    StageId          = ISNULL(@StageId,          StageId),
               ContactName      = ISNULL(@ContactName,      ContactName),
               CompanyName      = ISNULL(@CompanyName,      CompanyName),
               Email            = ISNULL(@Email,            Email),
               Phone            = ISNULL(@Phone,            Phone),
               AssignedToUserId = ISNULL(@AssignedToUserId, AssignedToUserId),
               EstimatedValue   = ISNULL(@EstimatedValue,   EstimatedValue),
               ExpectedCloseDate= ISNULL(@ExpectedCloseDate,ExpectedCloseDate),
               Notes            = ISNULL(@Notes,            Notes),
               Tags             = ISNULL(@Tags,             Tags),
               Priority         = ISNULL(@Priority,         Priority),
               UpdatedByUserId  = @UserId,
               UpdatedAt        = SYSUTCDATETIME()
        WHERE  LeadId = @LeadId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Lead_ChangeStage
--  Mueve un lead a una nueva etapa y registra en historial.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Lead_ChangeStage
    @LeadId     INT,
    @NewStageId INT,
    @Notes      NVARCHAR(500) = NULL,
    @UserId     INT,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        DECLARE @OldStageId INT;
        SELECT @OldStageId = StageId FROM crm.Lead WHERE LeadId = @LeadId;

        IF @OldStageId IS NULL
        BEGIN
            SET @Mensaje = N'Lead no encontrado';
            RETURN;
        END;

        UPDATE crm.Lead
        SET    StageId         = @NewStageId,
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  LeadId = @LeadId;

        INSERT INTO crm.LeadHistory (LeadId, Action, FromStageId, ToStageId, Notes, CreatedByUserId, CreatedAt)
        VALUES (@LeadId, 'STAGE_CHANGE', @OldStageId, @NewStageId, @Notes, @UserId, SYSUTCDATETIME());

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Lead_Close
--  Cierra un lead como ganado o perdido.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Lead_Close
    @LeadId    INT,
    @IsWon     BIT,
    @LostReason NVARCHAR(500) = NULL,
    @CustomerId INT           = NULL,
    @UserId    INT,
    @Resultado INT            OUTPUT,
    @Mensaje   NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        DECLARE @OldStageId INT;
        DECLARE @NewStatus NVARCHAR(20) = CASE WHEN @IsWon = 1 THEN 'WON' ELSE 'LOST' END;

        SELECT @OldStageId = StageId FROM crm.Lead WHERE LeadId = @LeadId;

        IF @OldStageId IS NULL
        BEGIN
            SET @Mensaje = N'Lead no encontrado';
            RETURN;
        END;

        -- Buscar la etapa cerrada correspondiente (ganada o perdida)
        DECLARE @ClosedStageId INT;
        SELECT TOP 1 @ClosedStageId = s.StageId
        FROM   crm.PipelineStage s
        JOIN   crm.Lead l ON l.PipelineId = s.PipelineId
        WHERE  l.LeadId = @LeadId AND s.IsClosed = 1 AND s.IsWon = @IsWon;

        UPDATE crm.Lead
        SET    Status          = @NewStatus,
               StageId         = ISNULL(@ClosedStageId, StageId),
               LostReason      = @LostReason,
               CustomerId      = @CustomerId,
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  LeadId = @LeadId;

        INSERT INTO crm.LeadHistory (LeadId, Action, FromStageId, ToStageId, Notes, CreatedByUserId, CreatedAt)
        VALUES (@LeadId, @NewStatus, @OldStageId, ISNULL(@ClosedStageId, @OldStageId),
                ISNULL(@LostReason, N'Cerrado como ' + @NewStatus), @UserId, SYSUTCDATETIME());

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Activity_List
--  Listado paginado de actividades CRM.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Activity_List
    @CompanyId   INT,
    @LeadId      INT           = NULL,
    @CustomerId  INT           = NULL,
    @IsCompleted BIT           = NULL,
    @DueBefore   DATETIME2     = NULL,
    @Page        INT           = 1,
    @Limit       INT           = 50,
    @TotalCount  INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM   crm.Activity a
    WHERE  a.CompanyId = @CompanyId
      AND  (@LeadId      IS NULL OR a.LeadId      = @LeadId)
      AND  (@CustomerId  IS NULL OR a.CustomerId   = @CustomerId)
      AND  (@IsCompleted IS NULL OR a.IsCompleted  = @IsCompleted)
      AND  (@DueBefore   IS NULL OR a.DueDate     <= @DueBefore);

    SELECT
        a.ActivityId, a.LeadId, a.CustomerId,
        a.ActivityType, a.Subject, a.Description,
        a.DueDate, a.CompletedAt, a.IsCompleted,
        a.Priority, a.AssignedToUserId,
        a.CreatedAt, a.UpdatedAt
    FROM   crm.Activity a
    WHERE  a.CompanyId = @CompanyId
      AND  (@LeadId      IS NULL OR a.LeadId      = @LeadId)
      AND  (@CustomerId  IS NULL OR a.CustomerId   = @CustomerId)
      AND  (@IsCompleted IS NULL OR a.IsCompleted  = @IsCompleted)
      AND  (@DueBefore   IS NULL OR a.DueDate     <= @DueBefore)
    ORDER BY a.DueDate ASC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_CRM_Activity_Create
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Activity_Create
    @CompanyId        INT,
    @LeadId           INT           = NULL,
    @CustomerId       INT           = NULL,
    @ActivityType     NVARCHAR(30),
    @Subject          NVARCHAR(200),
    @Description      NVARCHAR(MAX) = NULL,
    @DueDate          DATETIME2     = NULL,
    @AssignedToUserId INT,
    @Priority         NVARCHAR(20)  = 'MEDIUM',
    @UserId           INT,
    @Resultado        INT           OUTPUT,
    @Mensaje          NVARCHAR(500) OUTPUT,
    @ActivityId       INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        INSERT INTO crm.Activity (
            CompanyId, LeadId, CustomerId, ActivityType,
            Subject, Description, DueDate, IsCompleted,
            AssignedToUserId, Priority,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        ) VALUES (
            @CompanyId, @LeadId, @CustomerId, @ActivityType,
            @Subject, @Description, @DueDate, 0,
            @AssignedToUserId, @Priority,
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @ActivityId = SCOPE_IDENTITY();
        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Activity_Complete
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Activity_Complete
    @ActivityId INT,
    @UserId     INT,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        UPDATE crm.Activity
        SET    IsCompleted     = 1,
               CompletedAt     = SYSUTCDATETIME(),
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  ActivityId = @ActivityId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Activity_Update
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Activity_Update
    @ActivityId  INT,
    @Subject     NVARCHAR(200) = NULL,
    @Description NVARCHAR(MAX) = NULL,
    @DueDate     DATETIME2     = NULL,
    @Priority    NVARCHAR(20)  = NULL,
    @UserId      INT,
    @Resultado   INT           OUTPUT,
    @Mensaje     NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        UPDATE crm.Activity
        SET    Subject         = ISNULL(@Subject,     Subject),
               Description     = ISNULL(@Description, Description),
               DueDate         = ISNULL(@DueDate,     DueDate),
               Priority        = ISNULL(@Priority,    Priority),
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  ActivityId = @ActivityId;

        SET @Resultado = 1;
        SET @Mensaje = N'OK';
    END TRY
    BEGIN CATCH
        SET @Resultado = 0;
        SET @Mensaje = ERROR_MESSAGE();
    END CATCH;
END;
GO

-- =============================================================================
--  usp_CRM_Dashboard
--  KPIs del pipeline CRM: leads por etapa, tasa de conversion, valor promedio.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Dashboard
    @CompanyId  INT,
    @PipelineId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Resolver pipeline (si no se indica, usar el default)
    IF @PipelineId IS NULL
    BEGIN
        SELECT TOP 1 @PipelineId = PipelineId
        FROM   crm.Pipeline
        WHERE  CompanyId = @CompanyId AND IsDefault = 1 AND IsActive = 1;
    END;

    -- Leads por etapa
    SELECT
        s.StageId,
        s.StageName,
        s.StageOrder,
        s.Color,
        COUNT(l.LeadId)          AS LeadCount,
        ISNULL(SUM(l.EstimatedValue), 0) AS TotalValue
    FROM   crm.PipelineStage s
    LEFT JOIN crm.Lead l ON l.StageId = s.StageId AND l.Status = 'OPEN'
    WHERE  s.PipelineId = @PipelineId
    GROUP BY s.StageId, s.StageName, s.StageOrder, s.Color
    ORDER BY s.StageOrder;

    -- KPIs generales
    DECLARE @TotalLeads INT, @WonLeads INT, @LostLeads INT, @AvgValue DECIMAL(18,2);
    DECLARE @MonthStart DATETIME2 = DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE));

    SELECT @TotalLeads = COUNT(*) FROM crm.Lead WHERE CompanyId = @CompanyId AND PipelineId = @PipelineId;
    SELECT @WonLeads   = COUNT(*) FROM crm.Lead WHERE CompanyId = @CompanyId AND PipelineId = @PipelineId AND Status = 'WON';
    SELECT @LostLeads  = COUNT(*) FROM crm.Lead WHERE CompanyId = @CompanyId AND PipelineId = @PipelineId AND Status = 'LOST';
    SELECT @AvgValue   = ISNULL(AVG(EstimatedValue), 0) FROM crm.Lead WHERE CompanyId = @CompanyId AND PipelineId = @PipelineId AND Status = 'WON';

    SELECT
        @TotalLeads AS TotalLeads,
        @WonLeads   AS WonLeads,
        @LostLeads  AS LostLeads,
        CASE WHEN @TotalLeads > 0 THEN CAST(@WonLeads * 100.0 / @TotalLeads AS DECIMAL(5,2)) ELSE 0 END AS ConversionRate,
        @AvgValue   AS AvgDealValue,
        (SELECT COUNT(*) FROM crm.Lead WHERE CompanyId = @CompanyId AND PipelineId = @PipelineId AND Status = 'WON' AND UpdatedAt >= @MonthStart) AS WonThisMonth,
        (SELECT COUNT(*) FROM crm.Lead WHERE CompanyId = @CompanyId AND PipelineId = @PipelineId AND Status = 'LOST' AND UpdatedAt >= @MonthStart) AS LostThisMonth;
END;
GO
