"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import CircularProgress from "@mui/material/CircularProgress";
import Alert from "@mui/material/Alert";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import { sitesApi } from "@/lib/api";

/* eslint-disable @typescript-eslint/no-namespace */
declare module "react" {
  namespace JSX {
    interface IntrinsicElements {
      "zs-landing-wizard": React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, unknown>, HTMLElement>;
    }
  }
}

export default function NewSitePage() {
  const router = useRouter();
  const [wcReady, setWcReady] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const handledRef = useRef(false);

  /* ---------- Load web component ---------- */
  useEffect(() => {
    let cancelled = false;
    import("@zentto/studio/landing-wizard")
      .then(() => {
        if (!cancelled) setWcReady(true);
      })
      .catch((err) => {
        console.error("Error al cargar landing-wizard:", err);
        if (!cancelled) setError("No se pudo cargar el asistente de sitios.");
      });
    return () => {
      cancelled = true;
    };
  }, []);

  /* ---------- Listen for wizard-complete (composed:true crosses Shadow DOM) ---------- */
  const handleWizardComplete = useCallback(
    async (e: Event) => {
      if (handledRef.current) return;
      handledRef.current = true;

      const detail = (e as CustomEvent).detail;
      if (!detail) {
        setError("El asistente no devolvio datos de configuracion.");
        handledRef.current = false;
        return;
      }

      try {
        setSaving(true);
        setError(null);

        const payload = {
          title: detail.title ?? detail.businessName ?? "Nuevo Sitio",
          slug: detail.slug ?? detail.subdomain ?? undefined,
          templateId: detail.templateId ?? detail.template ?? undefined,
          config: detail,
        };

        const created = await sitesApi.create(payload);
        const siteId = created?.id ?? created?.siteId;

        if (siteId) {
          router.push(`/sites/${siteId}`);
        } else {
          router.push("/sites");
        }
      } catch (err: any) {
        setError(err.message ?? "Error al crear el sitio");
        handledRef.current = false;
      } finally {
        setSaving(false);
      }
    },
    [router],
  );

  useEffect(() => {
    document.addEventListener("wizard-complete", handleWizardComplete);
    return () => {
      document.removeEventListener("wizard-complete", handleWizardComplete);
    };
  }, [handleWizardComplete]);

  /* ---------- Render ---------- */
  return (
    <Box sx={{ p: 4, maxWidth: 1200, mx: "auto" }}>
      {/* Header */}
      <Box sx={{ display: "flex", alignItems: "center", gap: 2, mb: 3 }}>
        <Button
          startIcon={<ArrowBackIcon />}
          onClick={() => router.push("/sites")}
          disabled={saving}
        >
          Mis Sitios
        </Button>
        <Typography variant="h5" fontWeight={700}>
          Crear Sitio
        </Typography>
      </Box>

      {/* Error */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Saving overlay */}
      {saving && (
        <Box
          sx={{
            position: "fixed",
            inset: 0,
            bgcolor: "rgba(255,255,255,0.7)",
            zIndex: 1300,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            gap: 2,
          }}
        >
          <CircularProgress size={48} />
          <Typography variant="h6">Creando tu sitio...</Typography>
        </Box>
      )}

      {/* Wizard */}
      {!wcReady ? (
        <Box
          sx={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            minHeight: 400,
          }}
        >
          <CircularProgress />
        </Box>
      ) : (
        <Box
          sx={{
            border: "1px solid",
            borderColor: "divider",
            borderRadius: 2,
            overflow: "hidden",
            minHeight: 500,
          }}
        >
          <zs-landing-wizard />
        </Box>
      )}
    </Box>
  );
}
