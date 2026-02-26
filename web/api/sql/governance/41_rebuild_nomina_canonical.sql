SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* Rebuild nomina domain (canonico) */

IF OBJECT_ID(N'dbo.NominaEmpleado', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaEmpleado (
    EmpleadoId INT IDENTITY(1,1) PRIMARY KEY,
    Cedula NVARCHAR(20) NOT NULL,
    Grupo NVARCHAR(50) NULL,
    NombreCompleto NVARCHAR(120) NOT NULL,
    Direccion NVARCHAR(255) NULL,
    Telefono NVARCHAR(60) NULL,
    FechaNacimiento DATE NULL,
    Cargo NVARCHAR(80) NULL,
    CodigoNomina NVARCHAR(15) NULL,
    SalarioBase DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaEmpleado_SalarioBase DEFAULT (0),
    FechaIngreso DATE NULL,
    FechaRetiro DATE NULL,
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_NominaEmpleado_Estado DEFAULT (N'ACTIVO'),
    ComisionPct DECIMAL(9,4) NULL,
    UtilidadPct DECIMAL(9,4) NULL,
    Sexo NVARCHAR(10) NULL,
    Nacionalidad NVARCHAR(50) NULL,
    AutorizaDescuento BIT NOT NULL CONSTRAINT DF_NominaEmpleado_Autoriza DEFAULT (0),
    Apodo NVARCHAR(50) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaEmpleado_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaEmpleado_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaEmpleado_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION
  );
  CREATE UNIQUE INDEX UX_NominaEmpleado_Cedula ON dbo.NominaEmpleado(Cedula);
END
GO

IF OBJECT_ID(N'dbo.NominaConcepto', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaConcepto (
    ConceptoId INT IDENTITY(1,1) PRIMARY KEY,
    CodigoConcepto NVARCHAR(20) NOT NULL,
    CodigoNomina NVARCHAR(15) NOT NULL,
    NombreConcepto NVARCHAR(120) NOT NULL,
    Formula NVARCHAR(255) NULL,
    Sobre NVARCHAR(255) NULL,
    Clase NVARCHAR(20) NULL,
    Tipo NVARCHAR(15) NOT NULL CONSTRAINT DF_NominaConcepto_Tipo DEFAULT (N'ASIGNACION'),
    Uso NVARCHAR(20) NULL,
    Bonificable CHAR(1) NULL,
    EsAntiguedad CHAR(1) NULL,
    CuentaContable NVARCHAR(50) NULL,
    Aplica CHAR(1) NOT NULL CONSTRAINT DF_NominaConcepto_Aplica DEFAULT ('S'),
    ValorDefecto DECIMAL(18,2) NULL,
    Activo BIT NOT NULL CONSTRAINT DF_NominaConcepto_Activo DEFAULT (1),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaConcepto_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaConcepto_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaConcepto_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION,
    CONSTRAINT UQ_NominaConcepto UNIQUE (CodigoNomina, CodigoConcepto)
  );
END
GO

IF OBJECT_ID(N'dbo.NominaConstante', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaConstante (
    ConstanteId INT IDENTITY(1,1) PRIMARY KEY,
    Codigo NVARCHAR(50) NOT NULL,
    Nombre NVARCHAR(100) NULL,
    Valor DECIMAL(18,6) NULL,
    Origen NVARCHAR(50) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaConstante_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaConstante_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaConstante_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION,
    CONSTRAINT UQ_NominaConstante_Codigo UNIQUE (Codigo)
  );
END
GO

IF OBJECT_ID(N'dbo.NominaRun', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaRun (
    RunId BIGINT IDENTITY(1,1) PRIMARY KEY,
    NominaCodigo NVARCHAR(10) NOT NULL,
    Cedula NVARCHAR(20) NOT NULL,
    TipoCalculo NVARCHAR(20) NOT NULL CONSTRAINT DF_NominaRun_TipoCalculo DEFAULT (N'MENSUAL'),
    FechaInicio DATE NOT NULL,
    FechaHasta DATE NOT NULL,
    FechaProceso DATETIME2(0) NOT NULL CONSTRAINT DF_NominaRun_FechaProceso DEFAULT SYSUTCDATETIME(),
    Cerrada BIT NOT NULL CONSTRAINT DF_NominaRun_Cerrada DEFAULT (0),
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_NominaRun_Estado DEFAULT (N'ABIERTA'),
    TotalAsignaciones DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaRun_Asig DEFAULT (0),
    TotalDeducciones DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaRun_Ded DEFAULT (0),
    TotalNeto DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaRun_Neto DEFAULT (0),
    UsuarioProceso NVARCHAR(20) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaRun_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaRun_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaRun_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION
  );
END
GO

IF OBJECT_ID(N'dbo.NominaRunDetalle', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaRunDetalle (
    DetalleId BIGINT IDENTITY(1,1) PRIMARY KEY,
    RunId BIGINT NOT NULL,
    CodigoConcepto NVARCHAR(20) NULL,
    NombreConcepto NVARCHAR(120) NOT NULL,
    TipoConcepto NVARCHAR(15) NOT NULL,
    Cantidad DECIMAL(18,4) NOT NULL CONSTRAINT DF_NominaRunDetalle_Cantidad DEFAULT (1),
    Monto DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaRunDetalle_Monto DEFAULT (0),
    Total DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaRunDetalle_Total DEFAULT (0),
    Descripcion NVARCHAR(255) NULL,
    CuentaContable NVARCHAR(50) NULL,
    Orden INT NOT NULL CONSTRAINT DF_NominaRunDetalle_Orden DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaRunDetalle_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaRunDetalle_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaRunDetalle_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION,
    CONSTRAINT FK_NominaRunDetalle_Run FOREIGN KEY (RunId) REFERENCES dbo.NominaRun(RunId)
  );
END
GO

IF OBJECT_ID(N'dbo.NominaVacacion', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaVacacion (
    VacacionId NVARCHAR(50) PRIMARY KEY,
    Cedula NVARCHAR(20) NOT NULL,
    FechaInicio DATE NOT NULL,
    FechaHasta DATE NOT NULL,
    FechaReintegro DATE NULL,
    FechaCalculo DATETIME2(0) NOT NULL CONSTRAINT DF_NominaVacacion_FechaCalculo DEFAULT SYSUTCDATETIME(),
    Total DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaVacacion_Total DEFAULT (0),
    TotalCalculado DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaVacacion_TotalCalc DEFAULT (0),
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_NominaVacacion_Estado DEFAULT (N'PROCESADA'),
    UsuarioProceso NVARCHAR(20) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaVacacion_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaVacacion_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaVacacion_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION
  );
END
GO

IF OBJECT_ID(N'dbo.NominaVacacionDetalle', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaVacacionDetalle (
    DetalleId BIGINT IDENTITY(1,1) PRIMARY KEY,
    VacacionId NVARCHAR(50) NOT NULL,
    CodigoConcepto NVARCHAR(20) NULL,
    NombreConcepto NVARCHAR(120) NOT NULL,
    TipoConcepto NVARCHAR(15) NOT NULL,
    Cantidad DECIMAL(18,4) NOT NULL CONSTRAINT DF_NominaVacacionDetalle_Cantidad DEFAULT (1),
    Monto DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaVacacionDetalle_Monto DEFAULT (0),
    Total DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaVacacionDetalle_Total DEFAULT (0),
    Descripcion NVARCHAR(255) NULL,
    CuentaContable NVARCHAR(50) NULL,
    Orden INT NOT NULL CONSTRAINT DF_NominaVacacionDetalle_Orden DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaVacacionDetalle_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaVacacionDetalle_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaVacacionDetalle_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION,
    CONSTRAINT FK_NominaVacacionDetalle_Vac FOREIGN KEY (VacacionId) REFERENCES dbo.NominaVacacion(VacacionId)
  );
END
GO

IF OBJECT_ID(N'dbo.NominaLiquidacion', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaLiquidacion (
    LiquidacionId NVARCHAR(50) PRIMARY KEY,
    Cedula NVARCHAR(20) NOT NULL,
    FechaRetiro DATE NOT NULL,
    CausaRetiro NVARCHAR(50) NULL,
    FechaCalculo DATETIME2(0) NOT NULL CONSTRAINT DF_NominaLiquidacion_FechaCalculo DEFAULT SYSUTCDATETIME(),
    TotalAsignaciones DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaLiquidacion_Asig DEFAULT (0),
    TotalDeducciones DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaLiquidacion_Ded DEFAULT (0),
    TotalNeto DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaLiquidacion_Neto DEFAULT (0),
    Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_NominaLiquidacion_Estado DEFAULT (N'PROCESADA'),
    UsuarioProceso NVARCHAR(20) NULL,
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaLiquidacion_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaLiquidacion_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaLiquidacion_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION
  );
END
GO

IF OBJECT_ID(N'dbo.NominaLiquidacionDetalle', N'U') IS NULL
BEGIN
  CREATE TABLE dbo.NominaLiquidacionDetalle (
    DetalleId BIGINT IDENTITY(1,1) PRIMARY KEY,
    LiquidacionId NVARCHAR(50) NOT NULL,
    CodigoConcepto NVARCHAR(20) NULL,
    NombreConcepto NVARCHAR(120) NOT NULL,
    TipoConcepto NVARCHAR(15) NOT NULL,
    Cantidad DECIMAL(18,4) NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_Cantidad DEFAULT (1),
    Monto DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_Monto DEFAULT (0),
    Total DECIMAL(18,2) NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_Total DEFAULT (0),
    Descripcion NVARCHAR(255) NULL,
    CuentaContable NVARCHAR(50) NULL,
    Orden INT NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_Orden DEFAULT (0),
    CreatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2(0) NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CreatedBy NVARCHAR(80) NULL,
    UpdatedBy NVARCHAR(80) NULL,
    IsDeleted BIT NOT NULL CONSTRAINT DF_NominaLiquidacionDetalle_IsDeleted DEFAULT (0),
    DeletedAt DATETIME2(0) NULL,
    DeletedBy NVARCHAR(80) NULL,
    RowVer ROWVERSION,
    CONSTRAINT FK_NominaLiquidacionDetalle_Liq FOREIGN KEY (LiquidacionId) REFERENCES dbo.NominaLiquidacion(LiquidacionId)
  );
END
GO

IF NOT EXISTS (SELECT 1 FROM dbo.NominaConstante WHERE Codigo = N'DIAS_MES')
  INSERT INTO dbo.NominaConstante (Codigo, Nombre, Valor, Origen, CreatedBy, UpdatedBy)
  VALUES (N'DIAS_MES', N'Dias base para calculo diario', 30, N'SISTEMA', N'SISTEMA', N'SISTEMA');

IF NOT EXISTS (SELECT 1 FROM dbo.NominaConstante WHERE Codigo = N'VAC_BONO_FACTOR')
  INSERT INTO dbo.NominaConstante (Codigo, Nombre, Valor, Origen, CreatedBy, UpdatedBy)
  VALUES (N'VAC_BONO_FACTOR', N'Factor bono vacacional sobre base', 0.33, N'SISTEMA', N'SISTEMA', N'SISTEMA');

IF NOT EXISTS (SELECT 1 FROM dbo.NominaConstante WHERE Codigo = N'LIQ_PREST_FACTOR')
  INSERT INTO dbo.NominaConstante (Codigo, Nombre, Valor, Origen, CreatedBy, UpdatedBy)
  VALUES (N'LIQ_PREST_FACTOR', N'Factor prestaciones para liquidacion', 0.50, N'SISTEMA', N'SISTEMA', N'SISTEMA');
GO

-- drop procs for recreate (compat old SQL Server)
IF OBJECT_ID(N'dbo.usp_Empleados_List', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_Empleados_List;
IF OBJECT_ID(N'dbo.usp_Empleados_GetByCedula', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_Empleados_GetByCedula;
IF OBJECT_ID(N'dbo.usp_Empleados_Insert', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_Empleados_Insert;
IF OBJECT_ID(N'dbo.usp_Empleados_Update', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_Empleados_Update;
IF OBJECT_ID(N'dbo.usp_Empleados_Delete', N'P') IS NOT NULL DROP PROCEDURE dbo.usp_Empleados_Delete;
IF OBJECT_ID(N'dbo.sp_Nomina_Conceptos_List', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Conceptos_List;
IF OBJECT_ID(N'dbo.sp_Nomina_Concepto_Save', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Concepto_Save;
IF OBJECT_ID(N'dbo.sp_Nomina_ProcesarEmpleado', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarEmpleado;
IF OBJECT_ID(N'dbo.sp_Nomina_ProcesarNomina', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarNomina;
IF OBJECT_ID(N'dbo.sp_Nomina_List', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_List;
IF OBJECT_ID(N'dbo.sp_Nomina_Get', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Get;
IF OBJECT_ID(N'dbo.sp_Nomina_Cerrar', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Cerrar;
IF OBJECT_ID(N'dbo.sp_Nomina_ProcesarVacaciones', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarVacaciones;
IF OBJECT_ID(N'dbo.sp_Nomina_Vacaciones_List', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Vacaciones_List;
IF OBJECT_ID(N'dbo.sp_Nomina_Vacaciones_Get', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Vacaciones_Get;
IF OBJECT_ID(N'dbo.sp_Nomina_CalcularLiquidacion', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CalcularLiquidacion;
IF OBJECT_ID(N'dbo.sp_Nomina_Liquidaciones_List', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Liquidaciones_List;
IF OBJECT_ID(N'dbo.sp_Nomina_GetLiquidacion', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_GetLiquidacion;
IF OBJECT_ID(N'dbo.sp_Nomina_Constantes_List', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Constantes_List;
IF OBJECT_ID(N'dbo.sp_Nomina_Constante_Save', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_Constante_Save;
IF OBJECT_ID(N'dbo.sp_Nomina_ConceptosLegales_List', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ConceptosLegales_List;
IF OBJECT_ID(N'dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal;
IF OBJECT_ID(N'dbo.sp_Nomina_ValidarFormulasConceptoLegal', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_ValidarFormulasConceptoLegal;
IF OBJECT_ID(N'dbo.sp_Nomina_CopiarConceptosDesdeLegal', N'P') IS NOT NULL DROP PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal;
GO
CREATE PROCEDURE dbo.usp_Empleados_List
  @Search NVARCHAR(100) = NULL,
  @Grupo NVARCHAR(50) = NULL,
  @Status NVARCHAR(50) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1)-1) * ISNULL(NULLIF(@Limit,0),50);
  IF @Offset < 0 SET @Offset = 0;
  IF @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @SearchLike NVARCHAR(120) = NULL;
  IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
    SET @SearchLike = N'%' + LTRIM(RTRIM(@Search)) + N'%';

  SELECT @TotalCount = COUNT(1)
  FROM dbo.NominaEmpleado e
  WHERE e.IsDeleted = 0
    AND (@SearchLike IS NULL OR e.Cedula LIKE @SearchLike OR e.NombreCompleto LIKE @SearchLike OR e.Cargo LIKE @SearchLike)
    AND (@Grupo IS NULL OR LTRIM(RTRIM(@Grupo)) = N'' OR e.Grupo = @Grupo)
    AND (@Status IS NULL OR LTRIM(RTRIM(@Status)) = N'' OR e.Estado = @Status);

  SELECT
    CEDULA = e.Cedula,
    GRUPO = e.Grupo,
    NOMBRE = e.NombreCompleto,
    DIRECCION = e.Direccion,
    TELEFONO = e.Telefono,
    NACIMIENTO = e.FechaNacimiento,
    CARGO = e.Cargo,
    NOMINA = e.CodigoNomina,
    SUELDO = e.SalarioBase,
    INGRESO = e.FechaIngreso,
    RETIRO = e.FechaRetiro,
    STATUS = e.Estado,
    COMISION = e.ComisionPct,
    UTILIDAD = e.UtilidadPct,
    CO_Usuario = COALESCE(e.UpdatedBy, e.CreatedBy),
    SEXO = e.Sexo,
    NACIONALIDAD = e.Nacionalidad,
    Autoriza = e.AutorizaDescuento,
    Apodo = e.Apodo
  FROM dbo.NominaEmpleado e
  WHERE e.IsDeleted = 0
    AND (@SearchLike IS NULL OR e.Cedula LIKE @SearchLike OR e.NombreCompleto LIKE @SearchLike OR e.Cargo LIKE @SearchLike)
    AND (@Grupo IS NULL OR LTRIM(RTRIM(@Grupo)) = N'' OR e.Grupo = @Grupo)
    AND (@Status IS NULL OR LTRIM(RTRIM(@Status)) = N'' OR e.Estado = @Status)
  ORDER BY e.NombreCompleto
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE PROCEDURE dbo.usp_Empleados_GetByCedula
  @Cedula NVARCHAR(20)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT TOP 1
    CEDULA = e.Cedula,
    GRUPO = e.Grupo,
    NOMBRE = e.NombreCompleto,
    DIRECCION = e.Direccion,
    TELEFONO = e.Telefono,
    NACIMIENTO = e.FechaNacimiento,
    CARGO = e.Cargo,
    NOMINA = e.CodigoNomina,
    SUELDO = e.SalarioBase,
    INGRESO = e.FechaIngreso,
    RETIRO = e.FechaRetiro,
    STATUS = e.Estado,
    COMISION = e.ComisionPct,
    UTILIDAD = e.UtilidadPct,
    CO_Usuario = COALESCE(e.UpdatedBy, e.CreatedBy),
    SEXO = e.Sexo,
    NACIONALIDAD = e.Nacionalidad,
    Autoriza = e.AutorizaDescuento,
    Apodo = e.Apodo
  FROM dbo.NominaEmpleado e
  WHERE e.IsDeleted = 0 AND e.Cedula = @Cedula;
END
GO

CREATE PROCEDURE dbo.usp_Empleados_Insert
  @RowXml NVARCHAR(MAX),
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @xml XML = CAST(@RowXml AS XML);
  SET @Resultado = 0;
  SET @Mensaje = N'';

  IF @xml IS NULL
  BEGIN
    SET @Resultado = -98;
    SET @Mensaje = N'RowXml invalido';
    RETURN;
  END

  DECLARE
    @Cedula NVARCHAR(20) = NULLIF(@xml.value('(/row/@CEDULA)[1]', 'NVARCHAR(20)'), N''),
    @Nombre NVARCHAR(120) = NULLIF(@xml.value('(/row/@NOMBRE)[1]', 'NVARCHAR(120)'), N''),
    @Grupo NVARCHAR(50) = NULLIF(@xml.value('(/row/@GRUPO)[1]', 'NVARCHAR(50)'), N''),
    @Direccion NVARCHAR(255) = NULLIF(@xml.value('(/row/@DIRECCION)[1]', 'NVARCHAR(255)'), N''),
    @Telefono NVARCHAR(60) = NULLIF(@xml.value('(/row/@TELEFONO)[1]', 'NVARCHAR(60)'), N''),
    @Cargo NVARCHAR(80) = NULLIF(@xml.value('(/row/@CARGO)[1]', 'NVARCHAR(80)'), N''),
    @Nomina NVARCHAR(15) = NULLIF(@xml.value('(/row/@NOMINA)[1]', 'NVARCHAR(15)'), N''),
    @Estado NVARCHAR(20) = COALESCE(NULLIF(@xml.value('(/row/@STATUS)[1]', 'NVARCHAR(20)'), N''), N'ACTIVO'),
    @Sexo NVARCHAR(10) = NULLIF(@xml.value('(/row/@SEXO)[1]', 'NVARCHAR(10)'), N''),
    @Nacionalidad NVARCHAR(50) = NULLIF(@xml.value('(/row/@NACIONALIDAD)[1]', 'NVARCHAR(50)'), N''),
    @Apodo NVARCHAR(50) = NULLIF(@xml.value('(/row/@Apodo)[1]', 'NVARCHAR(50)'), N''),
    @CoUsuario NVARCHAR(80) = COALESCE(NULLIF(@xml.value('(/row/@CO_Usuario)[1]', 'NVARCHAR(80)'), N''), N'API');

  DECLARE
    @Salario DECIMAL(18,2) = CASE WHEN ISNUMERIC(NULLIF(@xml.value('(/row/@SUELDO)[1]', 'NVARCHAR(60)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@SUELDO)[1]', 'NVARCHAR(60)'), N'') AS DECIMAL(18,2)) ELSE NULL END,
    @Comision DECIMAL(9,4) = CASE WHEN ISNUMERIC(NULLIF(@xml.value('(/row/@COMISION)[1]', 'NVARCHAR(60)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@COMISION)[1]', 'NVARCHAR(60)'), N'') AS DECIMAL(9,4)) ELSE NULL END,
    @Utilidad DECIMAL(9,4) = CASE WHEN ISNUMERIC(NULLIF(@xml.value('(/row/@UTILIDAD)[1]', 'NVARCHAR(60)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@UTILIDAD)[1]', 'NVARCHAR(60)'), N'') AS DECIMAL(9,4)) ELSE NULL END,
    @FechaNacimiento DATE = CASE 
      WHEN ISDATE(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N'') AS DATE)
      WHEN ISDATE(REPLACE(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N''), N'-', N'')) = 1 THEN CAST(REPLACE(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N''), N'-', N'') AS DATE)
      ELSE NULL END,
    @FechaIngreso DATE = CASE 
      WHEN ISDATE(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N'') AS DATE)
      WHEN ISDATE(REPLACE(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N''), N'-', N'')) = 1 THEN CAST(REPLACE(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N''), N'-', N'') AS DATE)
      ELSE NULL END,
    @FechaRetiro DATE = CASE 
      WHEN ISDATE(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N'') AS DATE)
      WHEN ISDATE(REPLACE(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N''), N'-', N'')) = 1 THEN CAST(REPLACE(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N''), N'-', N'') AS DATE)
      ELSE NULL END,
    @Autoriza BIT = CASE WHEN NULLIF(@xml.value('(/row/@Autoriza)[1]', 'NVARCHAR(10)'), N'') IN (N'0', N'1') THEN CAST(NULLIF(@xml.value('(/row/@Autoriza)[1]', 'NVARCHAR(10)'), N'') AS BIT) ELSE NULL END;

  IF @Cedula IS NULL OR @Nombre IS NULL
  BEGIN
    SET @Resultado = -2;
    SET @Mensaje = N'CEDULA y NOMBRE son requeridos';
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.NominaEmpleado WHERE Cedula = @Cedula AND IsDeleted = 0)
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'Empleado ya existe';
    RETURN;
  END

  INSERT INTO dbo.NominaEmpleado
  (Cedula, Grupo, NombreCompleto, Direccion, Telefono, FechaNacimiento, Cargo, CodigoNomina, SalarioBase, FechaIngreso, FechaRetiro, Estado, ComisionPct, UtilidadPct, Sexo, Nacionalidad, AutorizaDescuento, Apodo, CreatedBy, UpdatedBy)
  VALUES
  (@Cedula, @Grupo, @Nombre, @Direccion, @Telefono, @FechaNacimiento, @Cargo, @Nomina, COALESCE(@Salario,0), @FechaIngreso, @FechaRetiro, @Estado, @Comision, @Utilidad, @Sexo, @Nacionalidad, COALESCE(@Autoriza,0), @Apodo, @CoUsuario, @CoUsuario);

  SET @Resultado = 1;
  SET @Mensaje = N'OK';
END
GO

CREATE PROCEDURE dbo.usp_Empleados_Update
  @Cedula NVARCHAR(20),
  @RowXml NVARCHAR(MAX),
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @xml XML = CAST(@RowXml AS XML);
  SET @Resultado = 0;
  SET @Mensaje = N'';

  IF @xml IS NULL
  BEGIN
    SET @Resultado = -98;
    SET @Mensaje = N'RowXml invalido';
    RETURN;
  END

  IF NOT EXISTS (SELECT 1 FROM dbo.NominaEmpleado WHERE Cedula = @Cedula AND IsDeleted = 0)
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'Empleado no encontrado';
    RETURN;
  END

  UPDATE e
  SET
    Grupo = COALESCE(NULLIF(@xml.value('(/row/@GRUPO)[1]', 'NVARCHAR(50)'), N''), e.Grupo),
    NombreCompleto = COALESCE(NULLIF(@xml.value('(/row/@NOMBRE)[1]', 'NVARCHAR(120)'), N''), e.NombreCompleto),
    Direccion = COALESCE(NULLIF(@xml.value('(/row/@DIRECCION)[1]', 'NVARCHAR(255)'), N''), e.Direccion),
    Telefono = COALESCE(NULLIF(@xml.value('(/row/@TELEFONO)[1]', 'NVARCHAR(60)'), N''), e.Telefono),
    FechaNacimiento = COALESCE(CASE 
      WHEN ISDATE(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N'') AS DATE)
      WHEN ISDATE(REPLACE(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N''), N'-', N'')) = 1 THEN CAST(REPLACE(NULLIF(@xml.value('(/row/@NACIMIENTO)[1]', 'NVARCHAR(40)'), N''), N'-', N'') AS DATE)
      ELSE NULL END, e.FechaNacimiento),
    Cargo = COALESCE(NULLIF(@xml.value('(/row/@CARGO)[1]', 'NVARCHAR(80)'), N''), e.Cargo),
    CodigoNomina = COALESCE(NULLIF(@xml.value('(/row/@NOMINA)[1]', 'NVARCHAR(15)'), N''), e.CodigoNomina),
    SalarioBase = COALESCE(CASE WHEN ISNUMERIC(NULLIF(@xml.value('(/row/@SUELDO)[1]', 'NVARCHAR(60)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@SUELDO)[1]', 'NVARCHAR(60)'), N'') AS DECIMAL(18,2)) ELSE NULL END, e.SalarioBase),
    FechaIngreso = COALESCE(CASE 
      WHEN ISDATE(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N'') AS DATE)
      WHEN ISDATE(REPLACE(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N''), N'-', N'')) = 1 THEN CAST(REPLACE(NULLIF(@xml.value('(/row/@INGRESO)[1]', 'NVARCHAR(40)'), N''), N'-', N'') AS DATE)
      ELSE NULL END, e.FechaIngreso),
    FechaRetiro = COALESCE(CASE 
      WHEN ISDATE(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N'') AS DATE)
      WHEN ISDATE(REPLACE(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N''), N'-', N'')) = 1 THEN CAST(REPLACE(NULLIF(@xml.value('(/row/@RETIRO)[1]', 'NVARCHAR(40)'), N''), N'-', N'') AS DATE)
      ELSE NULL END, e.FechaRetiro),
    Estado = COALESCE(NULLIF(@xml.value('(/row/@STATUS)[1]', 'NVARCHAR(20)'), N''), e.Estado),
    ComisionPct = COALESCE(CASE WHEN ISNUMERIC(NULLIF(@xml.value('(/row/@COMISION)[1]', 'NVARCHAR(60)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@COMISION)[1]', 'NVARCHAR(60)'), N'') AS DECIMAL(9,4)) ELSE NULL END, e.ComisionPct),
    UtilidadPct = COALESCE(CASE WHEN ISNUMERIC(NULLIF(@xml.value('(/row/@UTILIDAD)[1]', 'NVARCHAR(60)'), N'')) = 1 THEN CAST(NULLIF(@xml.value('(/row/@UTILIDAD)[1]', 'NVARCHAR(60)'), N'') AS DECIMAL(9,4)) ELSE NULL END, e.UtilidadPct),
    Sexo = COALESCE(NULLIF(@xml.value('(/row/@SEXO)[1]', 'NVARCHAR(10)'), N''), e.Sexo),
    Nacionalidad = COALESCE(NULLIF(@xml.value('(/row/@NACIONALIDAD)[1]', 'NVARCHAR(50)'), N''), e.Nacionalidad),
    AutorizaDescuento = COALESCE(CASE WHEN NULLIF(@xml.value('(/row/@Autoriza)[1]', 'NVARCHAR(10)'), N'') IN (N'0', N'1') THEN CAST(NULLIF(@xml.value('(/row/@Autoriza)[1]', 'NVARCHAR(10)'), N'') AS BIT) ELSE NULL END, e.AutorizaDescuento),
    Apodo = COALESCE(NULLIF(@xml.value('(/row/@Apodo)[1]', 'NVARCHAR(50)'), N''), e.Apodo),
    UpdatedAt = SYSUTCDATETIME(),
    UpdatedBy = COALESCE(NULLIF(@xml.value('(/row/@CO_Usuario)[1]', 'NVARCHAR(80)'), N''), N'API')
  FROM dbo.NominaEmpleado e
  WHERE e.Cedula = @Cedula AND e.IsDeleted = 0;

  SET @Resultado = 1;
  SET @Mensaje = N'OK';
END
GO

CREATE PROCEDURE dbo.usp_Empleados_Delete
  @Cedula NVARCHAR(20),
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje = N'';

  IF NOT EXISTS (SELECT 1 FROM dbo.NominaEmpleado WHERE Cedula = @Cedula AND IsDeleted = 0)
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'Empleado no encontrado';
    RETURN;
  END

  UPDATE dbo.NominaEmpleado
  SET IsDeleted = 1, Estado = N'INACTIVO', DeletedAt = SYSUTCDATETIME(), DeletedBy = N'API', UpdatedAt = SYSUTCDATETIME(), UpdatedBy = N'API'
  WHERE Cedula = @Cedula AND IsDeleted = 0;

  SET @Resultado = 1;
  SET @Mensaje = N'OK';
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Conceptos_List
  @CoNomina NVARCHAR(15) = NULL,
  @Tipo NVARCHAR(15) = NULL,
  @Search NVARCHAR(100) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1)-1) * ISNULL(NULLIF(@Limit,0),50);
  IF @Offset < 0 SET @Offset = 0;
  IF @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  DECLARE @SearchLike NVARCHAR(120) = NULL;
  IF @Search IS NOT NULL AND LTRIM(RTRIM(@Search)) <> N''
    SET @SearchLike = N'%' + LTRIM(RTRIM(@Search)) + N'%';

  SELECT @TotalCount = COUNT(1)
  FROM dbo.NominaConcepto c
  WHERE c.IsDeleted = 0
    AND c.Activo = 1
    AND (@CoNomina IS NULL OR LTRIM(RTRIM(@CoNomina)) = N'' OR c.CodigoNomina = @CoNomina)
    AND (@Tipo IS NULL OR LTRIM(RTRIM(@Tipo)) = N'' OR c.Tipo = @Tipo)
    AND (@SearchLike IS NULL OR c.CodigoConcepto LIKE @SearchLike OR c.NombreConcepto LIKE @SearchLike);

  SELECT
    codigo = c.CodigoConcepto,
    codigoNomina = c.CodigoNomina,
    nombre = c.NombreConcepto,
    formula = c.Formula,
    sobre = c.Sobre,
    clase = c.Clase,
    tipo = c.Tipo,
    uso = c.Uso,
    bonificable = c.Bonificable,
    esAntiguedad = c.EsAntiguedad,
    cuentaContable = c.CuentaContable,
    aplica = c.Aplica,
    valorDefecto = c.ValorDefecto
  FROM dbo.NominaConcepto c
  WHERE c.IsDeleted = 0
    AND c.Activo = 1
    AND (@CoNomina IS NULL OR LTRIM(RTRIM(@CoNomina)) = N'' OR c.CodigoNomina = @CoNomina)
    AND (@Tipo IS NULL OR LTRIM(RTRIM(@Tipo)) = N'' OR c.Tipo = @Tipo)
    AND (@SearchLike IS NULL OR c.CodigoConcepto LIKE @SearchLike OR c.NombreConcepto LIKE @SearchLike)
  ORDER BY c.CodigoNomina, c.CodigoConcepto
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Concepto_Save
  @CoConcept NVARCHAR(10),
  @CoNomina NVARCHAR(15),
  @NbConcepto NVARCHAR(100),
  @Formula NVARCHAR(255) = NULL,
  @Sobre NVARCHAR(255) = NULL,
  @Clase NVARCHAR(15) = NULL,
  @Tipo NVARCHAR(15) = NULL,
  @Uso NVARCHAR(15) = NULL,
  @Bonificable NVARCHAR(1) = NULL,
  @Antiguedad NVARCHAR(1) = NULL,
  @Contable NVARCHAR(50) = NULL,
  @Aplica NVARCHAR(1) = N'S',
  @Defecto FLOAT = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje = N'';

  IF @CoConcept IS NULL OR @CoNomina IS NULL OR @NbConcepto IS NULL
  BEGIN
    SET @Resultado = -2;
    SET @Mensaje = N'Datos requeridos incompletos';
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.NominaConcepto WHERE CodigoNomina = @CoNomina AND CodigoConcepto = @CoConcept AND IsDeleted = 0)
  BEGIN
    UPDATE dbo.NominaConcepto
    SET NombreConcepto=@NbConcepto, Formula=@Formula, Sobre=@Sobre, Clase=@Clase, Tipo=COALESCE(@Tipo,Tipo), Uso=@Uso,
        Bonificable=@Bonificable, EsAntiguedad=@Antiguedad, CuentaContable=@Contable, Aplica=COALESCE(@Aplica,Aplica),
        ValorDefecto=CASE WHEN ISNUMERIC(CAST(@Defecto AS NVARCHAR(100)))=1 THEN CAST(@Defecto AS DECIMAL(18,2)) ELSE NULL END, UpdatedAt=SYSUTCDATETIME(), UpdatedBy=N'API'
    WHERE CodigoNomina = @CoNomina AND CodigoConcepto = @CoConcept AND IsDeleted = 0;
  END
  ELSE
  BEGIN
    INSERT INTO dbo.NominaConcepto
    (CodigoConcepto,CodigoNomina,NombreConcepto,Formula,Sobre,Clase,Tipo,Uso,Bonificable,EsAntiguedad,CuentaContable,Aplica,ValorDefecto,CreatedBy,UpdatedBy)
    VALUES
    (@CoConcept,@CoNomina,@NbConcepto,@Formula,@Sobre,@Clase,COALESCE(@Tipo,N'ASIGNACION'),@Uso,@Bonificable,@Antiguedad,@Contable,COALESCE(@Aplica,N'S'),CASE WHEN ISNUMERIC(CAST(@Defecto AS NVARCHAR(100)))=1 THEN CAST(@Defecto AS DECIMAL(18,2)) ELSE NULL END,N'API',N'API');
  END

  SET @Resultado = 1;
  SET @Mensaje = N'OK';
END
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarEmpleado
  @Nomina NVARCHAR(10),
  @Cedula NVARCHAR(12),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @CoUsuario NVARCHAR(20) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje = N'';

  DECLARE @SalarioBase DECIMAL(18,2);
  SELECT @SalarioBase = COALESCE(SalarioBase,0) FROM dbo.NominaEmpleado WHERE Cedula=@Cedula AND IsDeleted=0;
  IF @SalarioBase IS NULL
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'Empleado no encontrado';
    RETURN;
  END

  DECLARE @RunId BIGINT;
  SELECT @RunId = RunId FROM dbo.NominaRun WHERE NominaCodigo=@Nomina AND Cedula=@Cedula AND TipoCalculo=N'MENSUAL' AND FechaInicio=@FechaInicio AND FechaHasta=@FechaHasta AND IsDeleted=0;

  IF @RunId IS NULL
  BEGIN
    INSERT INTO dbo.NominaRun (NominaCodigo,Cedula,TipoCalculo,FechaInicio,FechaHasta,UsuarioProceso,CreatedBy,UpdatedBy)
    VALUES (@Nomina,@Cedula,N'MENSUAL',@FechaInicio,@FechaHasta,@CoUsuario,@CoUsuario,@CoUsuario);
    SET @RunId = SCOPE_IDENTITY();
  END
  ELSE
  BEGIN
    UPDATE dbo.NominaRun SET FechaProceso=SYSUTCDATETIME(), UsuarioProceso=@CoUsuario, Cerrada=0, Estado=N'ABIERTA', UpdatedAt=SYSUTCDATETIME(), UpdatedBy=@CoUsuario WHERE RunId=@RunId;
    DELETE FROM dbo.NominaRunDetalle WHERE RunId=@RunId;
  END

  INSERT INTO dbo.NominaRunDetalle
  (RunId,CodigoConcepto,NombreConcepto,TipoConcepto,Cantidad,Monto,Total,Descripcion,CuentaContable,Orden,CreatedBy,UpdatedBy)
  SELECT
    @RunId,
    c.CodigoConcepto,
    c.NombreConcepto,
    UPPER(COALESCE(c.Tipo,N'ASIGNACION')),
    1,
    COALESCE(CASE WHEN ISNUMERIC(REPLACE(c.Formula, ',', '.')) = 1 THEN CAST(REPLACE(c.Formula, ',', '.') AS DECIMAL(18,2)) ELSE NULL END, c.ValorDefecto,
      CASE WHEN UPPER(COALESCE(c.Tipo,N''))=N'DEDUCCION' THEN ROUND(@SalarioBase*0.04,2)
           WHEN UPPER(COALESCE(c.Tipo,N''))=N'BONO' THEN ROUND(@SalarioBase*0.10,2)
           ELSE ROUND(@SalarioBase*0.20,2) END),
    COALESCE(CASE WHEN ISNUMERIC(REPLACE(c.Formula, ',', '.')) = 1 THEN CAST(REPLACE(c.Formula, ',', '.') AS DECIMAL(18,2)) ELSE NULL END, c.ValorDefecto,
      CASE WHEN UPPER(COALESCE(c.Tipo,N''))=N'DEDUCCION' THEN ROUND(@SalarioBase*0.04,2)
           WHEN UPPER(COALESCE(c.Tipo,N''))=N'BONO' THEN ROUND(@SalarioBase*0.10,2)
           ELSE ROUND(@SalarioBase*0.20,2) END),
    CONCAT(N'Concepto ', c.CodigoConcepto),
    c.CuentaContable,
    ROW_NUMBER() OVER (ORDER BY c.CodigoConcepto),
    @CoUsuario,
    @CoUsuario
  FROM dbo.NominaConcepto c
  WHERE c.IsDeleted=0 AND c.Activo=1 AND c.CodigoNomina=@Nomina;

  UPDATE r
  SET TotalAsignaciones = COALESCE(s.Asig,0), TotalDeducciones = COALESCE(s.Ded,0), TotalNeto = COALESCE(s.Asig,0)-COALESCE(s.Ded,0), UpdatedAt=SYSUTCDATETIME(), UpdatedBy=@CoUsuario
  FROM dbo.NominaRun r
  OUTER APPLY (
    SELECT
      Asig = SUM(CASE WHEN UPPER(d.TipoConcepto) IN (N'ASIGNACION',N'BONO') THEN d.Total ELSE 0 END),
      Ded  = SUM(CASE WHEN UPPER(d.TipoConcepto) = N'DEDUCCION' THEN d.Total ELSE 0 END)
    FROM dbo.NominaRunDetalle d
    WHERE d.RunId = r.RunId
  ) s
  WHERE r.RunId = @RunId;

  DECLARE @Asig DECIMAL(18,2), @Ded DECIMAL(18,2), @Neto DECIMAL(18,2);
  SELECT @Asig=TotalAsignaciones, @Ded=TotalDeducciones, @Neto=TotalNeto FROM dbo.NominaRun WHERE RunId=@RunId;

  SET @Resultado = 1;
  SET @Mensaje = CONCAT(N'OK. Asignaciones: ', FORMAT(COALESCE(@Asig,0), 'N2'), N' Deducciones: ', FORMAT(COALESCE(@Ded,0), 'N2'), N' Neto: ', FORMAT(COALESCE(@Neto,0), 'N2'));
END
GO

CREATE PROCEDURE dbo.sp_Nomina_ProcesarNomina
  @Nomina NVARCHAR(10),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @CoUsuario NVARCHAR(20) = N'API',
  @SoloActivos BIT = 1,
  @Procesados INT OUTPUT,
  @Errores INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Procesados = 0;
  SET @Errores = 0;

  DECLARE @Cedula NVARCHAR(20), @R INT, @M NVARCHAR(500);
  DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT Cedula FROM dbo.NominaEmpleado
    WHERE IsDeleted=0 AND (@SoloActivos=0 OR UPPER(Estado)=N'ACTIVO') AND (@Nomina IS NULL OR LTRIM(RTRIM(@Nomina))=N'' OR CodigoNomina=@Nomina);

  OPEN cur;
  FETCH NEXT FROM cur INTO @Cedula;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    EXEC dbo.sp_Nomina_ProcesarEmpleado @Nomina,@Cedula,@FechaInicio,@FechaHasta,@CoUsuario,@R OUTPUT,@M OUTPUT;
    IF @R = 1 SET @Procesados += 1 ELSE SET @Errores += 1;
    FETCH NEXT FROM cur INTO @Cedula;
  END
  CLOSE cur;
  DEALLOCATE cur;

  SET @Mensaje = CONCAT(N'Procesados=', @Procesados, N' Errores=', @Errores);
END
GO

CREATE PROCEDURE dbo.sp_Nomina_List
  @Nomina NVARCHAR(10) = NULL,
  @Cedula NVARCHAR(12) = NULL,
  @FechaDesde DATE = NULL,
  @FechaHasta DATE = NULL,
  @SoloAbiertas BIT = 0,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1)-1) * ISNULL(NULLIF(@Limit,0),50);
  IF @Offset < 0 SET @Offset = 0;
  IF @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  SELECT @TotalCount = COUNT(1)
  FROM dbo.NominaRun r
  WHERE r.IsDeleted=0
    AND (@Nomina IS NULL OR LTRIM(RTRIM(@Nomina))=N'' OR r.NominaCodigo=@Nomina)
    AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR r.Cedula=@Cedula)
    AND (@FechaDesde IS NULL OR r.FechaInicio >= @FechaDesde)
    AND (@FechaHasta IS NULL OR r.FechaHasta <= @FechaHasta)
    AND (@SoloAbiertas=0 OR r.Cerrada=0);

  SELECT
    nomina = r.NominaCodigo,
    cedula = r.Cedula,
    nombreEmpleado = e.NombreCompleto,
    cargo = e.Cargo,
    fechaProceso = r.FechaProceso,
    fechaInicio = r.FechaInicio,
    fechaHasta = r.FechaHasta,
    totalAsignaciones = r.TotalAsignaciones,
    totalDeducciones = r.TotalDeducciones,
    totalNeto = r.TotalNeto,
    cerrada = r.Cerrada,
    tipoNomina = r.TipoCalculo
  FROM dbo.NominaRun r
  LEFT JOIN dbo.NominaEmpleado e ON e.Cedula=r.Cedula AND e.IsDeleted=0
  WHERE r.IsDeleted=0
    AND (@Nomina IS NULL OR LTRIM(RTRIM(@Nomina))=N'' OR r.NominaCodigo=@Nomina)
    AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR r.Cedula=@Cedula)
    AND (@FechaDesde IS NULL OR r.FechaInicio >= @FechaDesde)
    AND (@FechaHasta IS NULL OR r.FechaHasta <= @FechaHasta)
    AND (@SoloAbiertas=0 OR r.Cerrada=0)
  ORDER BY r.FechaProceso DESC, r.RunId DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Get
  @Nomina NVARCHAR(10),
  @Cedula NVARCHAR(12)
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @RunId BIGINT;
  SELECT TOP 1 @RunId = RunId FROM dbo.NominaRun WHERE IsDeleted=0 AND NominaCodigo=@Nomina AND Cedula=@Cedula ORDER BY FechaProceso DESC, RunId DESC;

  SELECT nomina=r.NominaCodigo, cedula=r.Cedula, nombreEmpleado=e.NombreCompleto, cargo=e.Cargo,
         fechaProceso=r.FechaProceso, fechaInicio=r.FechaInicio, fechaHasta=r.FechaHasta,
         totalAsignaciones=r.TotalAsignaciones, totalDeducciones=r.TotalDeducciones, totalNeto=r.TotalNeto,
         cerrada=r.Cerrada, tipoNomina=r.TipoCalculo
  FROM dbo.NominaRun r
  LEFT JOIN dbo.NominaEmpleado e ON e.Cedula=r.Cedula AND e.IsDeleted=0
  WHERE r.RunId=@RunId;

  SELECT coConcepto=d.CodigoConcepto, nombreConcepto=d.NombreConcepto, tipoConcepto=d.TipoConcepto,
         cantidad=d.Cantidad, monto=d.Monto, total=d.Total, descripcion=d.Descripcion, cuentaContable=d.CuentaContable
  FROM dbo.NominaRunDetalle d
  WHERE d.RunId=@RunId AND d.IsDeleted=0
  ORDER BY d.Orden, d.DetalleId;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Cerrar
  @Nomina NVARCHAR(10),
  @Cedula NVARCHAR(12) = NULL,
  @CoUsuario NVARCHAR(20) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  UPDATE dbo.NominaRun
  SET Cerrada=1, Estado=N'CERRADA', UpdatedAt=SYSUTCDATETIME(), UpdatedBy=@CoUsuario
  WHERE IsDeleted=0 AND NominaCodigo=@Nomina AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR Cedula=@Cedula);

  IF @@ROWCOUNT = 0
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'No hay nominas para cerrar';
    RETURN;
  END

  SET @Resultado = 1;
  SET @Mensaje = N'OK';
END
GO
CREATE PROCEDURE dbo.sp_Nomina_ProcesarVacaciones
  @VacacionID NVARCHAR(50),
  @Cedula NVARCHAR(12),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @FechaReintegro DATE = NULL,
  @CoUsuario NVARCHAR(20) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SalarioBase DECIMAL(18,2);
  SELECT @SalarioBase = COALESCE(SalarioBase,0) FROM dbo.NominaEmpleado WHERE Cedula=@Cedula AND IsDeleted=0;
  IF @SalarioBase IS NULL
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'Empleado no encontrado';
    RETURN;
  END

  DECLARE @DiasMes DECIMAL(18,6) = COALESCE((SELECT Valor FROM dbo.NominaConstante WHERE Codigo=N'DIAS_MES' AND IsDeleted=0), 30);
  DECLARE @BonoFactor DECIMAL(18,6) = COALESCE((SELECT Valor FROM dbo.NominaConstante WHERE Codigo=N'VAC_BONO_FACTOR' AND IsDeleted=0), 0.33);
  DECLARE @Dias INT = DATEDIFF(DAY, @FechaInicio, @FechaHasta) + 1;
  IF @Dias < 1 SET @Dias = 1;
  DECLARE @SalarioDiario DECIMAL(18,6) = CASE WHEN @DiasMes=0 THEN 0 ELSE @SalarioBase/@DiasMes END;
  DECLARE @Base DECIMAL(18,2) = ROUND(@SalarioDiario * @Dias, 2);
  DECLARE @Bono DECIMAL(18,2) = ROUND(@Base * @BonoFactor, 2);
  DECLARE @Total DECIMAL(18,2) = @Base + @Bono;

  IF EXISTS (SELECT 1 FROM dbo.NominaVacacion WHERE VacacionId=@VacacionID)
  BEGIN
    UPDATE dbo.NominaVacacion
    SET Cedula=@Cedula, FechaInicio=@FechaInicio, FechaHasta=@FechaHasta, FechaReintegro=@FechaReintegro,
        FechaCalculo=SYSUTCDATETIME(), Total=@Total, TotalCalculado=@Total, Estado=N'PROCESADA',
        UsuarioProceso=@CoUsuario, UpdatedAt=SYSUTCDATETIME(), UpdatedBy=@CoUsuario, IsDeleted=0, DeletedAt=NULL, DeletedBy=NULL
    WHERE VacacionId=@VacacionID;
    DELETE FROM dbo.NominaVacacionDetalle WHERE VacacionId=@VacacionID;
  END
  ELSE
  BEGIN
    INSERT INTO dbo.NominaVacacion
    (VacacionId,Cedula,FechaInicio,FechaHasta,FechaReintegro,Total,TotalCalculado,Estado,UsuarioProceso,CreatedBy,UpdatedBy)
    VALUES
    (@VacacionID,@Cedula,@FechaInicio,@FechaHasta,@FechaReintegro,@Total,@Total,N'PROCESADA',@CoUsuario,@CoUsuario,@CoUsuario);
  END

  INSERT INTO dbo.NominaVacacionDetalle
  (VacacionId,CodigoConcepto,NombreConcepto,TipoConcepto,Cantidad,Monto,Total,Descripcion,Orden,CreatedBy,UpdatedBy)
  VALUES
    (@VacacionID,N'VAC_BASE',N'Base Vacaciones',N'ASIGNACION',@Dias,@SalarioDiario,@Base,N'Base por dias de vacaciones',1,@CoUsuario,@CoUsuario),
    (@VacacionID,N'VAC_BONO',N'Bono Vacacional',N'BONO',1,@Bono,@Bono,N'Bono vacacional',2,@CoUsuario,@CoUsuario);

  SET @Resultado = 1;
  SET @Mensaje = CONCAT(N'OK. Total vacaciones: ', FORMAT(@Total, 'N2'));
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Vacaciones_List
  @Cedula NVARCHAR(12) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1)-1) * ISNULL(NULLIF(@Limit,0),50);
  IF @Offset < 0 SET @Offset = 0;
  IF @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  SELECT @TotalCount = COUNT(1)
  FROM dbo.NominaVacacion v
  WHERE v.IsDeleted=0 AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR v.Cedula=@Cedula);

  SELECT vacacion=v.VacacionId, cedula=v.Cedula, nombreEmpleado=e.NombreCompleto,
         inicio=v.FechaInicio, hasta=v.FechaHasta, reintegro=v.FechaReintegro,
         fechaCalculo=v.FechaCalculo, total=v.Total, totalCalculado=v.TotalCalculado
  FROM dbo.NominaVacacion v
  LEFT JOIN dbo.NominaEmpleado e ON e.Cedula=v.Cedula AND e.IsDeleted=0
  WHERE v.IsDeleted=0 AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR v.Cedula=@Cedula)
  ORDER BY v.FechaCalculo DESC, v.VacacionId DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Vacaciones_Get
  @VacacionID NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT vacacion=v.VacacionId, cedula=v.Cedula, nombreEmpleado=e.NombreCompleto,
         inicio=v.FechaInicio, hasta=v.FechaHasta, reintegro=v.FechaReintegro,
         fechaCalculo=v.FechaCalculo, total=v.Total, totalCalculado=v.TotalCalculado, estado=v.Estado
  FROM dbo.NominaVacacion v
  LEFT JOIN dbo.NominaEmpleado e ON e.Cedula=v.Cedula AND e.IsDeleted=0
  WHERE v.VacacionId=@VacacionID AND v.IsDeleted=0;

  SELECT coConcepto=d.CodigoConcepto, nombreConcepto=d.NombreConcepto, tipoConcepto=d.TipoConcepto,
         cantidad=d.Cantidad, monto=d.Monto, total=d.Total, descripcion=d.Descripcion, cuentaContable=d.CuentaContable
  FROM dbo.NominaVacacionDetalle d
  WHERE d.VacacionId=@VacacionID AND d.IsDeleted=0
  ORDER BY d.Orden, d.DetalleId;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_CalcularLiquidacion
  @LiquidacionID NVARCHAR(50),
  @Cedula NVARCHAR(12),
  @FechaRetiro DATE,
  @CausaRetiro NVARCHAR(50) = N'RENUNCIA',
  @CoUsuario NVARCHAR(20) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @SalarioBase DECIMAL(18,2), @FechaIngreso DATE;
  SELECT @SalarioBase=COALESCE(SalarioBase,0), @FechaIngreso=FechaIngreso FROM dbo.NominaEmpleado WHERE Cedula=@Cedula AND IsDeleted=0;
  IF @FechaIngreso IS NULL
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'Empleado no encontrado o sin fecha de ingreso';
    RETURN;
  END

  DECLARE @PrestFactor DECIMAL(18,6) = COALESCE((SELECT Valor FROM dbo.NominaConstante WHERE Codigo=N'LIQ_PREST_FACTOR' AND IsDeleted=0),0.50);
  DECLARE @Meses INT = DATEDIFF(MONTH, @FechaIngreso, @FechaRetiro);
  IF @Meses < 0 SET @Meses = 0;

  DECLARE @Prest DECIMAL(18,2) = ROUND(@SalarioBase * (@Meses / 12.0) * @PrestFactor, 2);
  DECLARE @VacPend DECIMAL(18,2) = ROUND(@SalarioBase * 0.10, 2);
  DECLARE @Asig DECIMAL(18,2) = @Prest + @VacPend;
  DECLARE @Ded DECIMAL(18,2) = ROUND(@Asig * 0.01, 2);
  DECLARE @Neto DECIMAL(18,2) = @Asig - @Ded;

  IF EXISTS (SELECT 1 FROM dbo.NominaLiquidacion WHERE LiquidacionId=@LiquidacionID)
  BEGIN
    UPDATE dbo.NominaLiquidacion
    SET Cedula=@Cedula, FechaRetiro=@FechaRetiro, CausaRetiro=@CausaRetiro, FechaCalculo=SYSUTCDATETIME(),
        TotalAsignaciones=@Asig, TotalDeducciones=@Ded, TotalNeto=@Neto, Estado=N'PROCESADA',
        UsuarioProceso=@CoUsuario, UpdatedAt=SYSUTCDATETIME(), UpdatedBy=@CoUsuario, IsDeleted=0, DeletedAt=NULL, DeletedBy=NULL
    WHERE LiquidacionId=@LiquidacionID;
    DELETE FROM dbo.NominaLiquidacionDetalle WHERE LiquidacionId=@LiquidacionID;
  END
  ELSE
  BEGIN
    INSERT INTO dbo.NominaLiquidacion
    (LiquidacionId,Cedula,FechaRetiro,CausaRetiro,TotalAsignaciones,TotalDeducciones,TotalNeto,Estado,UsuarioProceso,CreatedBy,UpdatedBy)
    VALUES
    (@LiquidacionID,@Cedula,@FechaRetiro,@CausaRetiro,@Asig,@Ded,@Neto,N'PROCESADA',@CoUsuario,@CoUsuario,@CoUsuario);
  END

  INSERT INTO dbo.NominaLiquidacionDetalle
  (LiquidacionId,CodigoConcepto,NombreConcepto,TipoConcepto,Cantidad,Monto,Total,Descripcion,Orden,CreatedBy,UpdatedBy)
  VALUES
    (@LiquidacionID,N'LIQ_PREST',N'Prestaciones',N'ASIGNACION',1,@Prest,@Prest,N'Prestaciones sociales',1,@CoUsuario,@CoUsuario),
    (@LiquidacionID,N'LIQ_VACPEND',N'Vacaciones pendientes',N'ASIGNACION',1,@VacPend,@VacPend,N'Vacaciones pendientes',2,@CoUsuario,@CoUsuario),
    (@LiquidacionID,N'LIQ_RET',N'Retenciones',N'DEDUCCION',1,@Ded,@Ded,N'Retenciones de salida',3,@CoUsuario,@CoUsuario);

  SET @Resultado = 1;
  SET @Mensaje = CONCAT(N'OK. Total neto liquidacion: ', FORMAT(@Neto, 'N2'));
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Liquidaciones_List
  @Cedula NVARCHAR(12) = NULL,
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1)-1) * ISNULL(NULLIF(@Limit,0),50);
  IF @Offset < 0 SET @Offset = 0;
  IF @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  SELECT @TotalCount = COUNT(1) FROM dbo.NominaLiquidacion l WHERE l.IsDeleted=0 AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR l.Cedula=@Cedula);

  SELECT liquidacion=l.LiquidacionId, cedula=l.Cedula, nombreEmpleado=e.NombreCompleto,
         fechaRetiro=l.FechaRetiro, causaRetiro=l.CausaRetiro, fechaCalculo=l.FechaCalculo,
         totalAsignaciones=l.TotalAsignaciones, totalDeducciones=l.TotalDeducciones, totalNeto=l.TotalNeto, estado=l.Estado
  FROM dbo.NominaLiquidacion l
  LEFT JOIN dbo.NominaEmpleado e ON e.Cedula=l.Cedula AND e.IsDeleted=0
  WHERE l.IsDeleted=0 AND (@Cedula IS NULL OR LTRIM(RTRIM(@Cedula))=N'' OR l.Cedula=@Cedula)
  ORDER BY l.FechaCalculo DESC, l.LiquidacionId DESC
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_GetLiquidacion
  @LiquidacionID NVARCHAR(50)
AS
BEGIN
  SET NOCOUNT ON;
  SELECT coConcepto=d.CodigoConcepto, nombreConcepto=d.NombreConcepto, tipoConcepto=d.TipoConcepto,
         cantidad=d.Cantidad, monto=d.Monto, total=d.Total, descripcion=d.Descripcion, cuentaContable=d.CuentaContable
  FROM dbo.NominaLiquidacionDetalle d
  WHERE d.LiquidacionId=@LiquidacionID AND d.IsDeleted=0
  ORDER BY d.Orden, d.DetalleId;

  SELECT liquidacion=l.LiquidacionId, cedula=l.Cedula, fechaRetiro=l.FechaRetiro, causaRetiro=l.CausaRetiro,
         totalAsignaciones=l.TotalAsignaciones, totalDeducciones=l.TotalDeducciones, totalNeto=l.TotalNeto
  FROM dbo.NominaLiquidacion l
  WHERE l.LiquidacionId=@LiquidacionID AND l.IsDeleted=0;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Constantes_List
  @Page INT = 1,
  @Limit INT = 50,
  @TotalCount INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @Offset INT = (ISNULL(NULLIF(@Page,0),1)-1) * ISNULL(NULLIF(@Limit,0),50);
  IF @Offset < 0 SET @Offset = 0;
  IF @Limit < 1 SET @Limit = 50;
  IF @Limit > 500 SET @Limit = 500;

  SELECT @TotalCount = COUNT(1) FROM dbo.NominaConstante WHERE IsDeleted=0;

  SELECT codigo=Codigo, nombre=Nombre, valor=Valor, origen=Origen
  FROM dbo.NominaConstante
  WHERE IsDeleted=0
  ORDER BY Codigo
  OFFSET @Offset ROWS FETCH NEXT @Limit ROWS ONLY;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_Constante_Save
  @Codigo NVARCHAR(50),
  @Nombre NVARCHAR(100) = NULL,
  @Valor FLOAT = NULL,
  @Origen NVARCHAR(50) = NULL,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  IF @Codigo IS NULL OR LTRIM(RTRIM(@Codigo))=N''
  BEGIN
    SET @Resultado = -2;
    SET @Mensaje = N'Codigo es requerido';
    RETURN;
  END

  IF EXISTS (SELECT 1 FROM dbo.NominaConstante WHERE Codigo=@Codigo)
  BEGIN
    UPDATE dbo.NominaConstante
    SET Nombre=COALESCE(@Nombre,Nombre), Valor=COALESCE(CASE WHEN ISNUMERIC(CAST(@Valor AS NVARCHAR(100)))=1 THEN CAST(@Valor AS DECIMAL(18,6)) ELSE NULL END,Valor), Origen=COALESCE(@Origen,Origen),
        IsDeleted=0, DeletedAt=NULL, DeletedBy=NULL, UpdatedAt=SYSUTCDATETIME(), UpdatedBy=N'API'
    WHERE Codigo=@Codigo;
  END
  ELSE
  BEGIN
    INSERT INTO dbo.NominaConstante (Codigo,Nombre,Valor,Origen,CreatedBy,UpdatedBy)
    VALUES (@Codigo,@Nombre,CASE WHEN ISNUMERIC(CAST(@Valor AS NVARCHAR(100)))=1 THEN CAST(@Valor AS DECIMAL(18,6)) ELSE NULL END,@Origen,N'API',N'API');
  END

  SET @Resultado = 1;
  SET @Mensaje = N'OK';
END
GO

CREATE PROCEDURE dbo.sp_Nomina_ConceptosLegales_List
  @Convencion NVARCHAR(50) = NULL,
  @TipoCalculo NVARCHAR(50) = NULL,
  @Tipo NVARCHAR(15) = NULL,
  @Activo BIT = 1
AS
BEGIN
  SET NOCOUNT ON;
  SELECT
    id = l.Id,
    convencion = l.Convencion,
    tipoCalculo = l.TipoCalculo,
    coConcept = l.CO_CONCEPT,
    nbConcepto = l.NB_CONCEPTO,
    formula = l.FORMULA,
    sobre = l.SOBRE,
    tipo = l.TIPO,
    bonificable = l.BONIFICABLE,
    lotttArticulo = l.LOTTT_Articulo,
    ccpClausula = l.CCP_Clausula,
    orden = l.Orden,
    activo = l.Activo
  FROM dbo.NominaConceptoLegal l
  WHERE l.IsDeleted=0
    AND (@Activo=0 OR l.Activo=1)
    AND (@Convencion IS NULL OR LTRIM(RTRIM(@Convencion))=N'' OR l.Convencion=@Convencion)
    AND (@TipoCalculo IS NULL OR LTRIM(RTRIM(@TipoCalculo))=N'' OR l.TipoCalculo=@TipoCalculo)
    AND (@Tipo IS NULL OR LTRIM(RTRIM(@Tipo))=N'' OR l.TIPO=@Tipo)
  ORDER BY l.Convencion, l.TipoCalculo, l.Orden, l.CO_CONCEPT;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_ProcesarEmpleadoConceptoLegal
  @Nomina NVARCHAR(10),
  @Cedula NVARCHAR(12),
  @FechaInicio DATE,
  @FechaHasta DATE,
  @Convencion NVARCHAR(50) = NULL,
  @TipoCalculo NVARCHAR(50) = N'MENSUAL',
  @CoUsuario NVARCHAR(20) = N'API',
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  -- Por ahora reusa motor base para mantener API operativa.
  EXEC dbo.sp_Nomina_ProcesarEmpleado @Nomina,@Cedula,@FechaInicio,@FechaHasta,@CoUsuario,@Resultado OUTPUT,@Mensaje OUTPUT;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_ValidarFormulasConceptoLegal
  @Convencion NVARCHAR(50) = NULL,
  @TipoCalculo NVARCHAR(50) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  ;WITH Base AS
  (
    SELECT l.Id, l.Convencion, l.TipoCalculo, l.CO_CONCEPT, l.NB_CONCEPTO, l.FORMULA,
      TieneFormula = CASE WHEN l.FORMULA IS NULL OR LTRIM(RTRIM(l.FORMULA))=N'' THEN 0 ELSE 1 END,
      TieneCaracterNoPermitido = CASE
        WHEN l.FORMULA IS NULL OR LTRIM(RTRIM(l.FORMULA))=N'' THEN 0
        WHEN PATINDEX('%[^0-9A-Za-z_ +\-*/().,%]%', l.FORMULA) > 0 THEN 1
        ELSE 0
      END
    FROM dbo.NominaConceptoLegal l
    WHERE l.IsDeleted=0 AND l.Activo=1
      AND (@Convencion IS NULL OR LTRIM(RTRIM(@Convencion))=N'' OR l.Convencion=@Convencion)
      AND (@TipoCalculo IS NULL OR LTRIM(RTRIM(@TipoCalculo))=N'' OR l.TipoCalculo=@TipoCalculo)
  )
  SELECT
    TotalConceptos = COUNT(1),
    FormulasConValor = SUM(CASE WHEN TieneFormula=1 THEN 1 ELSE 0 END),
    FormulasValidas = SUM(CASE WHEN TieneFormula=0 OR TieneCaracterNoPermitido=0 THEN 1 ELSE 0 END),
    FormulasInvalidas = SUM(CASE WHEN TieneFormula=1 AND TieneCaracterNoPermitido=1 THEN 1 ELSE 0 END)
  FROM Base;

  ;WITH Base AS
  (
    SELECT l.Id, l.Convencion, l.TipoCalculo, l.CO_CONCEPT, l.NB_CONCEPTO, l.FORMULA,
      TieneCaracterNoPermitido = CASE
        WHEN l.FORMULA IS NULL OR LTRIM(RTRIM(l.FORMULA))=N'' THEN 0
        WHEN PATINDEX('%[^0-9A-Za-z_ +\-*/().,%]%', l.FORMULA) > 0 THEN 1
        ELSE 0
      END
    FROM dbo.NominaConceptoLegal l
    WHERE l.IsDeleted=0 AND l.Activo=1
      AND (@Convencion IS NULL OR LTRIM(RTRIM(@Convencion))=N'' OR l.Convencion=@Convencion)
      AND (@TipoCalculo IS NULL OR LTRIM(RTRIM(@TipoCalculo))=N'' OR l.TipoCalculo=@TipoCalculo)
  )
  SELECT id=b.Id, convencion=b.Convencion, tipoCalculo=b.TipoCalculo, coConcept=b.CO_CONCEPT, nbConcepto=b.NB_CONCEPTO,
         formula=b.FORMULA, error=N'Formula contiene caracteres no permitidos'
  FROM Base b
  WHERE b.TieneCaracterNoPermitido=1
  ORDER BY b.Convencion,b.TipoCalculo,b.CO_CONCEPT;
END
GO

CREATE PROCEDURE dbo.sp_Nomina_CopiarConceptosDesdeLegal
  @CoNomina NVARCHAR(15),
  @Convencion NVARCHAR(20),
  @TipoCalculo NVARCHAR(20),
  @Sobrescribir BIT = 0,
  @Resultado INT OUTPUT,
  @Mensaje NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  IF NOT EXISTS (SELECT 1 FROM dbo.NominaConceptoLegal WHERE IsDeleted=0 AND Activo=1 AND Convencion=@Convencion AND TipoCalculo=@TipoCalculo)
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje = N'No hay conceptos legales para el filtro indicado';
    RETURN;
  END

  IF @Sobrescribir = 1
  BEGIN
    UPDATE c
    SET
      NombreConcepto = l.NB_CONCEPTO,
      Formula = l.FORMULA,
      Sobre = l.SOBRE,
      Tipo = COALESCE(l.TIPO,c.Tipo),
      Bonificable = l.BONIFICABLE,
      UpdatedAt = SYSUTCDATETIME(),
      UpdatedBy = N'API',
      IsDeleted = 0,
      DeletedAt = NULL,
      DeletedBy = NULL,
      Activo = 1
    FROM dbo.NominaConcepto c
    INNER JOIN dbo.NominaConceptoLegal l ON l.CO_CONCEPT=c.CodigoConcepto AND l.Convencion=@Convencion AND l.TipoCalculo=@TipoCalculo
    WHERE c.CodigoNomina=@CoNomina AND l.IsDeleted=0 AND l.Activo=1;
  END

  INSERT INTO dbo.NominaConcepto
  (CodigoConcepto,CodigoNomina,NombreConcepto,Formula,Sobre,Tipo,Bonificable,Aplica,CreatedBy,UpdatedBy)
  SELECT l.CO_CONCEPT,@CoNomina,l.NB_CONCEPTO,l.FORMULA,l.SOBRE,COALESCE(l.TIPO,N'ASIGNACION'),l.BONIFICABLE,N'S',N'API',N'API'
  FROM dbo.NominaConceptoLegal l
  WHERE l.IsDeleted=0 AND l.Activo=1 AND l.Convencion=@Convencion AND l.TipoCalculo=@TipoCalculo
    AND NOT EXISTS (SELECT 1 FROM dbo.NominaConcepto c WHERE c.CodigoNomina=@CoNomina AND c.CodigoConcepto=l.CO_CONCEPT AND c.IsDeleted=0);

  SET @Resultado = @@ROWCOUNT;
  SET @Mensaje = CONCAT(@Resultado, N' concepto(s) sincronizados en nomina ', @CoNomina);
END
GO
