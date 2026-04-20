"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Alert, Box, Button, Card, CardContent, Chip, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, InputAdornment, InputLabel, MenuItem, Paper, Select, Stack, TextField, Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import LockOpenIcon from "@mui/icons-material/LockOpen";
import LockIcon from "@mui/icons-material/Lock";
import ReceiptIcon from "@mui/icons-material/Receipt";
import LocalAtmIcon from "@mui/icons-material/LocalAtm";
import { formatCurrency, useGridLayoutSync } from "@zentto/shared-api";
import { useToast } from "@zentto/shared-ui";
import type { ColumnDef } from "@zentto/datagrid-core";
import {
  useCajaChicaBoxes, useCreateCajaChicaBox, useOpenSession, useCloseSession,
  useActiveSession, useAddExpense, useExpensesList,
} from "../hooks/useCajaChica";
import { useBancosGridRegistration } from "./zenttoGridPersistence";


const CATEGORIAS = [
  { value: "TRANSPORTE", label: "Transporte" }, { value: "MATERIAL_OFICINA", label: "Material de Oficina" },
  { value: "LIMPIEZA", label: "Limpieza" }, { value: "ALIMENTACION", label: "Alimentación" },
  { value: "MANTENIMIENTO", label: "Mantenimiento" }, { value: "MENSAJERIA", label: "Mensajería" }, { value: "OTROS", label: "Otros" },
];

const COLS_BOXES: ColumnDef[] = [
  { field: "Name", header: "Nombre", flex: 1, minWidth: 140, sortable: true },
  { field: "CurrentBalance", header: "Balance", width: 130, type: "number", aggregation: "sum" },
  { field: "Status", header: "Estado", width: 100, statusColors: { ACTIVE: "success" } },
  { field: "Responsible", header: "Responsable", width: 130 },
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 80, pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
    ],
  } as ColumnDef,
];

const COLS_EXPENSES: ColumnDef[] = [
  { field: "CreatedAt", header: "Fecha", width: 140 },
  { field: "Category", header: "Categoría", width: 140 },
  { field: "Description", header: "Descripción", flex: 1, minWidth: 180 },
  { field: "Beneficiary", header: "Beneficiario", width: 140 },
  { field: "Amount", header: "Monto", width: 120, type: "number", aggregation: "sum" },
  { field: "ReceiptNumber", header: "Recibo", width: 100 },
  {
    field: "actions", header: "Acciones", type: "actions" as any, width: 100, pin: "right",
    actions: [
      { icon: "view", label: "Ver", action: "view" },
      { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
    ],
  } as ColumnDef,
];

const BOXES_GRID_ID = "module-bancos:caja-chica:boxes";
const EXPENSES_GRID_ID = "module-bancos:caja-chica:expenses";

export default function CajaChicaPage() {
  const boxesGridRef = useRef<any>(null);
  const expensesGridRef = useRef<any>(null);
  const { showToast } = useToast();
  const [selectedBoxId, setSelectedBoxId] = useState<number | null>(null);
  const [showCreateBox, setShowCreateBox] = useState(false);
  const [showOpenSession, setShowOpenSession] = useState(false);
  const [showCloseSession, setShowCloseSession] = useState(false);
  const [showAddExpense, setShowAddExpense] = useState(false);
  const [boxForm, setBoxForm] = useState({ name: "", maxAmount: "", responsible: "" });
  const [openAmount, setOpenAmount] = useState("");
  const [closeNotes, setCloseNotes] = useState("");
  const [expForm, setExpForm] = useState({ category: "OTROS", description: "", amount: "", beneficiary: "", receiptNumber: "" });

  const boxesQuery = useCajaChicaBoxes();
  const boxes: any[] = boxesQuery.data?.rows ?? [];
  const sessionQuery = useActiveSession(selectedBoxId ?? undefined);
  const activeSession = sessionQuery.data;
  const hasActiveSession = activeSession && activeSession.Status === "OPEN";
  const expensesQuery = useExpensesList(selectedBoxId ?? undefined, hasActiveSession ? activeSession.Id : undefined);
  const expenses: any[] = expensesQuery.data?.rows ?? [];

  const createBoxMut = useCreateCajaChicaBox();
  const openSessionMut = useOpenSession();
  const closeSessionMut = useCloseSession();
  const addExpenseMut = useAddExpense();
  const { ready: boxesLayoutReady } = useGridLayoutSync(BOXES_GRID_ID);
  const { ready: expensesLayoutReady } = useGridLayoutSync(EXPENSES_GRID_ID);
  const layoutReady = boxesLayoutReady && expensesLayoutReady;
  const { registered } = useBancosGridRegistration(layoutReady);

  useEffect(() => {
    const el = boxesGridRef.current; if (!el || !registered) return;
    el.columns = COLS_BOXES; el.rows = boxes; el.loading = boxesQuery.isLoading;
    el.getRowId = (r: any) => r.Id ?? Math.random();
  }, [boxes, boxesQuery.isLoading, registered]);

  useEffect(() => {
    const el = boxesGridRef.current; if (!el || !registered) return;
    const handler = (e: CustomEvent) => { if (e.detail?.row?.Id) setSelectedBoxId(Number(e.detail.row.Id)); };
    el.addEventListener("row-click", handler);
    return () => el.removeEventListener("row-click", handler);
  }, [registered]);

  useEffect(() => {
    const el = boxesGridRef.current; if (!el || !registered) return;
    const handler = (e: any) => {
      const { action, row } = e.detail;
      if (action === 'view' && row?.Id) setSelectedBoxId(Number(row.Id));
    };
    const createHandler = () => setShowCreateBox(true);
    el.addEventListener('action-click', handler);
    el.addEventListener('create-click', createHandler);
    return () => { el.removeEventListener('action-click', handler); el.removeEventListener('create-click', createHandler); };
  }, [registered]);

  useEffect(() => {
    const el = expensesGridRef.current; if (!el || !registered) return;
    el.columns = COLS_EXPENSES; el.rows = expenses; el.loading = expensesQuery.isLoading;
    el.getRowId = (r: any) => r.Id ?? Math.random();
  }, [expenses, expensesQuery.isLoading, registered]);

  const handleCreateBox = async () => { if (!boxForm.name.trim()) return; try { await createBoxMut.mutateAsync({ name: boxForm.name, maxAmount: Number(boxForm.maxAmount) || 0, responsible: boxForm.responsible || undefined }); showToast("Caja chica creada"); setShowCreateBox(false); setBoxForm({ name: "", maxAmount: "", responsible: "" }); } catch (e: any) { showToast(e?.message ?? "Error al crear caja chica"); } };
  const handleOpenSession = async () => { if (!selectedBoxId) return; try { await openSessionMut.mutateAsync({ boxId: selectedBoxId, openingAmount: Number(openAmount) || 0 }); showToast("Sesión abierta"); setShowOpenSession(false); setOpenAmount(""); } catch (e: any) { showToast(e?.message ?? "Error al abrir sesión"); } };
  const handleCloseSession = async () => { if (!selectedBoxId) return; try { await closeSessionMut.mutateAsync({ boxId: selectedBoxId, notes: closeNotes || undefined }); showToast("Sesión cerrada"); setShowCloseSession(false); setCloseNotes(""); } catch (e: any) { showToast(e?.message ?? "Error al cerrar sesión"); } };
  const handleAddExpense = async () => { if (!selectedBoxId || !hasActiveSession || !expForm.description.trim() || !expForm.amount) return; try { await addExpenseMut.mutateAsync({ boxId: selectedBoxId, sessionId: activeSession.Id, category: expForm.category, description: expForm.description, amount: Number(expForm.amount), beneficiary: expForm.beneficiary || undefined, receiptNumber: expForm.receiptNumber || undefined }); showToast("Gasto registrado"); setShowAddExpense(false); setExpForm({ category: "OTROS", description: "", amount: "", beneficiary: "", receiptNumber: "" }); } catch (e: any) { showToast(e?.message ?? "Error al registrar gasto"); } };

  const selectedBox = boxes.find((b) => b.Id === selectedBoxId);

  return (
    <Box>
      <Grid container spacing={2}>
        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight="bold" mb={1}><LocalAtmIcon sx={{ mr: 1, verticalAlign: "middle", fontSize: 20 }} />Cajas Chicas</Typography>
            <zentto-grid ref={boxesGridRef} grid-id={BOXES_GRID_ID} height="350px" show-totals enable-create create-label="Nueva Caja" enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
          </Paper>
        </Grid>

        <Grid size={{ xs: 12, lg: 8 }}>
          {selectedBoxId ? (
            <Stack spacing={2}>
              <Card>
                <CardContent>
                  <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
                    <Typography variant="h6" fontWeight={600}>{selectedBox?.Name ?? "Caja Chica"}</Typography>
                    <Stack direction="row" spacing={1}>
                      {hasActiveSession ? (
                        <>
                          <Button variant="contained" size="small" startIcon={<ReceiptIcon />} onClick={() => setShowAddExpense(true)}>Registrar Gasto</Button>
                          <Button variant="outlined" size="small" color="error" startIcon={<LockIcon />} onClick={() => setShowCloseSession(true)}>Cerrar Sesión</Button>
                        </>
                      ) : (
                        <Button variant="contained" size="small" color="success" startIcon={<LockOpenIcon />} onClick={() => setShowOpenSession(true)}>Abrir Sesión</Button>
                      )}
                    </Stack>
                  </Stack>
                  {hasActiveSession ? (
                    <Grid container spacing={2}>
                      <Grid size={{ xs: 4 }}><Box sx={{ borderLeft: "4px solid #2e7d32", pl: 2 }}><Typography variant="caption" color="text.secondary">Monto Apertura</Typography><Typography variant="h6" fontWeight={700}>{formatCurrency(Number(activeSession.OpeningAmount ?? 0))}</Typography></Box></Grid>
                      <Grid size={{ xs: 4 }}><Box sx={{ borderLeft: "4px solid #e55353", pl: 2 }}><Typography variant="caption" color="text.secondary">Total Gastos</Typography><Typography variant="h6" fontWeight={700}>{formatCurrency(Number(activeSession.TotalExpenses ?? 0))}</Typography></Box></Grid>
                      <Grid size={{ xs: 4 }}><Box sx={{ borderLeft: "4px solid #321fdb", pl: 2 }}><Typography variant="caption" color="text.secondary">Disponible</Typography><Typography variant="h6" fontWeight={700}>{formatCurrency(Number(activeSession.OpeningAmount ?? 0) - Number(activeSession.TotalExpenses ?? 0))}</Typography></Box></Grid>
                    </Grid>
                  ) : <Alert severity="info">No hay sesión activa. Abra una sesión para comenzar a registrar gastos.</Alert>}
                </CardContent>
              </Card>
              <Paper sx={{ p: 2 }}>
                <Typography variant="subtitle1" fontWeight="bold" mb={1}>Gastos de la Sesión</Typography>
                <zentto-grid ref={expensesGridRef} grid-id={EXPENSES_GRID_ID} height="300px" show-totals enable-toolbar enable-header-menu enable-header-filters enable-clipboard enable-quick-search enable-context-menu enable-status-bar enable-configurator />
              </Paper>
            </Stack>
          ) : (
            <Paper sx={{ p: 4, textAlign: "center" }}><LocalAtmIcon sx={{ fontSize: 60, color: "text.disabled", mb: 2 }} /><Typography color="text.secondary">Seleccione una caja chica para ver su sesión y gastos</Typography></Paper>
          )}
        </Grid>
      </Grid>

      {/* Dialogs */}
      <Dialog open={showCreateBox} onClose={() => setShowCreateBox(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Caja Chica</DialogTitle>
        <DialogContent><Stack spacing={2} sx={{ mt: 1 }}>
          <TextField label="Nombre" fullWidth value={boxForm.name} onChange={(e) => setBoxForm({ ...boxForm, name: e.target.value })} />
          <TextField label="Monto Máximo" type="number" fullWidth value={boxForm.maxAmount} onChange={(e) => setBoxForm({ ...boxForm, maxAmount: e.target.value })} InputProps={{ startAdornment: <InputAdornment position="start">$</InputAdornment> }} />
          <TextField label="Responsable" fullWidth value={boxForm.responsible} onChange={(e) => setBoxForm({ ...boxForm, responsible: e.target.value })} />
        </Stack></DialogContent>
        <DialogActions><Button onClick={() => setShowCreateBox(false)}>Cancelar</Button><Button variant="contained" onClick={handleCreateBox} disabled={createBoxMut.isPending}>Crear</Button></DialogActions>
      </Dialog>

      <Dialog open={showOpenSession} onClose={() => setShowOpenSession(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Abrir Sesión</DialogTitle>
        <DialogContent><TextField label="Monto de Apertura" type="number" fullWidth sx={{ mt: 1 }} value={openAmount} onChange={(e) => setOpenAmount(e.target.value)} InputProps={{ startAdornment: <InputAdornment position="start">$</InputAdornment> }} /></DialogContent>
        <DialogActions><Button onClick={() => setShowOpenSession(false)}>Cancelar</Button><Button variant="contained" color="success" onClick={handleOpenSession} disabled={openSessionMut.isPending}>Abrir</Button></DialogActions>
      </Dialog>

      <Dialog open={showCloseSession} onClose={() => setShowCloseSession(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Cerrar Sesión</DialogTitle>
        <DialogContent><Alert severity="warning" sx={{ mb: 2, mt: 1 }}>Al cerrar la sesión no podrá registrar más gastos hasta abrir una nueva.</Alert><TextField label="Observaciones (opcional)" fullWidth multiline rows={2} value={closeNotes} onChange={(e) => setCloseNotes(e.target.value)} /></DialogContent>
        <DialogActions><Button onClick={() => setShowCloseSession(false)}>Cancelar</Button><Button variant="contained" color="error" onClick={handleCloseSession} disabled={closeSessionMut.isPending}>Cerrar Sesión</Button></DialogActions>
      </Dialog>

      <Dialog open={showAddExpense} onClose={() => setShowAddExpense(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Registrar Gasto</DialogTitle>
        <DialogContent><Stack spacing={2} sx={{ mt: 1 }}>
          <FormControl fullWidth><InputLabel>Categoría</InputLabel><Select value={expForm.category} label="Categoría" onChange={(e) => setExpForm({ ...expForm, category: e.target.value })}>{CATEGORIAS.map((c) => <MenuItem key={c.value} value={c.value}>{c.label}</MenuItem>)}</Select></FormControl>
          <TextField label="Descripción" fullWidth value={expForm.description} onChange={(e) => setExpForm({ ...expForm, description: e.target.value })} />
          <TextField label="Monto" type="number" fullWidth value={expForm.amount} onChange={(e) => setExpForm({ ...expForm, amount: e.target.value })} InputProps={{ startAdornment: <InputAdornment position="start">$</InputAdornment> }} />
          <TextField label="Beneficiario (opcional)" fullWidth value={expForm.beneficiary} onChange={(e) => setExpForm({ ...expForm, beneficiary: e.target.value })} />
          <TextField label="Nro. Recibo (opcional)" fullWidth value={expForm.receiptNumber} onChange={(e) => setExpForm({ ...expForm, receiptNumber: e.target.value })} />
        </Stack></DialogContent>
        <DialogActions><Button onClick={() => setShowAddExpense(false)}>Cancelar</Button><Button variant="contained" onClick={handleAddExpense} disabled={addExpenseMut.isPending}>Registrar</Button></DialogActions>
      </Dialog>
    </Box>
  );
}

declare global { namespace JSX { interface IntrinsicElements { 'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>; } } }
