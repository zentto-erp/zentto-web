SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/*
  Contabilidad general base (SQL Server 2012+)
  - Crea estructura contable nuclear
  - Agrega enlaces contables a tablas auxiliares existentes (si existen)
  - Carga plan de cuentas base y centros de costo iniciales
*/

BEGIN TRY
  BEGIN TRAN;

  IF OBJECT_ID('dbo.PeriodoContable', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.PeriodoContable (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Periodo NVARCHAR(7) NOT NULL, -- YYYY-MM
      FechaDesde DATE NOT NULL,
      FechaHasta DATE NOT NULL,
      Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_PeriodoContable_Estado DEFAULT('ABIERTO'),
      CerradoPor NVARCHAR(40) NULL,
      CerradoEn DATETIME NULL,
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_PeriodoContable_FechaCreacion DEFAULT(GETDATE()),
      CONSTRAINT UQ_PeriodoContable_Periodo UNIQUE (Periodo)
    );
  END

  IF OBJECT_ID('dbo.AsientoContable', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AsientoContable (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      NumeroAsiento NVARCHAR(40) NOT NULL,
      Fecha DATE NOT NULL,
      Periodo NVARCHAR(7) NOT NULL,
      TipoAsiento NVARCHAR(20) NOT NULL, -- APE, DIA, AJU, CIE, DEP
      Referencia NVARCHAR(120) NULL,
      Concepto NVARCHAR(400) NOT NULL,
      Moneda NVARCHAR(10) NOT NULL CONSTRAINT DF_Asiento_Moneda DEFAULT('VES'),
      Tasa DECIMAL(18,6) NOT NULL CONSTRAINT DF_Asiento_Tasa DEFAULT(1),
      TotalDebe DECIMAL(18,2) NOT NULL CONSTRAINT DF_Asiento_Debe DEFAULT(0),
      TotalHaber DECIMAL(18,2) NOT NULL CONSTRAINT DF_Asiento_Haber DEFAULT(0),
      Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_Asiento_Estado DEFAULT('BORRADOR'), -- BORRADOR/APROBADO/ANULADO
      OrigenModulo NVARCHAR(40) NULL, -- FACTURAS, CXC, CXP, COMPRAS, BANCOS, INVENTARIO
      OrigenDocumento NVARCHAR(120) NULL,
      CodUsuario NVARCHAR(40) NULL,
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_Asiento_FechaCreacion DEFAULT(GETDATE()),
      FechaAprobacion DATETIME NULL,
      UsuarioAprobacion NVARCHAR(40) NULL,
      FechaAnulacion DATETIME NULL,
      UsuarioAnulacion NVARCHAR(40) NULL,
      MotivoAnulacion NVARCHAR(400) NULL,
      CONSTRAINT UQ_AsientoContable_Numero UNIQUE (NumeroAsiento)
    );
  END

  IF OBJECT_ID('dbo.AsientoContableDetalle', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AsientoContableDetalle (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      AsientoId BIGINT NOT NULL,
      Renglon INT NOT NULL,
      CodCuenta NVARCHAR(40) NOT NULL,
      Descripcion NVARCHAR(400) NULL,
      CentroCosto NVARCHAR(20) NULL,
      AuxiliarTipo NVARCHAR(30) NULL, -- CLIENTE/PROVEEDOR/BANCO/ARTICULO/EMPLEADO
      AuxiliarCodigo NVARCHAR(120) NULL,
      Documento NVARCHAR(120) NULL,
      Debe DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientoDet_Debe DEFAULT(0),
      Haber DECIMAL(18,2) NOT NULL CONSTRAINT DF_AsientoDet_Haber DEFAULT(0),
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_AsientoDet_FechaCreacion DEFAULT(GETDATE()),
      CONSTRAINT FK_AsientoDet_Asiento FOREIGN KEY (AsientoId) REFERENCES dbo.AsientoContable(Id)
    );
  END

  IF OBJECT_ID('dbo.AsientoOrigenAuxiliar', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AsientoOrigenAuxiliar (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      OrigenModulo NVARCHAR(40) NOT NULL,
      TipoDocumento NVARCHAR(40) NOT NULL,
      NumeroDocumento NVARCHAR(120) NOT NULL,
      TablaOrigen NVARCHAR(120) NULL,
      LlaveOrigen NVARCHAR(400) NULL,
      AsientoId BIGINT NOT NULL,
      Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_AsientoOri_Estado DEFAULT('APLICADO'),
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_AsientoOri_Fecha DEFAULT(GETDATE()),
      CONSTRAINT FK_AsientoOri_Asiento FOREIGN KEY (AsientoId) REFERENCES dbo.AsientoContable(Id),
      CONSTRAINT UQ_AsientoOri UNIQUE (OrigenModulo, TipoDocumento, NumeroDocumento, AsientoId)
    );
  END

  IF OBJECT_ID('dbo.ConfiguracionContableAuxiliar', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.ConfiguracionContableAuxiliar (
      Id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      Modulo NVARCHAR(40) NOT NULL,           -- FACTURAS/COMPRAS/CXC/CXP/BANCOS/INVENTARIO
      Proceso NVARCHAR(60) NOT NULL,          -- EMITIR/APLICAR/ANULAR/AJUSTAR
      Naturaleza NVARCHAR(20) NOT NULL,       -- DEBE/HABER
      CuentaContable NVARCHAR(40) NOT NULL,
      CentroCostoDefault NVARCHAR(20) NULL,
      Descripcion NVARCHAR(250) NULL,
      Activo BIT NOT NULL CONSTRAINT DF_ConfigCont_Activo DEFAULT(1),
      CONSTRAINT UQ_ConfigCont UNIQUE (Modulo, Proceso, Naturaleza, CuentaContable)
    );
  END

  IF OBJECT_ID('dbo.AjusteContable', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.AjusteContable (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      AsientoId BIGINT NOT NULL,
      TipoAjuste NVARCHAR(40) NOT NULL, -- CIERRE, RECLASIFICACION, CORRECCION
      Motivo NVARCHAR(500) NOT NULL,
      Fecha DATE NOT NULL,
      Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_AjusteCont_Estado DEFAULT('APROBADO'),
      CodUsuario NVARCHAR(40) NULL,
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_AjusteCont_Fecha DEFAULT(GETDATE()),
      CONSTRAINT FK_AjusteCont_Asiento FOREIGN KEY (AsientoId) REFERENCES dbo.AsientoContable(Id)
    );
  END

  IF OBJECT_ID('dbo.ActivoFijoContable', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.ActivoFijoContable (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      CodigoActivo NVARCHAR(40) NOT NULL,
      Descripcion NVARCHAR(250) NOT NULL,
      FechaCompra DATE NOT NULL,
      CostoAdquisicion DECIMAL(18,2) NOT NULL,
      ValorResidual DECIMAL(18,2) NOT NULL CONSTRAINT DF_ActivoFijo_Residual DEFAULT(0),
      VidaUtilMeses INT NOT NULL,
      Metodo NVARCHAR(20) NOT NULL CONSTRAINT DF_ActivoFijo_Metodo DEFAULT('LINEAL'),
      CuentaActivo NVARCHAR(40) NOT NULL,
      CuentaDepreciacionAcum NVARCHAR(40) NOT NULL,
      CuentaGastoDepreciacion NVARCHAR(40) NOT NULL,
      CentroCosto NVARCHAR(20) NULL,
      Activo BIT NOT NULL CONSTRAINT DF_ActivoFijo_Activo DEFAULT(1),
      CONSTRAINT UQ_ActivoFijo_Codigo UNIQUE (CodigoActivo)
    );
  END

  IF OBJECT_ID('dbo.DepreciacionContable', 'U') IS NULL
  BEGIN
    CREATE TABLE dbo.DepreciacionContable (
      Id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
      ActivoId BIGINT NOT NULL,
      Periodo NVARCHAR(7) NOT NULL,
      Fecha DATE NOT NULL,
      Monto DECIMAL(18,2) NOT NULL,
      AsientoId BIGINT NULL,
      Estado NVARCHAR(20) NOT NULL CONSTRAINT DF_DepCont_Estado DEFAULT('GENERADO'),
      FechaCreacion DATETIME NOT NULL CONSTRAINT DF_DepCont_Fecha DEFAULT(GETDATE()),
      CONSTRAINT FK_DepCont_Activo FOREIGN KEY (ActivoId) REFERENCES dbo.ActivoFijoContable(Id),
      CONSTRAINT FK_DepCont_Asiento FOREIGN KEY (AsientoId) REFERENCES dbo.AsientoContable(Id),
      CONSTRAINT UQ_DepCont UNIQUE (ActivoId, Periodo)
    );
  END

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AsientoContable_Fecha' AND object_id = OBJECT_ID('dbo.AsientoContable'))
    CREATE INDEX IX_AsientoContable_Fecha ON dbo.AsientoContable(Fecha);

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AsientoContable_Periodo' AND object_id = OBJECT_ID('dbo.AsientoContable'))
    CREATE INDEX IX_AsientoContable_Periodo ON dbo.AsientoContable(Periodo, Estado);

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AsientoDetalle_Cuenta' AND object_id = OBJECT_ID('dbo.AsientoContableDetalle'))
    CREATE INDEX IX_AsientoDetalle_Cuenta ON dbo.AsientoContableDetalle(CodCuenta, CentroCosto);

  IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_AsientoOri_Doc' AND object_id = OBJECT_ID('dbo.AsientoOrigenAuxiliar'))
    CREATE INDEX IX_AsientoOri_Doc ON dbo.AsientoOrigenAuxiliar(OrigenModulo, TipoDocumento, NumeroDocumento);

  /*
    Enlaces contables a auxiliares existentes.
    Se agregan columnas solo si la tabla existe y la columna no existe.
  */
  IF OBJECT_ID('dbo.DocumentosVenta', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.DocumentosVenta', 'Asiento_Id') IS NULL ALTER TABLE dbo.DocumentosVenta ADD Asiento_Id BIGINT NULL;
    IF COL_LENGTH('dbo.DocumentosVenta', 'Centro_Costo') IS NULL ALTER TABLE dbo.DocumentosVenta ADD Centro_Costo NVARCHAR(20) NULL;
  END

  IF OBJECT_ID('dbo.DocumentosVentaDetalle', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.DocumentosVentaDetalle', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.DocumentosVentaDetalle ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.DocumentosVentaDetalle', 'Centro_Costo') IS NULL ALTER TABLE dbo.DocumentosVentaDetalle ADD Centro_Costo NVARCHAR(20) NULL;
  END

  IF OBJECT_ID('dbo.DocumentosCompra', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.DocumentosCompra', 'Asiento_Id') IS NULL ALTER TABLE dbo.DocumentosCompra ADD Asiento_Id BIGINT NULL;
    IF COL_LENGTH('dbo.DocumentosCompra', 'Centro_Costo') IS NULL ALTER TABLE dbo.DocumentosCompra ADD Centro_Costo NVARCHAR(20) NULL;
  END

  IF OBJECT_ID('dbo.DocumentosCompraDetalle', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.DocumentosCompraDetalle', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.DocumentosCompraDetalle ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.DocumentosCompraDetalle', 'Centro_Costo') IS NULL ALTER TABLE dbo.DocumentosCompraDetalle ADD Centro_Costo NVARCHAR(20) NULL;
  END

  IF OBJECT_ID('dbo.p_cobrar', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.p_cobrar', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.p_cobrar ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.p_cobrar', 'Centro_Costo') IS NULL ALTER TABLE dbo.p_cobrar ADD Centro_Costo NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.p_cobrar', 'Asiento_Id') IS NULL ALTER TABLE dbo.p_cobrar ADD Asiento_Id BIGINT NULL;
  END

  IF OBJECT_ID('dbo.P_Pagar', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.P_Pagar', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.P_Pagar ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.P_Pagar', 'Centro_Costo') IS NULL ALTER TABLE dbo.P_Pagar ADD Centro_Costo NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.P_Pagar', 'Asiento_Id') IS NULL ALTER TABLE dbo.P_Pagar ADD Asiento_Id BIGINT NULL;
  END

  IF OBJECT_ID('dbo.MovInvent', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.MovInvent', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.MovInvent ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.MovInvent', 'Centro_Costo') IS NULL ALTER TABLE dbo.MovInvent ADD Centro_Costo NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.MovInvent', 'Asiento_Id') IS NULL ALTER TABLE dbo.MovInvent ADD Asiento_Id BIGINT NULL;
  END

  IF OBJECT_ID('dbo.Abonos', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.Abonos', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.Abonos ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.Abonos', 'Centro_Costo') IS NULL ALTER TABLE dbo.Abonos ADD Centro_Costo NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.Abonos', 'Asiento_Id') IS NULL ALTER TABLE dbo.Abonos ADD Asiento_Id BIGINT NULL;
  END

  IF OBJECT_ID('dbo.pagos', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.pagos', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.pagos ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.pagos', 'Centro_Costo') IS NULL ALTER TABLE dbo.pagos ADD Centro_Costo NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.pagos', 'Asiento_Id') IS NULL ALTER TABLE dbo.pagos ADD Asiento_Id BIGINT NULL;
  END

  IF OBJECT_ID('dbo.Pagosc', 'U') IS NOT NULL
  BEGIN
    IF COL_LENGTH('dbo.Pagosc', 'Cod_Cuenta') IS NULL ALTER TABLE dbo.Pagosc ADD Cod_Cuenta NVARCHAR(40) NULL;
    IF COL_LENGTH('dbo.Pagosc', 'Centro_Costo') IS NULL ALTER TABLE dbo.Pagosc ADD Centro_Costo NVARCHAR(20) NULL;
    IF COL_LENGTH('dbo.Pagosc', 'Asiento_Id') IS NULL ALTER TABLE dbo.Pagosc ADD Asiento_Id BIGINT NULL;
  END

  /*
    Seed de centros de costo base
  */
  IF OBJECT_ID('dbo.Centro_Costo', 'U') IS NOT NULL
  BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.Centro_Costo WHERE Codigo = 'ADM')
      INSERT INTO dbo.Centro_Costo (Codigo, Descripcion, Presupuestado, Saldo_Real) VALUES ('ADM', 'Administracion', '0', '0');
    IF NOT EXISTS (SELECT 1 FROM dbo.Centro_Costo WHERE Codigo = 'VEN')
      INSERT INTO dbo.Centro_Costo (Codigo, Descripcion, Presupuestado, Saldo_Real) VALUES ('VEN', 'Ventas', '0', '0');
    IF NOT EXISTS (SELECT 1 FROM dbo.Centro_Costo WHERE Codigo = 'COM')
      INSERT INTO dbo.Centro_Costo (Codigo, Descripcion, Presupuestado, Saldo_Real) VALUES ('COM', 'Compras', '0', '0');
    IF NOT EXISTS (SELECT 1 FROM dbo.Centro_Costo WHERE Codigo = 'ALM')
      INSERT INTO dbo.Centro_Costo (Codigo, Descripcion, Presupuestado, Saldo_Real) VALUES ('ALM', 'Almacen', '0', '0');
    IF NOT EXISTS (SELECT 1 FROM dbo.Centro_Costo WHERE Codigo = 'BAN')
      INSERT INTO dbo.Centro_Costo (Codigo, Descripcion, Presupuestado, Saldo_Real) VALUES ('BAN', 'Bancos y Tesoreria', '0', '0');
  END

  /*
    Seed Plan de Cuentas base (estructura universal + Venezuela)
    TIPO:
      D = Deudora natural (activos/gastos)
      A = Acreedora natural (pasivos/patrimonio/ingresos)
  */
  IF OBJECT_ID('dbo.Cuentas', 'U') IS NOT NULL
  BEGIN
    ;WITH cuentas_seed AS (
      SELECT * FROM (VALUES
        ('1', 'ACTIVOS', 'D', '1', 'GENERAL', 'HEADER', 1),
        ('1.1', 'ACTIVO CORRIENTE', 'D', '1', 'GENERAL', 'HEADER', 2),
        ('1.1.01', 'CAJA', 'D', '1', 'TESORERIA', 'MOV', 3),
        ('1.1.02', 'BANCOS', 'D', '1', 'TESORERIA', 'MOV', 3),
        ('1.1.03', 'CUENTAS POR COBRAR COMERCIALES', 'D', '1', 'CXC', 'MOV', 3),
        ('1.1.04', 'RETENCIONES POR RECUPERAR', 'D', '1', 'IMPUESTOS', 'MOV', 3),
        ('1.1.05', 'INVENTARIOS MERCANCIA', 'D', '1', 'INVENTARIO', 'MOV', 3),
        ('1.1.06', 'GASTOS PAGADOS POR ANTICIPADO', 'D', '1', 'GENERAL', 'MOV', 3),
        ('1.2', 'ACTIVO NO CORRIENTE', 'D', '1', 'GENERAL', 'HEADER', 2),
        ('1.2.01', 'PROPIEDAD, PLANTA Y EQUIPO', 'D', '1', 'ACTIVOS_FIJOS', 'MOV', 3),
        ('1.2.02', 'DEPRECIACION ACUMULADA PPE', 'A', '1', 'ACTIVOS_FIJOS', 'MOV', 3),
        ('1.2.03', 'ACTIVOS INTANGIBLES', 'D', '1', 'ACTIVOS_FIJOS', 'MOV', 3),

        ('2', 'PASIVOS', 'A', '2', 'GENERAL', 'HEADER', 1),
        ('2.1', 'PASIVO CORRIENTE', 'A', '2', 'GENERAL', 'HEADER', 2),
        ('2.1.01', 'CUENTAS POR PAGAR PROVEEDORES', 'A', '2', 'CXP', 'MOV', 3),
        ('2.1.02', 'RETENCIONES POR PAGAR', 'A', '2', 'IMPUESTOS', 'MOV', 3),
        ('2.1.03', 'IMPUESTOS POR PAGAR', 'A', '2', 'IMPUESTOS', 'MOV', 3),
        ('2.1.04', 'OBLIGACIONES LABORALES POR PAGAR', 'A', '2', 'NOMINA', 'MOV', 3),
        ('2.1.05', 'ANTICIPOS DE CLIENTES', 'A', '2', 'CXC', 'MOV', 3),
        ('2.2', 'PASIVO NO CORRIENTE', 'A', '2', 'GENERAL', 'HEADER', 2),
        ('2.2.01', 'PRESTAMOS LARGO PLAZO', 'A', '2', 'FINANCIERO', 'MOV', 3),

        ('3', 'PATRIMONIO', 'A', '3', 'GENERAL', 'HEADER', 1),
        ('3.1', 'CAPITAL SOCIAL', 'A', '3', 'GENERAL', 'MOV', 2),
        ('3.2', 'RESERVAS', 'A', '3', 'GENERAL', 'MOV', 2),
        ('3.3', 'RESULTADOS ACUMULADOS', 'A', '3', 'GENERAL', 'MOV', 2),
        ('3.4', 'UTILIDAD O PERDIDA DEL EJERCICIO', 'A', '3', 'GENERAL', 'MOV', 2),

        ('4', 'INGRESOS', 'A', '4', 'GENERAL', 'HEADER', 1),
        ('4.1', 'INGRESOS OPERACIONALES', 'A', '4', 'VENTAS', 'HEADER', 2),
        ('4.1.01', 'VENTAS GRAVADAS', 'A', '4', 'VENTAS', 'MOV', 3),
        ('4.1.02', 'VENTAS EXENTAS', 'A', '4', 'VENTAS', 'MOV', 3),
        ('4.1.03', 'SERVICIOS PRESTADOS', 'A', '4', 'VENTAS', 'MOV', 3),
        ('4.2', 'INGRESOS NO OPERACIONALES', 'A', '4', 'GENERAL', 'HEADER', 2),
        ('4.2.01', 'OTROS INGRESOS', 'A', '4', 'GENERAL', 'MOV', 3),

        ('5', 'COSTOS', 'D', '5', 'GENERAL', 'HEADER', 1),
        ('5.1', 'COSTO DE VENTAS', 'D', '5', 'INVENTARIO', 'MOV', 2),
        ('5.2', 'COSTO DE SERVICIOS', 'D', '5', 'SERVICIOS', 'MOV', 2),

        ('6', 'GASTOS OPERACIONALES', 'D', '6', 'GENERAL', 'HEADER', 1),
        ('6.1', 'GASTOS DE ADMINISTRACION', 'D', '6', 'ADMIN', 'HEADER', 2),
        ('6.1.01', 'SUELDOS Y SALARIOS ADMIN', 'D', '6', 'NOMINA', 'MOV', 3),
        ('6.1.02', 'ALQUILERES', 'D', '6', 'ADMIN', 'MOV', 3),
        ('6.1.03', 'SERVICIOS BASICOS', 'D', '6', 'ADMIN', 'MOV', 3),
        ('6.1.04', 'DEPRECIACION DEL EJERCICIO', 'D', '6', 'ACTIVOS_FIJOS', 'MOV', 3),
        ('6.2', 'GASTOS DE VENTAS', 'D', '6', 'VENTAS', 'HEADER', 2),
        ('6.2.01', 'COMISIONES DE VENTAS', 'D', '6', 'VENTAS', 'MOV', 3),
        ('6.2.02', 'PUBLICIDAD Y MERCADEO', 'D', '6', 'VENTAS', 'MOV', 3),

        ('7', 'RESULTADO INTEGRAL Y CIERRE', 'A', '7', 'CIERRE', 'HEADER', 1),
        ('7.1', 'RESUMEN DE INGRESOS', 'A', '7', 'CIERRE', 'MOV', 2),
        ('7.2', 'RESUMEN DE COSTOS Y GASTOS', 'D', '7', 'CIERRE', 'MOV', 2)
      ) s(COD_CUENTA, DESCRIPCION, TIPO, grupo, LINEA, USO, Nivel)
    )
    INSERT INTO dbo.Cuentas (COD_CUENTA, DESCRIPCION, TIPO, PRESUPUESTO, SALDO, COD_USUARIO, grupo, LINEA, USO, Nivel, Porcentaje)
    SELECT s.COD_CUENTA, s.DESCRIPCION, s.TIPO, 0, 0, 'SYS', s.grupo, s.LINEA, s.USO, s.Nivel, 0
    FROM cuentas_seed s
    WHERE NOT EXISTS (
      SELECT 1 FROM dbo.Cuentas c WHERE c.COD_CUENTA = s.COD_CUENTA
    );
  END

  COMMIT TRAN;
END TRY
BEGIN CATCH
  IF @@TRANCOUNT > 0 ROLLBACK TRAN;
  DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
  RAISERROR('Error create_contabilidad_general.sql: %s', 16, 1, @Err);
END CATCH;
GO

