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
import GavelIcon from "@mui/icons-material/Gavel";
import CalculateIcon from "@mui/icons-material/Calculate";
import ReceiptIcon from "@mui/icons-material/Receipt";
import SaveIcon from "@mui/icons-material/Save";
import DescriptionIcon from "@mui/icons-material/Description";
import dynamic from "next/dynamic";
const DocumentViewerModal = dynamic(() => import("./DocumentViewerModal"), { ssr: false });

import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { CustomStepper, useToast } from "@zentto/shared-ui";
import type { StepDef } from "@zentto/shared-ui";

import { useCalcularLiquidacion } from "../hooks/useNomina";
import { useEmpleadosList } from "../hooks/useEmpleados";

// ─── Definición de pasos ───────────────────────────────────────

const STEPS: StepDef[] = [
  { label: "Seleccionar Empleado", icon: <PersonIcon /> },
  { label: "Datos del Retiro", icon: <GavelIcon /> },
  { label: "Cálculo", icon: <CalculateIcon /> },
  { label: "Resumen y Guardar", icon: <ReceiptIcon /> },
];

// ─── Tipos locales ─────────────────────────────────────────────

type EmpleadoRow = Record<string, any>;

interface LiquidacionDesglose {
  concepto: string;
  monto: number;
}

// ─── Componente Principal ──────────────────────────────────────

interface LiquidacionesWizardProps {
  initialCedula?: string | null;
  onClose?: () => void;
}

export default function LiquidacionesWizard({ initialCedula, onClose }: LiquidacionesWizardProps = {}) {
  const router = useRouter();
  const { showToast } = useToast();
  const { timeZone } = useTimezone();
  const hasInitialCedula = !!initialCedula;
  const [docViewerOpen, setDocViewerOpen] = React.useState(false);
  const [activeStep, setActiveStep] = useState(hasInitialCedula ? 1 : 0);
  const [error, setError] = useState<string | null>(null);

  // Paso 1: Empleado
  const [cedulaSeleccionada, setCedulaSeleccionada] = useState<string | null>(initialCedula ?? null);

  // Paso 2: Retiro
  const [fechaRetiro, setFechaRetiro] = useState<Dayjs | null>(dayjs().tz(timeZone));
  const [causaRetiro, setCausaRetiro] = useState<"RENUNCIA" | "DESPIDO" | "DESPIDO_JUSTIFICADO">("RENUNCIA");
  const [liquidacionId, setLiquidacionId] = useState("");

  // Paso 3: Cálculo
  const [desglose, setDesglose] = useState<LiquidacionDesglose[]>([]);
  const [totalLiquidacion, setTotalLiquidacion] = useState(0);
  const [calculado, setCalculado] = useState(false);

  // ─── Queries ──────────────────────────────────────────────────

  const empQuery = useEmpleadosList({ status: "ACTIVO", limit: 500 });
  const empleados: EmpleadoRow[] = useMemo(
    () => (Array.isArray(empQuery.data) ? empQuery.data : empQuery.data?.rows ?? []),
    [empQuery.data]
  );

  // ─── Mutations ────────────────────────────────────────────────

  const calcularMut = useCalcularLiquidacion();

  // ─── Empleado seleccionado ────────────────────────────────────

  const empleadoObj = useMemo(
    () => empleados.find((e) => (e.CEDULA ?? e.cedula) === cedulaSeleccionada),
    [empleados, cedulaSeleccionada]
  );

  // ─── Helpers ──────────────────────────────────────────────────

  const empCedula = (e: EmpleadoRow | null | undefined) => e?.CEDULA ?? e?.cedula ?? "";
  const empNombre = (e: EmpleadoRow | null | undefined) => e?.NOMBRE ?? e?.nombre ?? "";
  const empCargo = (e: EmpleadoRow | null | undefined) => e?.CARGO ?? e?.cargo ?? "";
  const empSueldo = (e: EmpleadoRow | null | undefined) => Number(e?.SUELDO ?? e?.sueldo ?? 0);
  const empIngreso = (e: EmpleadoRow | null | undefined) => e?.FECHA_INGRESO ?? e?.fechaIngreso ?? e?.HireDate ?? "";

  const causaLabels: Record<string, string> = {
    RENUNCIA: "Renuncia voluntaria",
    DESPIDO: "Despido injustificado",
    DESPIDO_JUSTIFICADO: "Despido justificado",
  };

  // ─── Calcular liquidación ─────────────────────────────────────

  const handleCalcular = async () => {
    if (!cedulaSeleccionada || !fechaRetiro) return;

    const id = liquidacionId || `LIQ-${cedulaSeleccionada}-${fechaRetiro.format("YYYYMMDD")}`;
    setLiquidacionId(id);

    try {
      await calcularMut.mutateAsync({
        liquidacionId: id,
        cedula: cedulaSeleccionada,
        fechaRetiro: fechaRetiro.format("YYYY-MM-DD"),
        causaRetiro,
      });

      // Calculate desglose locally based on API pattern (service.ts calcularLiquidacion)
      const sueldo = empSueldo(empleadoObj);
      const fechaIng = empIngreso(empleadoObj);
      const hireDate = fechaIng ? dayjs(fechaIng) : fechaRetiro;
      const serviceDays = Math.max(0, fechaRetiro.diff(hireDate, "day"));
      const serviceYears = serviceDays / 365;
      const salarioDiario = sueldo / 30;

      const prestaciones = Number((serviceYears * salarioDiario * 30).toFixed(2));
      const vacPendientes = Number((salarioDiario * 15).toFixed(2));
      const bonoSalida = Number((salarioDiario * 10).toFixed(2));

      const items: LiquidacionDesglose[] = [
        { concepto: "Prestaciones Sociales", monto: prestaciones },
        { concepto: "Vacaciones Pendientes", monto: vacPendientes },
        { concepto: "Bono de Salida", monto: bonoSalida },
      ];

      setDesglose(items);
      setTotalLiquidacion(items.reduce((s, i) => s + i.monto, 0));
      setCalculado(true);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Error al calcular la liquidación");
    }
  };

  // ─── Navegación ───────────────────────────────────────────────

  const handleNext = async () => {
    setError(null);

    if (activeStep === 0 && !cedulaSeleccionada) {
      setError("Debe seleccionar un empleado");
      return;
    }

    if (activeStep === 1) {
      if (!fechaRetiro) {
        setError("Debe especificar la fecha de retiro");
        return;
      }
    }

    if (activeStep === 2) {
      if (!calculado) {
        setError("Debe calcular la liquidación antes de continuar");
        return;
      }
    }

    setActiveStep((prev) => prev + 1);
  };

  const handleBack = () => {
    setError(null);
    setActiveStep((prev) => prev - 1);
  };

  const handleGuardar = async () => {
    showToast("Liquidación guardada correctamente");
    router.push("/nomina/liquidaciones");
  };

  // ─── Render paso a paso ──────────────────────────────────────

  const renderStep = () => {
    switch (activeStep) {
      // ── Paso 1: Seleccionar Empleado ──
      case 0:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Seleccione el empleado a liquidar
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
                          <Typography variant="body2" color="text.secondary">Sueldo</Typography>
                          <Typography variant="body2" color="success.main" fontWeight={600}>
                            {formatCurrency(empSueldo(empleadoObj))}
                          </Typography>
                          {empIngreso(empleadoObj) && (
                            <>
                              <Typography variant="body2" color="text.secondary">Ingreso</Typography>
                              <Typography variant="body2" fontWeight={500}>
                                {empIngreso(empleadoObj)}
                              </Typography>
                            </>
                          )}
                        </Box>
                      </Stack>
                    </Paper>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        );

      // ── Paso 2: Datos del Retiro ──
      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Información del retiro
              </Typography>

              {empleadoObj && (
                <Alert severity="info" sx={{ mb: 3 }}>
                  <strong>Empleado:</strong> {empNombre(empleadoObj)} |{" "}
                  <strong>Cargo:</strong> {empCargo(empleadoObj)} |{" "}
                  <strong>Sueldo:</strong> {formatCurrency(empSueldo(empleadoObj))}
                </Alert>
              )}

              <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">
                <Stack spacing={3}>
                  <TextField
                    label="ID Liquidación"
                    value={liquidacionId}
                    onChange={(e) => setLiquidacionId(e.target.value)}
                    fullWidth
                    helperText="Se auto-genera si se deja vacío"
                  />

                  <DatePicker
                    label="Fecha de Retiro"
                    value={fechaRetiro}
                    onChange={setFechaRetiro}
                    slotProps={{ textField: { fullWidth: true } }}
                  />

                  <FormControl fullWidth>
                    <InputLabel>Causa de Retiro</InputLabel>
                    <Select
                      value={causaRetiro}
                      label="Causa de Retiro"
                      onChange={(e) => setCausaRetiro(e.target.value as typeof causaRetiro)}
                    >
                      <MenuItem value="RENUNCIA">Renuncia voluntaria</MenuItem>
                      <MenuItem value="DESPIDO">Despido injustificado</MenuItem>
                      <MenuItem value="DESPIDO_JUSTIFICADO">Despido justificado</MenuItem>
                    </Select>
                  </FormControl>
                </Stack>
              </LocalizationProvider>
            </CardContent>
          </Card>
        );

      // ── Paso 3: Cálculo ──
      case 2:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Cálculo de Liquidación
              </Typography>

              {empleadoObj && (
                <Alert severity="info" sx={{ mb: 2 }}>
                  <strong>Empleado:</strong> {empNombre(empleadoObj)} |{" "}
                  <strong>Fecha Retiro:</strong> {fechaRetiro?.format("DD/MM/YYYY")} |{" "}
                  <strong>Causa:</strong> {causaLabels[causaRetiro]}
                </Alert>
              )}

              {!calculado && (
                <Box textAlign="center" py={4}>
                  <Button
                    variant="contained"
                    size="large"
                    startIcon={calcularMut.isPending ? <CircularProgress size={20} color="inherit" /> : <CalculateIcon />}
                    onClick={handleCalcular}
                    disabled={calcularMut.isPending}
                  >
                    {calcularMut.isPending ? "Calculando…" : "Calcular Liquidación"}
                  </Button>
                </Box>
              )}

              {calculado && (
                <>
                  <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
                    <Table size="small">
                      <TableHead>
                        <TableRow sx={{ bgcolor: "grey.100" }}>
                          <TableCell>Concepto</TableCell>
                          <TableCell align="right">Monto</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {desglose.map((item, i) => (
                          <TableRow key={i}>
                            <TableCell>{item.concepto}</TableCell>
                            <TableCell align="right">{formatCurrency(item.monto)}</TableCell>
                          </TableRow>
                        ))}
                        <TableRow sx={{ bgcolor: "grey.50" }}>
                          <TableCell><strong>TOTAL LIQUIDACIÓN</strong></TableCell>
                          <TableCell align="right">
                            <strong>{formatCurrency(totalLiquidacion)}</strong>
                          </TableCell>
                        </TableRow>
                      </TableBody>
                    </Table>
                  </TableContainer>

                  <Paper sx={{ p: 3, textAlign: "center", bgcolor: "success.50" }}>
                    <Typography variant="h6" gutterBottom>TOTAL A PAGAR</Typography>
                    <Typography variant="h3" color="success.main" fontWeight={700}>
                      {formatCurrency(totalLiquidacion)}
                    </Typography>
                  </Paper>
                </>
              )}
            </CardContent>
          </Card>
        );

      // ── Paso 4: Resumen ──
      case 3:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Resumen de la Liquidación
              </Typography>

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
                        Fecha de retiro: {fechaRetiro?.format("DD/MM/YYYY")}
                      </Typography>
                      <Chip size="small" label={causaLabels[causaRetiro]} color="warning" sx={{ mt: 0.5 }} />
                    </Box>
                  </Stack>
                </Paper>
              )}

              <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow sx={{ bgcolor: "grey.100" }}>
                      <TableCell>Concepto</TableCell>
                      <TableCell align="right">Monto</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {desglose.map((item, i) => (
                      <TableRow key={i}>
                        <TableCell>{item.concepto}</TableCell>
                        <TableCell align="right">{formatCurrency(item.monto)}</TableCell>
                      </TableRow>
                    ))}
                    <TableRow sx={{ bgcolor: "grey.50" }}>
                      <TableCell><strong>TOTAL</strong></TableCell>
                      <TableCell align="right" sx={{ color: "success.main" }}>
                        <strong>{formatCurrency(totalLiquidacion)}</strong>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </TableContainer>

              <Paper sx={{ p: 3, textAlign: "center", bgcolor: "success.50", mb: 3 }}>
                <Typography variant="h5" gutterBottom>NETO A PAGAR</Typography>
                <Typography variant="h3" color="success.main" fontWeight={700}>
                  {formatCurrency(totalLiquidacion)}
                </Typography>
              </Paper>

              <Divider sx={{ my: 3 }} />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button variant="outlined" color="error" onClick={() => router.push("/nomina/liquidaciones")}>
                  Cancelar
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<DescriptionIcon />}
                  onClick={() => setDocViewerOpen(true)}
                >
                  Generar Liquidación
                </Button>
                <Button
                  variant="contained"
                  color="success"
                  startIcon={<SaveIcon />}
                  onClick={handleGuardar}
                >
                  Confirmar Liquidación
                </Button>
              </Stack>

              {/* Document Viewer para liquidación — render local con datos del wizard */}
              <DocumentViewerModal
                open={docViewerOpen}
                onClose={() => setDocViewerOpen(false)}
                documentType="liquidacion"
                employeeName={empleadoObj ? empNombre(empleadoObj) : undefined}
                directVars={{
                  'empleado.nombre': empNombre(empleadoObj),
                  'empleado.cedula': empCedula(empleadoObj),
                  'empleado.cargo': empCargo(empleadoObj),
                  'empleado.departamento': '',
                  'empleado.fechaIngreso': empIngreso(empleadoObj) ?? '',
                  'empleado.antiguedad': '',
                  'periodo.desde': empIngreso(empleadoObj) ?? '',
                  'periodo.hasta': fechaRetiro?.format('DD/MM/YYYY') ?? '',
                  'periodo.tipo': 'LIQUIDACION',
                  'nomina.tipo': 'LIQUIDACION',
                  'nomina.totalAsignaciones': totalLiquidacion.toFixed(2),
                  'nomina.totalDeducciones': '0.00',
                  'nomina.neto': totalLiquidacion.toFixed(2),
                  'nomina.netoLetras': `${totalLiquidacion.toFixed(2)} bolívares`,
                  'liquidacion.causa': causaLabels[causaRetiro] ?? causaRetiro,
                  'fecha.generacion': new Date().toLocaleDateString('es-VE'),
                  'anio': new Date().getFullYear().toString(),
                  'mes': new Date().toLocaleDateString('es-VE', { month: 'long' }),
                  'empresa.nombre': '',
                  'empresa.rif': '',
                  'empresa.direccion': '',
                  'empresa.representante': '',
                }}
                directLines={desglose.map((item, i) => ({
                  ConceptCode: `LIQ_${i}`,
                  ConceptName: item.concepto,
                  ConceptType: 'ASIGNACION',
                  Total: item.monto,
                  Quantity: 1,
                }))}
              />
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
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/nomina/liquidaciones")}>
          Volver
        </Button>
        <Typography variant="h5" fontWeight={700}>
          <GavelIcon sx={{ mr: 1, verticalAlign: "middle" }} />
          Calcular Liquidación
        </Typography>
      </Stack>

      {/* Error */}
      {error && (
        <Alert severity="error" onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Stepper */}
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
