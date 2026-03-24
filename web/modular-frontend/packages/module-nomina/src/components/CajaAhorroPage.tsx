"use client";

import React, { useState } from "react";
import {
  Box,
  Paper,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  Tab,
  Tabs,
  IconButton,
  Tooltip,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import AddIcon from "@mui/icons-material/Add";
import CheckCircleIcon from "@mui/icons-material/CheckCircle";
import { formatCurrency } from "@zentto/shared-api";
import {
  useSavingsList,
  useEnrollSavings,
  useLoanList,
  useRequestLoan,
  useApproveLoan,
  type SavingsFilter,
  type LoanFilter,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

export default function CajaAhorroPage() {
  const [tab, setTab] = useState(0);
  const [savingsFilter, setSavingsFilter] = useState<SavingsFilter>({ page: 1, limit: 25 });
  const [loanFilter, setLoanFilter] = useState<LoanFilter>({ page: 1, limit: 25 });
  const [enrollOpen, setEnrollOpen] = useState(false);
  const [loanRequestOpen, setLoanRequestOpen] = useState(false);
  const [enrollForm, setEnrollForm] = useState({ employeeCode: "", contributionPct: 5, employerMatchPct: 5 });
  const [loanForm, setLoanForm] = useState({ employeeCode: "", amount: 0, installments: 12, reason: "" });

  const { data: savingsData, isLoading: savingsLoading } = useSavingsList(savingsFilter);
  const { data: loanData, isLoading: loansLoading } = useLoanList(loanFilter);
  const enrollMutation = useEnrollSavings();
  const loanRequestMutation = useRequestLoan();
  const approveLoanMutation = useApproveLoan();

  const savingsRows = savingsData?.data ?? savingsData?.rows ?? [];
  const loanRows = loanData?.data ?? loanData?.rows ?? [];

  const savingsColumns: ZenttoColDef[] = [
    { field: "EmployeeCode", headerName: "Código", width: 100 },
    { field: "EmployeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    { field: "EmployeeContribution", headerName: "% Aporte", width: 110, renderCell: (p) => `${p.value ?? 0}%` },
    { field: "EmployerMatch", headerName: "% Patronal", width: 110, renderCell: (p) => `${p.value ?? 0}%` },
    { field: "CurrentBalance", headerName: "Saldo", width: 140, renderCell: (p) => formatCurrency(p.value ?? 0), currency: true, aggregation: 'sum' },
    {
      field: "Status",
      headerName: "Estado",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={p.value || "ACTIVO"}
          size="small"
          color={p.value === "ACTIVO" ? "success" : "default"}
        />
      ),
    },
  ];

  const loanColumns: ZenttoColDef[] = [
    { field: "employeeCode", headerName: "Código", width: 100 },
    { field: "employeeName", headerName: "Empleado", flex: 1, minWidth: 200 },
    { field: "amount", headerName: "Monto", width: 130, renderCell: (p) => formatCurrency(p.value ?? 0), currency: true, aggregation: 'sum' },
    { field: "installments", headerName: "Cuotas", width: 90 },
    { field: "outstanding", headerName: "Saldo Pendiente", width: 140, renderCell: (p) => formatCurrency(p.value ?? 0), currency: true, aggregation: 'sum' },
    {
      field: "status",
      headerName: "Estado",
      width: 120,
      renderCell: (p) => (
        <Chip
          label={p.value || "PENDIENTE"}
          size="small"
          color={
            p.value === "APROBADO" ? "success" :
            p.value === "RECHAZADO" ? "error" :
            p.value === "PAGADO" ? "info" : "warning"
          }
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 80,
      sortable: false,
      renderCell: (p) =>
        p.row.status === "PENDIENTE" ? (
          <Tooltip title="Aprobar prestamo">
            <IconButton
              size="small"
              color="success"
              onClick={() => approveLoanMutation.mutate({ loanId: p.row.id, approved: true })}
            >
              <CheckCircleIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        ) : null,
    },
  ];

  const handleEnroll = async () => {
    await enrollMutation.mutateAsync(enrollForm);
    setEnrollOpen(false);
    setEnrollForm({ employeeCode: "", contributionPct: 5, employerMatchPct: 5 });
  };

  const handleRequestLoan = async () => {
    await loanRequestMutation.mutateAsync(loanForm);
    setLoanRequestOpen(false);
    setLoanForm({ employeeCode: "", amount: 0, installments: 12, reason: "" });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Caja de Ahorro</Typography>
        <Stack direction="row" spacing={1}>
          {tab === 0 && (
            <Button variant="contained" startIcon={<AddIcon />} onClick={() => setEnrollOpen(true)}>
              Inscribir Empleado
            </Button>
          )}
          {tab === 1 && (
            <Button variant="contained" startIcon={<AddIcon />} onClick={() => setLoanRequestOpen(true)}>
              Solicitar Préstamo
            </Button>
          )}
        </Stack>
      </Stack>

      <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ mb: 2 }}>
        <Tab label="Miembros" />
        <Tab label="Préstamos" />
      </Tabs>

      <TabPanel value={tab} index={0}>
        <Stack direction="row" spacing={2} mb={2}>
          <TextField
            label="Buscar"
           
            value={savingsFilter.search || ""}
            onChange={(e) => setSavingsFilter((f) => ({ ...f, search: e.target.value }))}
          />
        </Stack>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={savingsRows}
            columns={savingsColumns}
            loading={savingsLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => r.SavingsFundId ?? r.EmployeeCode}
            showTotals
            totalsLabel="Total"
            enableClipboard
            mobileVisibleFields={['EmployeeCode', 'EmployeeName']}
            smExtraFields={['CurrentBalance', 'Status']}
          />
        </Paper>
      </TabPanel>

      <TabPanel value={tab} index={1}>
        <Stack direction="row" spacing={2} mb={2}>
          <TextField
            label="Buscar"
           
            value={loanFilter.search || ""}
            onChange={(e) => setLoanFilter((f) => ({ ...f, search: e.target.value }))}
          />
        </Stack>
        <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
          <ZenttoDataGrid
            rows={loanRows}
            columns={loanColumns}
            loading={loansLoading}
            pageSizeOptions={[25, 50]}
            disableRowSelectionOnClick
            getRowId={(r) => r.id ?? `${r.employeeCode}-${r.amount}`}
            showTotals
            totalsLabel="Total"
            enableClipboard
            mobileVisibleFields={['employeeCode', 'employeeName']}
            smExtraFields={['amount', 'status']}
          />
        </Paper>
      </TabPanel>

      {/* Enroll Dialog */}
      <Dialog open={enrollOpen} onClose={() => setEnrollOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Inscribir Empleado en Caja de Ahorro</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector
              value={enrollForm.employeeCode}
              onChange={(code) => setEnrollForm((f) => ({ ...f, employeeCode: code }))}
            />
            <TextField
              label="% Aporte Empleado"
              type="number"
              fullWidth
              value={enrollForm.contributionPct}
              onChange={(e) => setEnrollForm((f) => ({ ...f, contributionPct: Number(e.target.value) }))}
            />
            <TextField
              label="% Aporte Patronal"
              type="number"
              fullWidth
              value={enrollForm.employerMatchPct}
              onChange={(e) => setEnrollForm((f) => ({ ...f, employerMatchPct: Number(e.target.value) }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEnrollOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleEnroll} disabled={enrollMutation.isPending}>
            Inscribir
          </Button>
        </DialogActions>
      </Dialog>

      {/* Loan Request Dialog */}
      <Dialog open={loanRequestOpen} onClose={() => setLoanRequestOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Solicitar Préstamo</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector
              value={loanForm.employeeCode}
              onChange={(code) => setLoanForm((f) => ({ ...f, employeeCode: code }))}
            />
            <TextField
              label="Monto"
              type="number"
              fullWidth
              value={loanForm.amount || ""}
              onChange={(e) => setLoanForm((f) => ({ ...f, amount: Number(e.target.value) }))}
            />
            <TextField
              label="Cuotas"
              type="number"
              fullWidth
              value={loanForm.installments}
              onChange={(e) => setLoanForm((f) => ({ ...f, installments: Number(e.target.value) }))}
            />
            <TextField
              label="Motivo"
              fullWidth
              multiline
              rows={2}
              value={loanForm.reason}
              onChange={(e) => setLoanForm((f) => ({ ...f, reason: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLoanRequestOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleRequestLoan} disabled={loanRequestMutation.isPending}>
            Solicitar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
