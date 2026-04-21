// components/TrasladosMultiPasoPage.tsx
"use client";

import { useState, useRef, useEffect } from "react";
import {
  Box, Button, Typography, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, Stack, Alert, MenuItem,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useTrasladosMPList, useCrearTrasladoMP, useAvanzarTrasladoMP } from "../hooks/useConteoAlbaranes";

const ESTADO_ACTIONS: Record<string, string> = {
  BORRADOR:    "APROBAR",
  PENDIENTE:   "DESPACHAR",
  EN_TRANSITO: "RECIBIR",
};

const GRID_ID = "module-inventario:traslados-mp:list";

const COLUMNS: ColumnDef[] = [
  { field: "Numero",         header: "N° Traslado",  width: 160, sortable: true },
  { field: "Estado",         header: "Estado",       width: 120,
    statusColors: { BORRADOR: "default", PENDIENTE: "info", EN_TRANSITO: "warning", RECIBIDO: "success", CERRADO: "success", CANCELADO: "error" },
    statusVariant: "filled" },
  { field: "WarehouseFrom",  header: "Desde",        width: 120 },
  { field: "WarehouseTo",    header: "Hasta",        width: 120 },
  { field: "FechaSolicitud", header: "Solicitud",    width: 120 },
  { field: "FechaSalida",    header: "Salida",       width: 120 },
  { field: "FechaRecepcion", header: "Recepción",    width: 120 },
  {
    field: "actions", header: "Acciones", type: "actions", width: 140, pin: "right",
    actions: [
      { icon: "approve", label: "Avanzar estado", action: "advance" },
      { icon: "delete",  label: "Cancelar",       action: "cancel", color: "#dc2626" },
    ],
  },
];

export default function TrasladosMultiPasoPage() {
  const gridRef = useRef<any>(null);
  const [openNew, setOpenNew] = useState(false);
  const [whFrom, setWhFrom] = useState("");
  const [whTo, setWhTo]   = useState("");
  const [notas, setNotas]  = useState("");
  const [error, setError]  = useState("");

  const { data, isLoading } = useTrasladosMPList({ page: 1, limit: 200 });
  const crearMut   = useCrearTrasladoMP();
  const avanzarMut = useAvanzarTrasladoMP();

  const rows = (data?.rows ?? []).map((r) => ({
    ...r,
    id: r.TrasladoId,
    FechaSolicitud: r.FechaSolicitud?.slice(0, 10) ?? "",
    FechaSalida:    r.FechaSalida?.slice(0, 10) ?? "",
    FechaRecepcion: r.FechaRecepcion?.slice(0, 10) ?? "",
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
      if (action === "cancel") {
        if (confirm(`¿Cancelar traslado ${row.Numero}?`)) {
          avanzarMut.mutate({ id: row.TrasladoId, action: "CANCELAR" });
        }
        return;
      }
      if (action === "advance") {
        const nextAction = ESTADO_ACTIONS[row.Estado];
        if (!nextAction) return;
        const labels: Record<string, string> = { APROBAR: "aprobar", DESPACHAR: "despachar", RECIBIR: "recibir" };
        if (confirm(`¿${labels[nextAction] ?? nextAction} el traslado ${row.Numero}?`)) {
          avanzarMut.mutate({ id: row.TrasladoId, action: nextAction });
        }
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [avanzarMut]);

  async function handleCrear() {
    setError("");
    if (!whFrom.trim() || !whTo.trim()) { setError("Almacén origen y destino requeridos"); return; }
    if (whFrom.trim() === whTo.trim()) { setError("Origen y destino no pueden ser iguales"); return; }
    try {
      await crearMut.mutateAsync({ warehouseFrom: whFrom.trim(), warehouseTo: whTo.trim(), notas: notas.trim() || undefined });
      setOpenNew(false);
      setWhFrom(""); setWhTo(""); setNotas("");
    } catch (e: any) {
      setError(e?.message ?? "Error al crear");
    }
  }

  return (
    <Box sx={{ p: 2 }}>
      <Stack direction="row" justifyContent="flex-end" alignItems="center" mb={2}>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenNew(true)}>
          Nuevo traslado
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
        <DialogTitle>Nuevo traslado</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {error && <Alert severity="error">{error}</Alert>}
            <TextField label="Almacén origen *" value={whFrom} onChange={(e) => setWhFrom(e.target.value)} size="small" fullWidth />
            <TextField label="Almacén destino *" value={whTo}   onChange={(e) => setWhTo(e.target.value)}   size="small" fullWidth />
            <TextField label="Notas" value={notas} onChange={(e) => setNotas(e.target.value)} size="small" fullWidth multiline rows={2} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenNew(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCrear} disabled={crearMut.isPending}>Crear</Button>
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
