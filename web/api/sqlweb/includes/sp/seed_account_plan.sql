-- =============================================
-- seed_account_plan.sql (modelo canónico)
-- Tabla destino: acct.Account
-- Idempotente por CompanyId + AccountCode
-- =============================================

SET NOCOUNT ON;

IF OBJECT_ID(N'acct.Account', N'U') IS NULL
BEGIN
    PRINT N'ERROR: Tabla acct.Account no existe. Ejecutar primero 03_accounting_core.sql';
    RETURN;
END

DECLARE @CompanyId INT;
SELECT TOP 1 @CompanyId = CompanyId
FROM cfg.Company
WHERE IsDeleted = 0
ORDER BY CASE WHEN CompanyCode = N'DEFAULT' THEN 0 ELSE 1 END, CompanyId;

IF @CompanyId IS NULL
BEGIN
    PRINT N'ERROR: No se encontró una compañía activa en cfg.Company';
    RETURN;
END

DECLARE @SystemUserId INT = NULL;
SELECT TOP 1 @SystemUserId = UserId
FROM sec.[User]
WHERE UserCode = N'SYSTEM' AND IsDeleted = 0;

DECLARE @PlanCuentas TABLE (
    accountCode NVARCHAR(40) NOT NULL,
    parentCode NVARCHAR(40) NULL,
    accountName NVARCHAR(200) NOT NULL,
    accountType NCHAR(1) NOT NULL,
    accountLevel INT NOT NULL,
    allowsPosting BIT NOT NULL,
    requiresAuxiliary BIT NOT NULL
);

INSERT INTO @PlanCuentas (accountCode, parentCode, accountName, accountType, accountLevel, allowsPosting, requiresAuxiliary)
VALUES
(N'1',       NULL,    N'ACTIVO',                            N'A', 1, 0, 0),
(N'2',       NULL,    N'PASIVO',                            N'P', 1, 0, 0),
(N'3',       NULL,    N'PATRIMONIO',                        N'C', 1, 0, 0),
(N'4',       NULL,    N'INGRESOS',                          N'I', 1, 0, 0),
(N'5',       NULL,    N'COSTOS Y GASTOS',                   N'G', 1, 0, 0),

(N'1.1',     N'1',    N'ACTIVO CORRIENTE',                  N'A', 2, 0, 0),
(N'1.2',     N'1',    N'ACTIVO NO CORRIENTE',               N'A', 2, 0, 0),
(N'2.1',     N'2',    N'PASIVO CORRIENTE',                  N'P', 2, 0, 0),
(N'2.2',     N'2',    N'PASIVO NO CORRIENTE',               N'P', 2, 0, 0),
(N'3.1',     N'3',    N'CAPITAL SOCIAL',                    N'C', 2, 0, 0),
(N'3.2',     N'3',    N'RESERVAS',                          N'C', 2, 0, 0),
(N'3.3',     N'3',    N'RESULTADOS ACUMULADOS',             N'C', 2, 0, 0),
(N'4.1',     N'4',    N'INGRESOS OPERACIONALES',            N'I', 2, 0, 0),
(N'4.2',     N'4',    N'INGRESOS NO OPERACIONALES',         N'I', 2, 0, 0),
(N'5.1',     N'5',    N'COSTO DE VENTAS',                   N'G', 2, 0, 0),
(N'5.2',     N'5',    N'GASTOS OPERACIONALES',              N'G', 2, 0, 0),
(N'5.3',     N'5',    N'GASTOS NO OPERACIONALES',           N'G', 2, 0, 0),

(N'1.1.01',  N'1.1',  N'CAJA',                              N'A', 3, 1, 0),
(N'1.1.02',  N'1.1',  N'BANCOS',                            N'A', 3, 1, 0),
(N'1.1.03',  N'1.1',  N'INVERSIONES TEMPORALES',            N'A', 3, 1, 0),
(N'1.1.04',  N'1.1',  N'CUENTAS POR COBRAR - CLIENTES',     N'A', 3, 1, 1),
(N'1.1.05',  N'1.1',  N'DOCUMENTOS POR COBRAR',             N'A', 3, 1, 0),
(N'1.1.06',  N'1.1',  N'INVENTARIOS',                       N'A', 3, 1, 0),
(N'1.1.07',  N'1.1',  N'IVA CREDITO FISCAL',                N'A', 3, 1, 0),
(N'1.1.08',  N'1.1',  N'ANTICIPOS A PROVEEDORES',           N'A', 3, 1, 0),
(N'1.1.09',  N'1.1',  N'RETENCIONES DE IVA POR COBRAR',     N'A', 3, 1, 0),
(N'1.2.01',  N'1.2',  N'PROPIEDAD PLANTA Y EQUIPO',         N'A', 3, 1, 0),
(N'1.2.02',  N'1.2',  N'DEPRECIACION ACUMULADA',            N'A', 3, 1, 0),
(N'1.2.03',  N'1.2',  N'INVERSIONES PERMANENTES',           N'A', 3, 1, 0),
(N'1.2.04',  N'1.2',  N'INTANGIBLES',                       N'A', 3, 1, 0),
(N'1.2.05',  N'1.2',  N'ACTIVOS DIFERIDOS',                 N'A', 3, 1, 0),

(N'2.1.01',  N'2.1',  N'CUENTAS POR PAGAR - PROVEEDORES',   N'P', 3, 1, 1),
(N'2.1.02',  N'2.1',  N'DOCUMENTOS POR PAGAR',              N'P', 3, 1, 0),
(N'2.1.03',  N'2.1',  N'IVA DEBITO FISCAL',                 N'P', 3, 1, 0),
(N'2.1.04',  N'2.1',  N'RETENCIONES DE IVA POR PAGAR',      N'P', 3, 1, 0),
(N'2.1.05',  N'2.1',  N'SUELDOS Y SALARIOS POR PAGAR',      N'P', 3, 1, 0),
(N'2.1.06',  N'2.1',  N'SSO POR PAGAR',                     N'P', 3, 1, 0),
(N'2.1.07',  N'2.1',  N'FAOV POR PAGAR',                    N'P', 3, 1, 0),
(N'2.1.08',  N'2.1',  N'ISLR RETENIDO POR PAGAR',           N'P', 3, 1, 0),
(N'2.1.09',  N'2.1',  N'ANTICIPOS DE CLIENTES',             N'P', 3, 1, 0),
(N'2.1.10',  N'2.1',  N'INTERESES POR PAGAR',               N'P', 3, 1, 0),
(N'2.2.01',  N'2.2',  N'BONOS Y DEBENTURES',                N'P', 3, 1, 0),
(N'2.2.02',  N'2.2',  N'HIPOTECAS POR PAGAR',               N'P', 3, 1, 0),
(N'2.2.03',  N'2.2',  N'PRESTACIONES SOCIALES',             N'P', 3, 1, 0),

(N'3.1.01',  N'3.1',  N'CAPITAL SUSCRITO Y PAGADO',         N'C', 3, 1, 0),
(N'3.1.02',  N'3.1',  N'CAPITAL POR SUSCRIBIR',             N'C', 3, 1, 0),
(N'3.2.01',  N'3.2',  N'RESERVA LEGAL',                     N'C', 3, 1, 0),
(N'3.2.02',  N'3.2',  N'RESERVA ESTATUTARIA',               N'C', 3, 1, 0),
(N'3.3.01',  N'3.3',  N'UTILIDADES ACUMULADAS',             N'C', 3, 1, 0),
(N'3.3.02',  N'3.3',  N'PERDIDAS ACUMULADAS',               N'C', 3, 1, 0),
(N'3.3.03',  N'3.3',  N'RESULTADO DEL EJERCICIO',           N'C', 3, 1, 0),

(N'4.1.01',  N'4.1',  N'VENTAS DE BIENES Y SERVICIOS',      N'I', 3, 1, 0),
(N'4.1.02',  N'4.1',  N'DESCUENTOS EN VENTAS',              N'I', 3, 1, 0),
(N'4.1.03',  N'4.1',  N'DEVOLUCIONES EN VENTAS',            N'I', 3, 1, 0),
(N'4.1.04',  N'4.1',  N'VENTAS EXENTAS',                    N'I', 3, 1, 0),
(N'4.1.05',  N'4.1',  N'EXPORTACIONES',                     N'I', 3, 1, 0),
(N'4.2.01',  N'4.2',  N'INTERESES GANADOS',                 N'I', 3, 1, 0),
(N'4.2.02',  N'4.2',  N'COMISIONES GANADAS',                N'I', 3, 1, 0),
(N'4.2.03',  N'4.2',  N'GANANCIAS EN CAMBIO',               N'I', 3, 1, 0),
(N'4.2.04',  N'4.2',  N'OTROS INGRESOS',                    N'I', 3, 1, 0),

(N'5.1.01',  N'5.1',  N'COSTO DE MERCADERIA VENDIDA',       N'G', 3, 1, 0),
(N'5.1.02',  N'5.1',  N'FLETES Y ACARREOS',                 N'G', 3, 1, 0),
(N'5.2.01',  N'5.2',  N'SUELDOS Y SALARIOS',                N'G', 3, 1, 0),
(N'5.2.02',  N'5.2',  N'PRESTACIONES SOCIALES',             N'G', 3, 1, 0),
(N'5.2.03',  N'5.2',  N'SSO PATRONAL',                      N'G', 3, 1, 0),
(N'5.2.04',  N'5.2',  N'FAOV PATRONAL',                     N'G', 3, 1, 0),
(N'5.2.05',  N'5.2',  N'UTILIDADES',                        N'G', 3, 1, 0),
(N'5.2.06',  N'5.2',  N'VACACIONES',                        N'G', 3, 1, 0),
(N'5.2.07',  N'5.2',  N'ALQUILERES',                        N'G', 3, 1, 0),
(N'5.2.08',  N'5.2',  N'SERVICIOS PUBLICOS',                N'G', 3, 1, 0),
(N'5.2.09',  N'5.2',  N'TELEFONIA Y COMUNICACIONES',        N'G', 3, 1, 0),
(N'5.2.10',  N'5.2',  N'DEPRECIACION Y AMORTIZACION',       N'G', 3, 1, 0),
(N'5.2.11',  N'5.2',  N'MATERIALES Y SUMINISTROS',          N'G', 3, 1, 0),
(N'5.2.12',  N'5.2',  N'PUBLICIDAD Y MERCADEO',             N'G', 3, 1, 0),
(N'5.2.13',  N'5.2',  N'MANTENIMIENTO Y REPARACIONES',      N'G', 3, 1, 0),
(N'5.2.14',  N'5.2',  N'SEGUROS',                           N'G', 3, 1, 0),
(N'5.2.15',  N'5.2',  N'GASTOS DE VIAJE Y REPRESENTACION',  N'G', 3, 1, 0),
(N'5.3.01',  N'5.3',  N'INTERESES PAGADOS',                 N'G', 3, 1, 0),
(N'5.3.02',  N'5.3',  N'COMISIONES BANCARIAS',              N'G', 3, 1, 0),
(N'5.3.03',  N'5.3',  N'PERDIDAS EN CAMBIO',                N'G', 3, 1, 0),
(N'5.3.04',  N'5.3',  N'OTROS GASTOS',                      N'G', 3, 1, 0);

MERGE acct.Account AS tgt
USING (
    SELECT @CompanyId AS CompanyId,
           p.accountCode,
           p.accountName,
           p.accountType,
           p.accountLevel,
           p.allowsPosting,
           p.requiresAuxiliary
    FROM @PlanCuentas p
) AS src
ON tgt.CompanyId = src.CompanyId
AND tgt.AccountCode = src.accountCode
WHEN MATCHED THEN
    UPDATE SET
        tgt.AccountName = src.accountName,
        tgt.AccountType = src.accountType,
        tgt.AccountLevel = src.accountLevel,
        tgt.AllowsPosting = src.allowsPosting,
        tgt.RequiresAuxiliary = src.requiresAuxiliary,
        tgt.IsActive = 1,
        tgt.UpdatedAt = SYSUTCDATETIME(),
        tgt.UpdatedByUserId = @SystemUserId,
        tgt.IsDeleted = 0,
        tgt.DeletedAt = NULL,
        tgt.DeletedByUserId = NULL
WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        CompanyId,
        AccountCode,
        AccountName,
        AccountType,
        AccountLevel,
        ParentAccountId,
        AllowsPosting,
        RequiresAuxiliary,
        IsActive,
        CreatedAt,
        UpdatedAt,
        CreatedByUserId,
        UpdatedByUserId,
        IsDeleted
    )
    VALUES (
        src.CompanyId,
        src.accountCode,
        src.accountName,
        src.accountType,
        src.accountLevel,
        NULL,
        src.allowsPosting,
        src.requiresAuxiliary,
        1,
        SYSUTCDATETIME(),
        SYSUTCDATETIME(),
        @SystemUserId,
        @SystemUserId,
        0
    );

UPDATE child
SET ParentAccountId = parent.AccountId,
    UpdatedAt = SYSUTCDATETIME(),
    UpdatedByUserId = @SystemUserId
FROM acct.Account child
INNER JOIN @PlanCuentas p ON p.accountCode = child.AccountCode
LEFT JOIN acct.Account parent
    ON parent.CompanyId = child.CompanyId
   AND parent.AccountCode = p.parentCode
WHERE child.CompanyId = @CompanyId
  AND (
      (p.parentCode IS NULL AND child.ParentAccountId IS NOT NULL)
      OR (p.parentCode IS NOT NULL AND (child.ParentAccountId IS NULL OR child.ParentAccountId <> parent.AccountId))
  );

DECLARE @Total INT;
SELECT @Total = COUNT(1)
FROM acct.Account
WHERE CompanyId = @CompanyId
  AND AccountCode IN (SELECT accountCode FROM @PlanCuentas);

PRINT N'seed_account_plan.sql: cuentas canónicas sincronizadas para CompanyId=' + CAST(@CompanyId AS NVARCHAR(20)) + N'. Total=' + CAST(@Total AS NVARCHAR(20));
GO
