import type { GridRowId, GridRowsProp } from '@mui/x-data-grid';
import type {
  GridRow,
  ZenttoColDef,
  PivotConfig,
  AggregationType,
  RowGroupingConfig,
  TreeDataConfig,
  HeaderFilter,
  HeaderFilterOperator,
  ColumnGroup,
} from './types';
import {
  DETAIL_ROW_KEY,
  TOTALS_ROW_KEY,
  GROUP_ROW_KEY,
} from './types';

// ─── Row ID ───────────────────────────────────────────────────────────────────

export function resolveId(row: GridRow, getRowId?: (r: GridRow) => GridRowId): GridRowId {
  if (getRowId) {
    const id = getRowId(row);
    if (id != null && id !== '') return id;
  }
  return String(row.id ?? row.Id ?? row.Codigo ?? row.codigo ?? crypto.randomUUID());
}

// ─── Aggregation ──────────────────────────────────────────────────────────────

export function computeAgg(values: number[], type: AggregationType): number {
  if (!values.length) return 0;
  switch (type) {
    case 'sum':
      return values.reduce((a, b) => a + b, 0);
    case 'avg':
      return values.reduce((a, b) => a + b, 0) / values.length;
    case 'count':
      return values.length;
    case 'min':
      return Math.min(...values);
    case 'max':
      return Math.max(...values);
  }
}

// ─── Master-Detail ────────────────────────────────────────────────────────────

export function injectDetailRows(
  rows: GridRowsProp,
  expandedIds: Set<GridRowId>,
  getDetailContent: ((row: GridRow) => React.ReactNode) | undefined,
  getRowIdFn: (row: GridRow) => GridRowId
): GridRowsProp {
  if (!getDetailContent) return rows;

  const result: any[] = [];
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

// ─── Totals ───────────────────────────────────────────────────────────────────

export function computeTotals(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  label = 'Total'
): GridRow {
  const totals: GridRow = {
    id: '__zentto_totals__',
    [TOTALS_ROW_KEY]: true,
  };

  const firstTextField = columns.find(
    (c) => !c.field.startsWith('__') && c.type !== 'number' && c.type !== 'actions'
  );
  if (firstTextField) {
    totals[firstTextField.field] = label;
  }

  for (const col of columns) {
    if (!col.aggregation) continue;
    const values = (rows as GridRow[])
      .filter((r) => !r[DETAIL_ROW_KEY] && !r[TOTALS_ROW_KEY] && !r[GROUP_ROW_KEY])
      .map((r) => Number(r[col.field] ?? 0))
      .filter((v) => !isNaN(v));
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
    showGrandTotals = true,
    showRowTotals = true,
  } = config;

  const dataRows = rows as GridRow[];

  // Unique column values (sorted)
  const uniqueColValues = Array.from(new Set(dataRows.map((r) => String(r[columnField] ?? '')))).sort();

  // Group by rowField
  const groups = new Map<string, GridRow[]>();
  for (const row of dataRows) {
    const key = String(row[rowField] ?? '');
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(row);
  }

  // Build pivot rows
  const pivotRows: GridRow[] = [];
  let idx = 0;
  const groupEntries = Array.from(groups.entries());
  for (let ge = 0; ge < groupEntries.length; ge++) {
    const [rowKey, rowGroup] = groupEntries[ge];
    const pivotRow: GridRow = { id: `__pivot__${idx++}`, [rowField]: rowKey };

    let rowTotal = 0;
    for (const colVal of uniqueColValues) {
      const matching = rowGroup.filter((r: GridRow) => String(r[columnField] ?? '') === colVal);
      const values = matching.map((r: GridRow) => Number(r[valueField] ?? 0));
      const aggValue = computeAgg(values, aggregation);
      pivotRow[colVal] = aggValue;
      rowTotal += aggValue;
    }

    // Row total
    if (showRowTotals) {
      pivotRow['__pivot_row_total__'] = rowTotal;
    }

    pivotRows.push(pivotRow);
  }

  // Grand totals row
  if (showGrandTotals && pivotRows.length > 0) {
    const grandTotals: GridRow = {
      id: '__pivot_grand_totals__',
      [TOTALS_ROW_KEY]: true,
      [rowField]: 'TOTAL',
    };
    let grandTotal = 0;
    for (const colVal of uniqueColValues) {
      const values = pivotRows
        .filter((r) => !r[TOTALS_ROW_KEY])
        .map((r) => Number(r[colVal] ?? 0));
      const colTotal = values.reduce((a, b) => a + b, 0);
      grandTotals[colVal] = colTotal;
      grandTotal += colTotal;
    }
    if (showRowTotals) {
      grandTotals['__pivot_row_total__'] = grandTotal;
    }
    pivotRows.push(grandTotals);
  }

  // Build pivot columns
  const fmtOpts = valueFormatter
    ? { valueFormatter: (v: unknown) => valueFormatter(Number(v ?? 0)) }
    : {};

  const pivotCols: ZenttoColDef[] = [
    {
      field: rowField,
      headerName: rowFieldHeader ?? rowField,
      flex: 1,
      minWidth: 150,
    },
    ...uniqueColValues.map((val) => ({
      field: val,
      headerName: val,
      width: 120,
      type: 'number' as const,
      align: 'right' as const,
      headerAlign: 'right' as const,
      ...fmtOpts,
    })),
  ];

  // Row total column
  if (showRowTotals) {
    pivotCols.push({
      field: '__pivot_row_total__',
      headerName: 'Total',
      width: 130,
      type: 'number' as const,
      align: 'right' as const,
      headerAlign: 'right' as const,
      ...fmtOpts,
    });
  }

  return { rows: pivotRows, columns: pivotCols };
}

// ─── Row Grouping ─────────────────────────────────────────────────────────────

export function applyRowGrouping(
  rows: GridRowsProp,
  config: RowGroupingConfig,
  columns: ZenttoColDef[],
  expandedGroups: Set<string>,
  getRowIdFn: (row: GridRow) => GridRowId
): GridRowsProp {
  const { field, showSubtotals = true, sortGroups = 'asc' } = config;
  const dataRows = rows as GridRow[];

  // Group rows by field value
  const groups = new Map<string, GridRow[]>();
  for (const row of dataRows) {
    const key = String(row[field] ?? 'Sin grupo');
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key)!.push(row);
  }

  // Sort group keys
  let groupKeys = Array.from(groups.keys());
  if (sortGroups === 'asc') groupKeys.sort();
  else if (sortGroups === 'desc') groupKeys.sort().reverse();

  const result: GridRow[] = [];

  for (let gi = 0; gi < groupKeys.length; gi++) {
    const groupKey = groupKeys[gi];
    const groupRows = groups.get(groupKey)!;
    const isExpanded = expandedGroups.has(groupKey);

    // Build group header row with subtotals
    const groupHeader: GridRow = {
      id: `__group__${groupKey}`,
      [GROUP_ROW_KEY]: true,
      __groupKey: groupKey,
      __groupField: field,
      __groupCount: groupRows.length,
      __groupExpanded: isExpanded,
    };

    // Compute subtotals for columns with aggregation
    if (showSubtotals) {
      for (const col of columns) {
        if (!col.aggregation) continue;
        const values = groupRows
          .map((r) => Number(r[col.field] ?? 0))
          .filter((v) => !isNaN(v));
        groupHeader[col.field] = computeAgg(values, col.aggregation);
      }
    }

    // Set the display value for the grouped field
    const headerCol = columns.find((c) => c.field === field);
    groupHeader[field] = `${headerCol?.headerName ?? field}: ${groupKey} (${groupRows.length})`;

    result.push(groupHeader);

    // Add child rows only if expanded
    if (isExpanded) {
      for (const row of groupRows) {
        result.push(row);
      }
    }
  }

  return result;
}

// ─── Tree Data ────────────────────────────────────────────────────────────────

interface TreeNode {
  path: string[];
  row?: GridRow;
  children: Map<string, TreeNode>;
  level: number;
}

export function applyTreeData(
  rows: GridRowsProp,
  config: TreeDataConfig,
  expandedTreeNodes: Set<string>,
  getRowIdFn: (row: GridRow) => GridRowId
): GridRowsProp {
  const { getTreeDataPath, defaultExpandLevel = 0 } = config;

  // Build tree structure
  const root: TreeNode = { path: [], children: new Map(), level: -1 };

  for (const row of rows as GridRow[]) {
    const path = getTreeDataPath(row);
    let current = root;

    for (let i = 0; i < path.length; i++) {
      const segment = path[i];
      if (!current.children.has(segment)) {
        current.children.set(segment, {
          path: path.slice(0, i + 1),
          children: new Map(),
          level: i,
        });
      }
      current = current.children.get(segment)!;
    }
    current.row = row;
  }

  // Flatten tree into rows with indentation info
  const result: GridRow[] = [];

  function flattenNode(node: TreeNode, parentExpanded: boolean) {
    const entries = Array.from(node.children.entries());
    for (let ei = 0; ei < entries.length; ei++) {
      const [key, child] = entries[ei];
      const nodeId = child.path.join('/');
      const hasChildren = child.children.size > 0;

      // Determine if this node should be expanded
      const isAutoExpanded =
        defaultExpandLevel === -1 || child.level < defaultExpandLevel;
      const isExpanded = expandedTreeNodes.has(nodeId) || isAutoExpanded;

      if (!parentExpanded && node.level >= 0) continue;

      const treeRow: GridRow = {
        ...(child.row ?? {}),
        id: child.row ? getRowIdFn(child.row) : `__tree_${nodeId}`,
        __treeLevel: child.level,
        __treeNodeId: nodeId,
        __treeHasChildren: hasChildren,
        __treeExpanded: isExpanded,
        __treeLabel: key,
      };

      result.push(treeRow);

      if (hasChildren && isExpanded) {
        flattenNode(child, true);
      }
    }
  }

  flattenNode(root, true);
  return result;
}

// ─── Header Filters ───────────────────────────────────────────────────────────

export function applyHeaderFilters(
  rows: GridRowsProp,
  filters: HeaderFilter[]
): GridRowsProp {
  if (!filters.length) return rows;

  return (rows as GridRow[]).filter((row) => {
    // Row must pass ALL filters (AND logic)
    return filters.every((filter) => {
      if (filter.value == null || filter.value === '') return true;
      const cellValue = row[filter.field];
      if (cellValue == null) return false;

      const strCell = String(cellValue).toLowerCase();
      const strFilter = String(filter.value).toLowerCase();
      const numCell = Number(cellValue);
      const numFilter = Number(filter.value);

      switch (filter.operator) {
        case 'contains':
          return strCell.includes(strFilter);
        case 'equals': {
          // For numbers, compare numerically
          if (!isNaN(numCell) && !isNaN(numFilter)) return numCell === numFilter;
          return strCell === strFilter;
        }
        case 'startsWith': {
          // For dates: compare date portion (YYYY-MM-DD)
          const dateStr = String(cellValue);
          if (dateStr.includes('T') || dateStr.includes('-')) {
            const cellDate = dateStr.substring(0, 10); // YYYY-MM-DD
            return cellDate === String(filter.value);
          }
          return strCell.startsWith(strFilter);
        }
        case 'endsWith':
          return strCell.endsWith(strFilter);
        case '>':
          return !isNaN(numCell) && !isNaN(numFilter) && numCell > numFilter;
        case '<':
          return !isNaN(numCell) && !isNaN(numFilter) && numCell < numFilter;
        case '>=':
          return !isNaN(numCell) && !isNaN(numFilter) && numCell >= numFilter;
        case '<=':
          return !isNaN(numCell) && !isNaN(numFilter) && numCell <= numFilter;
        default:
          return true;
      }
    });
  });
}

// ─── Clipboard ────────────────────────────────────────────────────────────────

export function copyRowsToClipboard(
  rows: GridRow[],
  columns: ZenttoColDef[]
): void {
  const exportCols = columns.filter(
    (c) =>
      !c.field.startsWith('__') && c.type !== 'actions' && c.field !== 'actions'
  );

  const headers = exportCols.map((c) => c.headerName ?? c.field);
  const dataLines = rows.map((row) =>
    exportCols.map((col) => formatCellForExport(row, col)).join('\t')
  );

  const text = [headers.join('\t'), ...dataLines].join('\n');

  navigator.clipboard?.writeText(text).catch(() => {
    // Fallback: create a temporary textarea
    const ta = document.createElement('textarea');
    ta.value = text;
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  });
}

// ─── Column Groups (header grouping) ─────────────────────────────────────────

export function buildColumnGroupingSx(groups: ColumnGroup[]): Record<string, any> {
  if (!groups.length) return {};

  // Generate CSS for grouped header borders
  const sx: Record<string, any> = {};
  for (const group of groups) {
    for (const field of group.children) {
      sx[`& .MuiDataGrid-columnHeader[data-field="${field}"]`] = {
        borderTop: '2px solid',
        borderColor: 'divider',
      };
    }
  }
  return sx;
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
    (c) =>
      !c.field.startsWith('__') && c.type !== 'actions' && c.field !== 'actions'
  );
}

function formatCellForExport(row: GridRow, col: ZenttoColDef): string {
  const val = row[col.field];
  if (val == null || val === '') return '';
  if (col.valueFormatter && typeof col.valueFormatter === 'function') {
    try {
      const formatted = col.valueFormatter(
        val as never,
        row as never,
        col,
        {} as never
      );
      return formatted != null ? String(formatted) : String(val);
    } catch {
      return String(val);
    }
  }
  return String(val);
}

export function exportToCsv(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  filename: string
) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter((r) => !r[DETAIL_ROW_KEY]);

  const headers = exportCols.map((c) => c.headerName ?? c.field);
  const csvRows = exportRows.map((row) =>
    exportCols
      .map((col) => {
        const str = formatCellForExport(row, col);
        return str.includes(',') || str.includes('"') || str.includes('\n')
          ? `"${str.replace(/"/g, '""')}"`
          : str;
      })
      .join(',')
  );

  const content = '\uFEFF' + [headers.join(','), ...csvRows].join('\r\n');
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  downloadBlob(blob, `${filename}.csv`);
}

export function exportToExcel(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  filename: string
) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter((r) => !r[DETAIL_ROW_KEY]);

  const headerRow = exportCols
    .map(
      (c) =>
        `<th style="background:#1976d2;color:#fff;font-weight:bold;">${c.headerName ?? c.field}</th>`
    )
    .join('');

  const dataRows = exportRows
    .map((row) => {
      const isTotals = row[TOTALS_ROW_KEY];
      const isGroup = row[GROUP_ROW_KEY];
      const cells = exportCols
        .map((col) => {
          const str = formatCellForExport(row, col);
          const style =
            isTotals || isGroup
              ? 'font-weight:bold;background:#f5f5f5;'
              : '';
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

  const blob = new Blob([html], {
    type: 'application/vnd.ms-excel;charset=utf-8;',
  });
  downloadBlob(blob, `${filename}.xls`);
}

export function exportToJson(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  filename: string,
  getDetailExportData?: (row: GridRow) => Record<string, unknown>[],
  detailExportKey = 'detalles'
) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter(
    (r) => !r[DETAIL_ROW_KEY] && !r[TOTALS_ROW_KEY] && !r[GROUP_ROW_KEY]
  );
  const data = exportRows.map((row) => {
    const obj: Record<string, unknown> = {};
    exportCols.forEach((col) => {
      obj[col.headerName ?? col.field] = row[col.field] ?? null;
    });
    if (getDetailExportData) {
      obj[detailExportKey] = getDetailExportData(row);
    }
    return obj;
  });
  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json',
  });
  downloadBlob(blob, `${filename}.json`);
}

export function exportToMarkdown(
  rows: GridRowsProp,
  columns: ZenttoColDef[],
  filename: string
) {
  const exportCols = getExportableColumns(columns);
  const exportRows = (rows as GridRow[]).filter((r) => !r[DETAIL_ROW_KEY]);
  const headers = exportCols.map((c) => c.headerName ?? c.field);
  const separator = exportCols.map(() => '---');
  const dataRows = exportRows.map((row) =>
    exportCols.map((col) =>
      formatCellForExport(row, col).replace(/\|/g, '\\|')
    )
  );
  const lines = [
    `| ${headers.join(' | ')} |`,
    `| ${separator.join(' | ')} |`,
    ...dataRows.map((r) => `| ${r.join(' | ')} |`),
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

  // Calculate left offsets — each pinned-left column stacks after the previous
  const leftFields = pinned.left ?? [];
  const rightFields = pinned.right ?? [];

  // Build left offset map: col0 = 0px, col1 = col0.width, col2 = col0.width + col1.width...
  let leftOffset = 0;
  const leftOffsets: Record<string, number> = {};
  for (const field of leftFields) {
    const col = columns.find((c) => c.field === field);
    leftOffsets[field] = leftOffset;
    leftOffset += (col?.width as number) || 120; // default 120px if no width
  }

  // Build right offset map (reverse): last col = 0px, second-to-last = last.width...
  let rightOffset = 0;
  const rightOffsets: Record<string, number> = {};
  for (let i = rightFields.length - 1; i >= 0; i--) {
    const field = rightFields[i];
    const col = columns.find((c) => c.field === field);
    rightOffsets[field] = rightOffset;
    rightOffset += (col?.width as number) || 120;
  }

  // Reorder: pinned-left first, then unpinned, then pinned-right
  const leftCols = leftFields.map((f) => columns.find((c) => c.field === f)).filter(Boolean) as ZenttoColDef[];
  const rightCols = rightFields.map((f) => columns.find((c) => c.field === f)).filter(Boolean) as ZenttoColDef[];
  const middleCols = columns.filter((c) => !leftFields.includes(c.field) && !rightFields.includes(c.field));
  const ordered = [...leftCols, ...middleCols, ...rightCols];

  return ordered.map((col) => {
    const isLeft = leftFields.includes(col.field);
    const isRight = rightFields.includes(col.field);
    if (!isLeft && !isRight) return col;

    const idx = isLeft ? leftOffsets[col.field] : rightOffsets[col.field];
    const side = isLeft ? 'left' : 'right';
    // Use unique class per offset so CSS can target each independently
    const pinClass = `zentto-pin-${side}-${idx}`;
    const isLastLeft = isLeft && col.field === leftFields[leftFields.length - 1];
    const isFirstRight = isRight && col.field === rightFields[0];

    return {
      ...col,
      cellClassName: `${String(col.cellClassName ?? '')} zentto-pin ${pinClass}${isLastLeft ? ' zentto-pin-left-last' : ''}${isFirstRight ? ' zentto-pin-right-first' : ''}`.trim(),
      headerClassName: `${String(col.headerClassName ?? '')} zentto-pin ${pinClass}${isLastLeft ? ' zentto-pin-left-last' : ''}${isFirstRight ? ' zentto-pin-right-first' : ''}`.trim(),
    };
  });
}

/** Generate sx styles for pinned columns */
export function buildPinningSx(
  columns: ZenttoColDef[],
  pinned?: { left?: string[]; right?: string[] }
): Record<string, unknown> {
  if (!pinned) return {};

  const sx: Record<string, unknown> = {};
  const basePinStyle = {
    position: 'sticky !important',
    zIndex: '4 !important',
    backgroundColor: 'var(--mui-palette-background-paper, #fff) !important',
  };

  // Left pins
  let leftOffset = 0;
  for (const field of pinned.left ?? []) {
    const col = columns.find((c) => c.field === field);
    const w = (col?.width as number) || 120;
    const cls = `& .zentto-pin-left-${leftOffset}`;
    sx[cls] = { ...basePinStyle, left: `${leftOffset}px !important` };
    leftOffset += w;
  }

  // Right pins
  let rightOffset = 0;
  for (let i = (pinned.right?.length ?? 0) - 1; i >= 0; i--) {
    const field = pinned.right![i];
    const col = columns.find((c) => c.field === field);
    const w = (col?.width as number) || 120;
    const cls = `& .zentto-pin-right-${rightOffset}`;
    sx[cls] = { ...basePinStyle, right: `${rightOffset}px !important` };
    rightOffset += w;
  }

  // Border separators
  sx['& .zentto-pin-left-last'] = { borderRight: '2px solid var(--mui-palette-divider, #e0e0e0)', boxShadow: '4px 0 8px rgba(0,0,0,0.08)' };
  sx['& .zentto-pin-right-first'] = { borderLeft: '2px solid var(--mui-palette-divider, #e0e0e0)', boxShadow: '-4px 0 8px rgba(0,0,0,0.08)' };

  return sx;
}

/** Legacy pinningSx — kept for backwards compatibility */
export const pinningSx = {
  '& .zentto-pin-left-0': {
    position: 'sticky !important',
    left: '0 !important',
    zIndex: '4 !important',
    backgroundColor: 'var(--mui-palette-background-paper, #fff) !important',
    borderRight: '2px solid',
    borderColor: 'divider',
    boxShadow: '4px 0 8px rgba(0,0,0,0.08)',
  },
  '& .zentto-pin-right-0': {
    position: 'sticky !important',
    right: '0 !important',
    zIndex: '4 !important',
    backgroundColor: 'var(--mui-palette-background-paper, #fff) !important',
    borderLeft: '2px solid',
    borderColor: 'divider',
    boxShadow: '-4px 0 8px rgba(0,0,0,0.08)',
  },
} as const;
