import type { GridRowId, GridRowsProp } from '@mui/x-data-grid';
import type {
  GridRow,
  ZenttoColDef,
  PivotConfig,
  AggregationType,
} from './types';
import { DETAIL_ROW_KEY, TOTALS_ROW_KEY } from './types';

// ─── Row ID ───────────────────────────────────────────────────────────────────

export function resolveId(row: GridRow, getRowId?: (r: GridRow) => GridRowId): GridRowId {
  if (getRowId) {
    const id = getRowId(row);
    // Si getRowId retorna undefined/null (ej: fila pivot no tiene el campo del user),
    // fallback a los campos estándar. Esto permite usar pivotConfig con getRowId definido.
    if (id != null && id !== '') return id;
  }
  return String(row.id ?? row.Id ?? row.Codigo ?? row.codigo ?? crypto.randomUUID());
}

// ─── Master-Detail ────────────────────────────────────────────────────────────

export function injectDetailRows(
  rows: GridRowsProp,
  expandedIds: Set<GridRowId>,
  getDetailContent: ((row: GridRow) => React.ReactNode) | undefined,
  getRowIdFn: (row: GridRow) => GridRowId
): GridRowsProp {
  if (!getDetailContent) return rows;

  const result: GridRowsProp = [];
  for (const row of rows) {
    result.push(row);
    const id = getRowIdFn(row as GridRow);
    if (expandedIds.has(id)) {
      result.push({
        [DETAIL_ROW_KEY]: true,
        __parentId: id,
        __content: getDetailContent(row as GridRow),
        id: `__detail__${String(id)}`,
      } as GridRow);
    }
  }
  return result;
}

// ─── Aggregation / Totals ─────────────────────────────────────────────────────

function computeAgg(values: number[], type: AggregationType): number {
  if (!values.length) return 0;
  switch (type) {
    case 'sum': return values.reduce((a, b) => a + b, 0);
    case 'avg': return values.reduce((a, b) => a + b, 0) / values.length;
    case 'count': return values.length;
    case 'min': return Math.min(...values);
    case 'max': return Math.max(...values);
  }
}

export function computeTotals(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  label = 'Total'
): GridRow {
  const totals: GridRow = {
    id: '__zentto_totals__',
    [TOTALS_ROW_KEY]: true,
  };

  // Primer campo de texto → label de totales
  const firstTextField = columns.find(
    c => !c.field.startsWith('__') && c.type !== 'number' && c.type !== 'actions'
  );
  if (firstTextField) {
    totals[firstTextField.field] = label;
  }

  for (const col of columns) {
    if (!col.aggregation) continue;
    const values = (rows as GridRow[])
      .filter(r => !r[DETAIL_ROW_KEY] && !r[TOTALS_ROW_KEY])
      .map(r => Number(r[col.field] ?? 0))
      .filter(v => !isNaN(v));
    totals[col.field] = computeAgg(values, col.aggregation);
  }

  return totals;
}

// ─── Pivot ────────────────────────────────────────────────────────────────────

export function applyPivot(
  rows: GridRowsProp,
  config: PivotConfig
): { rows: GridRowsProp; columns: ZenttoColDef[] } {
  const {
    rowField,
    columnField,
    valueField,
    aggregation = 'sum',
    valueFormatter,
    rowFieldHeader,
  } = config;

  const dataRows = rows as GridRow[];

  // Valores únicos para columnas (ordenados)
  const uniqueColValues = [...new Set(dataRows.map(r => String(r[columnField])))].sort();

  // Agrupar por rowField
  const groups = new Map<string, GridRow[]>();
  for (const row of dataRows) {
    const key = String(row[rowField]);
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(row);
  }

  // Construir filas pivot
  const pivotRows: GridRow[] = [];
  let idx = 0;
  for (const [rowKey, rowGroup] of groups) {
    const pivotRow: GridRow = { id: `__pivot__${idx++}`, [rowField]: rowKey };
    for (const colVal of uniqueColValues) {
      const matching = rowGroup.filter(r => String(r[columnField]) === colVal);
      const values = matching.map(r => Number(r[valueField] ?? 0));
      pivotRow[colVal] = computeAgg(values, aggregation);
    }
    pivotRows.push(pivotRow);
  }

  // Construir columnas pivot
  const pivotCols: ZenttoColDef[] = [
    {
      field: rowField,
      headerName: rowFieldHeader ?? rowField,
      flex: 1,
      minWidth: 150,
    },
    ...uniqueColValues.map(val => ({
      field: val,
      headerName: val,
      width: 120,
      type: 'number' as const,
      ...(valueFormatter
        ? { valueFormatter: (v: unknown) => valueFormatter(Number(v ?? 0)) }
        : {}),
    })),
  ];

  return { rows: pivotRows, columns: pivotCols };
}

// ─── Export ───────────────────────────────────────────────────────────────────

function downloadBlob(blob: Blob, filename: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

function getExportableColumns(columns: ZenttoColDef[]) {
  return columns.filter(
    c =>
      !c.field.startsWith('__') &&
      c.type !== 'actions' &&
      c.field !== 'actions'
  );
}

function formatCellForExport(row: GridRow, col: ZenttoColDef): string {
  const val = row[col.field];
  if (val == null || val === '') return '';
  if (col.valueFormatter && typeof col.valueFormatter === 'function') {
    try {
      const formatted = col.valueFormatter(val as never, row as never, col, {} as never);
      return formatted != null ? String(formatted) : String(val);
    } catch {
      return String(val);
    }
  }
  return String(val);
}

export function exportToCsv(rows: GridRowsProp, columns: ZenttoColDef[], filename: string) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter(r => !r[DETAIL_ROW_KEY]);

  const headers = exportCols.map(c => c.headerName ?? c.field);
  const csvRows = exportRows.map(row =>
    exportCols.map(col => {
      const str = formatCellForExport(row, col);
      return str.includes(',') || str.includes('"') || str.includes('\n')
        ? `"${str.replace(/"/g, '""')}"`
        : str;
    }).join(',')
  );

  const content = '\uFEFF' + [headers.join(','), ...csvRows].join('\r\n');
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  downloadBlob(blob, `${filename}.csv`);
}

export function exportToExcel(rows: GridRowsProp, columns: ZenttoColDef[], filename: string) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter(r => !r[DETAIL_ROW_KEY]);

  const headerRow = exportCols
    .map(c => `<th style="background:#1976d2;color:#fff;font-weight:bold;">${c.headerName ?? c.field}</th>`)
    .join('');

  const dataRows = exportRows
    .map(row => {
      const isTotals = row[TOTALS_ROW_KEY];
      const cells = exportCols
        .map(col => {
          const str = formatCellForExport(row, col);
          const style = isTotals ? 'font-weight:bold;background:#f5f5f5;' : '';
          return `<td style="${style}">${str}</td>`;
        })
        .join('');
      return `<tr>${cells}</tr>`;
    })
    .join('');

  const html = `
<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel">
<head><meta charset="UTF-8"></head>
<body>
  <table border="1" cellspacing="0" cellpadding="4" style="font-family:Arial,sans-serif;font-size:12px;">
    <thead><tr>${headerRow}</tr></thead>
    <tbody>${dataRows}</tbody>
  </table>
</body>
</html>`;

  const blob = new Blob([html], { type: 'application/vnd.ms-excel;charset=utf-8;' });
  downloadBlob(blob, `${filename}.xls`);
}

export function exportToJson(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  filename: string,
  /** Opcional: provee datos raw del detalle de una fila para exportación anidada */
  getDetailExportData?: (row: GridRow) => Record<string, unknown>[],
  /** Nombre del campo anidado. Default: 'detalles' */
  detailExportKey = 'detalles',
) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter(r => !r[DETAIL_ROW_KEY] && !r[TOTALS_ROW_KEY]);
  const data = exportRows.map(row => {
    const obj: Record<string, unknown> = {};
    exportCols.forEach(col => {
      obj[col.headerName ?? col.field] = row[col.field] ?? null;
    });
    if (getDetailExportData) {
      obj[detailExportKey] = getDetailExportData(row);
    }
    return obj;
  });
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  downloadBlob(blob, `${filename}.json`);
}

export function exportToMarkdown(rows: GridRowsProp, columns: ZenttoColDef[], filename: string) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter(r => !r[DETAIL_ROW_KEY]);
  const headers = exportCols.map(c => c.headerName ?? c.field);
  const separator = exportCols.map(() => '---');
  const dataRows = exportRows.map(row =>
    exportCols.map(col => formatCellForExport(row, col).replace(/\|/g, '\\|'))
  );
  const lines = [
    `| ${headers.join(' | ')} |`,
    `| ${separator.join(' | ')} |`,
    ...dataRows.map(r => `| ${r.join(' | ')} |`),
  ];
  const blob = new Blob([lines.join('\n')], { type: 'text/markdown' });
  downloadBlob(blob, `${filename}.md`);
}

// ─── Column Pinning (CSS simulation) ─────────────────────────────────────────

export function applyColumnPinning(
  columns: ZenttoColDef[],
  pinned?: { left?: string[]; right?: string[] }
): ZenttoColDef[] {
  if (!pinned) return columns;

  return columns.map(col => {
    const isLeft = pinned.left?.includes(col.field);
    const isRight = pinned.right?.includes(col.field);
    if (!isLeft && !isRight) return col;

    const side = isLeft ? 'left' : 'right';
    return {
      ...col,
      cellClassName: `${String(col.cellClassName ?? '')} zentto-pin-${side}`.trim(),
      headerClassName: `${String(col.headerClassName ?? '')} zentto-pin-${side}`.trim(),
    };
  });
}

/** sx styles para columnas pinadas */
export const pinningSx = {
  '& .zentto-pin-left': {
    position: 'sticky !important',
    left: '0 !important',
    zIndex: '2 !important',
    bgcolor: 'background.paper',
    borderRight: '2px solid',
    borderColor: 'divider',
  },
  '& .zentto-pin-right': {
    position: 'sticky !important',
    right: '0 !important',
    zIndex: '2 !important',
    bgcolor: 'background.paper',
    borderLeft: '2px solid',
    borderColor: 'divider',
  },
} as const;
