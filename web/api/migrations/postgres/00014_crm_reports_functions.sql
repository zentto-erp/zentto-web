-- +goose Up
SELECT 1;

-- +goose Down
DROP FUNCTION IF EXISTS usp_crm_report_salesbyperiod(INT, INT, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_report_leadaging(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_report_conversionbysource(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_report_topperformers(INT, INT, TIMESTAMP) CASCADE;
