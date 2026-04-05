"use client";

import { useParams } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import {
  Alert,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  IconButton,
  Paper,
  Skeleton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/Delete";
import ArrowUpwardIcon from "@mui/icons-material/ArrowUpward";
import ArrowDownwardIcon from "@mui/icons-material/ArrowDownward";
import { pagesApi } from "@/lib/api";

interface SitePage {
  id: string;
  title: string;
  slug: string;
  status?: string;
  sortOrder?: number;
}

export default function PagesManagerPage() {
  const params = useParams<{ siteId: string }>();
  const siteId = params.siteId;

  const [pages, setPages] = useState<SitePage[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newSlug, setNewSlug] = useState("");
  const [creating, setCreating] = useState(false);

  const fetchPages = useCallback(async () => {
    if (!siteId) return;
    try {
      const data = await pagesApi.list(siteId);
      setPages(Array.isArray(data) ? data : []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [siteId]);

  useEffect(() => {
    fetchPages();
  }, [fetchPages]);

  const handleCreate = async () => {
    if (!siteId || !newTitle.trim()) return;
    setCreating(true);
    try {
      await pagesApi.create(siteId, {
        title: newTitle.trim(),
        slug: newSlug.trim() || newTitle.trim().toLowerCase().replace(/\s+/g, "-"),
      });
      setDialogOpen(false);
      setNewTitle("");
      setNewSlug("");
      await fetchPages();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setCreating(false);
    }
  };

  const handleDelete = async (pageId: string) => {
    if (!siteId || !confirm("Eliminar esta pagina?")) return;
    try {
      await pagesApi.delete(siteId, pageId);
      await fetchPages();
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleMove = async (index: number, direction: "up" | "down") => {
    if (!siteId) return;
    const swapIndex = direction === "up" ? index - 1 : index + 1;
    if (swapIndex < 0 || swapIndex >= pages.length) return;

    const reordered = [...pages];
    [reordered[index], reordered[swapIndex]] = [reordered[swapIndex], reordered[index]];
    setPages(reordered);

    try {
      await Promise.all(
        reordered.map((p, i) =>
          pagesApi.update(siteId, p.id, { sortOrder: i }),
        ),
      );
    } catch (err: any) {
      setError(err.message);
      await fetchPages();
    }
  };

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Skeleton variant="rectangular" height={300} />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3, maxWidth: 1000, mx: "auto" }}>
      <Box
        sx={{
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          mb: 3,
        }}
      >
        <Typography variant="h5" fontWeight={700}>
          Paginas
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setDialogOpen(true)}
        >
          Agregar pagina
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Titulo</TableCell>
              <TableCell>Slug</TableCell>
              <TableCell>Estado</TableCell>
              <TableCell align="center">Orden</TableCell>
              <TableCell align="right">Acciones</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {pages.length === 0 ? (
              <TableRow>
                <TableCell colSpan={5} align="center">
                  <Typography variant="body2" color="text.secondary" sx={{ py: 4 }}>
                    No hay paginas. Crea la primera.
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              pages.map((page, index) => (
                <TableRow key={page.id} hover>
                  <TableCell>
                    <Typography fontWeight={500}>{page.title}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" color="text.secondary">
                      /{page.slug}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={page.status || "draft"}
                      size="small"
                      color={page.status === "published" ? "success" : "default"}
                    />
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      disabled={index === 0}
                      onClick={() => handleMove(index, "up")}
                    >
                      <ArrowUpwardIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      disabled={index === pages.length - 1}
                      onClick={() => handleMove(index, "down")}
                    >
                      <ArrowDownwardIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                  <TableCell align="right">
                    <IconButton
                      size="small"
                      href={`/sites/${siteId}/editor?page=${page.id}`}
                      aria-label="Editar secciones"
                    >
                      <EditIcon fontSize="small" />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDelete(page.id)}
                      aria-label="Eliminar"
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Add page dialog */}
      <Dialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Nueva pagina</DialogTitle>
        <DialogContent sx={{ display: "flex", flexDirection: "column", gap: 2, pt: 1 }}>
          <TextField
            label="Titulo"
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
            fullWidth
            autoFocus
            margin="dense"
          />
          <TextField
            label="Slug (URL)"
            value={newSlug}
            onChange={(e) => setNewSlug(e.target.value)}
            placeholder={newTitle.toLowerCase().replace(/\s+/g, "-") || "mi-pagina"}
            fullWidth
            margin="dense"
            helperText="Se genera automaticamente si se deja vacio"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button
            variant="contained"
            onClick={handleCreate}
            disabled={!newTitle.trim() || creating}
          >
            {creating ? "Creando..." : "Crear"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
