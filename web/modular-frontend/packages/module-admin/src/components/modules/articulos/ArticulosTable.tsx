// components/modules/articulos/ArticulosTable.tsx
// Tabla de artículos con filtros avanzados: selectores, rangos, comodines
"use client";

import { useState, useCallback, useMemo, type Dispatch, type SetStateAction } from "react";
import { useRouter } from "next/navigation";
import {
  Box,
  Button,
  TextField,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Chip,
  InputAdornment,
  Typography,
  MenuItem,
  Stack,
  Collapse,
  Paper,
  Slider,
  FormControlLabel,
  Switch,
  IconButton,
  Tooltip,
  Divider,
  Badge,
} from "@mui/material";
import {
  GridColDef,
  GridPaginationModel,
  GridSortModel,
  GridRenderCellParams,
  GridActionsCellItem,
} from "@mui/x-data-grid";
import { ZenttoDataGrid } from "@zentto/shared-ui";
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Visibility as ViewIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
} from "@mui/icons-material";
import { useArticulosList, useDeleteArticulo, useArticuloFilterOptions } from "../../../hooks/useArticulos";
import { formatCurrency } from "@zentto/shared-api";
import { debounce } from "lodash";
import type { ArticuloFilter } from "@zentto/shared-api/types";

// ============ Componente selector reutilizable ============
function FilterSelect({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: string;
  options: string[];
  onChange: (val: string) => void;
}) {
  return (
    <TextField
      select
      label={label}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      size="small"
      sx={{ minWidth: 140, flex: 1 }}
    >
      <MenuItem value="">
        <em>Todos</em>
      </MenuItem>
      {options.map((o) => (
        <MenuItem key={o} value={o}>
          {o}
        </MenuItem>
      ))}
    </TextField>
  );
}

export default function ArticulosTable() {
  const router = useRouter();

  // ========== Estado del DataGrid ==========
  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    page: 0,
    pageSize: 25,
  });
  const [sortModel, setSortModel] = useState<GridSortModel>([
    { field: "codigo", sort: "asc" },
  ]);

  // ========== Búsqueda ==========
  const [searchText, setSearchText] = useState("");
  const [debouncedSearch, setDebouncedSearch] = useState("");
  const [wildcardText, setWildcardText] = useState("");
  const [debouncedWildcard, setDebouncedWildcard] = useState("");

  // ========== Filtros por selector ==========
  const [filterLinea, setFilterLinea] = useState("");
  const [filterCategoria, setFilterCategoria] = useState("");
  const [filterMarca, setFilterMarca] = useState("");
  const [filterTipo, setFilterTipo] = useState("");
  const [filterClase, setFilterClase] = useState("");
  const [filterUnidad, setFilterUnidad] = useState("");
  const [filterUbicacion, setFilterUbicacion] = useState("");

  // ========== Filtros avanzados ==========
  const [filterEstado, setFilterEstado] = useState<string>("todos");
  const [precioRange, setPrecioRange] = useState<[number, number]>([0, 0]);
  const [precioRangeActive, setPrecioRangeActive] = useState(false);
  const [stockMin, setStockMin] = useState<string>("");
  const [stockMax, setStockMax] = useState<string>("");
  const [filterServicio, setFilterServicio] = useState<boolean | undefined>(undefined);

  // ========== UI ==========
  const [showFilters, setShowFilters] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedArticulo, setSelectedArticulo] = useState<string | null>(null);

  // ========== Debounce para búsqueda ==========
  const debouncedSetSearch = useCallback(
    debounce((value: string) => {
      setDebouncedSearch(value);
      setPaginationModel((prev) => ({ ...prev, page: 0 }));
    }, 400),
    []
  );

  const debouncedSetWildcard = useCallback(
    debounce((value: string) => {
      setDebouncedWildcard(value);
      setPaginationModel((prev) => ({ ...prev, page: 0 }));
    }, 400),
    []
  );

  const handleSearchChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSearchText(e.target.value);
    debouncedSetSearch(e.target.value);
  };

  const handleWildcardChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setWildcardText(e.target.value);
    debouncedSetWildcard(e.target.value);
  };

  // ========== Mapeo de sort del DataGrid al API ==========
  const sortFieldMap: Record<string, string> = {
    codigo: "CODIGO",
    linea: "Linea",
    descripcionCompleta: "DescripcionCompleta",
    precioVenta: "PRECIO_VENTA",
    precioCompra: "PRECIO_COMPRA",
    stock: "EXISTENCIA",
    estado: "Eliminado",
    categoria: "Categoria",
    marca: "Marca",
    tipo: "Tipo",
    unidad: "Unidad",
    ubicacion: "UBICACION",
    barra: "Barra",
    referencia: "Referencia",
  };

  // ========== Contar filtros activos ==========
  const activeFilterCount = useMemo(() => {
    let c = 0;
    if (filterLinea) c++;
    if (filterCategoria) c++;
    if (filterMarca) c++;
    if (filterTipo) c++;
    if (filterClase) c++;
    if (filterUnidad) c++;
    if (filterUbicacion) c++;
    if (filterEstado !== "todos") c++;
    if (precioRangeActive) c++;
    if (stockMin) c++;
    if (stockMax) c++;
    if (filterServicio !== undefined) c++;
    if (debouncedWildcard) c++;
    return c;
  }, [filterLinea, filterCategoria, filterMarca, filterTipo, filterClase, filterUnidad, filterUbicacion, filterEstado, precioRangeActive, stockMin, stockMax, filterServicio, debouncedWildcard]);

  // ========== Limpiar todos los filtros ==========
  const clearAllFilters = () => {
    setFilterLinea("");
    setFilterCategoria("");
    setFilterMarca("");
    setFilterTipo("");
    setFilterClase("");
    setFilterUnidad("");
    setFilterUbicacion("");
    setFilterEstado("todos");
    setPrecioRange([0, 0]);
    setPrecioRangeActive(false);
    setStockMin("");
    setStockMax("");
    setFilterServicio(undefined);
    setWildcardText("");
    setDebouncedWildcard("");
    setSearchText("");
    setDebouncedSearch("");
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  // Resetear página al cambiar un filtro
  const onFilterChange = <T,>(setter: Dispatch<SetStateAction<T>>) => (val: T) => {
    setter(val);
    setPaginationModel((p) => ({ ...p, page: 0 }));
  };

  // ========== Filtro completo para el hook ==========
  const filter: ArticuloFilter = useMemo(() => {
    const sort = sortModel[0];
    return {
      search: debouncedSearch || undefined,
      page: paginationModel.page + 1,
      limit: paginationModel.pageSize,
      sortBy: sort ? (sortFieldMap[sort.field] ?? sort.field) : undefined,
      sortOrder: sort?.sort ?? undefined,
      linea: filterLinea || undefined,
      categoria: filterCategoria || undefined,
      marca: filterMarca || undefined,
      tipo: filterTipo || undefined,
      clase: filterClase || undefined,
      unidad: filterUnidad || undefined,
      ubicacion: filterUbicacion || undefined,
      estado: filterEstado !== "todos" ? filterEstado as "activo" | "inactivo" : undefined,
      precioMin: precioRangeActive && precioRange[0] > 0 ? precioRange[0] : undefined,
      precioMax: precioRangeActive && precioRange[1] > 0 ? precioRange[1] : undefined,
      stockMin: stockMin ? Number(stockMin) : undefined,
      stockMax: stockMax ? Number(stockMax) : undefined,
      servicio: filterServicio,
      wildcard: debouncedWildcard || undefined,
    };
  }, [debouncedSearch, paginationModel, sortModel, filterLinea, filterCategoria, filterMarca, filterTipo, filterClase, filterUnidad, filterUbicacion, filterEstado, precioRange, precioRangeActive, stockMin, stockMax, filterServicio, debouncedWildcard]);

  // ========== Queries ==========
  const { data: articulosData, isLoading, isFetching } = useArticulosList(filter);
  const { data: filterOptions } = useArticuloFilterOptions();
  const { mutate: deleteArticulo, isPending: isDeleting } = useDeleteArticulo();

  // ========== Columnas del DataGrid ==========
  const columns: GridColDef[] = useMemo(
    () => [
      {
        field: "codigo",
        headerName: "Código",
        width: 120,
        sortable: true,
      },
      {
        field: "descripcionCompleta",
        headerName: "Descripción",
        flex: 1,
        minWidth: 250,
        sortable: true,
      },
      {
        field: "linea",
        headerName: "Línea",
        width: 100,
        sortable: true,
        renderCell: (params: GridRenderCellParams) =>
          params.value ? (
            <Chip label={params.value} size="small" variant="outlined" color="info" />
          ) : "—",
      },
      {
        field: "categoria",
        headerName: "Categoría",
        width: 110,
        sortable: true,
      },
      {
        field: "marca",
        headerName: "Marca",
        width: 110,
        sortable: true,
      },
      {
        field: "unidad",
        headerName: "Unidad",
        width: 80,
        sortable: true,
      },
      {
        field: "ubicacion",
        headerName: "Ubicación",
        width: 100,
        sortable: true,
      },
      {
        field: "precioVenta",
        headerName: "Precio",
        width: 110,
        sortable: true,
        align: "right",
        headerAlign: "right",
        renderCell: (params: GridRenderCellParams) =>
          formatCurrency(params.value),
      },
      {
        field: "stock",
        headerName: "Stock",
        width: 80,
        sortable: true,
        align: "right",
        headerAlign: "right",
        renderCell: (params: GridRenderCellParams) =>
          params.value?.toLocaleString("es-VE") ?? "0",
      },
      {
        field: "estado",
        headerName: "Estado",
        width: 90,
        sortable: true,
        renderCell: (params: GridRenderCellParams) => (
          <Chip
            label={params.value === "Activo" ? "Activo" : "Inactivo"}
            color={params.value === "Activo" ? "success" : "default"}
            size="small"
            variant="outlined"
          />
        ),
      },
      {
        field: "actions",
        type: "actions",
        headerName: "Acciones",
        width: 120,
        getActions: (params) => [
          <GridActionsCellItem
            key="view"
            icon={<ViewIcon />}
            label="Ver"
            onClick={() => router.push(`/articulos/${params.row.codigo}`)}
          />,
          <GridActionsCellItem
            key="edit"
            icon={<EditIcon />}
            label="Editar"
            onClick={() => router.push(`/articulos/${params.row.codigo}/edit`)}
          />,
          <GridActionsCellItem
            key="delete"
            icon={<DeleteIcon color="error" />}
            label="Eliminar"
            onClick={() => {
              setSelectedArticulo(params.row.codigo);
              setDeleteDialogOpen(true);
            }}
          />,
        ],
      },
    ],
    [router]
  );

  // ========== Filas mapeadas ==========
  const rows = articulosData?.data ?? [];
  const totalRows = articulosData?.total ?? 0;

  // ========== Eliminar ==========
  const handleDelete = () => {
    if (!selectedArticulo) return;
    deleteArticulo(selectedArticulo, {
      onSuccess: () => {
        setDeleteDialogOpen(false);
        setSelectedArticulo(null);
      },
    });
  };

  // ========== Rango de precios desde opciones ==========
  const precioMin = filterOptions?.precioMin ?? 0;
  const precioMax = filterOptions?.precioMax ?? 1000;

  // ========== RENDER ==========
  return (
    <Box sx={{ width: "100%", flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      {/* ===== BARRA SUPERIOR: Búsqueda + Botones ===== */}
      <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2 }}>
        <TextField
          placeholder="Buscar por código, descripción, marca, referencia..."
          value={searchText}
          onChange={handleSearchChange}
          size="small"
          sx={{ flex: 1, maxWidth: 500 }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
            endAdornment: searchText ? (
              <InputAdornment position="end">
                <Tooltip title="Limpiar busqueda">
                  <IconButton size="small" onClick={() => { setSearchText(""); setDebouncedSearch(""); }}>
                    <ClearIcon fontSize="small" />
                  </IconButton>
                </Tooltip>
              </InputAdornment>
            ) : null,
          }}
        />

        <Tooltip title={showFilters ? "Ocultar filtros" : "Mostrar filtros"}>
          <Badge badgeContent={activeFilterCount} color="primary">
            <Button
              variant={showFilters ? "contained" : "outlined"}
              startIcon={<FilterIcon />}
              onClick={() => setShowFilters(!showFilters)}
              size="small"
            >
              Filtros
            </Button>
          </Badge>
        </Tooltip>

        {activeFilterCount > 0 && (
          <Button
            variant="text"
            color="error"
            startIcon={<ClearIcon />}
            onClick={clearAllFilters}
            size="small"
          >
            Limpiar ({activeFilterCount})
          </Button>
        )}

        <Box sx={{ flex: 1 }} />

        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push("/articulos/new")}
          size="small"
        >
          Nuevo Artículo
        </Button>
      </Stack>

      {/* ===== PANEL DE FILTROS COLAPSABLE ===== */}
      <Collapse in={showFilters}>
        <Paper variant="outlined" sx={{ p: 2, mb: 2 }}>
          {/* Fila 1: Selectores principales */}
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>
            Filtros básicos
          </Typography>
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap sx={{ mb: 1.5 }}>
            <FilterSelect
              label="Línea"
              value={filterLinea}
              options={filterOptions?.lineas ?? []}
              onChange={onFilterChange(setFilterLinea)}
            />
            <FilterSelect
              label="Categoría"
              value={filterCategoria}
              options={filterOptions?.categorias ?? []}
              onChange={onFilterChange(setFilterCategoria)}
            />
            <FilterSelect
              label="Marca"
              value={filterMarca}
              options={filterOptions?.marcas ?? []}
              onChange={onFilterChange(setFilterMarca)}
            />
            <FilterSelect
              label="Tipo"
              value={filterTipo}
              options={filterOptions?.tipos ?? []}
              onChange={onFilterChange(setFilterTipo)}
            />
          </Stack>

          {/* Fila 2: Selectores secundarios */}
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap sx={{ mb: 1.5 }}>
            <FilterSelect
              label="Clase"
              value={filterClase}
              options={filterOptions?.clases ?? []}
              onChange={onFilterChange(setFilterClase)}
            />
            <FilterSelect
              label="Unidad"
              value={filterUnidad}
              options={filterOptions?.unidades ?? []}
              onChange={onFilterChange(setFilterUnidad)}
            />
            <FilterSelect
              label="Ubicación"
              value={filterUbicacion}
              options={filterOptions?.ubicaciones ?? []}
              onChange={onFilterChange(setFilterUbicacion)}
            />
            <TextField
              select
              label="Estado"
              value={filterEstado}
              onChange={(e) => onFilterChange(setFilterEstado)(e.target.value)}
              size="small"
              sx={{ minWidth: 140, flex: 1 }}
            >
              <MenuItem value="todos">Todos</MenuItem>
              <MenuItem value="activo">Activo</MenuItem>
              <MenuItem value="inactivo">Inactivo</MenuItem>
            </TextField>
          </Stack>

          <Divider sx={{ my: 1 }} />

          {/* ===== FILTROS AVANZADOS ===== */}
          <Button
            size="small"
            onClick={() => setShowAdvanced(!showAdvanced)}
            endIcon={showAdvanced ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            sx={{ mb: 1 }}
          >
            Filtros avanzados
          </Button>

          <Collapse in={showAdvanced}>
            <Stack spacing={2} sx={{ mt: 1 }}>
              {/* Rango de precios */}
              <Box>
                <Stack direction="row" alignItems="center" spacing={1} sx={{ mb: 0.5 }}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={precioRangeActive}
                        onChange={(e) => {
                          setPrecioRangeActive(e.target.checked);
                          if (e.target.checked && precioRange[0] === 0 && precioRange[1] === 0) {
                            setPrecioRange([precioMin, precioMax]);
                          }
                          setPaginationModel((p) => ({ ...p, page: 0 }));
                        }}
                        size="small"
                      />
                    }
                    label={
                      <Typography variant="body2">
                        Rango de precio:{" "}
                        {precioRangeActive
                          ? `${formatCurrency(precioRange[0])} — ${formatCurrency(precioRange[1])}`
                          : "Desactivado"}
                      </Typography>
                    }
                  />
                </Stack>
                {precioRangeActive && (
                  <Box sx={{ px: 2 }}>
                    <Slider
                      value={precioRange}
                      onChange={(_, v) => setPrecioRange(v as [number, number])}
                      onChangeCommitted={() => setPaginationModel((p) => ({ ...p, page: 0 }))}
                      min={precioMin}
                      max={precioMax}
                      step={Math.max(1, Math.round((precioMax - precioMin) / 100))}
                      valueLabelDisplay="auto"
                      valueLabelFormat={(v) => formatCurrency(v)}
                      sx={{ maxWidth: 400 }}
                    />
                  </Box>
                )}
              </Box>

              {/* Rango de stock */}
              <Stack direction="row" spacing={1} alignItems="center" sx={{ maxWidth: 400 }}>
                <TextField
                  label="Stock mínimo"
                  type="number"
                  value={stockMin}
                  onChange={(e) => onFilterChange(setStockMin)(e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
                />
                <Typography variant="body2" color="text.secondary">—</Typography>
                <TextField
                  label="Stock máximo"
                  type="number"
                  value={stockMax}
                  onChange={(e) => onFilterChange(setStockMax)(e.target.value)}
                  size="small"
                  sx={{ flex: 1 }}
                />
              </Stack>

              {/* Búsqueda con comodines */}
              <TextField
                label="Búsqueda con comodines"
                placeholder="Ej: ACEI*MOTOR, ???-001, *FILTRO*"
                value={wildcardText}
                onChange={handleWildcardChange}
                size="small"
                sx={{ maxWidth: 400 }}
                helperText="Usa * para cualquier texto, ? para un solo carácter"
                InputProps={{
                  endAdornment: wildcardText ? (
                    <InputAdornment position="end">
                      <Tooltip title="Limpiar busqueda wildcard">
                        <IconButton size="small" onClick={() => { setWildcardText(""); setDebouncedWildcard(""); }}>
                          <ClearIcon fontSize="small" />
                        </IconButton>
                      </Tooltip>
                    </InputAdornment>
                  ) : null,
                }}
              />

              {/* Servicio */}
              <Stack direction="row" spacing={2} alignItems="center">
                <Typography variant="body2">Servicio:</Typography>
                <Button
                  variant={filterServicio === undefined ? "contained" : "outlined"}
                  size="small"
                  onClick={() => onFilterChange(setFilterServicio)(undefined)}
                >
                  Todos
                </Button>
                <Button
                  variant={filterServicio === true ? "contained" : "outlined"}
                  size="small"
                  onClick={() => onFilterChange(setFilterServicio)(true)}
                >
                  Sí
                </Button>
                <Button
                  variant={filterServicio === false ? "contained" : "outlined"}
                  size="small"
                  onClick={() => onFilterChange(setFilterServicio)(false)}
                >
                  No
                </Button>
              </Stack>
            </Stack>
          </Collapse>
        </Paper>
      </Collapse>

      {/* ===== RESUMEN ===== */}
      <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
        <Typography variant="body2" color="text.secondary">
          {totalRows.toLocaleString("es-VE")} artículo{totalRows !== 1 ? "s" : ""} encontrado{totalRows !== 1 ? "s" : ""}
        </Typography>
      </Stack>

      {/* ===== DATA GRID ===== */}
      <ZenttoDataGrid
        rows={rows}
        columns={columns}
        rowCount={totalRows}
        loading={isLoading}
        paginationMode="server"
        sortingMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        sortModel={sortModel}
        onSortModelChange={setSortModel}
        pageSizeOptions={[10, 25, 50, 100]}
        disableRowSelectionOnClick
        disableColumnFilter
        getRowId={(row) => row.codigo}
        mobileVisibleFields={["codigo", "descripcionCompleta"]}
        sx={{
          flex: 1,
          minHeight: 0,
          "& .MuiDataGrid-row:hover": {
            backgroundColor: "action.hover",
          },
        }}
        localeText={{
          noRowsLabel: "No se encontraron artículos",
          MuiTablePagination: {
            labelRowsPerPage: "Filas por página:",
            labelDisplayedRows: ({ from, to, count }) =>
              `${from}–${to} de ${count !== -1 ? count.toLocaleString("es-VE") : `más de ${to}`}`,
          },
        }}
      />

      {/* ===== DIALOG ELIMINAR ===== */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirmar eliminación</DialogTitle>
        <DialogContent>
          <Typography>
            ¿Está seguro de que desea eliminar el artículo <strong>{selectedArticulo}</strong>?
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={isDeleting}>
            Cancelar
          </Button>
          <Button
            onClick={handleDelete}
            color="error"
            variant="contained"
            disabled={isDeleting}
          >
            {isDeleting ? "Eliminando..." : "Eliminar"}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
