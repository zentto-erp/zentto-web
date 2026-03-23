import type { GridColDef, DataGridProps, GridRowId, GridRowsProp } from '@mui/x-data-grid';

export type GridRow = Record<string, unknown>;
export type AggregationType = 'sum' | 'avg' | 'count' | 'min' | 'max';

/** Extiende GridColDef con features de ZenttoDataGrid */
export interface ZenttoColDef extends GridColDef {
  /** Ocultar en móvil (xs). Columna se muestra solo en md+ */
  mobileHide?: boolean;
  /** Ocultar en tablet (sm). Solo visible en md+ */
  tabletHide?: boolean;
  /** Función de agregación para la fila de totales */
  aggregation?: AggregationType;
  /**
   * Código ISO 4217 de moneda para auto-formatear con Intl.NumberFormat.
   * Ej: 'VES', 'USD', 'EUR'. Requiere que la columna sea numérica.
   * Si se pasa `true`, usa el `defaultCurrency` del grid.
   */
  currency?: string | true;
}

/** Configuración para modo pivot */
export interface PivotConfig {
  /** Campo que define las filas (eje Y) */
  rowField: string;
  /** Campo cuyos valores únicos se convierten en columnas (eje X) */
  columnField: string;
  /** Campo con los valores de las celdas */
  valueField: string;
  /** Función de agregación cuando hay múltiples valores por celda. Default: sum */
  aggregation?: AggregationType;
  /** Formateador para los valores numéricos del pivot */
  valueFormatter?: (value: number) => string;
  /** Cabecera del primer campo (el rowField) */
  rowFieldHeader?: string;
}

/** Props del ZenttoDataGrid */
export interface ZenttoDataGridProps extends Omit<DataGridProps, 'columns'> {
  columns: ZenttoColDef[];

  // ─── Responsive ───────────────────────────────────────────────
  /** Campos visibles en xs (<600px). Auto-detecta los 2 primeros si no se proveen */
  mobileVisibleFields?: string[];
  /** Campos adicionales visibles en sm (600–900px) además de mobileVisibleFields */
  smExtraFields?: string[];
  /** Mostrar Drawer inferior con detalle completo al tocar una fila en móvil. Default: true */
  mobileDetailDrawer?: boolean;

  // ─── Master-Detail ────────────────────────────────────────────
  /** Función que retorna el contenido expandible de cada fila */
  getDetailContent?: (row: GridRow) => React.ReactNode;
  /** Altura del panel de detalle en px, o 'auto'. Default: 'auto' */
  detailPanelHeight?: number | 'auto';

  // ─── Pivot ────────────────────────────────────────────────────
  /** Configuración para transformar los datos en tabla pivot */
  pivotConfig?: PivotConfig;

  // ─── Aggregation ──────────────────────────────────────────────
  /** Mostrar fila de totales/agregados al final según las columnas con `aggregation` */
  showTotals?: boolean;
  /** Label de la fila de totales. Default: 'Total' */
  totalsLabel?: string;

  // ─── Column Pinning ───────────────────────────────────────────
  /** Columnas fijas (sticky) a izquierda/derecha. Community no tiene nativo — simulado con CSS */
  pinnedColumns?: { left?: string[]; right?: string[] };

  // ─── Export ───────────────────────────────────────────────────
  /** Nombre base del archivo exportado. Default: 'zentto-export' */
  exportFilename?: string;
  /** Mostrar botón Exportar CSV */
  showExportCsv?: boolean;
  /** Mostrar botón Exportar Excel (.xls) */
  showExportExcel?: boolean;
  /** Mostrar botón Exportar JSON (legible por IA/Claude) */
  showExportJson?: boolean;
  /** Mostrar botón Exportar Markdown (tabla renderizable por IA/Claude) */
  showExportMarkdown?: boolean;

  // ─── Fechas y Monedas ─────────────────────────────────────────
  /**
   * Locale BCP-47 para formatear columnas date/dateTime y moneda automáticamente.
   * Ej: 'es-VE', 'es-ES', 'es-CO', 'en-US'.
   * Default: navigator.language del navegador (refleja configuración regional del usuario).
   * Pasar explícitamente cuando se quiere forzar el locale del país de la empresa.
   */
  dateLocale?: string;
  /**
   * Código ISO 4217 de moneda por defecto para columnas con `currency: true`.
   * Ej: 'VES', 'USD', 'EUR', 'COP', 'MXN'.
   */
  defaultCurrency?: string;

  // ─── Layout Persistente ───────────────────────────────────────
  /**
   * Identificador único de la tabla para persistir el layout en IndexedDB.
   * Ej: 'empleados-grid', 'vacaciones-grid', 'centros-costo-grid'.
   * Si se omite, no se persiste nada.
   */
  gridId?: string;

  // ─── Toolbar ──────────────────────────────────────────────────
  /** Título en el toolbar */
  toolbarTitle?: string;
  /** Nodos adicionales en el toolbar (botones custom, etc.) */
  toolbarActions?: React.ReactNode;
  /** Ocultar completamente el toolbar. Default: false */
  hideToolbar?: boolean;
}

// Marcadores internos para filas especiales
export const DETAIL_ROW_KEY = '__zentto_detail__';
export const TOTALS_ROW_KEY = '__zentto_totals__';
export const EXPAND_COL_FIELD = '__zentto_expand__';
export const MOBILE_DETAIL_COL_FIELD = '__zentto_mobile__';
