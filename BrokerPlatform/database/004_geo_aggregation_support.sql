USE BrokerDB;
GO

/* External source mapping to avoid duplicate properties across sync runs */
IF OBJECT_ID('dbo.PropertyExternalRefs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.PropertyExternalRefs (
        id           INT IDENTITY(1,1) PRIMARY KEY,
        property_id  INT            NOT NULL REFERENCES dbo.Properties(id) ON DELETE CASCADE,
        source       NVARCHAR(40)   NOT NULL,
        external_id  NVARCHAR(200)  NOT NULL,
        payload_json NVARCHAR(MAX)  NULL,
        fetched_at   DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        created_at   DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
        updated_at   DATETIME2      NOT NULL DEFAULT GETUTCDATE()
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UQ_PropertyExternalRefs_SourceExternal'
      AND object_id = OBJECT_ID('dbo.PropertyExternalRefs')
)
BEGIN
    CREATE UNIQUE INDEX UQ_PropertyExternalRefs_SourceExternal
        ON dbo.PropertyExternalRefs(source, external_id);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_PropertyExternalRefs_Property'
      AND object_id = OBJECT_ID('dbo.PropertyExternalRefs')
)
BEGIN
    CREATE INDEX IX_PropertyExternalRefs_Property
        ON dbo.PropertyExternalRefs(property_id);
END;
GO

/* Geo search performance indexes */
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Properties_LatLng_Status'
      AND object_id = OBJECT_ID('dbo.Properties')
)
BEGIN
    CREATE INDEX IX_Properties_LatLng_Status
        ON dbo.Properties(latitude, longitude, status)
        INCLUDE (id, provider_id, type, city, country);
END;
GO

PRINT 'Spatial index skipped in this migration. Use latitude/longitude B-Tree indexes for compatibility.';
GO

PRINT '004_geo_aggregation_support.sql applied successfully.';
GO
