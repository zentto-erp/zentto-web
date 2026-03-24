"use client";

import React, { useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  InputAdornment,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  TextField,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import AddIcon from "@mui/icons-material/Add";
import LockOpenIcon from "@mui/icons-material/LockOpen";
import LockIcon from "@mui/icons-material/Lock";
import ReceiptIcon from "@mui/icons-material/Receipt";
import LocalAtmIcon from "@mui/icons-material/LocalAtm";
import { formatCurrency } from "@zentto/shared-api";
import { ContextActionHeader, useToast, ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import {
  useCajaChicaBoxes,
  useCreateCajaChicaBox,
  useOpenSession,
  useCloseSession,
  useActiveSession,
  useAddExpense,
  useExpensesList,
} from "../hooks/useCajaChica";

const CATEGORIAS = [
  { value: "TRANSPORTE", label: "Transporte" },
  { value: "MATERIAL_OFICINA", label: "Material de Oficina" },
  { value: "LIMPIEZA", label: "Limpieza" },
  { value: "ALIMENTACION", label: "Alimentación" },
  { value: "MANTENIMIENTO", label: "Mantenimiento" },
  { value: "MENSAJERIA", label: "Mensajería" },
  { value: "OTROS", label: "Otros" },
];

const colsBoxes: ZenttoColDef[] = [
  { field: "Name", headerName: "Nombre", flex: 1, minWidth: 140 },
  {
    field: "CurrentBalance",
    headerName: "Balance",
    width: 130,
    align: "right",
    headerAlign: "right",
    currency: true,
    aggregation: "sum",
    renderCell: (p) => formatCurrency(Number(p.value ?? 0)),
  },
  {
    field: "Status",
    headerName: "Estado",
    width: 100,
    renderCell: (p) => (
      <Chip size="small" label={p.value === "ACTIVE" ? "Activa" : "Inactiva"} color={p.value === "ACTIVE" ? "success" : "default"} />
    ),
  },
  { field: "Responsible", headerName: "Responsable", width: 130 },
];

const colsExpenses: ZenttoColDef[] = [
  {
    field: "CreatedAt",
    headerName: "Fecha",
    width: 140,
    renderCell: (p) => {
      if (!p.value) return "—";
      const d = new Date(p.value as string);
      return isNaN(d.getTime()) ? "—" : d.toLocaleDateString("es-VE");
    },
  },
  {
    field: "Category",
    headerName: "Categoría",
    width: 140,
    renderCell: (p) => {
      const cat = CATEGORIAS.find((c) => c.value === p.value);
      return <Chip size="small" label={cat?.label ?? String(p.value)} />;
    },
  },
  { field: "Description", headerName: "Descripción", flex: 1, minWidth: 180 },
  { field: "Beneficiary", headerName: "Beneficiario", width: 140 },
  {
    field: "Amount",
    headerName: "Monto",
    width: 120,
    align: "right",
    headerAlign: "right",
    currency: true,
    aggregation: "sum",
    renderCell: (p) => formatCurrency(Number(p.value ?? 0)),
  },
  { field: "ReceiptNumber", headerName: "Recibo", width: 100 },
];

export default function CajaChicaPage() {
  const { showToast } = useToast();
  const [selectedBoxId, setSelectedBoxId] = useState<number | null>(null);
  const [showCreateBox, setShowCreateBox] = useState(false);
  const [showOpenSession, setShowOpenSession] = useState(false);
  const [showCloseSession, setShowCloseSession] = useState(false);
  const [showAddExpense, setShowAddExpense] = useState(false);

  // Form state
  const [boxForm, setBoxForm] = useState({ name: "", maxAmount: "", responsible: "" });
  const [openAmount, setOpenAmount] = useState("");
  const [closeNotes, setCloseNotes] = useState("");
  const [expForm, setExpForm] = useState({
    category: "OTROS",
    description: "",
    amount: "",
    beneficiary: "",
    receiptNumber: "",
  });

  // Queries
  const boxesQuery = useCajaChicaBoxes();
  const boxes: any[] = boxesQuery.data?.rows ?? [];

  const sessionQuery = useActiveSession(selectedBoxId ?? undefined);
  const activeSession = sessionQuery.data;
  const hasActiveSession = activeSession && activeSession.Status === "OPEN";

  const expensesQuery = useExpensesList(selectedBoxId ?? undefined, hasActiveSession ? activeSession.Id : undefined);
  const expenses: any[] = expensesQuery.data?.rows ?? [];

  // Mutations
  const createBoxMut = useCreateCajaChicaBox();
  const openSessionMut = useOpenSession();
  const closeSessionMut = useCloseSession();
  const addExpenseMut = useAddExpense();

  const handleCreateBox = async () => {
    if (!boxForm.name.trim()) return;
    try {
      await createBoxMut.mutateAsync({
        name: boxForm.name,
        maxAmount: Number(boxForm.maxAmount) || 0,
        responsible: boxForm.responsible || undefined,
      });
      showToast("Caja chica creada");
      setShowCreateBox(false);
      setBoxForm({ name: "", maxAmount: "", responsible: "" });
    } catch (e: any) {
      showToast(e?.message ?? "Error al crear caja chica");
    }
  };

  const handleOpenSession = async () => {
    if (!selectedBoxId) return;
    try {
      await openSessionMut.mutateAsync({
        boxId: selectedBoxId,
        openingAmount: Number(openAmount) || 0,
      });
      showToast("Sesión abierta");
      setShowOpenSession(false);
      setOpenAmount("");
    } catch (e: any) {
      showToast(e?.message ?? "Error al abrir sesión");
    }
  };

  const handleCloseSession = async () => {
    if (!selectedBoxId) return;
    try {
      await closeSessionMut.mutateAsync({
        boxId: selectedBoxId,
        notes: closeNotes || undefined,
      });
      showToast("Sesión cerrada");
      setShowCloseSession(false);
      setCloseNotes("");
    } catch (e: any) {
      showToast(e?.message ?? "Error al cerrar sesión");
    }
  };

  const handleAddExpense = async () => {
    if (!selectedBoxId || !hasActiveSession) return;
    if (!expForm.description.trim() || !expForm.amount) return;
    try {
      await addExpenseMut.mutateAsync({
        boxId: selectedBoxId,
        sessionId: activeSession.Id,
        category: expForm.category,
        description: expForm.description,
        amount: Number(expForm.amount),
        beneficiary: expForm.beneficiary || undefined,
        receiptNumber: expForm.receiptNumber || undefined,
      });
      showToast("Gasto registrado");
      setShowAddExpense(false);
      setExpForm({ category: "OTROS", description: "", amount: "", beneficiary: "", receiptNumber: "" });
    } catch (e: any) {
      showToast(e?.message ?? "Error al registrar gasto");
    }
  };

  const selectedBox = boxes.find((b) => b.Id === selectedBoxId);

  return (
    <Box>
      <ContextActionHeader
        title="Caja Chica"
        primaryAction={{ label: "Nueva Caja", onClick: () => setShowCreateBox(true) }}
      />

      <Grid container spacing={2}>
        {/* Panel izquierdo: Cajas */}
        <Grid size={{ xs: 12, lg: 4 }}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="subtitle1" fontWeight="bold" mb={1}>
              <LocalAtmIcon sx={{ mr: 1, verticalAlign: "middle", fontSize: 20 }} />
              Cajas Chicas
            </Typography>
            <ZenttoDataGrid
            gridId="bancos-caja-chica-list"
              rows={boxes}
              columns={colsBoxes}
              loading={boxesQuery.isLoading}
              onRowClick={(params) => setSelectedBoxId(Number(params.row.Id))}
              getRowId={(r) => r.Id ?? Math.random()}
              density="compact"
              hideFooter
              disableRowSelectionOnClick
              showTotals
              enableGrouping
              enableClipboard
              sx={{ minHeight: 350 }}
              mobileVisibleFields={['Name', 'CurrentBalance']}
              smExtraFields={['Status']}
            />
          </Paper>
        </Grid>

        {/* Panel derecho: Sesión activa + Gastos */}
        <Grid size={{ xs: 12, lg: 8 }}>
          {selectedBoxId ? (
            <Stack spacing={2}>
              {/* Session Info Card */}
              <Card>
                <CardContent>
                  <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
                    <Typography variant="h6" fontWeight={600}>
                      {selectedBox?.Name ?? "Caja Chica"}
                    </Typography>
                    <Stack direction="row" spacing={1}>
                      {hasActiveSession ? (
                        <>
                          <Button
                            variant="contained"
                            size="small"
                            startIcon={<ReceiptIcon />}
                            onClick={() => setShowAddExpense(true)}
                          >
                            Registrar Gasto
                          </Button>
                          <Button
                            variant="outlined"
                            size="small"
                            color="error"
                            startIcon={<LockIcon />}
                            onClick={() => setShowCloseSession(true)}
                          >
                            Cerrar Sesión
                          </Button>
                        </>
                      ) : (
                        <Button
                          variant="contained"
                          size="small"
                          color="success"
                          startIcon={<LockOpenIcon />}
                          onClick={() => setShowOpenSession(true)}
                        >
                          Abrir Sesión
                        </Button>
                      )}
                    </Stack>
                  </Stack>

                  {hasActiveSession ? (
                    <Grid container spacing={2}>
                      <Grid size={{ xs: 4 }}>
                        <Box sx={{ borderLeft: "4px solid #2e7d32", pl: 2 }}>
                          <Typography variant="caption" color="text.secondary">Monto Apertura</Typography>
                          <Typography variant="h6" fontWeight={700}>
                            {formatCurrency(Number(activeSession.OpeningAmount ?? 0))}
                          </Typography>
                        </Box>
                      </Grid>
                      <Grid size={{ xs: 4 }}>
                        <Box sx={{ borderLeft: "4px solid #e55353", pl: 2 }}>
                          <Typography variant="caption" color="text.secondary">Total Gastos</Typography>
                          <Typography variant="h6" fontWeight={700}>
                            {formatCurrency(Number(activeSession.TotalExpenses ?? 0))}
                          </Typography>
                        </Box>
                      </Grid>
                      <Grid size={{ xs: 4 }}>
                        <Box sx={{ borderLeft: "4px solid #321fdb", pl: 2 }}>
                          <Typography variant="caption" color="text.secondary">Disponible</Typography>
                          <Typography variant="h6" fontWeight={700}>
                            {formatCurrency(
                              Number(activeSession.OpeningAmount ?? 0) - Number(activeSession.TotalExpenses ?? 0)
                            )}
                          </Typography>
                        </Box>
                      </Grid>
                    </Grid>
                  ) : (
                    <Alert severity="info">
                      No hay sesión activa. Abra una sesión para comenzar a registrar gastos.
                    </Alert>
                  )}
                </CardContent>
              </Card>

              {/* Expenses Grid */}
              <Paper sx={{ p: 2 }}>
                <Typography variant="subtitle1" fontWeight="bold" mb={1}>
                  Gastos de la Sesión
                </Typography>
                <ZenttoDataGrid
            gridId="bancos-caja-chica-gastos"
                  rows={expenses}
                  columns={colsExpenses}
                  loading={expensesQuery.isLoading}
                  getRowId={(r) => r.Id ?? Math.random()}
                  density="compact"
                  hideFooter
                  disableRowSelectionOnClick
                  showTotals
                  enableGrouping
                  enableClipboard
                  sx={{ minHeight: 300 }}
                  mobileVisibleFields={['CreatedAt', 'Amount']}
                  smExtraFields={['Category', 'Description']}
                />
              </Paper>
            </Stack>
          ) : (
            <Paper sx={{ p: 4, textAlign: "center" }}>
              <LocalAtmIcon sx={{ fontSize: 60, color: "text.disabled", mb: 2 }} />
              <Typography color="text.secondary">
                Seleccione una caja chica para ver su sesión y gastos
              </Typography>
            </Paper>
          )}
        </Grid>
      </Grid>

      {/* Dialog: Crear Caja Chica */}
      <Dialog open={showCreateBox} onClose={() => setShowCreateBox(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva Caja Chica</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Nombre" fullWidth value={boxForm.name} onChange={(e) => setBoxForm({ ...boxForm, name: e.target.value })} />
            <TextField
              label="Monto Máximo"
              type="number"
              fullWidth
              value={boxForm.maxAmount}
              onChange={(e) => setBoxForm({ ...boxForm, maxAmount: e.target.value })}
              InputProps={{ startAdornment: <InputAdornment position="start">$</InputAdornment> }}
            />
            <TextField label="Responsable" fullWidth value={boxForm.responsible} onChange={(e) => setBoxForm({ ...boxForm, responsible: e.target.value })} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowCreateBox(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCreateBox} disabled={createBoxMut.isPending}>
            Crear
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Abrir Sesión */}
      <Dialog open={showOpenSession} onClose={() => setShowOpenSession(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Abrir Sesión</DialogTitle>
        <DialogContent>
          <TextField
            label="Monto de Apertura"
            type="number"
            fullWidth
            sx={{ mt: 1 }}
            value={openAmount}
            onChange={(e) => setOpenAmount(e.target.value)}
            InputProps={{ startAdornment: <InputAdornment position="start">$</InputAdornment> }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowOpenSession(false)}>Cancelar</Button>
          <Button variant="contained" color="success" onClick={handleOpenSession} disabled={openSessionMut.isPending}>
            Abrir
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Cerrar Sesión */}
      <Dialog open={showCloseSession} onClose={() => setShowCloseSession(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Cerrar Sesión</DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2, mt: 1 }}>
            Al cerrar la sesión no podrá registrar más gastos hasta abrir una nueva.
          </Alert>
          <TextField
            label="Observaciones (opcional)"
            fullWidth
            multiline
            rows={2}
            value={closeNotes}
            onChange={(e) => setCloseNotes(e.target.value)}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowCloseSession(false)}>Cancelar</Button>
          <Button variant="contained" color="error" onClick={handleCloseSession} disabled={closeSessionMut.isPending}>
            Cerrar Sesión
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog: Registrar Gasto */}
      <Dialog open={showAddExpense} onClose={() => setShowAddExpense(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Registrar Gasto</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <FormControl fullWidth>
              <InputLabel>Categoría</InputLabel>
              <Select
                value={expForm.category}
                label="Categoría"
                onChange={(e) => setExpForm({ ...expForm, category: e.target.value })}
              >
                {CATEGORIAS.map((c) => (
                  <MenuItem key={c.value} value={c.value}>{c.label}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="Descripción"
              fullWidth
              value={expForm.description}
              onChange={(e) => setExpForm({ ...expForm, description: e.target.value })}
            />
            <TextField
              label="Monto"
              type="number"
              fullWidth
              value={expForm.amount}
              onChange={(e) => setExpForm({ ...expForm, amount: e.target.value })}
              InputProps={{ startAdornment: <InputAdornment position="start">$</InputAdornment> }}
            />
            <TextField
              label="Beneficiario (opcional)"
              fullWidth
              value={expForm.beneficiary}
              onChange={(e) => setExpForm({ ...expForm, beneficiary: e.target.value })}
            />
            <TextField
              label="Nro. Recibo (opcional)"
              fullWidth
              value={expForm.receiptNumber}
              onChange={(e) => setExpForm({ ...expForm, receiptNumber: e.target.value })}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setShowAddExpense(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleAddExpense} disabled={addExpenseMut.isPending}>
            Registrar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
