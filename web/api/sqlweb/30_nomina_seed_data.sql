/*  ═══════════════════════════════════════════════════════════════
    30_nomina_seed_data.sql — Seed: Tabla Empleados + datos de prueba
    ═══════════════════════════════════════════════════════════════ */
SET QUOTED_IDENTIFIER ON;
USE [DatqBoxWeb];
GO

-- ───────────────────────────────────────────────────────
-- 1. Crear tabla dbo.Empleados (legado VB6 compatible)
-- ───────────────────────────────────────────────────────
IF OBJECT_ID('dbo.Empleados', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Empleados (
        CEDULA        NVARCHAR(20)  NOT NULL PRIMARY KEY,
        GRUPO         NVARCHAR(50)  NULL,
        NOMBRE        NVARCHAR(100) NOT NULL,
        DIRECCION     NVARCHAR(255) NULL,
        TELEFONO      NVARCHAR(60)  NULL,
        NACIMIENTO    DATETIME      NULL,
        CARGO         NVARCHAR(50)  NULL,
        NOMINA        NVARCHAR(50)  NULL,
        SUELDO        FLOAT         NULL DEFAULT 0,
        INGRESO       DATETIME      NULL,
        RETIRO        DATETIME      NULL,
        STATUS        NVARCHAR(50)  NULL DEFAULT N'ACTIVO',
        COMISION      FLOAT         NULL DEFAULT 0,
        UTILIDAD      FLOAT         NULL DEFAULT 0,
        CO_Usuario    NVARCHAR(10)  NULL,
        SEXO          NVARCHAR(10)  NULL,
        NACIONALIDAD  NVARCHAR(50)  NULL,
        Autoriza      BIT           NOT NULL DEFAULT 0,
        Apodo         NVARCHAR(50)  NULL
    );
    PRINT 'Tabla dbo.Empleados creada';
END
ELSE
    PRINT 'Tabla dbo.Empleados ya existe';
GO

-- ───────────────────────────────────────────────────────
-- 2. Datos seed de empleados
-- ───────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM dbo.Empleados)
BEGIN
    PRINT 'Insertando empleados de prueba...';

    INSERT INTO dbo.Empleados (CEDULA, GRUPO, NOMBRE, DIRECCION, TELEFONO, NACIMIENTO, CARGO, NOMINA, SUELDO, INGRESO, RETIRO, STATUS, SEXO, NACIONALIDAD, Autoriza)
    VALUES
    -- Gerencia
    (N'V-12345678', N'GERENCIA', N'Carlos Alberto Mendoza Rivera', N'Av. Libertador, Edif. Torres del Sol, Piso 12, Caracas', N'0412-5551234', '19800315', N'Gerente General', N'MENSUAL', 8500.00, '20150110', NULL, N'ACTIVO', N'M', N'Venezolano', 1),
    (N'V-14567890', N'GERENCIA', N'Maria Fernanda Lopez Garcia', N'Urb. El Paraiso, Calle 5, Casa 22, Caracas', N'0414-5552345', '19850722', N'Gerente Administrativo', N'MENSUAL', 7200.00, '20160301', NULL, N'ACTIVO', N'F', N'Venezolano', 1),
    (N'V-16789012', N'GERENCIA', N'Roberto Jose Hernandez Diaz', N'Res. Los Samanes, Torre B, Apto 8-2, Valencia', N'0424-5553456', '19781108', N'Gerente de Ventas', N'MENSUAL', 7500.00, '20170615', NULL, N'ACTIVO', N'M', N'Venezolano', 1),

    -- Administracion
    (N'V-18901234', N'ADMIN', N'Ana Maria Rodriguez Perez', N'Calle Miranda, Edif. Central, Ofc 304, Maracaibo', N'0416-5554567', '19900125', N'Contadora', N'MENSUAL', 4800.00, '20180201', NULL, N'ACTIVO', N'F', N'Venezolano', 0),
    (N'V-20123456', N'ADMIN', N'Luis Eduardo Martinez Gomez', N'Av. Bolivar, Centro Comercial Lido, Nivel 2, Barquisimeto', N'0412-5555678', '19920510', N'Asistente Contable', N'MENSUAL', 3200.00, '20190815', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-21234567', N'ADMIN', N'Patricia Elena Sanchez Torres', N'Urb. La Floresta, Calle 10, Qta. Miraflores, Caracas', N'0414-5556789', '19880914', N'Analista de RRHH', N'MENSUAL', 4000.00, '20181101', NULL, N'ACTIVO', N'F', N'Venezolano', 0),
    (N'V-22345678', N'ADMIN', N'Jorge Antonio Ramirez Silva', N'Sector La Candelaria, Edif. Don Bosco, Piso 3, Caracas', N'0424-5557890', '19950228', N'Asistente Administrativo', N'MENSUAL', 2800.00, '20200301', NULL, N'ACTIVO', N'M', N'Venezolano', 0),

    -- Ventas
    (N'V-23456789', N'VENTAS', N'Carmen Rosa Gonzalez Blanco', N'Av. Fuerzas Armadas, Res. El Bosque, Torre 2, Caracas', N'0416-5558901', '19910618', N'Vendedor Senior', N'QUINCENAL', 3500.00, '20190115', NULL, N'ACTIVO', N'F', N'Venezolano', 0),
    (N'V-24567890', N'VENTAS', N'Pedro Luis Castillo Vargas', N'Calle Sucre, Casa 45, San Cristobal', N'0412-5559012', '19931203', N'Vendedor', N'QUINCENAL', 2800.00, '20200601', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-25678901', N'VENTAS', N'Diana Carolina Morales Jimenez', N'Urb. Los Palos Grandes, Edif. Altamira, Apto 5B, Caracas', N'0414-5550123', '19940820', N'Vendedor', N'QUINCENAL', 2800.00, '20210215', NULL, N'ACTIVO', N'F', N'Venezolano', 0),
    (N'V-26789012', N'VENTAS', N'Miguel Angel Torres Rojas', N'Av. Universidad, Centro Prof. del Este, Nivel 1, Caracas', N'0424-5551234', '19960411', N'Vendedor Junior', N'QUINCENAL', 2200.00, '20220110', NULL, N'ACTIVO', N'M', N'Venezolano', 0),

    -- Produccion / Operaciones
    (N'V-27890123', N'PRODUCCION', N'Juan Carlos Paredes Medina', N'Zona Industrial, Galpones El Progreso, Guarenas', N'0416-5552345', '19871030', N'Jefe de Produccion', N'SEMANAL', 4200.00, '20170401', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-28901234', N'PRODUCCION', N'Francisco Javier Romero Pena', N'Barrio Sucre, Calle Principal, Casa 12, Guarenas', N'0412-5553456', '19890322', N'Operador de Maquinas', N'SEMANAL', 2600.00, '20190515', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-29012345', N'PRODUCCION', N'Jose Gregorio Flores Rivas', N'Urb. El Marques, Edif. Las Acacias, Piso 2, Caracas', N'0414-5554567', '19910715', N'Operador de Maquinas', N'SEMANAL', 2600.00, '20200901', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-30123456', N'PRODUCCION', N'Andres Felipe Gutierrez Leon', N'Sector Los Teques, Calle Bolivar, Casa 8', N'0424-5555678', '19931105', N'Ayudante General', N'SEMANAL', 2000.00, '20210701', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-31234567', N'PRODUCCION', N'Yolanda Beatriz Contreras Arias', N'Av. Principal de Catia, Edif. Catia, Piso 6, Caracas', N'0416-5556789', '19900214', N'Inspector de Calidad', N'SEMANAL', 3000.00, '20191101', NULL, N'ACTIVO', N'F', N'Venezolano', 0),

    -- Almacen / Logistica
    (N'V-32345678', N'ALMACEN', N'Rafael Eduardo Acosta Duarte', N'Calle Comercio, Galpon 5, Zona Industrial Ruiz Pineda, Caracas', N'0412-5557890', '19860809', N'Jefe de Almacen', N'QUINCENAL', 3800.00, '20160901', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-33456789', N'ALMACEN', N'Nelson Jose Espinoza Paz', N'Barrio Union, Calle 3, Casa 15, Petare', N'0414-5558901', '19920120', N'Almacenista', N'QUINCENAL', 2400.00, '20200415', NULL, N'ACTIVO', N'M', N'Venezolano', 0),
    (N'V-34567890', N'ALMACEN', N'Gabriela Maria Suarez Vega', N'Res. Los Naranjos, Torre C, Apto 3-1, Caracas', N'0424-5559012', '19940627', N'Despachador', N'QUINCENAL', 2200.00, '20211001', NULL, N'ACTIVO', N'F', N'Venezolano', 0),

    -- Empleados inactivos / retirados
    (N'V-10111213', N'VENTAS', N'Ricardo Enrique Bravo Pino', N'Av. Las Americas, Edif. La Cumbre, Merida', N'0416-5550234', '19830412', N'Vendedor', N'QUINCENAL', 2500.00, '20170301', '20230630', N'RETIRADO', N'M', N'Venezolano', 0),
    (N'V-11121314', N'PRODUCCION', N'Marcos Antonio Delgado Rios', N'Urb. Montalban, Calle A, Casa 7, Caracas', N'0412-5551345', '19881225', N'Operador de Maquinas', N'SEMANAL', 2400.00, '20180615', '20221215', N'RETIRADO', N'M', N'Venezolano', 0),
    (N'V-12131415', N'ADMIN', N'Luisa Teresa Navarro Cruz', N'Sector Chacao, Edif. Libertador, Ofc 201, Caracas', N'0414-5552456', '19860930', N'Recepcionista', N'MENSUAL', 2000.00, '20160110', NULL, N'SUSPENDIDO', N'F', N'Venezolano', 0);

    PRINT 'Empleados de prueba insertados correctamente';
END
ELSE
    PRINT 'Ya existen empleados, seed omitido';
GO

-- ───────────────────────────────────────────────────────
-- 3. Verificacion
-- ───────────────────────────────────────────────────────
SELECT
    COUNT(*) AS TotalEmpleados,
    SUM(CASE WHEN STATUS = N'ACTIVO' THEN 1 ELSE 0 END) AS Activos,
    SUM(CASE WHEN STATUS = N'RETIRADO' THEN 1 ELSE 0 END) AS Retirados,
    SUM(CASE WHEN STATUS = N'SUSPENDIDO' THEN 1 ELSE 0 END) AS Suspendidos,
    COUNT(DISTINCT GRUPO) AS Grupos,
    COUNT(DISTINCT NOMINA) AS TiposNomina
FROM dbo.Empleados;

SELECT GRUPO, NOMINA, COUNT(*) AS Cant, AVG(SUELDO) AS SueldoPromedio
FROM dbo.Empleados
WHERE STATUS = N'ACTIVO'
GROUP BY GRUPO, NOMINA
ORDER BY GRUPO;
GO
