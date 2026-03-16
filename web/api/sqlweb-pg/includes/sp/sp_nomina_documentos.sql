-- =============================================
-- Archivo  : sp_nomina_documentos.sql
-- Propósito: Plantillas de Documentos de Nómina (PostgreSQL)
-- Tabla    : hr."DocumentTemplate"
-- Origen   : Conversión desde T-SQL (SQL Server 2012 compatible)
-- Fecha    : 2026-03-16
-- =============================================

CREATE SCHEMA IF NOT EXISTS hr;

-- =============================================
-- 1. TABLA hr."DocumentTemplate"
-- =============================================
CREATE TABLE IF NOT EXISTS hr."DocumentTemplate" (
    "TemplateId"   SERIAL        NOT NULL CONSTRAINT "PK_DocumentTemplate" PRIMARY KEY,
    "CompanyId"    INTEGER       NOT NULL,
    "TemplateCode" VARCHAR(80)   NOT NULL,
    "TemplateName" VARCHAR(200)  NOT NULL,
    "TemplateType" VARCHAR(40)   NOT NULL,
    "CountryCode"  CHAR(2)       NOT NULL,
    "PayrollCode"  VARCHAR(20)   NULL,
    "ContentMD"    TEXT          NOT NULL,
    "IsDefault"    BOOLEAN       NOT NULL DEFAULT TRUE,
    "IsSystem"     BOOLEAN       NOT NULL DEFAULT FALSE,
    "IsActive"     BOOLEAN       NOT NULL DEFAULT TRUE,
    "CreatedAt"    TIMESTAMP(3)  NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    "UpdatedAt"    TIMESTAMP(3)  NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    CONSTRAINT "UQ_DocumentTemplate_Code" UNIQUE ("CompanyId", "TemplateCode")
);

-- Agregar columna IsSystem si la tabla ya existe sin ella (migración)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'hr'
          AND table_name   = 'DocumentTemplate'
          AND column_name  = 'IsSystem'
    ) THEN
        ALTER TABLE hr."DocumentTemplate"
            ADD COLUMN "IsSystem" BOOLEAN NOT NULL DEFAULT FALSE;
        RAISE NOTICE '>> Columna IsSystem agregada a hr.DocumentTemplate';
    END IF;
END;
$$;

-- =============================================
-- 2. FUNCIONES (equivalentes a los SPs)
-- =============================================

-- --------------------------------------------
-- usp_HR_DocumentTemplate_List
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_HR_DocumentTemplate_List(
    p_company_id    INTEGER,
    p_country_code  CHAR(2)     DEFAULT NULL,
    p_template_type VARCHAR(40) DEFAULT NULL
)
RETURNS TABLE(
    "TemplateId"   INTEGER,
    "TemplateCode" VARCHAR(80),
    "TemplateName" VARCHAR(200),
    "TemplateType" VARCHAR(40),
    "CountryCode"  CHAR(2),
    "PayrollCode"  VARCHAR(20),
    "IsDefault"    BOOLEAN,
    "IsSystem"     BOOLEAN,
    "IsActive"     BOOLEAN,
    "UpdatedAt"    TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId",
        t."TemplateCode",
        t."TemplateName",
        t."TemplateType",
        t."CountryCode",
        t."PayrollCode",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId" = p_company_id
      AND t."IsActive"  = TRUE
      AND (p_country_code  IS NULL OR t."CountryCode"  = p_country_code)
      AND (p_template_type IS NULL OR t."TemplateType" = p_template_type)
    ORDER BY t."CountryCode", t."TemplateType", t."TemplateName";
END;
$$;


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Get
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_HR_DocumentTemplate_Get(
    p_company_id    INTEGER,
    p_template_code VARCHAR(80)
)
RETURNS TABLE(
    "TemplateId"   INTEGER,
    "TemplateCode" VARCHAR(80),
    "TemplateName" VARCHAR(200),
    "TemplateType" VARCHAR(40),
    "CountryCode"  CHAR(2),
    "PayrollCode"  VARCHAR(20),
    "ContentMD"    TEXT,
    "IsDefault"    BOOLEAN,
    "IsSystem"     BOOLEAN,
    "IsActive"     BOOLEAN,
    "CreatedAt"    TIMESTAMP(3),
    "UpdatedAt"    TIMESTAMP(3)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId",
        t."TemplateCode",
        t."TemplateName",
        t."TemplateType",
        t."CountryCode",
        t."PayrollCode",
        t."ContentMD",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."CreatedAt",
        t."UpdatedAt"
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId"    = p_company_id
      AND t."TemplateCode" = p_template_code;
END;
$$;


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Save
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_HR_DocumentTemplate_Save(
    p_company_id    INTEGER,
    p_template_code VARCHAR(80),
    p_template_name VARCHAR(200),
    p_template_type VARCHAR(40),
    p_country_code  CHAR(2),
    p_content_md    TEXT,
    p_payroll_code  VARCHAR(20) DEFAULT NULL,
    p_is_default    BOOLEAN     DEFAULT TRUE,
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    -- Proteger plantillas del sistema
    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede modificar una plantilla del sistema.';
        RETURN;
    END IF;

    -- MERGE equivalente en PostgreSQL usando INSERT ... ON CONFLICT
    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault",
        "IsSystem", "IsActive", "CreatedAt", "UpdatedAt"
    )
    VALUES (
        p_company_id, p_template_code, p_template_name, p_template_type,
        p_country_code, p_payroll_code, p_content_md, p_is_default,
        FALSE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = EXCLUDED."TemplateName",
        "TemplateType" = EXCLUDED."TemplateType",
        "CountryCode"  = EXCLUDED."CountryCode",
        "PayrollCode"  = EXCLUDED."PayrollCode",
        "ContentMD"    = EXCLUDED."ContentMD",
        "IsDefault"    = EXCLUDED."IsDefault",
        "IsSystem"     = FALSE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    p_resultado := 1;
    p_mensaje   := 'Plantilla guardada correctamente.';
END;
$$;


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Delete
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_HR_DocumentTemplate_Delete(
    p_company_id    INTEGER,
    p_template_code VARCHAR(80),
    OUT p_resultado INTEGER,
    OUT p_mensaje   TEXT
)
RETURNS record
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := '';

    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede eliminar una plantilla del sistema.';
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Plantilla no encontrada.';
        RETURN;
    END IF;

    DELETE FROM hr."DocumentTemplate"
    WHERE "CompanyId"    = p_company_id
      AND "TemplateCode" = p_template_code;

    p_resultado := 1;
    p_mensaje   := 'Plantilla eliminada correctamente.';
END;
$$;


-- =============================================
-- 3. SEED — Plantillas legales (IsSystem=TRUE)
-- =============================================
DO $$
DECLARE
    v_seed_company_id INTEGER;
    v_md1 TEXT;
    v_md2 TEXT;
    v_md3 TEXT;
    v_md4 TEXT;
    v_md5 TEXT;
    v_md6 TEXT;
BEGIN
    SELECT "CompanyId"
    INTO v_seed_company_id
    FROM cfg."Company"
    WHERE "IsActive" = TRUE
    ORDER BY "CompanyId"
    LIMIT 1;

    IF v_seed_company_id IS NULL THEN
        RAISE NOTICE '>> SEED: No hay empresa activa en cfg.Company — omitiendo seed de plantillas.';
        RETURN;
    END IF;

    -- -----------------------------------------------
    -- PLANTILLA 1: VE_RECIBO_PAGO
    -- -----------------------------------------------
    v_md1 := '# RECIBO DE PAGO DE NÓMINA

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

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_RECIBO_PAGO',
        'Recibo de Pago de Nómina — LOTTT Art. 104', 'RECIBO_PAGO',
        'VE', NULL, v_md1, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Recibo de Pago de Nómina — LOTTT Art. 104',
        "TemplateType" = 'RECIBO_PAGO',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md1,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 2: VE_RECIBO_VACACIONES
    -- -----------------------------------------------
    v_md2 := '# RECIBO DE DISFRUTE Y PAGO DE VACACIONES

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

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_RECIBO_VACACIONES',
        'Recibo de Vacaciones — LOTTT Arts. 190-192', 'RECIBO_VAC',
        'VE', NULL, v_md2, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Recibo de Vacaciones — LOTTT Arts. 190-192',
        "TemplateType" = 'RECIBO_VAC',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md2,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 3: VE_PARTICIPACION_GANANCIAS
    -- -----------------------------------------------
    v_md3 := '# PLANILLA DE PARTICIPACIÓN EN LAS GANANCIAS (UTILIDADES)

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

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_PARTICIPACION_GANANCIAS',
        'Participación en las Ganancias (Utilidades) — LOTTT Art. 131', 'UTILIDADES',
        'VE', NULL, v_md3, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Participación en las Ganancias (Utilidades) — LOTTT Art. 131',
        "TemplateType" = 'UTILIDADES',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md3,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 4: VE_LIQUIDACION
    -- -----------------------------------------------
    v_md4 := '# PLANILLA DE LIQUIDACIÓN DE PRESTACIONES SOCIALES

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

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_LIQUIDACION',
        'Liquidación de Prestaciones Sociales — LOTTT Arts. 142-143', 'LIQUIDACION',
        'VE', NULL, v_md4, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Liquidación de Prestaciones Sociales — LOTTT Arts. 142-143',
        "TemplateType" = 'LIQUIDACION',
        "CountryCode"  = 'VE',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md4,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 5: ES_NOMINA_OFICIAL
    -- -----------------------------------------------
    v_md5 := '# RECIBO DE SALARIOS (NÓMINA)

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

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'ES_NOMINA_OFICIAL',
        'Nómina Oficial — RD 1784/1996 España', 'NOMINA_ES',
        'ES', NULL, v_md5, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Nómina Oficial — RD 1784/1996 España',
        "TemplateType" = 'NOMINA_ES',
        "CountryCode"  = 'ES',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md5,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    -- -----------------------------------------------
    -- PLANTILLA 6: ES_FINIQUITO
    -- -----------------------------------------------
    v_md6 := '# FINIQUITO DE RELACIÓN LABORAL

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

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'ES_FINIQUITO',
        'Finiquito de Relación Laboral — ET Art. 49 España', 'FINIQUITO_ES',
        'ES', NULL, v_md6, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Finiquito de Relación Laboral — ET Art. 49 España',
        "TemplateType" = 'FINIQUITO_ES',
        "CountryCode"  = 'ES',
        "PayrollCode"  = NULL,
        "ContentMD"    = v_md6,
        "IsDefault"    = TRUE,
        "IsSystem"     = TRUE,
        "IsActive"     = TRUE,
        "UpdatedAt"    = (NOW() AT TIME ZONE 'UTC');

    RAISE NOTICE '>> SEED: 6 plantillas legales aplicadas OK';

END;
$$;

-- >> sp_nomina_documentos.sql — despliegue completo OK
