"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box, AppBar, Toolbar, Typography, Button, CircularProgress,
  Dialog, DialogTitle, DialogContent, DialogActions, TextField,
  FormControl, InputLabel, Select, MenuItem, OutlinedInput,
  Checkbox, ListItemText, Chip,
} from "@mui/material";
import { ArrowBack as BackIcon, Save as SaveIcon } from "@mui/icons-material";
import { createAddon } from "@zentto/shared-api";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-app-wizard": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}

const WIZARD_CONFIG_KEY = "zentto-studio-wizard-config";
const MODULES = [
  { value: "global", label: "Global (todas las apps)" },
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

export default function WizardPage() {
  const router = useRouter();
  const wizardRef = useRef<HTMLElement>(null);
  const [ready, setReady] = useState(false);
  const [pending, setPending] = useState<Record<string, unknown> | null>(null);
  const [title, setTitle] = useState("");
  const [desc, setDesc] = useState("");
  const [icon, setIcon] = useState("📦");
  const [mods, setMods] = useState<string[]>(["global"]);

  useEffect(() => { import("@zentto/studio").then(() => setReady(true)); }, []);

  useEffect(() => {
    if (!ready || !wizardRef.current) return;
    const h = (e: Event) => {
      const cfg = (e as CustomEvent).detail.config;
      if (cfg?.branding?.title) setTitle(cfg.branding.title);
      if (cfg?.branding?.subtitle) setDesc(cfg.branding.subtitle);
      setPending(cfg);
    };
    wizardRef.current.addEventListener("wizard-complete", h);
    return () => wizardRef.current?.removeEventListener("wizard-complete", h);
  }, [ready]);

  const handleSave = useCallback(async () => {
    if (!pending || !title.trim()) return;
    try {
      await createAddon({ title: title.trim(), description: desc.trim(), icon, modules: mods, config: pending });
      setPending(null);
      router.push("/addons");
    } catch (err) {
      console.error("Error saving addon:", err);
    }
  }, [pending, title, desc, icon, mods, router]);

  const handleSkip = useCallback(() => {
    if (!pending) return;
    localStorage.setItem(WIZARD_CONFIG_KEY, JSON.stringify(pending));
    setPending(null);
    router.push("/studio-designer/preview");
  }, [pending, router]);

  if (!ready) return <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "80vh" }}><CircularProgress sx={{ mr: 2 }} /><Typography>Cargando Wizard...</Typography></Box>;

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Button size="small" startIcon={<BackIcon />} onClick={() => router.push("/studio-designer")}>Designer</Button>
          <Typography fontWeight={600}>Studio Wizard</Typography>
        </Toolbar>
      </AppBar>
      <Box sx={{ flex: 1, overflow: "auto", bgcolor: "#f5f5f5", p: { xs: 2, md: 5 } }}>
        <Box sx={{ maxWidth: 900, mx: "auto" }}>
          <Typography variant="h5" fontWeight={700} gutterBottom>Zentto Studio Wizard</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 4 }}>Crea una aplicación completa en minutos.</Typography>
          <zs-app-wizard ref={wizardRef} />
        </Box>
      </Box>

      <Dialog open={!!pending} onClose={() => setPending(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Guardar Aplicación</DialogTitle>
        <DialogContent sx={{ display: "flex", flexDirection: "column", gap: 2, pt: "16px !important" }}>
          <TextField label="Nombre" value={title} onChange={(e) => setTitle(e.target.value)} required fullWidth autoFocus />
          <TextField label="Descripción" value={desc} onChange={(e) => setDesc(e.target.value)} multiline rows={2} fullWidth />
          <TextField label="Icono (emoji)" value={icon} onChange={(e) => setIcon(e.target.value)} sx={{ maxWidth: 120 }} inputProps={{ maxLength: 4 }} />
          <FormControl fullWidth>
            <InputLabel>Módulos</InputLabel>
            <Select multiple value={mods} onChange={(e) => setMods(typeof e.target.value === "string" ? e.target.value.split(",") : e.target.value)} input={<OutlinedInput label="Módulos" />}
              renderValue={(sel) => <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}>{sel.map((v) => <Chip key={v} label={MODULES.find((m) => m.value === v)?.label || v} size="small" />)}</Box>}>
              {MODULES.map((m) => <MenuItem key={m.value} value={m.value}><Checkbox checked={mods.includes(m.value)} /><ListItemText primary={m.label} /></MenuItem>)}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleSkip}>Solo preview</Button>
          <Button onClick={handleSave} variant="contained" startIcon={<SaveIcon />} disabled={!title.trim()}>Guardar</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
