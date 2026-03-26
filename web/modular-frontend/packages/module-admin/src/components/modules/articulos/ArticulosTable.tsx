// components/modules/articulos/ArticulosTable.tsx
// Tabla de articulos con filtros avanzados: selectores, rangos, comodines
"use client";

import { useState, useCallback, useMemo, useEffect, useRef, type Dispatch, type SetStateAction } from "react";
import { useRouter, usePathname } from "next/navigation";
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
  Add as AddIcon,
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  ViewColumn as ViewColumnIcon,
} from "@mui/icons-material";
import { useArticulosList, useDeleteArticulo, useArticuloFilterOptions } from "../../../hooks/useArticulos";
import { formatCurrency, apiGet } from "@zentto/shared-api";
import { useQuery } from "@tanstack/react-query";
import { debounce } from "lodash";
import type { ArticuloFilter } from "@zentto/shared-api/types";
import type { ColumnDef } from "@zentto/datagrid-core";


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
      sx={{ minWidth: 130, flex: 1 }}
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
  const pathname = usePathname() || '';
  const basePath = pathname.includes('/inventario/') ? '/inventario/articulos' : '/articulos';
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);

  useEffect(() => {
    import("@zentto/datagrid").then(() => setRegistered(true));
  }, []);

  // ========== Estado del DataGrid ==========
  const [paginationModel, setPaginationModel] = useState({ page: 0, pageSize: 20 });
  const [sortModel, setSortModel] = useState([{ field: "codigo", sort: "asc" as const }]);

  // ========== Busqueda ==========
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
  const [extendedView, setExtendedView] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedArticulo, setSelectedArticulo] = useState<string | null>(null);

  // ========== Debounce para busqueda ==========
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
    descripcion: "ProductName",
    precioVenta: "PRECIO_VENTA",
    precioCompra: "PRECIO_COMPRA",
    stock: "EXISTENCIA",
    estado: "IsActive",
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
    if (debouncedSearch) c++;
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
  }, [debouncedSearch, filterLinea, filterCategoria, filterMarca, filterTipo, filterClase, filterUnidad, filterUbicacion, filterEstado, precioRangeActive, stockMin, stockMax, filterServicio, debouncedWildcard]);

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

  // Resetear pagina al cambiar un filtro
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
  const { data: tasaData } = useQuery({
    queryKey: ["config-tasas"],
    queryFn: () => apiGet("/v1/config/tasas") as Promise<{ USD?: number }>,
    staleTime: 10 * 60 * 1000,
  });
  const tasaCambio = tasaData?.USD || 1;
  const { data: filterOptions } = useArticuloFilterOptions();
  const { mutate: deleteArticulo, isPending: isDeleting } = useDeleteArticulo();

  // ========== Columnas del DataGrid ==========
  const columns = useMemo<ColumnDef[]>(
    () => {
      const base: ColumnDef[] = [
        { field: "codigo", header: "Codigo", width: 120, sortable: true },
        { field: "descripcion", header: "Articulo", flex: 1, minWidth: 200, sortable: true },
        { field: "categoria", header: "Categoria", width: 110, sortable: true },
        { field: "precioCompra", header: "Costo", width: 110, type: "number", currency: "VES", sortable: true },
        { field: "precioVenta", header: "Precio", width: 110, type: "number", currency: "VES", sortable: true },
        { field: "precioUsd", header: "Precio ($)", width: 100, type: "number", currency: "USD" },
        { field: "stock", header: "Stock", width: 80, type: "number", sortable: true, aggregation: "sum" },
        {
          field: "estado", header: "Estado", width: 100, sortable: true,
          statusColors: { Activo: "success", Inactivo: "error" },
          statusVariant: "outlined",
        },
      ];

      const extended: ColumnDef[] = [
        { field: "referencia", header: "Referencia", width: 120, sortable: true },
        { field: "marca", header: "Marca", width: 110, sortable: true },
        { field: "linea", header: "Linea", width: 100, sortable: true },
        { field: "clase", header: "Clase", width: 100, sortable: true },
        { field: "unidad", header: "Unidad", width: 80, sortable: true },
        { field: "tipo", header: "Tipo", width: 100, sortable: true },
        { field: "minimo", header: "Minimo", width: 80, type: "number", sortable: true },
        { field: "maximo", header: "Maximo", width: 80, type: "number", sortable: true },
        { field: "barra", header: "Cod. Barras", width: 120, sortable: true },
        { field: "nParte", header: "N. Parte", width: 110, sortable: true },
        { field: "ubicacion", header: "Ubicacion", width: 100, sortable: true },
      ];

      const actionsCol: ColumnDef = {
        field: "actions", header: "Acciones", type: "actions" as any, width: 130, pin: "right",
        actions: [
          { icon: "view", label: "Ver detalle", action: "view" },
          { icon: "edit", label: "Editar", action: "edit", color: "#e67e22" },
          { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
        ],
      } as ColumnDef;

      return extendedView ? [...base, ...extended, actionsCol] : [...base, actionsCol];
    },
    [extendedView]
  );

  // ========== Filas mapeadas ==========
  const rawRows = articulosData?.data ?? [];
  const totalRows = articulosData?.total ?? 0;

  const rows = useMemo(
    () =>
      rawRows.map((item: any) => ({
        ...item,
        id: item.codigo,
        precioUsd: tasaCambio > 1 && (item.precioVenta ?? 0) > 0
          ? Number(((item.precioVenta ?? 0) / tasaCambio).toFixed(2))
          : 0,
      })),
    [rawRows, tasaCambio]
  );

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

  // ========== Bind data to web component ==========
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = rows;
    el.loading = isLoading;
  }, [columns, rows, isLoading, registered]);

  // ========== Listen for action-click events ==========
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail || {};
      if (!row) return;
      if (action === "view") router.push(`${basePath}/${row.codigo}`);
      if (action === "edit") router.push(`${basePath}/${row.codigo}/edit`);
      if (action === "delete") {
        setSelectedArticulo(row.codigo);
        setDeleteDialogOpen(true);
      }
    };

    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, router, basePath]);

  // ========== RENDER ==========
  return (
    <Box sx={{ width: "100%", flex: 1, display: "flex", flexDirection: "column", minHeight: 0, height: "100%" }}>
      {/* ===== BARRA SUPERIOR: Busqueda + Botones ===== */}
      <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2 }}>
        <TextField
          placeholder="Buscar por codigo, descripcion, marca, referencia..."
          value={searchText}
          onChange={handleSearchChange}
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

        <Tooltip title="Vista compacta / extendida">
          <Button
            variant={extendedView ? "contained" : "outlined"}
            startIcon={<ViewColumnIcon />}
            onClick={() => setExtendedView(!extendedView)}
            size="small"
          >
            {extendedView ? "Compacta" : "Extendida"}
          </Button>
        </Tooltip>

        <Tooltip title="Crear un nuevo articulo en inventario">
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => router.push(`${basePath}/new`)}
            size="small"
          >
            Nuevo Articulo
          </Button>
        </Tooltip>

        <Tooltip title="Registrar entrada o salida de stock">
          <Button
            variant="outlined"
            onClick={() => router.push("/inventario/ajuste")}
            size="small"
          >
            Ajuste de Inventario
          </Button>
        </Tooltip>
      </Stack>

      {/* ===== PANEL DE FILTROS COLAPSABLE ===== */}
      <Collapse in={showFilters}>
        <Paper variant="outlined" sx={{ p: 1.5, mb: 1.5, position: 'relative', zIndex: 10 }}>
          {/* Fila 1: Selectores principales */}
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>
            Filtros basicos
          </Typography>
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap sx={{ mb: 1.5 }}>
            <FilterSelect label="Linea" value={filterLinea} options={filterOptions?.lineas ?? []} onChange={onFilterChange(setFilterLinea)} />
            <FilterSelect label="Categoria" value={filterCategoria} options={filterOptions?.categorias ?? []} onChange={onFilterChange(setFilterCategoria)} />
            <FilterSelect label="Marca" value={filterMarca} options={filterOptions?.marcas ?? []} onChange={onFilterChange(setFilterMarca)} />
            <FilterSelect label="Tipo" value={filterTipo} options={filterOptions?.tipos ?? []} onChange={onFilterChange(setFilterTipo)} />
          </Stack>

          {/* Fila 2: Selectores secundarios */}
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap sx={{ mb: 1.5 }}>
            <FilterSelect label="Clase" value={filterClase} options={filterOptions?.clases ?? []} onChange={onFilterChange(setFilterClase)} />
            <FilterSelect label="Unidad" value={filterUnidad} options={filterOptions?.unidades ?? []} onChange={onFilterChange(setFilterUnidad)} />
            <FilterSelect label="Ubicacion" value={filterUbicacion} options={filterOptions?.ubicaciones ?? []} onChange={onFilterChange(setFilterUbicacion)} />
            <TextField
              select
              label="Estado"
              value={filterEstado}
              onChange={(e) => onFilterChange(setFilterEstado)(e.target.value)}
              size="small"
              sx={{ minWidth: 130, flex: 1 }}
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
            sx={{ mb: 0.5 }}
          >
            Filtros avanzados
          </Button>

          <Collapse in={showAdvanced} unmountOnExit>
            <Stack direction={{ xs: "column", md: "row" }} spacing={2} sx={{ mt: 1 }} alignItems="flex-start">
              {/* Rango de precios */}
              <Box sx={{ flex: 1, minWidth: 200, maxWidth: 350 }}>
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
                      Precio:{" "}
                      {precioRangeActive
                        ? `${formatCurrency(precioRange[0])} — ${formatCurrency(precioRange[1])}`
                        : "Off"}
                    </Typography>
                  }
                />
                {precioRangeActive && (
                  <Slider
                    value={precioRange}
                    onChange={(_, v) => setPrecioRange(v as [number, number])}
                    onChangeCommitted={() => setPaginationModel((p) => ({ ...p, page: 0 }))}
                    min={precioMin}
                    max={precioMax}
                    step={Math.max(1, Math.round((precioMax - precioMin) / 100))}
                    valueLabelDisplay="auto"
                    valueLabelFormat={(v) => formatCurrency(v)}
                    size="small"
                    sx={{ mx: 1 }}
                  />
                )}
              </Box>

              {/* Rango de stock */}
              <Stack direction="row" spacing={1} alignItems="center" sx={{ minWidth: 200 }}>
                <TextField
                  label="Stock min"
                  type="number"
                  size="small"
                  value={stockMin}
                  onChange={(e) => onFilterChange(setStockMin)(e.target.value)}
                  sx={{ width: 100 }}
                />
                <Typography variant="body2" color="text.secondary">—</Typography>
                <TextField
                  label="Stock max"
                  type="number"
                  size="small"
                  value={stockMax}
                  onChange={(e) => onFilterChange(setStockMax)(e.target.value)}
                  sx={{ width: 100 }}
                />
              </Stack>

              {/* Busqueda con comodines */}
              <Box sx={{ flex: 1, minWidth: 200, maxWidth: 300 }}>
                <TextField
                  label="Comodines"
                  placeholder="ACEI*MOTOR, *FILTRO*"
                  value={wildcardText}
                  onChange={handleWildcardChange}
                  size="small"
                  fullWidth
                  helperText="* = cualquier texto, ? = 1 caracter"
                  InputProps={{
                    endAdornment: wildcardText ? (
                      <InputAdornment position="end">
                        <IconButton size="small" onClick={() => { setWildcardText(""); setDebouncedWildcard(""); }}>
                          <ClearIcon fontSize="small" />
                        </IconButton>
                      </InputAdornment>
                    ) : null,
                  }}
                />
              </Box>

              {/* Servicio */}
              <Stack direction="row" spacing={0.5} alignItems="center">
                <Typography variant="body2" sx={{ mr: 0.5 }}>Servicio:</Typography>
                {([undefined, true, false] as const).map((val) => (
                  <Button
                    key={String(val)}
                    variant={filterServicio === val ? "contained" : "outlined"}
                    size="small"
                    onClick={() => onFilterChange(setFilterServicio)(val as any)}
                    sx={{ minWidth: 40, px: 1 }}
                  >
                    {val === undefined ? "Todos" : val ? "Si" : "No"}
                  </Button>
                ))}
              </Stack>
            </Stack>
          </Collapse>
        </Paper>
      </Collapse>

      {/* ===== RESUMEN — solo si hay busqueda o filtros activos ===== */}
      {activeFilterCount > 0 && (
        <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
          <Typography variant="body2" color="text.secondary">
            {totalRows.toLocaleString("es-VE")} articulo{totalRows !== 1 ? "s" : ""} encontrado{totalRows !== 1 ? "s" : ""}
          </Typography>
        </Stack>
      )}

      {/* ===== DATA GRID ===== */}
      <Box sx={{ flex: 1, minHeight: 400 }}>
        {registered && (
          <zentto-grid
            ref={gridRef}
            default-currency="VES"
            export-filename="articulos"
            height="100%"
            show-totals
            enable-toolbar
            enable-header-menu
            enable-header-filters
            enable-clipboard
            enable-quick-search
            enable-context-menu
            enable-status-bar
            enable-configurator
          ></zentto-grid>
        )}
      </Box>

      {/* ===== DIALOG ELIMINAR ===== */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirmar eliminacion</DialogTitle>
        <DialogContent>
          <Typography>
            Esta seguro de que desea eliminar el articulo <strong>{selectedArticulo}</strong>?
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

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
