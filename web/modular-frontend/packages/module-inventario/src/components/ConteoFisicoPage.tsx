// components/ConteoFisicoPage.tsx
"use client";

import { useState } from "react";
import {
  Box, Button, Chip, Typography, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, Stack, Alert,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import type { ColumnDef } from "@zentto/datagrid-core";
import { InventarioGrid } from "./InventarioGrid";
import { useConteoList, useCrearConteo, useCerrarConteo, useUpsertLineaConteo } from "../hooks/useConteoAlbaranes";

const ESTADO_COLORS: Record<string, "default" | "info" | "warning" | "success" | "error"> = {
  BORRADOR: "default",
  EN_PROCESO: "info",
  APROBADA: "warning",
  CERRADA: "success",
  CANCELADA: "error",
};

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
  const [page, setPage]   = useState(1);
  const [limit]           = useState(50);
  const [openNew, setOpenNew] = useState(false);
  const [warehouse, setWarehouse] = useState("");
  const [notas, setNotas] = useState("");
  const [error, setError] = useState("");

  const { data, isLoading } = useConteoList({ page, limit });
  const crearMut   = useCrearConteo();
  const cerrarMut  = useCerrarConteo();

  const rows = (data?.rows ?? []).map((r) => ({
    ...r,
    id: r.HojaConteoId,
    FechaConteo: r.FechaConteo ? r.FechaConteo.slice(0, 10) : "",
  }));

  function handleAction(action: string, row: any) {
    if (action === "close" && row.Estado !== "CERRADA" && row.Estado !== "CANCELADA") {
      if (confirm(`¿Cerrar conteo ${row.Numero} y generar ajustes de stock?`)) {
        cerrarMut.mutate(row.HojaConteoId);
      }
    }
  }

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

      <InventarioGrid
        columns={COLUMNS}
        rows={rows}
        loading={isLoading}
        totalRows={data?.total ?? 0}
        page={page}
        pageSize={limit}
        onPageChange={setPage}
        onAction={handleAction}
        height={520}
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
