-- ============================================================================
--  Logistics Analytics — Dashboard Enterprise
--  SQL Server stored procedures for charts and analytics
-- ============================================================================

-- ============================================================================
--  usp_Logistics_Analytics_ReceiptsByMonth
--  Recepciones por mes (ultimos 6 meses)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Analytics_ReceiptsByMonth', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Logistics_Analytics_ReceiptsByMonth;
GO
CREATE PROCEDURE dbo.usp_Logistics_Analytics_ReceiptsByMonth
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH months AS (
        SELECT DATEADD(MONTH, -n, DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE))) AS month_start
        FROM (VALUES (0),(1),(2),(3),(4),(5)) AS t(n)
    )
    SELECT
        FORMAT(m.month_start, 'yyyy-MM')     AS [Month],
        FORMAT(m.month_start, 'MMM yyyy')    AS [MonthLabel],
        ISNULL(COUNT(gr.GoodsReceiptId), 0)  AS [Total]
    FROM months m
    LEFT JOIN logistics.GoodsReceipt gr
        ON gr.CompanyId = @CompanyId
        AND gr.BranchId = @BranchId
        AND gr.IsDeleted = 0
        AND DATEADD(DAY, 1 - DAY(gr.ReceiptDate), CAST(gr.ReceiptDate AS DATE)) = m.month_start
    GROUP BY m.month_start
    ORDER BY m.month_start;
END;
GO

-- ============================================================================
--  usp_Logistics_Analytics_DeliveryByStatus
--  Albaranes por estado (para grafico de dona)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Analytics_DeliveryByStatus', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Logistics_Analytics_DeliveryByStatus;
GO
CREATE PROCEDURE dbo.usp_Logistics_Analytics_DeliveryByStatus
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        dn.[Status]                          AS [Status],
        CASE dn.[Status]
            WHEN 'DRAFT' THEN N'Borrador'
            WHEN 'CONFIRMED' THEN N'Confirmado'
            WHEN 'PICKING' THEN N'En Picking'
            WHEN 'PACKED' THEN N'Empacado'
            WHEN 'DISPATCHED' THEN N'Despachado'
            WHEN 'DELIVERED' THEN N'Entregado'
            WHEN 'VOIDED' THEN N'Anulado'
            ELSE dn.[Status]
        END                                  AS [StatusLabel],
        COUNT(*)                             AS [Count]
    FROM logistics.DeliveryNote dn
    WHERE dn.CompanyId = @CompanyId
      AND dn.BranchId = @BranchId
      AND dn.IsDeleted = 0
    GROUP BY dn.[Status]
    ORDER BY [Count] DESC;
END;
GO

-- ============================================================================
--  usp_Logistics_Analytics_RecentActivity
--  Ultimos 10 movimientos (recepciones + despachos)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Analytics_RecentActivity', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Logistics_Analytics_RecentActivity;
GO
CREATE PROCEDURE dbo.usp_Logistics_Analytics_RecentActivity
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 10 *
    FROM (
        SELECT TOP 10
            gr.GoodsReceiptId                AS ActivityId,
            'RECEIPT'                        AS ActivityType,
            gr.ReceiptNumber                 AS DocNumber,
            ISNULL(s.SupplierName, '')       AS EntityName,
            gr.ReceiptDate                   AS ActivityDate,
            gr.[Status]                      AS [Status],
            CASE gr.[Status]
                WHEN 'DRAFT' THEN N'Borrador'
                WHEN 'PARTIAL' THEN N'Parcial'
                WHEN 'COMPLETE' THEN N'Completa'
                WHEN 'VOIDED' THEN N'Anulada'
                ELSE gr.[Status]
            END                              AS StatusLabel
        FROM logistics.GoodsReceipt gr
        LEFT JOIN master.Supplier s ON s.SupplierId = gr.SupplierId
        WHERE gr.CompanyId = @CompanyId AND gr.BranchId = @BranchId AND gr.IsDeleted = 0
        ORDER BY gr.ReceiptDate DESC

        UNION ALL

        SELECT TOP 10
            dn.DeliveryNoteId                AS ActivityId,
            'DELIVERY'                       AS ActivityType,
            dn.DeliveryNumber                AS DocNumber,
            ISNULL(c.CustomerName, '')       AS EntityName,
            dn.DeliveryDate                  AS ActivityDate,
            dn.[Status]                      AS [Status],
            CASE dn.[Status]
                WHEN 'DRAFT' THEN N'Borrador'
                WHEN 'CONFIRMED' THEN N'Confirmado'
                WHEN 'PICKING' THEN N'En Picking'
                WHEN 'PACKED' THEN N'Empacado'
                WHEN 'DISPATCHED' THEN N'Despachado'
                WHEN 'DELIVERED' THEN N'Entregado'
                WHEN 'VOIDED' THEN N'Anulado'
                ELSE dn.[Status]
            END                              AS StatusLabel
        FROM logistics.DeliveryNote dn
        LEFT JOIN master.Customer c ON c.CustomerId = dn.CustomerId
        WHERE dn.CompanyId = @CompanyId AND dn.BranchId = @BranchId AND dn.IsDeleted = 0
        ORDER BY dn.DeliveryDate DESC
    ) AS combined
    ORDER BY ActivityDate DESC;
END;
GO

-- ============================================================================
--  usp_Logistics_Analytics_TrendCards
--  Recepciones este mes vs anterior (% cambio)
-- ============================================================================
IF OBJECT_ID('dbo.usp_Logistics_Analytics_TrendCards', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_Logistics_Analytics_TrendCards;
GO
CREATE PROCEDURE dbo.usp_Logistics_Analytics_TrendCards
    @CompanyId INT,
    @BranchId  INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ThisStart DATE = DATEADD(DAY, 1 - DAY(SYSUTCDATETIME()), CAST(SYSUTCDATETIME() AS DATE));
    DECLARE @LastStart DATE = DATEADD(MONTH, -1, @ThisStart);

    SELECT
        (SELECT COUNT(*) FROM logistics.GoodsReceipt
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND IsDeleted = 0
           AND ReceiptDate >= @ThisStart) AS ReceiptsThisMonth,

        (SELECT COUNT(*) FROM logistics.GoodsReceipt
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND IsDeleted = 0
           AND ReceiptDate >= @LastStart AND ReceiptDate < @ThisStart) AS ReceiptsLastMonth,

        (SELECT COUNT(*) FROM logistics.DeliveryNote
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND IsDeleted = 0
           AND DeliveryDate >= @ThisStart) AS DeliveriesThisMonth,

        (SELECT COUNT(*) FROM logistics.DeliveryNote
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND IsDeleted = 0
           AND DeliveryDate >= @LastStart AND DeliveryDate < @ThisStart) AS DeliveriesLastMonth,

        (SELECT COUNT(*) FROM logistics.GoodsReturn
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND IsDeleted = 0
           AND ReturnDate >= @ThisStart) AS ReturnsThisMonth,

        (SELECT COUNT(*) FROM logistics.GoodsReturn
         WHERE CompanyId = @CompanyId AND BranchId = @BranchId AND IsDeleted = 0
           AND ReturnDate >= @LastStart AND ReturnDate < @ThisStart) AS ReturnsLastMonth;
END;
GO
