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
} from "@mui/icons-material";

import {
  getLandingTemplate,
  THEME_PRESETS,
  applyThemePresetToConfig,
  getThemePreset,
} from "@zentto/studio-core";
import type { AppConfig } from "@zentto/studio-core";

declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zs-landing-designer": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

/* ------------------------------------------------------------------ */
/*  Constantes                                                         */
/* ------------------------------------------------------------------ */

const STORAGE_KEY = "zentto-landing-designer-config";

interface SnackState {
  open: boolean;
  msg: string;
  sev: "success" | "error" | "info" | "warning";
}

/* ------------------------------------------------------------------ */
/*  Página principal                                                   */
/* ------------------------------------------------------------------ */

export default function LandingDesignerPage() {
  const router = useRouter();
  const designerRef = useRef<any>(null);

  const [ready, setReady] = useState(false);
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [preset, setPreset] = useState("");
  const [snack, setSnack] = useState<SnackState>({ open: false, msg: "", sev: "info" });

  /* ---- helpers --------------------------------------------------- */

  const toast = useCallback((msg: string, sev: SnackState["sev"] = "info") => {
    setSnack({ open: true, msg, sev });
  }, []);

  /* ---- cargar config inicial ------------------------------------- */

  useEffect(() => {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (saved) {
      try {
        setConfig(JSON.parse(saved));
      } catch {
        setConfig(getLandingTemplate("saas-startup"));
      }
    } else {
      setConfig(getLandingTemplate("saas-startup"));
    }
  }, []);

  /* ---- cargar web component ------------------------------------- */

  useEffect(() => {
    import("@zentto/studio/landing-designer").then(() => setReady(true));
  }, []);

  /* ---- pasar config al web component ----------------------------- */

  useEffect(() => {
    if (!ready || !designerRef.current || !config) return;
    designerRef.current.config = config;
  }, [ready, config]);

  /* ---- escuchar eventos ------------------------------------------ */

  useEffect(() => {
    if (!ready || !designerRef.current) return;
    const el = designerRef.current;

    const handleConfigChange = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      setConfig(detail.config);
      console.log("[LandingDesigner] config-change", detail);
    };

    const handleAutoSave = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      localStorage.setItem(STORAGE_KEY, JSON.stringify(detail.config));
      toast("Auto-guardado", "success");
      console.log("[LandingDesigner] auto-save", detail);
    };

    el.addEventListener("config-change", handleConfigChange);
    el.addEventListener("auto-save", handleAutoSave);

    return () => {
      el.removeEventListener("config-change", handleConfigChange);
      el.removeEventListener("auto-save", handleAutoSave);
    };
  }, [ready, toast]);

  /* ---- acciones -------------------------------------------------- */

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

  const handlePresetChange = (presetId: string) => {
    if (!config) return;
    const p = getThemePreset(presetId);
    if (p) {
      const updated = applyThemePresetToConfig(config, p);
      setConfig(updated);
      setPreset(presetId);
      toast(`Tema "${p.name}" aplicado`, "info");
    }
  };

  /* ---- render ---------------------------------------------------- */

  if (!ready || !config) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "80vh" }}>
        <Typography>Cargando Landing Designer...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "calc(100vh - 64px)" }}>
      {/* Toolbar */}
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar variant="dense" sx={{ gap: 1 }}>
          <Button
            size="small"
            startIcon={<BackIcon />}
            onClick={() => router.push("/")}
          >
            Inicio
          </Button>

          <Typography fontWeight={600} sx={{ mr: 2 }}>
            Landing Page Designer
          </Typography>

          {/* Theme preset selector */}
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

          <Button
            size="small"
            startIcon={<SaveIcon />}
            variant="outlined"
            onClick={handleSave}
          >
            Guardar
          </Button>

          <Button
            size="small"
            startIcon={<PreviewIcon />}
            variant="contained"
            onClick={handlePreview}
          >
            Preview
          </Button>
        </Toolbar>
      </AppBar>

      {/* Designer */}
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        <zs-landing-designer
          ref={designerRef}
          style={{ display: "block", width: "100%", height: "100%" }}
        />
      </Box>

      {/* Snackbar */}
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
