"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  IconButton,
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
  ListItemSecondaryAction,
  Breadcrumbs,
  Link,
  CircularProgress,
  Tooltip,
} from "@mui/material";
import {
  NoteAdd as NewIcon,
  Save as SaveIcon,
  FolderOpen as LoadIcon,
  Code as ExportIcon,
  AutoFixHigh as WizardIcon,
  Delete as DeleteIcon,
  NavigateNext as NavNextIcon,
} from "@mui/icons-material";
import type { StudioSchema } from "@zentto/studio-core";
import { useStudioRegistration } from "@/lib/zentto-grid";

/* ── JSX declarations for Lit web components ───────────────────── */
declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-page-designer": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
      "zs-toast": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
      "zs-confirm-dialog": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

/* ── localStorage keys ─────────────────────────────────────────── */
const STORAGE_KEY = "zentto-studio-schemas";

interface SavedSchema {
  id: string;
  title: string;
  schema: StudioSchema;
  updatedAt: string;
}

function loadSchemas(): SavedSchema[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveSchemas(schemas: SavedSchema[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(schemas));
}

/* ── Default empty schema ──────────────────────────────────────── */
function createEmptySchema(): StudioSchema {
  return {
    id: `schema-${Date.now()}`,
    version: "1.0",
    title: "Nuevo Formulario",
    layout: { type: "grid", columns: 2, gap: 16 },
    sections: [
      {
        id: "seccion-1",
        title: "Seccion Principal",
        fields: [],
      },
    ],
    actions: [
      { id: "guardar", type: "submit", label: "Guardar", variant: "primary" },
      { id: "cancelar", type: "reset", label: "Cancelar", variant: "secondary" },
    ],
  };
}

/* ── Component ─────────────────────────────────────────────────── */
export default function StudioDesignerClient() {
  const router = useRouter();
  const designerRef = useRef<any>(null);
  const toastRef = useRef<any>(null);

  const { registered } = useStudioRegistration();
  const [schema, setSchema] = useState<StudioSchema>(createEmptySchema);
  const [currentId, setCurrentId] = useState<string | null>(null);
  const [loadDialogOpen, setLoadDialogOpen] = useState(false);
  const [savedList, setSavedList] = useState<SavedSchema[]>([]);
  const [snack, setSnack] = useState<{ open: boolean; message: string; severity: "success" | "error" | "info" }>({
    open: false,
    message: "",
    severity: "info",
  });

  /* ── Push schema into <zs-page-designer> & listen events ────── */
  useEffect(() => {
    if (!registered || !designerRef.current) return;
    designerRef.current.schema = schema;
    designerRef.current.data = {};

    const handleChange = (e: Event) => {
      const newSchema = (e as CustomEvent).detail.schema;
      setSchema(newSchema);
    };

    designerRef.current.addEventListener("schema-change", handleChange);
    return () => designerRef.current?.removeEventListener("schema-change", handleChange);
  }, [registered]);

  /* ── Actions ─────────────────────────────────────────────────── */
  const handleNew = useCallback(() => {
    const empty = createEmptySchema();
    setSchema(empty);
    setCurrentId(null);
    if (designerRef.current) {
      designerRef.current.schema = empty;
      designerRef.current.data = {};
    }
    setSnack({ open: true, message: "Nuevo schema creado", severity: "info" });
  }, []);

  const handleSave = useCallback(() => {
    const all = loadSchemas();
    const entry: SavedSchema = {
      id: currentId || schema.id,
      title: schema.title || "Sin titulo",
      schema,
      updatedAt: new Date().toISOString(),
    };

    const idx = all.findIndex((s) => s.id === entry.id);
    if (idx >= 0) {
      all[idx] = entry;
    } else {
      all.push(entry);
    }

    saveSchemas(all);
    setCurrentId(entry.id);
    setSnack({ open: true, message: "Schema guardado en localStorage", severity: "success" });
  }, [schema, currentId]);

  const handleOpenLoadDialog = useCallback(() => {
    setSavedList(loadSchemas());
    setLoadDialogOpen(true);
  }, []);

  const handleLoad = useCallback((saved: SavedSchema) => {
    setSchema(saved.schema);
    setCurrentId(saved.id);
    if (designerRef.current) {
      designerRef.current.schema = saved.schema;
      designerRef.current.data = {};
    }
    setLoadDialogOpen(false);
    setSnack({ open: true, message: `Schema "${saved.title}" cargado`, severity: "success" });
  }, []);

  const handleDeleteSaved = useCallback((id: string) => {
    const all = loadSchemas().filter((s) => s.id !== id);
    saveSchemas(all);
    setSavedList(all);
    if (currentId === id) {
      setCurrentId(null);
    }
    setSnack({ open: true, message: "Schema eliminado", severity: "info" });
  }, [currentId]);

  const handleExportJson = useCallback(() => {
    const json = JSON.stringify(schema, null, 2);
    navigator.clipboard.writeText(json).then(() => {
      setSnack({ open: true, message: "JSON copiado al portapapeles", severity: "success" });
    });
  }, [schema]);

  const handleGoWizard = useCallback(() => {
    router.push("/studio-designer/wizard");
  }, [router]);

  /* ── Loading state ───────────────────────────────────────────── */
  if (!registered) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "calc(100vh - 64px)" }}>
        <CircularProgress sx={{ mr: 2 }} />
        <Typography>Cargando Studio Designer...</Typography>
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
            <Link underline="hover" color="inherit" href="/" sx={{ cursor: "pointer" }}>
              Inicio
            </Link>
            <Typography color="text.primary" fontWeight={600}>
              Studio Designer
            </Typography>
          </Breadcrumbs>

          <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
            {schema.title || "Sin titulo"}
          </Typography>

          <Box sx={{ flex: 1 }} />

          <Tooltip title="Nuevo schema vacio">
            <Button size="small" startIcon={<NewIcon />} onClick={handleNew}>
              Nuevo
            </Button>
          </Tooltip>

          <Tooltip title="Guardar en localStorage">
            <Button size="small" startIcon={<SaveIcon />} onClick={handleSave} variant="contained" color="primary">
              Guardar
            </Button>
          </Tooltip>

          <Tooltip title="Cargar schema guardado">
            <Button size="small" startIcon={<LoadIcon />} onClick={handleOpenLoadDialog}>
              Cargar
            </Button>
          </Tooltip>

          <Tooltip title="Copiar JSON al portapapeles">
            <Button size="small" startIcon={<ExportIcon />} onClick={handleExportJson}>
              Exportar JSON
            </Button>
          </Tooltip>

          <Tooltip title="Abrir wizard de aplicaciones">
            <Button size="small" startIcon={<WizardIcon />} onClick={handleGoWizard} color="secondary">
              Wizard
            </Button>
          </Tooltip>
        </Toolbar>
      </AppBar>

      {/* ── Designer ─────────────────────────────────────────── */}
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        <zs-page-designer ref={designerRef} style={{ display: "block", height: "100%" }} />
      </Box>

      {/* ── Load dialog ──────────────────────────────────────── */}
      <Dialog open={loadDialogOpen} onClose={() => setLoadDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Schemas guardados</DialogTitle>
        <DialogContent dividers>
          {savedList.length === 0 ? (
            <Typography color="text.secondary" sx={{ py: 4, textAlign: "center" }}>
              No hay schemas guardados
            </Typography>
          ) : (
            <List disablePadding>
              {savedList.map((s) => (
                <ListItem key={s.id} disablePadding divider>
                  <ListItemButton onClick={() => handleLoad(s)}>
                    <ListItemText
                      primary={s.title}
                      secondary={`Actualizado: ${new Date(s.updatedAt).toLocaleString()}`}
                    />
                  </ListItemButton>
                  <ListItemSecondaryAction>
                    <IconButton edge="end" size="small" onClick={() => handleDeleteSaved(s.id)}>
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </ListItemSecondaryAction>
                </ListItem>
              ))}
            </List>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setLoadDialogOpen(false)}>Cerrar</Button>
        </DialogActions>
      </Dialog>

      {/* ── Snackbar ─────────────────────────────────────────── */}
      <Snackbar
        open={snack.open}
        autoHideDuration={3000}
        onClose={() => setSnack((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        <Alert severity={snack.severity} variant="filled" onClose={() => setSnack((s) => ({ ...s, open: false }))}>
          {snack.message}
        </Alert>
      </Snackbar>

      {/* ── Lit toast / confirm (optional, kept for designer internals) */}
      <zs-toast ref={toastRef} position="top-right" />
    </Box>
  );
}
