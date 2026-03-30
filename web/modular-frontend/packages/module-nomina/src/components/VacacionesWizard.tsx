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
import BeachAccessIcon from "@mui/icons-material/BeachAccess";
import CalculateIcon from "@mui/icons-material/Calculate";
import ReceiptIcon from "@mui/icons-material/Receipt";
import SaveIcon from "@mui/icons-material/Save";
import EventAvailableIcon from "@mui/icons-material/EventAvailable";

import { useRouter } from "next/navigation";
import { formatCurrency } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { CustomStepper, useToast } from "@zentto/shared-ui";
import type { StepDef } from "@zentto/shared-ui";

import { useProcesarVacaciones } from "../hooks/useNomina";
import { useEmpleadosList } from "../hooks/useEmpleados";
import { useDiasDisponibles } from "../hooks/useVacacionesSolicitudes";

// ─── Definición de pasos ───────────────────────────────────────

const STEPS: StepDef[] = [
  { label: "Seleccionar Empleado", icon: <PersonIcon /> },
  { label: "Período de Vacaciones", icon: <BeachAccessIcon /> },
  { label: "Cálculo", icon: <CalculateIcon /> },
  { label: "Resumen y Guardar", icon: <ReceiptIcon /> },
];

// ─── Tipos locales ─────────────────────────────────────────────

type EmpleadoRow = Record<string, any>;

// ─── Componente Principal ──────────────────────────────────────

interface VacacionesWizardProps {
  initialCedula?: string | null;
  onClose?: () => void;
}

export default function VacacionesWizard({ initialCedula, onClose }: VacacionesWizardProps = {}) {
  const router = useRouter();
  const { showToast } = useToast();
  const { timeZone } = useTimezone();
  const hasInitialCedula = !!initialCedula;
  const [activeStep, setActiveStep] = useState(hasInitialCedula ? 1 : 0);
  const [error, setError] = useState<string | null>(null);

  // Paso 1: Empleado
  const [cedulaSeleccionada, setCedulaSeleccionada] = useState<string | null>(initialCedula ?? null);

  // Paso 2: Período
  const [fechaInicio, setFechaInicio] = useState<Dayjs | null>(dayjs().tz(timeZone));
  const [fechaFin, setFechaFin] = useState<Dayjs | null>(dayjs().tz(timeZone).add(15, "day"));
  const [fechaReintegro, setFechaReintegro] = useState<Dayjs | null>(null);
  const [vacacionId, setVacacionId] = useState("");

  // Paso 3: Cálculo
  const [calculado, setCalculado] = useState(false);
  const [montoVacaciones, setMontoVacaciones] = useState(0);
  const [diasCalculados, setDiasCalculados] = useState(0);
  const [salarioDiario, setSalarioDiario] = useState(0);

  // ─── Queries ──────────────────────────────────────────────────

  const empQuery = useEmpleadosList({ status: "ACTIVO", limit: 500 });
  const empleados: EmpleadoRow[] = useMemo(
    () => (Array.isArray(empQuery.data) ? empQuery.data : empQuery.data?.rows ?? []),
    [empQuery.data]
  );

  const diasDisponibles = useDiasDisponibles(cedulaSeleccionada);
  const diasInfo = diasDisponibles.data;

  // ─── Mutations ────────────────────────────────────────────────

  const procesarMut = useProcesarVacaciones();

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

  // Days between two dates (workdays only, Mon-Fri)
  const calcularDias = (start: Dayjs, end: Dayjs): number => {
    let count = 0;
    let current = start;
    while (current.isBefore(end) || current.isSame(end, "day")) {
      const dow = current.day();
      if (dow !== 0 && dow !== 6) count++;
      current = current.add(1, "day");
    }
    return count;
  };

  const diasSolicitados = useMemo(() => {
    if (!fechaInicio || !fechaFin) return 0;
    return calcularDias(fechaInicio, fechaFin);
  }, [fechaInicio, fechaFin]);

  // ─── Calcular vacaciones ──────────────────────────────────────

  const handleCalcular = () => {
    if (!fechaInicio || !fechaFin || !empleadoObj) return;

    const sueldo = empSueldo(empleadoObj);
    const diario = sueldo / 30;
    const dias = diasSolicitados;
    const monto = Number((diario * dias).toFixed(2));

    setSalarioDiario(diario);
    setDiasCalculados(dias);
    setMontoVacaciones(monto);
    setCalculado(true);
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
        setError("Debe especificar el período de vacaciones");
        return;
      }
      if (fechaFin.isBefore(fechaInicio)) {
        setError("La fecha fin no puede ser anterior a la fecha de inicio");
        return;
      }
      if (diasInfo && diasSolicitados > (diasInfo.DiasDisponibles - diasInfo.DiasTomados - diasInfo.DiasPendientes)) {
        setError(`Solo dispone de ${diasInfo.DiasDisponibles - diasInfo.DiasTomados - diasInfo.DiasPendientes} días. Está solicitando ${diasSolicitados}.`);
        return;
      }
    }

    if (activeStep === 2 && !calculado) {
      setError("Debe calcular las vacaciones antes de continuar");
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

    const id = vacacionId || `VAC-${cedulaSeleccionada}-${fechaInicio.format("YYYYMMDD")}`;

    try {
      await procesarMut.mutateAsync({
        vacacionId: id,
        cedula: cedulaSeleccionada,
        fechaInicio: fechaInicio.format("YYYY-MM-DD"),
        fechaHasta: fechaFin.format("YYYY-MM-DD"),
        fechaReintegro: fechaReintegro?.format("YYYY-MM-DD"),
      });
      showToast("Vacaciones procesadas correctamente");
      router.push("/vacaciones");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Error al procesar vacaciones");
    }
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
                      setCalculado(false);
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
                        </Box>
                      </Stack>
                    </Paper>
                  )}

                  {cedulaSeleccionada && diasInfo && (
                    <Stack direction="row" spacing={2} mt={2} flexWrap="wrap">
                      <Chip
                        icon={<EventAvailableIcon />}
                        label={`Días disponibles: ${diasInfo.DiasDisponibles}`}
                        color="primary"
                        variant="outlined"
                      />
                      <Chip label={`Años de servicio: ${diasInfo.AnosServicio}`} variant="outlined" />
                      <Chip label={`Días tomados: ${diasInfo.DiasTomados}`} variant="outlined" />
                      <Chip label={`Pendientes: ${diasInfo.DiasPendientes} días`} variant="outlined" color="warning" />
                    </Stack>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        );

      // ── Paso 2: Período ──
      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Período de Vacaciones
              </Typography>

              {empleadoObj && (
                <Alert severity="info" sx={{ mb: 3 }}>
                  <strong>Empleado:</strong> {empNombre(empleadoObj)} |{" "}
                  <strong>Cargo:</strong> {empCargo(empleadoObj)} |{" "}
                  <strong>Sueldo:</strong> {formatCurrency(empSueldo(empleadoObj))}
                  {diasInfo && (
                    <> | <strong>Días disponibles:</strong> {diasInfo.DiasDisponibles - diasInfo.DiasTomados - diasInfo.DiasPendientes}</>
                  )}
                </Alert>
              )}

              <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">
                <Stack spacing={3}>
                  <TextField
                    label="ID Vacación"
                    value={vacacionId}
                    onChange={(e) => setVacacionId(e.target.value)}
                    fullWidth
                    helperText="Se auto-genera si se deja vacío"
                  />

                  <Stack direction="row" spacing={3}>
                    <DatePicker
                      label="Fecha Inicio"
                      value={fechaInicio}
                      onChange={(v) => { setFechaInicio(v); setCalculado(false); }}
                      slotProps={{ textField: { fullWidth: true } }}
                    />
                    <DatePicker
                      label="Fecha Fin"
                      value={fechaFin}
                      onChange={(v) => { setFechaFin(v); setCalculado(false); }}
                      slotProps={{ textField: { fullWidth: true } }}
                    />
                  </Stack>

                  <DatePicker
                    label="Fecha de Reintegro (opcional)"
                    value={fechaReintegro}
                    onChange={setFechaReintegro}
                    slotProps={{ textField: { fullWidth: true } }}
                  />

                  {fechaInicio && fechaFin && (
                    <Alert severity={diasInfo && diasSolicitados > (diasInfo.DiasDisponibles - diasInfo.DiasTomados - diasInfo.DiasPendientes) ? "error" : "success"}>
                      Días laborables solicitados: <strong>{diasSolicitados}</strong>
                    </Alert>
                  )}
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
                Cálculo de Vacaciones
              </Typography>

              {empleadoObj && (
                <Alert severity="info" sx={{ mb: 2 }}>
                  <strong>Empleado:</strong> {empNombre(empleadoObj)} |{" "}
                  <strong>Período:</strong> {fechaInicio?.format("DD/MM/YYYY")} al {fechaFin?.format("DD/MM/YYYY")} |{" "}
                  <strong>Días:</strong> {diasSolicitados}
                </Alert>
              )}

              {!calculado && (
                <Box textAlign="center" py={4}>
                  <Button
                    variant="contained"
                    size="large"
                    startIcon={<CalculateIcon />}
                    onClick={handleCalcular}
                  >
                    Calcular Vacaciones
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
                          <TableCell align="right">Valor</TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        <TableRow>
                          <TableCell>Salario Diario</TableCell>
                          <TableCell align="right">{formatCurrency(salarioDiario)}</TableCell>
                        </TableRow>
                        <TableRow>
                          <TableCell>Días de Vacaciones</TableCell>
                          <TableCell align="right">{diasCalculados}</TableCell>
                        </TableRow>
                        <TableRow sx={{ bgcolor: "grey.50" }}>
                          <TableCell><strong>TOTAL VACACIONES</strong></TableCell>
                          <TableCell align="right">
                            <strong>{formatCurrency(montoVacaciones)}</strong>
                          </TableCell>
                        </TableRow>
                      </TableBody>
                    </Table>
                  </TableContainer>

                  <Paper sx={{ p: 3, textAlign: "center", bgcolor: "success.50" }}>
                    <Typography variant="h6" gutterBottom>PAGO DE VACACIONES</Typography>
                    <Typography variant="h3" color="success.main" fontWeight={700}>
                      {formatCurrency(montoVacaciones)}
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
                Resumen de Vacaciones
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
                        Período: {fechaInicio?.format("DD/MM/YYYY")} al {fechaFin?.format("DD/MM/YYYY")}
                      </Typography>
                      <Chip size="small" label={`${diasCalculados} días`} color="primary" sx={{ mt: 0.5 }} />
                    </Box>
                  </Stack>
                </Paper>
              )}

              <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
                <Table size="small">
                  <TableHead>
                    <TableRow sx={{ bgcolor: "grey.100" }}>
                      <TableCell>Concepto</TableCell>
                      <TableCell align="right">Valor</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    <TableRow>
                      <TableCell>Salario Diario</TableCell>
                      <TableCell align="right">{formatCurrency(salarioDiario)}</TableCell>
                    </TableRow>
                    <TableRow>
                      <TableCell>Días de Vacaciones</TableCell>
                      <TableCell align="right">{diasCalculados}</TableCell>
                    </TableRow>
                    {fechaReintegro && (
                      <TableRow>
                        <TableCell>Fecha de Reintegro</TableCell>
                        <TableCell align="right">{fechaReintegro.format("DD/MM/YYYY")}</TableCell>
                      </TableRow>
                    )}
                    <TableRow sx={{ bgcolor: "grey.50" }}>
                      <TableCell><strong>TOTAL</strong></TableCell>
                      <TableCell align="right" sx={{ color: "success.main" }}>
                        <strong>{formatCurrency(montoVacaciones)}</strong>
                      </TableCell>
                    </TableRow>
                  </TableBody>
                </Table>
              </TableContainer>

              <Paper sx={{ p: 3, textAlign: "center", bgcolor: "success.50", mb: 3 }}>
                <Typography variant="h5" gutterBottom>PAGO DE VACACIONES</Typography>
                <Typography variant="h3" color="success.main" fontWeight={700}>
                  {formatCurrency(montoVacaciones)}
                </Typography>
              </Paper>

              <Divider sx={{ my: 3 }} />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button variant="outlined" color="error" onClick={() => router.push("/vacaciones")}>
                  Cancelar
                </Button>
                <Button
                  variant="contained"
                  color="success"
                  startIcon={procesarMut.isPending ? <CircularProgress size={20} color="inherit" /> : <SaveIcon />}
                  onClick={handleGuardar}
                  disabled={procesarMut.isPending}
                >
                  {procesarMut.isPending ? "Procesando…" : "Procesar Vacaciones"}
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
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/vacaciones")}>
          Volver
        </Button>
        <Typography variant="h5" fontWeight={700}>
          <BeachAccessIcon sx={{ mr: 1, verticalAlign: "middle" }} />
          Procesar Vacaciones
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
