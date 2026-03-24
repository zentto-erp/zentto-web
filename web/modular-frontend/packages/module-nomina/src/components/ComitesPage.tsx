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
  IconButton,
  Tooltip,
} from "@mui/material";
import { ZenttoDataGrid, type ZenttoColDef, DatePicker, FormGrid, FormField } from "@zentto/shared-ui";
import dayjs from "dayjs";
import AddIcon from "@mui/icons-material/Add";
import VisibilityIcon from "@mui/icons-material/Visibility";
import DeleteIcon from "@mui/icons-material/Delete";
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

  const columns: ZenttoColDef[] = [
    { field: "CommitteeName", headerName: "Nombre", flex: 1, minWidth: 200 },
    {
      field: "MeetingFrequency",
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
    { field: "FormationDate", headerName: "Fecha Inicio", width: 120 },
    {
      field: "ActiveMemberCount",
      headerName: "Miembros",
      width: 100,
      type: "number",
    },
    {
      field: "IsActive",
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
        <Tooltip title="Ver detalle">
          <IconButton
            size="small"
            onClick={() => {
              setDetailId(p.row.SafetyCommitteeId);
              setDetailData(p.row);
              setDetailTab(0);
            }}
          >
            <VisibilityIcon fontSize="small" />
          </IconButton>
        </Tooltip>
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

      <FormGrid spacing={2} sx={{ mb: 2 }}>
        <FormField xs={12} sm={6}>
          <TextField
            label="Buscar"
           
            fullWidth
            value={filter.search || ""}
            onChange={(e) => setFilter((f) => ({ ...f, search: e.target.value }))}
          />
        </FormField>
        <FormField xs={12} sm={6}>
          <FormControl fullWidth>
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
        </FormField>
      </FormGrid>

      <Paper sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, width: "100%", border: "1px solid #E5E7EB" }}>
        <ZenttoDataGrid
            gridId="nomina-comites-list"
          rows={rows}
          columns={columns}
          loading={isLoading}
          pageSizeOptions={[25, 50]}
          disableRowSelectionOnClick
          getRowId={(r) => r.SafetyCommitteeId ?? r.CommitteeName}
          enableClipboard
          enableHeaderFilters
          mobileVisibleFields={['CommitteeName', 'IsActive']}
          smExtraFields={['MeetingFrequency', 'ActiveMemberCount']}
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
            <DatePicker
              label="Fecha Inicio"
              value={committeeForm.startDate ? dayjs(committeeForm.startDate) : null}
              onChange={(v) => setCommitteeForm((f) => ({ ...f, startDate: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
            />
            <DatePicker
              label="Fecha Fin"
              value={committeeForm.endDate ? dayjs(committeeForm.endDate) : null}
              onChange={(v) => setCommitteeForm((f) => ({ ...f, endDate: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
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
            <Typography variant="h6">{(detailData as Record<string, string>)?.CommitteeName ?? "Comité"}</Typography>
            <Chip
              label={(detailData as Record<string, unknown>)?.IsActive === false ? "Inactivo" : "Activo"}
              size="small"
              color={(detailData as Record<string, unknown>)?.IsActive === false ? "default" : "success"}
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
                      <Tooltip title="Eliminar miembro">
                        <IconButton
                          edge="end"
                          size="small"
                          color="error"
                          onClick={() => handleRemoveMember(m.id as number)}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
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
            <DatePicker
              label="Fecha"
              value={meetingForm.date ? dayjs(meetingForm.date) : null}
              onChange={(v) => setMeetingForm((f) => ({ ...f, date: v ? v.format('YYYY-MM-DD') : '' }))}
              slotProps={{ textField: { size: 'small', fullWidth: true } }}
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
