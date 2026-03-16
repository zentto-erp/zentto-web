# Sistema de Nómina - DatqBox

## Descripción
Sistema completo de nómina con evaluación de fórmulas dinámicas en SQL Server, reemplazando la lógica de VB6.

## Características

### 1. Evaluación de Fórmulas Dinámicas
- Las fórmulas se almacenan en `ConcNom.FORMULA`
- Variables se reemplazan automáticamente antes de evaluar
- Soporte para operaciones matemáticas: `+`, `-`, `*`, `/`, `^`, `%`

### 2. Variables Disponibles

#### Variables Base (siempre disponibles)
| Variable | Descripción |
|----------|-------------|
| `SUELDO` | Sueldo base del empleado |
| `SUELDO_DIARIO` | Sueldo / días del período |
| `SUELDO_HORA` | Sueldo / (días × 8) |
| `HORAS_MES` | 240 (30 días × 8 horas) |

#### Variables de Antigüedad
| Variable | Descripción |
|----------|-------------|
| `ANTI_ANIOS` | Años de antigüedad |
| `ANTI_MESES` | Meses de antigüedad |
| `ANTI_DIAS` | Días de antigüedad |
| `ANTI_TOTAL_MESES` | Total meses calculados |

#### Variables de Antigüedad (de tabla)
| Variable | Descripción |
|----------|-------------|
| `PREAVISO` | Días de preaviso según antigüedad |
| `LEGAL` | Días legales |
| `VAC_INDUS` | Días vacaciones industriales |
| `CONTRATO` | Días contrato |
| `ADICIONAL` | Días adicionales |
| `BONO_VAC` | Días bono vacacional |
| `NORMAL` | Días vacaciones normales |

#### Variables de Período
| Variable | Descripción |
|----------|-------------|
| `DIAS_PERIODO` | Total días del período |
| `FERIADOS` | Cantidad de feriados |
| `DOMINGOS` | Cantidad de domingos |

#### Variables de Cálculo (proceso)
| Variable | Descripción |
|----------|-------------|
| `TOTAL_ASIGNACIONES` | Acumulado de asignaciones |
| `SALARIO_NORMAL` | Salario promedio diario |
| `SALARIO_INTEGRAL` | Salario + utilidades |

#### Referencias a Conceptos
Los conceptos calculados se guardan como `C{CO_CONCEPT}` (ej: `C0001`, `CSSO`)

### 3. Constantes de Nómina
Definidas en tabla `ConstanteNomina`:
- `BaseUtil` - Base para cálculo de utilidades (%)
- `TECHOSSO` - Tope para retención SSO

## Ejemplos de Fórmulas

### Sueldo Base
```
SUELDO
```

### Retención SSO (sobre salario mensual)
```
SUELDO * 0.04
```

### Bono de Alimentación (sobre días trabajados)
```
DIAS_PERIODO * 10
```

### Vacaciones proporcionales
```
(SALARIO_DIARIO * VAC_INDUS) / 30 * DIAS_PERIODO
```

## API Endpoints

### Conceptos
```
GET    /v1/nomina/conceptos          # Listar conceptos
POST   /v1/nomina/conceptos          # Crear/actualizar concepto
```

### Nómina
```
POST   /v1/nomina/procesar-empleado  # Procesar un empleado
POST   /v1/nomina/procesar           # Procesar nómina completa
GET    /v1/nomina                    # Listar nóminas
GET    /v1/nomina/:nomina/:cedula    # Ver detalle
POST   /v1/nomina/cerrar             # Cerrar nómina
```

### Vacaciones
```
POST   /v1/nomina/vacaciones/procesar
GET    /v1/nomina/vacaciones/list
GET    /v1/nomina/vacaciones/:id
```

### Liquidación
```
POST   /v1/nomina/liquidacion/calcular
GET    /v1/nomina/liquidaciones/list
GET    /v1/nomina/liquidaciones/:id
```

### Constantes
```
GET    /v1/nomina/constantes
POST   /v1/nomina/constantes
```

## Ejemplos de Uso

### Procesar nómina de un empleado
```json
POST /v1/nomina/procesar-empleado
{
  "nomina": "NOM20240201",
  "cedula": "V12345678",
  "fechaInicio": "2024-02-01",
  "fechaHasta": "2024-02-15"
}
```

### Procesar nómina completa
```json
POST /v1/nomina/procesar
{
  "nomina": "NOM20240201",
  "fechaInicio": "2024-02-01",
  "fechaHasta": "2024-02-15",
  "soloActivos": true
}
```

### Calcular vacaciones
```json
POST /v1/nomina/vacaciones/procesar
{
  "vacacionId": "VAC001",
  "cedula": "V12345678",
  "fechaInicio": "2024-03-01",
  "fechaHasta": "2024-03-15",
  "fechaReintegro": "2024-03-16"
}
```

### Calcular liquidación
```json
POST /v1/nomina/liquidacion/calcular
{
  "liquidacionId": "LIQ001",
  "cedula": "V12345678",
  "fechaRetiro": "2024-02-28",
  "causaRetiro": "RENUNCIA"
}
```

## Instalación

Ejecutar los scripts SQL en orden:
1. `sp_nomina_sistema.sql` - Funciones base
2. `sp_nomina_calculo.sql` - Motor de cálculo
3. `sp_nomina_vacaciones_liquidacion.sql` - Vacaciones y liquidación
4. `sp_nomina_consultas.sql` - Consultas y listados

O ejecutar todo con:
```sql
:r sp_nomina_run_all.sql
```

## Migración desde VB6

El sistema reemplaza las siguientes funciones de VB6:
- `EvaluateExpr()` → `sp_Nomina_EvaluarFormula`
- `FUNC_FERIADOS()` → `fn_Nomina_ContarFeriados`
- `FUNC_DOMINGOS()` → `fn_Nomina_ContarDomingos`
- `FUNC_DIASANTIGUO()` → `sp_Nomina_CalcularAntiguedad`
- `FUNC_SALARIOS()` → `sp_Nomina_CalcularSalariosPromedio`

Las fórmulas existentes en `ConcNom.FORMULA` son compatibles sin modificaciones.
