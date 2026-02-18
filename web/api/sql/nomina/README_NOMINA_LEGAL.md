# Nómina – Base de conocimiento legal (LOTTT y CCT Venezuela)

## Objetivo

Parametrizar fórmulas y constantes por **convención** (LOT, CCT Petrolero, CCT Construcción) y por **tipo de cálculo** (nómina semanal/quincenal/mensual, vacaciones, liquidación, utilidades), de forma que el sistema pueda:

- Evaluar fórmulas escritas en la base de datos.
- Usar constantes (días, porcentajes) desde `ConstanteNomina` (referenciables como variables en fórmulas).
- Tener una base de conocimiento (`NominaConceptoLegal`) que luego se copia a `ConcNom` según la nómina/convención que use cada empleado.

## Gananciales y deducciones incluidos

- **Sueldo base**
- **Horas extras:** recargo 50% (LOTTT 175-178). Fórmula: `SALARIO_HORA * (1 + RECARGO_HE)` × variable `HORAS_EXTRAS`
- **Horas extras nocturnas:** recargo 50% + 30% nocturno
- **Descanso legal trabajado** (domingo/descanso obligatorio): recargo 100%. Variable: `DOMINGOS_TRABAJADOS`
- **Feriado trabajado:** recargo 100%. Variable: `FERIADOS_TRABAJADOS`
- **Tiempo de viaje:** `SALARIO_DIARIO * PORC_TIEMPO_VIAJE * DIAS_TIEMPO_VIAJE`. Variable: `DIAS_TIEMPO_VIAJE`
- **TEA / Cesta ticket:** `MONTO_TEA_DIA * DIAS_PERIODO` (constante parametrizable)
- **Comidas / Bono alimentación:** `MONTO_COMIDA_DIA * DIAS_PERIODO`
- **Vivienda** (CCT Petrolero): `MONTO_VIVIENDA_DIA * DIAS_PERIODO` (LOTTT 159, CCP 23)
- **SSO y FAOV:** calculados sobre **total devengado** del período (`TOTAL_ASIGNACIONES`), según base legal (Ley Vivienda: salario integral; IVSS sobre ingreso). El motor debe procesar primero todas las asignaciones y luego las deducciones para que `TOTAL_ASIGNACIONES` esté disponible.

## Variables que debe fijar el proceso o la ficha

Para que las fórmulas de gananciales resuelvan bien, el proceso de nómina (o la carga de datos del empleado) debe dejar en sesión/variables al menos:

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `HORAS_EXTRAS` | Horas extras diurnas en el período | 10 |
| `HORAS_EXTRAS_NOCTURNAS` | Horas extras nocturnas | 0 |
| `DOMINGOS_TRABAJADOS` | Días de descanso obligatorio trabajados | 1 |
| `FERIADOS_TRABAJADOS` | Días feriados trabajados | 0 |
| `DIAS_TIEMPO_VIAJE` | Días/cantidad por tiempo de viaje | 0 |

Si no se definen, usar 0 en constantes o en la lógica que rellena variables.

## Orden de ejecución

1. **create_nomina_convencion_conocimiento.sql**  
   Crea: `NominaConvencion`, `NominaTipoCalculo`, `NominaConceptoLegal`.

2. **seed_gananciales_y_deducciones_completo.sql**  
   - Crea `ConstanteNomina` si no existe.  
   - MERGE de constantes (recargos HE, feriado, descanso, nocturno, PCT_SSO, PCT_FAOV, MONTO_TEA_DIA, etc.).  
   - Inserta en `NominaConceptoLegal` todos los conceptos por convención y tipo (LOT, CCT Petrolero, CCT Construcción; MENSUAL, VACACIONES, LIQUIDACION).

3. **sp_nomina_copiar_conceptos_desde_legal.sql**  
   SP que copia desde `NominaConceptoLegal` a `ConcNom` para una `CO_NOMINA` dada.

**Todo en uno:** ejecutar `run_nomina_legal_completo.sql` (usa `:r`; requiere sqlcmd).

## Uso típico

- Asignar a cada empleado un **tipo de nómina** (`Empleados.NOMINA`) que identifique convención y/o periodicidad (ej. `PETROLERO`, `CONSTRUCCION`, `MENSUAL`).
- Cargar constantes con `sp_Nomina_CargarConstantes` (ya usado en el flujo actual).
- Para poblar conceptos desde el conocimiento legal:
  ```sql
  DECLARE @R INT, @M NVARCHAR(500);
  EXEC sp_Nomina_CopiarConceptosDesdeLegal 
    @CoNomina = 'PETROLERO', 
    @Convencion = 'CCT_PETROLERO', 
    @TipoCalculo = 'MENSUAL', 
    @Sobrescribir = 0, 
    @Resultado = @R OUTPUT, 
    @Mensaje = @M OUTPUT;
  ```
- Las fórmulas en `ConcNom` usan variables como `SUELDO`, `SALARIO_DIARIO`, `SALARIO_INTEGRAL`, `DIAS_VACACIONES`, `BONO_VAC`, `ANTI_TOTAL_MESES`, `PCT_SSO`, etc. (definidas en sesión o en `ConstanteNomina`).

## Documentación legal

- **RESUMEN_CONTRATOS_COLECTIVOS_LOTTT_VENEZUELA.md**: resumen de LOTTT, CCT Petrolero, CCT Construcción, parámetros comunes y por convenio, y deducciones (SSO, FAOV, LRPE, INCE). Sirve de base para mantener constantes y conceptos alineados a la normativa.

## Fuentes

- LOTTT 2012 (arts. 121, 131, 142, 143, 157, 159, 178, 189-203, 190-194).
- CCT Petrolero (convenciones 2011/2013, 2019/2021).
- CCT Construcción (ej. 2013-2015, cláusula 44).
- Documentos tipo “Informe de pago de vacaciones” y “Recibo de prestaciones sociales acumuladas” para casos de uso y fórmulas.
