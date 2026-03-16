# Integración con NominaConceptoLegal

## Descripción

Sistema de nómina adaptado para trabajar directamente con la tabla `NominaConceptoLegal` existente, que contiene información legal actualizada de convenios colectivos venezolanos.

## Estructura de NominaConceptoLegal

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| `Id` | Identificador único | 1, 2, 3... |
| `Convencion` | Tipo de convenio | LOT, CCT_PETROLERO |
| `TipoCalculo` | Contexto de cálculo | MENSUAL, VACACIONES, LIQUIDACION |
| `CO_CONCEPT` | Código del concepto | SUELDO, HE, SSO, VAC |
| `NB_CONCEPTO` | Nombre descriptivo | Sueldo base, Horas extras... |
| `FORMULA` | Fórmula de cálculo | `SUELDO`, `SALARIO_HORA * 1.5` |
| `SOBRE` | Base de cálculo adicional | HORAS_EXTRAS, DIAS_TRABAJADOS |
| `TIPO` | Tipo de concepto | ASIGNACION, DEDUCCION |
| `BONIFICABLE` | Suma para utilidades | S, N |
| `LOTTT_Articulo` | Artículo de ley | LOTTT Art. 190 |
| `CCP_Clausula` | Cláusula de convenio | CCP Cláusula 24 |
| `Orden` | Orden de cálculo | 1, 2, 3... |
| `Activo` | Estado del concepto | 1, 0 |

## Convenciones Soportadas

### 1. LOT (Ley Orgánica del Trabajo)
Régimen general para todos los trabajadores venezolanos.

**Conceptos típicos:**
- SUELDO - Salario base
- HE - Horas extras (50% recargo)
- HENOCT - Horas extras nocturnas
- SSO - Seguro Social (4%)
- FAOV - Fondo vivienda (1%)
- VAC - Vacaciones (15 días base)

### 2. CCT_PETROLERO (Contrato Colectivo Petrolero)
Sector petrolero con beneficios superiores.

**Conceptos adicionales:**
- TEA - Tarifa Escala Activa
- TIEMVIAJE - Tiempo de viaje
- VIVIENDA - Ayuda habitacional
- Vacaciones: 34 días base + 55 días bono

### 3. CONSTRUCCION
Sector construcción con prestaciones específicas.

**Conceptos específicos:**
- Bono obra terminada
- Factor de liquidación 1.0833

## Tipo de Cálculo

| Tipo | Descripción | Uso |
|------|-------------|-----|
| **MENSUAL** | Nómina regular mensual | Sueldos, deducciones mensuales |
| **SEMANAL** | Nómina semanal | Construcción, temporal |
| **VACACIONES** | Cálculo de vacaciones | Vacaciones + bono vacacional |
| **LIQUIDACION** | Liquidación final | Prestaciones, indemnización |

## Fórmulas Soportadas

### Variables del Sistema
```
SUELDO              - Sueldo base mensual
SALARIO_DIARIO      - Sueldo / 30
SALARIO_HORA        - Sueldo / 240
SALARIO_INTEGRAL    - Salario normal + alícuotas
DIAS_PERIODO        - Días del período (30, 15, 7)
HORAS_MES           - Horas del período (240, 120, 40)
FERIADOS            - Cantidad de feriados
DOMINGOS            - Cantidad de domingos
DIAS_VACACIONES     - Días de vacaciones según antigüedad
DIAS_BONO_VAC       - Días de bono vacacional
PCT_SSO             - 0.04 (4%)
PCT_FAOV            - 0.01 (1%)
PCT_LRPE            - 0.005 (0.5%)
RECARGO_HE          - 0.50 (50%)
RECARGO_NOCTURNO    - 0.30 (30%)
RECARGO_DESCANSO    - 0.50 (50%)
ANTI_ANIOS          - Años de antigüedad
ANTI_MESES          - Meses de antigüedad
C{CODIGO}           - Valor de otro concepto ya calculado
```

### Operadores
```
+   Suma
-   Resta
*   Multiplicación
/   División
MENOR(a,b)  - Mínimo entre a y b
MAYOR(a,b)  - Máximo entre a y b
```

### Ejemplos de Fórmulas

**SSO con tope:**
```sql
MENOR(TOTAL_ASIGNACIONES * PCT_SSO, TOPE_SSO * SUELDO_MIN * PCT_SSO)
```

**Horas extras diurnas:**
```sql
HORAS_EXTRAS * SALARIO_HORA * (1 + RECARGO_HE)
```

**Vacaciones:**
```sql
DIAS_VACACIONES * SALARIO_DIARIO
```

## API Endpoints

### Listar Conceptos Legales
```
GET /v1/nomina/conceptos-legales

Query params:
  ?convencion=LOT              # LOT, CCT_PETROLERO
  ?tipoCalculo=MENSUAL         # MENSUAL, VACACIONES, LIQUIDACION
  ?tipo=ASIGNACION             # ASIGNACION, DEDUCCION
  ?activo=true
```

### Ver Convenciones Disponibles
```
GET /v1/nomina/convenciones
```

### Procesar Nómina
```
POST /v1/nomina/procesar-conceptolegal

{
  "nomina": "NOM20240201",
  "cedula": "V12345678",
  "fechaInicio": "2024-02-01",
  "fechaHasta": "2024-02-29",
  "convencion": "LOT",              # Opcional, detecta automático
  "tipoCalculo": "MENSUAL"          # Opcional, default MENSUAL
}
```

### Procesar Vacaciones
```
POST /v1/nomina/vacaciones/procesar-conceptolegal

{
  "vacacionId": "VAC001",
  "cedula": "V12345678",
  "fechaInicio": "2024-03-01",
  "fechaHasta": "2024-03-15",
  "convencion": "CCT_PETROLERO"
}
```

### Procesar Liquidación
```
POST /v1/nomina/liquidacion/procesar-conceptolegal

{
  "liquidacionId": "LIQ001",
  "cedula": "V12345678",
  "fechaRetiro": "2024-02-28",
  "convencion": "LOT"
}
```

### Validar Fórmulas
```
POST /v1/nomina/validar-formulas

{
  "convencion": "LOT",
  "tipoCalculo": "MENSUAL"
}
```

## Instalación

```sql
-- 1. Ejecutar el adaptador
:r sp_nomina_conceptolegal_adapter.sql

-- 2. Verificar instalación
SELECT * FROM vw_ConceptosPorRegimen WHERE Convencion = 'LOT';

-- 3. Validar fórmulas
EXEC sp_Nomina_ValidarFormulasConceptoLegal @Convencion = 'LOT';
```

## Ejemplo de Uso Completo

```sql
-- Procesar nómina mensual LOT
DECLARE @Result INT, @Msg NVARCHAR(500);

EXEC sp_Nomina_ProcesarEmpleadoConceptoLegal
    @Nomina = 'NOM20240201',
    @Cedula = 'V12345678',
    @FechaInicio = '2024-02-01',
    @FechaHasta = '2024-02-29',
    @Convencion = 'LOT',
    @TipoCalculo = 'MENSUAL',
    @CoUsuario = 'API',
    @Resultado = @Result OUTPUT,
    @Mensaje = @Msg OUTPUT;

PRINT @Msg;
```

## Integración con Sistema Anterior

El sistema mantiene compatibilidad con:
- `sp_Nomina_ProcesarEmpleado` (sistema anterior)
- `sp_Nomina_ProcesarEmpleadoRegimen` (con régimen)
- `sp_Nomina_ProcesarEmpleadoConceptoLegal` (nuevo, usa tu tabla)

## Ventajas de NominaConceptoLegal

1. **Información Legal Actualizada**: Contiene artículos LOTTT y cláusulas de convenios
2. **Flexibilidad**: Fácil agregar nuevos conceptos sin modificar código
3. **Auditoría**: Trazabilidad de qué artículo/ley aplica a cada concepto
4. **Múltiples Convenios**: Soporta LOT, Petrolero, Construcción, etc.
5. **Validación**: Verificación automática de fórmulas antes de procesar

## Notas Importantes

1. La tabla `NominaConceptoLegal` debe existir antes de ejecutar el adaptador
2. Los conceptos marcados como `Activo = 0` no se procesan
3. El orden de cálculo se respeta según campo `Orden`
4. Las fórmulas pueden referenciar otros conceptos ya calculados usando `C{CO_CONCEPT}`
