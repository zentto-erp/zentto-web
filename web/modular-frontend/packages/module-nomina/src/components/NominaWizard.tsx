"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Button,
  Typography,
  Paper,
  Stack,
  Alert,
  Card,
  CardContent,
  Chip,
  Avatar,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  TextField,
  InputAdornment,
  CircularProgress,
  Autocomplete,
} from "@mui/material";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import dayjs, { type Dayjs } from "dayjs";
import "dayjs/locale/es";

import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import PersonIcon from "@mui/icons-material/Person";
import CalculateIcon from "@mui/icons-material/Calculate";
import AttachMoneyIcon from "@mui/icons-material/AttachMoney";
import ReceiptIcon from "@mui/icons-material/Receipt";
import SaveIcon from "@mui/icons-material/Save";

import { useRouter } from "next/navigation";
import { formatCurrency, useLookup } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { CustomStepper, useToast, FormGrid, FormField } from "@zentto/shared-ui";
import type { StepDef } from "@zentto/shared-ui";
import { EditableDataGrid } from "@zentto/module-contabilidad";
import type { ColumnDef } from "@zentto/datagrid-core";

import {
  useConceptosList,
  useProcesarNominaEmpleado,
  useCerrarNomina,
} from "../hooks/useNomina";
import { useEmpleadosList } from "../hooks/useEmpleados";

// ─── Definición de pasos ───────────────────────────────────────

const STEPS: StepDef[] = [
  { label: "Seleccionar Empleado", icon: <PersonIcon /> },
  { label: "Período y Base", icon: <CalculateIcon /> },
  { label: "Conceptos", icon: <AttachMoneyIcon /> },
  { label: "Resumen y Guardar", icon: <ReceiptIcon /> },
];

// ─── Tipos locales ─────────────────────────────────────────────

interface ConceptoRow {
  id: string;
  codigo: string;
  descripcion: string;
  tipo: "ASIGNACION" | "DEDUCCION";
  formula?: string;
  valor: number;
  editable?: boolean;
}

type EmpleadoRow = Record<string, any>;
type ConceptoApiRow = Record<string, any>;
type CellLike = { value: any };

// ─── Componente Principal ──────────────────────────────────────

interface NominaWizardProps {
  initialCedula?: string | null;
  onClose?: () => void;
}

export default function NominaWizard({ initialCedula, onClose }: NominaWizardProps = {}) {
  const router = useRouter();
  const { showToast } = useToast();
  const { timeZone } = useTimezone();
  const { data: payrollTypes = [] } = useLookup('PAYROLL_TYPE');
  const hasInitialCedula = !!initialCedula;
  const [activeStep, setActiveStep] = useState(hasInitialCedula ? 1 : 0);
  const [error, setError] = useState<string | null>(null);

  // Paso 1: Empleado
  const [cedulaSeleccionada, setCedulaSeleccionada] = useState<string | null>(initialCedula ?? null);

  // Paso 2: Período
  const [fechaInicio, setFechaInicio] = useState<Dayjs | null>(dayjs().tz(timeZone).startOf("month"));
  const [fechaFin, setFechaFin] = useState<Dayjs | null>(dayjs().tz(timeZone).endOf("month"));
  const [tipoCalculo, setTipoCalculo] = useState("MENSUAL");
  const [sueldoBase, setSueldoBase] = useState(0);
  const [diasPeriodo, setDiasPeriodo] = useState(30);

  // Paso 3: Conceptos
  const [conceptos, setConceptos] = useState<ConceptoRow[]>([]);

  // Paso 4: nombre de nómina para el backend
  const [nominaCodigo, setNominaCodigo] = useState("ADMIN");

  // ─── Queries ──────────────────────────────────────────────────

  const empQuery = useEmpleadosList({ status: "ACTIVO", limit: 500 });
  const empleados: EmpleadoRow[] = useMemo(
    () => (Array.isArray(empQuery.data) ? empQuery.data : empQuery.data?.rows ?? []),
    [empQuery.data]
  );

  const conceptosQuery = useConceptosList({ coNomina: nominaCodigo, limit: 200 });
  const conceptosApi: ConceptoApiRow[] = useMemo(
    () => (Array.isArray(conceptosQuery.data) ? conceptosQuery.data : conceptosQuery.data?.rows ?? []),
    [conceptosQuery.data]
  );

  // ─── Mutations ────────────────────────────────────────────────

  const procesarMut = useProcesarNominaEmpleado();
  const cerrarMut = useCerrarNomina();

  // ─── Empleado seleccionado ────────────────────────────────────

  const empleadoObj = useMemo(
    () => empleados.find((e) => (e.CEDULA ?? e.cedula) === cedulaSeleccionada),
    [empleados, cedulaSeleccionada]
  );

  // ─── Helpers ──────────────────────────────────────────────────

  const empCedula = (e: EmpleadoRow | null | undefined) => e?.CEDULA ?? e?.cedula ?? "";
  const empNombre = (e: EmpleadoRow | null | undefined) => e?.NOMBRE ?? e?.nombre ?? "";
  const empCargo = (e: EmpleadoRow | null | undefined) => e?.CARGO ?? e?.cargo ?? "";
  const empNomina = (e: EmpleadoRow | null | undefined) => e?.NOMINA ?? e?.nomina ?? "";
  const empSueldo = (e: EmpleadoRow | null | undefined) => Number(e?.SUELDO ?? e?.sueldo ?? 0);

  const cargarConceptos = () => {
    const sueldo = sueldoBase || empSueldo(empleadoObj);

    // Evalúa fórmula simple reemplazando variables conocidas
    const evalFormula = (formula: string, totalAsig: number): number | null => {
      const vars: Record<string, number> = { SUELDO: sueldo, TOTAL_ASIGNACIONES: totalAsig };
      const match = formula.match(/^(\w+)\s*\*\s*([\d.]+)$/i);
      if (match) {
        const base = vars[match[1].toUpperCase()];
        if (base !== undefined) return base * parseFloat(match[2]);
      }
      return null;
    };

    // Tomar conceptos del API si hay, si no usar por defecto
    if (conceptosApi.length > 0) {
      // Primera pasada: mapear conceptos y calcular asignaciones
      const preMapped = conceptosApi.map((c, i: number) => {
        const tipo = String(c.tipo ?? c.TIPO ?? "ASIGNACION").toUpperCase();
        const valorDefecto = Number(c.valorDefecto ?? c.VALOR_DEFECTO ?? 0);
        const formula = String(c.formula ?? c.FORMULA ?? "");
        let valor = valorDefecto;
        if (valorDefecto === 0 && !formula && tipo === "ASIGNACION" && (c.codigo ?? c.CODIGO ?? "").toUpperCase() === "SUELDO") {
          valor = sueldo;
        } else if (formula) {
          const r = evalFormula(formula, 0);
          if (r !== null) valor = r;
        }
        return { i, tipo, formula, valor, c };
      });

      const totalAsig = preMapped.filter(p => p.tipo !== "DEDUCCION").reduce((s, p) => s + p.valor, 0);

      // Segunda pasada: recalcular deducciones que usan TOTAL_ASIGNACIONES
      const mapped: ConceptoRow[] = preMapped.map((p) => {
        let valor = p.valor;
        if (p.formula && p.formula.includes("TOTAL_ASIGNACIONES")) {
          const r = evalFormula(p.formula, totalAsig);
          if (r !== null) valor = r;
        }
        return {
          id: String(p.i + 1),
          codigo: p.c.codigo ?? p.c.CODIGO ?? "",
          descripcion: p.c.nombre ?? p.c.NOMBRE ?? p.c.descripcion ?? "",
          tipo: (p.tipo === "DEDUCCION" ? "DEDUCCION" : "ASIGNACION") as "ASIGNACION" | "DEDUCCION",
          formula: p.formula || undefined,
          valor,
          editable: !p.formula,
        };
      });
      setConceptos(mapped);
    } else {
      // TODO: fetch from API usp_HR_PayrollConcept_List when no concepts are configured for this payroll
      setConceptos([]);
    }
  };

  const calcResumen = () => {
    const asignaciones = conceptos.filter((c) => c.tipo === "ASIGNACION").reduce((s, c) => s + c.valor, 0);
    const deducciones = conceptos.filter((c) => c.tipo === "DEDUCCION").reduce((s, c) => s + c.valor, 0);
    return { asignaciones, deducciones, neto: asignaciones - deducciones };
  };

  // ─── Navegación ───────────────────────────────────────────────

  const handleNext = async () => {
    setError(null);

    if (activeStep === 0 && !cedulaSeleccionada) {
      setError("Debe seleccionar un empleado");
      return;
    }

    if (activeStep === 1) {
      if (!fechaInicio || !fechaFin) {
        setError("Debe especificar el período de nómina");
        return;
      }
      if (!sueldoBase && empleadoObj) setSueldoBase(empSueldo(empleadoObj));
      cargarConceptos();
    }

    if (activeStep === 2 && conceptos.length === 0) {
      setError("Debe tener al menos un concepto de nómina");
      return;
    }

    setActiveStep((prev) => prev + 1);
  };

  const handleBack = () => {
    setError(null);
    setActiveStep((prev) => prev - 1);
  };

  const handleGuardar = async () => {
    if (!cedulaSeleccionada || !fechaInicio || !fechaFin) return;
    try {
      await procesarMut.mutateAsync({
        nomina: nominaCodigo,
        cedula: cedulaSeleccionada,
        fechaInicio: fechaInicio.format("YYYY-MM-DD"),
        fechaHasta: fechaFin.format("YYYY-MM-DD"),
      });
      showToast("Nómina procesada correctamente");
      router.push("/nomina");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Error al procesar la nómina");
    }
  };

  // ─── Columnas conceptos ───────────────────────────────────────

  const colsConceptos: ColumnDef[] = [
    {
      field: "tipo",
      header: "Tipo",
      width: 120,
      statusColors: { ASIGNACION: "success", DEDUCCION: "error" },
      statusVariant: "outlined",
    },
    { field: "codigo", header: "Codigo", width: 110 },
    { field: "descripcion", header: "Descripcion", flex: 1 },
    {
      field: "formula",
      header: "Formula",
      width: 160,
      renderCell: (value: unknown) => value ? String(value) : "—",
    },
    {
      field: "valor",
      header: "Valor",
      width: 140,
      type: "number",
      currency: true,
    },
  ];

  const resumen = calcResumen();

  // ─── Render paso a paso ──────────────────────────────────────

  const renderStep = () => {
    switch (activeStep) {
      // ── Paso 1: Seleccionar Empleado ──
      case 0:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Seleccione el empleado
              </Typography>

              {empQuery.isLoading ? (
                <Stack alignItems="center" py={4}>
                  <CircularProgress />
                  <Typography variant="body2" mt={1}>Cargando empleados…</Typography>
                </Stack>
              ) : (
                <>
                  <Autocomplete
                    options={empleados}
                    getOptionLabel={(e: EmpleadoRow) => `${empCedula(e)} — ${empNombre(e)} (${empCargo(e)})`}
                    value={empleadoObj ?? null}
                    onChange={(_, val) => {
                      setCedulaSeleccionada(val ? empCedula(val) : null);
                      if (val) {
                        setSueldoBase(empSueldo(val));
                        setNominaCodigo(empNomina(val) || "ADMIN");
                      }
                    }}
                    renderInput={(params) => (
                      <TextField {...params} label="Buscar empleado por cédula o nombre" fullWidth />
                    )}
                    sx={{ mb: 3 }}
                  />

                  {empleadoObj && (
                    <Paper sx={{ p: 2, bgcolor: "primary.50" }} variant="outlined">
                      <Stack direction="row" spacing={2} alignItems="center">
                        <Avatar sx={{ width: 56, height: 56, bgcolor: "primary.main" }}>
                          <PersonIcon />
                        </Avatar>
                        <Box>
                          <Typography variant="subtitle1" fontWeight={600}>
                            {empNombre(empleadoObj)}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {empCedula(empleadoObj)}
                          </Typography>
                          <Chip size="small" label={empCargo(empleadoObj)} sx={{ mt: 0.5 }} />
                        </Box>
                        <Box sx={{ ml: "auto !important", textAlign: "right" }}>
                          <Typography variant="body2" color="text.secondary">Nómina</Typography>
                          <Typography fontWeight={600}>{empNomina(empleadoObj)}</Typography>
                          <Typography variant="body2" color="success.main" fontWeight={600}>
                            {formatCurrency(empSueldo(empleadoObj))}
                          </Typography>
                        </Box>
                      </Stack>
                    </Paper>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        );

      // ── Paso 2: Período y Base ──
      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Configure el período y tipo de cálculo
              </Typography>

              {empleadoObj && (
                <Alert severity="info" sx={{ mb: 3 }}>
                  <strong>Empleado:</strong> {empNombre(empleadoObj)} |{" "}
                  <strong>Cargo:</strong> {empCargo(empleadoObj)} |{" "}
                  <strong>Sueldo Base:</strong> {formatCurrency(empSueldo(empleadoObj))}
                </Alert>
              )}

              <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">
                <FormGrid spacing={3}>
                  <FormField xs={12} md={4}>
                    <FormControl>
                      <InputLabel>Tipo de Cálculo</InputLabel>
                      <Select
                        value={tipoCalculo}
                        label="Tipo de Cálculo"
                        onChange={(e) => setTipoCalculo(e.target.value)}
                      >
                        {payrollTypes.map(pt => (
                          <MenuItem key={pt.Code} value={pt.Code}>{pt.Label}</MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  </FormField>

                  <FormField xs={12} md={4}>
                    <DatePicker
                      label="Fecha Inicio"
                      value={fechaInicio}
                      onChange={setFechaInicio}
                    />
                  </FormField>

                  <FormField xs={12} md={4}>
                    <DatePicker
                      label="Fecha Fin"
                      value={fechaFin}
                      onChange={setFechaFin}
                    />
                  </FormField>

                  <FormField xs={12} md={6}>
                    <TextField
                      label="Sueldo Base"
                      type="number"
                      value={sueldoBase}
                      onChange={(e) => setSueldoBase(Number(e.target.value))}
                      InputProps={{
                        startAdornment: <InputAdornment position="start">$</InputAdornment>,
                      }}
                    />
                  </FormField>

                  <FormField xs={12} md={6}>
                    <TextField
                      label="Días del Período"
                      type="number"
                      value={diasPeriodo}
                      onChange={(e) => setDiasPeriodo(Number(e.target.value))}
                    />
                  </FormField>
                </FormGrid>
              </LocalizationProvider>
            </CardContent>
          </Card>
        );

      // ── Paso 3: Conceptos ──
      case 2:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Ajuste los conceptos de nómina
              </Typography>

              <Alert severity="info" sx={{ mb: 2 }}>
                Los conceptos con fórmula se calculan automáticamente. Puede editar los valores manuales.
              </Alert>

              <EditableDataGrid
                rows={conceptos}
                columns={colsConceptos}
                onSave={(row) => {
                  setConceptos((prev) =>
                    prev.map((c) => (c.id === row.id ? (row as ConceptoRow) : c))
                  );
                }}
                onDelete={(id) => setConceptos((prev) => prev.filter((c) => String(c.id) !== String(id)))}
                height={380}
                addButtonText="Agregar Concepto"
                defaultNewRow={{ codigo: "", descripcion: "", tipo: "ASIGNACION", valor: 0, editable: true }}
              />

              {/* Resumen rápido */}
              <Paper sx={{ mt: 2, p: 2, bgcolor: "grey.50" }}>
                <Stack direction="row" justifyContent="space-around">
                  <Box textAlign="center">
                    <Typography variant="body2" color="text.secondary">Asignaciones</Typography>
                    <Typography variant="h6" color="success.main" fontWeight={700}>
                      {formatCurrency(resumen.asignaciones)}
                    </Typography>
                  </Box>
                  <Box textAlign="center">
                    <Typography variant="body2" color="text.secondary">Deducciones</Typography>
                    <Typography variant="h6" color="error.main" fontWeight={700}>
                      {formatCurrency(resumen.deducciones)}
                    </Typography>
                  </Box>
                  <Box textAlign="center">
                    <Typography variant="body2" color="text.secondary">Neto a Pagar</Typography>
                    <Typography variant="h6" color="primary.main" fontWeight={700}>
                      {formatCurrency(resumen.neto)}
                    </Typography>
                  </Box>
                </Stack>
              </Paper>
            </CardContent>
          </Card>
        );

      // ── Paso 4: Resumen ──
      case 3:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Resumen de la Nómina
              </Typography>

              {/* Info del empleado */}
              {empleadoObj && (
                <Paper sx={{ p: 2, mb: 3, bgcolor: "primary.50" }}>
                  <Stack direction="row" spacing={3} alignItems="center">
                    <Avatar sx={{ width: 64, height: 64, bgcolor: "primary.main" }}>
                      <PersonIcon fontSize="large" />
                    </Avatar>
                    <Box>
                      <Typography variant="h6">{empNombre(empleadoObj)}</Typography>
                      <Typography variant="body2" color="text.secondary">
                        {empCedula(empleadoObj)} | {empCargo(empleadoObj)}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        Período: {fechaInicio?.format("DD/MM/YYYY")} al {fechaFin?.format("DD/MM/YYYY")}
                      </Typography>
                    </Box>
                  </Stack>
                </Paper>
              )}

              {/* Tabla de conceptos */}
              <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow sx={{ bgcolor: "grey.100" }}>
                      <TableCell>Código</TableCell>
                      <TableCell>Concepto</TableCell>
                      <TableCell align="right">Asignaciones</TableCell>
                      <TableCell align="right">Deducciones</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {conceptos.map((c) => (
                      <TableRow key={c.id}>
                        <TableCell>{c.codigo}</TableCell>
                        <TableCell>{c.descripcion}</TableCell>
                        <TableCell align="right">
                          {c.tipo === "ASIGNACION" ? formatCurrency(c.valor) : "—"}
                        </TableCell>
                        <TableCell align="right">
                          {c.tipo === "DEDUCCION" ? formatCurrency(c.valor) : "—"}
                        </TableCell>
                      </TableRow>
                    ))}
                    <TableRow sx={{ bgcolor: "grey.50" }}>
                      <TableCell colSpan={2}><strong>TOTALES</strong></TableCell>
                      <TableCell align="right" sx={{ color: "success.main" }}>
                        <strong>{formatCurrency(resumen.asignaciones)}</strong>
                      </TableCell>
                      <TableCell align="right" sx={{ color: "error.main" }}>
                        <strong>{formatCurrency(resumen.deducciones)}</strong>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </TableContainer>

              {/* Neto destacado */}
              <Paper sx={{ p: 3, textAlign: "center", bgcolor: "success.50" }}>
                <Typography variant="h5" gutterBottom>NETO A PAGAR</Typography>
                <Typography variant="h3" color="success.main" fontWeight={700}>
                  {formatCurrency(resumen.neto)}
                </Typography>
              </Paper>

              <Divider sx={{ my: 3 }} />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button variant="outlined" color="error" onClick={() => router.push("/nomina")}>
                  Cancelar
                </Button>
                <Button
                  variant="contained"
                  color="success"
                  startIcon={<SaveIcon />}
                  onClick={handleGuardar}
                  disabled={procesarMut.isPending}
                >
                  {procesarMut.isPending ? "Guardando…" : "Guardar Nómina"}
                </Button>
              </Stack>
            </CardContent>
          </Card>
        );

      default:
        return null;
    }
  };

  // ─── Render Principal ─────────────────────────────────────────

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 3 }}>
      {/* Header */}
      <Stack direction="row" alignItems="center" spacing={2}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/nomina")}>
          Volver
        </Button>
        <Typography variant="h5" fontWeight={700}>
          <CalculateIcon sx={{ mr: 1, verticalAlign: "middle" }} />
          Procesar Nómina
        </Typography>
      </Stack>

      {/* Error */}
      {error && (
        <Alert severity="error" onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Stepper con gradiente */}
      <Paper sx={{ p: 3 }}>
        <CustomStepper
          activeStep={activeStep}
          steps={STEPS}
          onStepClick={(step) => {
            if (step < activeStep) setActiveStep(step);
          }}
        />
      </Paper>

      {/* Contenido del paso */}
      {renderStep()}

      {/* Botones de navegación */}
      {activeStep < 3 && (
        <Paper sx={{ p: 2 }}>
          <Stack direction="row" justifyContent="space-between">
            <Button
              variant="outlined"
              onClick={handleBack}
              disabled={activeStep === 0}
              startIcon={<ArrowBackIcon />}
            >
              Anterior
            </Button>
            <Button
              variant="contained"
              onClick={handleNext}
              endIcon={<ArrowForwardIcon />}
            >
              Siguiente
            </Button>
          </Stack>
        </Paper>
      )}
    </Box>
  );
}
