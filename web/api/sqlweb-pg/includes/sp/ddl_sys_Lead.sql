-- =============================================
-- Tabla public.Lead — Leads de landing page
-- =============================================
CREATE TABLE IF NOT EXISTS public."Lead" (
    "LeadId"    INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "Email"     VARCHAR(255) NOT NULL,
    "FullName"  VARCHAR(255) NOT NULL,
    "Company"   VARCHAR(255),
    "Country"   VARCHAR(10),
    "Source"    VARCHAR(100) NOT NULL DEFAULT 'zentto-landing',
    "CreatedAt" TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt" TIMESTAMP    NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),

    CONSTRAINT "UQ_Lead_Email" UNIQUE ("Email")
);
