-- =============================================
-- Tabla de conocimiento: conceptos por convencion y tipo de calculo
-- Base para poblar ConcNom y ConstanteNomina segun LOTTT y CCT Venezuela.
-- Ejecutar sobre la misma base que usa la nomina (ej. Sanjose).
-- =============================================

-- 1) Tabla: Convencion (LOT, CCT Petrolero, CCT Construccion)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NominaConvencion')
BEGIN
    CREATE TABLE dbo.NominaConvencion (
        Codigo        NVARCHAR(20) NOT NULL PRIMARY KEY,
        Nombre        NVARCHAR(100) NOT NULL,
        Descripcion   NVARCHAR(500) NULL,
        LOTTT_Base    NVARCHAR(200) NULL,
        Activo        BIT NOT NULL DEFAULT 1
    );
    INSERT INTO dbo.NominaConvencion (Codigo, Nombre, Descripcion, LOTTT_Base) VALUES
        ('LOT', N'LOT/LOTTT General', N'Régimen legal sin convenio colectivo específico', N'LOTTT 2012 arts. 142, 143, 189-203'),
        ('CCT_PETROLERO', N'CCT Petrolero', N'Convención Colectiva Petrolera (ej. 2011/2013, 2019/2021)', N'LOTTT + CCP Petrolero'),
        ('CCT_CONSTRUCCION', N'CCT Construcción', N'Convención Colectiva Industria de la Construcción', N'LOTTT + CCT Construcción');
    PRINT N'Tabla NominaConvencion creada.';
END
GO

-- 2) Tabla: Tipo de calculo (semanal, quincenal, mensual, vacaciones, liquidacion, utilidades)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NominaTipoCalculo')
BEGIN
    CREATE TABLE dbo.NominaTipoCalculo (
        Codigo      NVARCHAR(20) NOT NULL PRIMARY KEY,
        Nombre      NVARCHAR(80) NOT NULL,
        Descripcion NVARCHAR(255) NULL
    );
    INSERT INTO dbo.NominaTipoCalculo (Codigo, Nombre, Descripcion) VALUES
        ('SEMANAL', N'Nómina semanal', N'Periodo 7 días'),
        ('QUINCENAL', N'Nómina quincenal', N'Periodo 15 días'),
        ('MENSUAL', N'Nómina mensual', N'Periodo 30 días'),
        ('VACACIONES', N'Pago de vacaciones', N'Vacaciones + bono vacacional + bono post si aplica'),
        ('LIQUIDACION', N'Liquidación / Prestaciones', N'Prestaciones sociales, vacaciones no gozadas, utilidades, deducciones'),
        ('UTILIDADES', N'Utilidades', N'Participación en beneficios');
    PRINT N'Tabla NominaTipoCalculo creada.';
END
GO

-- 3) Tabla: Conceptos legales por convencion y tipo (base de conocimiento)
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NominaConceptoLegal')
BEGIN
    CREATE TABLE dbo.NominaConceptoLegal (
        Id              INT IDENTITY(1,1) PRIMARY KEY,
        Convencion      NVARCHAR(20) NOT NULL,
        TipoCalculo     NVARCHAR(20) NOT NULL,
        CO_CONCEPT      NVARCHAR(10) NOT NULL,
        NB_CONCEPTO     NVARCHAR(150) NOT NULL,
        FORMULA         NVARCHAR(500) NULL,
        SOBRE           NVARCHAR(255) NULL,
        TIPO            NVARCHAR(15) NOT NULL,
        BONIFICABLE     NVARCHAR(1) NULL DEFAULT 'S',
        LOTTT_Articulo  NVARCHAR(50) NULL,
        CCP_Clausula    NVARCHAR(50) NULL,
        Orden           INT NULL DEFAULT 0,
        Activo          BIT NOT NULL DEFAULT 1,
        CONSTRAINT FK_NominaConceptoLegal_Convencion FOREIGN KEY (Convencion) REFERENCES dbo.NominaConvencion(Codigo),
        CONSTRAINT FK_NominaConceptoLegal_Tipo FOREIGN KEY (TipoCalculo) REFERENCES dbo.NominaTipoCalculo(Codigo)
    );
    CREATE INDEX IX_NominaConceptoLegal_Conv_Tipo ON dbo.NominaConceptoLegal(Convencion, TipoCalculo);
    PRINT N'Tabla NominaConceptoLegal creada.';
END
GO
