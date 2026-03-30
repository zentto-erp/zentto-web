-- ============================================================
-- DatqBoxWeb PostgreSQL - 001_fiscal_multipais_base.sql
-- Base fiscal multi-pais para Venezuela + Espana (Verifactu).
-- No destructivo e idempotente.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS fiscal;

-- NOTA: Tablas legacy public.* eliminadas (2026-03-16).
-- Usar fiscal.CountryConfig, fiscal.TaxRate, fiscal.InvoiceType, fiscal.Record.
-- Tablas eliminadas: FiscalCountryConfig, FiscalTaxRates, FiscalInvoiceTypes, FiscalRecords.
-- Los INSERTs de seed para FiscalTaxRates y FiscalInvoiceTypes fueron eliminados de este archivo.
-- El seed canonico vive en 06_seed_reference_data.sql (tablas fiscal.TaxRate / fiscal.InvoiceType).
