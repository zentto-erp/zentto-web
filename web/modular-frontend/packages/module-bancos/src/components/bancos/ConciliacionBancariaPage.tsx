"use client";

import { useMemo, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  IconButton,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import LockIcon from "@mui/icons-material/Lock";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import { useRouter } from "next/navigation";
import { formatCurrency, toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";
import { useToast } from "@zentto/shared-ui";
import {
  useCerrarConciliacion,
  useConciliacionDetalle,
  useConciliaciones,
  useConciliarMovimiento,
  useCuentasBank,
  useGenerarAjuste,
  useImportarExtracto,
  useAsientosVinculados,
} from "../../hooks/useConciliacionBancaria";
import { useAuth } from "@zentto/shared-auth";

type ConciliacionRow = Record<string, any>;

const estadoColors: Record<string, "warning" | "success" | "info" | "error" | "default"> = {
  ABIERTA: "warning",
  EN_PROCESO: "info",
  CERRADA: "success",
  ANULADA: "error",
};

export default function ConciliacionBancariaPage() {
  const router = useRouter();
  const { showToast } = useToast();
  const { timeZone } = useTimezone();
  const { hasModule } = useAuth();
  const showAsientos = hasModule("contabilidad");

  // Filtros
  const [nroCta, setNroCta] = useState("");
  const [estado, setEstado] = useState("");
  const [page, setPage] = useState(1);
  const [limit] = useState(50);

  // Detalle dialog
  const [selectedId, setSelectedId] = useState<number | null>(null);

  // Importar extracto dialog
  const [importOpen, setImportOpen] = useState(false);
  const [importText, setImportText] = useState(
    JSON.stringify(
      [{ Fecha: toDateOnly(new Date(), timeZone), Descripcion: "Deposito", Referencia: "DEP-001", Tipo: "CREDITO", Monto: 100, Saldo: 100 }],
      null, 2
    )
  );

  // Cerrar conciliación dialog
  const [cerrarOpen, setCerrarOpen] = useState(false);
  const [saldoFinalBanco, setSaldoFinalBanco] = useState("");
  const [obsCierre, setObsCierre] = useState("");

  // Queries
  const { data: cuentasData } = useCuentasBank();
  const filter = useMemo(() => ({
    Nro_Cta: nroCta || undefined,
    Estado: estado || undefined,
    page,
    limit,
  }), [nroCta, estado, page, limit]);
  const { data: listData, isLoading } = useConciliaciones(filter);
  const { data: detalleData, refetch: refetchDetalle } = useConciliacionDetalle(selectedId ?? undefined);
  const { data: asientosVinculadosData } = useAsientosVinculados(showAsientos ? (selectedId ?? undefined) : undefined);
  const asientosVinculados: any[] = asientosVinculadosData?.rows ?? [];

  // Mutations
  const importar = useImportarExtracto();
  const cerrar = useCerrarConciliacion();

  const rows = (listData?.rows ?? []) as ConciliacionRow[];
  const cuentas = (cuentasData?.rows ?? []) as Record<string, any>[];

  // Movimientos del detalle
  const movSistema = (detalleData?.movimientosSistema ?? []) as Record<string, any>[];
  const extractoPendiente = (detalleData?.extractoPendiente ?? []) as Record<string, any>[];

  // ─── Handlers ───────────────────────────────────────────

  const handleImportar = async () => {
    if (!selectedId) return;
    try {
      const parsed = JSON.parse(importText);
      const r = await importar.mutateAsync({ conciliacionId: selectedId, extracto: parsed });
      showToast(`Extracto importado. Registros: ${r?.registrosImportados ?? "ok"}`);
      setImportOpen(false);
      await refetchDetalle();
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error al importar extracto");
    }
  };

  const handleCerrar = async () => {
    if (!selectedId) return;
    try {
      const r = await cerrar.mutateAsync({
        Conciliacion_ID: selectedId,
        Saldo_Final_Banco: Number(saldoFinalBanco),
        Observaciones: obsCierre || undefined,
      });
      showToast(`Conciliación cerrada. Estado: ${r?.estado ?? "ok"}, Diferencia: ${r?.diferencia ?? 0}`);
      setCerrarOpen(false);
      setSelectedId(null);
    } catch (e: unknown) {
      showToast(e instanceof Error ? e.message : "Error al cerrar conciliación");
    }
  };

  // ─── Columnas DataGrid principal ────────────────────────

  const columns: GridColDef[] = [
    { field: "ID", headerName: "ID", width: 70 },
    { field: "Nro_Cta", headerName: "Cuenta", width: 160 },
    {
      field: "Fecha_Desde", headerName: "Desde", width: 120,
      renderCell: (p) => toDateOnly(p.value as string, timeZone),
    },
    {
      field: "Fecha_Hasta", headerName: "Hasta", width: 120,
      renderCell: (p) => toDateOnly(p.value as string, timeZone),
    },
    {
      field: "Saldo_Final_Sistema", headerName: "Saldo Sistema", width: 140,
      align: "right", headerAlign: "right",
      renderCell: (p) => formatCurrency(Number(p.value ?? 0)),
    },
    {
      field: "Diferencia", headerName: "Diferencia", width: 130,
      align: "right", headerAlign: "right",
      renderCell: (p) => {
        const val = Number(p.value ?? 0);
        return (
          <Typography variant="body2" color={val === 0 ? "success.main" : "error.main"} fontWeight={600}>
            {formatCurrency(val)}
          </Typography>
        );
      },
    },
    {
      field: "Estado", headerName: "Estado", width: 130,
      renderCell: (p) => (
        <Chip
          size="small"
          label={String(p.value ?? "—")}
          color={estadoColors[String(p.value)] ?? "default"}
        />
      ),
    },
    {
      field: "acciones", headerName: "Acciones", width: 120, sortable: false,
      renderCell: (p) => (
        <Stack direction="row" spacing={0.5}>
          <IconButton size="small" onClick={() => setSelectedId(Number(p.row.ID))}>
            <VisibilityIcon fontSize="small" />
          </IconButton>
          {p.row.Estado === "ABIERTA" && (
            <IconButton
              size="small"
              color="warning"
              onClick={() => {
                setSelectedId(Number(p.row.ID));
                setCerrarOpen(true);
              }}
            >
              <LockIcon fontSize="small" />
            </IconButton>
          )}
        </Stack>
      ),
    },
  ];

  // ─── Columnas del detalle ───────────────────────────────

  const colsMovSistema: GridColDef[] = [
    { field: "Fecha", headerName: "Fecha", width: 110, renderCell: (p) => toDateOnly(p.value as string, timeZone) },
    { field: "Tipo", headerName: "Tipo", width: 80 },
    { field: "Concepto", headerName: "Concepto", flex: 1, minWidth: 150 },
    { field: "Monto", headerName: "Monto", width: 120, align: "right", headerAlign: "right", renderCell: (p) => formatCurrency(Number(p.value ?? 0)) },
    {
      field: "Estado", headerName: "Estado", width: 100,
      renderCell: (p) => <Chip size="small" label={String(p.value ?? "Pendiente")} color={p.value === "CONCILIADO" ? "success" : "default"} />,
    },
  ];

  const colsExtracto: GridColDef[] = [
    { field: "Fecha", headerName: "Fecha", width: 110, renderCell: (p) => toDateOnly(p.value as string, timeZone) },
    { field: "Descripcion", headerName: "Descripción", flex: 1, minWidth: 150 },
    { field: "Referencia", headerName: "Ref", width: 120 },
    { field: "Tipo", headerName: "Tipo", width: 90, renderCell: (p) => <Chip size="small" label={String(p.value)} color={p.value === "CREDITO" ? "success" : "error"} /> },
    { field: "Monto", headerName: "Monto", width: 120, align: "right", headerAlign: "right", renderCell: (p) => formatCurrency(Number(p.value ?? 0)) },
  ];

  // ─── Render ─────────────────────────────────────────────

  return (
    <Box sx={{ display: "flex", flexDirection: "column", gap: 2 }}>
      {/* Header */}
      <Stack direction="row" justifyContent="space-between" alignItems="center">
        <Typography variant="h6">Conciliaciones Bancarias</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/conciliacion/wizard")}
        >
          Nueva Conciliación
        </Button>
      </Stack>

      {/* Filtros */}
      <Stack direction="row" spacing={2}>
        <FormControl size="small" sx={{ minWidth: 200 }}>
          <InputLabel>Cuenta</InputLabel>
          <Select value={nroCta} label="Cuenta" onChange={(e) => setNroCta(e.target.value)}>
            <MenuItem value="">Todas</MenuItem>
            {cuentas.map((c) => (
              <MenuItem key={String(c.Nro_Cta)} value={String(c.Nro_Cta)}>
                {String(c.Nro_Cta)} - {String(c.BancoNombre ?? c.Banco ?? "")}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
        <FormControl size="small" sx={{ minWidth: 160 }}>
          <InputLabel>Estado</InputLabel>
          <Select value={estado} label="Estado" onChange={(e) => setEstado(e.target.value)}>
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="ABIERTA">Abierta</MenuItem>
            <MenuItem value="EN_PROCESO">En Proceso</MenuItem>
            <MenuItem value="CERRADA">Cerrada</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      {/* DataGrid principal */}
      <Paper sx={{ p: 0 }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          rowCount={listData?.total ?? rows.length}
          pageSizeOptions={[25, 50, 100]}
          paginationModel={{ page: page - 1, pageSize: limit }}
          onPaginationModelChange={(m) => setPage(m.page + 1)}
          paginationMode="server"
          disableRowSelectionOnClick
          getRowId={(r) => r.ID ?? Math.random()}
          sx={{ minHeight: 400 }}
        />
      </Paper>

      {/* Dialog: Detalle de Conciliación */}
      <Dialog
        open={selectedId != null && !cerrarOpen}
        onClose={() => setSelectedId(null)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>
          Conciliación #{selectedId}
          {detalleData?.cabecera && (
            <Typography variant="body2" color="text.secondary">
              Cuenta: {detalleData.cabecera.Nro_Cta} | Período: {toDateOnly(detalleData.cabecera.Fecha_Desde, timeZone)} - {toDateOnly(detalleData.cabecera.Fecha_Hasta, timeZone)}
            </Typography>
          )}
        </DialogTitle>
        <DialogContent>
          {detalleData?.cabecera && (
            <Alert severity="info" sx={{ mb: 2 }}>
              <Stack direction="row" spacing={3}>
                <Typography variant="body2"><strong>Saldo Sistema:</strong> {formatCurrency(Number(detalleData.cabecera.Saldo_Final_Sistema ?? 0))}</Typography>
                <Typography variant="body2"><strong>Saldo Banco:</strong> {formatCurrency(Number(detalleData.cabecera.Saldo_Final_Banco ?? 0))}</Typography>
                <Typography variant="body2"><strong>Diferencia:</strong> {formatCurrency(Number(detalleData.cabecera.Diferencia ?? 0))}</Typography>
                <Chip size="small" label={String(detalleData.cabecera.Estado ?? "—")} color={estadoColors[String(detalleData.cabecera.Estado)] ?? "default"} />
              </Stack>
            </Alert>
          )}

          <Grid container spacing={2}>
            <Grid size={{ xs: 12, md: 6 }}>
              <Typography variant="subtitle2" gutterBottom>Movimientos del Sistema</Typography>
              <Box sx={{ height: 350 }}>
                <DataGrid
                  rows={movSistema}
                  columns={colsMovSistema}
                  density="compact"
                  hideFooter
                  disableRowSelectionOnClick
                  getRowId={(r) => r.id ?? r.ID ?? r.Mov_ID ?? Math.random()}
                />
              </Box>
            </Grid>
            <Grid size={{ xs: 12, md: 6 }}>
              <Typography variant="subtitle2" gutterBottom>Extracto Pendiente</Typography>
              <Box sx={{ height: 350 }}>
                <DataGrid
                  rows={extractoPendiente}
                  columns={colsExtracto}
                  density="compact"
                  hideFooter
                  disableRowSelectionOnClick
                  getRowId={(r) => r.id ?? r.ID ?? r.Extracto_ID ?? Math.random()}
                />
              </Box>
            </Grid>
          </Grid>

          {/* Asientos vinculados — solo si el usuario tiene módulo contabilidad */}
          {showAsientos && asientosVinculados.length > 0 && (
            <Box sx={{ mt: 2 }}>
              <Typography variant="subtitle2" gutterBottom>Asientos Contables Vinculados</Typography>
              <Box sx={{ height: 200 }}>
                <DataGrid
                  rows={asientosVinculados}
                  columns={[
                    { field: "EntryDate", headerName: "Fecha", width: 110, valueGetter: (v: any) => typeof v === "string" ? v.slice(0, 10) : v },
                    { field: "EntryNumber", headerName: "N Asiento", width: 120 },
                    { field: "Concept", headerName: "Concepto", flex: 1, minWidth: 150 },
                    { field: "TotalDebit", headerName: "Debe", width: 120, align: "right", headerAlign: "right", renderCell: (p) => formatCurrency(Number(p.value ?? 0)) },
                    { field: "TotalCredit", headerName: "Haber", width: 120, align: "right", headerAlign: "right", renderCell: (p) => formatCurrency(Number(p.value ?? 0)) },
                  ]}
                  density="compact"
                  hideFooter
                  disableRowSelectionOnClick
                  getRowId={(r) => r.JournalEntryId ?? Math.random()}
                />
              </Box>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button
            variant="outlined"
            startIcon={<UploadFileIcon />}
            onClick={() => setImportOpen(true)}
          >
            Importar Extracto
          </Button>
          {detalleData?.cabecera?.Estado === "ABIERTA" && (
            <Button variant="contained" color="warning" startIcon={<LockIcon />} onClick={() => setCerrarOpen(true)}>
              Cerrar Conciliación
            </Button>
          )}
          <Button onClick={() => setSelectedId(null)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Importar Extracto */}
      <Dialog open={importOpen} onClose={() => setImportOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Importar Extracto Bancario (JSON)</DialogTitle>
        <DialogContent>
          <Alert severity="info" sx={{ mb: 2 }}>
            Ingrese un array JSON con los movimientos del extracto bancario.
            Campos: Fecha, Descripcion, Referencia, Tipo (DEBITO/CREDITO), Monto, Saldo.
          </Alert>
          <TextField
            fullWidth
            multiline
            minRows={10}
            value={importText}
            onChange={(e) => setImportText(e.target.value)}
            sx={{ fontFamily: "monospace" }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setImportOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleImportar} disabled={importar.isPending}>
            {importar.isPending ? "Importando..." : "Importar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Cerrar Conciliación */}
      <Dialog open={cerrarOpen} onClose={() => setCerrarOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Cerrar Conciliación #{selectedId}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              fullWidth
              label="Saldo Final del Banco"
              type="number"
              value={saldoFinalBanco}
              onChange={(e) => setSaldoFinalBanco(e.target.value)}
            />
            <TextField
              fullWidth
              label="Observaciones"
              multiline
              rows={3}
              value={obsCierre}
              onChange={(e) => setObsCierre(e.target.value)}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCerrarOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            color="warning"
            onClick={handleCerrar}
            disabled={cerrar.isPending || !saldoFinalBanco}
          >
            {cerrar.isPending ? "Cerrando..." : "Cerrar Conciliación"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
