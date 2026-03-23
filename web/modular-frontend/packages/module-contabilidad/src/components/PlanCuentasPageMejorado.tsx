"use client";

import React, { useState, useCallback } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  Stack,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Chip,
  IconButton,
  Tooltip,
  Tabs,
  Tab,
  Card,
  CardContent,
} from "@mui/material";
import { GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import RefreshIcon from "@mui/icons-material/Refresh";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import ArticleIcon from "@mui/icons-material/Article";
import ArrowForwardIcon from "@mui/icons-material/ArrowForward";
import { useRouter } from "next/navigation";
import {
  usePlanCuentas,
  useSeedPlanCuentas,
  useLibroMayor,
  useMayorAnalitico,
  useCreateCuenta,
  useUpdateCuenta,
  useDeleteCuenta,
} from "../hooks/useContabilidad";
import EditableDataGrid from "./EditableDataGrid";
import { ContextActionHeader, DatePicker, ZenttoDataGrid } from "@zentto/shared-ui";
import dayjs from "dayjs";
import { toDateOnly } from "@zentto/shared-api";
import { useTimezone } from "@zentto/shared-auth";

// ─── Tipos ─────────────────────────────────────────────────────

interface CuentaContable {
  id: string;
  codCuenta: string;
  descripcion: string;
  tipo: string;
  nivel: number;
  isNew?: boolean;
}

// ─── Componente Mayor Analítico Dialog ─────────────────────────

function MayorAnaliticoDialog({
  open,
  onClose,
  cuenta
}: {
  open: boolean;
  onClose: () => void;
  cuenta: CuentaContable | null;
}) {
  const { timeZone } = useTimezone();
  const [fechaDesde, setFechaDesde] = useState(
    toDateOnly(new Date(new Date().getFullYear(), 0, 1), timeZone)
  );
  const [fechaHasta, setFechaHasta] = useState(
    toDateOnly(new Date(), timeZone)
  );

  const { data, isLoading } = useMayorAnalitico(
    cuenta?.codCuenta || "",
    fechaDesde,
    fechaHasta,
    open && !!cuenta?.codCuenta
  );

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        Mayor Analítico - {cuenta?.codCuenta} {cuenta?.descripcion}
      </DialogTitle>
      <DialogContent>
        <Stack direction="row" spacing={2} sx={{ mb: 2, mt: 1 }}>
          <DatePicker
            label="Desde"
            value={fechaDesde ? dayjs(fechaDesde) : null}
            onChange={(v) => setFechaDesde(v ? v.format('YYYY-MM-DD') : '')}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
          <DatePicker
            label="Hasta"
            value={fechaHasta ? dayjs(fechaHasta) : null}
            onChange={(v) => setFechaHasta(v ? v.format('YYYY-MM-DD') : '')}
            slotProps={{ textField: { size: 'small', fullWidth: true } }}
          />
        </Stack>

        <ZenttoDataGrid
          rows={(data?.rows ?? []).map((row: any, i: number) => ({ id: i, ...row }))}
          columns={[
            { field: 'fecha', headerName: 'Fecha', width: 110 },
            { field: 'concepto', headerName: 'Concepto', flex: 1 },
            {
              field: 'debe', headerName: 'Debe', width: 110, type: 'number',
              valueFormatter: (v: any) => v > 0 ? Number(v).toFixed(2) : '',
            },
            {
              field: 'haber', headerName: 'Haber', width: 110, type: 'number',
              valueFormatter: (v: any) => v > 0 ? Number(v).toFixed(2) : '',
            },
            {
              field: 'saldo', headerName: 'Saldo', width: 120, type: 'number',
              valueFormatter: (v: any) => v != null ? Number(v).toFixed(2) : '',
              cellClassName: 'font-semibold',
            },
          ]}
          loading={isLoading}
          autoHeight
          hideFooter={(data?.rows?.length ?? 0) <= 100}
          noRowsMessage="No hay movimientos para esta cuenta en el período seleccionado"
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cerrar</Button>
      </DialogActions>
    </Dialog>
  );
}

// ─── Componente Principal ──────────────────────────────────────

export default function PlanCuentasPageMejorado() {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [tabValue, setTabValue] = useState(0);
  const [cuentaMayor, setCuentaMayor] = useState<CuentaContable | null>(null);
  const [error, setError] = useState<string | null>(null);

  const { data, isLoading, refetch } = usePlanCuentas({ search });
  const seedMutation = useSeedPlanCuentas();
  const createMutation = useCreateCuenta();
  const updateMutation = useUpdateCuenta();
  const deleteMutation = useDeleteCuenta();

  // Transformar datos para el grid
  const rows: CuentaContable[] = React.useMemo(() => {
    return (data?.data || []).map((c: any) => ({
      id: c.codCuenta || c.Cod_Cuenta || String(Math.random()),
      codCuenta: c.codCuenta || c.Cod_Cuenta,
      descripcion: c.descripcion || c.Desc_Cta || c.Desc_Cuenta,
      tipo: c.tipo || c.Tipo || "",
      nivel: c.nivel || c.Nivel || 1,
    }));
  }, [data]);

  // Filtrar por tipo de cuenta según tab (usando primer dígito del código)
  const filteredRows = React.useMemo(() => {
    if (tabValue === 0) return rows;

    // Filtrar por el primer dígito del código de cuenta
    // 1 = Activos, 2 = Pasivos, 3 = Capital, 4 = Ingresos, 5/6 = Gastos/Costos
    return rows.filter((r) => {
      const primerDigito = r.codCuenta?.charAt(0);
      switch (tabValue) {
        case 1: return primerDigito === "1"; // Activos
        case 2: return primerDigito === "2"; // Pasivos
        case 3: return primerDigito === "3"; // Capital
        case 4: return primerDigito === "4"; // Ingresos
        case 5: return primerDigito === "5" || primerDigito === "6"; // Gastos/Costos
        default: return true;
      }
    });
  }, [rows, tabValue]);

  // Handlers CRUD
  const handleSave = useCallback(async (row: CuentaContable) => {
    const payload = {
      codCuenta: row.codCuenta,
      descripcion: row.descripcion,
      tipo: row.tipo,
      nivel: row.nivel,
    };
    try {
      if (row.isNew) {
        await createMutation.mutateAsync(payload);
      } else {
        await updateMutation.mutateAsync(payload);
      }
    } catch (err: any) {
      setError(err.message || "Error al guardar la cuenta");
      throw err;
    }
  }, [createMutation, updateMutation]);

  const handleDelete = useCallback(async (id: string | number) => {
    try {
      await deleteMutation.mutateAsync(String(id));
    } catch (err: any) {
      setError(err.message || "Error al eliminar la cuenta");
    }
  }, [deleteMutation]);

  const handleSeedData = async () => {
    try {
      await seedMutation.mutateAsync();
      refetch();
    } catch (err: any) {
      setError("Error al crear datos de ejemplo");
    }
  };

  const handleNuevoAsiento = (cuenta: CuentaContable) => {
    // Navegar a nuevo asiento con la cuenta preseleccionada
    router.push(`/contabilidad/asientos/new?cuenta=${cuenta.codCuenta}`);
  };

  // Columnas
  const columns: GridColDef[] = [
    {
      field: "codCuenta",
      headerName: "Código",
      width: 120,
      editable: true,
      renderCell: (params) => (
        <Box
          sx={{
            fontFamily: "monospace",
            fontWeight: 600,
            pl: (params.row.nivel - 1) * 2,
            color: params.row.nivel === 1 ? "primary.main" : "text.primary",
          }}
        >
          {params.value}
        </Box>
      ),
    },
    {
      field: "descripcion",
      headerName: "Descripción",
      flex: 1,
      minWidth: 250,
      editable: true,
      renderCell: (params) => (
        <Box
          sx={{
            fontWeight: params.row.nivel <= 2 ? 600 : 400,
            fontStyle: params.row.nivel === 3 ? "normal" : "inherit",
          }}
        >
          {params.value}
        </Box>
      ),
    },
    {
      field: "tipo",
      headerName: "Tipo",
      width: 100,
      editable: true,
      type: "singleSelect",
      valueOptions: [
        { value: "A", label: "Acreedor" },
        { value: "D", label: "Deudor" },
      ],
      renderCell: (params) => {
        // Determinar el tipo contable por el primer dígito del código
        const primerDigito = params.row.codCuenta?.charAt(0);
        const tipoContable: Record<string, { label: string; color: any }> = {
          "1": { label: "Activo", color: { bg: "success.light", color: "success.dark" } },
          "2": { label: "Pasivo", color: { bg: "error.light", color: "error.dark" } },
          "3": { label: "Capital", color: { bg: "info.light", color: "info.dark" } },
          "4": { label: "Ingreso", color: { bg: "warning.light", color: "warning.dark" } },
          "5": { label: "Costo", color: { bg: "secondary.light", color: "secondary.dark" } },
          "6": { label: "Gasto", color: { bg: "secondary.light", color: "secondary.dark" } },
        };
        const tc = tipoContable[primerDigito] || { label: params.value, color: { bg: "grey.200", color: "grey.800" } };

        return (
          <Chip
            label={tc.label}
            size="small"
            sx={{
              bgcolor: tc.color.bg,
              color: tc.color.color,
              fontWeight: 600,
              fontSize: "0.75rem",
            }}
          />
        );
      },
    },
    {
      field: "nivel",
      headerName: "Nivel",
      width: 80,
      type: "number",
      editable: true,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          variant="outlined"
          color={params.value === 1 ? "primary" : "default"}
        />
      ),
    },
  ];

  // Acciones extra para cada fila
  const extraActions = (row: CuentaContable) => [
    <Tooltip key="mayor" title="Ver mayor analítico">
      <IconButton
        size="small"
        color="info"
        onClick={(e) => {
          e.stopPropagation();
          setCuentaMayor(row);
        }}
      >
        <AccountBalanceIcon fontSize="small" />
      </IconButton>
    </Tooltip>,
    <Tooltip key="asiento" title="Crear asiento">
      <IconButton
        size="small"
        color="success"
        onClick={(e) => {
          e.stopPropagation();
          handleNuevoAsiento(row);
        }}
      >
        <ArticleIcon fontSize="small" />
      </IconButton>
    </Tooltip>,
  ];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* Context Action Header (Odoo Style) */}
      <ContextActionHeader
        title="Plan de Cuentas"
        primaryAction={{
          label: "Nueva cuenta",
          onClick: () => {
            // Este evento idealmente llamaría al dispatch addRow del EditableDataGrid
            // Por simplicidad en este demo lo dejamos como placeholder
            console.log("Nueva cuenta activada");
          }
        }}
        secondaryActions={[
          {
            label: seedMutation.isPending ? "Creando..." : "Crear datos ejemplo",
            onClick: handleSeedData,
            disabled: seedMutation.isPending
          },
          {
            label: "Nuevo asiento",
            onClick: () => router.push("/contabilidad/asientos/new")
          }
        ]}
        onSearch={setSearch}
        searchPlaceholder="Buscar por código o descripción..."
      />

      {/* Error */}
      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Tabs de filtro */}
      <Paper sx={{ mb: 2 }}>
        <Tabs
          value={tabValue}
          onChange={(_, v) => setTabValue(v)}
          variant="scrollable"
          scrollButtons="auto"
        >
          <Tab label="Todas" />
          <Tab label="Activos" sx={{ color: "success.main" }} />
          <Tab label="Pasivos" sx={{ color: "error.main" }} />
          <Tab label="Capital" sx={{ color: "info.main" }} />
          <Tab label="Ingresos" sx={{ color: "warning.main" }} />
          <Tab label="Gastos" sx={{ color: "secondary.main" }} />
        </Tabs>
      </Paper>

      {/* Resumen */}
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack direction="row" spacing={3}>
            <Box>
              <Typography variant="body2" color="text.secondary">Total Cuentas</Typography>
              <Typography variant="h6" fontWeight={700}>{rows.length}</Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">Nivel 1</Typography>
              <Typography variant="h6" fontWeight={700}>
                {rows.filter((r) => r.nivel === 1).length}
              </Typography>
            </Box>
            <Box>
              <Typography variant="body2" color="text.secondary">Cuentas de Detalle</Typography>
              <Typography variant="h6" fontWeight={700}>
                {rows.filter((r) => r.nivel === 3).length}
              </Typography>
            </Box>
          </Stack>
        </CardContent>
      </Card>

      {/* Grid */}
      <EditableDataGrid
        rows={filteredRows}
        columns={columns}
        onSave={handleSave}
        onDelete={handleDelete}
        loading={isLoading}
        title={`Plan de Cuentas (${filteredRows.length} registros)`}
        addButtonText="Nueva cuenta"
        getRowId={(row) => row.codCuenta}
        extraActions={extraActions}
        defaultNewRow={{ codCuenta: "", descripcion: "", tipo: "A", nivel: 3 }}
      />

      {/* Dialog Mayor Analítico */}
      <MayorAnaliticoDialog
        open={!!cuentaMayor}
        onClose={() => setCuentaMayor(null)}
        cuenta={cuentaMayor}
      />
    </Box>
  );
}
