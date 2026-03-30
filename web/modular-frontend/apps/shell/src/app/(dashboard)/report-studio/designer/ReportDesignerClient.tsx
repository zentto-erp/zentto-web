"use client";

import React, { useEffect, useState, useCallback, useRef } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  Snackbar,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  Breadcrumbs,
  Link,
  CircularProgress,
  Tooltip,
  TextField,
  Stack,
} from "@mui/material";
import {
  NoteAdd as NewIcon,
  Save as SaveIcon,
  FolderOpen as LoadIcon,
  Code as ExportIcon,
  Preview as PreviewIcon,
  AutoFixHigh as WizardIcon,
  NavigateNext as NavNextIcon,
} from "@mui/icons-material";
import { ReportDesigner } from "@zentto/shared-reports";
import { createBlankLayout } from "@zentto/shared-reports";
import type { ReportLayout, DataSet } from "@zentto/report-core";
import {
  listSavedReports,
  getSavedReport,
  createSavedReport,
  updateSavedReport,
} from "@zentto/shared-api";
import type { SavedReport } from "@zentto/shared-api";

/* ── localStorage keys ─────────────────────────────────────────── */
const CONFIG_KEY = "zentto-report-studio-config";
const AUTOSAVE_KEY = "zentto-report-designer:autosave";

/* ── Component ─────────────────────────────────────────────────── */
interface Props {
  basePath?: string;
}

export default function ReportDesignerClient({ basePath = "/report-studio" }: Props) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const [layout, setLayout] = useState<ReportLayout>(() => createBlankLayout("Nuevo Reporte"));
  const [sampleData, setSampleData] = useState<DataSet>({});
  const [currentId, setCurrentId] = useState<string | null>(null);
  const [isModified, setIsModified] = useState(false);
  const [loading, setLoading] = useState(true);

  /* Dialogs */
  const [loadDialogOpen, setLoadDialogOpen] = useState(false);
  const [savedList, setSavedList] = useState<SavedReport[]>([]);
  const [saveDialogOpen, setSaveDialogOpen] = useState(false);
  const [saveName, setSaveName] = useState("");

  /* Snackbar */
  const [snack, setSnack] = useState<{ message: string; severity: "success" | "error" | "info" } | null>(null);

  /* Ref to track layout for autosave without re-triggering effect */
  const layoutRef = useRef(layout);
  const sampleDataRef = useRef(sampleData);
  useEffect(() => { layoutRef.current = layout; }, [layout]);
  useEffect(() => { sampleDataRef.current = sampleData; }, [sampleData]);

  /* ── Initialization ──────────────────────────────────────────── */
  useEffect(() => {
    async function init() {
      try {
        const idParam = searchParams.get("id");

        if (idParam) {
          const saved = await getSavedReport(idParam);
          if (saved) {
            setLayout(saved.layout as unknown as ReportLayout);
            setSampleData((saved.sampleData ?? {}) as DataSet);
            setCurrentId(saved.id);
            setLoading(false);
            return;
          }
        }

        const raw = localStorage.getItem(CONFIG_KEY);
        if (raw) {
          try {
            const parsed = JSON.parse(raw);
            if (parsed.layout) setLayout(parsed.layout);
            if (parsed.sampleData) setSampleData(parsed.sampleData);
            localStorage.removeItem(CONFIG_KEY);
            setLoading(false);
            return;
          } catch { /* ignore parse errors */ }
        }

        setLayout(createBlankLayout("Nuevo Reporte"));
      } catch {
        setLayout(createBlankLayout("Nuevo Reporte"));
      } finally {
        setLoading(false);
      }
    }

    init();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /* ── Auto-save every 30s ─────────────────────────────────────── */
  useEffect(() => {
    const interval = setInterval(() => {
      try {
        localStorage.setItem(
          AUTOSAVE_KEY,
          JSON.stringify({ layout: layoutRef.current, sampleData: sampleDataRef.current, savedAt: new Date().toISOString() }),
        );
      } catch { /* quota exceeded — ignore */ }
    }, 30_000);
    return () => clearInterval(interval);
  }, []);

  /* ── Layout change handler ───────────────────────────────────── */
  const handleLayoutChange = useCallback((newLayout: ReportLayout) => {
    setLayout(newLayout);
    setIsModified(true);
  }, []);

  /* ── Actions ─────────────────────────────────────────────────── */
  const handleNew = useCallback(() => {
    setLayout(createBlankLayout("Nuevo Reporte"));
    setSampleData({});
    setCurrentId(null);
    setIsModified(false);
    setSnack({ message: "Nuevo reporte creado", severity: "info" });
  }, []);

  const handleSave = useCallback(async () => {
    if (currentId) {
      try {
        await updateSavedReport(currentId, {
          name: (layout as any).name ?? "Sin titulo",
          layout: layout as unknown as Record<string, unknown>,
          sampleData: sampleData as unknown as Record<string, unknown>,
        });
        setIsModified(false);
        setSnack({ message: "Reporte guardado", severity: "success" });
      } catch {
        setSnack({ message: "Error al guardar el reporte", severity: "error" });
      }
    } else {
      setSaveName((layout as any).name ?? "Nuevo Reporte");
      setSaveDialogOpen(true);
    }
  }, [currentId, layout, sampleData]);

  const handleSaveAs = useCallback(async () => {
    if (!saveName.trim()) return;
    try {
      const created = await createSavedReport({
        name: saveName.trim(),
        layout: layout as unknown as Record<string, unknown>,
        sampleData: sampleData as unknown as Record<string, unknown>,
      });
      setCurrentId(created.id);
      setIsModified(false);
      setSaveDialogOpen(false);
      setSnack({ message: `Reporte "${saveName.trim()}" guardado`, severity: "success" });
    } catch {
      setSnack({ message: "Error al crear el reporte", severity: "error" });
    }
  }, [saveName, layout, sampleData]);

  const handleOpenLoadDialog = useCallback(async () => {
    try {
      const reports = await listSavedReports();
      setSavedList(reports);
    } catch {
      setSavedList([]);
    }
    setLoadDialogOpen(true);
  }, []);

  const handleLoad = useCallback((saved: SavedReport) => {
    setLayout(saved.layout as unknown as ReportLayout);
    setSampleData((saved.sampleData ?? {}) as DataSet);
    setCurrentId(saved.id);
    setIsModified(false);
    setLoadDialogOpen(false);
    setSnack({ message: `Reporte "${saved.name}" cargado`, severity: "success" });
  }, []);

  const handleExportJson = useCallback(() => {
    const json = JSON.stringify(layout, null, 2);
    navigator.clipboard.writeText(json).then(() => {
      setSnack({ message: "JSON copiado al portapapeles", severity: "success" });
    });
  }, [layout]);

  const handlePreview = useCallback(() => {
    localStorage.setItem(CONFIG_KEY, JSON.stringify({ layout, sampleData }));
    router.push(`${basePath}/preview`);
  }, [layout, sampleData, router]);

  const handleWizard = useCallback(() => {
    router.push(`${basePath}/wizard`);
  }, [router]);

  /* ── Loading state ───────────────────────────────────────────── */
  if (loading) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "calc(100vh - 64px)" }}>
        <CircularProgress sx={{ mr: 2 }} />
        <Typography>Cargando Report Designer...</Typography>
      </Box>
    );
  }

  /* ── Render ──────────────────────────────────────────────────── */
  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)", overflow: "hidden" }}>
      {/* ── Toolbar ──────────────────────────────────────────── */}
      <AppBar position="static" color="default" elevation={1} sx={{ zIndex: 1 }}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Breadcrumbs separator={<NavNextIcon fontSize="small" />} sx={{ flexShrink: 0 }}>
            <Link underline="hover" color="inherit" href={basePath} sx={{ cursor: "pointer" }}>
              Reportes
            </Link>
            <Typography color="text.primary" fontWeight={600}>
              Designer
            </Typography>
          </Breadcrumbs>

          <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
            {(layout as any).name || "Sin titulo"}
            {isModified && " *"}
          </Typography>

          <Box sx={{ flex: 1 }} />

          <Stack direction="row" spacing={0.5}>
            <Tooltip title="Nuevo reporte vacio">
              <Button size="small" startIcon={<NewIcon />} onClick={handleNew}>
                Nuevo
              </Button>
            </Tooltip>

            <Tooltip title="Guardar reporte">
              <Button size="small" startIcon={<SaveIcon />} onClick={handleSave} variant="contained" color="primary">
                Guardar
              </Button>
            </Tooltip>

            <Tooltip title="Cargar reporte guardado">
              <Button size="small" startIcon={<LoadIcon />} onClick={handleOpenLoadDialog}>
                Cargar
              </Button>
            </Tooltip>

            <Tooltip title="Copiar JSON al portapapeles">
              <Button size="small" startIcon={<ExportIcon />} onClick={handleExportJson}>
                Exportar JSON
              </Button>
            </Tooltip>

            <Tooltip title="Vista previa del reporte">
              <Button size="small" startIcon={<PreviewIcon />} onClick={handlePreview}>
                Preview
              </Button>
            </Tooltip>

            <Tooltip title="Abrir wizard de reportes">
              <Button size="small" startIcon={<WizardIcon />} onClick={handleWizard} color="secondary">
                Wizard
              </Button>
            </Tooltip>
          </Stack>
        </Toolbar>
      </AppBar>

      {/* ── Designer ─────────────────────────────────────────── */}
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        <ReportDesigner
          layout={layout}
          sampleData={sampleData}
          onLayoutChange={handleLayoutChange}
          style={{ height: "100%" }}
        />
      </Box>

      {/* ── Load dialog ──────────────────────────────────────── */}
      <Dialog open={loadDialogOpen} onClose={() => setLoadDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Reportes guardados</DialogTitle>
        <DialogContent dividers>
          {savedList.length === 0 ? (
            <Typography color="text.secondary" sx={{ py: 4, textAlign: "center" }}>
              No hay reportes guardados
            </Typography>
          ) : (
            <List disablePadding>
              {savedList.map((r) => (
                <ListItem key={r.id} disablePadding divider>
                  <ListItemButton onClick={() => handleLoad(r)}>
                    <ListItemText
                      primary={r.name}
                      secondary={r.updatedAt ? `Actualizado: ${new Date(r.updatedAt).toLocaleString()}` : undefined}
                    />
                  </ListItemButton>
                </ListItem>
              ))}
            </List>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLoadDialogOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* ── Save-as dialog ───────────────────────────────────── */}
      <Dialog open={saveDialogOpen} onClose={() => setSaveDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle>Guardar reporte como</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="Nombre del reporte"
            value={saveName}
            onChange={(e) => setSaveName(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter") handleSaveAs(); }}
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSaveDialogOpen(false)}>Cancelar</Button>
          <Button onClick={handleSaveAs} variant="contained" disabled={!saveName.trim()}>
            Guardar
          </Button>
        </DialogActions>
      </Dialog>

      {/* ── Snackbar ─────────────────────────────────────────── */}
      <Snackbar
        open={snack !== null}
        autoHideDuration={3000}
        onClose={() => setSnack(null)}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert
          severity={snack?.severity ?? "info"}
          variant="filled"
          onClose={() => setSnack(null)}
        >
          {snack?.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
