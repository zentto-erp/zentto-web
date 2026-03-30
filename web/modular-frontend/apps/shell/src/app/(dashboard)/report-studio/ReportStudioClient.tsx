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
  Tabs,
  Tab,
  Chip,
  InputAdornment,
  CircularProgress,
} from "@mui/material";
import SearchIcon from "@mui/icons-material/Search";
import PublicIcon from "@mui/icons-material/Public";
import PersonIcon from "@mui/icons-material/Person";
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
import { listSavedReports, listPublicReports, getPublicReport, getSavedReport, updateSavedReport, deleteSavedReport, createSavedReport } from "@zentto/shared-api";
import type { SavedReport } from "@zentto/shared-api";

/* ── Constants ────────────────────────────────────────────────── */
const CONFIG_KEY = "zentto-report-studio-config";

interface Props {
  basePath?: string;
}

/* ── Module label mapping ─────────────────────────────────────── */
const MODULE_LABELS: Record<string, string> = {
  contabilidad: "Contabilidad",
  ventas: "Ventas",
  compras: "Compras",
  inventario: "Inventario",
  bancos: "Bancos",
  nomina: "Nomina",
  crm: "CRM",
  maestros: "Maestros",
};

function getModuleFromId(id: string): string {
  const first = id.split("-")[0];
  return MODULE_LABELS[first] || first;
}

export default function ReportStudioClient({ basePath = "/report-studio" }: Props) {
  const router = useRouter();
  const [publicReports, setPublicReports] = useState<SavedReport[]>([]);
  const [myReports, setMyReports] = useState<SavedReport[]>([]);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState(0);
  const [search, setSearch] = useState("");
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

  const refresh = useCallback(async () => {
    setLoading(true);
    const [pub, saved] = await Promise.all([
      listPublicReports().catch(() => []),
      listSavedReports().catch(() => []),
    ]);
    setPublicReports(pub);
    setMyReports(saved);
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  /* ── Filtered reports ──────────────────────────────────────── */
  const activeReports = tab === 0 ? publicReports : myReports;
  const filteredReports = search
    ? activeReports.filter((r) => r.name.toLowerCase().includes(search.toLowerCase()) || r.description?.toLowerCase().includes(search.toLowerCase()))
    : activeReports;

  /* ── Actions ────────────────────────────────────────────────── */
  const handleCreateWizard = useCallback(() => {
    router.push(`${basePath}/wizard`);
  }, [router, basePath]);

  const handleCreateDesigner = useCallback(() => {
    router.push(`${basePath}/designer`);
  }, [router, basePath]);

  const resolveLayout = useCallback(async (report: SavedReport): Promise<{ layout: Record<string, unknown>; sampleData: Record<string, unknown> } | null> => {
    // If layout already loaded (has bands), use it directly
    if (report.layout && Object.keys(report.layout).length > 2) {
      return { layout: report.layout, sampleData: report.sampleData };
    }
    // Otherwise fetch full layout — try public first, then saved
    const full = await getPublicReport(report.id).catch(() => null) ?? await getSavedReport(report.id).catch(() => null);
    if (full?.layout && Object.keys(full.layout).length > 0) {
      return { layout: full.layout, sampleData: full.sampleData };
    }
    return null;
  }, []);

  const handleOpen = useCallback(
    async (report: SavedReport) => {
      const resolved = await resolveLayout(report);
      if (!resolved) return;
      localStorage.setItem(CONFIG_KEY, JSON.stringify(resolved));
      router.push(`${basePath}/preview`);
    },
    [router, basePath, resolveLayout]
  );

  const handleEdit = useCallback(
    async (report: SavedReport) => {
      const resolved = await resolveLayout(report);
      if (!resolved) return;
      localStorage.setItem(CONFIG_KEY, JSON.stringify(resolved));
      router.push(`${basePath}/designer?id=${report.id}`);
    },
    [router, basePath, resolveLayout]
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

      {/* ── Tabs + Search ───────────────────────────────────────── */}
      <Box sx={{ px: 3, pt: 2, display: "flex", alignItems: "center", gap: 2 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)}>
          <Tab icon={<PublicIcon fontSize="small" />} iconPosition="start" label={`Plantillas (${publicReports.length})`} />
          <Tab icon={<PersonIcon fontSize="small" />} iconPosition="start" label={`Mis Reportes (${myReports.length})`} />
        </Tabs>
        <Box sx={{ flex: 1 }} />
        <TextField
          size="small"
          placeholder="Buscar reporte..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
          sx={{ width: 260 }}
        />
      </Box>

      {/* ── Content ──────────────────────────────────────────── */}
      <Box sx={{ flex: 1, p: 3 }}>
        {loading ? (
          <Box sx={{ display: "flex", justifyContent: "center", py: 10 }}><CircularProgress /></Box>
        ) : filteredReports.length === 0 ? (
          <Box sx={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", py: 10 }}>
            <ReportIcon sx={{ fontSize: 64, color: "text.disabled", mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              {tab === 0 ? "No hay plantillas disponibles" : "No hay reportes personalizados"}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3, textAlign: "center", maxWidth: 480 }}>
              {tab === 0 ? "Las plantillas del sistema apareceran aqui cuando sean configuradas" : "Crea reportes con el Wizard o el Designer"}
            </Typography>
            {tab === 1 && (
              <Box sx={{ display: "flex", gap: 2 }}>
                <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreateWizard} sx={{ bgcolor: "#ed6c02", "&:hover": { bgcolor: "#e65100" } }}>
                  Crear con Wizard
                </Button>
                <Button variant="outlined" onClick={handleCreateDesigner}>
                  Abrir Designer
                </Button>
              </Box>
            )}
          </Box>
        ) : (
          <Grid container spacing={3}>
            {filteredReports.map((report) => (
              <Grid key={report.id} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
                <Card variant="outlined" sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
                  <CardContent sx={{ flex: 1 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                      <Typography fontSize={24}>{report.icon || "📊"}</Typography>
                      <Typography variant="subtitle1" fontWeight={600} noWrap>
                        {report.name}
                      </Typography>
                    </Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                      {report.description || "Sin descripcion"}
                    </Typography>
                    {tab === 0 && (
                      <Chip label={getModuleFromId(report.id)} size="small" variant="outlined" sx={{ mt: 0.5 }} />
                    )}
                    {report.updatedAt && (
                      <Typography variant="caption" color="text.disabled" sx={{ display: "block", mt: 1 }}>
                        {new Date(report.updatedAt).toLocaleDateString()}
                      </Typography>
                    )}
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
                    {tab === 1 && (
                      <>
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
                      </>
                    )}
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
