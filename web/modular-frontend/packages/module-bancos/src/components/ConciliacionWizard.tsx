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
  Grid,
  Chip,
  Divider,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import { DatePicker } from "@mui/x-date-pickers/DatePicker";
import { LocalizationProvider } from "@mui/x-date-pickers/LocalizationProvider";
import { AdapterDayjs } from "@mui/x-date-pickers/AdapterDayjs";
import dayjs, { type Dayjs } from "dayjs";
import "dayjs/locale/es";

import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import CompareArrowsIcon from "@mui/icons-material/CompareArrows";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import SaveIcon from "@mui/icons-material/Save";

import { useRouter } from "next/navigation";
import { formatCurrency } from "@datqbox/shared-api";
import { CustomStepper, useToast } from "@datqbox/shared-ui";
import type { StepDef } from "@datqbox/shared-ui";
import { EditableDataGrid } from "@datqbox/module-contabilidad";

import {
  useCuentasBank,
  useCrearConciliacion,
  useImportarExtracto,
  useConciliarMovimiento,
  useCerrarConciliacion,
} from "../hooks/useConciliacionBancaria";
import { useMovimientosCuenta } from "../hooks/useBancosAuxiliares";

// ─── Definición de pasos ───────────────────────────────────────

const STEPS: StepDef[] = [
  { label: "Seleccionar Cuenta", icon: <AccountBalanceIcon /> },
  { label: "Importar Extracto", icon: <UploadFileIcon /> },
  { label: "Conciliar Movimientos", icon: <CompareArrowsIcon /> },
  { label: "Generar Ajustes", icon: <CheckCircleIcon /> },
];

// ─── Tipos locales ─────────────────────────────────────────────

interface MovimientoExtracto {
  id: string;
  fecha: string;
  descripcion: string;
  referencia: string;
  tipo: "DEBITO" | "CREDITO";
  monto: number;
  conciliado?: boolean;
}

type CuentaRow = Record<string, any>;
type MovimientoSistemaRow = Record<string, any>;

// ─── Componente Principal ──────────────────────────────────────

export default function ConciliacionWizard() {
  const router = useRouter();
  const { showToast } = useToast();
  const [activeStep, setActiveStep] = useState(0);
  const [error, setError] = useState<string | null>(null);

  // Paso 1 — cuenta y período
  const [nroCtaSeleccionada, setNroCtaSeleccionada] = useState("");
  const [fechaDesde, setFechaDesde] = useState<Dayjs | null>(dayjs().startOf("month"));
  const [fechaHasta, setFechaHasta] = useState<Dayjs | null>(dayjs());

  // Paso 2 — extracto bancario importado por el usuario
  const [movimientosExtracto, setMovimientosExtracto] = useState<MovimientoExtracto[]>([]);

  // Paso 3 — control local de conciliados
  const [conciliadosIds, setConciliadosIds] = useState<Set<string>>(new Set());

  // ID de la conciliación creada en el backend
  const [conciliacionId, setConciliacionId] = useState<number | null>(null);

  // ─── Queries ──────────────────────────────────────────────────

  const cuentasQuery = useCuentasBank();
  const cuentas: CuentaRow[] = useMemo(
    () => (Array.isArray(cuentasQuery.data) ? cuentasQuery.data : cuentasQuery.data?.rows ?? []),
    [cuentasQuery.data]
  );

  const movSistemaQuery = useMovimientosCuenta({
    nroCta: nroCtaSeleccionada || undefined,
    desde: fechaDesde?.format("YYYY-MM-DD"),
    hasta: fechaHasta?.format("YYYY-MM-DD"),
  });
  const movSistema: MovimientoSistemaRow[] = useMemo(
    () => (Array.isArray(movSistemaQuery.data) ? movSistemaQuery.data : movSistemaQuery.data?.rows ?? []),
    [movSistemaQuery.data]
  );

  // ─── Mutations ────────────────────────────────────────────────

  const crearMut = useCrearConciliacion();
  const importarMut = useImportarExtracto();
  const conciliarMut = useConciliarMovimiento();
  const cerrarMut = useCerrarConciliacion();

  // ─── Cuenta seleccionada ──────────────────────────────────────

  const cuentaObj = useMemo(
    () => cuentas.find((c) => (c.Nro_Cta ?? c.nroCta ?? c.id) === nroCtaSeleccionada),
    [cuentas, nroCtaSeleccionada]
  );

  // ─── Helpers ──────────────────────────────────────────────────

  const cuentaKey = (c: CuentaRow) => c.Nro_Cta ?? c.nroCta ?? c.id;
  const cuentaLabel = (c: CuentaRow) =>
    `${c.Banco ?? c.banco ?? ""} - ${c.Nro_Cta ?? c.nroCta ?? ""}`;

  // ─── Navegación ───────────────────────────────────────────────

  const handleNext = async () => {
    setError(null);

    if (activeStep === 0) {
      if (!nroCtaSeleccionada) {
        setError("Debe seleccionar una cuenta bancaria");
        return;
      }
      if (!fechaDesde || !fechaHasta) {
        setError("Debe especificar el período de conciliación");
        return;
      }
      // Crear la conciliación en el backend
      try {
        const res = await crearMut.mutateAsync({
          Nro_Cta: nroCtaSeleccionada,
          Fecha_Desde: fechaDesde.format("YYYY-MM-DD"),
          Fecha_Hasta: fechaHasta.format("YYYY-MM-DD"),
        });
        setConciliacionId(res?.id ?? res?.Conciliacion_ID ?? null);
        showToast("Conciliación creada correctamente");
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Error al crear la conciliación");
        return;
      }
    }

    if (activeStep === 1) {
      if (movimientosExtracto.length === 0) {
        setError("Debe importar o agregar movimientos del extracto");
        return;
      }
      // Enviar extracto al backend si hay ID
      if (conciliacionId) {
        try {
          await importarMut.mutateAsync({
            conciliacionId,
            extracto: movimientosExtracto,
          });
          showToast("Extracto importado correctamente");
        } catch {
          // No bloquear; puede no existir el endpoint
        }
      }
    }

    setActiveStep((prev) => prev + 1);
  };

  const handleBack = () => {
    setError(null);
    setActiveStep((prev) => prev - 1);
  };

  const handleConciliar = async (movId: string) => {
    setConciliadosIds((prev) => new Set(prev).add(movId));
    if (conciliacionId) {
      try {
        await conciliarMut.mutateAsync({
          Conciliacion_ID: conciliacionId,
          MovimientoSistema_ID: Number(movId),
        });
      } catch {
        // silencioso
      }
    }
  };

  const handleFinalizar = async () => {
    if (!conciliacionId) {
      showToast("Conciliación procesada (sin backend)");
      router.push("/bancos");
      return;
    }
    try {
      await cerrarMut.mutateAsync({
        Conciliacion_ID: conciliacionId,
        Saldo_Final_Banco: Number(cuentaObj?.Saldo ?? 0),
      });
      showToast("Conciliación cerrada exitosamente");
      router.push("/bancos");
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Error al cerrar la conciliación");
    }
  };

  // ─── Columnas de grids ────────────────────────────────────────

  const colsExtracto: GridColDef[] = [
    { field: "fecha", headerName: "Fecha", width: 120, editable: true },
    { field: "descripcion", headerName: "Descripción", flex: 1, editable: true },
    { field: "referencia", headerName: "Referencia", width: 130, editable: true },
    {
      field: "tipo",
      headerName: "Tipo",
      width: 110,
      editable: true,
      type: "singleSelect",
      valueOptions: ["DEBITO", "CREDITO"],
    },
    {
      field: "monto",
      headerName: "Monto",
      width: 130,
      editable: true,
      type: "number",
      renderCell: (p) => formatCurrency(p.value),
    },
  ];

  const colsSistema: GridColDef[] = [
    { field: "Fecha", headerName: "Fecha", width: 110 },
    { field: "Concepto", headerName: "Concepto", flex: 1 },
    {
      field: "Monto",
      headerName: "Monto",
      width: 120,
      renderCell: (p) => formatCurrency(p.value),
    },
    {
      field: "actions",
      type: "actions",
      headerName: "",
      width: 60,
      getActions: (params) => [
        <Tooltip key="c" title="Conciliar">
          <IconButton
            size="small"
            color="success"
            disabled={conciliadosIds.has(String(params.id))}
            onClick={() => handleConciliar(String(params.id))}
          >
            <CheckCircleIcon />
          </IconButton>
        </Tooltip>,
      ],
    },
  ];

  const movSistemaConId = useMemo(
    () =>
      movSistema.map((m, i: number) => ({
        ...m,
        id: m.id ?? m.Mov_ID ?? i,
      })),
    [movSistema]
  );

  const noConciliados = useMemo(
    () => movSistemaConId.filter((m) => !conciliadosIds.has(String(m.id))),
    [movSistemaConId, conciliadosIds]
  );

  // ─── Render paso a paso ──────────────────────────────────────

  const renderStep = () => {
    switch (activeStep) {
      // ── Paso 1: Seleccionar Cuenta ──
      case 0:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Seleccione la cuenta bancaria y el período
              </Typography>

              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <FormControl fullWidth>
                    <InputLabel>Cuenta Bancaria</InputLabel>
                    <Select
                      value={nroCtaSeleccionada}
                      label="Cuenta Bancaria"
                      onChange={(e) => setNroCtaSeleccionada(e.target.value)}
                    >
                      {cuentas.map((c) => (
                        <MenuItem key={cuentaKey(c)} value={cuentaKey(c)}>
                          <Stack direction="row" alignItems="center" spacing={1}>
                            <AccountBalanceIcon fontSize="small" />
                            <span>{cuentaLabel(c)}</span>
                            {c.Saldo != null && (
                              <Chip size="small" label={formatCurrency(c.Saldo ?? c.saldo)} color="success" />
                            )}
                          </Stack>
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>

                <Grid item xs={12} md={3}>
                  <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">
                    <DatePicker
                      label="Fecha Desde"
                      value={fechaDesde}
                      onChange={setFechaDesde}
                      slotProps={{ textField: { fullWidth: true } }}
                    />
                  </LocalizationProvider>
                </Grid>

                <Grid item xs={12} md={3}>
                  <LocalizationProvider dateAdapter={AdapterDayjs} adapterLocale="es">
                    <DatePicker
                      label="Fecha Hasta"
                      value={fechaHasta}
                      onChange={setFechaHasta}
                      slotProps={{ textField: { fullWidth: true } }}
                    />
                  </LocalizationProvider>
                </Grid>
              </Grid>

              {cuentaObj && (
                <Alert severity="info" sx={{ mt: 3 }}>
                  <Typography variant="body2">
                    <strong>Cuenta:</strong> {cuentaLabel(cuentaObj)}
                  </Typography>
                  {cuentaObj.Saldo != null && (
                    <Typography variant="body2">
                      <strong>Saldo actual:</strong> {formatCurrency(cuentaObj.Saldo ?? cuentaObj.saldo)}
                    </Typography>
                  )}
                </Alert>
              )}
            </CardContent>
          </Card>
        );

      // ── Paso 2: Importar Extracto ──
      case 1:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Importe o ingrese los movimientos del extracto bancario
              </Typography>

              <Stack direction="row" spacing={2} mb={2}>
                <Button variant="outlined" startIcon={<UploadFileIcon />}>
                  Importar CSV / Excel
                </Button>
              </Stack>

              <Box sx={{ flex: 1, minHeight: 0 }}>
                <EditableDataGrid
                  rows={movimientosExtracto}
                  columns={colsExtracto}
                  onSave={(row) => {
                    setMovimientosExtracto((prev) => {
                      const exists = prev.find((r) => r.id === row.id);
                      if (exists) return prev.map((r) => (r.id === row.id ? (row as MovimientoExtracto) : r));
                      return [...prev, row as MovimientoExtracto];
                    });
                  }}
                  onDelete={(id) =>
                    setMovimientosExtracto((prev) => prev.filter((m) => m.id !== id))
                  }
                  height={350}
                  addButtonText="Agregar Movimiento"
                  defaultNewRow={{
                    fecha: dayjs().format("YYYY-MM-DD"),
                    descripcion: "",
                    referencia: "",
                    tipo: "DEBITO",
                    monto: 0,
                  }}
                />
              </Box>

              <Alert severity="info" sx={{ mt: 2 }}>
                Total movimientos importados: {movimientosExtracto.length}
              </Alert>
            </CardContent>
          </Card>
        );

      // ── Paso 3: Conciliar Movimientos ──
      case 2:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Concilie los movimientos del sistema con el extracto
              </Typography>

              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" gutterBottom>
                    Movimientos del Extracto Bancario
                  </Typography>
                  <Box sx={{ height: 350, bgcolor: "grey.50", borderRadius: 1 }}>
                    <DataGrid
                      rows={movimientosExtracto}
                      columns={[
                        { field: "fecha", headerName: "Fecha", width: 110 },
                        { field: "descripcion", headerName: "Descripción", flex: 1 },
                        {
                          field: "monto",
                          headerName: "Monto",
                          width: 120,
                          renderCell: (p) => formatCurrency(p.value),
                        },
                      ]}
                      hideFooter
                      density="compact"
                    />
                  </Box>
                </Grid>

                <Grid item xs={12} md={6}>
                  <Typography variant="subtitle2" gutterBottom>
                    Movimientos del Sistema (sin conciliar)
                  </Typography>
                  <Box sx={{ height: 350, bgcolor: "grey.50", borderRadius: 1 }}>
                    {movSistemaQuery.isLoading ? (
                      <Stack alignItems="center" justifyContent="center" height="100%">
                        <CircularProgress size={32} />
                      </Stack>
                    ) : (
                      <DataGrid
                        rows={noConciliados}
                        columns={colsSistema}
                        hideFooter
                        density="compact"
                      />
                    )}
                  </Box>
                </Grid>
              </Grid>

              <Alert severity="success" sx={{ mt: 2 }}>
                Movimientos conciliados: {conciliadosIds.size} de {movSistemaConId.length}
              </Alert>
            </CardContent>
          </Card>
        );

      // ── Paso 4: Generar Ajustes ──
      case 3:
        return (
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Revise y genere los ajustes necesarios
              </Typography>

              <Alert severity="warning" sx={{ mb: 2 }}>
                Movimientos no conciliados que requieren ajuste: {noConciliados.length}
              </Alert>

              <Box sx={{ mb: 3 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Ajustes Propuestos
                </Typography>
                <EditableDataGrid
                  rows={noConciliados.map((m) => ({
                    id: m.id,
                    cuenta: "6.1.01",
                    descripcion: `Ajuste: ${m.Concepto ?? m.concepto ?? ""}`,
                    debe: m.Monto ?? m.monto ?? 0,
                    haber: 0,
                  }))}
                  columns={[
                    { field: "cuenta", headerName: "Cuenta Contable", width: 160, editable: true },
                    { field: "descripcion", headerName: "Descripción", flex: 1, editable: true },
                    {
                      field: "debe",
                      headerName: "Debe",
                      width: 130,
                      editable: true,
                      type: "number",
                      renderCell: (p) => formatCurrency(p.value),
                    },
                    {
                      field: "haber",
                      headerName: "Haber",
                      width: 130,
                      editable: true,
                      type: "number",
                      renderCell: (p) => formatCurrency(p.value),
                    },
                  ]}
                  onSave={(row) => console.log("Guardar ajuste:", row)}
                  onDelete={(id) => console.log("Eliminar ajuste:", id)}
                  height={280}
                  addButtonText="Agregar Ajuste"
                />
              </Box>

              <Divider sx={{ my: 2 }} />

              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button variant="outlined" color="error" onClick={() => router.push("/bancos")}>
                  Cancelar
                </Button>
                <Button
                  variant="contained"
                  color="success"
                  startIcon={<SaveIcon />}
                  onClick={handleFinalizar}
                  disabled={cerrarMut.isPending}
                >
                  {cerrarMut.isPending ? "Guardando…" : "Guardar y Cerrar Conciliación"}
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

  const isBusy = crearMut.isPending || importarMut.isPending;

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 3 }}>
      {/* Header */}
      <Stack direction="row" alignItems="center" spacing={2}>
        <Button startIcon={<ArrowBackIcon />} onClick={() => router.push("/bancos")}>
          Volver
        </Button>
        <Typography variant="h5" fontWeight={700}>
          <AccountBalanceIcon sx={{ mr: 1, verticalAlign: "middle" }} />
          Nueva Conciliación Bancaria
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
              disabled={isBusy}
            >
              {isBusy ? "Procesando…" : "Siguiente"}
            </Button>
          </Stack>
        </Paper>
      )}
    </Box>
  );
}
