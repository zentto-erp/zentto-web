"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Box,
  Typography,
  Button,
  TextField,
  Stack,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Tab,
  Tabs,
} from "@mui/material";

import type { ColumnDef } from "@zentto/datagrid-core";
import AddIcon from "@mui/icons-material/Add";
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

const SAVINGS_COLUMNS: ColumnDef[] = [
  { field: "EmployeeCode", header: "Código", width: 100, sortable: true },
  { field: "EmployeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "EmployeeContribution", header: "% Aporte", width: 110 },
  { field: "EmployerMatch", header: "% Patronal", width: 110 },
  { field: "CurrentBalance", header: "Saldo", width: 140, type: "number", aggregation: "sum" },
  {
    field: "Status", header: "Estado", width: 110,
    statusColors: { ACTIVO: "success" },
  },
];

const LOAN_COLUMNS: ColumnDef[] = [
  { field: "employeeCode", header: "Código", width: 100, sortable: true },
  { field: "employeeName", header: "Empleado", flex: 1, minWidth: 200, sortable: true },
  { field: "amount", header: "Monto", width: 130, type: "number", aggregation: "sum" },
  { field: "installments", header: "Cuotas", width: 90, type: "number" },
  { field: "outstanding", header: "Saldo Pendiente", width: 140, type: "number", aggregation: "sum" },
  {
    field: "status", header: "Estado", width: 120,
    statusColors: { APROBADO: "success", RECHAZADO: "error", PAGADO: "info", PENDIENTE: "warning" },
  },
];


const SVG_APPROVE = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>';

export default function CajaAhorroPage() {
  const savingsGridRef = useRef<any>(null);
  const loansGridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
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

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // Savings grid
  useEffect(() => {
    const el = savingsGridRef.current;
    if (!el || !registered) return;
    el.columns = SAVINGS_COLUMNS;
    el.rows = savingsRows;
    el.loading = savingsLoading;
    el.getRowId = (r: any) => r.SavingsFundId ?? r.EmployeeCode;
  }, [savingsRows, savingsLoading, registered]);

  // Loans grid
  useEffect(() => {
    const el = loansGridRef.current;
    if (!el || !registered) return;
    el.columns = LOAN_COLUMNS;
    el.rows = loanRows;
    el.loading = loansLoading;
    el.getRowId = (r: any) => r.id ?? `${r.employeeCode}-${r.amount}`;
    el.actionButtons = [
      { icon: SVG_APPROVE, label: "Aprobar préstamo", action: "approve", color: "#2e7d32" },
    ];
  }, [loanRows, loansLoading, registered]);

  useEffect(() => {
    const el = loansGridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail;
      if (action === "approve" && row.status === "PENDIENTE") {
        approveLoanMutation.mutate({ loanId: row.id, approved: true });
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, loanRows]);

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
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid
            ref={savingsGridRef}
            height="calc(100vh - 200px)"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-grouping
            enable-pivot
          />
        </Box>
      </TabPanel>

      <TabPanel value={tab} index={1}>
        <Box sx={{ flex: 1, minHeight: 0 }}>
          <zentto-grid
            ref={loansGridRef}
            height="calc(100vh - 200px)"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
            enable-grouping
            enable-pivot
          />
        </Box>
      </TabPanel>

      {/* Enroll Dialog */}
      <Dialog open={enrollOpen} onClose={() => setEnrollOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Inscribir Empleado en Caja de Ahorro</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector value={enrollForm.employeeCode} onChange={(code) => setEnrollForm((f) => ({ ...f, employeeCode: code }))} />
            <TextField label="% Aporte Empleado" type="number" fullWidth value={enrollForm.contributionPct} onChange={(e) => setEnrollForm((f) => ({ ...f, contributionPct: Number(e.target.value) }))} />
            <TextField label="% Aporte Patronal" type="number" fullWidth value={enrollForm.employerMatchPct} onChange={(e) => setEnrollForm((f) => ({ ...f, employerMatchPct: Number(e.target.value) }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEnrollOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleEnroll} disabled={enrollMutation.isPending}>Inscribir</Button>
        </DialogActions>
      </Dialog>

      {/* Loan Request Dialog */}
      <Dialog open={loanRequestOpen} onClose={() => setLoanRequestOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Solicitar Préstamo</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector value={loanForm.employeeCode} onChange={(code) => setLoanForm((f) => ({ ...f, employeeCode: code }))} />
            <TextField label="Monto" type="number" fullWidth value={loanForm.amount || ""} onChange={(e) => setLoanForm((f) => ({ ...f, amount: Number(e.target.value) }))} />
            <TextField label="Cuotas" type="number" fullWidth value={loanForm.installments} onChange={(e) => setLoanForm((f) => ({ ...f, installments: Number(e.target.value) }))} />
            <TextField label="Motivo" fullWidth multiline rows={2} value={loanForm.reason} onChange={(e) => setLoanForm((f) => ({ ...f, reason: e.target.value }))} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLoanRequestOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleRequestLoan} disabled={loanRequestMutation.isPending}>Solicitar</Button>
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
