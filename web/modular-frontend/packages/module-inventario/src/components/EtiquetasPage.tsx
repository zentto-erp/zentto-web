// components/EtiquetasPage.tsx
"use client";

import { useState, useCallback, useRef } from "react";
import {
  Box,
  Button,
  TextField,
  Paper,
  Typography,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Checkbox,
  InputAdornment,
  CircularProgress,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import LocalOfferIcon from "@mui/icons-material/LocalOffer";
import PrintIcon from "@mui/icons-material/Print";
import SearchIcon from "@mui/icons-material/Search";
import DeleteIcon from "@mui/icons-material/Delete";
import AddIcon from "@mui/icons-material/Add";
import { useInventarioList } from "../hooks/useInventario";
import { formatCurrency } from "@zentto/shared-api";
import { debounce } from "lodash";

interface EtiquetaItem {
  codigo: string;
  descripcion: string;
  precio: number;
  barra: string;
  cantidad: number;
}

export default function EtiquetasPage() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<EtiquetaItem[]>([]);
  const [showPreview, setShowPreview] = useState(false);

  const { data: inventario, isLoading } = useInventarioList({ search, limit: 50 });
  const rows = (inventario?.rows ?? []) as Record<string, unknown>[];

  const debouncedSearch = useCallback(
    debounce((value: string) => setSearch(value), 500),
    []
  );

  const addItem = (item: Record<string, unknown>) => {
    const codigo = String(item.CODIGO ?? item.ProductCode ?? "");
    if (selected.some((s) => s.codigo === codigo)) return;
    setSelected([
      ...selected,
      {
        codigo,
        descripcion: String(item.DescripcionCompleta ?? item.DESCRIPCION ?? ""),
        precio: Number(item.PRECIO_VENTA ?? item.SalesPrice ?? 0),
        barra: String(item.Barra ?? item.CODIGO ?? ""),
        cantidad: 1,
      },
    ]);
  };

  const removeItem = (codigo: string) => {
    setSelected(selected.filter((s) => s.codigo !== codigo));
  };

  const updateCantidad = (codigo: string, cantidad: number) => {
    setSelected(selected.map((s) => (s.codigo === codigo ? { ...s, cantidad: Math.max(1, cantidad) } : s)));
  };

  const handlePrint = () => {
    setShowPreview(true);
    setTimeout(() => {
      window.print();
    }, 300);
  };

  return (
    <Box sx={{ p: 2 }}>
      {/* Screen content (hidden when printing) */}
      <Box className="no-print">
        <Typography variant="h5" sx={{ mb: 3, fontWeight: 600, display: "flex", alignItems: "center", gap: 1 }}>
          <LocalOfferIcon /> Generador de Etiquetas
        </Typography>

        <Grid container spacing={3}>
          {/* Left: Search & add items */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle1" fontWeight={600} sx={{ mb: 2 }}>Buscar Articulos</Typography>
              <TextField
                placeholder="Buscar por codigo o nombre..."
                onChange={(e) => debouncedSearch(e.target.value)}
                fullWidth
                size="small"
                sx={{ mb: 2 }}
                InputProps={{ startAdornment: <InputAdornment position="start"><SearchIcon fontSize="small" /></InputAdornment> }}
              />

              {isLoading && <CircularProgress size={24} />}

              {!isLoading && search && rows.length > 0 && (
                <TableContainer sx={{ maxHeight: 300 }}>
                  <Table size="small" stickyHeader>
                    <TableHead>
                      <TableRow>
                        <TableCell sx={{ fontWeight: 600 }}>Codigo</TableCell>
                        <TableCell sx={{ fontWeight: 600 }}>Articulo</TableCell>
                        <TableCell align="right" sx={{ fontWeight: 600 }}>Precio</TableCell>
                        <TableCell />
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {rows.map((item, i) => {
                        const codigo = String(item.CODIGO ?? "");
                        const alreadyAdded = selected.some((s) => s.codigo === codigo);
                        return (
                          <TableRow key={i} hover>
                            <TableCell>{codigo}</TableCell>
                            <TableCell>{String(item.DescripcionCompleta ?? item.DESCRIPCION ?? "")}</TableCell>
                            <TableCell align="right">{formatCurrency(Number(item.PRECIO_VENTA ?? 0))}</TableCell>
                            <TableCell align="center">
                              <IconButton size="small" color="primary" onClick={() => addItem(item)} disabled={alreadyAdded}>
                                <AddIcon fontSize="small" />
                              </IconButton>
                            </TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </Paper>
          </Grid>

          {/* Right: Selected items */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Paper sx={{ p: 2 }}>
              <Box sx={{ display: "flex", justifyContent: "space-between", alignItems: "center", mb: 2 }}>
                <Typography variant="subtitle1" fontWeight={600}>
                  Etiquetas a Imprimir ({selected.reduce((acc, s) => acc + s.cantidad, 0)})
                </Typography>
                <Button
                  variant="contained"
                  startIcon={<PrintIcon />}
                  onClick={handlePrint}
                  disabled={selected.length === 0}
                  size="small"
                >
                  Imprimir
                </Button>
              </Box>

              {selected.length === 0 ? (
                <Typography variant="body2" color="text.secondary" sx={{ py: 3, textAlign: "center" }}>
                  Agregue articulos desde la busqueda para generar etiquetas
                </Typography>
              ) : (
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell sx={{ fontWeight: 600 }}>Articulo</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600 }}>Precio</TableCell>
                      <TableCell align="center" sx={{ fontWeight: 600 }}>Cant.</TableCell>
                      <TableCell />
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {selected.map((s) => (
                      <TableRow key={s.codigo}>
                        <TableCell>
                          <Typography variant="body2" fontWeight={500}>{s.codigo}</Typography>
                          <Typography variant="caption" color="text.secondary">{s.descripcion}</Typography>
                        </TableCell>
                        <TableCell align="right">{formatCurrency(s.precio)}</TableCell>
                        <TableCell align="center">
                          <TextField
                            type="number"
                            value={s.cantidad}
                            onChange={(e) => updateCantidad(s.codigo, parseInt(e.target.value, 10))}
                            size="small"
                            inputProps={{ min: 1, style: { width: 50, textAlign: "center" } }}
                          />
                        </TableCell>
                        <TableCell align="center">
                          <IconButton size="small" color="error" onClick={() => removeItem(s.codigo)}>
                            <DeleteIcon fontSize="small" />
                          </IconButton>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </Paper>
          </Grid>
        </Grid>
      </Box>

      {/* Print layout */}
      <Box
        className="print-only"
        sx={{
          display: "none",
          "@media print": {
            display: "flex",
            flexWrap: "wrap",
            gap: "8px",
            padding: "4mm",
          },
        }}
      >
        {selected.flatMap((item) =>
          Array.from({ length: item.cantidad }, (_, i) => (
            <Box
              key={`${item.codigo}-${i}`}
              sx={{
                "@media print": {
                  width: "60mm",
                  height: "30mm",
                  border: "1px solid #000",
                  borderRadius: "4px",
                  padding: "3mm",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                  pageBreakInside: "avoid",
                  fontSize: "9pt",
                },
              }}
            >
              <Box sx={{ "@media print": { fontWeight: "bold", fontSize: "8pt", lineHeight: 1.2, overflow: "hidden", maxHeight: "10mm" } }}>
                {item.descripcion}
              </Box>
              <Box sx={{ "@media print": { display: "flex", justifyContent: "space-between", alignItems: "flex-end" } }}>
                <Box sx={{ "@media print": { fontSize: "7pt", color: "#666" } }}>
                  {item.codigo}
                  {item.barra && item.barra !== item.codigo && (
                    <Box component="span" sx={{ "@media print": { display: "block" } }}>
                      {item.barra}
                    </Box>
                  )}
                </Box>
                <Box sx={{ "@media print": { fontWeight: "bold", fontSize: "12pt" } }}>
                  {formatCurrency(item.precio)}
                </Box>
              </Box>
            </Box>
          ))
        )}
      </Box>

      {/* Print styles */}
      <style jsx global>{`
        @media print {
          .no-print { display: none !important; }
          .print-only { display: flex !important; }
          @page { margin: 5mm; }
        }
      `}</style>
    </Box>
  );
}
