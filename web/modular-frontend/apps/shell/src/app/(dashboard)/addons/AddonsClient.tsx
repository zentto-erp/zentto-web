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
  Chip,
  Tooltip,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  OutlinedInput,
  Checkbox,
  ListItemText,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Add as AddIcon,
  OpenInNew as OpenIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Extension as ExtensionIcon,
  NavigateNext as NavNextIcon,
  Save as SaveIcon,
  ContentCopy as CopyIcon,
} from "@mui/icons-material";
import { listAddons, updateAddon, deleteAddon } from "@zentto/shared-api";
import type { StudioAddon } from "@zentto/shared-api";

/* ── Constants ────────────────────────────────────────────────── */
const WIZARD_CONFIG_KEY = "zentto-studio-wizard-config";

const AVAILABLE_MODULES = [
  { value: "global", label: "Global" },
  { value: "compras", label: "Compras" },
  { value: "ventas", label: "Ventas" },
  { value: "inventario", label: "Inventario" },
  { value: "contabilidad", label: "Contabilidad" },
  { value: "nomina", label: "Nómina" },
  { value: "bancos", label: "Bancos" },
  { value: "crm", label: "CRM" },
  { value: "logistica", label: "Logística" },
  { value: "manufactura", label: "Manufactura" },
  { value: "flota", label: "Flota" },
  { value: "pos", label: "POS" },
  { value: "restaurante", label: "Restaurante" },
  { value: "ecommerce", label: "E-Commerce" },
];

export default function AddonsClient() {
  const router = useRouter();
  const [apps, setApps] = useState<StudioAddon[]>([]);
  const [deleteTarget, setDeleteTarget] = useState<StudioAddon | null>(null);
  const [editTarget, setEditTarget] = useState<StudioAddon | null>(null);

  // Edit form state
  const [editTitle, setEditTitle] = useState("");
  const [editDesc, setEditDesc] = useState("");
  const [editIcon, setEditIcon] = useState("");
  const [editModules, setEditModules] = useState<string[]>([]);

  const [snack, setSnack] = useState<{ open: boolean; message: string; severity: "success" | "info" | "error" }>({
    open: false,
    message: "",
    severity: "info",
  });

  useEffect(() => {
    listAddons().then(setApps).catch(() => setApps([]));
  }, []);

  /* ── Actions ────────────────────────────────────────────────── */
  const handleCreateWizard = useCallback(() => {
    router.push("/studio-designer/wizard");
  }, [router]);

  const handleCreateDesigner = useCallback(() => {
    router.push("/studio-designer");
  }, [router]);

  const handleOpen = useCallback(
    (app: StudioAddon) => {
      localStorage.setItem(WIZARD_CONFIG_KEY, JSON.stringify(app.config));
      router.push("/studio-designer/preview");
    },
    [router]
  );

  const handleStartEdit = useCallback((app: StudioAddon) => {
    setEditTitle(app.title);
    setEditDesc(app.description);
    setEditIcon(app.icon);
    setEditModules(app.modules);
    setEditTarget(app);
  }, []);

  const handleSaveEdit = useCallback(async () => {
    if (!editTarget || !editTitle.trim()) return;
    await updateAddon(editTarget.id, {
      title: editTitle.trim(),
      description: editDesc.trim(),
      icon: editIcon,
      modules: editModules,
      config: editTarget.config,
    });
    const updated = await listAddons();
    setApps(updated);
    setEditTarget(null);
    setSnack({ open: true, message: "Aplicación actualizada", severity: "success" });
  }, [editTarget, editTitle, editDesc, editIcon, editModules]);

  const handleConfirmDelete = useCallback(async () => {
    if (!deleteTarget) return;
    await deleteAddon(deleteTarget.id);
    const updated = await listAddons();
    setApps(updated);
    setDeleteTarget(null);
    setSnack({ open: true, message: `"${deleteTarget.title}" eliminada`, severity: "info" });
  }, [deleteTarget]);

  const handleCopyId = useCallback((app: StudioAddon) => {
    navigator.clipboard.writeText(app.id);
    setSnack({ open: true, message: `ID copiado: ${app.id}`, severity: "info" });
  }, []);

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
              Aplicaciones Personalizadas
            </Typography>
          </Breadcrumbs>

          <Box sx={{ flex: 1 }} />

          <Button size="small" variant="outlined" onClick={handleCreateDesigner}>
            Abrir Designer
          </Button>
          <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={handleCreateWizard}>
            Crear con Wizard
          </Button>
        </Toolbar>
      </AppBar>

      {/* ── Content ──────────────────────────────────────────── */}
      <Box sx={{ flex: 1, p: 3 }}>
        {apps.length === 0 ? (
          <Box sx={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", py: 10 }}>
            <ExtensionIcon sx={{ fontSize: 64, color: "text.disabled", mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>
              No hay aplicaciones personalizadas
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3, textAlign: "center", maxWidth: 480 }}>
              Crea aplicaciones personalizadas con el Wizard o el Designer. Las apps aparecerán automáticamente en el menú del módulo que elijas.
            </Typography>
            <Box sx={{ display: "flex", gap: 2 }}>
              <Button variant="contained" startIcon={<AddIcon />} onClick={handleCreateWizard}>
                Crear con Wizard
              </Button>
              <Button variant="outlined" onClick={handleCreateDesigner}>
                Abrir Designer
              </Button>
            </Box>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {apps.map((app) => (
              <Grid key={app.id} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
                <Card variant="outlined" sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
                  <CardContent sx={{ flex: 1 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                      <Typography fontSize={24}>{app.icon || "📦"}</Typography>
                      <Typography variant="subtitle1" fontWeight={600} noWrap>
                        {app.title}
                      </Typography>
                    </Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
                      {app.description || "Sin descripción"}
                    </Typography>
                    <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}>
                      {app.modules.map((m) => (
                        <Chip key={m} label={AVAILABLE_MODULES.find((am) => am.value === m)?.label || m} size="small" variant="outlined" />
                      ))}
                    </Box>
                    <Typography variant="caption" color="text.disabled" sx={{ display: "block", mt: 1 }}>
                      {new Date(app.createdAt).toLocaleDateString()}
                    </Typography>
                  </CardContent>
                  <CardActions sx={{ justifyContent: "flex-end", gap: 0.5 }}>
                    <Tooltip title="Copiar ID">
                      <IconButton size="small" onClick={() => handleCopyId(app)}>
                        <CopyIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Abrir">
                      <IconButton size="small" onClick={() => handleOpen(app)}>
                        <OpenIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Editar">
                      <IconButton size="small" onClick={() => handleStartEdit(app)}>
                        <EditIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Eliminar">
                      <IconButton size="small" onClick={() => setDeleteTarget(app)} color="error">
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

      {/* ── Edit Dialog ──────────────────────────────────────── */}
      <Dialog open={!!editTarget} onClose={() => setEditTarget(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Editar Aplicación</DialogTitle>
        <DialogContent sx={{ display: "flex", flexDirection: "column", gap: 2, pt: "16px !important" }}>
          <TextField label="Nombre" value={editTitle} onChange={(e) => setEditTitle(e.target.value)} required fullWidth autoFocus />
          <TextField label="Descripción" value={editDesc} onChange={(e) => setEditDesc(e.target.value)} multiline rows={2} fullWidth />
          <TextField label="Icono (emoji)" value={editIcon} onChange={(e) => setEditIcon(e.target.value)} sx={{ maxWidth: 120 }} inputProps={{ maxLength: 4 }} />
          <FormControl fullWidth>
            <InputLabel>Módulos donde aparece</InputLabel>
            <Select
              multiple
              value={editModules}
              onChange={(e) => setEditModules(typeof e.target.value === "string" ? e.target.value.split(",") : e.target.value)}
              input={<OutlinedInput label="Módulos donde aparece" />}
              renderValue={(sel) => (
                <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}>
                  {sel.map((v) => (
                    <Chip key={v} label={AVAILABLE_MODULES.find((m) => m.value === v)?.label || v} size="small" />
                  ))}
                </Box>
              )}
            >
              {AVAILABLE_MODULES.map((m) => (
                <MenuItem key={m.value} value={m.value}>
                  <Checkbox checked={editModules.includes(m.value)} />
                  <ListItemText primary={m.label} />
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditTarget(null)}>Cancelar</Button>
          <Button onClick={handleSaveEdit} variant="contained" startIcon={<SaveIcon />} disabled={!editTitle.trim()}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Delete Dialog ────────────────────────────────────── */}
      <Dialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Eliminar aplicación</DialogTitle>
        <DialogContent>
          <DialogContentText>
            ¿Está seguro que desea eliminar &quot;{deleteTarget?.title}&quot;? Se eliminará de todos los módulos.
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
