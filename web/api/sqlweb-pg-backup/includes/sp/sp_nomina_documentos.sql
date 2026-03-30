-- =============================================
-- Archivo  : sp_nomina_documentos.sql
-- PropÃ³sito: Plantillas de Documentos de NÃ³mina (PostgreSQL)
-- Tabla    : hr."DocumentTemplate"
-- Origen   : ConversiÃ³n desde T-SQL (SQL Server 2012 compatible)
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

-- Agregar columna IsSystem si la tabla ya existe sin ella (migraciÃ³n)
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

-- Nuclear drop: eliminar TODAS las sobrecargas por OID para evitar
-- el error "function is not unique" que ocurre cuando conviven
-- sobrecargas con firmas (CHAR vs VARCHAR) diferentes.
DO $do$
DECLARE _oid OID;
BEGIN
  FOR _oid IN
    SELECT p.oid FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname IN (
      'usp_hr_documenttemplate_list',
      'usp_hr_documenttemplate_get',
      'usp_hr_documenttemplate_save',
      'usp_hr_documenttemplate_delete'
    )
  LOOP
    EXECUTE format('DROP FUNCTION IF EXISTS %s CASCADE', _oid::regprocedure);
  END LOOP;
END $do$;

-- --------------------------------------------
-- usp_HR_DocumentTemplate_List
-- Firma canÃ³nica: (INT, VARCHAR, VARCHAR) â€” sin CHAR, sin tamaÃ±o
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_list(
    p_company_id    INT,
    p_country_code  VARCHAR DEFAULT NULL,
    p_template_type VARCHAR DEFAULT NULL
)
RETURNS TABLE(
    "TemplateId"   BIGINT,
    "TemplateCode" VARCHAR,
    "TemplateName" VARCHAR,
    "TemplateType" VARCHAR,
    "CountryCode"  VARCHAR,
    "PayrollCode"  VARCHAR,
    "IsDefault"    BOOLEAN,
    "IsSystem"     BOOLEAN,
    "IsActive"     BOOLEAN,
    "UpdatedAt"    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId"::BIGINT,
        t."TemplateCode"::VARCHAR,
        t."TemplateName"::VARCHAR,
        t."TemplateType"::VARCHAR,
        t."CountryCode"::VARCHAR,
        t."PayrollCode"::VARCHAR,
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."UpdatedAt"::TIMESTAMP
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
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_get(
    p_company_id    INT,
    p_template_code VARCHAR
)
RETURNS TABLE(
    "TemplateId"   BIGINT,
    "TemplateCode" VARCHAR,
    "TemplateName" VARCHAR,
    "TemplateType" VARCHAR,
    "CountryCode"  VARCHAR,
    "PayrollCode"  VARCHAR,
    "ContentMD"    TEXT,
    "IsDefault"    BOOLEAN,
    "IsSystem"     BOOLEAN,
    "IsActive"     BOOLEAN,
    "CreatedAt"    TIMESTAMP,
    "UpdatedAt"    TIMESTAMP
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t."TemplateId"::BIGINT,
        t."TemplateCode"::VARCHAR,
        t."TemplateName"::VARCHAR,
        t."TemplateType"::VARCHAR,
        t."CountryCode"::VARCHAR,
        t."PayrollCode"::VARCHAR,
        t."ContentMD",
        t."IsDefault",
        t."IsSystem",
        t."IsActive",
        t."CreatedAt"::TIMESTAMP,
        t."UpdatedAt"::TIMESTAMP
    FROM hr."DocumentTemplate" t
    WHERE t."CompanyId"    = p_company_id
      AND t."TemplateCode" = p_template_code;
END;
$$;


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Save
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_save(
    p_company_id    INT,
    p_template_code VARCHAR,
    p_template_name VARCHAR,
    p_template_type VARCHAR,
    p_country_code  VARCHAR,
    p_content_md    TEXT,
    p_payroll_code  VARCHAR DEFAULT NULL,
    p_is_default    BOOLEAN DEFAULT FALSE,
    OUT p_resultado INT,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := ''::VARCHAR;

    -- Proteger plantillas del sistema
    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede modificar una plantilla del sistema.'::VARCHAR;
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
        p_country_code, p_payroll_code, p_content_md, COALESCE(p_is_default, FALSE),
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
    p_mensaje   := 'Plantilla guardada correctamente.'::VARCHAR;
END;
$$;


-- --------------------------------------------
-- usp_HR_DocumentTemplate_Delete
-- --------------------------------------------
CREATE OR REPLACE FUNCTION public.usp_hr_documenttemplate_delete(
    p_company_id    INT,
    p_template_code VARCHAR,
    OUT p_resultado INT,
    OUT p_mensaje   TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_resultado := 0;
    p_mensaje   := ''::VARCHAR;

    IF EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
          AND "IsSystem"     = TRUE
    ) THEN
        p_resultado := -1;
        p_mensaje   := 'No se puede eliminar una plantilla del sistema.'::VARCHAR;
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM hr."DocumentTemplate"
        WHERE "CompanyId"    = p_company_id
          AND "TemplateCode" = p_template_code
    ) THEN
        p_resultado := -2;
        p_mensaje   := 'Plantilla no encontrada.'::VARCHAR;
        RETURN;
    END IF;

    DELETE FROM hr."DocumentTemplate"
    WHERE "CompanyId"    = p_company_id
      AND "TemplateCode" = p_template_code;

    p_resultado := 1;
    p_mensaje   := 'Plantilla eliminada correctamente.'::VARCHAR;
END;
$$;


-- =============================================
-- 3. SEED â€” Plantillas legales (IsSystem=TRUE)
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
        RAISE NOTICE '>> SEED: No hay empresa activa en cfg.Company â€” omitiendo seed de plantillas.';
        RETURN;
    END IF;

    -- -----------------------------------------------
    -- PLANTILLA 1: VE_RECIBO_PAGO
    -- -----------------------------------------------
    v_md1 := '# RECIBO DE PAGO DE NÃ“MINA

> **Base Legal:** LOTTT Art. 104 | **RepÃºblica Bolivariana de Venezuela**

---

## Datos del Empleador

| Campo | Valor |
|:------|:------|
| Empresa | {{empresa.nombre}} |
| RIF | {{empresa.rif}} |
| DirecciÃ³n | {{empresa.direccion}} |
| Representante Legal | {{empresa.representante}} |

## Datos del Trabajador

| Campo | Valor |
|:------|:------|
| Nombre Completo | {{empleado.nombre}} |
| CÃ©dula de Identidad | {{empleado.cedula}} |
| Cargo | {{empleado.cargo}} |
| Departamento | {{empleado.departamento}} |
| Fecha de Ingreso | {{empleado.fechaIngreso}} |
| Tipo de NÃ³mina | {{nomina.tipo}} |

## PerÃ­odo de Pago

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

*Yo, **{{empleado.nombre}}**, portador(a) de la C.I. NÂ° {{empleado.cedula}}, declaro haber recibido la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) como pago de nÃ³mina correspondiente al perÃ­odo **{{periodo.desde}}** al **{{periodo.hasta}}**.*

*Conforme con lo establecido en el Art. 104 de la Ley OrgÃ¡nica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT), este recibo acredita el pago de todos los conceptos descritos.*

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
        'Recibo de Pago de NÃ³mina â€” LOTTT Art. 104', 'RECIBO_PAGO',
        'VE', NULL, v_md1, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Recibo de Pago de NÃ³mina â€” LOTTT Art. 104',
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

> **Base Legal:** LOTTT Arts. 190, 191, 192 y 219 | **RepÃºblica Bolivariana de Venezuela**

---

## IdentificaciÃ³n

| | |
|:--|:--|
| **Empresa** | {{empresa.nombre}} |
| **RIF** | {{empresa.rif}} |
| **Trabajador** | {{empleado.nombre}} |
| **CÃ©dula** | {{empleado.cedula}} |
| **Cargo** | {{empleado.cargo}} |

## PerÃ­odo Vacacional

| Concepto | Valor |
|:---------|:------|
| PerÃ­odo de trabajo que origina las vacaciones | {{periodo.desde}} al {{periodo.hasta}} |
| DÃ­as de vacaciones (LOTTT Art. 190) | {{concepto.VAC_PAGO.cantidad}} dÃ­as |
| DÃ­as de bono vacacional (LOTTT Art. 192) | {{concepto.VAC_BONO.cantidad}} dÃ­as |
| **Total dÃ­as de disfrute** | {{concepto.DIAS_TOTALES_VAC}} dÃ­as |

## CÃ¡lculo

{{tabla_todos}}

---

## Resumen

| Concepto | Monto (Bs.) |
|:---------|------------:|
| Pago de Vacaciones | {{concepto.VAC_PAGO.monto}} |
| Bono Vacacional | {{concepto.VAC_BONO.monto}} |
| **Total a Pagar** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, C.I. NÂ° {{empleado.cedula}}, recibo conforme la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) por concepto de vacaciones y bono vacacional del perÃ­odo {{periodo.desde}} al {{periodo.hasta}}, segÃºn lo establecido en los Arts. 190 y 192 de la LOTTT.*

| Firma del Trabajador | Firma del Empleador |
|:--------------------:|:-------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |

*{{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_RECIBO_VACACIONES',
        'Recibo de Vacaciones â€” LOTTT Arts. 190-192', 'RECIBO_VAC',
        'VE', NULL, v_md2, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Recibo de Vacaciones â€” LOTTT Arts. 190-192',
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
    v_md3 := '# PLANILLA DE PARTICIPACIÃ“N EN LAS GANANCIAS (UTILIDADES)

> **Base Legal:** LOTTT Arts. 131, 132 y 133 | **Ejercicio Fiscal {{anio}}**

---

| | |
|:--|:--|
| **Empresa** | {{empresa.nombre}} |
| **RIF** | {{empresa.rif}} |
| **Trabajador** | {{empleado.nombre}} |
| **CÃ©dula** | {{empleado.cedula}} |
| **Cargo** | {{empleado.cargo}} |
| **Fecha de Ingreso** | {{empleado.fechaIngreso}} |

## Base de CÃ¡lculo (LOTTT Art. 131)

| Concepto | Monto |
|:---------|------:|
| Salario Diario Normal | {{concepto.SALARIO_DIARIO.monto}} |
| DÃ­as de Utilidades (mÃ­nimo 30, mÃ¡ximo 120) | {{concepto.DIAS_UTILIDADES.cantidad}} |
| **Total Utilidades** | **{{nomina.neto}}** |

*Las utilidades fueron calculadas sobre el salario normal devengado durante el aÃ±o. El porcentaje mÃ­nimo garantizado es equivalente a **30 dÃ­as de salario** segÃºn el Art. 131 LOTTT.*

---

## CertificaciÃ³n

*La empresa **{{empresa.nombre}}**, RIF {{empresa.rif}}, certifica haber pagado a **{{empleado.nombre}}**, C.I. {{empleado.cedula}}, la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) correspondiente a la ParticipaciÃ³n en las Ganancias del ejercicio {{anio}}, en cumplimiento del Art. 131 de la LOTTT.*

| Recibido Conforme | Representante Empresa |
|:-----------------:|:---------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.nombre}} |

*{{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_PARTICIPACION_GANANCIAS',
        'ParticipaciÃ³n en las Ganancias (Utilidades) â€” LOTTT Art. 131', 'UTILIDADES',
        'VE', NULL, v_md3, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'ParticipaciÃ³n en las Ganancias (Utilidades) â€” LOTTT Art. 131',
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
    v_md4 := '# PLANILLA DE LIQUIDACIÃ“N DE PRESTACIONES SOCIALES

> **Base Legal:** LOTTT Arts. 92, 142, 143 y 144 | **RepÃºblica Bolivariana de Venezuela**

---

## Datos de la RelaciÃ³n Laboral

| Concepto | Valor |
|:---------|:------|
| Empresa | {{empresa.nombre}} |
| RIF | {{empresa.rif}} |
| Trabajador | {{empleado.nombre}} |
| CÃ©dula | {{empleado.cedula}} |
| Cargo | {{empleado.cargo}} |
| Fecha de Ingreso | {{empleado.fechaIngreso}} |
| Fecha de Egreso | {{periodo.hasta}} |
| Causa de TerminaciÃ³n | {{liquidacion.causa}} |
| Tiempo de Servicio | {{empleado.antiguedad}} |

## CÃ¡lculo de Prestaciones y Beneficios

{{tabla_todos}}

---

## Resumen de LiquidaciÃ³n (LOTTT Art. 142)

| Concepto | Monto (Bs.) |
|:---------|------------:|
| GarantÃ­a de Prestaciones Sociales | {{concepto.LIQ_PREST.monto}} |
| Vacaciones Fraccionadas | {{concepto.LIQ_VAC.monto}} |
| Utilidades Fraccionadas | {{concepto.LIQ_UTIL.monto}} |
| Otros Beneficios | {{concepto.LIQ_OTROS.monto}} |
| **TOTAL LIQUIDACIÃ“N** | **{{nomina.totalAsignaciones}}** |
| Deducciones | {{nomina.totalDeducciones}} |
| **NETO A PAGAR** | **{{nomina.neto}}** |

---

*Yo, **{{empleado.nombre}}**, C.I. NÂ° {{empleado.cedula}}, DECLARO haber recibido de la empresa **{{empresa.nombre}}** la cantidad de **Bs. {{nomina.neto}}** ({{nomina.netoLetras}}) en PAGO TOTAL Y DEFINITIVO de todos y cada uno de los conceptos derivados de la relaciÃ³n laboral que me uniÃ³ con dicha empresa desde el {{empleado.fechaIngreso}} hasta el {{periodo.hasta}}, quedando a ambas partes libre de todo compromiso laboral.*

*Este pago incluye todos los beneficios establecidos en la Ley OrgÃ¡nica del Trabajo, los Trabajadores y las Trabajadoras (LOTTT), el contrato colectivo vigente y la legislaciÃ³n aplicable.*

| Firma del Trabajador | Firma del Empleador |
|:--------------------:|:-------------------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| C.I.: {{empleado.cedula}} | {{empresa.rif}} |

*Ante Notario PÃºblico / Inspector del Trabajo si aplica*

*{{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'VE_LIQUIDACION',
        'LiquidaciÃ³n de Prestaciones Sociales â€” LOTTT Arts. 142-143', 'LIQUIDACION',
        'VE', NULL, v_md4, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'LiquidaciÃ³n de Prestaciones Sociales â€” LOTTT Arts. 142-143',
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
    v_md5 := '# RECIBO DE SALARIOS (NÃ“MINA)

> **Base Legal:** RD 1784/1996 art. 2 | **Reino de EspaÃ±a**

---

## I. DATOS DE LA EMPRESA Y TRABAJADOR

| Empresa | CIF/NIF | Centro de Trabajo |
|:--------|:--------|:------------------|
| {{empresa.nombre}} | {{empresa.rif}} | {{empresa.direccion}} |

| Trabajador | NIF | N.Â° S.S. | CategorÃ­a / Grupo Prof. | AntigÃ¼edad |
|:-----------|:----|:---------|:------------------------|:-----------|
| {{empleado.nombre}} | {{empleado.cedula}} | {{empleado.nss}} | {{empleado.cargo}} | {{empleado.fechaIngreso}} |

**PerÃ­odo de liquidaciÃ³n:** Del {{periodo.desde}} al {{periodo.hasta}}

---

## II. DEVENGOS

{{tabla_asignaciones}}

**TOTAL DEVENGOS** | **{{nomina.totalAsignaciones}} â‚¬**

---

## III. DEDUCCIONES

{{tabla_deducciones}}

**TOTAL DEDUCCIONES** | **{{nomina.totalDeducciones}} â‚¬**

---

## IV. BASES DE COTIZACIÃ“N A LA SEGURIDAD SOCIAL

| Base Contingencias Comunes | Base A.T. y E.P. | Base Horas Extra F.M. | Base H.E. Voluntarias |
|---------------------------:|------------------:|----------------------:|----------------------:|
| {{es.baseCC}} â‚¬ | {{es.baseAT}} â‚¬ | {{es.baseHEFM}} â‚¬ | {{es.baseHEV}} â‚¬ |

| Cuota Obrero S.S. | RetenciÃ³n IRPF | Otras Deducciones |
|------------------:|---------------:|------------------:|
| {{concepto.DED_SS_CC.monto}} + {{concepto.DED_SS_DESEMP.monto}} + {{concepto.DED_SS_FP.monto}} â‚¬ | {{concepto.DED_IRPF.monto}} â‚¬ | â€” |

---

## V. LÃQUIDO A PERCIBIR

| Total Devengos | â€” | Total Deducciones | = | **LÃQUIDO A PERCIBIR** |
|---------------:|:-:|------------------:|:-:|:----------------------:|
| {{nomina.totalAsignaciones}} â‚¬ | â€” | {{nomina.totalDeducciones}} â‚¬ | = | **{{nomina.neto}} â‚¬** |

*Firma y sello de la empresa:* _________________________ *RecibÃ­:* _________________________

*{{empresa.nombre}} â€” {{fecha.generacion}} â€” DatqBox*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'ES_NOMINA_OFICIAL',
        'NÃ³mina Oficial â€” RD 1784/1996 EspaÃ±a', 'NOMINA_ES',
        'ES', NULL, v_md5, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'NÃ³mina Oficial â€” RD 1784/1996 EspaÃ±a',
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
    v_md6 := '# FINIQUITO DE RELACIÃ“N LABORAL

> **Base Legal:** Estatuto de los Trabajadores Art. 49 | **Reino de EspaÃ±a**

---

En **{{empresa.direccion}}**, a {{fecha.generacion}},

**De una parte:** La empresa **{{empresa.nombre}}**, con CIF {{empresa.rif}}, representada por **{{empresa.representante}}**.

**De otra parte:** D./DÃ±a. **{{empleado.nombre}}**, con NIF {{empleado.cedula}}, que ha prestado sus servicios en calidad de **{{empleado.cargo}}**.

---

## Hechos

1. La relaciÃ³n laboral entre las partes dio comienzo el dÃ­a **{{empleado.fechaIngreso}}** y se extingue el **{{periodo.hasta}}**.
2. La causa de extinciÃ³n del contrato es: **{{liquidacion.causa}}**.
3. El trabajador ha prestado sus servicios a jornada **{{empleado.tipoJornada}}**.

## LiquidaciÃ³n

{{tabla_todos}}

| Concepto | Importe (â‚¬) |
|:---------|------------:|
| **Total Devengado** | **{{nomina.totalAsignaciones}}** |
| Retenciones e impuestos | {{nomina.totalDeducciones}} |
| **TOTAL LÃQUIDO** | **{{nomina.neto}}** |

---

## DeclaraciÃ³n

*Con la percepciÃ³n de la cantidad de **{{nomina.neto}} â‚¬** ({{nomina.netoLetras}}), el trabajador/a declara quedar **saldado/a y finiquitado/a** de cuantos derechos y acciones pudieran corresponderle derivados de la relaciÃ³n laboral extinguida, incluyendo salarios, vacaciones, pagas extraordinarias, indemnizaciones y cualquier otro concepto.*

*El trabajador/a dispone de un plazo de 3 dÃ­as para solicitar la presencia de un representante sindical antes de la firma.*

---

| El Trabajador | La Empresa |
|:-------------:|:----------:|
| | |
| _________________________ | _________________________ |
| {{empleado.nombre}} | {{empresa.representante}} |
| NIF: {{empleado.cedula}} | {{empresa.nombre}} |

*DatqBox â€” Sistema de GestiÃ³n Laboral*';

    INSERT INTO hr."DocumentTemplate" (
        "CompanyId", "TemplateCode", "TemplateName", "TemplateType",
        "CountryCode", "PayrollCode", "ContentMD", "IsDefault", "IsSystem", "IsActive",
        "CreatedAt", "UpdatedAt"
    )
    VALUES (
        v_seed_company_id, 'ES_FINIQUITO',
        'Finiquito de RelaciÃ³n Laboral â€” ET Art. 49 EspaÃ±a', 'FINIQUITO_ES',
        'ES', NULL, v_md6, TRUE, TRUE, TRUE,
        (NOW() AT TIME ZONE 'UTC'), (NOW() AT TIME ZONE 'UTC')
    )
    ON CONFLICT ("CompanyId", "TemplateCode") DO UPDATE
    SET "TemplateName" = 'Finiquito de RelaciÃ³n Laboral â€” ET Art. 49 EspaÃ±a',
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

-- >> sp_nomina_documentos.sql â€” despliegue completo OK
