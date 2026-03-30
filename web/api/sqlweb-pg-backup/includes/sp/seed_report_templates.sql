-- ============================================================================
--  Archivo : seed_report_templates.sql (PostgreSQL)
--  Esquema : acct
--  Base    : datqboxweb
--
--  Descripcion:
--    Seeds de plantillas de reportes financieros legales para Venezuela y Espana.
--    12 plantillas por defecto con contenido Markdown y variables {{...}}.
--
--  Venezuela (7): VEN-NIF / BA VEN-NIF / NIC 29 / DPC-10
--  Espana (5): PGC (RD 1514/2007) / PGC-PYME (RD 1515/2007)
--
--  Patron: Idempotente con NOT EXISTS
--  Convertido desde SQL Server
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '=== seed_report_templates.sql — Inicio ===';

  -- ============================================================================
  -- VENEZUELA: 7 plantillas
  -- ============================================================================

  -- 1. Estado de Situacion Financiera (Balance General) - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'BALANCE_GENERAL_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'BALANCE_GENERAL_VE',
      'Estado de Situacion Financiera',
      'VEN-NIF',
      'BA VEN-NIF 1, parrafos 55-80; NIC 1 parrafos 54-80A',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}
### {{companyAddress}}

---

## ESTADO DE SITUACION FINANCIERA
### Al {{reportDate}}
### (Expresado en {{currency}})

*Preparado de acuerdo con los Principios de Contabilidad Generalmente Aceptados en Venezuela (VEN-NIF)*
*Ref. BA VEN-NIF 1, parrafos 55-80*

---

### ACTIVOS

#### Activos Corrientes
{{table:activosCorrientes}}

**Total Activos Corrientes: {{totalActivosCorrientes}}**

#### Activos No Corrientes
{{table:activosNoCorrientes}}

**Total Activos No Corrientes: {{totalActivosNoCorrientes}}**

### **TOTAL ACTIVOS: {{totalActivos}}**

---

### PASIVOS

#### Pasivos Corrientes
{{table:pasivosCorrientes}}

**Total Pasivos Corrientes: {{totalPasivosCorrientes}}**

#### Pasivos No Corrientes
{{table:pasivosNoCorrientes}}

**Total Pasivos No Corrientes: {{totalPasivosNoCorrientes}}**

### **TOTAL PASIVOS: {{totalPasivos}}**

---

### PATRIMONIO
{{table:patrimonio}}

### **TOTAL PATRIMONIO: {{totalPatrimonio}}**

---

### **TOTAL PASIVOS Y PATRIMONIO: {{totalPasivosPatrimonio}}**

---

*Las notas que se acompanan forman parte integral de estos estados financieros.*

| | |
|---|---|
| _________________________ | _________________________ |
| Representante Legal | Contador Publico |
| | CPC N° {{cpcNumber}} |',
      '{"showLogo":true,"showRIF":true,"showAddress":true}',
      '{"showSignatures":true,"showNotes":true,"showPageNumbers":true}');
    RAISE NOTICE 'Plantilla BALANCE_GENERAL_VE creada.';
  END IF;

  -- 2. Estado de Resultados Integral - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'ESTADO_RESULTADOS_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'ESTADO_RESULTADOS_VE',
      'Estado de Resultados Integral',
      'VEN-NIF',
      'BA VEN-NIF 1, parrafos 81-105; NIC 1 parrafos 81-105',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}

---

## ESTADO DE RESULTADOS INTEGRAL
### Del {{fechaDesde}} al {{fechaHasta}}
### (Expresado en {{currency}})

*Ref. BA VEN-NIF 1, parrafos 81-105*

---

### INGRESOS OPERACIONALES
{{table:ingresosOperacionales}}

**Total Ingresos: {{totalIngresos}}**

### COSTOS
{{table:costos}}

### **UTILIDAD BRUTA: {{utilidadBruta}}**

### GASTOS OPERACIONALES
{{table:gastosOperacionales}}

### **UTILIDAD OPERACIONAL: {{utilidadOperacional}}**

### OTROS INGRESOS Y GASTOS
{{table:otrosIngresosGastos}}

### RESULTADO MONETARIO DEL PERIODO (REME)
{{reme}}

### **UTILIDAD (PERDIDA) ANTES DE IMPUESTOS: {{utilidadAntesImpuestos}}**

### IMPUESTO SOBRE LA RENTA
{{isrl}}

### **UTILIDAD (PERDIDA) NETA DEL EJERCICIO: {{utilidadNeta}}**

---

*Las notas que se acompanan forman parte integral de estos estados financieros.*',
      '{"showLogo":true,"showRIF":true}',
      '{"showSignatures":true,"showNotes":true}');
    RAISE NOTICE 'Plantilla ESTADO_RESULTADOS_VE creada.';
  END IF;

  -- 3. Estado de Cambios en el Patrimonio - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'CAMBIOS_PATRIMONIO_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'CAMBIOS_PATRIMONIO_VE',
      'Estado de Cambios en el Patrimonio',
      'VEN-NIF',
      'BA VEN-NIF 1, parrafos 106-110; NIC 1 parrafos 106-110',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}

---

## ESTADO DE CAMBIOS EN EL PATRIMONIO
### Ejercicio fiscal finalizado el {{reportDate}}
### (Expresado en {{currency}})

*Ref. BA VEN-NIF 1, parrafos 106-110*

---

{{table:cambiosPatrimonio}}

---

**Notas:**
- El capital social autorizado es de {{capitalAutorizado}}.
- La reserva legal se constituye con el 5% de la utilidad neta hasta alcanzar el 10% del capital social (Art. 262 Codigo de Comercio).
- El superavit por revaluacion incluye los ajustes por inflacion segun BA VEN-NIF 2.

*Las notas que se acompanan forman parte integral de estos estados financieros.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla CAMBIOS_PATRIMONIO_VE creada.';
  END IF;

  -- 4. Estado de Flujos de Efectivo - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'FLUJO_EFECTIVO_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'FLUJO_EFECTIVO_VE',
      'Estado de Flujos de Efectivo',
      'VEN-NIF',
      'NIC 7; BA VEN-NIF 1',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}

---

## ESTADO DE FLUJOS DE EFECTIVO
### Del {{fechaDesde}} al {{fechaHasta}}
### (Expresado en {{currency}})

*Ref. NIC 7 - Estado de Flujos de Efectivo*

---

### ACTIVIDADES OPERACIONALES
{{table:actividadesOperacionales}}

**Flujo neto de actividades operacionales: {{flujoOperacional}}**

### ACTIVIDADES DE INVERSION
{{table:actividadesInversion}}

**Flujo neto de actividades de inversion: {{flujoInversion}}**

### ACTIVIDADES DE FINANCIAMIENTO
{{table:actividadesFinanciamiento}}

**Flujo neto de actividades de financiamiento: {{flujoFinanciamiento}}**

---

### **AUMENTO (DISMINUCION) NETO DE EFECTIVO: {{variacionNeta}}**

Efectivo al inicio del periodo: {{efectivoInicio}}
**Efectivo al final del periodo: {{efectivoFinal}}**

---

*Las notas que se acompanan forman parte integral de estos estados financieros.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla FLUJO_EFECTIVO_VE creada.';
  END IF;

  -- 5. Balance de Comprobacion - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'BALANCE_COMPROBACION_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'BALANCE_COMPROBACION_VE',
      'Balance de Comprobacion',
      'VEN-NIF',
      'Codigo de Comercio Art. 32-35; LISLR Art. 90',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}

---

## BALANCE DE COMPROBACION
### Del {{fechaDesde}} al {{fechaHasta}}
### (Expresado en {{currency}})

*Ref. Codigo de Comercio Art. 32-35*

---

{{table:balanceComprobacion}}

---

| Totales | Debe | Haber |
|---|---|---|
| **Sumas iguales** | **{{totalDebe}}** | **{{totalHaber}}** |

---

*Este balance de comprobacion fue preparado con base en los libros legales de la empresa.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla BALANCE_COMPROBACION_VE creada.';
  END IF;

  -- 6. REME (Resultado Monetario) - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'REME_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'REME_VE',
      'Resultado Monetario del Periodo (REME)',
      'VEN-NIF',
      'BA VEN-NIF 2; NIC 29 parrafos 27-28; DPC-10',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}

---

## RESULTADO MONETARIO DEL PERIODO (REME)
### Del {{fechaDesde}} al {{fechaHasta}}
### (Expresado en {{currency}})

*Ref. BA VEN-NIF 2 - Criterios para el reconocimiento de la inflacion en la informacion financiera*
*NIC 29 - Informacion Financiera en Economias Hiperinflacionarias*

---

### Datos del Indice de Precios
| Concepto | Valor |
|---|---|
| INPC inicio del periodo | {{inpcInicio}} |
| INPC fin del periodo | {{inpcFin}} |
| Factor de reexpresion | {{factorReexpresion}} |
| Inflacion acumulada anual | {{inflacionAcumulada}}% |

---

### Posicion Monetaria Neta
{{table:posicionMonetaria}}

### **RESULTADO MONETARIO (Ganancia/Perdida): {{reme}}**

---

**Nota:** Una ganancia monetaria indica que la empresa mantiene una posicion monetaria neta pasiva (deudora neta). Una perdida monetaria indica posicion monetaria neta activa.

*Las notas que se acompanan forman parte integral de estos estados financieros.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla REME_VE creada.';
  END IF;

  -- 7. Notas a los Estados Financieros - VE
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'NOTAS_EF_VE' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'VE', 'NOTAS_EF_VE',
      'Notas a los Estados Financieros',
      'VEN-NIF',
      'BA VEN-NIF 1, parrafos 112-138; NIC 1 parrafos 112-138',
      true,
      '# {{companyName}}
### RIF: {{companyRIF}}

---

## NOTAS A LOS ESTADOS FINANCIEROS
### Al {{reportDate}}
### (Expresado en {{currency}})

*Ref. BA VEN-NIF 1, parrafos 112-138*

---

### NOTA 1 - INFORMACION GENERAL
{{companyName}}, RIF {{companyRIF}}, es una empresa constituida en {{companyCountry}}, cuya actividad principal es {{companyActivity}}. Domicilio: {{companyAddress}}.

### NOTA 2 - BASES DE PREPARACION
Los estados financieros han sido preparados de conformidad con los Principios de Contabilidad Generalmente Aceptados en Venezuela (VEN-NIF), los cuales comprenden las Normas Internacionales de Informacion Financiera adaptadas mediante los Boletines de Aplicacion (BA VEN-NIF).

### NOTA 3 - POLITICAS CONTABLES SIGNIFICATIVAS
{{notaPoliticas}}

### NOTA 4 - EFECTOS DE LA INFLACION
La empresa ha aplicado el metodo del Nivel General de Precios (NGP) utilizando el Indice Nacional de Precios al Consumidor (INPC) publicado por el Banco Central de Venezuela, de acuerdo con BA VEN-NIF 2 y NIC 29.

Factor de reexpresion del periodo: {{factorReexpresion}}
Resultado monetario (REME): {{reme}}

### NOTA 5 - EFECTIVO Y EQUIVALENTES
{{notaEfectivo}}

### NOTA 6 - CUENTAS POR COBRAR
{{notaCxC}}

### NOTA 7 - INVENTARIOS
{{notaInventarios}}

### NOTA 8 - PROPIEDAD, PLANTA Y EQUIPO
{{notaPPE}}

### NOTA 9 - CUENTAS POR PAGAR
{{notaCxP}}

### NOTA 10 - PATRIMONIO
{{notaPatrimonio}}

---

*Estas notas forman parte integral de los estados financieros.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla NOTAS_EF_VE creada.';
  END IF;

  -- ============================================================================
  -- ESPANA: 5 plantillas
  -- ============================================================================

  -- 8. Balance de Situacion - ES
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'BALANCE_SITUACION_ES' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'ES', 'BALANCE_SITUACION_ES',
      'Balance de Situacion',
      'PGC',
      'RD 1514/2007 PGC 3a parte; Art. 35 Codigo de Comercio',
      true,
      '# {{companyName}}
### NIF: {{companyNIF}}
### {{companyAddress}}

---

## BALANCE DE SITUACION
### Ejercicio cerrado el {{reportDate}}
### (Expresado en {{currency}})

*Conforme al Plan General de Contabilidad (RD 1514/2007)*
*Ref. PGC 3a parte - Cuentas anuales*

---

### ACTIVO

#### A) ACTIVO NO CORRIENTE
{{table:activoNoCorriente}}
**Total activo no corriente: {{totalActivoNoCorriente}}**

#### B) ACTIVO CORRIENTE
{{table:activoCorriente}}
**Total activo corriente: {{totalActivoCorriente}}**

### **TOTAL ACTIVO: {{totalActivo}}**

---

### PATRIMONIO NETO Y PASIVO

#### A) PATRIMONIO NETO
{{table:patrimonioNeto}}
**Total patrimonio neto: {{totalPatrimonioNeto}}**

#### B) PASIVO NO CORRIENTE
{{table:pasivoNoCorriente}}
**Total pasivo no corriente: {{totalPasivoNoCorriente}}**

#### C) PASIVO CORRIENTE
{{table:pasivoCorriente}}
**Total pasivo corriente: {{totalPasivoCorriente}}**

### **TOTAL PATRIMONIO NETO Y PASIVO: {{totalPasivoPatrimonio}}**

---

*Las notas de la memoria adjunta forman parte integrante de estas cuentas anuales.*

| | |
|---|---|
| _________________________ | _________________________ |
| Administrador | |
| Fecha de formulacion: {{fechaFormulacion}} | |',
      '{"showLogo":true,"showNIF":true,"showAddress":true}',
      '{"showSignatures":true,"showFormulationDate":true}');
    RAISE NOTICE 'Plantilla BALANCE_SITUACION_ES creada.';
  END IF;

  -- 9. Cuenta de Perdidas y Ganancias - ES
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'PYG_ES' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'ES', 'PYG_ES',
      'Cuenta de Perdidas y Ganancias',
      'PGC',
      'RD 1514/2007 PGC 3a parte; Art. 35.2 Codigo de Comercio',
      true,
      '# {{companyName}}
### NIF: {{companyNIF}}

---

## CUENTA DE PERDIDAS Y GANANCIAS
### Ejercicio del {{fechaDesde}} al {{fechaHasta}}
### (Expresado en {{currency}})

*Ref. PGC 3a parte - Cuenta de Perdidas y Ganancias*

---

### A) OPERACIONES CONTINUADAS

**1. Importe neto de la cifra de negocios**
{{table:cifraNegocio}}

**2. Variacion de existencias**
{{variacionExistencias}}

**3. Trabajos realizados por la empresa para su activo**
{{trabajosPropios}}

**4. Aprovisionamientos**
{{table:aprovisionamientos}}

**5. Otros ingresos de explotacion**
{{table:otrosIngresos}}

**6. Gastos de personal**
{{table:gastosPersonal}}

**7. Otros gastos de explotacion**
{{table:otrosGastos}}

**8. Amortizacion del inmovilizado**
{{amortizacion}}

### **A.1) RESULTADO DE EXPLOTACION: {{resultadoExplotacion}}**

**9. Ingresos financieros**
{{ingresosFinancieros}}

**10. Gastos financieros**
{{gastosFinancieros}}

### **A.2) RESULTADO FINANCIERO: {{resultadoFinanciero}}**

### **A.3) RESULTADO ANTES DE IMPUESTOS: {{resultadoAntesImpuestos}}**

**11. Impuesto sobre beneficios**
{{impuestoBeneficios}}

### **A.4) RESULTADO DEL EJERCICIO: {{resultadoEjercicio}}**

---

*Las notas de la memoria adjunta forman parte integrante de estas cuentas anuales.*',
      '{"showLogo":true,"showNIF":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla PYG_ES creada.';
  END IF;

  -- 10. Estado de Cambios en el Patrimonio Neto (ECPN) - ES
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'ECPN_ES' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'ES', 'ECPN_ES',
      'Estado de Cambios en el Patrimonio Neto',
      'PGC',
      'RD 1514/2007 PGC 3a parte; Art. 35.1.c LSC',
      true,
      '# {{companyName}}
### NIF: {{companyNIF}}

---

## ESTADO DE CAMBIOS EN EL PATRIMONIO NETO
### Ejercicio cerrado el {{reportDate}}
### (Expresado en {{currency}})

*Ref. PGC 3a parte - ECPN*

---

### A) ESTADO DE INGRESOS Y GASTOS RECONOCIDOS

| Concepto | Ejercicio N | Ejercicio N-1 |
|---|---|---|
| Resultado de la cuenta de P y G | {{resultadoEjercicio}} | {{resultadoAnterior}} |
| Ingresos y gastos imputados directamente al patrimonio neto | {{ingresosPatrimonio}} | {{ingresosPatrimonioAnt}} |
| Transferencias a la cuenta de P y G | {{transferencias}} | {{transferenciasAnt}} |
| **TOTAL INGRESOS Y GASTOS RECONOCIDOS** | **{{totalReconocidos}}** | **{{totalReconocidosAnt}}** |

### B) ESTADO TOTAL DE CAMBIOS EN EL PATRIMONIO NETO

{{table:cambiosPatrimonioNeto}}

---

*Las notas de la memoria adjunta forman parte integrante de estas cuentas anuales.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla ECPN_ES creada.';
  END IF;

  -- 11. Estado de Flujos de Efectivo - ES
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'EFE_ES' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'ES', 'EFE_ES',
      'Estado de Flujos de Efectivo',
      'PGC',
      'RD 1514/2007 PGC 3a parte; NIC 7',
      true,
      '# {{companyName}}
### NIF: {{companyNIF}}

---

## ESTADO DE FLUJOS DE EFECTIVO
### Ejercicio del {{fechaDesde}} al {{fechaHasta}}
### (Expresado en {{currency}})

*Ref. PGC 3a parte - EFE*
*Nota: Solo obligatorio para empresas que no formulen cuentas anuales abreviadas (Art. 257 LSC)*

---

### A) FLUJOS DE EFECTIVO DE LAS ACTIVIDADES DE EXPLOTACION
{{table:flujosExplotacion}}
**A) Total flujos de explotacion: {{totalFlujosExplotacion}}**

### B) FLUJOS DE EFECTIVO DE LAS ACTIVIDADES DE INVERSION
{{table:flujosInversion}}
**B) Total flujos de inversion: {{totalFlujosInversion}}**

### C) FLUJOS DE EFECTIVO DE LAS ACTIVIDADES DE FINANCIACION
{{table:flujosFinanciacion}}
**C) Total flujos de financiacion: {{totalFlujosFinanciacion}}**

---

### **D) AUMENTO/DISMINUCION NETA DEL EFECTIVO: {{variacionNeta}}**

Efectivo al comienzo del ejercicio: {{efectivoInicio}}
**Efectivo al final del ejercicio: {{efectivoFinal}}**

---

*Las notas de la memoria adjunta forman parte integrante de estas cuentas anuales.*',
      '{"showLogo":true}',
      '{"showSignatures":true}');
    RAISE NOTICE 'Plantilla EFE_ES creada.';
  END IF;

  -- 12. Memoria - ES
  IF NOT EXISTS (SELECT 1 FROM acct."ReportTemplate" WHERE "ReportCode" = 'MEMORIA_ES' AND "CompanyId" = 1) THEN
    INSERT INTO acct."ReportTemplate" ("CompanyId", "CountryCode", "ReportCode", "ReportName", "LegalFramework", "LegalReference", "IsDefault", "TemplateContent", "HeaderJson", "FooterJson")
    VALUES (1, 'ES', 'MEMORIA_ES',
      'Memoria',
      'PGC',
      'RD 1514/2007 PGC 3a parte nota 25; Art. 259 LSC; Art. 35.5 Codigo de Comercio',
      true,
      '# {{companyName}}
### NIF: {{companyNIF}}

---

## MEMORIA DE LAS CUENTAS ANUALES
### Ejercicio cerrado el {{reportDate}}
### (Expresado en {{currency}})

*Ref. PGC 3a parte, Art. 259 Ley de Sociedades de Capital*

---

### 1. ACTIVIDAD DE LA EMPRESA
{{companyName}}, con NIF {{companyNIF}}, tiene como actividad principal {{companyActivity}}. Domicilio social: {{companyAddress}}.

### 2. BASES DE PRESENTACION DE LAS CUENTAS ANUALES
Las cuentas anuales se han preparado a partir de los registros contables de la Sociedad de acuerdo con el Plan General de Contabilidad aprobado por el Real Decreto 1514/2007.

### 3. NORMAS DE REGISTRO Y VALORACION
{{notaValoracion}}

### 4. INMOVILIZADO MATERIAL
{{notaInmovilizado}}

### 5. ACTIVOS FINANCIEROS
{{notaActivosFinancieros}}

### 6. PASIVOS FINANCIEROS
{{notaPasivosFinancieros}}

### 7. FONDOS PROPIOS
{{notaFondosPropios}}

### 8. SITUACION FISCAL
{{notaSituacionFiscal}}

### 9. INGRESOS Y GASTOS
{{notaIngresosGastos}}

### 10. OPERACIONES CON PARTES VINCULADAS
{{notaPartesVinculadas}}

### 11. OTRA INFORMACION
{{notaOtraInfo}}

---

*Estas cuentas anuales fueron formuladas por el organo de administracion el dia {{fechaFormulacion}}.*',
      '{"showLogo":true}',
      '{"showSignatures":true,"showFormulationDate":true}');
    RAISE NOTICE 'Plantilla MEMORIA_ES creada.';
  END IF;

  RAISE NOTICE '=== seed_report_templates.sql completado: 12 plantillas creadas ===';

EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Error en seed_report_templates.sql: %', SQLERRM;
END $$;
