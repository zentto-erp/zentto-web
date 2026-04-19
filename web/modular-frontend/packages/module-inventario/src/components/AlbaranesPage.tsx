// components/AlbaranesPage.tsx
"use client";

import { useState } from "react";
import {
  Box, Button, Typography, Dialog, DialogTitle, DialogContent,
  DialogActions, TextField, Stack, Alert, MenuItem,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import type { ColumnDef } from "@zentto/datagrid-core";
import { InventarioGrid } from "./InventarioGrid";
import { useAlbaranesList, useCrearAlbaran, useEmitirAlbaran, useFirmarAlbaran } from "../hooks/useConteoAlbaranes";

const COLUMNS: ColumnDef[] = [
  { field: "Numero",          header: "N° Albarán",    width: 160, sortable: true },
  { field: "Tipo",            header: "Tipo",          width: 110,
    statusColors: { DESPACHO: "error", RECEPCION: "success", TRASLADO: "info" }, statusVariant: "filled" },
  { field: "Estado",          header: "Estado",        width: 110,
    statusColors: { BORRADOR: "default", EMITIDO: "info", FIRMADO: "success", ANULADO: "error" }, statusVariant: "outlined" },
  { field: "FechaEmision",    header: "Fecha",         width: 120 },
  { field: "WarehouseFrom",   header: "Desde",         width: 100 },
  { field: "WarehouseTo",     header: "Hasta",         width: 100 },
  { field: "DestinatarioNombre", header: "Destinatario", flex: 1, minWidth: 150 },
  { field: "TotalLineas",     header: "Líneas",        width: 80, type: "number" },
  {
    field: "actions", header: "Acciones", type: "actions", width: 140, pin: "right",
    actions: [
      { icon: "view",     label: "Ver",    action: "view" },
      { icon: "edit",     label: "Emitir", action: "emitir" },
      { icon: "approve",  label: "Firmar", action: "firmar" },
    ],
  },
];

export default function AlbaranesPage() {
  const [page, setPage] = useState(1);
  const [limit]         = useState(50);
  const [openNew, setOpenNew] = useState(false);
  const [tipo, setTipo]   = useState("DESPACHO");
  const [whFrom, setWhFrom] = useState("");
  const [whTo, setWhTo]   = useState("");
  const [destNombre, setDestNombre] = useState("");
  const [error, setError] = useState("");

  const { data, isLoading }  = useAlbaranesList({ page, limit });
  const crearMut   = useCrearAlbaran();
  const emitirMut  = useEmitirAlbaran();
  const firmarMut  = useFirmarAlbaran();

  const rows = (data?.rows ?? []).map((r) => ({
    ...r,
    id: r.AlbaranId,
    FechaEmision: r.FechaEmision ? r.FechaEmision.slice(0, 10) : "",
  }));

  function handleAction(action: string, row: any) {
    if (action === "emitir" && row.Estado === "BORRADOR") {
      emitirMut.mutate(row.AlbaranId);
    } else if (action === "firmar" && row.Estado === "EMITIDO") {
      if (confirm(`¿Firmar albarán ${row.Numero}? Esta acción generará movimientos de stock.`)) {
        firmarMut.mutate({ id: row.AlbaranId });
      }
    }
  }

  async function handleCrear() {
    setError("");
    try {
      await crearMut.mutateAsync({
        tipo: tipo as any,
        warehouseFrom: whFrom.trim() || undefined,
        warehouseTo:   whTo.trim()   || undefined,
        destinatarioNombre: destNombre.trim() || undefined,
      });
      setOpenNew(false);
      setWhFrom(""); setWhTo(""); setDestNombre(""); setTipo("DESPACHO");
    } catch (e: any) {
      setError(e?.message ?? "Error al crear");
    }
  }

  return (
    <Box sx={{ p: 2 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h5" fontWeight={600}>Albaranes</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setOpenNew(true)}>
          Nuevo albarán
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

      <Dialog open={openNew} onClose={() => setOpenNew(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo albarán</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            {error && <Alert severity="error">{error}</Alert>}
            <TextField select label="Tipo *" value={tipo} onChange={(e) => setTipo(e.target.value)} size="small" fullWidth>
              <MenuItem value="DESPACHO">Despacho</MenuItem>
              <MenuItem value="RECEPCION">Recepción</MenuItem>
              <MenuItem value="TRASLADO">Traslado</MenuItem>
            </TextField>
            <TextField label="Almacén origen" value={whFrom} onChange={(e) => setWhFrom(e.target.value)} size="small" fullWidth />
            <TextField label="Almacén destino" value={whTo} onChange={(e) => setWhTo(e.target.value)} size="small" fullWidth />
            <TextField label="Destinatario" value={destNombre} onChange={(e) => setDestNombre(e.target.value)} size="small" fullWidth />
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
