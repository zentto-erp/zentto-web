-- ============================================================
-- zentto_dev — Seed data core (SQL Server 2012)
-- ============================================================
USE zentto_dev;
GO

-- ── Countries ───────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'VE')
  INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName, TimeZoneIana, CurrencySymbol)
  VALUES ('VE', 'Venezuela', 'VES', 'SENIAT', 'RIF', 'America/Caracas', N'Bs');
GO
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'ES')
  INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName, TimeZoneIana, CurrencySymbol)
  VALUES ('ES', N'España', 'EUR', 'AEAT', 'NIF', 'Europe/Madrid', N'€');
GO
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'CO')
  INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName, TimeZoneIana, CurrencySymbol)
  VALUES ('CO', 'Colombia', 'COP', 'DIAN', 'NIT', 'America/Bogota', N'$');
GO
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'MX')
  INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName, TimeZoneIana, CurrencySymbol)
  VALUES ('MX', N'México', 'MXN', 'SAT', 'RFC', 'America/Mexico_City', N'$');
GO
IF NOT EXISTS (SELECT 1 FROM cfg.Country WHERE CountryCode = 'US')
  INSERT INTO cfg.Country (CountryCode, CountryName, CurrencyCode, TaxAuthorityCode, FiscalIdName, TimeZoneIana, CurrencySymbol)
  VALUES ('US', 'United States', 'USD', 'IRS', 'EIN', 'America/New_York', N'$');
GO

-- ── System User ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = 'SYSTEM')
  INSERT INTO sec.[User] (UserCode, UserName, IsAdmin, IsActive, [Role])
  VALUES ('SYSTEM', 'System User', 1, 1, 'admin');
GO

-- ── Admin Role ──────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sec.[Role] WHERE RoleCode = 'ADMIN')
  INSERT INTO sec.[Role] (RoleCode, RoleName, IsSystem, IsActive)
  VALUES ('ADMIN', 'Administrators', 1, 1);
GO

-- ── UserRole ────────────────────────────────────────────────
DECLARE @sysUserId INT, @adminRoleId INT;
SELECT @sysUserId = UserId FROM sec.[User] WHERE UserCode = 'SYSTEM';
SELECT @adminRoleId = RoleId FROM sec.[Role] WHERE RoleCode = 'ADMIN';
IF @sysUserId IS NOT NULL AND @adminRoleId IS NOT NULL
  IF NOT EXISTS (SELECT 1 FROM sec.UserRole WHERE UserId = @sysUserId AND RoleId = @adminRoleId)
    INSERT INTO sec.UserRole (UserId, RoleId) VALUES (@sysUserId, @adminRoleId);
GO

-- ── Default Company ─────────────────────────────────────────
DECLARE @sysUid INT;
SELECT @sysUid = UserId FROM sec.[User] WHERE UserCode = 'SYSTEM';
IF NOT EXISTS (SELECT 1 FROM cfg.Company WHERE CompanyCode = 'DEFAULT')
  INSERT INTO cfg.Company (CompanyCode, LegalName, TradeName, FiscalCountryCode, FiscalId, BaseCurrency, CreatedByUserId, UpdatedByUserId)
  VALUES ('DEFAULT', 'Zentto Default Company', 'Zentto', 'VE', 'J-00000000-0', 'VES', @sysUid, @sysUid);
GO

-- ── Default Branch ──────────────────────────────────────────
DECLARE @compId INT, @sysUid2 INT;
SELECT @compId = CompanyId FROM cfg.Company WHERE CompanyCode = 'DEFAULT';
SELECT @sysUid2 = UserId FROM sec.[User] WHERE UserCode = 'SYSTEM';
IF @compId IS NOT NULL
  IF NOT EXISTS (SELECT 1 FROM cfg.Branch WHERE CompanyId = @compId AND BranchCode = 'MAIN')
    INSERT INTO cfg.Branch (CompanyId, BranchCode, BranchName, CreatedByUserId, UpdatedByUserId)
    VALUES (@compId, 'MAIN', 'Principal', @sysUid2, @sysUid2);
GO

-- ── Admin User (sa) ─────────────────────────────────────────
DECLARE @sysUid3 INT;
SELECT @sysUid3 = UserId FROM sec.[User] WHERE UserCode = 'SYSTEM';
IF NOT EXISTS (SELECT 1 FROM sec.[User] WHERE UserCode = 'sa')
  INSERT INTO sec.[User] (UserCode, UserName, PasswordHash, Email, IsAdmin, IsActive, [Role], CompanyId, CreatedByUserId, UpdatedByUserId)
  VALUES ('sa', 'Administrador', '$2b$10$LK8EVYEM3kPQdIiKWVBi.eG5Dlxy.f50JDJhCNnkHn07j0YRpPh0W',
          'admin@zentto.net', 1, 1, 'admin', 1, @sysUid3, @sysUid3);
GO

-- ── AuthIdentity for sa ─────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM sec.AuthIdentity WHERE UserCode = 'sa')
  INSERT INTO sec.AuthIdentity (UserCode, Email, EmailNormalized, EmailVerifiedAtUtc)
  VALUES ('sa', 'admin@zentto.net', 'admin@zentto.net', SYSUTCDATETIME());
GO

PRINT 'Seed core completado';
GO
