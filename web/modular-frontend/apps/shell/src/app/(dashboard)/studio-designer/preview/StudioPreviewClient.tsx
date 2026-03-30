"use client";

import React, { useEffect, useState, useRef, useCallback } from "react";
import { useStudioRegistration } from "@/lib/zentto-grid";
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
  Alert,
} from "@mui/material";
import {
  ArrowBack as BackIcon,
  NavigateNext as NavNextIcon,
  Code as ExportIcon,
} from "@mui/icons-material";
import type { AppConfig } from "@zentto/studio-core";

/* ── JSX declarations ──────────────────────────────────────────── */
declare global {
  namespace JSX {
    interface IntrinsicElements {
      "zentto-studio-app": React.DetailedHTMLProps<
        React.HTMLAttributes<HTMLElement> & Record<string, any>,
        HTMLElement
      >;
    }
  }
}

const WIZARD_CONFIG_KEY = "zentto-studio-wizard-config";

export default function StudioPreviewClient() {
  const router = useRouter();
  const appRef = useRef<HTMLElement>(null);
  const { registered } = useStudioRegistration();
  const [config, setConfig] = useState<AppConfig | null>(null);
  const [noConfig, setNoConfig] = useState(false);

  /* ── Load config from localStorage ───────────────────────────── */
  useEffect(() => {
    try {
      const raw = localStorage.getItem(WIZARD_CONFIG_KEY);
      if (raw) {
        setConfig(JSON.parse(raw));
      } else {
        setNoConfig(true);
      }
    } catch {
      setNoConfig(true);
    }
  }, []);

  /* ── Push config into <zentto-studio-app> ────────────────────── */
  useEffect(() => {
    if (!registered || !config || !appRef.current) return;
    (appRef.current as any).config = config;
  }, [registered, config]);

  const handleBack = useCallback(() => {
    router.push("/studio-designer");
  }, [router]);

  const handleExport = useCallback(() => {
    if (!config) return;
    navigator.clipboard.writeText(JSON.stringify(config, null, 2));
  }, [config]);

  /* ── No config state ─────────────────────────────────────────── */
  if (noConfig) {
    return (
      <Box sx={{ p: 4 }}>
        <Alert severity="warning" sx={{ mb: 2 }}>
          No se encontro configuracion de aplicacion. Usa el Wizard para crear una primero.
        </Alert>
        <Button startIcon={<BackIcon />} onClick={handleBack}>
          Volver al Designer
        </Button>
      </Box>
    );
  }

  /* ── Loading state ───────────────────────────────────────────── */
  if (!registered || !config) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", height: "calc(100vh - 64px)" }}>
        <CircularProgress sx={{ mr: 2 }} />
        <Typography>Cargando Preview...</Typography>
      </Box>
    );
  }

  /* ── Render ──────────────────────────────────────────────────── */
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
              Preview
            </Typography>
          </Breadcrumbs>

          <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
            {config.branding?.title || "App"}
          </Typography>

          <Box sx={{ flex: 1 }} />

          <Button size="small" startIcon={<ExportIcon />} onClick={handleExport}>
            Copiar JSON
          </Button>
        </Toolbar>
      </AppBar>

      {/* ── App preview ──────────────────────────────────────── */}
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        <zentto-studio-app ref={appRef} style={{ display: "block", height: "100%" }} />
      </Box>
    </Box>
  );
}
