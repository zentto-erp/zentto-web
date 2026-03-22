/*
 * ============================================================================
 *  Archivo : usp_crm_callcenter.sql
 *  Esquema : crm (Call Center)
 *  Base    : DatqBoxWeb
 *  Fecha   : 2026-03-22
 *
 *  Descripcion:
 *    Tablas y procedimientos almacenados para el subsistema Call Center del CRM.
 *    - Colas (CallQueue)
 *    - Agentes (Agent)
 *    - Registro de llamadas (CallLog)
 *    - Scripts de llamada (CallScript)
 *    - Campanas (Campaign / CampaignContact)
 *    - Dashboard de metricas
 *
 *  Patron  : CREATE OR ALTER (idempotente)
 * ============================================================================
 */

USE DatqBoxWeb;
GO

-- ═══════════════════════════════════════════════════════════════════════════════
--  TABLAS
-- ═══════════════════════════════════════════════════════════════════════════════

-- ── 1. crm.CallQueue ────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'crm' AND t.name = 'CallQueue')
BEGIN
    CREATE TABLE crm.CallQueue (
        QueueId           BIGINT        IDENTITY(1,1) NOT NULL,
        CompanyId         INT           NOT NULL,
        QueueCode         NVARCHAR(20)  NOT NULL,
        QueueName         NVARCHAR(100) NOT NULL,
        QueueType         NVARCHAR(20)  NOT NULL DEFAULT 'GENERAL',  -- SALES/SUPPORT/COLLECTIONS/GENERAL
        Description       NVARCHAR(500) NULL,
        IsActive          BIT           NOT NULL DEFAULT 1,
        CreatedAt         DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt         DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId   INT           NULL,
        UpdatedByUserId   INT           NULL,
        IsDeleted         BIT           NOT NULL DEFAULT 0,
        DeletedAt         DATETIME2(0)  NULL,
        DeletedByUserId   INT           NULL,
        RowVer            ROWVERSION    NOT NULL,
        CONSTRAINT PK_CallQueue PRIMARY KEY (QueueId),
        CONSTRAINT FK_CallQueue_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT UQ_CallQueue_Code UNIQUE (CompanyId, QueueCode),
        CONSTRAINT CK_CallQueue_Type CHECK (QueueType IN ('SALES','SUPPORT','COLLECTIONS','GENERAL'))
    );
END;
GO

-- ── 2. crm.Agent ────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'crm' AND t.name = 'Agent')
BEGIN
    CREATE TABLE crm.Agent (
        AgentId              BIGINT        IDENTITY(1,1) NOT NULL,
        CompanyId            INT           NOT NULL,
        UserId               INT           NOT NULL,
        QueueId              BIGINT        NULL,
        AgentCode            NVARCHAR(20)  NOT NULL,
        AgentName            NVARCHAR(200) NOT NULL,
        Extension            NVARCHAR(20)  NULL,
        Status               NVARCHAR(20)  NOT NULL DEFAULT 'OFFLINE',  -- AVAILABLE/BUSY/ON_CALL/BREAK/OFFLINE
        MaxConcurrentCalls   INT           NOT NULL DEFAULT 1,
        IsActive             BIT           NOT NULL DEFAULT 1,
        CreatedAt            DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt            DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId      INT           NULL,
        UpdatedByUserId      INT           NULL,
        IsDeleted            BIT           NOT NULL DEFAULT 0,
        DeletedAt            DATETIME2(0)  NULL,
        DeletedByUserId      INT           NULL,
        RowVer               ROWVERSION    NOT NULL,
        CONSTRAINT PK_Agent PRIMARY KEY (AgentId),
        CONSTRAINT FK_Agent_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT FK_Agent_User FOREIGN KEY (UserId) REFERENCES sec.[User](UserId),
        CONSTRAINT FK_Agent_Queue FOREIGN KEY (QueueId) REFERENCES crm.CallQueue(QueueId),
        CONSTRAINT UQ_Agent_Code UNIQUE (CompanyId, AgentCode),
        CONSTRAINT CK_Agent_Status CHECK (Status IN ('AVAILABLE','BUSY','ON_CALL','BREAK','OFFLINE'))
    );
END;
GO

-- ── 3. crm.CallLog ──────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'crm' AND t.name = 'CallLog')
BEGIN
    CREATE TABLE crm.CallLog (
        CallLogId              BIGINT         IDENTITY(1,1) NOT NULL,
        CompanyId              INT            NOT NULL,
        BranchId               INT            NOT NULL,
        AgentId                BIGINT         NULL,
        QueueId                BIGINT         NULL,
        CallDirection          NVARCHAR(10)   NOT NULL,       -- INBOUND/OUTBOUND
        CallerNumber           NVARCHAR(30)   NOT NULL,
        CalledNumber           NVARCHAR(30)   NOT NULL,
        CustomerCode           NVARCHAR(24)   NULL,
        CustomerId             BIGINT         NULL,
        LeadId                 BIGINT         NULL,
        ContactName            NVARCHAR(200)  NULL,
        CallStartTime          DATETIME2(0)   NOT NULL,
        CallEndTime            DATETIME2(0)   NULL,
        DurationSeconds        INT            NULL,
        WaitSeconds            INT            NULL,
        Result                 NVARCHAR(20)   NOT NULL,       -- ANSWERED/NO_ANSWER/BUSY/VOICEMAIL/CALLBACK/TRANSFERRED/DROPPED
        Disposition            NVARCHAR(30)   NULL,            -- SALE/APPOINTMENT/INFO/COMPLAINT/COLLECTION_PROMISE/COLLECTION_REFUSED/WRONG_NUMBER/NOT_INTERESTED/CALLBACK_SCHEDULED/OTHER
        Notes                  NVARCHAR(MAX)  NULL,
        RecordingUrl           NVARCHAR(500)  NULL,
        CallbackScheduled      DATETIME2(0)   NULL,
        RelatedDocumentType    NVARCHAR(30)   NULL,
        RelatedDocumentNumber  NVARCHAR(60)   NULL,
        Tags                   NVARCHAR(500)  NULL,
        SatisfactionScore      INT            NULL,
        CreatedAt              DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt              DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId        INT            NULL,
        UpdatedByUserId        INT            NULL,
        IsDeleted              BIT            NOT NULL DEFAULT 0,
        DeletedAt              DATETIME2(0)   NULL,
        DeletedByUserId        INT            NULL,
        RowVer                 ROWVERSION     NOT NULL,
        CONSTRAINT PK_CallLog PRIMARY KEY (CallLogId),
        CONSTRAINT FK_CallLog_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT FK_CallLog_Branch FOREIGN KEY (BranchId) REFERENCES cfg.Branch(BranchId),
        CONSTRAINT FK_CallLog_Agent FOREIGN KEY (AgentId) REFERENCES crm.Agent(AgentId),
        CONSTRAINT FK_CallLog_Queue FOREIGN KEY (QueueId) REFERENCES crm.CallQueue(QueueId),
        CONSTRAINT FK_CallLog_Customer FOREIGN KEY (CustomerId) REFERENCES master.Customer(CustomerId),
        CONSTRAINT FK_CallLog_Lead FOREIGN KEY (LeadId) REFERENCES crm.Lead(LeadId),
        CONSTRAINT CK_CallLog_Direction CHECK (CallDirection IN ('INBOUND','OUTBOUND')),
        CONSTRAINT CK_CallLog_Result CHECK (Result IN ('ANSWERED','NO_ANSWER','BUSY','VOICEMAIL','CALLBACK','TRANSFERRED','DROPPED')),
        CONSTRAINT CK_CallLog_Score CHECK (SatisfactionScore IS NULL OR (SatisfactionScore >= 1 AND SatisfactionScore <= 5))
    );

    CREATE NONCLUSTERED INDEX IX_CallLog_CompanyDate ON crm.CallLog (CompanyId, CallStartTime DESC);
    CREATE NONCLUSTERED INDEX IX_CallLog_CustomerCode ON crm.CallLog (CompanyId, CustomerCode);
    CREATE NONCLUSTERED INDEX IX_CallLog_Agent ON crm.CallLog (AgentId, CallStartTime DESC);
END;
GO

-- ── 4. crm.CallScript ──────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'crm' AND t.name = 'CallScript')
BEGIN
    CREATE TABLE crm.CallScript (
        ScriptId          BIGINT         IDENTITY(1,1) NOT NULL,
        CompanyId         INT            NOT NULL,
        ScriptCode        NVARCHAR(20)   NOT NULL,
        ScriptName        NVARCHAR(200)  NOT NULL,
        QueueType         NVARCHAR(20)   NOT NULL,
        Content           NVARCHAR(MAX)  NOT NULL,
        Version           INT            NOT NULL DEFAULT 1,
        IsActive          BIT            NOT NULL DEFAULT 1,
        CreatedAt         DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt         DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId   INT            NULL,
        UpdatedByUserId   INT            NULL,
        IsDeleted         BIT            NOT NULL DEFAULT 0,
        DeletedAt         DATETIME2(0)   NULL,
        DeletedByUserId   INT            NULL,
        RowVer            ROWVERSION     NOT NULL,
        CONSTRAINT PK_CallScript PRIMARY KEY (ScriptId),
        CONSTRAINT FK_CallScript_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT UQ_CallScript_Code UNIQUE (CompanyId, ScriptCode)
    );
END;
GO

-- ── 5. crm.Campaign ────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'crm' AND t.name = 'Campaign')
BEGIN
    CREATE TABLE crm.Campaign (
        CampaignId        BIGINT         IDENTITY(1,1) NOT NULL,
        CompanyId         INT            NOT NULL,
        CampaignCode      NVARCHAR(20)   NOT NULL,
        CampaignName      NVARCHAR(200)  NOT NULL,
        CampaignType      NVARCHAR(30)   NOT NULL,  -- OUTBOUND_SALES/OUTBOUND_COLLECTION/OUTBOUND_SURVEY/OUTBOUND_FOLLOWUP
        QueueId           BIGINT         NULL,
        ScriptId          BIGINT         NULL,
        StartDate         DATE           NOT NULL,
        EndDate           DATE           NULL,
        TotalContacts     INT            NOT NULL DEFAULT 0,
        ContactedCount    INT            NOT NULL DEFAULT 0,
        SuccessCount      INT            NOT NULL DEFAULT 0,
        Status            NVARCHAR(20)   NOT NULL DEFAULT 'DRAFT',  -- DRAFT/ACTIVE/PAUSED/COMPLETED/CANCELLED
        Notes             NVARCHAR(MAX)  NULL,
        AssignedToUserId  INT            NULL,
        CreatedAt         DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt         DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId   INT            NULL,
        UpdatedByUserId   INT            NULL,
        IsDeleted         BIT            NOT NULL DEFAULT 0,
        DeletedAt         DATETIME2(0)   NULL,
        DeletedByUserId   INT            NULL,
        RowVer            ROWVERSION     NOT NULL,
        CONSTRAINT PK_Campaign PRIMARY KEY (CampaignId),
        CONSTRAINT FK_Campaign_Company FOREIGN KEY (CompanyId) REFERENCES cfg.Company(CompanyId),
        CONSTRAINT FK_Campaign_Queue FOREIGN KEY (QueueId) REFERENCES crm.CallQueue(QueueId),
        CONSTRAINT FK_Campaign_Script FOREIGN KEY (ScriptId) REFERENCES crm.CallScript(ScriptId),
        CONSTRAINT FK_Campaign_AssignedTo FOREIGN KEY (AssignedToUserId) REFERENCES sec.[User](UserId),
        CONSTRAINT UQ_Campaign_Code UNIQUE (CompanyId, CampaignCode),
        CONSTRAINT CK_Campaign_Type CHECK (CampaignType IN ('OUTBOUND_SALES','OUTBOUND_COLLECTION','OUTBOUND_SURVEY','OUTBOUND_FOLLOWUP')),
        CONSTRAINT CK_Campaign_Status CHECK (Status IN ('DRAFT','ACTIVE','PAUSED','COMPLETED','CANCELLED'))
    );
END;
GO

-- ── 6. crm.CampaignContact ─────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE s.name = 'crm' AND t.name = 'CampaignContact')
BEGIN
    CREATE TABLE crm.CampaignContact (
        CampaignContactId  BIGINT         IDENTITY(1,1) NOT NULL,
        CampaignId         BIGINT         NOT NULL,
        CustomerId         BIGINT         NULL,
        LeadId             BIGINT         NULL,
        ContactName        NVARCHAR(200)  NOT NULL,
        Phone              NVARCHAR(30)   NOT NULL,
        Email              NVARCHAR(150)  NULL,
        Status             NVARCHAR(20)   NOT NULL DEFAULT 'PENDING',  -- PENDING/CALLED/CALLBACK/COMPLETED/SKIPPED/DO_NOT_CALL
        Attempts           INT            NOT NULL DEFAULT 0,
        LastAttempt        DATETIME2(0)   NULL,
        LastResult         NVARCHAR(30)   NULL,
        CallbackDate       DATETIME2(0)   NULL,
        AssignedAgentId    BIGINT         NULL,
        Notes              NVARCHAR(MAX)  NULL,
        Priority           NVARCHAR(10)   NOT NULL DEFAULT 'MEDIUM',  -- LOW/MEDIUM/HIGH
        CreatedAt          DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt          DATETIME2(0)   NOT NULL DEFAULT SYSUTCDATETIME(),
        CreatedByUserId    INT            NULL,
        UpdatedByUserId    INT            NULL,
        IsDeleted          BIT            NOT NULL DEFAULT 0,
        DeletedAt          DATETIME2(0)   NULL,
        DeletedByUserId    INT            NULL,
        RowVer             ROWVERSION     NOT NULL,
        CONSTRAINT PK_CampaignContact PRIMARY KEY (CampaignContactId),
        CONSTRAINT FK_CampaignContact_Campaign FOREIGN KEY (CampaignId) REFERENCES crm.Campaign(CampaignId),
        CONSTRAINT FK_CampaignContact_Customer FOREIGN KEY (CustomerId) REFERENCES master.Customer(CustomerId),
        CONSTRAINT FK_CampaignContact_Lead FOREIGN KEY (LeadId) REFERENCES crm.Lead(LeadId),
        CONSTRAINT FK_CampaignContact_Agent FOREIGN KEY (AssignedAgentId) REFERENCES crm.Agent(AgentId),
        CONSTRAINT CK_CampaignContact_Status CHECK (Status IN ('PENDING','CALLED','CALLBACK','COMPLETED','SKIPPED','DO_NOT_CALL')),
        CONSTRAINT CK_CampaignContact_Priority CHECK (Priority IN ('LOW','MEDIUM','HIGH'))
    );

    CREATE NONCLUSTERED INDEX IX_CampaignContact_Status ON crm.CampaignContact (CampaignId, Status, Priority);
END;
GO


-- ═══════════════════════════════════════════════════════════════════════════════
--  STORED PROCEDURES
-- ═══════════════════════════════════════════════════════════════════════════════

-- =============================================================================
--  usp_CRM_CallQueue_List
--  Lista todas las colas de una empresa con conteo de agentes.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallQueue_List
    @CompanyId INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        q.QueueId,
        q.CompanyId,
        q.QueueCode,
        q.QueueName,
        q.QueueType,
        q.Description,
        q.IsActive,
        q.CreatedAt,
        q.UpdatedAt,
        (SELECT COUNT(*) FROM crm.Agent a WHERE a.QueueId = q.QueueId AND a.IsActive = 1 AND a.IsDeleted = 0) AS AgentCount
    FROM crm.CallQueue q
    WHERE q.CompanyId = @CompanyId
      AND q.IsDeleted = 0
    ORDER BY q.QueueName;
END;
GO

-- =============================================================================
--  usp_CRM_CallQueue_Upsert
--  Inserta o actualiza una cola.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallQueue_Upsert
    @CompanyId    INT,
    @QueueId      BIGINT        = NULL,
    @QueueCode    NVARCHAR(20),
    @QueueName    NVARCHAR(100),
    @QueueType    NVARCHAR(20)  = 'GENERAL',
    @Description  NVARCHAR(500) = NULL,
    @IsActive     BIT           = 1,
    @UserId       INT,
    @Resultado    INT           OUTPUT,
    @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF @QueueId IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM crm.CallQueue WHERE CompanyId = @CompanyId AND QueueCode = @QueueCode AND IsDeleted = 0)
            BEGIN
                SET @Mensaje = N'Ya existe una cola con el codigo ' + @QueueCode;
                RETURN;
            END;

            INSERT INTO crm.CallQueue (CompanyId, QueueCode, QueueName, QueueType, Description, IsActive, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@CompanyId, @QueueCode, @QueueName, @QueueType, @Description, @IsActive, @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());
        END
        ELSE
        BEGIN
            UPDATE crm.CallQueue
            SET    QueueCode       = @QueueCode,
                   QueueName       = @QueueName,
                   QueueType       = @QueueType,
                   Description     = @Description,
                   IsActive        = @IsActive,
                   UpdatedByUserId = @UserId,
                   UpdatedAt       = SYSUTCDATETIME()
            WHERE  QueueId = @QueueId AND CompanyId = @CompanyId AND IsDeleted = 0;
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
--  usp_CRM_Agent_List
--  Listado paginado de agentes con filtros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Agent_List
    @CompanyId  INT,
    @QueueId    BIGINT       = NULL,
    @Status     NVARCHAR(20) = NULL,
    @Page       INT          = 1,
    @Limit      INT          = 50,
    @TotalCount INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM crm.Agent a
    WHERE a.CompanyId = @CompanyId
      AND a.IsDeleted = 0
      AND (@QueueId IS NULL OR a.QueueId = @QueueId)
      AND (@Status IS NULL OR a.Status = @Status);

    SELECT
        a.AgentId,
        a.CompanyId,
        a.UserId,
        a.QueueId,
        a.AgentCode,
        a.AgentName,
        a.Extension,
        a.Status,
        a.MaxConcurrentCalls,
        a.IsActive,
        a.CreatedAt,
        a.UpdatedAt,
        q.QueueName
    FROM crm.Agent a
    LEFT JOIN crm.CallQueue q ON q.QueueId = a.QueueId
    WHERE a.CompanyId = @CompanyId
      AND a.IsDeleted = 0
      AND (@QueueId IS NULL OR a.QueueId = @QueueId)
      AND (@Status IS NULL OR a.Status = @Status)
    ORDER BY a.AgentName
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_CRM_Agent_Upsert
--  Inserta o actualiza un agente.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Agent_Upsert
    @CompanyId          INT,
    @AgentId            BIGINT        = NULL,
    @UserId_Agent       INT,
    @QueueId            BIGINT        = NULL,
    @AgentCode          NVARCHAR(20),
    @AgentName          NVARCHAR(200),
    @Extension          NVARCHAR(20)  = NULL,
    @MaxConcurrentCalls INT           = 1,
    @IsActive           BIT           = 1,
    @AdminUserId        INT,
    @Resultado          INT           OUTPUT,
    @Mensaje            NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF @AgentId IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM crm.Agent WHERE CompanyId = @CompanyId AND AgentCode = @AgentCode AND IsDeleted = 0)
            BEGIN
                SET @Mensaje = N'Ya existe un agente con el codigo ' + @AgentCode;
                RETURN;
            END;

            INSERT INTO crm.Agent (CompanyId, UserId, QueueId, AgentCode, AgentName, Extension, MaxConcurrentCalls, IsActive, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@CompanyId, @UserId_Agent, @QueueId, @AgentCode, @AgentName, @Extension, @MaxConcurrentCalls, @IsActive, @AdminUserId, @AdminUserId, SYSUTCDATETIME(), SYSUTCDATETIME());
        END
        ELSE
        BEGIN
            UPDATE crm.Agent
            SET    UserId               = @UserId_Agent,
                   QueueId              = @QueueId,
                   AgentCode            = @AgentCode,
                   AgentName            = @AgentName,
                   Extension            = @Extension,
                   MaxConcurrentCalls   = @MaxConcurrentCalls,
                   IsActive             = @IsActive,
                   UpdatedByUserId      = @AdminUserId,
                   UpdatedAt            = SYSUTCDATETIME()
            WHERE  AgentId = @AgentId AND CompanyId = @CompanyId AND IsDeleted = 0;
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
--  usp_CRM_Agent_UpdateStatus
--  Actualiza el estado de un agente.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Agent_UpdateStatus
    @AgentId    BIGINT,
    @Status     NVARCHAR(20),
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM crm.Agent WHERE AgentId = @AgentId AND IsDeleted = 0)
        BEGIN
            SET @Mensaje = N'Agente no encontrado';
            RETURN;
        END;

        UPDATE crm.Agent
        SET    Status    = @Status,
               UpdatedAt = SYSUTCDATETIME()
        WHERE  AgentId = @AgentId AND IsDeleted = 0;

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
--  usp_CRM_CallLog_List
--  Listado paginado de llamadas con filtros.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallLog_List
    @CompanyId     INT,
    @AgentId       BIGINT        = NULL,
    @QueueId       BIGINT        = NULL,
    @Direction     NVARCHAR(10)  = NULL,
    @Result        NVARCHAR(20)  = NULL,
    @CustomerCode  NVARCHAR(24)  = NULL,
    @FechaDesde    DATETIME2(0),
    @FechaHasta    DATETIME2(0),
    @Page          INT           = 1,
    @Limit         INT           = 50,
    @TotalCount    INT           OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM crm.CallLog c
    WHERE c.CompanyId = @CompanyId
      AND c.IsDeleted = 0
      AND c.CallStartTime >= @FechaDesde
      AND c.CallStartTime <= @FechaHasta
      AND (@AgentId IS NULL OR c.AgentId = @AgentId)
      AND (@QueueId IS NULL OR c.QueueId = @QueueId)
      AND (@Direction IS NULL OR c.CallDirection = @Direction)
      AND (@Result IS NULL OR c.Result = @Result)
      AND (@CustomerCode IS NULL OR c.CustomerCode = @CustomerCode);

    SELECT
        c.CallLogId,
        c.CompanyId,
        c.BranchId,
        c.AgentId,
        c.QueueId,
        c.CallDirection,
        c.CallerNumber,
        c.CalledNumber,
        c.CustomerCode,
        c.CustomerId,
        c.LeadId,
        c.ContactName,
        c.CallStartTime,
        c.CallEndTime,
        c.DurationSeconds,
        c.WaitSeconds,
        c.Result,
        c.Disposition,
        c.Notes,
        c.RecordingUrl,
        c.CallbackScheduled,
        c.Tags,
        c.SatisfactionScore,
        a.AgentName,
        q.QueueName
    FROM crm.CallLog c
    LEFT JOIN crm.Agent a ON a.AgentId = c.AgentId
    LEFT JOIN crm.CallQueue q ON q.QueueId = c.QueueId
    WHERE c.CompanyId = @CompanyId
      AND c.IsDeleted = 0
      AND c.CallStartTime >= @FechaDesde
      AND c.CallStartTime <= @FechaHasta
      AND (@AgentId IS NULL OR c.AgentId = @AgentId)
      AND (@QueueId IS NULL OR c.QueueId = @QueueId)
      AND (@Direction IS NULL OR c.CallDirection = @Direction)
      AND (@Result IS NULL OR c.Result = @Result)
      AND (@CustomerCode IS NULL OR c.CustomerCode = @CustomerCode)
    ORDER BY c.CallStartTime DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_CRM_CallLog_Get
--  Obtiene detalle de una llamada.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallLog_Get
    @CallLogId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.CallLogId,
        c.CompanyId,
        c.BranchId,
        c.AgentId,
        c.QueueId,
        c.CallDirection,
        c.CallerNumber,
        c.CalledNumber,
        c.CustomerCode,
        c.CustomerId,
        c.LeadId,
        c.ContactName,
        c.CallStartTime,
        c.CallEndTime,
        c.DurationSeconds,
        c.WaitSeconds,
        c.Result,
        c.Disposition,
        c.Notes,
        c.RecordingUrl,
        c.CallbackScheduled,
        c.RelatedDocumentType,
        c.RelatedDocumentNumber,
        c.Tags,
        c.SatisfactionScore,
        c.CreatedAt,
        a.AgentName,
        q.QueueName
    FROM crm.CallLog c
    LEFT JOIN crm.Agent a ON a.AgentId = c.AgentId
    LEFT JOIN crm.CallQueue q ON q.QueueId = c.QueueId
    WHERE c.CallLogId = @CallLogId
      AND c.IsDeleted = 0;
END;
GO

-- =============================================================================
--  usp_CRM_CallLog_Create
--  Crea un registro de llamada.
--  Si no hay LeadId ni CustomerCode y CallerNumber tiene valor, crea un Lead.
--  Tambien crea una Activity de tipo CALL vinculada al lead o cliente.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallLog_Create
    @CompanyId              INT,
    @BranchId               INT,
    @AgentId                BIGINT         = NULL,
    @QueueId                BIGINT         = NULL,
    @CallDirection          NVARCHAR(10),
    @CallerNumber           NVARCHAR(30),
    @CalledNumber           NVARCHAR(30),
    @CustomerCode           NVARCHAR(24)   = NULL,
    @CustomerId             BIGINT         = NULL,
    @LeadId                 BIGINT         = NULL,
    @ContactName            NVARCHAR(200)  = NULL,
    @CallStartTime          DATETIME2(0),
    @CallEndTime            DATETIME2(0)   = NULL,
    @DurationSeconds        INT            = NULL,
    @WaitSeconds            INT            = NULL,
    @Result                 NVARCHAR(20),
    @Disposition            NVARCHAR(30)   = NULL,
    @Notes                  NVARCHAR(MAX)  = NULL,
    @RecordingUrl           NVARCHAR(500)  = NULL,
    @CallbackScheduled      DATETIME2(0)   = NULL,
    @RelatedDocumentType    NVARCHAR(30)   = NULL,
    @RelatedDocumentNumber  NVARCHAR(60)   = NULL,
    @Tags                   NVARCHAR(500)  = NULL,
    @SatisfactionScore      INT            = NULL,
    @UserId                 INT,
    @Resultado              INT            OUTPUT,
    @Mensaje                NVARCHAR(500)  OUTPUT,
    @CallLogId              BIGINT         OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @CallLogId = 0;

    BEGIN TRY
        DECLARE @NewLeadId BIGINT = @LeadId;

        -- Auto-crear Lead si no hay LeadId ni CustomerCode y hay CallerNumber
        IF @NewLeadId IS NULL AND (@CustomerCode IS NULL OR @CustomerCode = '') AND @CallerNumber <> ''
        BEGIN
            DECLARE @DefaultPipelineId INT;
            DECLARE @DefaultStageId INT;

            SELECT TOP 1 @DefaultPipelineId = PipelineId
            FROM crm.Pipeline
            WHERE CompanyId = @CompanyId AND IsDefault = 1 AND IsActive = 1;

            IF @DefaultPipelineId IS NOT NULL
            BEGIN
                SELECT TOP 1 @DefaultStageId = StageId
                FROM crm.PipelineStage
                WHERE PipelineId = @DefaultPipelineId AND IsActive = 1
                ORDER BY StageOrder;

                IF @DefaultStageId IS NOT NULL
                BEGIN
                    -- Generar LeadCode
                    DECLARE @LeadSeq INT;
                    SELECT @LeadSeq = ISNULL(MAX(CAST(REPLACE(LeadCode, 'LEAD-', '') AS INT)), 0) + 1
                    FROM crm.Lead WHERE CompanyId = @CompanyId AND LeadCode LIKE 'LEAD-%';

                    DECLARE @LeadCode NVARCHAR(30) = 'LEAD-' + RIGHT('000000' + CAST(@LeadSeq AS NVARCHAR), 6);

                    INSERT INTO crm.Lead (CompanyId, BranchId, PipelineId, StageId, LeadCode, ContactName, Phone, Source, Status, Priority, EstimatedValue, CurrencyCode, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
                    VALUES (@CompanyId, @BranchId, @DefaultPipelineId, @DefaultStageId, @LeadCode,
                            ISNULL(@ContactName, N'Llamada ' + @CallerNumber),
                            @CallerNumber, 'CALL_CENTER', 'NEW', 'MEDIUM', 0, 'USD',
                            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());

                    SET @NewLeadId = SCOPE_IDENTITY();
                END;
            END;
        END;

        -- Insertar CallLog
        INSERT INTO crm.CallLog (
            CompanyId, BranchId, AgentId, QueueId, CallDirection,
            CallerNumber, CalledNumber, CustomerCode, CustomerId, LeadId, ContactName,
            CallStartTime, CallEndTime, DurationSeconds, WaitSeconds,
            Result, Disposition, Notes, RecordingUrl, CallbackScheduled,
            RelatedDocumentType, RelatedDocumentNumber, Tags, SatisfactionScore,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        )
        VALUES (
            @CompanyId, @BranchId, @AgentId, @QueueId, @CallDirection,
            @CallerNumber, @CalledNumber, @CustomerCode, @CustomerId, @NewLeadId, @ContactName,
            @CallStartTime, @CallEndTime, @DurationSeconds, @WaitSeconds,
            @Result, @Disposition, @Notes, @RecordingUrl, @CallbackScheduled,
            @RelatedDocumentType, @RelatedDocumentNumber, @Tags, @SatisfactionScore,
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @CallLogId = SCOPE_IDENTITY();

        -- Crear Activity de tipo CALL
        DECLARE @ActivitySubject NVARCHAR(200) = @CallDirection + N' - ' + ISNULL(@ContactName, @CallerNumber) + N' (' + @Result + N')';

        INSERT INTO crm.Activity (
            CompanyId, LeadId, CustomerId, ActivityType, Subject,
            Description, IsCompleted, CompletedAt,
            AssignedToUserId, Priority,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        )
        VALUES (
            @CompanyId, @NewLeadId, @CustomerId, 'CALL', @ActivitySubject,
            @Notes, 1, SYSUTCDATETIME(),
            @UserId, 'MEDIUM',
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

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
--  usp_CRM_CallScript_List
--  Lista scripts de llamada, opcionalmente filtrado por tipo de cola.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallScript_List
    @CompanyId  INT,
    @QueueType  NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.ScriptId,
        s.CompanyId,
        s.ScriptCode,
        s.ScriptName,
        s.QueueType,
        s.Content,
        s.Version,
        s.IsActive,
        s.CreatedAt,
        s.UpdatedAt
    FROM crm.CallScript s
    WHERE s.CompanyId = @CompanyId
      AND s.IsDeleted = 0
      AND (@QueueType IS NULL OR s.QueueType = @QueueType)
    ORDER BY s.ScriptName;
END;
GO

-- =============================================================================
--  usp_CRM_CallScript_Upsert
--  Inserta o actualiza un script de llamada.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallScript_Upsert
    @CompanyId   INT,
    @ScriptId    BIGINT         = NULL,
    @ScriptCode  NVARCHAR(20),
    @ScriptName  NVARCHAR(200),
    @QueueType   NVARCHAR(20),
    @Content     NVARCHAR(MAX),
    @IsActive    BIT            = 1,
    @UserId      INT,
    @Resultado   INT            OUTPUT,
    @Mensaje     NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF @ScriptId IS NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM crm.CallScript WHERE CompanyId = @CompanyId AND ScriptCode = @ScriptCode AND IsDeleted = 0)
            BEGIN
                SET @Mensaje = N'Ya existe un script con el codigo ' + @ScriptCode;
                RETURN;
            END;

            INSERT INTO crm.CallScript (CompanyId, ScriptCode, ScriptName, QueueType, Content, IsActive, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            VALUES (@CompanyId, @ScriptCode, @ScriptName, @QueueType, @Content, @IsActive, @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME());
        END
        ELSE
        BEGIN
            UPDATE crm.CallScript
            SET    ScriptCode      = @ScriptCode,
                   ScriptName      = @ScriptName,
                   QueueType       = @QueueType,
                   Content         = @Content,
                   Version         = Version + 1,
                   IsActive        = @IsActive,
                   UpdatedByUserId = @UserId,
                   UpdatedAt       = SYSUTCDATETIME()
            WHERE  ScriptId = @ScriptId AND CompanyId = @CompanyId AND IsDeleted = 0;
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
--  usp_CRM_Campaign_List
--  Listado paginado de campanas con filtro de estado.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Campaign_List
    @CompanyId  INT,
    @Status     NVARCHAR(20) = NULL,
    @Page       INT          = 1,
    @Limit      INT          = 50,
    @TotalCount INT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @TotalCount = COUNT(*)
    FROM crm.Campaign c
    WHERE c.CompanyId = @CompanyId
      AND c.IsDeleted = 0
      AND (@Status IS NULL OR c.Status = @Status);

    SELECT
        c.CampaignId,
        c.CompanyId,
        c.CampaignCode,
        c.CampaignName,
        c.CampaignType,
        c.QueueId,
        c.ScriptId,
        c.StartDate,
        c.EndDate,
        c.TotalContacts,
        c.ContactedCount,
        c.SuccessCount,
        c.Status,
        c.Notes,
        c.AssignedToUserId,
        c.CreatedAt,
        c.UpdatedAt,
        q.QueueName
    FROM crm.Campaign c
    LEFT JOIN crm.CallQueue q ON q.QueueId = c.QueueId
    WHERE c.CompanyId = @CompanyId
      AND c.IsDeleted = 0
      AND (@Status IS NULL OR c.Status = @Status)
    ORDER BY c.CreatedAt DESC
    OFFSET (@Page - 1) * @Limit ROWS FETCH NEXT @Limit ROWS ONLY;
END;
GO

-- =============================================================================
--  usp_CRM_Campaign_Get
--  Obtiene cabecera de campana con resumen de contactos.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Campaign_Get
    @CampaignId BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Cabecera
    SELECT
        c.CampaignId,
        c.CompanyId,
        c.CampaignCode,
        c.CampaignName,
        c.CampaignType,
        c.QueueId,
        c.ScriptId,
        c.StartDate,
        c.EndDate,
        c.TotalContacts,
        c.ContactedCount,
        c.SuccessCount,
        c.Status,
        c.Notes,
        c.AssignedToUserId,
        c.CreatedAt,
        c.UpdatedAt,
        q.QueueName,
        s.ScriptName,
        (SELECT COUNT(*) FROM crm.CampaignContact cc WHERE cc.CampaignId = c.CampaignId AND cc.Status = 'PENDING' AND cc.IsDeleted = 0) AS PendingCount,
        (SELECT COUNT(*) FROM crm.CampaignContact cc WHERE cc.CampaignId = c.CampaignId AND cc.Status = 'CALLBACK' AND cc.IsDeleted = 0) AS CallbackCount
    FROM crm.Campaign c
    LEFT JOIN crm.CallQueue q ON q.QueueId = c.QueueId
    LEFT JOIN crm.CallScript s ON s.ScriptId = c.ScriptId
    WHERE c.CampaignId = @CampaignId
      AND c.IsDeleted = 0;
END;
GO

-- =============================================================================
--  usp_CRM_Campaign_Create
--  Crea una campana con sus contactos via JSON.
--  ContactsJson: [{"customerId":1,"leadId":null,"contactName":"...","phone":"...","email":"...","priority":"HIGH"},...]
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Campaign_Create
    @CompanyId        INT,
    @CampaignCode     NVARCHAR(20),
    @CampaignName     NVARCHAR(200),
    @CampaignType     NVARCHAR(30),
    @QueueId          BIGINT          = NULL,
    @ScriptId         BIGINT          = NULL,
    @StartDate        DATE,
    @EndDate          DATE            = NULL,
    @AssignedToUserId INT             = NULL,
    @Notes            NVARCHAR(MAX)   = NULL,
    @ContactsJson     NVARCHAR(MAX)   = NULL,
    @UserId           INT,
    @Resultado        INT             OUTPUT,
    @Mensaje          NVARCHAR(500)   OUTPUT,
    @CampaignId       BIGINT          OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;
    SET @CampaignId = 0;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM crm.Campaign WHERE CompanyId = @CompanyId AND CampaignCode = @CampaignCode AND IsDeleted = 0)
        BEGIN
            SET @Mensaje = N'Ya existe una campana con el codigo ' + @CampaignCode;
            RETURN;
        END;

        DECLARE @ContactCount INT = 0;
        IF @ContactsJson IS NOT NULL AND @ContactsJson <> ''
            SELECT @ContactCount = COUNT(*) FROM OPENJSON(@ContactsJson);

        INSERT INTO crm.Campaign (
            CompanyId, CampaignCode, CampaignName, CampaignType,
            QueueId, ScriptId, StartDate, EndDate,
            TotalContacts, Status, Notes, AssignedToUserId,
            CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt
        )
        VALUES (
            @CompanyId, @CampaignCode, @CampaignName, @CampaignType,
            @QueueId, @ScriptId, @StartDate, @EndDate,
            @ContactCount, 'DRAFT', @Notes, @AssignedToUserId,
            @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
        );

        SET @CampaignId = SCOPE_IDENTITY();

        -- Insertar contactos
        IF @ContactsJson IS NOT NULL AND @ContactsJson <> ''
        BEGIN
            INSERT INTO crm.CampaignContact (CampaignId, CustomerId, LeadId, ContactName, Phone, Email, Priority, CreatedByUserId, UpdatedByUserId, CreatedAt, UpdatedAt)
            SELECT
                @CampaignId,
                JSON_VALUE(j.[value], '$.customerId'),
                JSON_VALUE(j.[value], '$.leadId'),
                JSON_VALUE(j.[value], '$.contactName'),
                JSON_VALUE(j.[value], '$.phone'),
                JSON_VALUE(j.[value], '$.email'),
                ISNULL(JSON_VALUE(j.[value], '$.priority'), 'MEDIUM'),
                @UserId, @UserId, SYSUTCDATETIME(), SYSUTCDATETIME()
            FROM OPENJSON(@ContactsJson) j;
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
--  usp_CRM_Campaign_UpdateStatus
--  Actualiza el estado de una campana.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Campaign_UpdateStatus
    @CampaignId BIGINT,
    @Status     NVARCHAR(20),
    @UserId     INT,
    @Resultado  INT           OUTPUT,
    @Mensaje    NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM crm.Campaign WHERE CampaignId = @CampaignId AND IsDeleted = 0)
        BEGIN
            SET @Mensaje = N'Campana no encontrada';
            RETURN;
        END;

        UPDATE crm.Campaign
        SET    Status          = @Status,
               UpdatedByUserId = @UserId,
               UpdatedAt       = SYSUTCDATETIME()
        WHERE  CampaignId = @CampaignId AND IsDeleted = 0;

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
--  usp_CRM_Campaign_GetNextContact
--  Obtiene el siguiente contacto pendiente de una campana para un agente.
--  Orden: priority (HIGH>MEDIUM>LOW), callbacks vencidos primero, luego pendientes.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Campaign_GetNextContact
    @CampaignId BIGINT,
    @AgentId    BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1
        cc.CampaignContactId,
        cc.CampaignId,
        cc.CustomerId,
        cc.LeadId,
        cc.ContactName,
        cc.Phone,
        cc.Email,
        cc.Status,
        cc.Attempts,
        cc.LastAttempt,
        cc.LastResult,
        cc.CallbackDate,
        cc.AssignedAgentId,
        cc.Notes,
        cc.Priority
    FROM crm.CampaignContact cc
    WHERE cc.CampaignId = @CampaignId
      AND cc.IsDeleted = 0
      AND (cc.AssignedAgentId IS NULL OR cc.AssignedAgentId = @AgentId)
      AND cc.Status IN ('PENDING', 'CALLBACK')
      AND (cc.Status = 'CALLBACK' AND cc.CallbackDate <= SYSUTCDATETIME()
           OR cc.Status = 'PENDING')
    ORDER BY
        CASE cc.Status WHEN 'CALLBACK' THEN 0 ELSE 1 END,
        CASE cc.Priority WHEN 'HIGH' THEN 0 WHEN 'MEDIUM' THEN 1 ELSE 2 END,
        cc.CallbackDate,
        cc.CampaignContactId;
END;
GO

-- =============================================================================
--  usp_CRM_Campaign_LogAttempt
--  Registra un intento de contacto en una campana.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_Campaign_LogAttempt
    @CampaignContactId BIGINT,
    @Result            NVARCHAR(30),
    @CallbackDate      DATETIME2(0)   = NULL,
    @Notes             NVARCHAR(MAX)  = NULL,
    @UserId            INT,
    @Resultado         INT            OUTPUT,
    @Mensaje           NVARCHAR(500)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Resultado = 0;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM crm.CampaignContact WHERE CampaignContactId = @CampaignContactId AND IsDeleted = 0)
        BEGIN
            SET @Mensaje = N'Contacto de campana no encontrado';
            RETURN;
        END;

        DECLARE @NewStatus NVARCHAR(20);
        SET @NewStatus = CASE
            WHEN @CallbackDate IS NOT NULL THEN 'CALLBACK'
            WHEN @Result IN ('ANSWERED', 'SALE', 'APPOINTMENT', 'COLLECTION_PROMISE') THEN 'COMPLETED'
            WHEN @Result IN ('DO_NOT_CALL', 'WRONG_NUMBER') THEN 'DO_NOT_CALL'
            ELSE 'CALLED'
        END;

        UPDATE crm.CampaignContact
        SET    Attempts       = Attempts + 1,
               LastAttempt    = SYSUTCDATETIME(),
               LastResult     = @Result,
               Status         = @NewStatus,
               CallbackDate   = @CallbackDate,
               Notes          = ISNULL(@Notes, Notes),
               UpdatedByUserId = @UserId,
               UpdatedAt      = SYSUTCDATETIME()
        WHERE  CampaignContactId = @CampaignContactId AND IsDeleted = 0;

        -- Actualizar contadores de campana
        DECLARE @CampId BIGINT;
        SELECT @CampId = CampaignId FROM crm.CampaignContact WHERE CampaignContactId = @CampaignContactId;

        UPDATE crm.Campaign
        SET    ContactedCount = (SELECT COUNT(*) FROM crm.CampaignContact WHERE CampaignId = @CampId AND Status NOT IN ('PENDING') AND IsDeleted = 0),
               SuccessCount   = (SELECT COUNT(*) FROM crm.CampaignContact WHERE CampaignId = @CampId AND Status = 'COMPLETED' AND IsDeleted = 0),
               UpdatedAt      = SYSUTCDATETIME()
        WHERE  CampaignId = @CampId;

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
--  usp_CRM_CallCenter_Dashboard
--  KPIs del call center para un periodo de tiempo.
-- =============================================================================
CREATE OR ALTER PROCEDURE dbo.usp_CRM_CallCenter_Dashboard
    @CompanyId   INT,
    @FechaDesde  DATETIME2(0),
    @FechaHasta  DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;

    -- Metricas generales
    SELECT
        COUNT(*)                                                           AS TotalCalls,
        SUM(CASE WHEN Result = 'ANSWERED' THEN 1 ELSE 0 END)              AS AnsweredCalls,
        AVG(DurationSeconds)                                               AS AvgDurationSeconds,
        AVG(WaitSeconds)                                                   AS AvgWaitSeconds
    FROM crm.CallLog
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND CallStartTime >= @FechaDesde
      AND CallStartTime <= @FechaHasta;

    -- Llamadas por resultado
    SELECT
        Result,
        COUNT(*) AS CallCount
    FROM crm.CallLog
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND CallStartTime >= @FechaDesde
      AND CallStartTime <= @FechaHasta
    GROUP BY Result
    ORDER BY CallCount DESC;

    -- Top agentes
    SELECT TOP 10
        a.AgentId,
        a.AgentName,
        COUNT(*)                                                           AS TotalCalls,
        SUM(CASE WHEN c.Result = 'ANSWERED' THEN 1 ELSE 0 END)            AS AnsweredCalls,
        AVG(c.DurationSeconds)                                             AS AvgDuration
    FROM crm.CallLog c
    INNER JOIN crm.Agent a ON a.AgentId = c.AgentId
    WHERE c.CompanyId = @CompanyId
      AND c.IsDeleted = 0
      AND c.CallStartTime >= @FechaDesde
      AND c.CallStartTime <= @FechaHasta
    GROUP BY a.AgentId, a.AgentName
    ORDER BY TotalCalls DESC;

    -- Campanas activas
    SELECT
        COUNT(*) AS ActiveCampaigns
    FROM crm.Campaign
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND Status = 'ACTIVE';

    -- Callbacks pendientes
    SELECT
        COUNT(*) AS CallbacksPending
    FROM crm.CallLog
    WHERE CompanyId = @CompanyId
      AND IsDeleted = 0
      AND CallbackScheduled IS NOT NULL
      AND CallbackScheduled >= SYSUTCDATETIME()
      AND Result = 'CALLBACK';
END;
GO
