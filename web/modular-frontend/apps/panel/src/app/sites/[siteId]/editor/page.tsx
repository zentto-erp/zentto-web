"use client";

import { useParams, useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  AppBar,
  Box,
  Button,
  CircularProgress,
  IconButton,
  Snackbar,
  Alert,
  Toolbar,
  Typography,
} from "@mui/material";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import SaveIcon from "@mui/icons-material/Save";
import PublishIcon from "@mui/icons-material/Publish";
import PreviewIcon from "@mui/icons-material/Preview";
import { sitesApi } from "@/lib/api";

/* eslint-disable @typescript-eslint/no-namespace */
declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "zs-landing-designer": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, unknown>, HTMLElement>;
    }
  }
}

/* ------------------------------------------------------------------ */
/* Debounce helper                                                     */
/* ------------------------------------------------------------------ */
function useDebouncedCallback<T extends (...args: any[]) => void>(
  fn: T,
  delay: number,
): T {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  return useCallback(
    ((...args: any[]) => {
      if (timer.current) clearTimeout(timer.current);
      timer.current = setTimeout(() => fn(...args), delay);
    }) as unknown as T,
    [fn, delay],
  );
}

export default function EditorPage() {
  const params = useParams<{ siteId: string }>();
  const router = useRouter();
  const siteId = params.siteId;

  const [config, setConfig] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [publishing, setPublishing] = useState(false);
  const [ready, setReady] = useState(false);
  const [toast, setToast] = useState<{ msg: string; severity: "success" | "error" } | null>(null);

  const designerRef = useRef<HTMLElement | null>(null);

  /* --- Load site config ------------------------------------------- */
  useEffect(() => {
    if (!siteId) return;
    sitesApi
      .get(siteId)
      .then((data) => {
        setConfig(data.config ?? data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, [siteId]);

  /* --- Load web component ----------------------------------------- */
  useEffect(() => {
    Promise.all([
      import("@zentto/studio/landing-designer"),
      import("@zentto/studio/landing"),
    ]).then(() => setReady(true));
  }, []);

  /* --- Auto-save on config change --------------------------------- */
  const saveConfig = useCallback(
    async (newConfig: any) => {
      if (!siteId) return;
      setSaving(true);
      try {
        await sitesApi.update(siteId, { config: newConfig });
        setToast({ msg: "Guardado", severity: "success" });
      } catch (err: any) {
        setToast({ msg: err.message || "Error al guardar", severity: "error" });
      } finally {
        setSaving(false);
      }
    },
    [siteId],
  );

  const debouncedSave = useDebouncedCallback(saveConfig, 1500);

  /* --- Listen for config-change events from designer --------------- */
  useEffect(() => {
    const el = designerRef.current;
    if (!el) return;

    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      if (detail) {
        setConfig(detail);
        debouncedSave(detail);
      }
    };

    el.addEventListener("config-change", handler);
    return () => el.removeEventListener("config-change", handler);
  }, [ready, debouncedSave]);

  /* --- Manual save ------------------------------------------------ */
  const handleSave = async () => {
    if (config) await saveConfig(config);
  };

  /* --- Publish ---------------------------------------------------- */
  const handlePublish = async () => {
    if (!siteId) return;
    setPublishing(true);
    try {
      await sitesApi.publish(siteId);
      setToast({ msg: "Sitio publicado", severity: "success" });
    } catch (err: any) {
      setToast({ msg: err.message || "Error al publicar", severity: "error" });
    } finally {
      setPublishing(false);
    }
  };

  /* --- Preview ---------------------------------------------------- */
  const handlePreview = () => {
    window.open(`https://${siteId}.zentto.net`, "_blank");
  };

  /* --- Render ----------------------------------------------------- */
  if (loading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", alignItems: "center", height: "100vh" }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box sx={{ p: 4 }}>
        <Alert severity="error">{error}</Alert>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", flexDirection: "column", height: "100vh" }}>
      {/* Top bar */}
      <AppBar position="static" color="default" elevation={1}>
        <Toolbar sx={{ gap: 1 }}>
          <IconButton
            edge="start"
            onClick={() => router.push(`/sites/${siteId}`)}
            aria-label="Volver"
          >
            <ArrowBackIcon />
          </IconButton>
          <Typography variant="h6" sx={{ flexGrow: 1 }} noWrap>
            Editor
          </Typography>

          {saving && <CircularProgress size={20} sx={{ mr: 1 }} />}

          <Button
            variant="outlined"
            size="small"
            startIcon={<SaveIcon />}
            onClick={handleSave}
            disabled={saving}
          >
            Guardar
          </Button>
          <Button
            variant="contained"
            size="small"
            startIcon={<PublishIcon />}
            onClick={handlePublish}
            disabled={publishing}
          >
            {publishing ? "Publicando..." : "Publicar"}
          </Button>
          <Button
            variant="outlined"
            size="small"
            startIcon={<PreviewIcon />}
            onClick={handlePreview}
          >
            Vista previa
          </Button>
        </Toolbar>
      </AppBar>

      {/* Designer area */}
      <Box sx={{ flex: 1, overflow: "hidden" }}>
        {ready ? (
          <zs-landing-designer
            ref={designerRef}
            config={config ? JSON.stringify(config) : undefined}
            style={{ width: "100%", height: "100%" }}
          />
        ) : (
          <Box
            sx={{
              display: "flex",
              justifyContent: "center",
              alignItems: "center",
              height: "100%",
            }}
          >
            <CircularProgress />
            <Typography sx={{ ml: 2 }}>Cargando designer...</Typography>
          </Box>
        )}
      </Box>

      {/* Toast notifications */}
      <Snackbar
        open={!!toast}
        autoHideDuration={3000}
        onClose={() => setToast(null)}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      >
        {toast ? (
          <Alert severity={toast.severity} onClose={() => setToast(null)} variant="filled">
            {toast.msg}
          </Alert>
        ) : undefined}
      </Snackbar>
    </Box>
  );
}
