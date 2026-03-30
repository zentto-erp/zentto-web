"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
  CardActions,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Snackbar,
  Alert,
  Breadcrumbs,
  Link,
  AppBar,
  Toolbar,
  Tooltip,
  TextField,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Add as AddIcon,
  Visibility as VisibilityIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Description as ReportIcon,
  NavigateNext as NavNextIcon,
  Save as SaveIcon,
  ContentCopy as CopyIcon,
  DesignServices as DesignerIcon,
} from "@mui/icons-material";
import { listSavedReports, updateSavedReport, deleteSavedReport, createSavedReport } from "@zentto/shared-api";
import type { SavedReport } from "@zentto/shared-api";

/* ── Constants ────────────────────────────────────────────────── */
const CONFIG_KEY = "zentto-report-studio-config";

export default function ReportStudioClient() {
  const router = useRouter();
  const [reports, setReports] = useState<SavedReport[]>([]);
  const [deleteTarget, setDeleteTarget] = useState<SavedReport | null>(null);
  const [editTarget, setEditTarget] = useState<SavedReport | null>(null);

  // Edit form state
  const [editName, setEditName] = useState("");
  const [editDesc, setEditDesc] = useState("");
  const [editIcon, setEditIcon] = useState("");

  const [snack, setSnack] = useState<{ open: boolean; message: string; severity: "success" | "info" | "error" }>({
    open: false,
    message: "",
    severity: "info",
  });

  const refresh = useCallback(() => {
    listSavedReports().then(setReports).catch(() => setReports([]));
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  /* ── Actions ────────────────────────────────────────────────── */
  const handleCreateWizard = useCallback(() => {
    router.push("/report-studio/wizard");
  }, [router]);

  const handleCreateDesigner = useCallback(() => {
    router.push("/report-studio/designer");
  }, [router]);

  const handleOpen = useCallback(
    (report: SavedReport) => {
      localStorage.setItem(CONFIG_KEY, JSON.stringify({ layout: report.layout, sampleData: report.sampleData }));
      router.push("/report-studio/preview");
    },
    [router]
  );

  const handleEdit = useCallback(
    (report: SavedReport) => {
      localStorage.setItem(CONFIG_KEY, JSON.stringify({ layout: report.layout, sampleData: report.sampleData }));
      router.push("/report-studio/designer?id=" + report.id);
    },
    [router]
  );

  const handleStartEditMeta = useCallback((report: SavedReport) => {
    setEditName(report.name);
    setEditDesc(report.description);
    setEditIcon(report.icon);
    setEditTarget(report);
  }, []);

  const handleSaveEdit = useCallback(async () => {
    if (!editTarget || !editName.trim()) return;
    await updateSavedReport(editTarget.id, {
      name: editName.trim(),
      description: editDesc.trim(),
      icon: editIcon,
      layout: editTarget.layout,
      sampleData: editTarget.sampleData,
    });
    refresh();
    setEditTarget(null);
    setSnack({ open: true, message: "Reporte actualizado", severity: "success" });
  }, [editTarget, editName, editDesc, editIcon, refresh]);

  const handleDuplicate = useCallback(
    async (report: SavedReport) => {
      await createSavedReport({
        name: report.name + " (copia)",
        layout: report.layout,
        sampleData: report.sampleData,
        icon: report.icon,
      });
      refresh();
      setSnack({ open: true, message: `"${report.name}" duplicado`, severity: "success" });
    },
    [refresh]
  );

  const handleConfirmDelete = useCallback(async () => {
    if (!deleteTarget) return;
    await deleteSavedReport(deleteTarget.id);
    refresh();
    setDeleteTarget(null);
    setSnack({ open: true, message: `"${deleteTarget.name}" eliminado`, severity: "info" });
  }, [deleteTarget, refresh]);

  return (
    <Box sx={{ display: "flex", flexDirection: "column", minHeight: "calc(100vh - 64px)" }}>
      {/* ── Toolbar ──────────────────────────────────────────── */}
      <AppBar position="static" color="default" elevation={1} sx={{ zIndex: 1 }}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Breadcrumbs separator={<NavNextIcon fontSize="small" />}>
            <Link underline="hover" color="inherit" href="/" sx={{ cursor: "pointer" }}>
              Inicio
            </Link>
            <Typography color="text.primary" fontWeight={600}>
              Mis Reportes
            </Typography>
          </Breadcrumbs>

          <Box sx={{ flex: 1 }} />

          <Button size="small" variant="outlined" onClick={handleCreateDesigner}>
            Abrir Designer
          </Button>
          <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={handleCreateWizard} sx={{ bgcolor: "#ed6c02", "&:hover": { bgcolor: "#e65100" } }}>
            Crear con Wizard
          </Button>
        </Toolbar>
      </AppBar>

      {/* ── Content ──────────────────────────────────────────── */}
      <Box sx={{ flex: 1, p: 3 }}>
        {reports.length === 0 ? (
          <Box sx={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", py: 10 }}>
            <ReportIcon sx={{ fontSize: 64, color: "text.disabled", mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No hay reportes personalizados
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3, textAlign: "center", maxWidth: 480 }}>
              Crea reportes con el Wizard o el Designer
            </Typography>
            <Box sx={{ display: "flex", gap: 2 }}>
              <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreateWizard} sx={{ bgcolor: "#ed6c02", "&:hover": { bgcolor: "#e65100" } }}>
                Crear con Wizard
              </Button>
              <Button variant="outlined" onClick={handleCreateDesigner}>
                Abrir Designer
              </Button>
            </Box>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {reports.map((report) => (
              <Grid key={report.id} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
                <Card variant="outlined" sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
                  <CardContent sx={{ flex: 1 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                      <Typography fontSize={24}>{report.icon || "📊"}</Typography>
                      <Typography variant="subtitle1" fontWeight={600} noWrap>
                        {report.name}
                      </Typography>
                    </Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                      {report.description || "Sin descripcion"}
                    </Typography>
                    <Typography variant="caption" color="text.disabled" sx={{ display: "block", mt: 1 }}>
                      {report.updatedAt ? new Date(report.updatedAt).toLocaleDateString() : new Date(report.createdAt).toLocaleDateString()}
                    </Typography>
                  </CardContent>
                  <CardActions sx={{ justifyContent: "flex-end", gap: 0.5 }}>
                    <Tooltip title="Preview">
                      <IconButton size="small" onClick={() => handleOpen(report)}>
                        <VisibilityIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Editar en Designer">
                      <IconButton size="small" onClick={() => handleEdit(report)}>
                        <DesignerIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Editar Metadatos">
                      <IconButton size="small" onClick={() => handleStartEditMeta(report)}>
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Duplicar">
                      <IconButton size="small" onClick={() => handleDuplicate(report)}>
                        <CopyIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Eliminar">
                      <IconButton size="small" onClick={() => setDeleteTarget(report)} color="error">
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </CardActions>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Box>

      {/* ── Edit Metadata Dialog ─────────────────────────────── */}
      <Dialog open={!!editTarget} onClose={() => setEditTarget(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Editar Reporte</DialogTitle>
        <DialogContent sx={{ display: "flex", flexDirection: "column", gap: 2, pt: "16px !important" }}>
          <TextField label="Nombre" value={editName} onChange={(e) => setEditName(e.target.value)} required fullWidth autoFocus />
          <TextField label="Descripcion" value={editDesc} onChange={(e) => setEditDesc(e.target.value)} multiline rows={2} fullWidth />
          <TextField label="Icono (emoji)" value={editIcon} onChange={(e) => setEditIcon(e.target.value)} sx={{ maxWidth: 120 }} inputProps={{ maxLength: 4 }} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditTarget(null)}>Cancelar</Button>
          <Button onClick={handleSaveEdit} variant="contained" startIcon={<SaveIcon />} disabled={!editName.trim()}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Delete Dialog ────────────────────────────────────── */}
      <Dialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Eliminar reporte</DialogTitle>
        <DialogContent>
          <DialogContentText>
            ¿Esta seguro que desea eliminar &quot;{deleteTarget?.name}&quot;? Esta accion no se puede deshacer.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button onClick={handleConfirmDelete} color="error" variant="contained">
            Eliminar
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Snackbar ─────────────────────────────────────────── */}
      <Snackbar open={snack.open} autoHideDuration={3000} onClose={() => setSnack((s) => ({ ...s, open: false }))} anchorOrigin={{ vertical: "bottom", horizontal: "center" }}>
        <Alert severity={snack.severity} variant="filled" onClose={() => setSnack((s) => ({ ...s, open: false }))}>
          {snack.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
