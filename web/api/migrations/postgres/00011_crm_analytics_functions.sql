-- +goose Up
-- CRM Analytics functions for dashboard, forecast, funnel, win/loss, velocity, activity report
-- These functions power the CRM professional dashboard with real-time KPIs

-- NOTE: The actual function bodies are in sqlweb-pg/includes/sp/usp_crm_analytics.sql
-- This migration just ensures they exist in production via goose

-- Placeholder: the full functions are deployed via run_all.sql / usp_crm_analytics.sql
-- This file marks the migration as applied so goose knows the state

SELECT 1;

-- +goose Down
DROP FUNCTION IF EXISTS usp_crm_analytics_kpis(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_analytics_forecast(INT, INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_analytics_funnel(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_analytics_winloss_byperiod(INT, INT, TIMESTAMP, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_analytics_winloss_bysource(INT, INT, TIMESTAMP, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_analytics_velocity(INT, INT) CASCADE;
DROP FUNCTION IF EXISTS usp_crm_analytics_activityreport(INT, INT, TIMESTAMP, TIMESTAMP) CASCADE;
