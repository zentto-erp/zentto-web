-- ============================================================
-- DatqBoxWeb PostgreSQL - create_vacation_request.sql
-- Tables: hr.VacationRequest, hr.VacationRequestDay
-- Workflow: PENDIENTE -> APROBADA -> PROCESADA (or RECHAZADA/CANCELADA)
-- ============================================================

BEGIN;

-- hr.VacationRequest
CREATE TABLE IF NOT EXISTS hr."VacationRequest" (
    "RequestId"       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "CompanyId"       INT NOT NULL DEFAULT 1,
    "BranchId"        INT NOT NULL DEFAULT 1,
    "EmployeeCode"    VARCHAR(60) NOT NULL,
    "RequestDate"     DATE NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')::DATE,
    "StartDate"       DATE NOT NULL,
    "EndDate"         DATE NOT NULL,
    "TotalDays"       INT NOT NULL,
    "IsPartial"       BOOLEAN NOT NULL DEFAULT FALSE,
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    "Notes"           VARCHAR(500),
    "ApprovedBy"      VARCHAR(60),
    "ApprovalDate"    TIMESTAMP,
    "RejectionReason" VARCHAR(500),
    "VacationId"      BIGINT,
    "CreatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"       TIMESTAMP NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),

    CONSTRAINT "CK_VacationRequest_Status" CHECK ("Status" IN ('PENDIENTE','APROBADA','RECHAZADA','CANCELADA','PROCESADA')),
    CONSTRAINT "CK_VacationRequest_Dates"  CHECK ("EndDate" >= "StartDate"),
    CONSTRAINT "CK_VacationRequest_Days"   CHECK ("TotalDays" > 0)
);

CREATE INDEX IF NOT EXISTS "IX_VacationRequest_Employee"
    ON hr."VacationRequest" ("CompanyId", "EmployeeCode", "Status");

CREATE INDEX IF NOT EXISTS "IX_VacationRequest_Status"
    ON hr."VacationRequest" ("Status", "RequestDate");

-- hr.VacationRequestDay
CREATE TABLE IF NOT EXISTS hr."VacationRequestDay" (
    "DayId"        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    "RequestId"    BIGINT NOT NULL REFERENCES hr."VacationRequest"("RequestId"),
    "SelectedDate" DATE NOT NULL,
    "DayType"      VARCHAR(20) NOT NULL DEFAULT 'COMPLETO',

    CONSTRAINT "CK_VacationRequestDay_Type" CHECK ("DayType" IN ('COMPLETO','MEDIO_DIA'))
);

CREATE INDEX IF NOT EXISTS "IX_VacationRequestDay_Request"
    ON hr."VacationRequestDay" ("RequestId");

COMMIT;
