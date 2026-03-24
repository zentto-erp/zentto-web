import type { GridColDef, DataGridProps, GridRowId, GridRowsProp } from '@mui/x-data-grid';

export type GridRow = Record<string, unknown>;
export type AggregationType = 'sum' | 'avg' | 'count' | 'min' | 'max';

// ─── Column Definition ─────────────────────────────────────────────────────
// NOTE: GridColDef in MUI X v7 is a union type (GridSingleSelectColDef | etc.)
// Using `extends` on a union breaks object-literal checks for `field`, `type`, etc.
// Solution: intersection type `GridColDef & { ... }` preserves all GridColDef variants.

export type ZenttoColDef = GridColDef & {
  /** Ocultar en movil (xs). Columna se muestra solo en md+ */
  mobileHide?: boolean;
  /** Ocultar en tablet (sm). Solo visible en md+ */
  tabletHide?: boolean;
  /** Funcion de agregacion para la fila de totales */
  aggregation?: AggregationType;
  /**
   * Codigo ISO 4217 de moneda para auto-formatear con Intl.NumberFormat.
   * Ej: 'VES', 'USD', 'EUR'. Requiere que la columna sea numerica.
   * Si se pasa `true`, usa el `defaultCurrency` del grid.
   */
  currency?: string | true;
  /**
   * Column group ID — agrupa este header bajo un grupo padre.
   * Ej: columnGroupId: 'financial' agrupa bajo "Datos Financieros".
   */
  columnGroupId?: string;
  /**
   * Enable inline header filter for this column.
   */
  headerFilter?: boolean;

  // ─── Column Templates (Rich Rendering) ──────────────────────────────
  // These allow rich cell content without writing custom renderCell.

  /**
   * Render as avatar + text cell.
   * - `avatarField`: field name containing the image URL
   * - `subtitleField`: optional field for subtitle text below the main value
   * - `avatarVariant`: 'circular' | 'rounded' | 'square'. Default: 'circular'
   */
  avatarField?: string;
  subtitleField?: string;
  avatarVariant?: 'circular' | 'rounded' | 'square';

  /**
   * Render as image/thumbnail cell.
   * - `imageField`: field name containing the image URL (defaults to current field)
   * - `imageWidth`: width in px. Default: 40
   * - `imageHeight`: height in px. Default: 40
   */
  imageField?: string;
  imageWidth?: number;
  imageHeight?: number;

  /**
   * Render as status badge/chip.
   * - `statusColors`: map of value -> color
   *   Ej: { 'Active': 'success', 'Pending': 'warning', 'Inactive': 'error' }
   * - `statusVariant`: 'filled' | 'outlined'. Default: 'filled'
   */
  statusColors?: Record<string, 'success' | 'error' | 'warning' | 'info' | 'default' | 'primary' | 'secondary' | string>;
  statusVariant?: 'filled' | 'outlined';

  /**
   * Render as country flag + name.
   * - `flagField`: field name containing the country code (ISO 3166-1 alpha-2)
   *   Uses emoji flags. If omitted, uses the column's own field value.
   */
  flagField?: string;

  /**
   * Render as progress bar.
   * - `progressMax`: max value for the bar. Default: 100
   * - `progressColor`: color of the bar. Default: 'primary'
   */
  progressMax?: number;
  progressColor?: 'primary' | 'secondary' | 'success' | 'error' | 'warning' | 'info';

  /**
   * Render as rating stars.
   * - `ratingMax`: max number of stars. Default: 5
   */
  ratingMax?: number;

  /**
   * Render as link/URL.
   * - `linkField`: field containing the URL. If omitted, uses column value.
   * - `linkTarget`: '_blank' | '_self'. Default: '_blank'
   */
  linkField?: string;
  linkTarget?: '_blank' | '_self';

  /**
   * Allow groupable in toolbar grouping selector.
   * Set to false to exclude from grouping dropdown. Default: true.
   */
  groupable?: boolean;
};

// ─── Pivot Config ───────────────────────────────────────────────────────────

export interface PivotConfig {
  rowField: string;
  columnField: string;
  valueField: string;
  aggregation?: AggregationType;
  valueFormatter?: (value: number) => string;
  rowFieldHeader?: string;
  showGrandTotals?: boolean;
  showRowTotals?: boolean;
}

// ─── Column Group ───────────────────────────────────────────────────────────

export interface ColumnGroup {
  groupId: string;
  headerName: string;
  children: string[];
}

// ─── Row Grouping Config ────────────────────────────────────────────────────

export interface RowGroupingConfig {
  field: string;
  showSubtotals?: boolean;
  sortGroups?: 'asc' | 'desc' | null;
}

// ─── Tree Data Config ───────────────────────────────────────────────────────

export interface TreeDataConfig {
  getTreeDataPath: (row: GridRow) => string[];
  defaultExpandLevel?: number;
}

// ─── Header Filter ──────────────────────────────────────────────────────────

export type HeaderFilterValue = string | number | boolean | null;
export type HeaderFilterOperator = 'contains' | 'equals' | 'startsWith' | 'endsWith' | '>' | '<' | '>=' | '<=';

export interface HeaderFilter {
  field: string;
  value: HeaderFilterValue;
  operator: HeaderFilterOperator;
}

// ─── Cell Selection ─────────────────────────────────────────────────────────

export interface CellRange {
  startRow: number;
  endRow: number;
  startCol: number;
  endCol: number;
}

// ─── ZenttoDataGridProps ────────────────────────────────────────────────────

export interface ZenttoDataGridProps extends Omit<DataGridProps, 'columns'> {
  columns: ZenttoColDef[];

  // ─── Responsive ───────────────────────────────────────────────
  mobileVisibleFields?: string[];
  smExtraFields?: string[];
  mobileDetailDrawer?: boolean;

  // ─── Master-Detail ────────────────────────────────────────────
  getDetailContent?: (row: GridRow) => React.ReactNode;
  detailPanelHeight?: number | 'auto';
  getDetailExportData?: (row: GridRow) => Record<string, unknown>[];
  detailExportKey?: string;

  // ─── Pivot ────────────────────────────────────────────────────
  pivotConfig?: PivotConfig;
  enablePivot?: boolean;

  // ─── Aggregation ──────────────────────────────────────────────
  showTotals?: boolean;
  totalsLabel?: string;

  // ─── Column Pinning ───────────────────────────────────────────
  pinnedColumns?: { left?: string[]; right?: string[] };

  // ─── Column Groups ────────────────────────────────────────────
  columnGroups?: ColumnGroup[];

  // ─── Row Grouping ─────────────────────────────────────────────
  enableGrouping?: boolean;
  rowGroupingConfig?: RowGroupingConfig;

  // ─── Tree Data ────────────────────────────────────────────────
  treeDataConfig?: TreeDataConfig;

  // ─── Row Pinning ──────────────────────────────────────────────
  pinnedRowsTop?: GridRowId[];
  pinnedRowsBottom?: GridRowId[];

  // ─── Row Reordering ───────────────────────────────────────────
  onRowReorder?: (params: { oldIndex: number; newIndex: number; row: GridRow }) => void;

  // ─── Header Filters ───────────────────────────────────────────
  enableHeaderFilters?: boolean;

  // ─── Clipboard ────────────────────────────────────────────────
  enableClipboard?: boolean;

  // ─── Cell Selection ───────────────────────────────────────────
  enableCellSelection?: boolean;

  // ─── Lazy Loading / Infinite Scroll ───────────────────────────
  onLoadMore?: () => void;
  loadingMore?: boolean;
  serverRowCount?: number;

  // ─── Export ───────────────────────────────────────────────────
  exportFilename?: string;
  showExportCsv?: boolean;
  showExportExcel?: boolean;
  showExportJson?: boolean;
  showExportMarkdown?: boolean;

  // ─── Fechas y Monedas ─────────────────────────────────────────
  dateLocale?: string;
  defaultCurrency?: string;

  // ─── Layout Persistente ───────────────────────────────────────
  gridId?: string;

  // ─── Toolbar ──────────────────────────────────────────────────
  toolbarTitle?: string;
  toolbarActions?: React.ReactNode;
  hideToolbar?: boolean;
  hideColumnsButton?: boolean;
  hideDensityButton?: boolean;
  hideQuickFilter?: boolean;
}

// ─── Internal Markers ───────────────────────────────────────────────────────

export const DETAIL_ROW_KEY = '__zentto_detail__';
export const TOTALS_ROW_KEY = '__zentto_totals__';
export const GROUP_ROW_KEY = '__zentto_group__';
export const TREE_NODE_KEY = '__zentto_tree_node__';

export const EXPAND_COL_FIELD = '__zentto_expand__';
export const MOBILE_DETAIL_COL_FIELD = '__zentto_mobile__';
export const GROUP_EXPAND_COL_FIELD = '__zentto_group_expand__';
export const TREE_EXPAND_COL_FIELD = '__zentto_tree_expand__';
export const REORDER_COL_FIELD = '__zentto_reorder__';
