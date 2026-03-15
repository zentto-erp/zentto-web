"use client";

import React, { useState } from "react";
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
  Card,
  CardContent,
  CardActions,
  Chip,
  List,
  ListItem,
  ListItemText,
  Collapse,
  IconButton,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Divider,
  Grid,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import EventNoteIcon from "@mui/icons-material/EventNote";
import ExpandMoreIcon from "@mui/icons-material/ExpandMore";
import ExpandLessIcon from "@mui/icons-material/ExpandLess";
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

export default function ComitesPage() {
  const [filter, setFilter] = useState<CommitteeFilter>({ page: 1, limit: 25 });
  const [committeeDialogOpen, setCommitteeDialogOpen] = useState(false);
  const [memberDialogOpen, setMemberDialogOpen] = useState(false);
  const [meetingDialogOpen, setMeetingDialogOpen] = useState(false);
  const [expandedId, setExpandedId] = useState<number | null>(null);
  const [selectedCommitteeId, setSelectedCommitteeId] = useState<number | null>(null);

  const [committeeForm, setCommitteeForm] = useState<CommitteeInput>({
    name: "", type: "", description: "", startDate: "",
  });
  const [memberForm, setMemberForm] = useState<Omit<AddCommitteeMemberInput, "committeeId">>({
    employeeCode: "", role: "",
  });
  const [meetingForm, setMeetingForm] = useState<Omit<RecordMeetingInput, "committeeId">>({
    date: "", summary: "", agreements: "",
  });

  const { data, isLoading } = useCommitteeList(filter);
  const saveCommitteeMutation = useSaveCommittee();
  const addMemberMutation = useAddCommitteeMember();
  const removeMemberMutation = useRemoveCommitteeMember();
  const recordMeetingMutation = useRecordMeeting();
  const meetingsQuery = useCommitteeMeetings(expandedId);

  const committees = data?.data ?? data?.rows ?? [];
  const meetings = meetingsQuery.data?.data ?? meetingsQuery.data?.rows ?? [];

  const handleSaveCommittee = async () => {
    await saveCommitteeMutation.mutateAsync(committeeForm);
    setCommitteeDialogOpen(false);
    setCommitteeForm({ name: "", type: "", description: "", startDate: "" });
  };

  const handleAddMember = async () => {
    if (!selectedCommitteeId) return;
    await addMemberMutation.mutateAsync({ ...memberForm, committeeId: selectedCommitteeId });
    setMemberDialogOpen(false);
    setMemberForm({ employeeCode: "", role: "" });
  };

  const handleRecordMeeting = async () => {
    if (!selectedCommitteeId) return;
    await recordMeetingMutation.mutateAsync({ ...meetingForm, committeeId: selectedCommitteeId });
    setMeetingDialogOpen(false);
    setMeetingForm({ date: "", summary: "", agreements: "" });
  };

  const openMemberDialog = (committeeId: number) => {
    setSelectedCommitteeId(committeeId);
    setMemberDialogOpen(true);
  };

  const openMeetingDialog = (committeeId: number) => {
    setSelectedCommitteeId(committeeId);
    setMeetingDialogOpen(true);
  };

  const toggleExpand = (committeeId: number) => {
    setExpandedId((prev) => (prev === committeeId ? null : committeeId));
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
        <Typography variant="h6">Comités</Typography>
        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCommitteeDialogOpen(true)}>
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
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>Tipo</InputLabel>
          <Select
            value={filter.type || ""}
            label="Tipo"
            onChange={(e) => setFilter((f) => ({ ...f, type: e.target.value || undefined }))}
          >
            <MenuItem value="">Todos</MenuItem>
            <MenuItem value="SEGURIDAD">Seguridad y Salud</MenuItem>
            <MenuItem value="DISCIPLINARIO">Disciplinario</MenuItem>
            <MenuItem value="BIENESTAR">Bienestar</MenuItem>
            <MenuItem value="CONVIVENCIA">Convivencia</MenuItem>
          </Select>
        </FormControl>
      </Stack>

      <Box sx={{ flex: 1, overflow: "auto" }}>
        {isLoading ? (
          <Typography>Cargando...</Typography>
        ) : (
          <Grid container spacing={2}>
            {committees.map((committee: Record<string, unknown>) => {
              const id = committee.id as number;
              const members = (committee.members ?? []) as Record<string, unknown>[];
              const isExpanded = expandedId === id;

              return (
                <Grid item xs={12} md={6} key={id}>
                  <Card sx={{ border: "1px solid #E5E7EB" }}>
                    <CardContent>
                      <Stack direction="row" justifyContent="space-between" alignItems="center">
                        <Typography variant="h6" sx={{ fontSize: "1rem" }}>
                          {committee.name as string}
                        </Typography>
                        <Chip label={committee.type as string} size="small" color="primary" variant="outlined" />
                      </Stack>
                      {committee.description && (
                        <Typography variant="body2" color="text.secondary" mt={1}>
                          {committee.description as string}
                        </Typography>
                      )}

                      <Typography variant="subtitle2" mt={2} mb={1}>
                        Miembros ({members.length})
                      </Typography>
                      <List dense disablePadding>
                        {members.map((member, idx) => (
                          <ListItem
                            key={idx}
                            disablePadding
                            secondaryAction={
                              <IconButton
                                edge="end"
                                size="small"
                                onClick={() =>
                                  removeMemberMutation.mutate({
                                    committeeId: id,
                                    memberId: member.memberId as number,
                                  })
                                }
                              >
                                <DeleteIcon fontSize="small" />
                              </IconButton>
                            }
                          >
                            <ListItemText
                              primary={member.employeeName as string}
                              secondary={member.role as string}
                            />
                          </ListItem>
                        ))}
                      </List>

                      {/* Meeting History */}
                      <Divider sx={{ my: 1 }} />
                      <Button
                        size="small"
                        onClick={() => toggleExpand(id)}
                        endIcon={isExpanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                      >
                        Historial de Reuniones
                      </Button>
                      <Collapse in={isExpanded}>
                        {meetingsQuery.isLoading ? (
                          <Typography variant="body2" sx={{ mt: 1 }}>Cargando...</Typography>
                        ) : meetings.length === 0 ? (
                          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                            Sin reuniones registradas
                          </Typography>
                        ) : (
                          <List dense disablePadding>
                            {meetings.map((meeting: Record<string, unknown>, idx: number) => (
                              <ListItem key={idx} disablePadding sx={{ pl: 1 }}>
                                <ListItemText
                                  primary={`${meeting.date} - ${meeting.summary}`}
                                  secondary={meeting.agreements ? `Acuerdos: ${meeting.agreements}` : undefined}
                                />
                              </ListItem>
                            ))}
                          </List>
                        )}
                      </Collapse>
                    </CardContent>
                    <CardActions>
                      <Button size="small" startIcon={<PersonAddIcon />} onClick={() => openMemberDialog(id)}>
                        Agregar Miembro
                      </Button>
                      <Button size="small" startIcon={<EventNoteIcon />} onClick={() => openMeetingDialog(id)}>
                        Registrar Reunión
                      </Button>
                    </CardActions>
                  </Card>
                </Grid>
              );
            })}
          </Grid>
        )}
      </Box>

      {/* New Committee Dialog */}
      <Dialog open={committeeDialogOpen} onClose={() => setCommitteeDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo Comité</DialogTitle>
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
                <MenuItem value="SEGURIDAD">Seguridad y Salud</MenuItem>
                <MenuItem value="DISCIPLINARIO">Disciplinario</MenuItem>
                <MenuItem value="BIENESTAR">Bienestar</MenuItem>
                <MenuItem value="CONVIVENCIA">Convivencia</MenuItem>
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
          <Button onClick={() => setCommitteeDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleSaveCommittee} disabled={saveCommitteeMutation.isPending}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add Member Dialog */}
      <Dialog open={memberDialogOpen} onClose={() => setMemberDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Agregar Miembro al Comité</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              label="Código Empleado"
              fullWidth
              value={memberForm.employeeCode}
              onChange={(e) => setMemberForm((f) => ({ ...f, employeeCode: e.target.value }))}
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
                <MenuItem value="DELEGADO_EMPLEADOR">Delegado del Empleador</MenuItem>
                <MenuItem value="DELEGADO_TRABAJADOR">Delegado del Trabajador</MenuItem>
                <MenuItem value="MIEMBRO">Miembro</MenuItem>
              </Select>
            </FormControl>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setMemberDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleAddMember} disabled={addMemberMutation.isPending}>
            Agregar
          </Button>
        </DialogActions>
      </Dialog>

      {/* Record Meeting Dialog */}
      <Dialog open={meetingDialogOpen} onClose={() => setMeetingDialogOpen(false)} maxWidth="sm" fullWidth>
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
          <Button onClick={() => setMeetingDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleRecordMeeting} disabled={recordMeetingMutation.isPending}>
            Registrar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
