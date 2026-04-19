-- ============================================================
-- Patch 06: inv schema — Conteo físico + Albaranes + Traslados multi-paso
-- SQL Server 2012+ compatible
-- Equivalent of migration 00135_inv_conteo_fisico_albaranes.sql (PG)
-- ============================================================
USE zentto_dev;
GO

-- ── HojaConteo ────────────────────────────────────────────────────────────────
IF OBJECT_ID('inv.HojaConteo', 'U') IS NULL
CREATE TABLE inv.HojaConteo (
    HojaConteoId     INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_inv_HojaConteo PRIMARY KEY,
    CompanyId        INT           NOT NULL,
    WarehouseCode    NVARCHAR(20)  NOT NULL,
    Numero           NVARCHAR(30)  NOT NULL,
    Estado           NVARCHAR(20)  NOT NULL CONSTRAINT DF_HojaConteo_Estado DEFAULT('BORRADOR'),
    FechaConteo      DATETIME      NOT NULL CONSTRAINT DF_HojaConteo_FechaConteo DEFAULT(GETUTCDATE()),
    FechaCierre      DATETIME      NULL,
    ResponsableId    INT           NULL,
    Notas            NVARCHAR(MAX) NULL,
    CreatedAt        DATETIME      NOT NULL CONSTRAINT DF_HojaConteo_CreatedAt DEFAULT(GETUTCDATE()),
    CreatedByUserId  INT           NULL,
    CONSTRAINT CHK_HojaConteo_Estado CHECK (Estado IN ('BORRADOR','EN_PROCESO','APROBADA','CERRADA','CANCELADA')),
    CONSTRAINT UQ_HojaConteo_Numero  UNIQUE (CompanyId, Numero)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_HojaConteo_Company' AND object_id = OBJECT_ID('inv.HojaConteo'))
    CREATE INDEX IX_HojaConteo_Company ON inv.HojaConteo (CompanyId, Estado);
GO

-- ── HojaConteoLinea ───────────────────────────────────────────────────────────
IF OBJECT_ID('inv.HojaConteoLinea', 'U') IS NULL
CREATE TABLE inv.HojaConteoLinea (
    LineaId          INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_inv_HojaConteoLinea PRIMARY KEY,
    HojaConteoId     INT           NOT NULL CONSTRAINT FK_HojaConteoLinea_Hoja REFERENCES inv.HojaConteo(HojaConteoId),
    ProductCode      NVARCHAR(50)  NOT NULL,
    StockSistema     DECIMAL(14,4) NOT NULL CONSTRAINT DF_HojaConteoLinea_SistDft DEFAULT(0),
    StockFisico      DECIMAL(14,4) NULL,
    UnitCost         DECIMAL(14,4) NOT NULL CONSTRAINT DF_HojaConteoLinea_UnitCostDft DEFAULT(0),
    Justificacion    NVARCHAR(500) NULL,
    ContadoPorId     INT           NULL,
    ContadoAt        DATETIME      NULL,
    CONSTRAINT UQ_HojaConteoLinea_Prod UNIQUE (HojaConteoId, ProductCode)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_HojaConteoLinea_Hoja' AND object_id = OBJECT_ID('inv.HojaConteoLinea'))
    CREATE INDEX IX_HojaConteoLinea_Hoja ON inv.HojaConteoLinea (HojaConteoId);
GO

-- ── Albaran ───────────────────────────────────────────────────────────────────
IF OBJECT_ID('inv.Albaran', 'U') IS NULL
CREATE TABLE inv.Albaran (
    AlbaranId            INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_inv_Albaran PRIMARY KEY,
    CompanyId            INT           NOT NULL,
    Numero               NVARCHAR(40)  NOT NULL,
    Tipo                 NVARCHAR(20)  NOT NULL CONSTRAINT DF_Albaran_Tipo DEFAULT('DESPACHO'),
    Estado               NVARCHAR(20)  NOT NULL CONSTRAINT DF_Albaran_Estado DEFAULT('BORRADOR'),
    FechaEmision         DATETIME      NOT NULL CONSTRAINT DF_Albaran_FechaEmision DEFAULT(GETUTCDATE()),
    FechaFirma           DATETIME      NULL,
    WarehouseFrom        NVARCHAR(20)  NULL,
    WarehouseTo          NVARCHAR(20)  NULL,
    DestinatarioNombre   NVARCHAR(200) NULL,
    DestinatarioRif      NVARCHAR(30)  NULL,
    DestinatarioDireccion NVARCHAR(MAX) NULL,
    Observaciones        NVARCHAR(MAX) NULL,
    FirmadoPorId         INT           NULL,
    FirmadoPorNombre     NVARCHAR(200) NULL,
    SourceDocumentType   NVARCHAR(30)  NULL,
    SourceDocumentId     INT           NULL,
    ReportLayoutId       INT           NULL,
    CreatedByUserId      INT           NULL,
    CreatedAt            DATETIME      NOT NULL CONSTRAINT DF_Albaran_CreatedAt DEFAULT(GETUTCDATE()),
    CONSTRAINT CHK_Albaran_Tipo   CHECK (Tipo   IN ('DESPACHO','RECEPCION','TRASLADO')),
    CONSTRAINT CHK_Albaran_Estado CHECK (Estado IN ('BORRADOR','EMITIDO','FIRMADO','ANULADO')),
    CONSTRAINT UQ_Albaran_Numero  UNIQUE (CompanyId, Numero)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Albaran_Company' AND object_id = OBJECT_ID('inv.Albaran'))
    CREATE INDEX IX_Albaran_Company ON inv.Albaran (CompanyId, Estado, Tipo);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Albaran_Fecha' AND object_id = OBJECT_ID('inv.Albaran'))
    CREATE INDEX IX_Albaran_Fecha ON inv.Albaran (CompanyId, FechaEmision);
GO

-- ── AlbaranLinea ──────────────────────────────────────────────────────────────
IF OBJECT_ID('inv.AlbaranLinea', 'U') IS NULL
CREATE TABLE inv.AlbaranLinea (
    AlbaranLineaId   INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_inv_AlbaranLinea PRIMARY KEY,
    AlbaranId        INT           NOT NULL CONSTRAINT FK_AlbaranLinea_Albaran REFERENCES inv.Albaran(AlbaranId),
    ProductCode      NVARCHAR(50)  NOT NULL,
    Descripcion      NVARCHAR(500) NULL,
    Cantidad         DECIMAL(14,4) NOT NULL,
    Unidad           NVARCHAR(20)  NULL,
    CostoUnitario    DECIMAL(14,4) NOT NULL CONSTRAINT DF_AlbaranLinea_Costo DEFAULT(0),
    Lote             NVARCHAR(50)  NULL,
    FechaVencimiento DATE          NULL,
    Observaciones    NVARCHAR(500) NULL
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AlbaranLinea_Albaran' AND object_id = OBJECT_ID('inv.AlbaranLinea'))
    CREATE INDEX IX_AlbaranLinea_Albaran ON inv.AlbaranLinea (AlbaranId);
GO

-- ── TrasladoMultiPaso ─────────────────────────────────────────────────────────
IF OBJECT_ID('inv.TrasladoMultiPaso', 'U') IS NULL
CREATE TABLE inv.TrasladoMultiPaso (
    TrasladoId        INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_inv_TrasladoMP PRIMARY KEY,
    CompanyId         INT           NOT NULL,
    Numero            NVARCHAR(40)  NOT NULL,
    Estado            NVARCHAR(20)  NOT NULL CONSTRAINT DF_TrasladoMP_Estado DEFAULT('BORRADOR'),
    WarehouseFrom     NVARCHAR(20)  NOT NULL,
    WarehouseTo       NVARCHAR(20)  NOT NULL,
    FechaSolicitud    DATETIME      NOT NULL CONSTRAINT DF_TrasladoMP_FechaSol DEFAULT(GETUTCDATE()),
    FechaSalida       DATETIME      NULL,
    FechaRecepcion    DATETIME      NULL,
    AlbaranSalidaId   INT           NULL CONSTRAINT FK_TrasladoMP_AlbSalida REFERENCES inv.Albaran(AlbaranId),
    AlbaranEntradaId  INT           NULL CONSTRAINT FK_TrasladoMP_AlbEntrada REFERENCES inv.Albaran(AlbaranId),
    Notas             NVARCHAR(MAX) NULL,
    SolicitadoPorId   INT           NULL,
    AprobadoPorId     INT           NULL,
    RecibidoPorId     INT           NULL,
    CreatedAt         DATETIME      NOT NULL CONSTRAINT DF_TrasladoMP_CreatedAt DEFAULT(GETUTCDATE()),
    CONSTRAINT CHK_TrasladoMP_Estado CHECK (Estado IN ('BORRADOR','PENDIENTE','EN_TRANSITO','RECIBIDO','CERRADO','CANCELADO')),
    CONSTRAINT UQ_TrasladoMP_Numero   UNIQUE (CompanyId, Numero)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_TrasladoMP_Company' AND object_id = OBJECT_ID('inv.TrasladoMultiPaso'))
    CREATE INDEX IX_TrasladoMP_Company ON inv.TrasladoMultiPaso (CompanyId, Estado);
GO

-- ── TrasladoMultiPasoLinea ────────────────────────────────────────────────────
IF OBJECT_ID('inv.TrasladoMultiPasoLinea', 'U') IS NULL
CREATE TABLE inv.TrasladoMultiPasoLinea (
    TrasladoLineaId      INT           NOT NULL IDENTITY(1,1) CONSTRAINT PK_inv_TrasladoMPLinea PRIMARY KEY,
    TrasladoId           INT           NOT NULL CONSTRAINT FK_TrasladoMPLinea_Trl REFERENCES inv.TrasladoMultiPaso(TrasladoId),
    ProductCode          NVARCHAR(50)  NOT NULL,
    CantidadSolicitada   DECIMAL(14,4) NOT NULL,
    CantidadDespachada   DECIMAL(14,4) NULL,
    CantidadRecibida     DECIMAL(14,4) NULL,
    CostoUnitario        DECIMAL(14,4) NOT NULL CONSTRAINT DF_TrasladoMPLinea_Costo DEFAULT(0),
    Observaciones        NVARCHAR(500) NULL,
    CONSTRAINT UQ_TrasladoMPLinea_Prod UNIQUE (TrasladoId, ProductCode)
);
GO
