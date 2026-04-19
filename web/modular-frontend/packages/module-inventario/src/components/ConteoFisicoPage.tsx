// components/ConteoFisicoPage.tsx
"use client";

import { useState, useRef, useEffect } from "react";
import {
  Box, Button, Chip, Typography, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, Stack, Alert,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useConteoList, useCrearConteo, useCerrarConteo, useUpsertLineaConteo } from "../hooks/useConteoAlbaranes";

const ESTADO_COLORS: Record<string, "default" | "info" | "warning" | "success" | "error"> = {
  BORRADOR: "default",
  EN_PROCESO: "info",
  APROBADA: "warning",
  CERRADA: "success",
  CANCELADA: "error",
};

const GRID_ID = "module-inventario:conteo:list";

const COLUMNS: ColumnDef[] = [
  { field: "Numero",        header: "N° Conteo",    width: 150, sortable: true },
  { field: "WarehouseCode", header: "Almacén",      width: 120 },
  { field: "FechaConteo",   header: "Fecha",        width: 120 },
  { field: "Estado",        header: "Estado",       width: 110,
    statusColors: { BORRADOR: "default", EN_PROCESO: "info", APROBADA: "warning", CERRADA: "success", CANCELADA: "error" },
    statusVariant: "filled" },
  { field: "TotalLineas",    header: "Total",        width: 80,  type: "number" },
  { field: "LineasContadas", header: "Contadas",     width: 90,  type: "number" },
  {
    field: "actions", header: "Acciones", type: "actions", width: 120, pin: "right",
    actions: [
      { icon: "view",   label: "Ver / editar", action: "edit" },
      { icon: "delete", label: "Cerrar conteo", action: "close", color: "#16a34a" },
    ],
  },
];

export default function ConteoFisicoPage() {
  const gridRef = useRef<any>(null);
  const [openNew, setOpenNew] = useState(false);
  const [warehouse, setWarehouse] = useState("");
  const [notas, setNotas] = useState("");
  const [error, setError] = useState("");

  const { data, isLoading } = useConteoList({ page: 1, limit: 200 });
  const crearMut   = useCrearConteo();
  const cerrarMut  = useCerrarConteo();

  const rows = (data?.rows ?? []).map((r) => ({
    ...r,
    id: r.HojaConteoId,
    FechaConteo: r.FechaConteo ? r.FechaConteo.slice(0, 10) : "",
  }));

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    el.columns = COLUMNS;
    el.rows = rows;
    el.loading = isLoading;
  }, [rows, isLoading]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "close" && row.Estado !== "CERRADA" && row.Estado !== "CANCELADA") {
        if (confirm(`¿Cerrar conteo ${row.Numero} y generar ajustes de stock?`)) {
          cerrarMut.mutate(row.HojaConteoId);
        }
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [cerrarMut]);

  async function handleCrear() {
    setError("");
    if (!warehouse.trim()) { setError("Almacén requerido"); return; }
    try {
      await crearMut.mutateAsync({ warehouseCode: warehouse.trim(), notas: notas.trim() || undefined });
      setOpenNew(false);
      setWarehouse(""); setNotas("");
    } catch (e: any) {
      setError(e?.message ?? "Error al crear");
    }
  }

  return (
    <Box sx={{ p: 2 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h5" fontWeight={600}>Conteo Físico</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenNew(true)}>
          Nueva hoja de conteo
        </Button>
      </Stack>

      <zentto-grid
        ref={gridRef}
        grid-id={GRID_ID}
        height="520px"
        enable-toolbar
        enable-header-filters
        enable-status-bar
        enable-quick-search
      />

      <Dialog open={openNew} onClose={() => setOpenNew(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Nueva hoja de conteo</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {error && <Alert severity="error">{error}</Alert>}
            <TextField
              label="Código de almacén *"
              value={warehouse}
              onChange={(e) => setWarehouse(e.target.value)}
              size="small"
              fullWidth
            />
            <TextField
              label="Notas"
              value={notas}
              onChange={(e) => setNotas(e.target.value)}
              size="small"
              fullWidth
              multiline
              rows={2}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenNew(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCrear} disabled={crearMut.isPending}>
            Crear
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
