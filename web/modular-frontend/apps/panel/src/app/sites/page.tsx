"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import Box from "@mui/material/Box";
import Typography from "@mui/material/Typography";
import Button from "@mui/material/Button";
import Grid from "@mui/material/Grid2";
import Card from "@mui/material/Card";
import CardContent from "@mui/material/CardContent";
import CardActions from "@mui/material/CardActions";
import Chip from "@mui/material/Chip";
import IconButton from "@mui/material/IconButton";
import Tooltip from "@mui/material/Tooltip";
import CircularProgress from "@mui/material/CircularProgress";
import Dialog from "@mui/material/Dialog";
import DialogTitle from "@mui/material/DialogTitle";
import DialogContent from "@mui/material/DialogContent";
import DialogContentText from "@mui/material/DialogContentText";
import DialogActions from "@mui/material/DialogActions";
import Skeleton from "@mui/material/Skeleton";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import OpenInNewIcon from "@mui/icons-material/OpenInNew";
import PublishIcon from "@mui/icons-material/Publish";
import UnpublishedIcon from "@mui/icons-material/Unpublished";
import LanguageIcon from "@mui/icons-material/Language";
import { sitesApi } from "@/lib/api";

interface Site {
  id: string;
  title: string;
  slug: string;
  status: "draft" | "published";
  updatedAt: string;
  createdAt: string;
}

export default function SitesListPage() {
  const router = useRouter();
  const [sites, setSites] = useState<Site[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<Site | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [publishingId, setPublishingId] = useState<string | null>(null);

  const fetchSites = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await sitesApi.list();
      setSites(Array.isArray(data) ? data : data.sites ?? []);
    } catch (err: any) {
      setError(err.message ?? "Error al cargar los sitios");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSites();
  }, [fetchSites]);

  const handleDelete = async () => {
    if (!deleteTarget) return;
    try {
      setDeleting(true);
      await sitesApi.delete(deleteTarget.id);
      setSites((prev) => prev.filter((s) => s.id !== deleteTarget.id));
    } catch (err: any) {
      setError(err.message ?? "Error al eliminar el sitio");
    } finally {
      setDeleting(false);
      setDeleteTarget(null);
    }
  };

  const handleTogglePublish = async (site: Site) => {
    try {
      setPublishingId(site.id);
      if (site.status === "published") {
        await sitesApi.unpublish(site.id);
      } else {
        await sitesApi.publish(site.id);
      }
      setSites((prev) =>
        prev.map((s) =>
          s.id === site.id
            ? {
                ...s,
                status: s.status === "published" ? "draft" : "published",
              }
            : s,
        ),
      );
    } catch (err: any) {
      setError(err.message ?? "Error al cambiar el estado del sitio");
    } finally {
      setPublishingId(null);
    }
  };

  const formatDate = (dateStr: string) => {
    try {
      return new Intl.DateTimeFormat("es", {
        day: "2-digit",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      }).format(new Date(dateStr));
    } catch {
      return dateStr;
    }
  };

  /* ---------- Loading skeleton ---------- */
  if (loading) {
    return (
      <Box sx={{ p: 4 }}>
        <Box
          sx={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            mb: 4,
          }}
        >
          <Skeleton variant="text" width={200} height={48} />
          <Skeleton variant="rounded" width={140} height={40} />
        </Box>
        <Grid container spacing={3}>
          {[1, 2, 3].map((i) => (
            <Grid key={i} size={{ xs: 12, sm: 6, md: 4 }}>
              <Skeleton variant="rounded" height={200} />
            </Grid>
          ))}
        </Grid>
      </Box>
    );
  }

  /* ---------- Empty state ---------- */
  if (!loading && sites.length === 0 && !error) {
    return (
      <Box
        sx={{
          p: 4,
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          minHeight: "60vh",
          textAlign: "center",
        }}
      >
        <LanguageIcon sx={{ fontSize: 96, color: "text.disabled", mb: 2 }} />
        <Typography variant="h5" gutterBottom>
          No tienes sitios aun
        </Typography>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
          Crea tu primer sitio web con el asistente de landing pages.
        </Typography>
        <Button
          variant="contained"
          size="large"
          startIcon={<AddIcon />}
          onClick={() => router.push("/sites/new")}
        >
          Crear Sitio
        </Button>
      </Box>
    );
  }

  /* ---------- Sites grid ---------- */
  return (
    <Box sx={{ p: 4 }}>
      {/* Top bar */}
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 4,
        }}
      >
        <Typography variant="h4" fontWeight={700}>
          Mis Sitios
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/sites/new")}
        >
          Crear Sitio
        </Button>
      </Box>

      {/* Error banner */}
      {error && (
        <Typography color="error" sx={{ mb: 2 }}>
          {error}
        </Typography>
      )}

      <Grid container spacing={3}>
        {sites.map((site) => {
          const isPublished = site.status === "published";
          const isPublishing = publishingId === site.id;

          return (
            <Grid key={site.id} size={{ xs: 12, sm: 6, md: 4 }}>
              <Card
                sx={{
                  height: "100%",
                  display: "flex",
                  flexDirection: "column",
                  cursor: "pointer",
                  transition: "box-shadow 0.2s",
                  "&:hover": { boxShadow: 6 },
                }}
                onClick={() => router.push(`/sites/${site.id}`)}
              >
                <CardContent sx={{ flexGrow: 1 }}>
                  <Box
                    sx={{
                      display: "flex",
                      justifyContent: "space-between",
                      alignItems: "flex-start",
                      mb: 1,
                    }}
                  >
                    <Typography variant="h6" noWrap sx={{ maxWidth: "70%" }}>
                      {site.title}
                    </Typography>
                    <Chip
                      label={isPublished ? "Publicado" : "Borrador"}
                      color={isPublished ? "success" : "default"}
                      size="small"
                    />
                  </Box>

                  <Typography
                    variant="body2"
                    color="text.secondary"
                    gutterBottom
                  >
                    {site.slug}.zentto.net
                  </Typography>

                  <Typography variant="caption" color="text.disabled">
                    Actualizado: {formatDate(site.updatedAt)}
                  </Typography>
                </CardContent>

                <CardActions
                  sx={{ justifyContent: "flex-end", px: 2, pb: 1.5 }}
                  onClick={(e) => e.stopPropagation()}
                >
                  <Tooltip title="Editar">
                    <IconButton
                      size="small"
                      onClick={() => router.push(`/sites/${site.id}`)}
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>

                  <Tooltip title={isPublished ? "Despublicar" : "Publicar"}>
                    <span>
                      <IconButton
                        size="small"
                        disabled={isPublishing}
                        onClick={() => handleTogglePublish(site)}
                      >
                        {isPublishing ? (
                          <CircularProgress size={18} />
                        ) : isPublished ? (
                          <UnpublishedIcon fontSize="small" />
                        ) : (
                          <PublishIcon fontSize="small" />
                        )}
                      </IconButton>
                    </span>
                  </Tooltip>

                  <Tooltip title="Abrir sitio">
                    <IconButton
                      size="small"
                      component="a"
                      href={`https://${site.slug}.zentto.net`}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      <OpenInNewIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>

                  <Tooltip title="Eliminar">
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => setDeleteTarget(site)}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </CardActions>
              </Card>
            </Grid>
          );
        })}
      </Grid>

      {/* Delete confirmation dialog */}
      <Dialog
        open={!!deleteTarget}
        onClose={() => !deleting && setDeleteTarget(null)}
      >
        <DialogTitle>Eliminar sitio</DialogTitle>
        <DialogContent>
          <DialogContentText>
            ¿Estas seguro de que deseas eliminar{" "}
            <strong>{deleteTarget?.title}</strong>? Esta accion no se puede
            deshacer.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setDeleteTarget(null)}
            disabled={deleting}
          >
            Cancelar
          </Button>
          <Button
            onClick={handleDelete}
            color="error"
            variant="contained"
            disabled={deleting}
            startIcon={deleting ? <CircularProgress size={16} /> : undefined}
          >
            {deleting ? "Eliminando..." : "Eliminar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
