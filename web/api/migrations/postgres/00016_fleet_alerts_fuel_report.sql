-- +goose Up

-- +goose StatementBegin
-- Fleet: Alertas de documentos/mantenimientos + Reporte combustible mensual

-- usp_Fleet_Alerts_Get
DROP FUNCTION IF EXISTS usp_fleet_alerts_get(INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_alerts_get(
    p_company_id INT,
    p_branch_id  INT DEFAULT NULL
)
RETURNS TABLE(
    "AlertType"             VARCHAR,
    "ItemId"                BIGINT,
    "VehicleId"             BIGINT,
    "LicensePlate"          VARCHAR,
    "Brand"                 VARCHAR,
    "Model"                 VARCHAR,
    "DocumentType"          VARCHAR,
    "DocumentNumber"        VARCHAR,
    "MaintenanceTypeName"   VARCHAR,
    "OrderNumber"           VARCHAR,
    "ExpiryDate"            TIMESTAMP,
    "ScheduledDate"         TIMESTAMP,
    "DaysOverdue"           INT,
    "DaysUntilExpiry"       INT,
    "ExpiredDocsCount"      INT,
    "ExpiringSoonDocsCount" INT,
    "OverdueMaintenanceCount" INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_now        TIMESTAMP := NOW() AT TIME ZONE 'UTC';
    v_in30days   TIMESTAMP := (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days';
    v_expired_docs INT;
    v_expiring_docs INT;
    v_overdue_maint INT;
BEGIN
    SELECT COUNT(*)::INT INTO v_expired_docs
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" < v_now AND vd."ExpiresAt" IS NOT NULL;

    SELECT COUNT(*)::INT INTO v_expiring_docs
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" >= v_now AND vd."ExpiresAt" <= v_in30days;

    SELECT COUNT(*)::INT INTO v_overdue_maint
    FROM fleet."MaintenanceOrder" mo
    WHERE mo."CompanyId" = p_company_id
      AND mo."Status" = 'SCHEDULED'
      AND mo."ScheduledDate" < v_now
      AND mo."IsDeleted" IS NOT TRUE;

    RETURN QUERY
    SELECT
        'EXPIRED'::VARCHAR,
        vd."VehicleDocumentId",
        vd."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        vd."DocumentType"::VARCHAR,
        vd."DocumentNumber"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        vd."ExpiresAt",
        NULL::TIMESTAMP,
        EXTRACT(DAY FROM v_now - vd."ExpiresAt")::INT,
        NULL::INT,
        v_expired_docs,
        v_expiring_docs,
        v_overdue_maint
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" < v_now AND vd."ExpiresAt" IS NOT NULL
    ORDER BY vd."ExpiresAt";

    RETURN QUERY
    SELECT
        'EXPIRING_SOON'::VARCHAR,
        vd."VehicleDocumentId",
        vd."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        vd."DocumentType"::VARCHAR,
        vd."DocumentNumber"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        vd."ExpiresAt",
        NULL::TIMESTAMP,
        NULL::INT,
        EXTRACT(DAY FROM vd."ExpiresAt" - v_now)::INT,
        v_expired_docs,
        v_expiring_docs,
        v_overdue_maint
    FROM fleet."VehicleDocument" vd
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = vd."VehicleId"
    WHERE v."CompanyId" = p_company_id AND v."IsActive" = TRUE
      AND v."IsDeleted" IS NOT TRUE AND vd."IsDeleted" IS NOT TRUE
      AND vd."ExpiresAt" >= v_now AND vd."ExpiresAt" <= v_in30days
    ORDER BY vd."ExpiresAt";

    RETURN QUERY
    SELECT
        'MAINTENANCE_OVERDUE'::VARCHAR,
        mo."MaintenanceOrderId",
        mo."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        NULL::VARCHAR,
        NULL::VARCHAR,
        mt."TypeName"::VARCHAR,
        mo."OrderNumber"::VARCHAR,
        NULL::TIMESTAMP,
        mo."ScheduledDate",
        EXTRACT(DAY FROM v_now - mo."ScheduledDate")::INT,
        NULL::INT,
        v_expired_docs,
        v_expiring_docs,
        v_overdue_maint
    FROM fleet."MaintenanceOrder" mo
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = mo."VehicleId"
    LEFT JOIN fleet."MaintenanceType" mt ON mt."MaintenanceTypeId" = mo."MaintenanceTypeId"
    WHERE mo."CompanyId" = p_company_id
      AND mo."Status" = 'SCHEDULED'
      AND mo."ScheduledDate" < v_now
      AND mo."IsDeleted" IS NOT TRUE
    ORDER BY mo."ScheduledDate";
END;
$$;

-- usp_Fleet_Report_FuelMonthly
DROP FUNCTION IF EXISTS usp_fleet_report_fuelmonthly(INT, INT, INT, INT) CASCADE;
CREATE OR REPLACE FUNCTION usp_fleet_report_fuelmonthly(
    p_company_id INT,
    p_branch_id  INT DEFAULT NULL,
    p_year       INT DEFAULT NULL,
    p_month      INT DEFAULT NULL
)
RETURNS TABLE(
    "VehicleId"      BIGINT,
    "LicensePlate"   VARCHAR,
    "Brand"          VARCHAR,
    "Model"          VARCHAR,
    "TotalLiters"    NUMERIC,
    "TotalCost"      NUMERIC,
    "AvgCostPerLiter" NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        fl."VehicleId",
        v."LicensePlate"::VARCHAR,
        v."Brand"::VARCHAR,
        v."Model"::VARCHAR,
        COALESCE(SUM(fl."Quantity"), 0)     AS "TotalLiters",
        COALESCE(SUM(fl."TotalCost"), 0)    AS "TotalCost",
        CASE
            WHEN SUM(fl."Quantity") > 0 THEN SUM(fl."TotalCost") / SUM(fl."Quantity")
            ELSE 0
        END                                  AS "AvgCostPerLiter"
    FROM fleet."FuelLog" fl
    INNER JOIN fleet."Vehicle" v ON v."VehicleId" = fl."VehicleId"
    WHERE v."CompanyId" = p_company_id
      AND v."IsDeleted" IS NOT TRUE
      AND fl."IsDeleted" IS NOT TRUE
      AND EXTRACT(YEAR FROM fl."FuelDate") = p_year
      AND EXTRACT(MONTH FROM fl."FuelDate") = p_month
    GROUP BY fl."VehicleId", v."LicensePlate", v."Brand", v."Model"
    ORDER BY v."LicensePlate";
END;
$$;

-- +goose StatementEnd

-- +goose Down
DROP FUNCTION IF EXISTS usp_fleet_alerts_get(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_fleet_report_fuelmonthly(INT, INT, INT, INT) CASCADE;
