"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  Breadcrumbs,
  Link,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  OutlinedInput,
  Checkbox,
  ListItemText,
} from "@mui/material";
import {
  ArrowBack as BackIcon,
  NavigateNext as NavNextIcon,
  Save as SaveIcon,
} from "@mui/icons-material";
import { createAddon } from "@zentto/shared-api";
import { useStudioRegistration } from "@/lib/zentto-grid";

/* ── Types ─────────────────────────────────────────────────────── */
declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-app-wizard": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

const WIZARD_CONFIG_KEY = "zentto-studio-wizard-config";

const AVAILABLE_MODULES = [
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
  { value: "pos", label: "Punto de Venta" },
  { value: "restaurante", label: "Restaurante" },
  { value: "ecommerce", label: "E-Commerce" },
];

export default function StudioWizardClient() {
  const router = useRouter();
  const wizardRef = useRef<HTMLElement>(null);
  const { registered } = useStudioRegistration();
  const [pendingConfig, setPendingConfig] = useState<Record<string, unknown> | null>(null);

  // Save dialog fields
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [icon, setIcon] = useState("📦");
  const [modules, setModules] = useState<string[]>(["global"]);

  /* ── Listen wizard-complete ──────────────────────────────────── */
  useEffect(() => {
    if (!registered || !wizardRef.current) return;

    const handleComplete = (e: Event) => {
      const config = (e as CustomEvent).detail.config;
      // Pre-fill title from config branding
      const brand = config?.branding;
      if (brand?.title) setTitle(brand.title);
      if (brand?.subtitle) setDescription(brand.subtitle);
      setPendingConfig(config);
    };

    wizardRef.current.addEventListener("wizard-complete", handleComplete);
    return () => wizardRef.current?.removeEventListener("wizard-complete", handleComplete);
  }, [registered]);

  /* ── Save as addon ──────────────────────────────────────────── */
  const handleSave = useCallback(async () => {
    if (!pendingConfig || !title.trim()) return;
    try {
      await createAddon({
        title: title.trim(),
        description: description.trim(),
        icon,
        modules,
        config: pendingConfig,
      });
      setPendingConfig(null);
      router.push("/addons");
    } catch (err) {
      console.error("Error saving addon:", err);
    }
  }, [pendingConfig, title, description, icon, modules, router]);

  const handleSkipSave = useCallback(() => {
    if (!pendingConfig) return;
    localStorage.setItem(WIZARD_CONFIG_KEY, JSON.stringify(pendingConfig));
    setPendingConfig(null);
    router.push("/studio-designer/preview");
  }, [pendingConfig, router]);

  const handleBack = useCallback(() => {
    router.push("/studio-designer");
  }, [router]);

  /* ── Loading ────────────────────────────────────────────────── */
  if (!registered) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "calc(100vh - 64px)" }}>
        <CircularProgress sx={{ mr: 2 }} />
        <Typography>Cargando Studio Wizard...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)", overflow: "hidden" }}>
      {/* ── Toolbar ──────────────────────────────────────────── */}
      <AppBar position="static" color="default" elevation={1} sx={{ zIndex: 1 }}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Button size="small" startIcon={<BackIcon />} onClick={handleBack}>
            Volver al Designer
          </Button>
          <Breadcrumbs separator={<NavNextIcon fontSize="small" />} sx={{ ml: 2 }}>
            <Link underline="hover" color="inherit" href="/studio-designer" sx={{ cursor: "pointer" }}>
              Studio Designer
            </Link>
            <Typography color="text.primary" fontWeight={600}>
              Wizard
            </Typography>
          </Breadcrumbs>
        </Toolbar>
      </AppBar>

      {/* ── Wizard ───────────────────────────────────────────── */}
      <Box sx={{ flex: 1, overflow: "auto", bgcolor: "#f5f5f5", p: { xs: 2, md: 5 } }}>
        <Box sx={{ maxWidth: 900, mx: "auto" }}>
          <Typography variant="h5" fontWeight={700} gutterBottom>
            Zentto Studio Wizard
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 4 }}>
            Crea una aplicación completa en minutos. Selecciona una plantilla, personaliza y listo.
          </Typography>
          <zs-app-wizard ref={wizardRef} />
        </Box>
      </Box>

      {/* ── Save Dialog ──────────────────────────────────────── */}
      <Dialog open={!!pendingConfig} onClose={() => setPendingConfig(null)} maxWidth="sm" fullWidth>
        <DialogTitle>Guardar Aplicación</DialogTitle>
        <DialogContent sx={{ display: "flex", flexDirection: "column", gap: 2, pt: "16px !important" }}>
          <Typography variant="body2" color="text.secondary">
            Tu aplicación está lista. Configura cómo aparecerá en el menú de addons.
          </Typography>

          <TextField
            label="Nombre de la aplicación"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
            fullWidth
            autoFocus
          />

          <TextField
            label="Descripción"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            multiline
            rows={2}
            fullWidth
          />

          <TextField
            label="Icono (emoji)"
            value={icon}
            onChange={(e) => setIcon(e.target.value)}
            sx={{ maxWidth: 120 }}
            inputProps={{ maxLength: 4 }}
          />

          <FormControl fullWidth>
            <InputLabel>Módulos donde aparece</InputLabel>
            <Select
              multiple
              value={modules}
              onChange={(e) => setModules(typeof e.target.value === "string" ? e.target.value.split(",") : e.target.value)}
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
                  <Checkbox checked={modules.includes(m.value)} />
                  <ListItemText primary={m.label} />
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleSkipSave}>Solo preview</Button>
          <Button onClick={handleSave} variant="contained" startIcon={<SaveIcon />} disabled={!title.trim()}>
            Guardar y publicar
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
