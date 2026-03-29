"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box, AppBar, Toolbar, Typography, Button, Snackbar, Alert,
  Dialog, DialogTitle, DialogContent, DialogActions, List,
  ListItemButton, ListItemText, IconButton,
} from "@mui/material";
import {
  Add as AddIcon, Save as SaveIcon, FolderOpen as LoadIcon,
  ContentCopy as CopyIcon, AutoFixHigh as WizardIcon,
  Delete as DeleteIcon,
} from "@mui/icons-material";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-page-designer": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}

const SCHEMAS_KEY = "zentto-studio-schemas";

interface SavedSchema { id: string; title: string; schema: any; savedAt: string; }

function loadSchemas(): SavedSchema[] {
  try { return JSON.parse(localStorage.getItem(SCHEMAS_KEY) || "[]"); } catch { return []; }
}
function saveSchemas(s: SavedSchema[]) { localStorage.setItem(SCHEMAS_KEY, JSON.stringify(s)); }

function blankSchema() {
  return {
    id: `schema-${Date.now()}`, version: "1", title: "Nuevo Formulario",
    layout: { type: "form", columns: 2 },
    sections: [{ id: "s1", title: "Sección 1", fields: [] }],
  };
}

export default function StudioDesignerPage() {
  const router = useRouter();
  const ref = useRef<any>(null);
  const [ready, setReady] = useState(false);
  const [schema, setSchema] = useState<any>(null);
  const [loadOpen, setLoadOpen] = useState(false);
  const [snack, setSnack] = useState({ open: false, msg: "", sev: "success" as "success" | "info" | "error" });

  useEffect(() => { import("@zentto/studio").then(() => setReady(true)); }, []);

  useEffect(() => {
    if (!ready || !ref.current) return;
    const s = blankSchema();
    ref.current.schema = s;
    setSchema(s);
    const handler = (e: Event) => setSchema((e as CustomEvent).detail.schema);
    ref.current.addEventListener("schema-change", handler);
    return () => ref.current?.removeEventListener("schema-change", handler);
  }, [ready]);

  const handleNew = useCallback(() => {
    if (!ref.current) return;
    const s = blankSchema();
    ref.current.schema = s;
    setSchema(s);
  }, []);

  const handleSave = useCallback(() => {
    if (!schema) return;
    const all = loadSchemas();
    const idx = all.findIndex((s) => s.id === schema.id);
    const entry: SavedSchema = { id: schema.id, title: schema.title || "Sin título", schema, savedAt: new Date().toISOString() };
    if (idx >= 0) all[idx] = entry; else all.push(entry);
    saveSchemas(all);
    setSnack({ open: true, msg: "Schema guardado", sev: "success" });
  }, [schema]);

  const handleCopy = useCallback(() => {
    if (!schema) return;
    navigator.clipboard.writeText(JSON.stringify(schema, null, 2));
    setSnack({ open: true, msg: "JSON copiado", sev: "info" });
  }, [schema]);

  const handleLoadSchema = useCallback((s: SavedSchema) => {
    if (!ref.current) return;
    ref.current.schema = s.schema;
    setSchema(s.schema);
    setLoadOpen(false);
  }, []);

  const handleDeleteSchema = useCallback((id: string) => {
    const all = loadSchemas().filter((s) => s.id !== id);
    saveSchemas(all);
    setLoadOpen(false);
    setTimeout(() => setLoadOpen(true), 50);
  }, []);

  if (!ready) {
    return <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "80vh" }}>
      <Typography>Cargando Studio Designer...</Typography>
    </Box>;
  }

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Typography fontWeight={700} sx={{ mr: 2 }}>Studio Designer</Typography>
          <Button size="small" startIcon={<AddIcon />} onClick={handleNew}>Nuevo</Button>
          <Button size="small" startIcon={<SaveIcon />} onClick={handleSave}>Guardar</Button>
          <Button size="small" startIcon={<LoadIcon />} onClick={() => setLoadOpen(true)}>Cargar</Button>
          <Button size="small" startIcon={<CopyIcon />} onClick={handleCopy}>JSON</Button>
          <Box flex={1} />
          <Button size="small" variant="contained" startIcon={<WizardIcon />} onClick={() => router.push("/studio-designer/wizard")}>
            Wizard
          </Button>
          <Button size="small" variant="outlined" onClick={() => router.push("/addons")}>
            Addons
          </Button>
        </Toolbar>
      </AppBar>
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        <zs-page-designer ref={ref} style={{ display: "block", width: "100%", height: "100%" }} />
      </Box>

      <Dialog open={loadOpen} onClose={() => setLoadOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Schemas guardados</DialogTitle>
        <DialogContent>
          {loadSchemas().length === 0 ? (
            <Typography color="text.secondary" sx={{ py: 2 }}>No hay schemas guardados.</Typography>
          ) : (
            <List>
              {loadSchemas().map((s) => (
                <ListItemButton key={s.id} onClick={() => handleLoadSchema(s)}>
                  <ListItemText primary={s.title} secondary={new Date(s.savedAt).toLocaleString()} />
                  <IconButton size="small" onClick={(e) => { e.stopPropagation(); handleDeleteSchema(s.id); }}>
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </ListItemButton>
              ))}
            </List>
          )}
        </DialogContent>
        <DialogActions><Button onClick={() => setLoadOpen(false)}>Cerrar</Button></DialogActions>
      </Dialog>

      <Snackbar open={snack.open} autoHideDuration={2500} onClose={() => setSnack((s) => ({ ...s, open: false }))} anchorOrigin={{ vertical: "bottom", horizontal: "center" }}>
        <Alert severity={snack.sev} variant="filled">{snack.msg}</Alert>
      </Snackbar>
    </Box>
  );
}
