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
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
} from "@mui/material";
import { DataGrid, type GridColDef } from "@mui/x-data-grid";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import DeleteIcon from "@mui/icons-material/Delete";
import IconButton from "@mui/material/IconButton";
import {
  useCommitteeList,
  useSaveCommittee,
  useAddCommitteeMember,
  useRemoveCommitteeMember,
  useRecordMeeting,
  useCommitteeMeetings,
  type CommitteeFilter,
  type CommitteeInput,
  type AddCommitteeMemberInput,
  type RecordMeetingInput,
} from "../hooks/useRRHH";
import EmployeeSelector from "./EmployeeSelector";

function TabPanel({ children, value, index }: { children: React.ReactNode; value: number; index: number }) {
  return value === index ? <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>{children}</Box> : null;
}

const emptyCommittee: CommitteeInput = {
  name: "", type: "", description: "", startDate: "", endDate: "",
};

export default function ComitesPage() {
  const [filter, setFilter] = useState<CommitteeFilter>({ page: 1, limit: 25 });
  const [createOpen, setCreateOpen] = useState(false);
  const [committeeForm, setCommitteeForm] = useState<CommitteeInput>({ ...emptyCommittee });

  // Detail dialog state
  const [detailId, setDetailId] = useState<number | null>(null);
  const [detailTab, setDetailTab] = useState(0);
  const [detailData, setDetailData] = useState<Record<string, unknown> | null>(null);

  // Member dialog
  const [memberOpen, setMemberOpen] = useState(false);
  const [memberForm, setMemberForm] = useState<Omit<AddCommitteeMemberInput, "committeeId">>({
    employeeCode: "", role: "",
  });

  // Meeting dialog
  const [meetingOpen, setMeetingOpen] = useState(false);
  const [meetingForm, setMeetingForm] = useState<Omit<RecordMeetingInput, "committeeId">>({
    date: "", summary: "", agreements: "",
  });

  const { data, isLoading } = useCommitteeList(filter);
  const saveMutation = useSaveCommittee();
  const addMemberMutation = useAddCommitteeMember();
  const removeMemberMutation = useRemoveCommitteeMember();
  const recordMeetingMutation = useRecordMeeting();
  const meetingsQuery = useCommitteeMeetings(detailId);

  const rows = data?.data ?? data?.rows ?? [];
  const meetings = meetingsQuery.data?.data ?? meetingsQuery.data?.rows ?? meetingsQuery.data ?? [];

  const columns: GridColDef[] = [
    { field: "name", headerName: "Nombre", flex: 1, minWidth: 200 },
    {
      field: "type",
      headerName: "Tipo",
      width: 180,
      renderCell: (p) => (
        <Chip
          label={p.value || "—"}
          size="small"
          variant="outlined"
          color="primary"
        />
      ),
    },
    { field: "startDate", headerName: "Fecha Inicio", width: 120 },
    { field: "endDate", headerName: "Fecha Fin", width: 120 },
    {
      field: "memberCount",
      headerName: "Miembros",
      width: 100,
      type: "number",
    },
    {
      field: "active",
      headerName: "Estado",
      width: 110,
      renderCell: (p) => (
        <Chip
          label={p.value === false ? "Inactivo" : "Activo"}
          size="small"
          color={p.value === false ? "default" : "success"}
        />
      ),
    },
    {
      field: "actions",
      headerName: "",
      width: 80,
      sortable: false,
      renderCell: (p) => (
        <IconButton
          size="small"
          onClick={() => {
            setDetailId(p.row.id);
            setDetailData(p.row);
            setDetailTab(0);
          }}
        >
          <VisibilityIcon fontSize="small" />
        </IconButton>
      ),
    },
  ];

  const handleCreateCommittee = async () => {
    await saveMutation.mutateAsync(committeeForm);
    setCreateOpen(false);
    setCommitteeForm({ ...emptyCommittee });
  };

  const handleAddMember = async () => {
    if (!detailId) return;
    await addMemberMutation.mutateAsync({ committeeId: detailId, ...memberForm });
    setMemberOpen(false);
    setMemberForm({ employeeCode: "", role: "" });
  };

  const handleRemoveMember = (memberId: number) => {
    if (!detailId) return;
    removeMemberMutation.mutate({ committeeId: detailId, memberId });
  };

  const handleRecordMeeting = async () => {
    if (!detailId) return;
    await recordMeetingMutation.mutateAsync({ committeeId: detailId, ...meetingForm });
    setMeetingOpen(false);
    setMeetingForm({ date: "", summary: "", agreements: "" });
  };

  const members: Record<string, unknown>[] = (detailData as any)?.members ?? [];

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Comités de Seguridad e Higiene</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>
          Nuevo Comité
        </Button>
      </Stack>

      <Stack direction="row" spacing={2} mb={2}>
        <TextField
          label="Buscar"
          size="small"
          value={filter.search || ""}
          onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
        />
        <FormControl size="small" sx={{ minWidth: 160 }}>
          <InputLabel>Tipo</InputLabel>
          <Select
            value={filter.type || ""}
            label="Tipo"
            onChange={(e) => setFilter((f) => ({ ...f, type: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="SEGURIDAD_HIGIENE">Seguridad e Higiene</MenuItem>
            <MenuItem value="SALUD_LABORAL">Salud Laboral</MenuItem>
            <MenuItem value="BIENESTAR">Bienestar</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <DataGrid
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.id ?? r.name}
        />
      </Paper>

      {/* Create Committee Dialog */}
      <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Crear Comité</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Nombre"
              fullWidth
              value={committeeForm.name}
              onChange={(e) => setCommitteeForm((f) => ({ ...f, name: e.target.value }))}
            />
            <FormControl fullWidth>
              <InputLabel>Tipo</InputLabel>
              <Select
                value={committeeForm.type}
                label="Tipo"
                onChange={(e) => setCommitteeForm((f) => ({ ...f, type: e.target.value }))}
              >
                <MenuItem value="SEGURIDAD_HIGIENE">Seguridad e Higiene</MenuItem>
                <MenuItem value="SALUD_LABORAL">Salud Laboral</MenuItem>
                <MenuItem value="BIENESTAR">Bienestar</MenuItem>
              </Select>
            </FormControl>
            <TextField
              label="Descripción"
              fullWidth
              multiline
              rows={2}
              value={committeeForm.description || ""}
              onChange={(e) => setCommitteeForm((f) => ({ ...f, description: e.target.value }))}
            />
            <TextField
              label="Fecha Inicio"
              type="date"
              fullWidth
              InputLabelProps={{ shrink: true }}
              value={committeeForm.startDate}
              onChange={(e) => setCommitteeForm((f) => ({ ...f, startDate: e.target.value }))}
            />
            <TextField
              label="Fecha Fin"
              type="date"
              fullWidth
              InputLabelProps={{ shrink: true }}
              value={committeeForm.endDate || ""}
              onChange={(e) => setCommitteeForm((f) => ({ ...f, endDate: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCreateCommittee} disabled={saveMutation.isPending}>
            Crear
          </Button>
        </DialogActions>
      </Dialog>

      {/* Detail Dialog with Tabs: Miembros y Reuniones */}
      <Dialog
        open={detailId != null}
        onClose={() => { setDetailId(null); setDetailData(null); }}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Stack direction="row" justifyContent="space-between" alignItems="center">
            <Typography variant="h6">{(detailData as Record<string, string>)?.name ?? "Comité"}</Typography>
            <Chip
              label={(detailData as Record<string, unknown>)?.active === false ? "Inactivo" : "Activo"}
              size="small"
              color={(detailData as Record<string, unknown>)?.active === false ? "default" : "success"}
            />
          </Stack>
        </DialogTitle>
        <DialogContent>
          <Tabs value={detailTab} onChange={(_, v) => setDetailTab(v)} sx={{ mb: 2 }}>
            <Tab label="Miembros" />
            <Tab label="Reuniones" />
          </Tabs>

          {/* Tab: Miembros */}
          <TabPanel value={detailTab} index={0}>
            <Stack direction="row" justifyContent="flex-end" mb={1}>
              <Button size="small" startIcon={<AddIcon />} onClick={() => setMemberOpen(true)}>
                Agregar Miembro
              </Button>
            </Stack>
            {members.length === 0 ? (
              <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: "center" }}>
                No hay miembros registrados.
              </Typography>
            ) : (
              <List dense>
                {members.map((m: Record<string, unknown>, i: number) => (
                  <ListItem key={(m.id as number) ?? i} divider>
                    <ListItemText
                      primary={String(m.employeeName ?? m.employeeCode ?? "")}
                      secondary={`Rol: ${String(m.role ?? "—")}`}
                    />
                    <ListItemSecondaryAction>
                      <IconButton
                        edge="end"
                        size="small"
                        color="error"
                        onClick={() => handleRemoveMember(m.id as number)}
                      >
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </ListItemSecondaryAction>
                  </ListItem>
                ))}
              </List>
            )}
          </TabPanel>

          {/* Tab: Reuniones */}
          <TabPanel value={detailTab} index={1}>
            <Stack direction="row" justifyContent="flex-end" mb={1}>
              <Button size="small" startIcon={<AddIcon />} onClick={() => setMeetingOpen(true)}>
                Registrar Reunión
              </Button>
            </Stack>
            {meetingsQuery.isLoading ? (
              <CircularProgress />
            ) : Array.isArray(meetings) && meetings.length === 0 ? (
              <Typography variant="body2" color="text.secondary" sx={{ py: 2, textAlign: "center" }}>
                No hay reuniones registradas.
              </Typography>
            ) : (
              <List dense>
                {(Array.isArray(meetings) ? meetings : []).map((m: Record<string, unknown>, i: number) => (
                  <ListItem key={(m.id as number) ?? i} divider>
                    <ListItemText
                      primary={`${String(m.date ?? "")} — ${String(m.summary ?? "")}`}
                      secondary={m.agreements ? `Acuerdos: ${String(m.agreements)}` : undefined}
                    />
                  </ListItem>
                ))}
              </List>
            )}
          </TabPanel>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => { setDetailId(null); setDetailData(null); }}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* Add Member Dialog */}
      <Dialog open={memberOpen} onClose={() => setMemberOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Agregar Miembro</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <EmployeeSelector
              value={memberForm.employeeCode}
              onChange={(code) => setMemberForm((f) => ({ ...f, employeeCode: code }))}
            />
            <FormControl fullWidth>
              <InputLabel>Rol</InputLabel>
              <Select
                value={memberForm.role}
                label="Rol"
                onChange={(e) => setMemberForm((f) => ({ ...f, role: e.target.value }))}
              >
                <MenuItem value="PRESIDENTE">Presidente</MenuItem>
                <MenuItem value="SECRETARIO">Secretario</MenuItem>
                <MenuItem value="DELEGADO_PATRONAL">Delegado Patronal</MenuItem>
                <MenuItem value="DELEGADO_TRABAJADOR">Delegado Trabajador</MenuItem>
                <MenuItem value="SUPLENTE">Suplente</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setMemberOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleAddMember} disabled={addMemberMutation.isPending}>
            Agregar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Record Meeting Dialog */}
      <Dialog open={meetingOpen} onClose={() => setMeetingOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Registrar Reunión</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Fecha"
              type="date"
              fullWidth
              InputLabelProps={{ shrink: true }}
              value={meetingForm.date}
              onChange={(e) => setMeetingForm((f) => ({ ...f, date: e.target.value }))}
            />
            <TextField
              label="Resumen"
              fullWidth
              multiline
              rows={3}
              value={meetingForm.summary}
              onChange={(e) => setMeetingForm((f) => ({ ...f, summary: e.target.value }))}
            />
            <TextField
              label="Acuerdos"
              fullWidth
              multiline
              rows={2}
              value={meetingForm.agreements || ""}
              onChange={(e) => setMeetingForm((f) => ({ ...f, agreements: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setMeetingOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleRecordMeeting} disabled={recordMeetingMutation.isPending}>
            Registrar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
