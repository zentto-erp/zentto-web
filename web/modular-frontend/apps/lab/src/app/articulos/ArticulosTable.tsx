// components/modules/articulos/ArticulosTable.tsx
// Tabla de artículos con filtros avanzados: selectores, rangos, comodines
"use client";

import { useState, useCallback, useMemo, type Dispatch, type SetStateAction } from "react";
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
  GridColDef,
  GridPaginationModel,
  GridSortModel,
  GridRenderCellParams,
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
  ViewColumn as ViewColumnIcon,
} from "@mui/icons-material";
import { useArticulosList, useDeleteArticulo, useArticuloFilterOptions } from "../../hooks/useArticulos";
import { GridSidebar } from "../../components/GridSidebar";
import { buildPivotConfig, buildGroupingConfig, type LabConfig } from "../../components/LabConfigurator";
import { formatCurrency, apiGet } from "@zentto/shared-api";
import { useQuery } from "@tanstack/react-query";
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

  // ========== Estado del DataGrid ==========
  const [paginationModel, setPaginationModel] = useState<GridPaginationModel>({
    page: 0,
    pageSize: 20,
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

  // ========== Lab Configurator ==========
  const [labConfig, setLabConfig] = useState<LabConfig>({
    pivotEnabled: true, pivotRowField: "categoria", pivotColField: "estado",
    pivotValueField: "stock", pivotAgg: "sum", pivotGrandTotals: true, pivotRowTotals: true,
    groupingEnabled: true, groupField: "categoria", groupSubtotals: true, groupSort: "asc",
    headerFilters: true, showTotals: true, clipboard: true, columnGroups: true, pinning: true,
    pinnedLeft: ["codigo"], pinnedRight: ["actions"],
  });
  const ART_FIELDS = [
    { value: "categoria", label: "Categoria" },
    { value: "estado", label: "Estado" },
    { value: "marca", label: "Marca" },
    { value: "linea", label: "Linea" },
    { value: "tipo", label: "Tipo" },
    { value: "unidad", label: "Unidad" },
    { value: "ubicacion", label: "Ubicacion" },
  ];
  const ART_NUMERIC = [
    { value: "stock", label: "Stock" },
    { value: "precioVenta", label: "Precio Venta" },
    { value: "precioCompra", label: "Precio Compra" },
  ];

  // ========== UI ==========
  const [showFilters, setShowFilters] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [extendedView, setExtendedView] = useState(false);
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
  const { data: tasaData } = useQuery({
    queryKey: ["config-tasas"],
    queryFn: () => apiGet("/v1/config/tasas") as Promise<{ USD?: number }>,
    staleTime: 10 * 60 * 1000,
  });
  const tasaCambio = tasaData?.USD || 1;
  const { data: filterOptions } = useArticuloFilterOptions();
  const { mutate: deleteArticulo, isPending: isDeleting } = useDeleteArticulo();

  // ========== Columnas del DataGrid ==========
  const columns: GridColDef[] = useMemo(
    () => {
      // Compacta: Código, Artículo, Categoría, Precio Compra, Precio Venta, Stock, Estado
      const base: GridColDef[] = [
        { field: "codigo", headerName: "Código", width: 120, sortable: true },
        { field: "descripcion", headerName: "Artículo", flex: 1, minWidth: 200, sortable: true },
        { field: "categoria", headerName: "Categoría", width: 110, sortable: true },
        {
          field: "precioCompra", headerName: "Costo", width: 110, sortable: true, align: "right", headerAlign: "right",
          renderCell: (params: GridRenderCellParams) => formatCurrency(params.value),
        },
        {
          field: "precioVenta", headerName: "Precio", width: 110, sortable: true, align: "right", headerAlign: "right",
          renderCell: (params: GridRenderCellParams) => formatCurrency(params.value),
        },
        {
          field: "precioUsd", headerName: "Precio ($)", width: 100, sortable: false, align: "right", headerAlign: "right",
          renderCell: (params: GridRenderCellParams) => {
            const venta = params.row.precioVenta ?? 0;
            return tasaCambio > 1 && venta > 0 ? `$ ${(venta / tasaCambio).toFixed(2)}` : "—";
          },
        },
        { field: "stock", headerName: "Stock", width: 80, sortable: true, align: "right", headerAlign: "right",
          renderCell: (params: GridRenderCellParams) => params.value?.toLocaleString("es-VE") ?? "0",
        },
        {
          field: "estado", headerName: "Estado", width: 100, sortable: true,
          renderCell: (params: GridRenderCellParams) => (
            <Box sx={{ display: 'flex', alignItems: 'center', height: '100%' }}>
              <Chip label={params.value === "Activo" ? "Activo" : "Inactivo"} color={params.value === "Activo" ? "success" : "default"} size="small" variant="outlined" sx={{ height: 22, fontSize: '0.75rem' }} />
            </Box>
          ),
        },
      ];

      // Extendida: sigue orden del formulario — Referencia, Marca, Línea, Clase, Unidad, Tipo, Mínimo, Máximo, Cód. Barras, N° Parte, Ubicación
      const extended: GridColDef[] = [
        { field: "referencia", headerName: "Referencia", width: 120, sortable: true },
        { field: "marca", headerName: "Marca", width: 110, sortable: true },
        {
          field: "linea", headerName: "Línea", width: 100, sortable: true,
          renderCell: (params: GridRenderCellParams) =>
            params.value ? <Chip label={params.value} size="small" variant="outlined" color="info" /> : "—",
        },
        { field: "clase", headerName: "Clase", width: 100, sortable: true },
        { field: "unidad", headerName: "Unidad", width: 80, sortable: true },
        { field: "tipo", headerName: "Tipo", width: 100, sortable: true },
        { field: "minimo", headerName: "Mínimo", width: 80, sortable: true, align: "right", headerAlign: "right" },
        { field: "maximo", headerName: "Máximo", width: 80, sortable: true, align: "right", headerAlign: "right" },
        { field: "barra", headerName: "Cód. Barras", width: 120, sortable: true },
        { field: "nParte", headerName: "N° Parte", width: 110, sortable: true },
        { field: "ubicacion", headerName: "Ubicación", width: 100, sortable: true },
      ];

      const actions: GridColDef = {
        field: "actions", type: "actions", headerName: "Acciones", width: 120, resizable: false,
        getActions: (params) => [
          <Tooltip title="Ver detalle" key="view">
            <IconButton size="small" onClick={() => router.push(`${basePath}/${params.row.codigo}`)}>
              <ViewIcon fontSize="small" />
            </IconButton>
          </Tooltip>,
          <Tooltip title="Editar artículo" key="edit">
            <IconButton size="small" onClick={() => router.push(`${basePath}/${params.row.codigo}/edit`)}>
              <EditIcon fontSize="small" />
            </IconButton>
          </Tooltip>,
          <Tooltip title="Eliminar artículo" key="delete">
            <IconButton size="small" onClick={() => { setSelectedArticulo(params.row.codigo); setDeleteDialogOpen(true); }}>
              <DeleteIcon fontSize="small" color="error" />
            </IconButton>
          </Tooltip>,
        ],
      };

      return extendedView ? [...base, ...extended, actions] : [...base, actions];
    },
    [router, basePath, extendedView, tasaCambio]
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
    <Box sx={{ width: "100%", flex: 1, display: "flex", flexDirection: "column", minHeight: 0, height: "100%" }}>
      {/* ===== BARRA SUPERIOR: Búsqueda + Botones ===== */}
      <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 2 }}>
        <TextField
          placeholder="Buscar por código, descripción, marca, referencia..."
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

        <Tooltip title="Crear un nuevo artículo en inventario">
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => router.push(`${basePath}/new`)}
            size="small"
          >
            Nuevo Artículo
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
                  label="Stock mín"
                  type="number"
                  size="small"
                  value={stockMin}
                  onChange={(e) => onFilterChange(setStockMin)(e.target.value)}
                  sx={{ width: 100 }}
                />
                <Typography variant="body2" color="text.secondary">—</Typography>
                <TextField
                  label="Stock máx"
                  type="number"
                  size="small"
                  value={stockMax}
                  onChange={(e) => onFilterChange(setStockMax)(e.target.value)}
                  sx={{ width: 100 }}
                />
              </Stack>

              {/* Búsqueda con comodines */}
              <Box sx={{ flex: 1, minWidth: 200, maxWidth: 300 }}>
                <TextField
                  label="Comodines"
                  placeholder="ACEI*MOTOR, *FILTRO*"
                  value={wildcardText}
                  onChange={handleWildcardChange}
                  size="small"
                  fullWidth
                  helperText="* = cualquier texto, ? = 1 carácter"
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
                    {val === undefined ? "Todos" : val ? "Sí" : "No"}
                  </Button>
                ))}
              </Stack>
            </Stack>
          </Collapse>
        </Paper>
      </Collapse>

      {/* ===== RESUMEN — solo si hay búsqueda o filtros activos ===== */}
      {activeFilterCount > 0 && (
        <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 1 }}>
          <Typography variant="body2" color="text.secondary">
            {totalRows.toLocaleString("es-VE")} artículo{totalRows !== 1 ? "s" : ""} encontrado{totalRows !== 1 ? "s" : ""}
          </Typography>
        </Stack>
      )}

      {/* ===== Grid + Sidebar estilo AG Grid ===== */}
      <GridSidebar config={labConfig} onChange={setLabConfig} fields={ART_FIELDS} numericFields={ART_NUMERIC}>
      <ZenttoDataGrid
        gridId="lab-articulos"
        rows={rows}
        columns={columns}
        serverRowCount={totalRows}
        loading={isLoading}
        paginationMode="server"
        sortingMode="server"
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        sortModel={sortModel}
        onSortModelChange={setSortModel}
        pageSizeOptions={[10, 20, 50, 100]}
        disableRowSelectionOnClick
        disableVirtualization
        getRowId={(row) => row.codigo}
        mobileVisibleFields={["codigo", "descripcion"]}
        // ─── Funciones controladas por el configurador ──────
        enableClipboard={labConfig.clipboard}
        enableHeaderFilters={labConfig.headerFilters}
        showTotals={labConfig.showTotals}
        totalsLabel="Totales"
        defaultCurrency="VES"
        enableGrouping={labConfig.groupingEnabled}
        rowGroupingConfig={buildGroupingConfig(labConfig)}
        enablePivot={labConfig.pivotEnabled}
        pivotConfig={buildPivotConfig(labConfig, ART_FIELDS)}
        columnGroups={labConfig.columnGroups ? [
          { groupId: "identificacion", headerName: "Identificacion", children: ["codigo", "descripcion", "referencia"] },
          { groupId: "clasificacion", headerName: "Clasificacion", children: ["categoria", "marca", "linea", "clase", "tipo"] },
          { groupId: "precios", headerName: "Precios", children: ["precioCompra", "precioVenta", "precioUsd"] },
          { groupId: "inventario", headerName: "Inventario", children: ["stock", "unidad", "ubicacion", "minimo", "maximo"] },
        ] : undefined}
        pinnedColumns={labConfig.pinning ? { left: ["codigo"], right: ["actions"] } : undefined}
        // Nuevas features
        enableContextMenu
        enableFind
        enableStatusBar
        // Export
        exportFilename="lab-articulos"
        // Toolbar
        hideQuickFilter
        toolbarActions={
          <Tooltip title={extendedView ? "Vista compacta" : "Vista extendida"}>
            <Button
              variant={extendedView ? "contained" : "outlined"}
              startIcon={<ViewColumnIcon />}
              onClick={() => setExtendedView(!extendedView)}
              size="small"
            >
              {extendedView ? "Compacta" : "Extendida"}
            </Button>
          </Tooltip>
        }
        sx={{
          flex: 1,
          minHeight: 400,
          '&.MuiDataGrid-root--densityCompact .MuiDataGrid-cell, &.MuiDataGrid-root--densityCompact .MuiDataGrid-columnHeaderTitle': { fontSize: '0.8rem' },
          '&.MuiDataGrid-root--densityStandard .MuiDataGrid-cell, &.MuiDataGrid-root--densityStandard .MuiDataGrid-columnHeaderTitle': { fontSize: '0.875rem' },
          '&.MuiDataGrid-root--densityComfortable .MuiDataGrid-cell, &.MuiDataGrid-root--densityComfortable .MuiDataGrid-columnHeaderTitle': { fontSize: '0.95rem' },
          "& .MuiDataGrid-row:hover": { backgroundColor: "action.hover" },
        }}
        localeText={{
          noRowsLabel: "No se encontraron artículos",
          toolbarDensity: "Tamaño",
          toolbarDensityLabel: "Tamaño de fila",
          toolbarDensityCompact: "Compacto",
          toolbarDensityStandard: "Normal",
          toolbarDensityComfortable: "Amplio",
          MuiTablePagination: {
            labelRowsPerPage: "Filas por página:",
            labelDisplayedRows: ({ from, to, count }) =>
              `${from}–${to} de ${count !== -1 ? count.toLocaleString("es-VE") : `más de ${to}`}`,
          },
        }}
      />
      </GridSidebar>

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
