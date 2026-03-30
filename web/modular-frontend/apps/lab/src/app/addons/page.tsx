"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box, Typography, Button, Card, CardContent, CardActions,
  IconButton, Dialog, DialogTitle, DialogContent, DialogContentText,
  DialogActions, Snackbar, Alert, AppBar, Toolbar, Chip, Tooltip,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import {
  Add as AddIcon, OpenInNew as OpenIcon, Delete as DeleteIcon,
  Extension as ExtensionIcon, ContentCopy as CopyIcon,
  ArrowBack as BackIcon,
} from "@mui/icons-material";
import { listAddons, deleteAddon } from "@zentto/shared-api";
import type { StudioAddon } from "@zentto/shared-api";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-studio-app": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}

export default function AddonsPage() {
  const router = useRouter();
  const appRef = useRef<any>(null);
  const [apps, setApps] = useState<StudioAddon[]>([]);
  const [loading, setLoading] = useState(true);
  const [deleteTarget, setDeleteTarget] = useState<StudioAddon | null>(null);
  const [runTarget, setRunTarget] = useState<StudioAddon | null>(null);
  const [studioReady, setStudioReady] = useState(false);
  const [snack, setSnack] = useState({ open: false, msg: "", sev: "info" as "success" | "info" | "error" });

  useEffect(() => {
    listAddons().then(setApps).catch(() => setApps([])).finally(() => setLoading(false));
  }, []);

  const handleRun = useCallback((app: StudioAddon) => {
    setRunTarget(app);
    if (!studioReady) import("@zentto/studio").then(() => setStudioReady(true));
  }, [studioReady]);

  useEffect(() => {
    if (!studioReady || !appRef.current || !runTarget) return;
    appRef.current.config = runTarget.config;
  }, [studioReady, runTarget]);

  const handleDelete = useCallback(async () => {
    if (!deleteTarget) return;
    await deleteAddon(deleteTarget.id);
    setApps((prev) => prev.filter((a) => a.id !== deleteTarget.id));
    setDeleteTarget(null);
    setSnack({ open: true, msg: `"${deleteTarget.title}" eliminada`, sev: "info" });
  }, [deleteTarget]);

  if (loading) return <Box sx={{ display: "flex", justifyContent: "center", py: 10 }}><CircularProgress /></Box>;

  // Running an addon
  if (runTarget) {
    return (
      <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
        <AppBar position="static" color="default" elevation={1}>
          <Toolbar variant="dense" sx={{ gap: 1 }}>
            <Button size="small" startIcon={<BackIcon />} onClick={() => setRunTarget(null)}>Volver</Button>
            <Typography fontSize={18}>{runTarget.icon} {runTarget.title}</Typography>
          </Toolbar>
        </AppBar>
        <Box sx={{ flex: 1, overflow: "hidden" }}>
          {!studioReady ? (
            <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%" }}><CircularProgress /></Box>
          ) : (
            <zentto-studio-app ref={appRef} style={{ display: "block", width: "100%", height: "100%" }} />
          )}
        </Box>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", flexDirection: "column", minHeight: "calc(100vh - 64px)" }}>
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Typography fontWeight={700}>Addons</Typography>
          <Box flex={1} />
          <Button size="small" variant="outlined" onClick={() => router.push("/studio-designer")}>Designer</Button>
          <Button size="small" variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/studio-designer/wizard")}>Crear con Wizard</Button>
        </Toolbar>
      </AppBar>

      <Box sx={{ flex: 1, p: 3 }}>
        {apps.length === 0 ? (
          <Box sx={{ display: "flex", flexDirection: "column", alignItems: "center", py: 10 }}>
            <ExtensionIcon sx={{ fontSize: 64, color: "text.disabled", mb: 2 }} />
            <Typography variant="h6" color="text.secondary" gutterBottom>No hay addons</Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>Crea tu primera aplicación con el Wizard.</Typography>
            <Button variant="contained" startIcon={<AddIcon />} onClick={() => router.push("/studio-designer/wizard")}>Crear</Button>
          </Box>
        ) : (
          <Grid container spacing={3}>
            {apps.map((app) => (
              <Grid key={app.id} size={{ xs: 12, sm: 6, md: 4, lg: 3 }}>
                <Card variant="outlined" sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
                  <CardContent sx={{ flex: 1 }}>
                    <Box sx={{ display: "flex", alignItems: "center", gap: 1, mb: 1 }}>
                      <Typography fontSize={24}>{app.icon || "📦"}</Typography>
                      <Typography variant="subtitle1" fontWeight={600} noWrap>{app.title}</Typography>
                    </Box>
                    <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>{app.description || "Sin descripción"}</Typography>
                    <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}>
                      {app.modules.map((m) => <Chip key={m} label={m} size="small" variant="outlined" />)}
                    </Box>
                  </CardContent>
                  <CardActions sx={{ justifyContent: "flex-end" }}>
                    <Tooltip title="Copiar ID"><IconButton size="small" onClick={() => { navigator.clipboard.writeText(app.id); setSnack({ open: true, msg: "ID copiado", sev: "info" }); }}><CopyIcon fontSize="small" /></IconButton></Tooltip>
                    <Tooltip title="Ejecutar"><IconButton size="small" color="primary" onClick={() => handleRun(app)}><OpenIcon fontSize="small" /></IconButton></Tooltip>
                    <Tooltip title="Eliminar"><IconButton size="small" color="error" onClick={() => setDeleteTarget(app)}><DeleteIcon fontSize="small" /></IconButton></Tooltip>
                  </CardActions>
                </Card>
              </Grid>
            ))}
          </Grid>
        )}
      </Box>

      <Dialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)}>
        <DialogTitle>Eliminar</DialogTitle>
        <DialogContent><DialogContentText>¿Eliminar &quot;{deleteTarget?.title}&quot;?</DialogContentText></DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteTarget(null)}>Cancelar</Button>
          <Button onClick={handleDelete} color="error" variant="contained">Eliminar</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={snack.open} autoHideDuration={2500} onClose={() => setSnack((s) => ({ ...s, open: false }))} anchorOrigin={{ vertical: "bottom", horizontal: "center" }}>
        <Alert severity={snack.sev} variant="filled">{snack.msg}</Alert>
      </Snackbar>
    </Box>
  );
}
