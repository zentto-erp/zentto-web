-- +goose Up
-- Zentto Shipping Module — Portal de paquetería para clientes
-- Tablas: ShippingCustomer, ShippingAddress, CarrierConfig,
--         Shipment, ShipmentPackage, ShipmentEvent, ShipmentRate,
--         CustomsDeclaration, ShipmentNotification

BEGIN;

-- ============================================================
-- 1. logistics.ShippingCustomer (Clientes del portal shipping)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."ShippingCustomer" (
  "ShippingCustomerId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"           INT           NOT NULL,
  "Email"               VARCHAR(200)  NOT NULL,
  "PasswordHash"        VARCHAR(200)  NOT NULL,
  "DisplayName"         VARCHAR(200)  NOT NULL,
  "Phone"               VARCHAR(60)   NULL,
  "FiscalId"            VARCHAR(30)   NULL,
  "CompanyName"         VARCHAR(200)  NULL,
  "CountryCode"         VARCHAR(3)    NULL,
  "PreferredLanguage"   VARCHAR(5)    NOT NULL DEFAULT 'es',
  "IsActive"            BOOLEAN       NOT NULL DEFAULT TRUE,
  "IsEmailVerified"     BOOLEAN       NOT NULL DEFAULT FALSE,
  "LastLoginAt"         TIMESTAMP     NULL,
  "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"              INT           NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_ShippingCustomer_Email"
  ON logistics."ShippingCustomer" ("CompanyId", LOWER("Email"));

CREATE INDEX IF NOT EXISTS "IX_ShippingCustomer_Active"
  ON logistics."ShippingCustomer" ("CompanyId", "IsActive");

-- ============================================================
-- 2. logistics.ShippingAddress (Direcciones guardadas)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."ShippingAddress" (
  "ShippingAddressId"    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ShippingCustomerId"   BIGINT        NOT NULL REFERENCES logistics."ShippingCustomer" ("ShippingCustomerId"),
  "Label"                VARCHAR(60)   NOT NULL DEFAULT 'Principal',
  "ContactName"          VARCHAR(150)  NOT NULL,
  "Phone"                VARCHAR(60)   NULL,
  "AddressLine1"         VARCHAR(300)  NOT NULL,
  "AddressLine2"         VARCHAR(300)  NULL,
  "City"                 VARCHAR(100)  NOT NULL,
  "State"                VARCHAR(100)  NULL,
  "PostalCode"           VARCHAR(20)   NULL,
  "CountryCode"          VARCHAR(3)    NOT NULL DEFAULT 'VE',
  "Latitude"             DECIMAL(10,7) NULL,
  "Longitude"            DECIMAL(10,7) NULL,
  "IsDefault"            BOOLEAN       NOT NULL DEFAULT FALSE,
  "CreatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ShippingAddress_Customer"
  ON logistics."ShippingAddress" ("ShippingCustomerId");

-- ============================================================
-- 3. logistics.CarrierConfig (Config API de carriers externos)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."CarrierConfig" (
  "CarrierConfigId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"        INT           NOT NULL,
  "CarrierCode"      VARCHAR(30)   NOT NULL,
  "CarrierName"      VARCHAR(100)  NOT NULL,
  "CarrierType"      VARCHAR(20)   NOT NULL DEFAULT 'API',
  "ApiBaseUrl"       VARCHAR(500)  NULL,
  "ApiKey"           VARCHAR(500)  NULL,
  "ApiSecret"        VARCHAR(500)  NULL,
  "AccountNumber"    VARCHAR(100)  NULL,
  "ExtraConfig"      JSONB         NULL,
  "SupportedCountries" VARCHAR(100) NULL,
  "IsActive"         BOOLEAN       NOT NULL DEFAULT TRUE,
  "CreatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_CarrierConfig_Code"
  ON logistics."CarrierConfig" ("CompanyId", "CarrierCode");

-- ============================================================
-- 4. logistics.Shipment (Envío principal)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."Shipment" (
  "ShipmentId"          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "CompanyId"           INT           NOT NULL,
  "ShippingCustomerId"  BIGINT        NULL REFERENCES logistics."ShippingCustomer" ("ShippingCustomerId"),
  "ShipmentNumber"      VARCHAR(30)   NOT NULL,
  "TrackingNumber"      VARCHAR(100)  NULL,
  "CarrierConfigId"     BIGINT        NULL REFERENCES logistics."CarrierConfig" ("CarrierConfigId"),
  "CarrierCode"         VARCHAR(30)   NULL,
  "CarrierTrackingUrl"  VARCHAR(500)  NULL,

  -- Origen
  "OriginContactName"   VARCHAR(150)  NOT NULL,
  "OriginPhone"         VARCHAR(60)   NULL,
  "OriginAddress"       VARCHAR(500)  NOT NULL,
  "OriginCity"          VARCHAR(100)  NOT NULL,
  "OriginState"         VARCHAR(100)  NULL,
  "OriginPostalCode"    VARCHAR(20)   NULL,
  "OriginCountryCode"   VARCHAR(3)    NOT NULL DEFAULT 'VE',

  -- Destino
  "DestContactName"     VARCHAR(150)  NOT NULL,
  "DestPhone"           VARCHAR(60)   NULL,
  "DestAddress"         VARCHAR(500)  NOT NULL,
  "DestCity"            VARCHAR(100)  NOT NULL,
  "DestState"           VARCHAR(100)  NULL,
  "DestPostalCode"      VARCHAR(20)   NULL,
  "DestCountryCode"     VARCHAR(3)    NOT NULL DEFAULT 'VE',

  -- Detalles
  "ServiceType"         VARCHAR(30)   NOT NULL DEFAULT 'STANDARD',
  "PaymentMethod"       VARCHAR(30)   NOT NULL DEFAULT 'PREPAID',
  "DeclaredValue"       DECIMAL(18,2) NULL,
  "Currency"            VARCHAR(3)    NOT NULL DEFAULT 'USD',
  "InsuredAmount"       DECIMAL(18,2) NULL,
  "ShippingCost"        DECIMAL(18,2) NULL,
  "TotalWeight"         DECIMAL(10,3) NULL,
  "Description"         VARCHAR(500)  NULL,
  "Notes"               VARCHAR(500)  NULL,
  "Reference"           VARCHAR(100)  NULL,

  -- Estado
  "Status"              VARCHAR(30)   NOT NULL DEFAULT 'DRAFT',
  "EstimatedDelivery"   DATE          NULL,
  "ActualDelivery"      TIMESTAMP     NULL,
  "DeliveredToName"     VARCHAR(150)  NULL,
  "DeliverySignature"   TEXT          NULL,
  "LabelUrl"            VARCHAR(500)  NULL,

  -- Aduanas
  "IsInternational"     BOOLEAN       NOT NULL DEFAULT FALSE,
  "CustomsStatus"       VARCHAR(30)   NULL,

  -- Control
  "CreatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"           TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "RowVer"              INT           NOT NULL DEFAULT 1,

  CONSTRAINT "CK_Shipment_Status" CHECK ("Status" IN (
    'DRAFT','QUOTED','LABEL_READY','PICKED_UP','IN_TRANSIT',
    'IN_CUSTOMS','CUSTOMS_HELD','CUSTOMS_CLEARED',
    'OUT_FOR_DELIVERY','DELIVERED','RETURNED','EXCEPTION','CANCELLED'
  )),
  CONSTRAINT "CK_Shipment_ServiceType" CHECK ("ServiceType" IN (
    'STANDARD','EXPRESS','SAME_DAY','ECONOMY','OVERNIGHT'
  ))
);

CREATE UNIQUE INDEX IF NOT EXISTS "UQ_Shipment_Number"
  ON logistics."Shipment" ("CompanyId", "ShipmentNumber");

CREATE INDEX IF NOT EXISTS "IX_Shipment_Customer"
  ON logistics."Shipment" ("ShippingCustomerId", "Status");

CREATE INDEX IF NOT EXISTS "IX_Shipment_Tracking"
  ON logistics."Shipment" ("TrackingNumber") WHERE "TrackingNumber" IS NOT NULL;

CREATE INDEX IF NOT EXISTS "IX_Shipment_Status"
  ON logistics."Shipment" ("CompanyId", "Status", "CreatedAt" DESC);

-- ============================================================
-- 5. logistics.ShipmentPackage (Paquetes del envío)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."ShipmentPackage" (
  "ShipmentPackageId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ShipmentId"         BIGINT        NOT NULL REFERENCES logistics."Shipment" ("ShipmentId"),
  "PackageNumber"      INT           NOT NULL DEFAULT 1,
  "Weight"             DECIMAL(10,3) NOT NULL DEFAULT 0,
  "WeightUnit"         VARCHAR(5)    NOT NULL DEFAULT 'kg',
  "Length"             DECIMAL(10,2) NULL,
  "Width"              DECIMAL(10,2) NULL,
  "Height"             DECIMAL(10,2) NULL,
  "DimensionUnit"      VARCHAR(5)    NOT NULL DEFAULT 'cm',
  "ContentDescription" VARCHAR(300)  NULL,
  "DeclaredValue"      DECIMAL(18,2) NULL,
  "HsCode"             VARCHAR(20)   NULL,
  "CountryOfOrigin"    VARCHAR(3)    NULL
);

CREATE INDEX IF NOT EXISTS "IX_ShipmentPackage_Shipment"
  ON logistics."ShipmentPackage" ("ShipmentId");

-- ============================================================
-- 6. logistics.ShipmentEvent (Timeline de eventos)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."ShipmentEvent" (
  "ShipmentEventId"  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ShipmentId"       BIGINT        NOT NULL REFERENCES logistics."Shipment" ("ShipmentId"),
  "EventType"        VARCHAR(30)   NOT NULL,
  "Status"           VARCHAR(30)   NOT NULL,
  "Description"      VARCHAR(500)  NOT NULL,
  "Location"         VARCHAR(200)  NULL,
  "City"             VARCHAR(100)  NULL,
  "CountryCode"      VARCHAR(3)    NULL,
  "CarrierEventCode" VARCHAR(50)   NULL,
  "Source"           VARCHAR(20)   NOT NULL DEFAULT 'SYSTEM',
  "EventAt"          TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "CreatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ShipmentEvent_Shipment"
  ON logistics."ShipmentEvent" ("ShipmentId", "EventAt" DESC);

-- ============================================================
-- 7. logistics.ShipmentRate (Cotizaciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."ShipmentRate" (
  "ShipmentRateId"   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ShipmentId"       BIGINT        NOT NULL REFERENCES logistics."Shipment" ("ShipmentId"),
  "CarrierCode"      VARCHAR(30)   NOT NULL,
  "CarrierName"      VARCHAR(100)  NOT NULL,
  "ServiceType"      VARCHAR(30)   NOT NULL,
  "ServiceName"      VARCHAR(100)  NULL,
  "Price"            DECIMAL(18,2) NOT NULL,
  "Currency"         VARCHAR(3)    NOT NULL DEFAULT 'USD',
  "EstimatedDays"    INT           NULL,
  "EstimatedDelivery" DATE         NULL,
  "IsSelected"       BOOLEAN       NOT NULL DEFAULT FALSE,
  "ExpiresAt"        TIMESTAMP     NULL,
  "CreatedAt"        TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ShipmentRate_Shipment"
  ON logistics."ShipmentRate" ("ShipmentId");

-- ============================================================
-- 8. logistics.CustomsDeclaration (Declaración aduanera)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."CustomsDeclaration" (
  "CustomsDeclarationId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ShipmentId"           BIGINT        NOT NULL REFERENCES logistics."Shipment" ("ShipmentId"),
  "DeclarationNumber"    VARCHAR(50)   NULL,
  "Status"               VARCHAR(30)   NOT NULL DEFAULT 'PENDING',
  "ContentType"          VARCHAR(30)   NOT NULL DEFAULT 'MERCHANDISE',
  "TotalDeclaredValue"   DECIMAL(18,2) NOT NULL,
  "Currency"             VARCHAR(3)    NOT NULL DEFAULT 'USD',
  "ExporterName"         VARCHAR(200)  NULL,
  "ExporterFiscalId"     VARCHAR(30)   NULL,
  "ImporterName"         VARCHAR(200)  NULL,
  "ImporterFiscalId"     VARCHAR(30)   NULL,
  "OriginCountryCode"    VARCHAR(3)    NOT NULL,
  "DestCountryCode"      VARCHAR(3)    NOT NULL,
  "HsCode"               VARCHAR(20)   NULL,
  "ItemDescription"      VARCHAR(500)  NOT NULL,
  "Quantity"             INT           NOT NULL DEFAULT 1,
  "WeightKg"             DECIMAL(10,3) NULL,
  "DocumentsJson"        JSONB         NULL,
  "Notes"                VARCHAR(500)  NULL,
  "SubmittedAt"          TIMESTAMP     NULL,
  "ClearedAt"            TIMESTAMP     NULL,
  "CreatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
  "UpdatedAt"            TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),

  CONSTRAINT "CK_Customs_Status" CHECK ("Status" IN (
    'PENDING','SUBMITTED','IN_REVIEW','CLEARED','HELD','RELEASED','REJECTED'
  )),
  CONSTRAINT "CK_Customs_ContentType" CHECK ("ContentType" IN (
    'MERCHANDISE','DOCUMENTS','GIFT','SAMPLE','RETURNED_GOODS','OTHER'
  ))
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_Customs_Shipment"
  ON logistics."CustomsDeclaration" ("ShipmentId");

-- ============================================================
-- 9. logistics.ShipmentNotification (Log de notificaciones)
-- ============================================================
CREATE TABLE IF NOT EXISTS logistics."ShipmentNotification" (
  "ShipmentNotificationId" BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  "ShipmentId"             BIGINT        NOT NULL REFERENCES logistics."Shipment" ("ShipmentId"),
  "Channel"                VARCHAR(20)   NOT NULL,
  "Recipient"              VARCHAR(200)  NOT NULL,
  "EventType"              VARCHAR(30)   NOT NULL,
  "Subject"                VARCHAR(300)  NULL,
  "Status"                 VARCHAR(20)   NOT NULL DEFAULT 'SENT',
  "ExternalMessageId"      VARCHAR(100)  NULL,
  "SentAt"                 TIMESTAMP     NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS "IX_ShipmentNotification_Shipment"
  ON logistics."ShipmentNotification" ("ShipmentId");

COMMIT;

-- +goose Down
BEGIN;
DROP TABLE IF EXISTS logistics."ShipmentNotification";
DROP TABLE IF EXISTS logistics."CustomsDeclaration";
DROP TABLE IF EXISTS logistics."ShipmentRate";
DROP TABLE IF EXISTS logistics."ShipmentEvent";
DROP TABLE IF EXISTS logistics."ShipmentPackage";
DROP TABLE IF EXISTS logistics."Shipment";
DROP TABLE IF EXISTS logistics."CarrierConfig";
DROP TABLE IF EXISTS logistics."ShippingAddress";
DROP TABLE IF EXISTS logistics."ShippingCustomer";
COMMIT;
