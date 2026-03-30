"use client";

import React, { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  AppBar,
  Toolbar,
  Typography,
  Button,
  Breadcrumbs,
  Link,
  IconButton,
  Alert,
} from "@mui/material";
import {
  ArrowBack as BackIcon,
  NavigateNext as NavNextIcon,
  Print as PrintIcon,
  Code as CodeIcon,
  Edit as EditIcon,
  Add as ZoomInIcon,
  Remove as ZoomOutIcon,
} from "@mui/icons-material";
import { ReportViewer } from "@zentto/shared-reports";
import type { ReportLayout, DataSet } from "@zentto/report-core";
import { renderToFullHtml } from "@zentto/report-core";

const CONFIG_KEY = "zentto-report-studio-config";

interface Props {
  basePath?: string;
}

export default function ReportPreviewClient({ basePath = "/report-studio" }: Props) {
  const router = useRouter();
  const [layout, setLayout] = useState<ReportLayout | null>(null);
  const [data, setData] = useState<DataSet | null>(null);
  const [noConfig, setNoConfig] = useState(false);
  const [zoom, setZoom] = useState(100);

  /* ── Load config from localStorage ───────────────────────────── */
  useEffect(() => {
    try {
      const raw = localStorage.getItem(CONFIG_KEY);
      if (raw) {
        const parsed = JSON.parse(raw);
        setLayout(parsed.layout ?? null);
        setData(parsed.sampleData ?? null);
      } else {
        setNoConfig(true);
      }
    } catch {
      setNoConfig(true);
    }
  }, []);

  /* ── Actions ─────────────────────────────────────────────────── */
  const handleBack = useCallback(() => {
    router.push(`${basePath}/designer`);
  }, [router]);

  const handlePrint = useCallback(() => {
    if (!layout) return;
    const html = renderToFullHtml(layout, data ?? {});
    const win = window.open("", "_blank");
    if (win) {
      win.document.write(html);
      win.document.close();
      win.focus();
      win.print();
    }
  }, [layout, data]);

  const handleCopyJson = useCallback(() => {
    if (!layout) return;
    navigator.clipboard.writeText(JSON.stringify(layout, null, 2));
  }, [layout]);

  const handleEdit = useCallback(() => {
    router.push(`${basePath}/designer`);
  }, [router]);

  /* ── No config state ─────────────────────────────────────────── */
  if (noConfig) {
    return (
      <Box sx={{ p: 4 }}>
        <Alert severity="warning" sx={{ mb: 2 }}>
          No se encontro ningun reporte para previsualizar.
        </Alert>
        <Button startIcon={<BackIcon />} onClick={handleBack}>
          Volver al Designer
        </Button>
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
            Volver
          </Button>

          <Breadcrumbs separator={<NavNextIcon fontSize="small" />} sx={{ ml: 2 }}>
            <Link underline="hover" color="inherit" href={basePath} sx={{ cursor: "pointer" }}>
              Reportes
            </Link>
            <Typography color="text.primary" fontWeight={600}>
              Preview
            </Typography>
          </Breadcrumbs>

          <Typography variant="body2" color="text.secondary" sx={{ ml: 1 }}>
            {layout?.name || "Reporte"}
          </Typography>

          <Box sx={{ flex: 1 }} />

          {/* ── Zoom controls ────────────────────────────────── */}
          <IconButton size="small" onClick={() => setZoom((z) => Math.max(10, z - 10))}>
            <ZoomOutIcon fontSize="small" />
          </IconButton>
          <Typography variant="body2" sx={{ minWidth: 40, textAlign: "center" }}>
            {zoom}%
          </Typography>
          <IconButton size="small" onClick={() => setZoom((z) => Math.min(300, z + 10))}>
            <ZoomInIcon fontSize="small" />
          </IconButton>

          <Button size="small" startIcon={<PrintIcon />} onClick={handlePrint}>
            Imprimir
          </Button>

          <Button size="small" startIcon={<CodeIcon />} onClick={handleCopyJson}>
            Copiar JSON
          </Button>

          <Button size="small" startIcon={<EditIcon />} onClick={handleEdit}>
            Editar en Designer
          </Button>
        </Toolbar>
      </AppBar>

      {/* ── Report viewer ────────────────────────────────────── */}
      <Box sx={{ flex: 1, overflow: "auto" }}>
        <ReportViewer layout={layout} data={data} zoom={zoom} showToolbar />
      </Box>
    </Box>
  );
}
