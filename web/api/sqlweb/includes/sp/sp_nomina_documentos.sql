-- =============================================
-- NÓMINA: PLANTILLAS DE DOCUMENTOS (hr.DocumentTemplate)
-- SQL Server 2012 compatible
-- NO CREATE OR ALTER, NO JSON, NO STRING_AGG
-- =============================================
SET NOCOUNT ON;
GO

IF SCHEMA_ID('hr') IS NULL EXEC('CREATE SCHEMA hr AUTHORIZATION dbo');
GO

-- =============================================
-- 1. TABLA hr.DocumentTemplate
-- =============================================
IF OBJECT_ID('hr.DocumentTemplate','U') IS NULL
BEGIN
  CREATE TABLE hr.DocumentTemplate (
    TemplateId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_DocumentTemplate PRIMARY KEY,
    CompanyId      INT NOT NULL,
    TemplateCode   NVARCHAR(80)  NOT NULL,
    TemplateName   NVARCHAR(200) NOT NULL,
    TemplateType   NVARCHAR(40)  NOT NULL,
    CountryCode    CHAR(2)       NOT NULL,
    PayrollCode    NVARCHAR(20)  NULL,
    ContentMD      NVARCHAR(MAX) NOT NULL,
    IsDefault      BIT           NOT NULL CONSTRAINT DF_DocumentTemplate_IsDefault  DEFAULT 1,
    IsSystem       BIT           NOT NULL CONSTRAINT DF_DocumentTemplate_IsSystem   DEFAULT 0,
    IsActive       BIT           NOT NULL CONSTRAINT DF_DocumentTemplate_IsActive   DEFAULT 1,
    CreatedAt      DATETIME2(3)  NOT NULL CONSTRAINT DF_DocumentTemplate_CreatedAt  DEFAULT SYSUTCDATETIME(),
    UpdatedAt      DATETIME2(3)  NOT NULL CONSTRAINT DF_DocumentTemplate_UpdatedAt  DEFAULT SYSUTCDATETIME(),
    CONSTRAINT UQ_DocumentTemplate_Code UNIQUE (CompanyId, TemplateCode)
  );
END
GO

PRINT '>> hr.DocumentTemplate OK';
GO

-- =============================================
-- 2. SPs
-- =============================================

-- --------------------------------------------
-- usp_HR_DocumentTemplate_List
-- --------------------------------------------
IF OBJECT_ID('hr.usp_HR_DocumentTemplate_List','P') IS NOT NULL
  DROP PROCEDURE hr.usp_HR_DocumentTemplate_List;
GO
IF OBJECT_ID('dbo.usp_HR_DocumentTemplate_List','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_HR_DocumentTemplate_List;
GO
CREATE PROCEDURE dbo.usp_HR_DocumentTemplate_List
  @CompanyId    INT,
  @CountryCode  CHAR(2)       = NULL,
  @TemplateType NVARCHAR(40)  = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    TemplateId,
    TemplateCode,
    TemplateName,
    TemplateType,
    CountryCode,
    PayrollCode,
    IsDefault,
    IsSystem,
    IsActive,
    UpdatedAt
  FROM hr.DocumentTemplate
  WHERE CompanyId = @CompanyId
    AND IsActive  = 1
    AND (@CountryCode  IS NULL OR CountryCode  = @CountryCode)
    AND (@TemplateType IS NULL OR TemplateType = @TemplateType)
  ORDER BY CountryCode, TemplateType, TemplateName;
END
GO

PRINT '>> usp_HR_DocumentTemplate_List OK';
GO

-- --------------------------------------------
-- usp_HR_DocumentTemplate_Get
-- --------------------------------------------
IF OBJECT_ID('hr.usp_HR_DocumentTemplate_Get','P') IS NOT NULL
  DROP PROCEDURE hr.usp_HR_DocumentTemplate_Get;
GO
IF OBJECT_ID('dbo.usp_HR_DocumentTemplate_Get','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_HR_DocumentTemplate_Get;
GO
CREATE PROCEDURE dbo.usp_HR_DocumentTemplate_Get
  @CompanyId   INT,
  @TemplateCode NVARCHAR(80)
AS
BEGIN
  SET NOCOUNT ON;

  SELECT
    TemplateId,
    TemplateCode,
    TemplateName,
    TemplateType,
    CountryCode,
    PayrollCode,
    ContentMD,
    IsDefault,
    IsSystem,
    IsActive,
    CreatedAt,
    UpdatedAt
  FROM hr.DocumentTemplate
  WHERE CompanyId   = @CompanyId
    AND TemplateCode = @TemplateCode;
END
GO

PRINT '>> usp_HR_DocumentTemplate_Get OK';
GO

-- --------------------------------------------
-- usp_HR_DocumentTemplate_Save
-- --------------------------------------------
IF OBJECT_ID('hr.usp_HR_DocumentTemplate_Save','P') IS NOT NULL
  DROP PROCEDURE hr.usp_HR_DocumentTemplate_Save;
GO
IF OBJECT_ID('dbo.usp_HR_DocumentTemplate_Save','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_HR_DocumentTemplate_Save;
GO
CREATE PROCEDURE dbo.usp_HR_DocumentTemplate_Save
  @CompanyId    INT,
  @TemplateCode NVARCHAR(80),
  @TemplateName NVARCHAR(200),
  @TemplateType NVARCHAR(40),
  @CountryCode  CHAR(2),
  @PayrollCode  NVARCHAR(20)  = NULL,
  @ContentMD    NVARCHAR(MAX),
  @IsDefault    BIT           = 1,
  @Resultado    INT           OUTPUT,
  @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje   = N'';

  -- Proteger plantillas del sistema
  IF EXISTS (
    SELECT 1 FROM hr.DocumentTemplate
    WHERE CompanyId    = @CompanyId
      AND TemplateCode = @TemplateCode
      AND IsSystem     = 1
  )
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje   = N'No se puede modificar una plantilla del sistema.';
    RETURN;
  END

  MERGE hr.DocumentTemplate AS tgt
  USING (
    SELECT
      @CompanyId    AS CompanyId,
      @TemplateCode AS TemplateCode,
      @TemplateName AS TemplateName,
      @TemplateType AS TemplateType,
      @CountryCode  AS CountryCode,
      @PayrollCode  AS PayrollCode,
      @ContentMD    AS ContentMD,
      @IsDefault    AS IsDefault
  ) AS src
    ON tgt.CompanyId    = src.CompanyId
   AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = src.TemplateName,
      TemplateType = src.TemplateType,
      CountryCode  = src.CountryCode,
      PayrollCode  = src.PayrollCode,
      ContentMD    = src.ContentMD,
      IsDefault    = src.IsDefault,
      IsSystem     = 0,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (src.CompanyId, src.TemplateCode, src.TemplateName, src.TemplateType, src.CountryCode, src.PayrollCode, src.ContentMD, src.IsDefault, 0, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  SET @Resultado = 1;
  SET @Mensaje   = N'Plantilla guardada correctamente.';
END
GO

PRINT '>> usp_HR_DocumentTemplate_Save OK';
GO

-- --------------------------------------------
-- usp_HR_DocumentTemplate_Delete
-- --------------------------------------------
IF OBJECT_ID('hr.usp_HR_DocumentTemplate_Delete','P') IS NOT NULL
  DROP PROCEDURE hr.usp_HR_DocumentTemplate_Delete;
GO
IF OBJECT_ID('dbo.usp_HR_DocumentTemplate_Delete','P') IS NOT NULL
  DROP PROCEDURE dbo.usp_HR_DocumentTemplate_Delete;
GO
CREATE PROCEDURE dbo.usp_HR_DocumentTemplate_Delete
  @CompanyId    INT,
  @TemplateCode NVARCHAR(80),
  @Resultado    INT           OUTPUT,
  @Mensaje      NVARCHAR(500) OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  SET @Resultado = 0;
  SET @Mensaje   = N'';

  IF EXISTS (
    SELECT 1 FROM hr.DocumentTemplate
    WHERE CompanyId    = @CompanyId
      AND TemplateCode = @TemplateCode
      AND IsSystem     = 1
  )
  BEGIN
    SET @Resultado = -1;
    SET @Mensaje   = N'No se puede eliminar una plantilla del sistema.';
    RETURN;
  END

  IF NOT EXISTS (
    SELECT 1 FROM hr.DocumentTemplate
    WHERE CompanyId    = @CompanyId
      AND TemplateCode = @TemplateCode
  )
  BEGIN
    SET @Resultado = -2;
    SET @Mensaje   = N'Plantilla no encontrada.';
    RETURN;
  END

  DELETE FROM hr.DocumentTemplate
  WHERE CompanyId    = @CompanyId
    AND TemplateCode = @TemplateCode;

  SET @Resultado = 1;
  SET @Mensaje   = N'Plantilla eliminada correctamente.';
END
GO

PRINT '>> usp_HR_DocumentTemplate_Delete OK';
GO

-- =============================================
-- 3. SEED — Plantillas legales (IsSystem=1)
-- Obtiene primera empresa activa igual que otros seeds
-- =============================================
DECLARE @SeedCompanyId INT;
SELECT TOP 1 @SeedCompanyId = CompanyId
FROM cfg.Company
WHERE IsActive = 1
ORDER BY CompanyId;

IF @SeedCompanyId IS NULL
BEGIN
  PRINT '>> SEED: No hay empresa activa en master.Company — omitiendo seed de plantillas.';
END
ELSE
BEGIN

  -- -----------------------------------------------
  -- PLANTILLA 1: VE_RECIBO_PAGO
  -- -----------------------------------------------
  DECLARE @md1 NVARCHAR(MAX);
  SET @md1 = N'# RECIBO DE PAGO DE NÓMINA

> **Base Legal:** LOTTT Art. 104 | **República Bolivariana de Venezuela**

---

## Datos del Empleador

| Campo | Valor |
|:------|:------|
| Empresa | {{empresa.nombre}} |
| RIF | {{empresa.rif}} |
| Dirección | {{empresa.direccion}} |
| Representante Legal | {{empresa.representante}} |

## Datos del Trabajador

| Campo | Valor |
|:------|:------|
| Nombre Completo | {{empleado.nombre}} |
| Cédula de Identidad | {{empleado.cedula}} |
| Cargo | {{empleado.cargo}} |
| Departamento | {{empleado.departamento}} |
| Fecha de Ingreso | {{empleado.fechaIngreso}} |
| Tipo de Nómina | {{nomina.tipo}} |

## Período de Pago

| Desde | Hasta | Frecuencia |
|:------|:------|:-----------|
| {{periodo.desde}} | {{periodo.hasta}} | {{periodo.tipo}} |

## Detalle de Asignaciones

{{tabla_asignaciones}}

## Deducciones Legales

{{tabla_deducciones}}

---

## Resumen

| Concepto | Monto (Bs.) |
|:---------|------------:|
| **Total Asignaciones** | **{{nomina.totalAsignaciones}}** |
| **Total Deducciones** | **{{nomina.totalDeducciones}}** |
| **NETO A PAGAR** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, portador(a) de la C.I. N° {{empleado.cedula}}, declaro haber recibido la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) como pago de nómina correspondiente al período **{{periodo.desde}}** al **{{periodo.hasta}}**.*

*Conforme con lo establecido en el Art. 104 de la Ley Orgánica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT), este recibo acredita el pago de todos los conceptos descritos.*

&nbsp;

| Firma del Trabajador | Firma del Empleador / Representante |
|:--------------------:|:-----------------------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.nombre}} |

*Generado el {{fecha.generacion}} mediante Sistema DatqBox*';

  MERGE hr.DocumentTemplate AS tgt
  USING (SELECT @SeedCompanyId AS CompanyId, N'VE_RECIBO_PAGO' AS TemplateCode) AS src
    ON tgt.CompanyId = src.CompanyId AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = N'Recibo de Pago de Nómina — LOTTT Art. 104',
      TemplateType = N'RECIBO_PAGO',
      CountryCode  = 'VE',
      PayrollCode  = NULL,
      ContentMD    = @md1,
      IsDefault    = 1,
      IsSystem     = 1,
      IsActive     = 1,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SeedCompanyId, N'VE_RECIBO_PAGO', N'Recibo de Pago de Nómina — LOTTT Art. 104', N'RECIBO_PAGO', 'VE', NULL, @md1, 1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  -- -----------------------------------------------
  -- PLANTILLA 2: VE_RECIBO_VACACIONES
  -- -----------------------------------------------
  DECLARE @md2 NVARCHAR(MAX);
  SET @md2 = N'# RECIBO DE DISFRUTE Y PAGO DE VACACIONES

> **Base Legal:** LOTTT Arts. 190, 191, 192 y 219 | **República Bolivariana de Venezuela**

---

## Identificación

| | |
|:--|:--|
| **Empresa** | {{empresa.nombre}} |
| **RIF** | {{empresa.rif}} |
| **Trabajador** | {{empleado.nombre}} |
| **Cédula** | {{empleado.cedula}} |
| **Cargo** | {{empleado.cargo}} |

## Período Vacacional

| Concepto | Valor |
|:---------|:------|
| Período de trabajo que origina las vacaciones | {{periodo.desde}} al {{periodo.hasta}} |
| Días de vacaciones (LOTTT Art. 190) | {{concepto.VAC_PAGO.cantidad}} días |
| Días de bono vacacional (LOTTT Art. 192) | {{concepto.VAC_BONO.cantidad}} días |
| **Total días de disfrute** | {{concepto.DIAS_TOTALES_VAC}} días |

## Cálculo

{{tabla_todos}}

---

## Resumen

| Concepto | Monto (Bs.) |
|:---------|------------:|
| Pago de Vacaciones | {{concepto.VAC_PAGO.monto}} |
| Bono Vacacional | {{concepto.VAC_BONO.monto}} |
| **Total a Pagar** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, C.I. N° {{empleado.cedula}}, recibo conforme la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) por concepto de vacaciones y bono vacacional del período {{periodo.desde}} al {{periodo.hasta}}, según lo establecido en los Arts. 190 y 192 de la LOTTT.*

| Firma del Trabajador | Firma del Empleador |
|:--------------------:|:-------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |

*{{fecha.generacion}} — DatqBox*';

  MERGE hr.DocumentTemplate AS tgt
  USING (SELECT @SeedCompanyId AS CompanyId, N'VE_RECIBO_VACACIONES' AS TemplateCode) AS src
    ON tgt.CompanyId = src.CompanyId AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = N'Recibo de Vacaciones — LOTTT Arts. 190-192',
      TemplateType = N'RECIBO_VAC',
      CountryCode  = 'VE',
      PayrollCode  = NULL,
      ContentMD    = @md2,
      IsDefault    = 1,
      IsSystem     = 1,
      IsActive     = 1,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SeedCompanyId, N'VE_RECIBO_VACACIONES', N'Recibo de Vacaciones — LOTTT Arts. 190-192', N'RECIBO_VAC', 'VE', NULL, @md2, 1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  -- -----------------------------------------------
  -- PLANTILLA 3: VE_PARTICIPACION_GANANCIAS
  -- -----------------------------------------------
  DECLARE @md3 NVARCHAR(MAX);
  SET @md3 = N'# PLANILLA DE PARTICIPACIÓN EN LAS GANANCIAS (UTILIDADES)

> **Base Legal:** LOTTT Arts. 131, 132 y 133 | **Ejercicio Fiscal {{anio}}**

---

| | |
|:--|:--|
| **Empresa** | {{empresa.nombre}} |
| **RIF** | {{empresa.rif}} |
| **Trabajador** | {{empleado.nombre}} |
| **Cédula** | {{empleado.cedula}} |
| **Cargo** | {{empleado.cargo}} |
| **Fecha de Ingreso** | {{empleado.fechaIngreso}} |

## Base de Cálculo (LOTTT Art. 131)

| Concepto | Monto |
|:---------|------:|
| Salario Diario Normal | {{concepto.SALARIO_DIARIO.monto}} |
| Días de Utilidades (mínimo 30, máximo 120) | {{concepto.DIAS_UTILIDADES.cantidad}} |
| **Total Utilidades** | **{{nomina.neto}}** |

*Las utilidades fueron calculadas sobre el salario normal devengado durante el año. El porcentaje mínimo garantizado es equivalente a **30 días de salario** según el Art. 131 LOTTT.*

---

## Certificación

*La empresa **{{empresa.nombre}}**, RIF {{empresa.rif}}, certifica haber pagado a **{{empleado.nombre}}**, C.I. {{empleado.cedula}}, la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) correspondiente a la Participación en las Ganancias del ejercicio {{anio}}, en cumplimiento del Art. 131 de la LOTTT.*

| Recibido Conforme | Representante Empresa |
|:-----------------:|:---------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.nombre}} |

*{{fecha.generacion}} — DatqBox*';

  MERGE hr.DocumentTemplate AS tgt
  USING (SELECT @SeedCompanyId AS CompanyId, N'VE_PARTICIPACION_GANANCIAS' AS TemplateCode) AS src
    ON tgt.CompanyId = src.CompanyId AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = N'Participación en las Ganancias (Utilidades) — LOTTT Art. 131',
      TemplateType = N'UTILIDADES',
      CountryCode  = 'VE',
      PayrollCode  = NULL,
      ContentMD    = @md3,
      IsDefault    = 1,
      IsSystem     = 1,
      IsActive     = 1,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SeedCompanyId, N'VE_PARTICIPACION_GANANCIAS', N'Participación en las Ganancias (Utilidades) — LOTTT Art. 131', N'UTILIDADES', 'VE', NULL, @md3, 1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  -- -----------------------------------------------
  -- PLANTILLA 4: VE_LIQUIDACION
  -- -----------------------------------------------
  DECLARE @md4 NVARCHAR(MAX);
  SET @md4 = N'# PLANILLA DE LIQUIDACIÓN DE PRESTACIONES SOCIALES

> **Base Legal:** LOTTT Arts. 92, 142, 143 y 144 | **República Bolivariana de Venezuela**

---

## Datos de la Relación Laboral

| Concepto | Valor |
|:---------|:------|
| Empresa | {{empresa.nombre}} |
| RIF | {{empresa.rif}} |
| Trabajador | {{empleado.nombre}} |
| Cédula | {{empleado.cedula}} |
| Cargo | {{empleado.cargo}} |
| Fecha de Ingreso | {{empleado.fechaIngreso}} |
| Fecha de Egreso | {{periodo.hasta}} |
| Causa de Terminación | {{liquidacion.causa}} |
| Tiempo de Servicio | {{empleado.antiguedad}} |

## Cálculo de Prestaciones y Beneficios

{{tabla_todos}}

---

## Resumen de Liquidación (LOTTT Art. 142)

| Concepto | Monto (Bs.) |
|:---------|------------:|
| Garantía de Prestaciones Sociales | {{concepto.LIQ_PREST.monto}} |
| Vacaciones Fraccionadas | {{concepto.LIQ_VAC.monto}} |
| Utilidades Fraccionadas | {{concepto.LIQ_UTIL.monto}} |
| Otros Beneficios | {{concepto.LIQ_OTROS.monto}} |
| **TOTAL LIQUIDACIÓN** | **{{nomina.totalAsignaciones}}** |
| Deducciones | {{nomina.totalDeducciones}} |
| **NETO A PAGAR** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, C.I. N° {{empleado.cedula}}, DECLARO haber recibido de la empresa **{{empresa.nombre}}** la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) en PAGO TOTAL Y DEFINITIVO de todos y cada uno de los conceptos derivados de la relación laboral que me unió con dicha empresa desde el {{empleado.fechaIngreso}} hasta el {{periodo.hasta}}, quedando a ambas partes libre de todo compromiso laboral.*

*Este pago incluye todos los beneficios establecidos en la Ley Orgánica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT), el contrato colectivo vigente y la legislación aplicable.*

| Firma del Trabajador | Firma del Empleador |
|:--------------------:|:-------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.rif}} |

*Ante Notario Público / Inspector del Trabajo si aplica*

*{{fecha.generacion}} — DatqBox*';

  MERGE hr.DocumentTemplate AS tgt
  USING (SELECT @SeedCompanyId AS CompanyId, N'VE_LIQUIDACION' AS TemplateCode) AS src
    ON tgt.CompanyId = src.CompanyId AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = N'Liquidación de Prestaciones Sociales — LOTTT Arts. 142-143',
      TemplateType = N'LIQUIDACION',
      CountryCode  = 'VE',
      PayrollCode  = NULL,
      ContentMD    = @md4,
      IsDefault    = 1,
      IsSystem     = 1,
      IsActive     = 1,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SeedCompanyId, N'VE_LIQUIDACION', N'Liquidación de Prestaciones Sociales — LOTTT Arts. 142-143', N'LIQUIDACION', 'VE', NULL, @md4, 1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  -- -----------------------------------------------
  -- PLANTILLA 5: ES_NOMINA_OFICIAL
  -- -----------------------------------------------
  DECLARE @md5 NVARCHAR(MAX);
  SET @md5 = N'# RECIBO DE SALARIOS (NÓMINA)

> **Base Legal:** RD 1784/1996 art. 2 | **Reino de España**

---

## I. DATOS DE LA EMPRESA Y TRABAJADOR

| Empresa | CIF/NIF | Centro de Trabajo |
|:--------|:--------|:------------------|
| {{empresa.nombre}} | {{empresa.rif}} | {{empresa.direccion}} |

| Trabajador | NIF | N.° S.S. | Categoría / Grupo Prof. | Antigüedad |
|:-----------|:----|:---------|:------------------------|:-----------|
| {{empleado.nombre}} | {{empleado.cedula}} | {{empleado.nss}} | {{empleado.cargo}} | {{empleado.fechaIngreso}} |

**Período de liquidación:** Del {{periodo.desde}} al {{periodo.hasta}}

---

## II. DEVENGOS

{{tabla_asignaciones}}

**TOTAL DEVENGOS** | **{{nomina.totalAsignaciones}} €**

---

## III. DEDUCCIONES

{{tabla_deducciones}}

**TOTAL DEDUCCIONES** | **{{nomina.totalDeducciones}} €**

---

## IV. BASES DE COTIZACIÓN A LA SEGURIDAD SOCIAL

| Base Contingencias Comunes | Base A.T. y E.P. | Base Horas Extra F.M. | Base H.E. Voluntarias |
|---------------------------:|------------------:|----------------------:|----------------------:|
| {{es.baseCC}} € | {{es.baseAT}} € | {{es.baseHEFM}} € | {{es.baseHEV}} € |

| Cuota Obrero S.S. | Retención IRPF | Otras Deducciones |
|------------------:|---------------:|------------------:|
| {{concepto.DED_SS_CC.monto}} + {{concepto.DED_SS_DESEMP.monto}} + {{concepto.DED_SS_FP.monto}} € | {{concepto.DED_IRPF.monto}} € | — |

---

## V. LÍQUIDO A PERCIBIR

| Total Devengos | — | Total Deducciones | = | **LÍQUIDO A PERCIBIR** |
|---------------:|:-:|------------------:|:-:|:----------------------:|
| {{nomina.totalAsignaciones}} € | — | {{nomina.totalDeducciones}} € | = | **{{nomina.neto}} €** |

*Firma y sello de la empresa:* _________________________ *Recibí:* _________________________

*{{empresa.nombre}} — {{fecha.generacion}} — DatqBox*';

  MERGE hr.DocumentTemplate AS tgt
  USING (SELECT @SeedCompanyId AS CompanyId, N'ES_NOMINA_OFICIAL' AS TemplateCode) AS src
    ON tgt.CompanyId = src.CompanyId AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = N'Nómina Oficial — RD 1784/1996 España',
      TemplateType = N'NOMINA_ES',
      CountryCode  = 'ES',
      PayrollCode  = NULL,
      ContentMD    = @md5,
      IsDefault    = 1,
      IsSystem     = 1,
      IsActive     = 1,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SeedCompanyId, N'ES_NOMINA_OFICIAL', N'Nómina Oficial — RD 1784/1996 España', N'NOMINA_ES', 'ES', NULL, @md5, 1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  -- -----------------------------------------------
  -- PLANTILLA 6: ES_FINIQUITO
  -- -----------------------------------------------
  DECLARE @md6 NVARCHAR(MAX);
  SET @md6 = N'# FINIQUITO DE RELACIÓN LABORAL

> **Base Legal:** Estatuto de los Trabajadores Art. 49 | **Reino de España**

---

En **{{empresa.direccion}}**, a {{fecha.generacion}},

**De una parte:** La empresa **{{empresa.nombre}}**, con CIF {{empresa.rif}}, representada por **{{empresa.representante}}**.

**De otra parte:** D./Dña. **{{empleado.nombre}}**, con NIF {{empleado.cedula}}, que ha prestado sus servicios en calidad de **{{empleado.cargo}}**.

---

## Hechos

1. La relación laboral entre las partes dio comienzo el día **{{empleado.fechaIngreso}}** y se extingue el **{{periodo.hasta}}**.
2. La causa de extinción del contrato es: **{{liquidacion.causa}}**.
3. El trabajador ha prestado sus servicios a jornada **{{empleado.tipoJornada}}**.

## Liquidación

{{tabla_todos}}

| Concepto | Importe (€) |
|:---------|------------:|
| **Total Devengado** | **{{nomina.totalAsignaciones}}** |
| Retenciones e impuestos | {{nomina.totalDeducciones}} |
| **TOTAL LÍQUIDO** | **{{nomina.neto}}** |

---

## Declaración

*Con la percepción de la cantidad de **{{nomina.neto}} €** ({{nomina.netoLetras}}), el trabajador/a declara quedar **saldado/a y finiquitado/a** de cuantos derechos y acciones pudieran corresponderle derivados de la relación laboral extinguida, incluyendo salarios, vacaciones, pagas extraordinarias, indemnizaciones y cualquier otro concepto.*

*El trabajador/a dispone de un plazo de 3 días para solicitar la presencia de un representante sindical antes de la firma.*

---

| El Trabajador | La Empresa |
|:-------------:|:----------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| NIF: {{empleado.cedula}} | {{empresa.nombre}} |

*DatqBox — Sistema de Gestión Laboral*';

  MERGE hr.DocumentTemplate AS tgt
  USING (SELECT @SeedCompanyId AS CompanyId, N'ES_FINIQUITO' AS TemplateCode) AS src
    ON tgt.CompanyId = src.CompanyId AND tgt.TemplateCode = src.TemplateCode
  WHEN MATCHED THEN
    UPDATE SET
      TemplateName = N'Finiquito de Relación Laboral — ET Art. 49 España',
      TemplateType = N'FINIQUITO_ES',
      CountryCode  = 'ES',
      PayrollCode  = NULL,
      ContentMD    = @md6,
      IsDefault    = 1,
      IsSystem     = 1,
      IsActive     = 1,
      UpdatedAt    = SYSUTCDATETIME()
  WHEN NOT MATCHED THEN
    INSERT (CompanyId, TemplateCode, TemplateName, TemplateType, CountryCode, PayrollCode, ContentMD, IsDefault, IsSystem, IsActive, CreatedAt, UpdatedAt)
    VALUES (@SeedCompanyId, N'ES_FINIQUITO', N'Finiquito de Relación Laboral — ET Art. 49 España', N'FINIQUITO_ES', 'ES', NULL, @md6, 1, 1, 1, SYSUTCDATETIME(), SYSUTCDATETIME());

  PRINT '>> SEED: 6 plantillas legales aplicadas OK';

END
GO

PRINT '>> sp_nomina_documentos.sql — despliegue completo OK';
GO
