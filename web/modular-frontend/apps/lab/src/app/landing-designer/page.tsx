"use client";

import React, { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Alert,
  AppBar,
  Box,
  Button,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Snackbar,
  Toolbar,
  Typography,
} from "@mui/material";
import {
  ArrowBack as BackIcon,
  Save as SaveIcon,
  Visibility as PreviewIcon,
  OpenInNew as LiveIcon,
  AutoAwesome as WizardIcon,
  Rocket as DeployIcon,
} from "@mui/icons-material";

import {
  THEME_PRESETS,
  getThemePreset,
  applyThemePresetToConfig,
} from "@zentto/studio-core";
import type { AppConfig } from "@zentto/studio-core";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-landing-wizard": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
      "zs-landing-designer": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

const STORAGE_KEY = "zentto-landing-designer-config";

type View = "wizard" | "designer";

interface SnackState {
  open: boolean;
  msg: string;
  sev: "success" | "error" | "info" | "warning";
}

export default function LandingDesignerPage() {
  const router = useRouter();
  const wizardRef = useRef<any>(null);
  const designerRef = useRef<any>(null);

  const [ready, setReady] = useState(false);
  const [view, setView] = useState<View>("wizard");
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [preset, setPreset] = useState("");
  const [snack, setSnack] = useState<SnackState>({ open: false, msg: "", sev: "info" });

  const toast = useCallback((msg: string, sev: SnackState["sev"] = "info") => {
    setSnack({ open: true, msg, sev });
  }, []);

  /* ---- detectar si ya hay config guardada → ir directo al designer -- */
  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        if (parsed?.pages?.[0]?.landingSections?.length > 0) {
          setConfig(parsed);
          setView("designer");
        }
      } catch { /* wizard */ }
    }
  }, []);

  /* ---- cargar web components ---------------------------------------- */
  useEffect(() => {
    Promise.all([
      import("@zentto/studio/landing-wizard"),
      import("@zentto/studio/landing-designer"),
      import("@zentto/studio/landing"),
    ]).then(() => setReady(true));
  }, []);

  /* ---- pasar config al componente activo ----------------------------- */
  useEffect(() => {
    if (!ready) return;
    if (view === "wizard" && wizardRef.current && config) {
      wizardRef.current.initialConfig = config;
    }
    if (view === "designer" && designerRef.current && config) {
      designerRef.current.config = config;
    }
  }, [ready, view, config]);

  /* ---- escuchar eventos del wizard ---------------------------------- */
  useEffect(() => {
    if (!ready || !wizardRef.current) return;
    const el = wizardRef.current;

    const handleComplete = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      const cfg = detail.config as AppConfig;
      setConfig(cfg);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(cfg));
      toast("Landing creada — abriendo designer", "success");
      setView("designer");
    };

    const handleOpenDesigner = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      const cfg = detail.config as AppConfig;
      setConfig(cfg);
      localStorage.setItem(STORAGE_KEY, JSON.stringify(cfg));
      setView("designer");
    };

    const handleChange = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      setConfig(detail.config);
    };

    el.addEventListener("wizard-complete", handleComplete);
    el.addEventListener("wizard-open-designer", handleOpenDesigner);
    el.addEventListener("config-change", handleChange);

    return () => {
      el.removeEventListener("wizard-complete", handleComplete);
      el.removeEventListener("wizard-open-designer", handleOpenDesigner);
      el.removeEventListener("config-change", handleChange);
    };
  }, [ready, toast]);

  /* ---- escuchar eventos del designer -------------------------------- */
  useEffect(() => {
    if (!ready || !designerRef.current || view !== "designer") return;
    const el = designerRef.current;

    const handleConfigChange = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      setConfig(detail.config);
    };

    const handleAutoSave = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      localStorage.setItem(STORAGE_KEY, JSON.stringify(detail.config));
      toast("Auto-guardado", "success");
    };

    el.addEventListener("config-change", handleConfigChange);
    el.addEventListener("auto-save", handleAutoSave);

    return () => {
      el.removeEventListener("config-change", handleConfigChange);
      el.removeEventListener("auto-save", handleAutoSave);
    };
  }, [ready, view, toast]);

  /* ---- acciones toolbar --------------------------------------------- */

  const handleSave = () => {
    if (config) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
      toast("Guardado exitosamente", "success");
    }
  };

  const handlePreview = () => {
    if (config) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
      window.open("/landing-designer/preview", "_blank");
    }
  };

  const handleLive = () => {
    if (config) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
      window.open("/landing-designer/live", "_blank");
    }
  };

  const handleNewWizard = () => {
    localStorage.removeItem(STORAGE_KEY);
    setConfig(null);
    setView("wizard");
  };

  const handlePresetChange = (presetId: string) => {
    if (!config) return;
    const p = getThemePreset(presetId);
    if (p) {
      const updated = applyThemePresetToConfig(config, p);
      setConfig(updated);
      setPreset(presetId);
      if (designerRef.current) designerRef.current.config = updated;
      toast(`Tema "${p.name}" aplicado`, "info");
    }
  };

  /* ---- loading ------------------------------------------------------ */

  if (!ready) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "80vh" }}>
        <Typography>Cargando Landing Designer...</Typography>
      </Box>
    );
  }

  /* ---- WIZARD view -------------------------------------------------- */

  if (view === "wizard") {
    return (
      <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
        <Box sx={{ flex: 1, overflow: "auto" }}>
          <zs-landing-wizard
            ref={wizardRef}
            style={{ display: "block", width: "100%", minHeight: "100%" }}
          />
        </Box>
      </Box>
    );
  }

  /* ---- DESIGNER view ------------------------------------------------ */

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Button size="small" startIcon={<BackIcon />} onClick={() => router.push("/")}>
            Inicio
          </Button>

          <Typography fontWeight={600} sx={{ mr: 2 }}>
            Landing Designer
          </Typography>

          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel id="preset-label">Tema</InputLabel>
            <Select
              labelId="preset-label"
              label="Tema"
              value={preset}
              onChange={(e) => handlePresetChange(e.target.value)}
            >
              {Object.entries(THEME_PRESETS).map(([id, p]) => (
                <MenuItem key={id} value={id}>
                  {(p as any).name || id}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <Box flex={1} />

          <Button size="small" startIcon={<WizardIcon />} onClick={handleNewWizard}>
            Nuevo
          </Button>

          <Button size="small" startIcon={<SaveIcon />} variant="outlined" onClick={handleSave}>
            Guardar
          </Button>

          <Button size="small" startIcon={<PreviewIcon />} variant="outlined" onClick={handlePreview}>
            Preview
          </Button>

          <Button size="small" startIcon={<LiveIcon />} variant="contained" color="success" onClick={handleLive}>
            Ver Sitio
          </Button>

          <Button size="small" startIcon={<DeployIcon />} variant="contained" color="secondary"
            onClick={() => { if (config) { localStorage.setItem(STORAGE_KEY, JSON.stringify(config)); router.push("/landing-designer/export"); } }}>
            Exportar
          </Button>
        </Toolbar>
      </AppBar>

      <Box sx={{ flex: 1, overflow: "hidden" }}>
        <zs-landing-designer
          ref={designerRef}
          style={{ display: "block", width: "100%", height: "100%" }}
        />
      </Box>

      <Snackbar
        open={snack.open}
        autoHideDuration={3000}
        onClose={() => setSnack((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: "bottom", horizontal: "left" }}
      >
        <Alert
          onClose={() => setSnack((s) => ({ ...s, open: false }))}
          severity={snack.sev}
          variant="filled"
          sx={{ width: "100%" }}
        >
          {snack.msg}
        </Alert>
      </Snackbar>
    </Box>
  );
}
