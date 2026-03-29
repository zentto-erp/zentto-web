"use client";

import React, { useState, useMemo } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  Stepper,
  Step,
  StepLabel,
  Card,
  CardContent,
  Chip,
  Divider,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Skeleton,
} from "@mui/material";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import ErrorIcon from "@mui/icons-material/Error";
import WarningAmberIcon from "@mui/icons-material/WarningAmber";
import LockIcon from "@mui/icons-material/Lock";
import LockOpenIcon from "@mui/icons-material/LockOpen";
import CalendarMonthIcon from "@mui/icons-material/CalendarMonth";
import { formatCurrency } from "@zentto/shared-api";
import {
  usePeriodosList,
  useEnsureYear,
  usePeriodoChecklist,
  useGenerateClosingEntries,
  useClosePeriod,
  type Periodo,
  type PeriodoChecklistItem,
} from "../hooks/useContabilidadAdvanced";

// ─── Steps ───────────────────────────────────────────────────

const STEPS = [
  "Seleccionar periodo",
  "Checklist de cierre",
  "Generar asientos de cierre",
  "Cerrar periodo",
];

// ─── Step 1: Select Period ───────────────────────────────────

function StepSeleccionarPeriodo({
  selectedPeriodo,
  onSelect,
}: {
  selectedPeriodo: string | null;
  onSelect: (periodo: string) => void;
}) {
  const currentYear = new Date().getFullYear();
  const [year, setYear] = useState(currentYear);
  const { data, isLoading, refetch } = usePeriodosList(year, "OPEN");
  const ensureYearMutation = useEnsureYear();

  const periodos: Periodo[] = data?.data ?? data?.rows ?? [];

  const handleEnsureYear = async () => {
    try {
      await ensureYearMutation.mutateAsync(year);
      refetch();
    } catch {
      // Error handled by mutation state
    }
  };

  const monthNames = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre",
  ];

  return (
    <Box>
      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <Typography variant="h6" fontWeight={600}>
          Periodos abiertos - {year}
        </Typography>
        <Stack direction="row" spacing={1}>
          <Button size="small" variant="outlined" onClick={() => setYear(year - 1)}>
            {year - 1}
          </Button>
          <Button size="small" variant="outlined" onClick={() => setYear(year + 1)}>
            {year + 1}
          </Button>
        </Stack>
        <Box sx={{ flex: 1 }} />
        <Button
          variant="outlined"
          color="primary"
          startIcon={<CalendarMonthIcon />}
          onClick={handleEnsureYear}
          disabled={ensureYearMutation.isPending}
        >
          {ensureYearMutation.isPending ? "Creando..." : `Asegurar año ${year}`}
        </Button>
      </Stack>

      {ensureYearMutation.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Error al crear periodos: {String(ensureYearMutation.error)}
        </Alert>
      )}

      {ensureYearMutation.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Periodos del ano {year} creados correctamente
        </Alert>
      )}

      {isLoading ? (
        <Box sx={{ display: "flex", gap: 2, flexWrap: "wrap" }}>
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} variant="rectangular" width={180} height={100} sx={{ borderRadius: 2 }} />
          ))}
        </Box>
      ) : periodos.length === 0 ? (
        <Alert severity="info">
          No hay periodos abiertos para el ano {year}. Use el boton &quot;Asegurar año&quot; para crear los periodos.
        </Alert>
      ) : (
        <Box sx={{ display: "flex", gap: 2, flexWrap: "wrap" }}>
          {periodos.map((p) => {
            const isSelected = selectedPeriodo === p.periodo;
            const monthIndex = p.month ? p.month - 1 : 0;

            return (
              <Card
                key={p.periodo}
                sx={{
                  width: 180,
                  cursor: "pointer",
                  border: isSelected ? "2px solid" : "1px solid",
                  borderColor: isSelected ? "primary.main" : "divider",
                  borderRadius: 2,
                  bgcolor: isSelected ? "primary.light" : "background.paper",
                  transition: "all 0.2s",
                  "&:hover": { borderColor: "primary.main", transform: "translateY(-2px)" },
                }}
                onClick={() => onSelect(p.periodo)}
              >
                <CardContent sx={{ textAlign: "center", py: 2 }}>
                  <LockOpenIcon sx={{ fontSize: 28, color: "success.main", mb: 1 }} />
                  <Typography variant="h6" fontWeight={700}>
                    {monthNames[monthIndex] || p.periodo}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {p.periodo}
                  </Typography>
                  <Chip
                    label={p.status}
                    size="small"
                    color={p.status === "OPEN" ? "success" : "default"}
                    sx={{ mt: 1 }}
                  />
                </CardContent>
              </Card>
            );
          })}
        </Box>
      )}
    </Box>
  );
}

// ─── Step 2: Checklist ───────────────────────────────────────

function StepChecklist({ periodo }: { periodo: string }) {
  const { data, isLoading, error } = usePeriodoChecklist(periodo);

  const items: PeriodoChecklistItem[] = data?.data ?? data?.rows ?? [];

  const statusIcon = (status: string) => {
    switch (status) {
      case "OK":
        return <CheckCircleIcon sx={{ color: "success.main" }} />;
      case "WARN":
        return <WarningAmberIcon sx={{ color: "warning.main" }} />;
      case "FAIL":
        return <ErrorIcon sx={{ color: "error.main" }} />;
      default:
        return <WarningAmberIcon sx={{ color: "grey.500" }} />;
    }
  };

  const allOk = items.length > 0 && items.every((i) => i.status === "OK");
  const hasFailures = items.some((i) => i.status === "FAIL");

  return (
    <Box>
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
        Checklist de Cierre - {periodo}
      </Typography>

      {isLoading ? (
        <Stack spacing={1}>
          {Array.from({ length: 5 }).map((_, i) => (
            <Skeleton key={i} height={56} />
          ))}
        </Stack>
      ) : error ? (
        <Alert severity="error">Error al cargar checklist: {String(error)}</Alert>
      ) : items.length === 0 ? (
        <Alert severity="info">
          No se encontraron items de checklist para este periodo. Puede continuar con precaucion.
        </Alert>
      ) : (
        <>
          {allOk && (
            <Alert severity="success" sx={{ mb: 2 }}>
              Todos los items del checklist estan OK. Puede continuar con el cierre.
            </Alert>
          )}
          {hasFailures && (
            <Alert severity="error" sx={{ mb: 2 }}>
              Hay items criticos pendientes. Resuelvalos antes de continuar.
            </Alert>
          )}

          <Stack spacing={1}>
            {items.map((item, i) => (
              <Paper
                key={i}
                variant="outlined"
                sx={{
                  p: 2,
                  display: "flex",
                  alignItems: "center",
                  gap: 2,
                  borderColor:
                    item.status === "OK"
                      ? "success.light"
                      : item.status === "FAIL"
                        ? "error.light"
                        : "warning.light",
                }}
              >
                {statusIcon(item.status)}
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body1" fontWeight={600}>
                    {item.item}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {item.description}
                  </Typography>
                </Box>
                {item.count != null && (
                  <Chip
                    label={item.count}
                    size="small"
                    color={
                      item.status === "OK"
                        ? "success"
                        : item.status === "FAIL"
                          ? "error"
                          : "warning"
                    }
                  />
                )}
              </Paper>
            ))}
          </Stack>
        </>
      )}
    </Box>
  );
}

// ─── Step 3: Generate Closing Entries ────────────────────────

function StepGenerarCierre({
  periodo,
  onGenerated,
}: {
  periodo: string;
  onGenerated: () => void;
}) {
  const generateMutation = useGenerateClosingEntries();
  const [generated, setGenerated] = useState(false);

  const handleGenerate = async () => {
    try {
      await generateMutation.mutateAsync(periodo);
      setGenerated(true);
      onGenerated();
    } catch {
      // Error handled by mutation state
    }
  };

  return (
    <Box>
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
        Generar asientos de cierre - {periodo}
      </Typography>

      <Alert severity="info" sx={{ mb: 3 }}>
        Este paso generara automaticamente los asientos de cierre para el periodo seleccionado.
        Se crearan los asientos necesarios para cerrar las cuentas de Ingresos (4) y Gastos (5/6),
        trasladando el resultado al Patrimonio.
      </Alert>

      <Paper variant="outlined" sx={{ p: 3, mb: 3 }}>
        <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>
          Resumen de lo que se generara:
        </Typography>
        <Stack spacing={1}>
          <Stack direction="row" justifyContent="space-between">
            <Typography variant="body2">Cierre de cuentas de Ingresos (tipo I)</Typography>
            <Typography variant="body2" color="text.secondary">
              Debitar saldos acreedores
            </Typography>
          </Stack>
          <Stack direction="row" justifyContent="space-between">
            <Typography variant="body2">Cierre de cuentas de Gastos (tipo G)</Typography>
            <Typography variant="body2" color="text.secondary">
              Acreditar saldos deudores
            </Typography>
          </Stack>
          <Stack direction="row" justifyContent="space-between">
            <Typography variant="body2">Traslado a Resultados del Ejercicio</Typography>
            <Typography variant="body2" color="text.secondary">
              Diferencia neta a Patrimonio
            </Typography>
          </Stack>
        </Stack>
      </Paper>

      {generateMutation.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          Error al generar asientos de cierre: {String(generateMutation.error)}
        </Alert>
      )}

      {generated ? (
        <Alert severity="success" icon={<CheckCircleIcon />}>
          Asientos de cierre generados correctamente. Puede continuar al siguiente paso.
        </Alert>
      ) : (
        <Button
          variant="contained"
          color="primary"
          size="large"
          onClick={handleGenerate}
          disabled={generateMutation.isPending}
          startIcon={generateMutation.isPending ? <CircularProgress size={20} /> : undefined}
        >
          {generateMutation.isPending ? "Generando..." : "Generar asientos de cierre"}
        </Button>
      )}
    </Box>
  );
}

// ─── Step 4: Close Period ────────────────────────────────────

function StepCerrarPeriodo({ periodo }: { periodo: string }) {
  const closeMutation = useClosePeriod();
  const [closed, setClosed] = useState(false);

  const handleClose = async () => {
    try {
      await closeMutation.mutateAsync(periodo);
      setClosed(true);
    } catch {
      // Error handled by mutation state
    }
  };

  return (
    <Box>
      <Typography variant="h6" fontWeight={600} sx={{ mb: 2 }}>
        Cerrar periodo - {periodo}
      </Typography>

      {closed ? (
        <Box textAlign="center" sx={{ py: 4 }}>
          <CheckCircleIcon sx={{ fontSize: 64, color: "success.main", mb: 2 }} />
          <Typography variant="h5" fontWeight={700} color="success.main">
            Periodo cerrado exitosamente
          </Typography>
          <Typography variant="body1" color="text.secondary" sx={{ mt: 1 }}>
            El periodo {periodo} ha sido cerrado. No se podran registrar mas movimientos en este periodo.
          </Typography>
          <Chip
            icon={<LockIcon />}
            label="CLOSED"
            color="error"
            sx={{ mt: 2, fontWeight: 600 }}
          />
        </Box>
      ) : (
        <>
          <Alert severity="warning" sx={{ mb: 3 }}>
            <Typography variant="body2" fontWeight={600}>
              Esta accion es irreversible (salvo reabrir manualmente).
            </Typography>
            <Typography variant="body2">
              Al cerrar el periodo {periodo}, no se podran crear, modificar ni anular asientos
              con fecha dentro de este periodo. Asegurese de que todos los movimientos estan correctos.
            </Typography>
          </Alert>

          {closeMutation.isError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              Error al cerrar el periodo: {String(closeMutation.error)}
            </Alert>
          )}

          <Stack direction="row" spacing={2}>
            <Button
              variant="contained"
              color="error"
              size="large"
              onClick={handleClose}
              disabled={closeMutation.isPending}
              startIcon={
                closeMutation.isPending ? (
                  <CircularProgress size={20} color="inherit" />
                ) : (
                  <LockIcon />
                )
              }
            >
              {closeMutation.isPending ? "Cerrando..." : "Confirmar cierre del periodo"}
            </Button>
          </Stack>
        </>
      )}
    </Box>
  );
}

// ─── Main Wizard ─────────────────────────────────────────────

export default function CierreContableWizard() {
  const [activeStep, setActiveStep] = useState(0);
  const [selectedPeriodo, setSelectedPeriodo] = useState<string | null>(null);
  const [entriesGenerated, setEntriesGenerated] = useState(false);

  const canNext = () => {
    switch (activeStep) {
      case 0:
        return !!selectedPeriodo;
      case 1:
        return true; // Can always proceed from checklist (at user's discretion)
      case 2:
        return entriesGenerated;
      case 3:
        return false; // Last step
      default:
        return false;
    }
  };

  const handleNext = () => {
    if (activeStep < STEPS.length - 1) {
      setActiveStep(activeStep + 1);
    }
  };

  const handleBack = () => {
    if (activeStep > 0) {
      setActiveStep(activeStep - 1);
    }
  };

  const handleReset = () => {
    setActiveStep(0);
    setSelectedPeriodo(null);
    setEntriesGenerated(false);
  };

  return (
    <Box sx={{ maxWidth: 900, mx: "auto" }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 3 }}>
        Cierre contable
      </Typography>

      {/* Stepper */}
      <Paper sx={{ p: 3, mb: 3, borderRadius: 2 }}>
        <Stepper activeStep={activeStep} alternativeLabel>
          {STEPS.map((label) => (
            <Step key={label}>
              <StepLabel>{label}</StepLabel>
            </Step>
          ))}
        </Stepper>
      </Paper>

      {/* Step Content */}
      <Paper sx={{ p: 3, borderRadius: 2, mb: 3, minHeight: 300 }}>
        {activeStep === 0 && (
          <StepSeleccionarPeriodo
            selectedPeriodo={selectedPeriodo}
            onSelect={setSelectedPeriodo}
          />
        )}
        {activeStep === 1 && selectedPeriodo && (
          <StepChecklist periodo={selectedPeriodo} />
        )}
        {activeStep === 2 && selectedPeriodo && (
          <StepGenerarCierre
            periodo={selectedPeriodo}
            onGenerated={() => setEntriesGenerated(true)}
          />
        )}
        {activeStep === 3 && selectedPeriodo && (
          <StepCerrarPeriodo periodo={selectedPeriodo} />
        )}
      </Paper>

      {/* Navigation */}
      <Stack direction="row" justifyContent="space-between">
        <Button disabled={activeStep === 0} onClick={handleBack} variant="outlined">
          Anterior
        </Button>
        <Stack direction="row" spacing={1}>
          {activeStep === STEPS.length - 1 ? (
            <Button variant="outlined" onClick={handleReset}>
              Nuevo cierre
            </Button>
          ) : (
            <Button
              variant="contained"
              onClick={handleNext}
              disabled={!canNext()}
            >
              Siguiente
            </Button>
          )}
        </Stack>
      </Stack>
    </Box>
  );
}
