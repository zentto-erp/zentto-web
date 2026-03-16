-- ============================================================
-- Migración: Campos complementarios en master.Employee y cfg.Company
-- Fecha: 2026-03-16
-- PostgreSQL version
-- ============================================================

-- ── cfg."Company": Address, LegalRep, Phone ──────────────────
ALTER TABLE cfg."Company"
  ADD COLUMN IF NOT EXISTS "Address" VARCHAR(500) NULL,
  ADD COLUMN IF NOT EXISTS "LegalRep" VARCHAR(200) NULL,
  ADD COLUMN IF NOT EXISTS "Phone"   VARCHAR(50)  NULL;

-- ── master."Employee": PositionName, DepartmentName, Salary ──
ALTER TABLE master."Employee"
  ADD COLUMN IF NOT EXISTS "PositionName"   VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS "DepartmentName" VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS "Salary"         DECIMAL(18,2) NULL;
