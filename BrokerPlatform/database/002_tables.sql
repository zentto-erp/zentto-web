-- ============================================
-- BrokerDB – Full schema
-- Compatible: SQL Server (primary) / PostgreSQL (future)
-- Notes:
--   SQL Server: INT IDENTITY  →  PostgreSQL: SERIAL
--   SQL Server: NVARCHAR      →  PostgreSQL: VARCHAR
--   SQL Server: DATETIME2     →  PostgreSQL: TIMESTAMP
--   SQL Server: BIT           →  PostgreSQL: BOOLEAN
--   SQL Server: NVARCHAR(MAX) →  PostgreSQL: TEXT
-- ============================================
USE BrokerDB;
GO

-- ─────────────────────────────────────────────
-- USERS & AUTH
-- ─────────────────────────────────────────────
CREATE TABLE Roles (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    name        NVARCHAR(50)  NOT NULL UNIQUE,
    description NVARCHAR(200) NULL,
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE Users (
    id             INT IDENTITY(1,1) PRIMARY KEY,
    email          NVARCHAR(150) NOT NULL UNIQUE,
    password_hash  NVARCHAR(255) NOT NULL,
    first_name     NVARCHAR(100) NOT NULL,
    last_name      NVARCHAR(100) NOT NULL,
    phone          NVARCHAR(30)  NULL,
    avatar_url     NVARCHAR(500) NULL,
    status         NVARCHAR(20)  NOT NULL DEFAULT 'active',      -- active, inactive, suspended
    created_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at     DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE UserRoles (
    user_id INT NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    role_id INT NOT NULL REFERENCES Roles(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- ─────────────────────────────────────────────
-- COUNTRIES & CURRENCIES
-- ─────────────────────────────────────────────
CREATE TABLE Countries (
    code NVARCHAR(3)   NOT NULL PRIMARY KEY,   -- ISO 3166-1 alpha-3
    name NVARCHAR(100) NOT NULL
);

CREATE TABLE Currencies (
    code          NVARCHAR(3)    NOT NULL PRIMARY KEY,  -- ISO 4217
    name          NVARCHAR(60)   NOT NULL,
    symbol        NVARCHAR(5)    NOT NULL,
    exchange_rate DECIMAL(18,6)  NOT NULL DEFAULT 1.0
);

-- ─────────────────────────────────────────────
-- PROVIDERS
-- ─────────────────────────────────────────────
CREATE TABLE Providers (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    name            NVARCHAR(200)  NOT NULL,
    type            NVARCHAR(30)   NOT NULL,  -- hotel, car_rental, marina, airline, lodge, tour
    tax_id          NVARCHAR(50)   NULL,
    email           NVARCHAR(150)  NULL,
    phone           NVARCHAR(30)   NULL,
    address         NVARCHAR(300)  NULL,
    city            NVARCHAR(100)  NULL,
    state           NVARCHAR(100)  NULL,
    country         NVARCHAR(3)    NULL REFERENCES Countries(code),
    logo_url        NVARCHAR(500)  NULL,
    description     NVARCHAR(MAX)  NULL,
    rating          DECIMAL(3,2)   NOT NULL DEFAULT 0.00,
    status          NVARCHAR(20)   NOT NULL DEFAULT 'active',
    commission_pct  DECIMAL(5,2)   NOT NULL DEFAULT 10.00,
    contact_person  NVARCHAR(150)  NULL,
    user_id         INT            NULL REFERENCES Users(id),
    created_at      DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    updated_at      DATETIME2      NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE ProviderCategories (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT           NOT NULL REFERENCES Providers(id) ON DELETE CASCADE,
    category    NVARCHAR(50)  NOT NULL   -- luxury, budget, boutique, family, business
);

-- ─────────────────────────────────────────────
-- AMENITIES CATALOG
-- ─────────────────────────────────────────────
CREATE TABLE Amenities (
    id       INT IDENTITY(1,1) PRIMARY KEY,
    name     NVARCHAR(100) NOT NULL,
    icon     NVARCHAR(50)  NULL,
    category NVARCHAR(50)  NOT NULL DEFAULT 'general'  -- general, room, safety, transport, entertainment
);

-- ─────────────────────────────────────────────
-- PROPERTIES & INVENTORY
-- ─────────────────────────────────────────────
CREATE TABLE Properties (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    provider_id INT           NOT NULL REFERENCES Providers(id) ON DELETE CASCADE,
    name        NVARCHAR(200) NOT NULL,
    type        NVARCHAR(30)  NOT NULL,  -- room, vehicle, boat, flight, unit
    description NVARCHAR(MAX) NULL,
    address     NVARCHAR(300) NULL,
    city        NVARCHAR(100) NULL,
    country     NVARCHAR(3)   NULL REFERENCES Countries(code),
    latitude    DECIMAL(10,7) NULL,
    longitude   DECIMAL(10,7) NULL,
    max_guests  INT           NOT NULL DEFAULT 2,
    images      NVARCHAR(MAX) NULL,      -- JSON array of URLs
    status      NVARCHAR(20)  NOT NULL DEFAULT 'active',
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE PropertyAmenities (
    property_id INT NOT NULL REFERENCES Properties(id) ON DELETE CASCADE,
    amenity_id  INT NOT NULL REFERENCES Amenities(id)  ON DELETE CASCADE,
    PRIMARY KEY (property_id, amenity_id)
);

CREATE TABLE PropertyRates (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    property_id     INT            NOT NULL REFERENCES Properties(id) ON DELETE CASCADE,
    name            NVARCHAR(50)   NOT NULL DEFAULT 'standard',  -- standard, weekend, holiday, promo
    price_per_night DECIMAL(18,2)  NOT NULL DEFAULT 0,
    price_per_hour  DECIMAL(18,2)  NOT NULL DEFAULT 0,
    currency        NVARCHAR(3)    NOT NULL DEFAULT 'USD',
    valid_from      DATETIME2      NULL,
    valid_to        DATETIME2      NULL
);

CREATE TABLE Availability (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    property_id     INT        NOT NULL REFERENCES Properties(id) ON DELETE CASCADE,
    date            DATE       NOT NULL,
    available_units INT        NOT NULL DEFAULT 1,
    booked_units    INT        NOT NULL DEFAULT 0,
    blocked         BIT        NOT NULL DEFAULT 0,
    min_stay        INT        NOT NULL DEFAULT 1,
    max_stay        INT        NOT NULL DEFAULT 30,
    UNIQUE (property_id, date)
);

-- ─────────────────────────────────────────────
-- CUSTOMERS / GUESTS
-- ─────────────────────────────────────────────
CREATE TABLE Customers (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    user_id         INT           NULL REFERENCES Users(id),
    first_name      NVARCHAR(100) NOT NULL,
    last_name       NVARCHAR(100) NOT NULL,
    email           NVARCHAR(150) NULL,
    phone           NVARCHAR(30)  NULL,
    document_type   NVARCHAR(20)  NULL,   -- passport, id_card, driver_license
    document_number NVARCHAR(50)  NULL,
    nationality     NVARCHAR(3)   NULL REFERENCES Countries(code),
    address         NVARCHAR(300) NULL,
    city            NVARCHAR(100) NULL,
    country         NVARCHAR(3)   NULL,
    loyalty_points  INT           NOT NULL DEFAULT 0,
    status          NVARCHAR(20)  NOT NULL DEFAULT 'active',
    created_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    updated_at      DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);

-- ─────────────────────────────────────────────
-- BOOKINGS
-- ─────────────────────────────────────────────
CREATE TABLE Bookings (
    id                INT IDENTITY(1,1) PRIMARY KEY,
    booking_code      NVARCHAR(20)   NOT NULL UNIQUE,
    customer_id       INT            NOT NULL REFERENCES Customers(id),
    property_id       INT            NOT NULL REFERENCES Properties(id),
    provider_id       INT            NOT NULL REFERENCES Providers(id),
    check_in          DATETIME2      NOT NULL,
    check_out         DATETIME2      NOT NULL,
    guests            INT            NOT NULL DEFAULT 1,
    status            NVARCHAR(20)   NOT NULL DEFAULT 'pending',  -- pending, confirmed, checked_in, checked_out, cancelled, no_show
    total_amount      DECIMAL(18,2)  NOT NULL DEFAULT 0,
    currency          NVARCHAR(3)    NOT NULL DEFAULT 'USD',
    commission_amount DECIMAL(18,2)  NOT NULL DEFAULT 0,
    notes             NVARCHAR(MAX)  NULL,
    created_at        DATETIME2      NOT NULL DEFAULT GETUTCDATE(),
    updated_at        DATETIME2      NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE BookingItems (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    booking_id  INT            NOT NULL REFERENCES Bookings(id) ON DELETE CASCADE,
    description NVARCHAR(200)  NOT NULL,
    quantity    INT            NOT NULL DEFAULT 1,
    unit_price  DECIMAL(18,2)  NOT NULL DEFAULT 0,
    subtotal    DECIMAL(18,2)  NOT NULL DEFAULT 0
);

CREATE TABLE BookingStatusHistory (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    booking_id  INT           NOT NULL REFERENCES Bookings(id) ON DELETE CASCADE,
    from_status NVARCHAR(20)  NULL,
    to_status   NVARCHAR(20)  NOT NULL,
    changed_by  INT           NULL REFERENCES Users(id),
    changed_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE(),
    notes       NVARCHAR(500) NULL
);

-- ─────────────────────────────────────────────
-- PAYMENTS
-- ─────────────────────────────────────────────
CREATE TABLE Payments (
    id             INT IDENTITY(1,1) PRIMARY KEY,
    booking_id     INT            NOT NULL REFERENCES Bookings(id),
    customer_id    INT            NOT NULL REFERENCES Customers(id),
    amount         DECIMAL(18,2)  NOT NULL,
    currency       NVARCHAR(3)    NOT NULL DEFAULT 'USD',
    payment_method NVARCHAR(30)   NOT NULL DEFAULT 'card',  -- cash, card, transfer, gateway
    gateway_ref    NVARCHAR(100)  NULL,
    status         NVARCHAR(20)   NOT NULL DEFAULT 'pending',  -- pending, completed, failed, refunded
    paid_at        DATETIME2      NULL,
    created_at     DATETIME2      NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE Invoices (
    id             INT IDENTITY(1,1)  PRIMARY KEY,
    booking_id     INT                NOT NULL REFERENCES Bookings(id),
    invoice_number NVARCHAR(30)       NOT NULL UNIQUE,
    subtotal       DECIMAL(18,2)      NOT NULL DEFAULT 0,
    tax_amount     DECIMAL(18,2)      NOT NULL DEFAULT 0,
    total          DECIMAL(18,2)      NOT NULL DEFAULT 0,
    status         NVARCHAR(20)       NOT NULL DEFAULT 'draft',  -- draft, issued, paid, void
    issued_at      DATETIME2          NULL,
    created_at     DATETIME2          NOT NULL DEFAULT GETUTCDATE()
);

CREATE TABLE Refunds (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    payment_id  INT            NOT NULL REFERENCES Payments(id),
    amount      DECIMAL(18,2)  NOT NULL,
    reason      NVARCHAR(500)  NULL,
    status      NVARCHAR(20)   NOT NULL DEFAULT 'pending',  -- pending, approved, completed
    refunded_at DATETIME2      NULL,
    created_at  DATETIME2      NOT NULL DEFAULT GETUTCDATE()
);

-- ─────────────────────────────────────────────
-- REVIEWS
-- ─────────────────────────────────────────────
CREATE TABLE Reviews (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    booking_id  INT           NOT NULL REFERENCES Bookings(id),
    customer_id INT           NOT NULL REFERENCES Customers(id),
    property_id INT           NOT NULL REFERENCES Properties(id),
    rating      INT           NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title       NVARCHAR(200) NULL,
    comment     NVARCHAR(MAX) NULL,
    response    NVARCHAR(MAX) NULL,    -- provider reply
    status      NVARCHAR(20)  NOT NULL DEFAULT 'published',  -- published, hidden, flagged
    created_at  DATETIME2     NOT NULL DEFAULT GETUTCDATE()
);

-- ─────────────────────────────────────────────
-- PROMOTIONS & FEATURED
-- ─────────────────────────────────────────────
CREATE TABLE Promotions (
    id              INT IDENTITY(1,1) PRIMARY KEY,
    provider_id     INT            NULL REFERENCES Providers(id),
    property_id     INT            NULL REFERENCES Properties(id),
    name            NVARCHAR(150)  NOT NULL,
    discount_pct    DECIMAL(5,2)   NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,2)  NOT NULL DEFAULT 0,
    valid_from      DATETIME2      NOT NULL,
    valid_to        DATETIME2      NOT NULL,
    promo_code      NVARCHAR(30)   NULL UNIQUE,
    usage_limit     INT            NOT NULL DEFAULT 0,
    times_used      INT            NOT NULL DEFAULT 0,
    status          NVARCHAR(20)   NOT NULL DEFAULT 'active'
);

CREATE TABLE FeaturedListings (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    property_id INT       NOT NULL REFERENCES Properties(id),
    position    INT       NOT NULL DEFAULT 0,
    valid_from  DATETIME2 NOT NULL,
    valid_to    DATETIME2 NOT NULL
);

-- ─────────────────────────────────────────────
-- SYSTEM SETTINGS
-- ─────────────────────────────────────────────
CREATE TABLE Settings (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    [key]       NVARCHAR(100) NOT NULL UNIQUE,
    value       NVARCHAR(MAX) NULL,
    category    NVARCHAR(50)  NOT NULL DEFAULT 'general',
    description NVARCHAR(300) NULL
);

CREATE TABLE CommissionRules (
    id            INT IDENTITY(1,1) PRIMARY KEY,
    provider_type NVARCHAR(30) NOT NULL,
    min_pct       DECIMAL(5,2) NOT NULL DEFAULT 5.00,
    max_pct       DECIMAL(5,2) NOT NULL DEFAULT 25.00,
    default_pct   DECIMAL(5,2) NOT NULL DEFAULT 10.00
);

-- ─────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────
CREATE INDEX IX_Users_email         ON Users(email);
CREATE INDEX IX_Providers_type      ON Providers(type);
CREATE INDEX IX_Providers_status    ON Providers(status);
CREATE INDEX IX_Properties_provider ON Properties(provider_id);
CREATE INDEX IX_Properties_type     ON Properties(type);
CREATE INDEX IX_Properties_city     ON Properties(city);
CREATE INDEX IX_Availability_date   ON Availability(property_id, date);
CREATE INDEX IX_Bookings_customer   ON Bookings(customer_id);
CREATE INDEX IX_Bookings_property   ON Bookings(property_id);
CREATE INDEX IX_Bookings_status     ON Bookings(status);
CREATE INDEX IX_Bookings_dates      ON Bookings(check_in, check_out);
CREATE INDEX IX_Payments_booking    ON Payments(booking_id);
CREATE INDEX IX_Reviews_property    ON Reviews(property_id);

PRINT 'All tables and indexes created successfully.';
GO
