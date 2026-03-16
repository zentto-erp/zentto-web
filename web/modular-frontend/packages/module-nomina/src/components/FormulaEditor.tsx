"use client";

import React, { useState, useRef, useCallback, useMemo, useEffect } from "react";
import {
  Box,
  TextField,
  Paper,
  List,
  ListItemButton,
  ListItemText,
  ListItemIcon,
  Typography,
  Chip,
  Stack,
  Popper,
  Divider,
  Tooltip,
  Alert,
  Collapse,
  IconButton,
} from "@mui/material";
import FunctionsIcon from "@mui/icons-material/Functions";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import PercentIcon from "@mui/icons-material/Percent";
import AccessTimeIcon from "@mui/icons-material/AccessTime";
import CalendarTodayIcon from "@mui/icons-material/CalendarToday";
import PersonIcon from "@mui/icons-material/Person";
import CalculateIcon from "@mui/icons-material/Calculate";
import CategoryIcon from "@mui/icons-material/Category";
import HelpOutlineIcon from "@mui/icons-material/HelpOutline";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import ErrorOutlineIcon from "@mui/icons-material/ErrorOutline";
import LinkIcon from "@mui/icons-material/Link";

// ─── Definición de tokens disponibles ──────────────────────────────

interface FormulaToken {
  token: string;
  label: string;
  description: string;
  category: TokenCategory;
  example?: string;
  insertText?: string; // override al token (ej: para funciones)
}

type TokenCategory =
  | "salario"
  | "tiempo"
  | "constante"
  | "antiguedad"
  | "acumulado"
  | "funcion"
  | "operador"
  | "concepto";

const CATEGORY_META: Record<TokenCategory, { label: string; color: string; icon: React.ReactNode }> = {
  salario: { label: "Salario", color: "#2e7d32", icon: <AttachMoneyIcon fontSize="small" /> },
  tiempo: { label: "Tiempo", color: "#1565c0", icon: <AccessTimeIcon fontSize="small" /> },
  constante: { label: "Constante Legal", color: "#7b1fa2", icon: <PercentIcon fontSize="small" /> },
  antiguedad: { label: "Antigüedad", color: "#e65100", icon: <CalendarTodayIcon fontSize="small" /> },
  acumulado: { label: "Acumulado", color: "#00838f", icon: <CalculateIcon fontSize="small" /> },
  funcion: { label: "Función", color: "#ad1457", icon: <FunctionsIcon fontSize="small" /> },
  operador: { label: "Operador", color: "#546e7a", icon: <CategoryIcon fontSize="small" /> },
  concepto: { label: "Otro Concepto", color: "#f57f17", icon: <LinkIcon fontSize="small" /> },
};

const SYSTEM_TOKENS: FormulaToken[] = [
  // Salario
  { token: "SUELDO", label: "Sueldo Base", description: "Sueldo base mensual del empleado", category: "salario", example: "4800.00" },
  { token: "SUELDO_SEMANAL", label: "Sueldo Semanal", description: "Sueldo mensual × 12 / 52 (salario semanal normalizado)", category: "salario", example: "1107.69" },
  { token: "TOPE_SSO_SEM", label: "Tope SSO Semanal", description: "MIN(SUELDO_SEMANAL, 5×SueldoMin_semanal) — base semanal SSO con tope legal aplicado", category: "salario" },
  { token: "TOPE_RPE_SEM", label: "Tope RPE Semanal", description: "MIN(SUELDO_SEMANAL, 10×SueldoMin_semanal) — base semanal RPE con tope legal aplicado", category: "salario" },
  { token: "SALARIO_DIARIO", label: "Salario Diario", description: "SUELDO / 30", category: "salario", example: "160.00" },
  { token: "SALARIO_HORA", label: "Salario Hora", description: "SUELDO / 240", category: "salario", example: "20.00" },
  { token: "SALARIO_INTEGRAL", label: "Salario Integral", description: "Salario normal + alícuotas de bono vac. y utilidades", category: "salario" },
  { token: "SUELDO_MIN", label: "Salario Mínimo", description: "Salario mínimo legal vigente", category: "salario" },

  // Tiempo
  { token: "DIAS_PERIODO", label: "Días del Período", description: "Días del período: 30 (mensual), 15 (quincenal), 7 (semanal)", category: "tiempo", example: "30" },
  { token: "HORAS_MES", label: "Horas del Período", description: "Horas laborables del período", category: "tiempo", example: "240" },
  { token: "FERIADOS", label: "Feriados", description: "Cantidad de feriados en el período", category: "tiempo" },
  { token: "DOMINGOS", label: "Domingos", description: "Cantidad de domingos en el período", category: "tiempo" },
  { token: "DIAS_VACACIONES", label: "Días Vacaciones", description: "Días de vacaciones según antigüedad del empleado", category: "tiempo" },
  { token: "DIAS_BONO_VAC", label: "Días Bono Vacacional", description: "Días de bono vacacional según antigüedad", category: "tiempo" },
  // Semanas (para cálculo SSO correcto por ley)
  { token: "LUNES_MES", label: "Lunes del Mes", description: "Cantidad de lunes en el mes del período (para cálculo SSO según ley IVSS)", category: "tiempo", example: "4 o 5" },
  { token: "SEMANAS_PERIODO", label: "Semanas del Período", description: "Semanas en el período: 1 (semanal), LUNES_MES/2 (quincenal), LUNES_MES (mensual)", category: "tiempo", example: "4.5" },
  // Variables de entrada del empleado
  { token: "HORAS_HE_D", label: "Horas HE Diurnas", description: "Variable de entrada: horas extras diurnas trabajadas en el período", category: "tiempo" },
  { token: "HORAS_HE_N", label: "Horas HE Nocturnas", description: "Variable de entrada: horas extras nocturnas trabajadas en el período", category: "tiempo" },
  { token: "HORAS_HE_V", label: "Horas HE Voluntarias", description: "Variable de entrada: horas extras voluntarias (España)", category: "tiempo" },
  { token: "DIAS_DESC", label: "Días Descanso Trabajados", description: "Variable de entrada: días de descanso trabajados en el período", category: "tiempo" },

  // Constantes legales
  { token: "PCT_SSO", label: "% SSO", description: "Porcentaje Seguro Social Obligatorio (ej: 0.04 = 4%)", category: "constante", example: "0.04" },
  { token: "PCT_FAOV", label: "% FAOV", description: "Porcentaje Ley Vivienda y Hábitat (ej: 0.01 = 1%)", category: "constante", example: "0.01" },
  { token: "PCT_LRPE", label: "% RPE", description: "Porcentaje Régimen Prestacional Empleo (ej: 0.005 = 0.5%)", category: "constante", example: "0.005" },
  { token: "RECARGO_HE", label: "Recargo H. Extra", description: "Factor recargo hora extra diurna (ej: 1.50)", category: "constante", example: "1.50" },
  { token: "RECARGO_NOCTURNO", label: "Recargo Nocturno", description: "Factor recargo horario nocturno (ej: 1.30)", category: "constante", example: "1.30" },
  { token: "RECARGO_DESCANSO", label: "Recargo Descanso", description: "Factor recargo día de descanso (ej: 1.50)", category: "constante", example: "1.50" },
  { token: "RECARGO_FERIADO", label: "Recargo Feriado", description: "Factor recargo día feriado (ej: 2.00)", category: "constante", example: "2.00" },
  { token: "DIAS_VACACIONES_BASE", label: "Días Vac. Base", description: "Días base vacaciones por ley (ej: 15)", category: "constante", example: "15" },
  { token: "DIAS_BONO_VAC_BASE", label: "Días Bono Vac. Base", description: "Días base bono vacacional (ej: 15)", category: "constante", example: "15" },
  { token: "DIAS_UTILIDADES_MIN", label: "Días Util. Mín", description: "Días mínimos de utilidades por ley (ej: 30)", category: "constante", example: "30" },
  { token: "DIAS_UTILIDADES_MAX", label: "Días Util. Máx", description: "Días máximos de utilidades por ley (ej: 120)", category: "constante", example: "120" },
  { token: "TOPE_SSO", label: "Tope SSO", description: "Tope SSO en salarios mínimos", category: "constante", example: "5" },
  // Constantes patronales
  { token: "PCT_SSO_PATRONO", label: "% SSO Patrono", description: "Aporte patronal SSO: mín=9%, medio=10%, máx=11% según riesgo (default 11%)", category: "constante", example: "0.11" },
  { token: "PCT_RPE_PATRONO", label: "% RPE Patrono", description: "Aporte patronal Paro Forzoso (2%)", category: "constante", example: "0.02" },
  { token: "PCT_FAOV_PATRONO", label: "% FAOV Patrono", description: "Aporte patronal Ley Vivienda (2%)", category: "constante", example: "0.02" },
  { token: "PCT_INCES_PATRONO", label: "% INCES Patrono", description: "Aporte patronal INCES (2%)", category: "constante", example: "0.02" },
  { token: "TOPE_RPE", label: "Tope RPE", description: "Tope RPE en salarios mínimos (10)", category: "constante", example: "10" },
  // España
  { token: "ES_PCT_CC_EMP", label: "SS CC Empleado (ES)", description: "Contingencias comunes empleado España (4.70%)", category: "constante", example: "0.047" },
  { token: "ES_PCT_DESEMP_EMP", label: "SS Desempleo (ES)", description: "Desempleo empleado España (1.55%)", category: "constante", example: "0.0155" },
  { token: "ES_PCT_FP_EMP", label: "SS FP (ES)", description: "Formación Profesional empleado España (0.10%)", category: "constante", example: "0.001" },
  { token: "ES_PCT_SS_PAT", label: "SS Patrono (ES)", description: "SS total patrono España (~29.9%)", category: "constante", example: "0.299" },
  { token: "ES_PCT_IRPF", label: "IRPF (ES)", description: "Retención IRPF España (configurable por tramo)", category: "constante", example: "0.15" },
  // México
  { token: "MX_PCT_IMSS_EMP", label: "IMSS Empleado (MX)", description: "IMSS empleado México (~2.04%)", category: "constante", example: "0.0204" },
  { token: "MX_PCT_IMSS_PAT", label: "IMSS Patrono (MX)", description: "IMSS patrono México (~8.87%)", category: "constante", example: "0.0887" },
  { token: "MX_PCT_INFONAVIT", label: "INFONAVIT (MX)", description: "INFONAVIT patrono México (5%)", category: "constante", example: "0.05" },
  { token: "MX_PCT_ISR", label: "ISR (MX)", description: "Retención ISR México (varía por tramo)", category: "constante", example: "0" },
  // Colombia
  { token: "CO_PCT_SALUD_EMP", label: "Salud Empleado (CO)", description: "Aporte salud empleado Colombia (4%)", category: "constante", example: "0.04" },
  { token: "CO_PCT_PENSION_EMP", label: "Pensión Empleado (CO)", description: "Aporte pensión empleado Colombia (4%)", category: "constante", example: "0.04" },
  { token: "CO_PCT_SALUD_PAT", label: "Salud Patrono (CO)", description: "Aporte salud patrono Colombia (8.5%)", category: "constante", example: "0.085" },
  { token: "CO_PCT_ARL", label: "ARL (CO)", description: "Riesgo laboral patrono Colombia (0.348%-8.7%)", category: "constante", example: "0.00348" },
  // Petroleo/Construccion
  { token: "PETRO_IND_COMIDA", label: "Ind. Comida Petróleo", description: "Indemnización diaria por comida (CCT Petrolero)", category: "constante" },
  { token: "PETRO_HRS_VIAJE_DIA", label: "Hrs Viaje/Día (Petróleo)", description: "Horas de viaje reconocidas por día (CCT Petrolero)", category: "constante" },
  { token: "PETRO_BONO_HERR", label: "Bono Herramienta (Petróleo)", description: "Bono mensual por herramienta (CCT Petrolero)", category: "constante" },
  { token: "CONST_FACTOR_ZONA", label: "Factor Zona (Const.)", description: "Multiplicador de zona geográfica (CCT Construcción)", category: "constante", example: "1.20" },
  { token: "CONST_PCT_PELIGRO", label: "% Peligro (Const.)", description: "% adicional por trabajo peligroso (CCT Construcción)", category: "constante" },

  // Antigüedad
  { token: "ANTI_ANIOS", label: "Años Antigüedad", description: "Años completos de antigüedad del empleado", category: "antiguedad" },
  { token: "ANTI_MESES", label: "Meses Antigüedad", description: "Meses totales de antigüedad del empleado", category: "antiguedad" },

  // Acumulados
  { token: "TOTAL_ASIGNACIONES", label: "Total Asignaciones", description: "Suma de todas las asignaciones calculadas hasta este punto", category: "acumulado" },

  // Funciones
  { token: "MENOR", label: "MENOR(a, b)", description: "Devuelve el menor de dos valores (mínimo)", category: "funcion", example: "MENOR(SUELDO * PCT_SSO, TOPE_SSO)", insertText: "MENOR(, )" },
  { token: "MAYOR", label: "MAYOR(a, b)", description: "Devuelve el mayor de dos valores (máximo)", category: "funcion", example: "MAYOR(SUELDO, SUELDO_MIN)", insertText: "MAYOR(, )" },

  // Operadores
  { token: "+", label: "Suma (+)", description: "Operador de suma", category: "operador" },
  { token: "-", label: "Resta (-)", description: "Operador de resta", category: "operador" },
  { token: "*", label: "Multiplicación (*)", description: "Operador de multiplicación", category: "operador" },
  { token: "/", label: "División (/)", description: "Operador de división", category: "operador" },
];

// ─── Ejemplos de fórmulas comunes ──────────────────────────────

interface FormulaTemplate {
  name: string;
  formula: string;
  description: string;
}

const FORMULA_TEMPLATES: FormulaTemplate[] = [
  { name: "SSO Empleado", formula: "SUELDO * PCT_SSO", description: "Deducción SSO estándar (4%)" },
  { name: "FAOV", formula: "SUELDO * PCT_FAOV", description: "Deducción Ley Vivienda (1%)" },
  { name: "RPE", formula: "SUELDO * PCT_LRPE", description: "Régimen Prestacional Empleo (0.5%)" },
  { name: "SSO con tope", formula: "MENOR(TOTAL_ASIGNACIONES * PCT_SSO, TOPE_SSO * SUELDO_MIN * PCT_SSO)", description: "SSO con tope en salarios mínimos" },
  { name: "Horas extras diurnas", formula: "HORAS_EXTRAS * SALARIO_HORA * RECARGO_HE", description: "Pago de horas extras (variable HORAS_EXTRAS como entrada)" },
  { name: "Bono vacacional", formula: "DIAS_BONO_VAC * SALARIO_DIARIO", description: "Bono vacacional según antigüedad" },
  { name: "Pago vacaciones", formula: "DIAS_VACACIONES * SALARIO_DIARIO", description: "Pago vacaciones según antigüedad" },
  { name: "Bono antigüedad", formula: "ANTI_ANIOS * SALARIO_DIARIO * 5", description: "Bono por años de servicio" },
  { name: "Recargo nocturno", formula: "HORAS_NOCTURNAS * SALARIO_HORA * RECARGO_NOCTURNO", description: "Pago horas nocturnas" },
  { name: "Referencia a otro concepto", formula: "C{SUELDO} + C{BONO}", description: "Suma el valor de otros conceptos ya calculados" },
  // Venezuela - SSO método correcto (por lunes/semanas según IVSS)
  { name: "SSO Empleado (método semanal)", formula: "TOPE_SSO_SEM * PCT_SSO * SEMANAS_PERIODO", description: "Deducción SSO correcta por ley: base semanal × 4% × semanas del período" },
  { name: "RPE Empleado (método semanal)", formula: "TOPE_RPE_SEM * PCT_LRPE * SEMANAS_PERIODO", description: "Deducción Paro Forzoso: base semanal × 0.5% × semanas del período" },
  { name: "FAOV (adapta a período)", formula: "TOTAL_ASIGNACIONES * PCT_FAOV", description: "Ley Vivienda 1% sobre asignaciones del período" },
  { name: "SSO Aporte Patronal", formula: "TOPE_SSO_SEM * PCT_SSO_PATRONO * SEMANAS_PERIODO", description: "Aporte patronal SSO 11% — tipo PATRONAL, no descuenta al empleado" },
  { name: "RPE Aporte Patronal", formula: "TOPE_RPE_SEM * PCT_RPE_PATRONO * SEMANAS_PERIODO", description: "Aporte patronal RPE 2%" },
  { name: "FAOV Aporte Patronal", formula: "TOTAL_ASIGNACIONES * PCT_FAOV_PATRONO", description: "Aporte patronal FAOV 2%" },
  { name: "INCES Patronal (trimestral)", formula: "TOTAL_ASIGNACIONES * PCT_INCES_PATRONO", description: "Aporte patronal INCES 2% — provisión mensual" },
  // CCT Petrolero
  { name: "Indemnización Comida (Petróleo)", formula: "PETRO_IND_COMIDA * DIAS_PERIODO", description: "Indemnización diaria por comida CCT Petrolero" },
  { name: "Tiempo de Viaje (Petróleo)", formula: "PETRO_HRS_VIAJE_DIA * DIAS_PERIODO * SALARIO_HORA", description: "Pago por tiempo de viaje CCT Petrolero" },
  // CCT Construcción
  { name: "Bono de Zona (Construcción)", formula: "SUELDO * CONST_FACTOR_ZONA - SUELDO", description: "Bono diferencial de zona geográfica CCT Construcción" },
  { name: "Trabajo Peligroso (Construcción)", formula: "SUELDO * CONST_PCT_PELIGRO", description: "Prima por trabajo peligroso CCT Construcción" },
  // España
  { name: "SS Empleado España", formula: "SUELDO * (ES_PCT_CC_EMP + ES_PCT_DESEMP_EMP + ES_PCT_FP_EMP)", description: "Seguridad Social empleado España (CC 4.70% + Desempleo 1.55% + FP 0.10%)" },
  { name: "IRPF España", formula: "SUELDO * ES_PCT_IRPF", description: "Retención IRPF España (configurar porcentaje según tramo)" },
  // México
  { name: "IMSS Empleado México", formula: "SUELDO * MX_PCT_IMSS_EMP", description: "IMSS empleado México" },
  // Colombia
  { name: "Salud + Pensión Colombia", formula: "SUELDO * (CO_PCT_SALUD_EMP + CO_PCT_PENSION_EMP)", description: "Aportes salud (4%) + pensión (4%) empleado Colombia" },
  // Horas extras
  { name: "HE Diurnas Venezuela", formula: "HORAS_HE_D * SALARIO_HORA * RECARGO_HE", description: "Horas extras diurnas (50% recargo LOTTT)" },
  { name: "HE Nocturnas Venezuela", formula: "HORAS_HE_N * SALARIO_HORA * RECARGO_HE * RECARGO_NOCTURNO", description: "Horas extras nocturnas (50% HE + 30% nocturno)" },
  { name: "Descanso Trabajado", formula: "DIAS_DESC * SALARIO_DIARIO * RECARGO_DESCANSO", description: "Días de descanso o feriados trabajados" },
];

// ─── Validación de fórmulas ──────────────────────────────

interface ValidationResult {
  valid: boolean;
  message: string;
  unknownTokens: string[];
}

function validateFormula(formula: string, allConceptCodes: string[]): ValidationResult {
  if (!formula || !formula.trim()) {
    return { valid: true, message: "", unknownTokens: [] };
  }

  // Check balanced parentheses
  let depth = 0;
  for (const ch of formula) {
    if (ch === "(") depth++;
    if (ch === ")") depth--;
    if (depth < 0) return { valid: false, message: "Paréntesis sin abrir", unknownTokens: [] };
  }
  if (depth !== 0) return { valid: false, message: "Paréntesis sin cerrar", unknownTokens: [] };

  // Check for invalid characters
  if (!/^[A-Za-z0-9_+\-*/().,{}\s]*$/.test(formula)) {
    return { valid: false, message: "Contiene caracteres no permitidos", unknownTokens: [] };
  }

  // Extract all tokens (words)
  const knownTokenNames = new Set(SYSTEM_TOKENS.map((t) => t.token));
  allConceptCodes.forEach((c) => knownTokenNames.add(c));

  // Also allow C{XXX} references
  const conceptRefs = formula.match(/C\{([^}]+)\}/g) || [];
  const unknownRefs: string[] = [];
  for (const ref of conceptRefs) {
    const code = ref.slice(2, -1);
    if (!allConceptCodes.includes(code) && !knownTokenNames.has(code)) {
      unknownRefs.push(code);
    }
  }

  // Extract word tokens (not inside C{})
  const cleaned = formula.replace(/C\{[^}]*\}/g, ""); // remove C{} refs
  const wordTokens = cleaned.match(/[A-Z_][A-Z0-9_]*/g) || [];
  // Variables de entrada de empleado — válidas aunque no tengan valor por defecto
  const INPUT_VARS = new Set(["HORAS_HE_D", "HORAS_HE_N", "HORAS_HE_V", "DIAS_DESC", "DIAS_CAMPO", "HORAS_NOCTURNAS", "HORAS_EXTRAS"]);
  const unknownTokens = wordTokens.filter(
    (t) => !knownTokenNames.has(t) && !["MENOR", "MAYOR"].includes(t) && !INPUT_VARS.has(t)
  );

  if (unknownRefs.length > 0) {
    return {
      valid: false,
      message: `Concepto(s) no reconocido(s): ${unknownRefs.join(", ")}`,
      unknownTokens: unknownRefs,
    };
  }

  if (unknownTokens.length > 0) {
    // Could be custom input variables — warn but allow
    return {
      valid: true,
      message: `Variable(s) personalizadas (se usarán como entrada): ${unknownTokens.join(", ")}`,
      unknownTokens,
    };
  }

  return { valid: true, message: "Fórmula válida", unknownTokens: [] };
}

// ─── Componente FormulaEditor ──────────────────────────────

interface FormulaEditorProps {
  value: string;
  onChange: (value: string) => void;
  conceptCodes?: string[]; // all concept codes for C{} references
  disabled?: boolean;
}

export default function FormulaEditor({ value, onChange, conceptCodes = [], disabled }: FormulaEditorProps) {
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [showTemplates, setShowTemplates] = useState(false);
  const [filterText, setFilterText] = useState("");
  const [selectedIdx, setSelectedIdx] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const anchorRef = useRef<HTMLDivElement>(null);

  // Build concept tokens from siblings
  const conceptTokens: FormulaToken[] = useMemo(
    () =>
      conceptCodes.map((code) => ({
        token: `C{${code}}`,
        label: code,
        description: `Valor calculado del concepto ${code}`,
        category: "concepto" as TokenCategory,
        insertText: `C{${code}}`,
      })),
    [conceptCodes]
  );

  const allTokens = useMemo(() => [...SYSTEM_TOKENS, ...conceptTokens], [conceptTokens]);

  // Get the current word being typed (for autocomplete)
  const getCurrentWord = useCallback((): string => {
    if (!inputRef.current) return "";
    const pos = inputRef.current.selectionStart ?? value.length;
    const before = value.slice(0, pos);
    const match = before.match(/([A-Z_][A-Z0-9_]*|C\{[^}]*)$/i);
    return match ? match[1].toUpperCase() : "";
  }, [value]);

  // Filtered suggestions
  const suggestions = useMemo(() => {
    const word = filterText.toUpperCase();
    if (!word) return allTokens.filter((t) => t.category !== "operador");
    return allTokens.filter(
      (t) =>
        t.token.toUpperCase().includes(word) ||
        t.label.toUpperCase().includes(word) ||
        t.description.toUpperCase().includes(word)
    );
  }, [filterText, allTokens]);

  // Group suggestions by category
  const groupedSuggestions = useMemo(() => {
    const groups: Record<string, FormulaToken[]> = {};
    for (const s of suggestions) {
      if (!groups[s.category]) groups[s.category] = [];
      groups[s.category].push(s);
    }
    return groups;
  }, [suggestions]);

  // Flat list for keyboard navigation
  const flatSuggestions = useMemo(() => {
    const flat: FormulaToken[] = [];
    for (const cat of Object.keys(groupedSuggestions)) {
      flat.push(...groupedSuggestions[cat]);
    }
    return flat;
  }, [groupedSuggestions]);

  // Validation
  const validation = useMemo(() => validateFormula(value, conceptCodes), [value, conceptCodes]);

  const insertToken = useCallback(
    (token: FormulaToken) => {
      const input = inputRef.current;
      if (!input) return;
      const pos = input.selectionStart ?? value.length;
      const before = value.slice(0, pos);
      const after = value.slice(pos);

      // Find how much to replace (the partial word)
      const match = before.match(/([A-Z_][A-Z0-9_]*|C\{[^}]*)$/i);
      const replaceStart = match ? pos - match[1].length : pos;
      const textToInsert = token.insertText ?? token.token;

      const needsSpaceBefore = replaceStart > 0 && !/[\s(,*+\-/]$/.test(value.slice(0, replaceStart));
      const needsSpaceAfter = after.length > 0 && !/^[\s),*+\-/]/.test(after);

      const newValue =
        value.slice(0, replaceStart) +
        (needsSpaceBefore ? " " : "") +
        textToInsert +
        (needsSpaceAfter ? " " : "") +
        after;

      onChange(newValue);
      setShowSuggestions(false);

      // Set cursor position after insert
      requestAnimationFrame(() => {
        if (!input) return;
        const cursorPos = replaceStart + (needsSpaceBefore ? 1 : 0) + textToInsert.length;
        // For MENOR(, ) and MAYOR(, ) place cursor after opening paren
        if (token.insertText?.includes("(, )")) {
          const parenPos = replaceStart + (needsSpaceBefore ? 1 : 0) + textToInsert.indexOf(",");
          input.setSelectionRange(parenPos, parenPos);
        } else {
          input.setSelectionRange(cursorPos, cursorPos);
        }
        input.focus();
      });
    },
    [value, onChange]
  );

  const applyTemplate = useCallback(
    (template: FormulaTemplate) => {
      onChange(template.formula);
      setShowTemplates(false);
      requestAnimationFrame(() => inputRef.current?.focus());
    },
    [onChange]
  );

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (!showSuggestions || flatSuggestions.length === 0) return;

      if (e.key === "ArrowDown") {
        e.preventDefault();
        setSelectedIdx((i) => Math.min(i + 1, flatSuggestions.length - 1));
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setSelectedIdx((i) => Math.max(i - 1, 0));
      } else if (e.key === "Enter" || e.key === "Tab") {
        if (flatSuggestions[selectedIdx]) {
          e.preventDefault();
          insertToken(flatSuggestions[selectedIdx]);
        }
      } else if (e.key === "Escape") {
        setShowSuggestions(false);
      }
    },
    [showSuggestions, flatSuggestions, selectedIdx, insertToken]
  );

  const handleInputChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const newVal = e.target.value;
      onChange(newVal);

      // Show suggestions when typing letters
      requestAnimationFrame(() => {
        const word = getCurrentWord();
        if (word.length >= 1) {
          setFilterText(word);
          setShowSuggestions(true);
          setSelectedIdx(0);
        } else {
          setShowSuggestions(false);
          setFilterText("");
        }
      });
    },
    [onChange, getCurrentWord]
  );

  // Close suggestions on blur (with delay for click)
  const handleBlur = useCallback(() => {
    setTimeout(() => setShowSuggestions(false), 200);
  }, []);

  // Reset selection when filter changes
  useEffect(() => {
    setSelectedIdx(0);
  }, [filterText]);

  return (
    <Box ref={anchorRef}>
      {/* Main input with validation indicator */}
      <TextField
        inputRef={inputRef}
        label="Fórmula"
        fullWidth
        disabled={disabled}
        value={value}
        onChange={handleInputChange}
        onKeyDown={handleKeyDown}
        onBlur={handleBlur}
        onFocus={() => {
          if (value) {
            const word = getCurrentWord();
            if (word.length >= 1) {
              setFilterText(word);
              setShowSuggestions(true);
            }
          }
        }}
        placeholder="Escribe o selecciona variables... Ej: SUELDO * PCT_SSO"
        InputProps={{
          endAdornment: (
            <Stack direction="row" spacing={0.5} alignItems="center">
              {value && validation.valid && (
                <Tooltip title={validation.message || "Fórmula válida"}>
                  <CheckCircleIcon fontSize="small" color={validation.unknownTokens.length > 0 ? "warning" : "success"} />
                </Tooltip>
              )}
              {value && !validation.valid && (
                <Tooltip title={validation.message}>
                  <ErrorOutlineIcon fontSize="small" color="error" />
                </Tooltip>
              )}
              <Tooltip title="Plantillas de fórmulas comunes">
                <IconButton size="small" onClick={() => setShowTemplates((v) => !v)} disabled={disabled}>
                  <HelpOutlineIcon fontSize="small" />
                </IconButton>
              </Tooltip>
              <Tooltip title="Mostrar todas las variables">
                <IconButton
                  size="small"
                  disabled={disabled}
                  onClick={() => {
                    setFilterText("");
                    setShowSuggestions((v) => !v);
                    inputRef.current?.focus();
                  }}
                >
                  <FunctionsIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            </Stack>
          ),
        }}
        sx={{
          "& .MuiOutlinedInput-root": {
            fontFamily: "monospace",
            fontSize: "0.95rem",
          },
        }}
      />

      {/* Validation message */}
      {value && validation.message && (
        <Collapse in>
          <Alert
            severity={!validation.valid ? "error" : validation.unknownTokens.length > 0 ? "warning" : "success"}
            sx={{ mt: 0.5, py: 0, fontSize: "0.8rem" }}
            icon={false}
          >
            {validation.message}
            {validation.unknownTokens.length > 0 && validation.valid && (
              <Typography variant="caption" display="block" color="text.secondary">
                Tip: Las variables personalizadas se solicitarán al procesar la nómina.
              </Typography>
            )}
          </Alert>
        </Collapse>
      )}

      {/* Token chips for quick reference */}
      {value && (
        <Stack direction="row" spacing={0.5} mt={0.5} flexWrap="wrap" useFlexGap>
          {(value.match(/[A-Z_][A-Z0-9_]*/g) || [])
            .filter((t, i, arr) => arr.indexOf(t) === i && !["MENOR", "MAYOR", "C"].includes(t))
            .slice(0, 8)
            .map((token) => {
              const found = SYSTEM_TOKENS.find((st) => st.token === token);
              const cat = found?.category;
              const meta = cat ? CATEGORY_META[cat] : null;
              return (
                <Chip
                  key={token}
                  label={found ? found.label : token}
                  size="small"
                  variant="outlined"
                  sx={{
                    fontSize: "0.7rem",
                    height: 22,
                    borderColor: meta?.color ?? "#999",
                    color: meta?.color ?? "#666",
                  }}
                />
              );
            })}
        </Stack>
      )}

      {/* Autocomplete suggestions dropdown */}
      <Popper
        open={showSuggestions && flatSuggestions.length > 0}
        anchorEl={anchorRef.current}
        placement="bottom-start"
        style={{ zIndex: 1400, width: anchorRef.current?.offsetWidth ?? 400 }}
      >
        <Paper
          elevation={8}
          sx={{
            maxHeight: 320,
            overflow: "auto",
            mt: 0.5,
            border: "1px solid",
            borderColor: "divider",
          }}
        >
          {Object.entries(groupedSuggestions).map(([cat, tokens]) => {
            const meta = CATEGORY_META[cat as TokenCategory];
            return (
              <React.Fragment key={cat}>
                <Typography
                  variant="caption"
                  sx={{
                    px: 1.5,
                    py: 0.5,
                    display: "flex",
                    alignItems: "center",
                    gap: 0.5,
                    bgcolor: "action.hover",
                    color: meta?.color ?? "text.secondary",
                    fontWeight: 700,
                    fontSize: "0.7rem",
                    textTransform: "uppercase",
                    letterSpacing: 1,
                    position: "sticky",
                    top: 0,
                    zIndex: 1,
                  }}
                >
                  {meta?.icon} {meta?.label ?? cat}
                </Typography>
                <List dense disablePadding>
                  {tokens.map((token) => {
                    const globalIdx = flatSuggestions.indexOf(token);
                    return (
                      <ListItemButton
                        key={token.token + token.category}
                        selected={globalIdx === selectedIdx}
                        onClick={() => insertToken(token)}
                        sx={{ py: 0.25 }}
                      >
                        <ListItemIcon sx={{ minWidth: 32, color: meta?.color }}>
                          {meta?.icon}
                        </ListItemIcon>
                        <ListItemText
                          primary={
                            <Stack direction="row" alignItems="center" spacing={1}>
                              <Typography
                                variant="body2"
                                fontFamily="monospace"
                                fontWeight={600}
                                sx={{ color: meta?.color }}
                              >
                                {token.token}
                              </Typography>
                              {token.example && (
                                <Chip label={`ej: ${token.example}`} size="small" sx={{ height: 18, fontSize: "0.65rem" }} />
                              )}
                            </Stack>
                          }
                          secondary={token.description}
                          secondaryTypographyProps={{ fontSize: "0.75rem" }}
                        />
                      </ListItemButton>
                    );
                  })}
                </List>
              </React.Fragment>
            );
          })}
        </Paper>
      </Popper>

      {/* Templates panel */}
      <Collapse in={showTemplates}>
        <Paper variant="outlined" sx={{ mt: 1, p: 1.5 }}>
          <Typography variant="subtitle2" gutterBottom sx={{ display: "flex", alignItems: "center", gap: 0.5 }}>
            <FunctionsIcon fontSize="small" /> Plantillas de Fórmulas Comunes
          </Typography>
          <Divider sx={{ mb: 1 }} />
          <Stack spacing={0.5}>
            {FORMULA_TEMPLATES.map((tpl) => (
              <Box
                key={tpl.name}
                onClick={() => applyTemplate(tpl)}
                sx={{
                  p: 1,
                  borderRadius: 1,
                  cursor: "pointer",
                  "&:hover": { bgcolor: "action.hover" },
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <Box>
                  <Typography variant="body2" fontWeight={600}>
                    {tpl.name}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {tpl.description}
                  </Typography>
                </Box>
                <Chip
                  label={tpl.formula}
                  size="small"
                  sx={{
                    fontFamily: "monospace",
                    fontSize: "0.72rem",
                    maxWidth: 260,
                    "& .MuiChip-label": { overflow: "hidden", textOverflow: "ellipsis" },
                  }}
                />
              </Box>
            ))}
          </Stack>
        </Paper>
      </Collapse>
    </Box>
  );
}
