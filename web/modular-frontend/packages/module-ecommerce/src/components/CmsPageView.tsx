"use client";

import React from "react";
import { Box, CircularProgress, Container, Typography } from "@mui/material";
import { useCmsPage } from "../hooks/useCmsPage";
import StudioPageRenderer from "./StudioPageRenderer";

export interface CmsPageViewProps {
  slug: string;
  fallbackTitle?: string;
}

/**
 * Carga la página CMS pública por slug y la renderiza con StudioPageRenderer.
 * Diseñado para usarse en las rutas públicas (acerca, contacto, etc.).
 */
export default function CmsPageView({ slug, fallbackTitle }: CmsPageViewProps) {
  const { data, isLoading, error } = useCmsPage(slug);

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", alignItems: "center", justifyContent: "center", minHeight: "60vh" }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error || !data?.page) {
    return (
      <Container maxWidth="md" sx={{ py: 8 }}>
        <Typography variant="h5" color="text.secondary" textAlign="center">
          {fallbackTitle ?? "Contenido no disponible"}
        </Typography>
        <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ mt: 2 }}>
          Esta sección aún no está publicada. Vuelve en unos minutos.
        </Typography>
      </Container>
    );
  }

  return <StudioPageRenderer config={data.page.config} />;
}
