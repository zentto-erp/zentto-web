"use client";

import React from "react";
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Container,
  IconButton,
  Paper,
  Stack,
  Tooltip,
  Typography,
} from "@mui/material";
import EditOutlined from "@mui/icons-material/EditOutlined";
import PublishOutlined from "@mui/icons-material/PublishOutlined";
import OpenInNewOutlined from "@mui/icons-material/OpenInNewOutlined";
import { useRouter } from "next/navigation";
import {
  useAdminPressReleases,
  usePublishPressRelease,
  type PressReleaseSummary,
} from "../hooks/usePressReleases";

function statusChip(status: string) {
  const map: Record<string, { color: "default" | "success" | "warning"; label: string }> = {
    draft:     { color: "warning", label: "Borrador" },
    published: { color: "success", label: "Publicado" },
    archived:  { color: "default", label: "Archivado" },
  };
  const cfg = map[status] ?? { color: "default" as const, label: status };
  return <Chip size="small" label={cfg.label} color={cfg.color} />;
}

function formatDate(iso: string | null): string {
  if (!iso) return "—";
  try {
    return new Date(iso).toLocaleDateString("es", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  } catch {
    return "—";
  }
}

export default function AdminPressReleasesList() {
  const router = useRouter();
  const { data, isLoading, error } = useAdminPressReleases();
  const publish = usePublishPressRelease();

  if (isLoading) {
    return (
      <Box sx={{ display: "flex", justifyContent: "center", py: 8 }}>
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Container>
        <Typography color="error">No se pudieron cargar los comunicados: {(error as Error).message}</Typography>
      </Container>
    );
  }

  const items: PressReleaseSummary[] = data?.items ?? [];

  return (
    <Box>
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>
          Press Releases
        </Typography>
        <Button
          variant="contained"
          onClick={() => router.push("/admin/prensa/nuevo")}
          sx={{ bgcolor: "#ff9900", color: "#131921", fontWeight: 700, textTransform: "none" }}
        >
          Nuevo comunicado
        </Button>
      </Stack>

      {items.length === 0 ? (
        <Paper sx={{ p: 4, textAlign: "center" }}>
          <Typography variant="body1" color="text.secondary">
            No hay comunicados registrados.
          </Typography>
        </Paper>
      ) : (
        <Stack spacing={2}>
          {items.map((p) => (
            <Paper
              key={p.pressReleaseId}
              elevation={1}
              sx={{
                p: 2.5,
                display: "flex",
                alignItems: "center",
                gap: 2,
                flexWrap: "wrap",
              }}
            >
              <Box sx={{ flex: 1, minWidth: 240 }}>
                <Stack direction="row" alignItems="center" spacing={1.5}>
                  <Typography variant="subtitle1" fontWeight={700} sx={{ color: "#131921" }}>
                    {p.title}
                  </Typography>
                  {statusChip(p.status)}
                </Stack>
                <Typography variant="caption" color="text.secondary" sx={{ fontFamily: "monospace" }}>
                  /prensa/{p.slug}
                </Typography>
                {p.excerpt && (
                  <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    {p.excerpt.slice(0, 180)}
                    {p.excerpt.length > 180 ? "…" : ""}
                  </Typography>
                )}
              </Box>

              <Box sx={{ textAlign: "right", minWidth: 140 }}>
                <Typography variant="caption" color="text.secondary">
                  Publicado
                </Typography>
                <Typography variant="body2">{formatDate(p.publishedAt)}</Typography>
              </Box>

              <Stack direction="row" spacing={0.5}>
                <Tooltip title="Ver">
                  <IconButton
                    size="small"
                    disabled={p.status !== "published"}
                    component="a"
                    href={`/prensa/${p.slug}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    <OpenInNewOutlined fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Editar">
                  <IconButton
                    size="small"
                    onClick={() => router.push(`/admin/prensa/${p.pressReleaseId}`)}
                  >
                    <EditOutlined fontSize="small" />
                  </IconButton>
                </Tooltip>
                <Tooltip title="Publicar">
                  <span>
                    <IconButton
                      size="small"
                      color="primary"
                      disabled={p.status === "published" || publish.isPending}
                      onClick={() => publish.mutate(p.pressReleaseId)}
                    >
                      <PublishOutlined fontSize="small" />
                    </IconButton>
                  </span>
                </Tooltip>
              </Stack>
            </Paper>
          ))}
        </Stack>
      )}
    </Box>
  );
}
