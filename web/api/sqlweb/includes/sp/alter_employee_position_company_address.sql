-- ============================================================
-- Migración: Campos complementarios en master.Employee y cfg.Company
-- Fecha: 2026-03-16
-- Propósito: Soporte a plantillas de documentos (cargo, departamento,
--            dirección empresa, representante legal)
-- ============================================================

-- ── 1. cfg.Company: agregar Address, LegalRep, Phone ─────────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='cfg' AND TABLE_NAME='Company' AND COLUMN_NAME='Address')
    ALTER TABLE cfg.Company ADD Address NVARCHAR(500) NULL;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='cfg' AND TABLE_NAME='Company' AND COLUMN_NAME='LegalRep')
    ALTER TABLE cfg.Company ADD LegalRep NVARCHAR(200) NULL;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='cfg' AND TABLE_NAME='Company' AND COLUMN_NAME='Phone')
    ALTER TABLE cfg.Company ADD Phone NVARCHAR(50) NULL;

PRINT 'cfg.Company: Address, LegalRep, Phone OK';
GO

-- ── 2. master.Employee: agregar PositionName, DepartmentName, Salary ─────
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='master' AND TABLE_NAME='Employee' AND COLUMN_NAME='PositionName')
    ALTER TABLE [master].Employee ADD PositionName NVARCHAR(150) NULL;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='master' AND TABLE_NAME='Employee' AND COLUMN_NAME='DepartmentName')
    ALTER TABLE [master].Employee ADD DepartmentName NVARCHAR(150) NULL;

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_SCHEMA='master' AND TABLE_NAME='Employee' AND COLUMN_NAME='Salary')
    ALTER TABLE [master].Employee ADD Salary DECIMAL(18,2) NULL;

PRINT 'master.Employee: PositionName, DepartmentName, Salary OK';
GO

-- ── 3. Actualizar SP usp_HR_Employee_GetByCode ───────────────
ALTER PROCEDURE dbo.usp_HR_Employee_GetByCode
    @CompanyId INT,
    @Cedula    NVARCHAR(60)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1
        EmployeeCode, EmployeeName, FiscalId,
        HireDate, TerminationDate, IsActive,
        PositionName, DepartmentName, Salary
    FROM [master].Employee
    WHERE CompanyId    = @CompanyId
      AND EmployeeCode = @Cedula
      AND ISNULL(IsDeleted, 0) = 0;
END;
GO

PRINT 'usp_HR_Employee_GetByCode actualizado OK';
GO
