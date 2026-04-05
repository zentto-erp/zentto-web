"use client";

import { useParams } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Card,
  CardActions,
  CardMedia,
  Dialog,
  DialogContent,
  DialogTitle,
  IconButton,
  Paper,
  Skeleton,
  Snackbar,
  Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
import DeleteIcon from "@mui/icons-material/Delete";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import { mediaApi } from "@/lib/api";

interface MediaItem {
  id: string;
  url: string;
  filename: string;
  size?: number;
  width?: number;
  height?: number;
  mimeType?: string;
}

function formatBytes(bytes?: number): string {
  if (!bytes) return "--";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function MediaLibraryPage() {
  const params = useParams<{ siteId: string }>();
  const siteId = params.siteId;

  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [preview, setPreview] = useState<MediaItem | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const fetchMedia = useCallback(async () => {
    if (!siteId) return;
    try {
      const data = await mediaApi.list(siteId);
      setItems(Array.isArray(data) ? data : []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [siteId]);

  useEffect(() => {
    fetchMedia();
  }, [fetchMedia]);

  const uploadFiles = async (files: FileList | File[]) => {
    if (!siteId) return;
    setUploading(true);
    try {
      for (const file of Array.from(files)) {
        await mediaApi.upload(siteId, file);
      }
      await fetchMedia();
      setToast("Archivos subidos correctamente");
    } catch (err: any) {
      setError(err.message);
    } finally {
      setUploading(false);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      uploadFiles(e.target.files);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragging(false);
    if (e.dataTransfer.files.length > 0) {
      uploadFiles(e.dataTransfer.files);
    }
  };

  const handleDelete = async (mediaId: string) => {
    if (!siteId || !confirm("Eliminar este archivo?")) return;
    try {
      await mediaApi.delete(siteId, mediaId);
      await fetchMedia();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const copyUrl = (url: string) => {
    navigator.clipboard.writeText(url);
    setToast("URL copiada al portapapeles");
  };

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="rectangular" height={300} />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: "auto" }}>
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={700}>
          Biblioteca de medios
        </Typography>
        <Button
          variant="contained"
          startIcon={<CloudUploadIcon />}
          onClick={() => fileInputRef.current?.click()}
          disabled={uploading}
        >
          {uploading ? "Subiendo..." : "Subir archivos"}
        </Button>
        <input
          ref={fileInputRef}
          type="file"
          multiple
          accept="image/*"
          hidden
          onChange={handleFileSelect}
        />
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Drop zone */}
      <Paper
        sx={{
          p: 4,
          mb: 3,
          border: "2px dashed",
          borderColor: dragging ? "primary.main" : "divider",
          bgcolor: dragging ? "action.hover" : "transparent",
          textAlign: "center",
          cursor: "pointer",
          transition: "all 0.2s",
        }}
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={handleDrop}
        onClick={() => fileInputRef.current?.click()}
      >
        <CloudUploadIcon sx={{ fontSize: 48, color: "text.secondary", mb: 1 }} />
        <Typography variant="body1" color="text.secondary">
          Arrastra archivos aqui o haz clic para seleccionar
        </Typography>
      </Paper>

      {/* Media grid */}
      {items.length === 0 ? (
        <Typography variant="body2" color="text.secondary" textAlign="center" sx={{ py: 4 }}>
          No hay archivos multimedia. Sube el primero.
        </Typography>
      ) : (
        <Grid container spacing={2}>
          {items.map((item) => (
            <Grid size={{ xs: 6, sm: 4, md: 3, lg: 2 }} key={item.id}>
              <Card sx={{ height: "100%", display: "flex", flexDirection: "column" }}>
                <CardMedia
                  component="img"
                  image={item.url}
                  alt={item.filename}
                  sx={{
                    height: 140,
                    objectFit: "cover",
                    cursor: "pointer",
                  }}
                  onClick={() => setPreview(item)}
                />
                <Box sx={{ px: 1, py: 0.5, flex: 1 }}>
                  <Typography variant="caption" noWrap title={item.filename}>
                    {item.filename}
                  </Typography>
                  <Typography variant="caption" display="block" color="text.secondary">
                    {formatBytes(item.size)}
                    {item.width && item.height ? ` | ${item.width}x${item.height}` : ""}
                  </Typography>
                </Box>
                <CardActions sx={{ justifyContent: "flex-end", pt: 0 }}>
                  <IconButton
                    size="small"
                    onClick={() => copyUrl(item.url)}
                    aria-label="Copiar URL"
                  >
                    <ContentCopyIcon fontSize="small" />
                  </IconButton>
                  <IconButton
                    size="small"
                    color="error"
                    onClick={() => handleDelete(item.id)}
                    aria-label="Eliminar"
                  >
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </CardActions>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}

      {/* Preview dialog */}
      <Dialog
        open={!!preview}
        onClose={() => setPreview(null)}
        maxWidth="md"
        fullWidth
      >
        {preview && (
          <>
            <DialogTitle>{preview.filename}</DialogTitle>
            <DialogContent>
              <Box
                component="img"
                src={preview.url}
                alt={preview.filename}
                sx={{ width: "100%", maxHeight: "70vh", objectFit: "contain" }}
              />
              <Typography variant="body2" sx={{ mt: 1 }} color="text.secondary">
                {formatBytes(preview.size)}
                {preview.width && preview.height
                  ? ` | ${preview.width} x ${preview.height} px`
                  : ""}
              </Typography>
              <Button
                size="small"
                startIcon={<ContentCopyIcon />}
                onClick={() => copyUrl(preview.url)}
                sx={{ mt: 1 }}
              >
                Copiar URL
              </Button>
            </DialogContent>
          </>
        )}
      </Dialog>

      {/* Toast */}
      <Snackbar
        open={!!toast}
        autoHideDuration={2500}
        onClose={() => setToast(null)}
        message={toast}
        anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
      />
    </Box>
  );
}
