# Sistema de Nómina - Venezuela (LOTTT + Convenios Colectivos)

## Resumen Ejecutivo

Sistema completo de cálculo de nómina basado en la legislación venezolana vigente:
- **LOTTT**: Ley Orgánica del Trabajo, Trabajadores y Trabajadoras (2012)
- **CCT Petrolero**: Contrato Colectivo PDVSA 2019-2021
- **CCO Construcción**: Convenio Colectivo sector construcción
- Extensible a otros sectores (comercio, salud, industria)

## Estructura del Sistema

### Tablas Principales

| Tabla | Descripción |
|-------|-------------|
| `RegimenLaboral` | Catálogo de regímenes (LOT, PETRO, CONST, COMERC, SALUD) |
| `ConstantesNominaExtendida` | Constantes con valores por régimen y referencias legales |
| `ConceptosNominaRegimen` | Conceptos con fórmulas específicas por régimen |
| `VariablesCalculadas` | Variables temporales durante el cálculo |

### Constantes por Régimen

#### 1. Régimen LOT (Ley General)
```sql
VAC_DIAS_BASE = 15              -- Art. 190 LOTTT
VAC_DIAS_ADIC_ANIO = 1          -- Art. 190 LOTTT
VAC_DIAS_MAX = 30               -- Art. 190 LOTTT
BONO_VAC_DIAS = 15              -- Art. 192 LOTTT
UTIL_DIAS_MIN = 30              -- Art. 131 LOTTT
PREST_DIAS_ANTIGUEDAD = 30      -- Art. 142 LOTTT
SSO_PORC_EMPLEADO = 0.04        -- Art. 203 LOTTT (4%)
FAOV_PORC_EMPLEADO = 0.01       -- Art. 203 LOTTT (1%)
```

#### 2. Contrato Petrolero (Más beneficios)
```sql
VAC_DIAS_BASE = 34              -- Cláusula 24 CCT
VAC_DIAS_ADIC_ANIO = 2          -- Cláusula 24 CCT
VAC_DIAS_MAX = 60               -- Cláusula 24 CCT
BONO_VAC_DIAS = 55              -- Cláusula 24 CCT
BONO_VAC_POST_DIAS = 15         -- Cláusula 24 CCT (específico)
UTIL_DIAS_MIN = 120             -- Cláusula 26 CCT
PREST_DIAS_ANTIGUEDAD = 45      -- Cláusula 23 CCT
JOR_TURNO_14x14 = 14            -- Cláusula 18 CCT (turnos)
CESTA_TICKET_DIA = 48.77        -- Cláusula 35 CCT
```

#### 3. Construcción (Obra específica)
```sql
PREST_FACTOR_CONSTRUCCION = 1.0833  -- Factor de liquidación
BONO_OBRA_TERMINADA = 30            -- 30 días al terminar
PREST_BONO_FINIQUITO = 15           -- Bono finiquito
```

## Fórmulas Dinámicas

### Estructura de Fórmulas

Las fórmulas se escriben en campos `Formula` de las tablas y pueden usar:

**Variables disponibles:**
- `SUELDO` - Sueldo base mensual
- `SUELDO_DIARIO` - Sueldo / 30
- `SALARIO_HORA` - Sueldo / 240
- `DIAS_PERIODO` - Días del período de nómina
- `FERIADOS`, `DOMINGOS` - Días especiales
- `VAC_DIAS_BASE`, `BONO_VAC_DIAS` - Constantes del régimen
- `C{CODIGO}` - Valores de conceptos ya calculados

**Operadores:**
```
+  Suma
-  Resta
*  Multiplicación
/  División
^  Potencia
MENOR(a,b)  Mínimo entre a y b
MAYOR(a,b)  Máximo entre a y b
```

### Ejemplos de Fórmulas

#### 1. SSO (4% con tope)
```sql
Formula: MENOR(SUELDO * 0.04, 5 * SUELDO_MINIMO * 0.04)
Sobre: NULL
```

#### 2. Bono Alimentación (Diario × días)
```sql
Formula: CESTA_TICKET_DIA * DIAS_PERIODO
Sobre: NULL
```

#### 3. Horas Extras Nocturnas (100% recargo)
```sql
Formula: HORAS_EXTRAS_NOCTURNAS * (SALARIO_HORA * 2)
Sobre: NULL
```

#### 4. Vacaciones Proporcionales
```sql
Formula: (VAC_DIAS_BASE / 12) * MESES_TRABAJADOS * SALARIO_DIARIO
Sobre: NULL
```

## Tipos de Nómina Soportados

### 1. Semanal
```sql
DIAS_PERIODO = 7
HORAS_PERIODO = 40
FACTOR_MES = 4.333333
```

### 2. Quincenal
```sql
DIAS_PERIODO = 15
HORAS_PERIODO = 120
FACTOR_MES = 2
```

### 3. Mensual
```sql
DIAS_PERIODO = 30
HORAS_PERIODO = 240
DIAS_UTIL_ANO = 360
```

## Cálculos Automáticos

### 1. Vacaciones
```sql
EXEC sp_Nomina_CalcularVacacionesRegimen
    @SessionID, @Regimen, @Anios, @Meses,
    @DiasVacaciones OUTPUT, @DiasBono OUTPUT, @DiasBonoPost OUTPUT
```

**Fórmula:**
```
Vacaciones = MIN(VAC_DIAS_BASE + (AÑOS × VAC_DIAS_ADIC_ANIO), VAC_DIAS_MAX)
Bono = MIN(BONO_VAC_DIAS + (AÑOS × BONO_VAC_ADIC_ANIO), BONO_VAC_MAX)
```

### 2. Utilidades
```sql
EXEC sp_Nomina_CalcularUtilidadesRegimen
    @SessionID, @Regimen, @DiasTrabajados, @SalarioNormal,
    @Utilidades OUTPUT
```

**Fórmula LOT:**
```
Utilidades = SALARIO_DIARIO × DIAS_UTILIDAD × (DIAS_TRABAJADOS / 360)
Mínimo: 30 días, Máximo: 120 días
```

**Fórmula Petrolero:**
```
Utilidades = Promedio últimas 6 semanas × 120 días × (DIAS / 360)
```

### 3. Prestaciones Sociales
```sql
EXEC sp_Nomina_CalcularPrestacionesRegimen
    @SessionID, @Regimen, @Anios, @Meses, @SalarioIntegral,
    @Prestaciones OUTPUT, @Intereses OUTPUT
```

**Fórmula:**
```
Prestaciones = SALARIO_INTEGRAL × DIAS_ANTIGÜEDAD / 30
Intereses = PRESTACIONES × INTERES_ANUAL × AÑOS
Tope: 10 meses de salario (LOT), 12 meses (Petrolero)
```

## Base Legal Referenciada

### LOTTT 2012
| Artículo | Concepto |
|----------|----------|
| Art. 104 | Salario Base |
| Art. 118 | Horas Extras y Recargos |
| Art. 119 | Trabajo en Descanso/Feriado |
| Art. 125 | Indemnización por Despido |
| Art. 131 | Utilidades |
| Art. 142 | Prestaciones Sociales |
| Art. 162 | Preaviso |
| Art. 174 | Jornada Laboral |
| Art. 190 | Vacaciones |
| Art. 192 | Bono Vacacional |
| Art. 203 | Seguridad Social |

### CCT Petrolero 2019-2021
| Cláusula | Concepto |
|----------|----------|
| Cláus. 15 | Salario Base Petrolero |
| Cláus. 18 | Turnos y Jornadas |
| Cláus. 20 | Horas Exceso |
| Cláus. 23 | Prestaciones Petrolero |
| Cláus. 24 | Vacaciones y Bonos |
| Cláus. 26 | Utilidades Petrolero |
| Cláus. 27 | Vivienda e Indemnización |
| Cláus. 29 | Indemnización Marinero |
| Cláus. 35 | Cesta Ticket y Alimentación |

## API Endpoints

### Conceptos por Régimen
```
GET  /v1/nomina/conceptos?regimen=PETRO&tipo=ASIGNACION
POST /v1/nomina/conceptos (con campo Regimen)
```

### Procesar Nómina
```
POST /v1/nomina/procesar-empleado
{
  "nomina": "NOM20240201",
  "cedula": "V12345678",
  "fechaInicio": "2024-02-01",
  "fechaHasta": "2024-02-15",
  "regimen": "PETRO"  // Opcional, detecta automático
}
```

### Constantes
```
GET /v1/nomina/constantes?regimen=PETRO
```

## Ejemplo Completo

### Caso: Trabajador Petrolero con 5 años

**Datos:**
- Régimen: PETRO
- Sueldo: 100,000 VES/mes
- Antigüedad: 5 años
- Tipo: Mensual

**Cálculos automáticos:**

```
Vacaciones:        34 + (5 × 2) = 44 días
Bono Vacacional:   55 + (5 × 2) = 65 días  
Bono Post-Vac:     15 días
Total Vacaciones:  124 días × 3,333 VES/día = 413,292 VES

Prestaciones:      45 días/año × 5 años × 3,600 VES = 810,000 VES
Intereses:         810,000 × 6% × 5 = 243,000 VES

Utilidades:        120 días × 3,333 VES × 1 = 400,000 VES (mínimo)
```

## Instalación

```sql
-- 1. Tablas y constantes
:r sp_nomina_constantes_venezuela.sql
:r sp_nomina_constantes_convenios.sql

-- 2. Motor de cálculo
:r sp_nomina_calculo_regimen.sql

-- 3. Verificar
SELECT * FROM RegimenLaboral;
SELECT * FROM ConstantesNominaExtendida WHERE Regimen = 'PETRO';
SELECT * FROM ConceptosNominaRegimen WHERE Regimen = 'LOT';
```

## Extensión a Nuevos Convenios

Para agregar un nuevo convenio colectivo:

1. Insertar régimen en `RegimenLaboral`:
```sql
INSERT INTO RegimenLaboral (Codigo, Nombre, Descripcion, BaseLegal)
VALUES ('MINERO', 'Minería', 'Sector minero', 'CCT Minería 2020');
```

2. Insertar constantes específicas:
```sql
INSERT INTO ConstantesNominaExtendida 
(Codigo, Regimen, Nombre, Valor, TipoDato, Unidad, Categoria, ArticuloLey)
VALUES 
('VAC_DIAS_BASE', 'MINERO', 'Vacaciones Minero', '20', 'NUMERO', 'DIAS', 'VACACIONES', 'CCT Minería');
```

3. Insertar conceptos con fórmulas:
```sql
INSERT INTO ConceptosNominaRegimen 
(CoConcepto, Regimen, NbConcepto, Formula, Tipo, Categoria)
VALUES 
('VAC_MINERO', 'MINERO', 'Vacaciones Sector', 'SUELDO * VAC_DIAS_BASE / 30', 'ASIGNACION', 'VACACIONES');
```

## Notas Importantes

1. **Jerarquía de constantes**: Régimen específico > LOT (general) > Tipo de nómina
2. **Tope salarial**: Se aplica automáticamente según el régimen
3. **Base 360**: Venezuela usa año de 360 días para cálculos laborales
4. **Salario Integral**: Salario Normal + Alícuota de utilidades + Alícuota bono vacacional

## Referencias Legales

- [LOTTT Gaceta Oficial Extraordinaria N° 6.015](http://www.oit.org.br/...)
- [CCT Petrolero 2019-2021](https://archive.org/...)
- [Normas CCO Construcción](https://datalaing.com/...)
