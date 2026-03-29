-- ============================================================
-- Tablas y SPs de Billing/Subscription (SaaS via Paddle)
-- Schema: sys
-- ============================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='sys' AND TABLE_NAME='BillingEvent')
BEGIN
  CREATE TABLE sys.BillingEvent (
    BillingEventId    INT IDENTITY(1,1) PRIMARY KEY,
    CompanyId         INT NULL,
    EventType         NVARCHAR(80) NOT NULL,
    PaddleEventId     NVARCHAR(100) NULL,
    Payload           NVARCHAR(MAX) NULL,
    CreatedAt         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_BillingEvent_Company ON sys.BillingEvent(CompanyId, CreatedAt);
END
GO

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='sys' AND TABLE_NAME='Subscription')
BEGIN
  CREATE TABLE sys.[Subscription] (
    SubscriptionId        INT IDENTITY(1,1) PRIMARY KEY,
    CompanyId             INT NULL,
    PaddleSubscriptionId  NVARCHAR(100) NOT NULL UNIQUE,
    PaddleCustomerId      NVARCHAR(100) NULL,
    PriceId               NVARCHAR(100) NULL,
    PlanName              NVARCHAR(100) NULL,
    [Status]              NVARCHAR(30) NOT NULL DEFAULT 'active',
    CurrentPeriodStart    DATETIME2 NULL,
    CurrentPeriodEnd      DATETIME2 NULL,
    CancelledAt           DATETIME2 NULL,
    TenantSubdomain       NVARCHAR(63) NULL,
    CreatedAt             DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt             DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
  );
  CREATE INDEX IX_Subscription_Company ON sys.[Subscription](CompanyId);
END
GO

-- ============================================================
-- usp_sys_BillingEvent_Insert
-- ============================================================
CREATE OR ALTER PROCEDURE usp_sys_BillingEvent_Insert
  @CompanyId       INT            = NULL,
  @EventType       NVARCHAR(80)   = N'',
  @PaddleEventId   NVARCHAR(100)  = NULL,
  @Payload         NVARCHAR(MAX)  = NULL,
  @Resultado       INT            = 0 OUTPUT,
  @Mensaje         NVARCHAR(500)  = N'' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Id INT;

  INSERT INTO sys.BillingEvent (CompanyId, EventType, PaddleEventId, Payload)
  VALUES (@CompanyId, @EventType, @PaddleEventId, @Payload);

  SET @Id = SCOPE_IDENTITY();
  SET @Resultado = 1;
  SET @Mensaje = N'BILLING_EVENT_INSERTED:' + CAST(@Id AS NVARCHAR);
END
GO

-- ============================================================
-- usp_sys_Subscription_Upsert
-- ============================================================
CREATE OR ALTER PROCEDURE usp_sys_Subscription_Upsert
  @CompanyId              INT            = NULL,
  @PaddleSubscriptionId   NVARCHAR(100)  = NULL,
  @PaddleCustomerId       NVARCHAR(100)  = NULL,
  @PriceId                NVARCHAR(100)  = NULL,
  @PlanName               NVARCHAR(100)  = NULL,
  @Status                 NVARCHAR(30)   = N'active',
  @CurrentPeriodStart     NVARCHAR(50)   = NULL,
  @CurrentPeriodEnd       NVARCHAR(50)   = NULL,
  @CancelledAt            NVARCHAR(50)   = NULL,
  @Resultado              INT            = 0 OUTPUT,
  @Mensaje                NVARCHAR(500)  = N'' OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF @PaddleSubscriptionId IS NULL
  BEGIN
    SET @Resultado = 0;
    SET @Mensaje = N'PADDLE_SUBSCRIPTION_ID_REQUIRED';
    RETURN;
  END;

  MERGE sys.[Subscription] AS t
  USING (SELECT @PaddleSubscriptionId AS PaddleSubscriptionId) AS s
  ON t.PaddleSubscriptionId = s.PaddleSubscriptionId
  WHEN MATCHED THEN UPDATE SET
    PriceId            = COALESCE(@PriceId, t.PriceId),
    PlanName           = COALESCE(@PlanName, t.PlanName),
    [Status]           = COALESCE(@Status, t.[Status]),
    CurrentPeriodStart = CASE WHEN @CurrentPeriodStart IS NOT NULL
                              THEN TRY_CAST(@CurrentPeriodStart AS DATETIME2)
                              ELSE t.CurrentPeriodStart END,
    CurrentPeriodEnd   = CASE WHEN @CurrentPeriodEnd IS NOT NULL
                              THEN TRY_CAST(@CurrentPeriodEnd AS DATETIME2)
                              ELSE t.CurrentPeriodEnd END,
    CancelledAt        = CASE WHEN @CancelledAt IS NOT NULL
                              THEN TRY_CAST(@CancelledAt AS DATETIME2)
                              ELSE t.CancelledAt END,
    CompanyId          = COALESCE(@CompanyId, t.CompanyId),
    PaddleCustomerId   = COALESCE(@PaddleCustomerId, t.PaddleCustomerId),
    UpdatedAt          = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN INSERT (
    CompanyId, PaddleSubscriptionId, PaddleCustomerId,
    PriceId, PlanName, [Status],
    CurrentPeriodStart, CurrentPeriodEnd, CancelledAt
  ) VALUES (
    @CompanyId, @PaddleSubscriptionId, @PaddleCustomerId,
    @PriceId, @PlanName, COALESCE(@Status, 'active'),
    TRY_CAST(@CurrentPeriodStart AS DATETIME2),
    TRY_CAST(@CurrentPeriodEnd AS DATETIME2),
    TRY_CAST(@CancelledAt AS DATETIME2)
  );

  SET @Resultado = 1;
  SET @Mensaje = N'SUBSCRIPTION_UPSERTED';
END
GO

-- ============================================================
-- usp_sys_Subscription_GetByCompany
-- ============================================================
CREATE OR ALTER PROCEDURE usp_sys_Subscription_GetByCompany
  @CompanyId INT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  SELECT TOP 1
    SubscriptionId, CompanyId,
    PaddleSubscriptionId, PaddleCustomerId,
    PriceId, PlanName, [Status],
    CurrentPeriodStart, CurrentPeriodEnd,
    CancelledAt, TenantSubdomain, CreatedAt
  FROM sys.[Subscription]
  WHERE CompanyId = @CompanyId
  ORDER BY CreatedAt DESC;
END
GO
