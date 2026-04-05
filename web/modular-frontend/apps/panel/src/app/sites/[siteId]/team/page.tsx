"use client";

import { useCallback, useEffect, useState } from "react";
import { useParams } from "next/navigation";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import Table from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TableRow from "@mui/material/TableRow";
import Paper from "@mui/material/Paper";
import Avatar from "@mui/material/Avatar";
import Chip from "@mui/material/Chip";
import IconButton from "@mui/material/IconButton";
import Tooltip from "@mui/material/Tooltip";
import Select from "@mui/material/Select";
import MenuItem from "@mui/material/MenuItem";
import Dialog from "@mui/material/Dialog";
import DialogTitle from "@mui/material/DialogTitle";
import DialogContent from "@mui/material/DialogContent";
import DialogActions from "@mui/material/DialogActions";
import TextField from "@mui/material/TextField";
import FormControl from "@mui/material/FormControl";
import InputLabel from "@mui/material/InputLabel";
import CircularProgress from "@mui/material/CircularProgress";
import Skeleton from "@mui/material/Skeleton";
import DeleteIcon from "@mui/icons-material/Delete";
import PersonAddIcon from "@mui/icons-material/PersonAdd";
import GroupIcon from "@mui/icons-material/Group";
import { collaboratorsApi } from "@/lib/api";

interface Collaborator {
  id: string;
  userId: string;
  name: string;
  email: string;
  role: "owner" | "admin" | "editor" | "viewer";
  joinedAt: string;
}

const ROLES = [
  { value: "admin", label: "Admin" },
  { value: "editor", label: "Editor" },
  { value: "viewer", label: "Viewer" },
];

function getInitials(name: string) {
  return name
    .split(" ")
    .map((w) => w[0])
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

function getRoleColor(role: string): "error" | "primary" | "info" | "default" {
  switch (role) {
    case "owner": return "error";
    case "admin": return "primary";
    case "editor": return "info";
    default: return "default";
  }
}

export default function TeamPage() {
  const params = useParams();
  const siteId = params.siteId as string;

  const [collaborators, setCollaborators] = useState<Collaborator[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [inviteOpen, setInviteOpen] = useState(false);
  const [inviteEmail, setInviteEmail] = useState("");
  const [inviteRole, setInviteRole] = useState("editor");
  const [inviting, setInviting] = useState(false);
  const [removeTarget, setRemoveTarget] = useState<Collaborator | null>(null);
  const [removing, setRemoving] = useState(false);
  const [updatingRole, setUpdatingRole] = useState<string | null>(null);

  const fetchCollaborators = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await collaboratorsApi.list(siteId);
      setCollaborators(Array.isArray(data) ? data : data.collaborators ?? []);
    } catch (err: any) {
      setError(err.message ?? "Error al cargar colaboradores");
    } finally {
      setLoading(false);
    }
  }, [siteId]);

  useEffect(() => {
    fetchCollaborators();
  }, [fetchCollaborators]);

  const handleInvite = async () => {
    if (!inviteEmail.trim()) return;
    try {
      setInviting(true);
      const result = await collaboratorsApi.invite(siteId, inviteEmail.trim(), inviteRole);
      setCollaborators((prev) => [...prev, result]);
      setInviteOpen(false);
      setInviteEmail("");
      setInviteRole("editor");
    } catch (err: any) {
      setError(err.message ?? "Error al invitar colaborador");
    } finally {
      setInviting(false);
    }
  };

  const handleRoleChange = async (collab: Collaborator, newRole: string) => {
    try {
      setUpdatingRole(collab.userId);
      await collaboratorsApi.updateRole(siteId, collab.userId, newRole);
      setCollaborators((prev) =>
        prev.map((c) => (c.userId === collab.userId ? { ...c, role: newRole as any } : c)),
      );
    } catch (err: any) {
      setError(err.message ?? "Error al cambiar rol");
    } finally {
      setUpdatingRole(null);
    }
  };

  const handleRemove = async () => {
    if (!removeTarget) return;
    try {
      setRemoving(true);
      await collaboratorsApi.remove(siteId, removeTarget.userId);
      setCollaborators((prev) => prev.filter((c) => c.userId !== removeTarget.userId));
    } catch (err: any) {
      setError(err.message ?? "Error al eliminar colaborador");
    } finally {
      setRemoving(false);
      setRemoveTarget(null);
    }
  };

  const formatDate = (dateStr: string) => {
    try {
      return new Intl.DateTimeFormat("es", {
        day: "2-digit",
        month: "short",
        year: "numeric",
      }).format(new Date(dateStr));
    } catch {
      return dateStr;
    }
  };

  /* ---------- Loading skeleton ---------- */
  if (loading) {
    return (
      <Box sx={{ p: 4 }}>
        <Skeleton variant="text" width={200} height={48} sx={{ mb: 2 }} />
        <Skeleton variant="rounded" height={300} />
      </Box>
    );
  }

  /* ---------- Empty state ---------- */
  if (!loading && collaborators.length === 0 && !error) {
    return (
      <Box
        sx={{
          p: 4,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "60vh",
          textAlign: "center",
        }}
      >
        <GroupIcon sx={{ fontSize: 96, color: "text.disabled", mb: 2 }} />
        <Typography variant="h5" gutterBottom>
          Sin colaboradores
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
          Invita a tu equipo para trabajar juntos en este sitio.
        </Typography>
        <Button
          variant="contained"
          size="large"
          startIcon={<PersonAddIcon />}
          onClick={() => setInviteOpen(true)}
        >
          Invitar colaborador
        </Button>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 4 }}>
      {/* Header */}
      <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 4 }}>
        <Typography variant="h4" fontWeight={700}>
          Equipo
        </Typography>
        <Button
          variant="contained"
          startIcon={<PersonAddIcon />}
          onClick={() => setInviteOpen(true)}
        >
          Invitar
        </Button>
      </Box>

      {/* Error */}
      {error && (
        <Typography color="error" sx={{ mb: 2 }}>
          {error}
        </Typography>
      )}

      {/* Collaborators table */}
      <TableContainer component={Paper} variant="outlined">
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Miembro</TableCell>
              <TableCell>Rol</TableCell>
              <TableCell>Se unio</TableCell>
              <TableCell align="right">Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {collaborators.map((collab) => {
              const isOwner = collab.role === "owner";
              return (
                <TableRow key={collab.userId} hover>
                  <TableCell>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
                      <Avatar sx={{ bgcolor: "#6366f1", width: 36, height: 36, fontSize: 14 }}>
                        {getInitials(collab.name || collab.email)}
                      </Avatar>
                      <Box>
                        <Typography variant="body2" fontWeight={600}>
                          {collab.name || "Sin nombre"}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {collab.email}
                        </Typography>
                      </Box>
                    </Box>
                  </TableCell>
                  <TableCell>
                    {isOwner ? (
                      <Chip label="Owner" color="error" size="small" variant="filled" />
                    ) : (
                      <FormControl size="small" sx={{ minWidth: 120 }}>
                        <Select
                          value={collab.role}
                          onChange={(e) => handleRoleChange(collab, e.target.value)}
                          disabled={updatingRole === collab.userId}
                          sx={{ fontSize: 14 }}
                        >
                          {ROLES.map((r) => (
                            <MenuItem key={r.value} value={r.value}>
                              {r.label}
                            </MenuItem>
                          ))}
                        </Select>
                      </FormControl>
                    )}
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      {formatDate(collab.joinedAt)}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    {isOwner ? (
                      <Typography variant="caption" color="text.disabled">
                        ---
                      </Typography>
                    ) : (
                      <Tooltip title="Eliminar colaborador">
                        <IconButton
                          size="small"
                          color="error"
                          onClick={() => setRemoveTarget(collab)}
                        >
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Invite dialog */}
      <Dialog open={inviteOpen} onClose={() => !inviting && setInviteOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Invitar colaborador</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="Correo electronico"
            type="email"
            value={inviteEmail}
            onChange={(e) => setInviteEmail(e.target.value)}
            sx={{ mt: 1, mb: 2 }}
          />
          <FormControl fullWidth>
            <InputLabel>Rol</InputLabel>
            <Select value={inviteRole} label="Rol" onChange={(e) => setInviteRole(e.target.value)}>
              {ROLES.map((r) => (
                <MenuItem key={r.value} value={r.value}>
                  {r.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setInviteOpen(false)} disabled={inviting}>
            Cancelar
          </Button>
          <Button
            variant="contained"
            onClick={handleInvite}
            disabled={inviting || !inviteEmail.trim()}
            startIcon={inviting ? <CircularProgress size={16} /> : undefined}
          >
            {inviting ? "Invitando..." : "Invitar"}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Remove confirmation dialog */}
      <Dialog open={!!removeTarget} onClose={() => !removing && setRemoveTarget(null)}>
        <DialogTitle>Eliminar colaborador</DialogTitle>
        <DialogContent>
          <Typography>
            ¿Estas seguro de que deseas eliminar a{" "}
            <strong>{removeTarget?.name || removeTarget?.email}</strong> del equipo?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRemoveTarget(null)} disabled={removing}>
            Cancelar
          </Button>
          <Button
            onClick={handleRemove}
            color="error"
            variant="contained"
            disabled={removing}
            startIcon={removing ? <CircularProgress size={16} /> : undefined}
          >
            {removing ? "Eliminando..." : "Eliminar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
