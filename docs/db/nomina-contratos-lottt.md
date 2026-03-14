# Resumen: Contratos Colectivos y LOTTT Venezuela – Base para nómina

Investigación para parametrizar fórmulas y constantes por convención (LOT/LOTTT, CCT Petrolero, CCT Construcción) y por tipo de cálculo (nómina semanal/quincenal/mensual, vacaciones, liquidación, utilidades).

---

## 1. Marco legal común (LOTTT 2012)

### 1.1 Prestaciones sociales (Art. 142 y 143 LOTTT)

- **Garantía trimestral:** 15 días de salario por trimestre (depósito patronal).
- **Garantía anual (después del 1er año):** 2 días de salario adicionales por año, acumulativos hasta **máximo 30 días**.
- **Al terminar la relación:** 30 días de salario por cada año de servicio (o fracción > 6 meses), sobre **último salario devengado**.
- **Regla:** el trabajador recibe el **monto mayor** entre lo depositado (trimestral + anual) y el cálculo retroactivo (30 × años).
- **Primeros 3 meses:** 5 días de salario por mes trabajado o fracción.
- **Intereses:** tasa activa BCV si el pago se retrasa (plazo: 5 días tras la terminación).

### 1.2 Vacaciones (LOTTT Título III, Cap. IX – Arts. 189-203)

- **Mínimo legal:** 15 días hábiles anuales después de 1 año continuo.
- **Progresión:** +1 día por cada año desde el 2º año, hasta **15 días adicionales** (máx. 30 días totales por ley).
- **Irrenunciables** y no pueden empeorarse por convenio.

### 1.3 Bono vacacional (LOTTT)

- **Mínimo:** 15 días de salario normal + 1 día por cada año de servicio, hasta **30 días** (carácter salarial).

### 1.4 Utilidades (LOTTT)

- Participación en beneficios; forma parte de la base para prestaciones y salario integral.
- **Base de cálculo:** suele usarse promedio de ingresos (ej. últimas 6 semanas o último mes) para alícuota diaria.

### 1.5 Salario integral

- Incluye salario normal + alícuota de utilidades (y, según convenio, bono vacacional).
- Usado para prestaciones, antigüedad e indemnizaciones (Art. 142 y siguientes).

### 1.6 Deducciones legales (trabajador)

| Concepto | Base de cálculo | % | Nota |
|----------|------------------|---|------|
| **SSO (IVSS)** | Salario / total devengado (techo ~5 SM) | 4% | Trabajador |
| **FAOV** | **Salario integral / total devengado** (Ley Vivienda: comisiones, primas, utilidades, bonos, etc.) | 1% | Vivienda; patrono 2% |
| **LRPE (paro forzoso)** | Salario (techo ~10 SM) | 0,5% – 2% | Según normativa vigente |
| **INCE (sobre utilidades)** | Monto utilidades pagadas | 0,5% | Sobre utilidades |

En el sistema, **FAOV y SSO** se calculan sobre **TOTAL_ASIGNACIONES** (total devengado del período) para alinear con la base legal habitacional y cotización.

### 1.7 Horas extras, descanso y feriados trabajados (LOTTT / RPLOTTT)

- **Horas extras:** recargo mínimo **50%** sobre hora ordinaria (LOTTT 175-178).
- **Feriado o descanso obligatorio trabajado:** recargo **100%** (pago doble).
- **Hora nocturna** (7pm-5am): recargo adicional **30%** sobre salario diurno.
- Variables en fórmulas: `HORAS_EXTRAS`, `HORAS_EXTRAS_NOCTURNAS`, `FERIADOS_TRABAJADOS`, `DOMINGOS_TRABAJADOS`.

*(Porcentajes y techos deben confirmarse con normativa vigente y Gaceta Oficial.)*

---

## 2. Contrato colectivo petrolero (CCT / Convención Petrolera)

**Referencias:** Convención Colectiva Petrolera (ej. 2011/2013, 2019/2021); LOTTT.

### 2.1 Parámetros típicos (gananciales / convenio)

- **Vacaciones:** hasta **34 días** (por encima del mínimo legal).
- **Bono vacacional:** hasta **55 días** (convenio).
- **Bono post-vacacional:** ej. **15 días** (convenio).
- **Utilidades:** ej. **120 días** (convenio, base para cálculo).
- **TEA (Tarjeta Electrónica de Alimentación):** monto diario fijo (ej. Bs por día) – LOTTT 190-194, LAT Art. 6, CCP 18.
- **Vivienda:** indemnización sustitutiva / ayuda única – LOTTT 159, CCP 23 (días × monto/día).
- **Horas extras:** LOTTT 178, CCP 24 (horas × tarifa; exceso de jornada).

### 2.2 Cálculo típico vacaciones (ejemplo documento real)

- **Días/mes:** 2,83 (vacaciones), 4,58 (ayuda), 1,25 (bono post).
- **Salarios:** “Salario de vacaciones”, “Salario de utilidades”, “Salario integral”.
- **Fórmula tipo:** `DIAS * SALARIO_VACACIONES` (o SALARIO_NORMAL / SALARIO_INTEGRAL según concepto).

### 2.3 Artículos LOTTT / CCP útiles

- LOTTT 121 (vacaciones), 157 (ayuda vacacional, bono post), 159 (vivienda), 178 (horas extras), 190-194 (TEA, cesta tickets).

---

## 3. Convención colectiva construcción (CCT Construcción)

**Referencias:** Convención Colectiva Industria de la Construcción (ej. 2013-2015); LOTTT.

### 3.1 Parámetros

- **Vacaciones:** mínimo legal **15 días** + progresión (hasta 15 adicionales).
- **Bono vacacional:** mínimo legal (15 + 1 por año hasta 30); la convención puede mejorar (cláusula 44 en CCT 2013-2015).
- **Utilidades:** según LOTTT y convenio sectorial.

### 3.2 Diferencia vs petrolero

- Menos días de vacaciones y bono que el CCT petrolero; más alineado al piso legal LOTTT.
- Otras cláusulas (seguridad, salud, económicas) en el CCT construcción definen montos o porcentajes específicos.

---

## 4. LOT / Régimen general (sin convenio específico)

- **Vacaciones:** 15 días + 1 por año (hasta 15 adicionales).
- **Bono vacacional:** 15 + 1 por año (hasta 30).
- **Prestaciones:** Art. 142/143 LOTTT (15 días/trimestre, 30 días/año al cese).
- **Utilidades:** según LOTTT y política de la empresa.
- **Deducciones:** SSO, FAOV, LRPE, INCE según ley.

---

## 5. Parámetros comunes vs por convenio

| Concepto | LOT / General | CCT Construcción | CCT Petrolero |
|----------|----------------|-------------------|----------------|
| Días vacaciones base | 15 | 15 | hasta 34 |
| Días bono vacacional | 15 + 1/año (máx. 30) | 15 + mejora posible | hasta 55 |
| Bono post-vacacional | no obligatorio | según CCT | ej. 15 |
| Días utilidades (base) | según ley/política | según CCT | ej. 120 |
| Prestaciones (142) | 15 días/trim, 30/año | igual | igual |
| TEA / Cesta tickets | según política | según CCT | sí (LOTTT 190-194, CCP) |
| Vivienda | no obligatorio | según CCT | sí (LOTTT 159, CCP 23) |

---

## 6. Tipos de cálculo en el sistema

- **NOMINA_SEMANAL / QUINCENAL / MENSUAL:** sueldo base, bonos, horas extras, deducciones (SSO, FAOV, LRPE, INCE sobre utilidades si aplica).
- **VACACIONES:** días vacaciones + bono vacacional (+ bono post si aplica) + TEA/vivienda en días vacacionales; salario = promedio/salario vacaciones o integral.
- **LIQUIDACION:** prestaciones (142), vacaciones no gozadas, bono vacacional, utilidades proporcionales, preaviso, indemnización (si aplica), menos descuentos.
- **UTILIDADES:** participación en beneficios; base y porcentaje/días según convenio y política.

---

## 7. Uso en base de datos (concnom / constantes)

- **ConstanteNomina:** almacenar valores numéricos (días base, porcentajes, montos fijos) por código (ej. `DIAS_VACACIONES_LOT`, `DIAS_BONO_VAC_PETROLERO`, `PCT_SSO`, `PCT_FAOV`).
- **ConcNom / NominaConceptoLegal:** fórmulas en texto que referencian variables (`SUELDO`, `SALARIO_DIARIO`, `DIAS_VACACIONES`, `VAC_INDUS`, `BONO_VAC`, `ANTI_TOTAL_MESES`, etc.) y constantes (`a1`, `a2` = códigos en ConstanteNomina).
- **Convención y tipo de cálculo:** tabla de “conocimiento” (ej. NominaConceptoLegal) con convención (LOT, CCT_PETROLERO, CCT_CONSTRUCCION) y tipo (NOMINA_MENSUAL, VACACIONES, LIQUIDACION, UTILIDADES) para generar o rellenar conceptos en `ConcNom` por `CO_NOMINA`.

---

## 8. Fuentes consultadas (resumen)

- LOTTT 2012 (arts. 121, 131, 142, 143, 157, 159, 178, 189-203, 190-194).
- CCT Petrolero (referencias 2011/2013, 2019/2021; Studocu, CVG, noticias).
- CCT Construcción 2013-2015 (SlideShare, cláusula 44).
- Cálculo prestaciones y deducciones: Sistematemis, Venelogía, TugaCetaOficial, documentos tipo “Informe de pago de vacaciones” y “Recibo de prestaciones sociales acumuladas”.

*(Revisar siempre Gaceta Oficial y normativa vigente para porcentajes y techos.)*
