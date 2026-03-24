"use client";

import * as React from "react";
import Box from "@mui/material/Box";
import Tooltip from "@mui/material/Tooltip";
import AddIcon from "@mui/icons-material/Add";
import EditIcon from "@mui/icons-material/Edit";
import DeleteIcon from "@mui/icons-material/DeleteOutlined";
import SaveIcon from "@mui/icons-material/Save";
import CancelIcon from "@mui/icons-material/Close";
import AccountBalanceIcon from "@mui/icons-material/AccountBalance";
import {
  GridRowsProp,
  GridRowModesModel,
  GridRowModes,
  GridRowId,
  GridRowModel,
  GridRowEditStopReasons,
  GridSlots,
  GridActionsCellItem,
  GridRenderCellParams,
} from "@mui/x-data-grid";
import { ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import { Button } from "@mui/material";

// Función para generar IDs únicos (reemplaza @mui/x-data-grid-generator)
const randomId = () => Math.random().toString(36).substring(2, 15);

// ─── Tipos ─────────────────────────────────────────────────────

export interface EditableDataGridProps<T extends { id?: string | number }> {
  rows: T[];
  columns: ZenttoColDef[];
  onSave: (row: T) => Promise<void> | void;
  onDelete: (id: GridRowId) => Promise<void> | void;
  onCancel?: (id: GridRowId) => void;
  loading?: boolean;
  height?: number | string;
  /** Cuando es true, el componente usa flex: 1 en vez de height fijo. */
  flexFill?: boolean;
  title?: string;
  addButtonText?: string;
  hideAddButton?: boolean;
  getRowId?: (row: T) => string | number;
  onRowClick?: (row: T) => void;
  extraActions?: (row: T) => React.ReactElement[];
  defaultNewRow?: Partial<T>;
}

// ─── Contexto para handlers ────────────────────────────────────

interface ActionHandlers {
  handleCancelClick: (id: GridRowId) => void;
  handleDeleteClick: (id: GridRowId) => void;
  handleEditClick: (id: GridRowId) => void;
  handleSaveClick: (id: GridRowId) => void;
}

const ActionHandlersContext = React.createContext<ActionHandlers>({
  handleCancelClick: () => {},
  handleDeleteClick: () => {},
  handleEditClick: () => {},
  handleSaveClick: () => {},
});

// ─── Toolbar ────────────────────────────────────────────────────

function EditToolbar({ 
  setRows, 
  setRowModesModel, 
  defaultNewRow, 
  title, 
  addButtonText 
}: any) {
  const handleClick = () => {
    const id = randomId();
    const newRow = { id, isNew: true, ...defaultNewRow };
    setRows((oldRows: GridRowsProp) => [...oldRows, newRow]);
    setRowModesModel((oldModel: GridRowModesModel) => ({
      ...oldModel,
      [id]: { mode: GridRowModes.Edit, fieldToFocus: Object.keys(defaultNewRow || {})[0] || "name" },
    }));
  };

  return (
    <Box sx={{ p: 1, display: "flex", alignItems: "center", gap: 1 }}>
      {title && (
        <Box sx={{ flex: 1 }}>
          <strong>{title}</strong>
        </Box>
      )}
      <Button 
        variant="outlined" 
        size="small" 
        onClick={handleClick} 
        startIcon={<AddIcon />}
      >
        {addButtonText || "Nuevo"}
      </Button>
    </Box>
  );
}

// ─── Celda de Acciones ─────────────────────────────────────────

function ActionsCell(props: GridRenderCellParams) {
  const { id } = props;
  // @ts-ignore — rowModesModel se pasa como prop custom al renderCell
  const isInEditMode = props.rowModesModel?.[id]?.mode === GridRowModes.Edit;

  const { handleSaveClick, handleCancelClick, handleEditClick, handleDeleteClick } =
    React.useContext(ActionHandlersContext);

  if (isInEditMode) {
    return (
      <Box sx={{ display: "flex", gap: 0.5 }}>
        <Tooltip title="Guardar">
          <GridActionsCellItem
            icon={<SaveIcon />}
            label="Save"
            onClick={() => handleSaveClick(id)}
            // @ts-ignore — sx es válido en MUI pero el tipo estricto no lo reconoce
            sx={{ color: "primary.main" }}
          />
        </Tooltip>
        <Tooltip title="Cancelar">
          <GridActionsCellItem
            icon={<CancelIcon />}
            label="Cancel"
            onClick={() => handleCancelClick(id)}
          />
        </Tooltip>
      </Box>
    );
  }

  return (
    <Box sx={{ display: "flex", gap: 0.5 }}>
      <Tooltip title="Editar">
        <GridActionsCellItem
          icon={<EditIcon />}
          label="Edit"
          onClick={() => handleEditClick(id)}
        />
      </Tooltip>
      <Tooltip title="Eliminar">
        <GridActionsCellItem
          icon={<DeleteIcon />}
          label="Delete"
          onClick={() => handleDeleteClick(id)}          // @ts-ignore — sx es válido en MUI pero el tipo estricto no lo reconoce          sx={{ color: "error.main" }}
        />
      </Tooltip>
    </Box>
  );
}

// ─── Componente Principal ──────────────────────────────────────

export default function EditableDataGrid<T extends { id?: string | number }>({
  rows: initialRows,
  columns,
  onSave,
  onDelete,
  onCancel,
  loading = false,
  height,
  title,
  addButtonText,
  hideAddButton = false,
  getRowId,
  onRowClick,
  extraActions,
  defaultNewRow,
}: EditableDataGridProps<T>) {
  const [rows, setRows] = React.useState<GridRowsProp>(initialRows);
  const [rowModesModel, setRowModesModel] = React.useState<GridRowModesModel>({});

  // Sincronizar rows externas
  React.useEffect(() => {
    setRows(initialRows);
  }, [initialRows]);

  const handleRowEditStop = ((params: any, event: any) => {
    if (params.reason === GridRowEditStopReasons.rowFocusOut) {
      event.defaultMuiPrevented = true;
    }
  }) as any;

  const actionHandlers = React.useMemo<ActionHandlers>(
    () => ({
      handleEditClick: (id: GridRowId) => {
        setRowModesModel((prev) => ({ ...prev, [id]: { mode: GridRowModes.Edit } }));
      },
      handleSaveClick: async (id: GridRowId) => {
        setRowModesModel((prev) => ({ ...prev, [id]: { mode: GridRowModes.View } }));
      },
      handleDeleteClick: async (id: GridRowId) => {
        const row = rows.find((r) => r.id === id);
        if (row?.isNew) {
          setRows((prev) => prev.filter((r) => r.id !== id));
        } else {
          await onDelete(id);
        }
      },
      handleCancelClick: (id: GridRowId) => {
        setRowModesModel((prev) => ({
          ...prev,
          [id]: { mode: GridRowModes.View, ignoreModifications: true },
        }));

        const editedRow = rows.find((r) => r.id === id);
        if (editedRow?.isNew) {
          setRows((prev) => prev.filter((r) => r.id !== id));
        }
        onCancel?.(id);
      },
    }),
    [rows, onDelete, onCancel]
  );

  const processRowUpdate = React.useCallback(
    async (newRow: GridRowModel, oldRow: GridRowModel) => {
      await onSave(newRow as unknown as T);
      const updatedRow = { ...newRow, isNew: false };
      return updatedRow;
    },
    [onSave]
  );

  const handleProcessRowUpdateError = React.useCallback((error: Error) => {
    console.error("Error al guardar fila:", error);
  }, []);

  // Agregar columna de acciones si no existe
  const columnsWithActions: ZenttoColDef[] = React.useMemo(() => {
    const hasActions = columns.some((c) => c.field === "actions");
    if (hasActions) return columns;

    return [
      ...columns,
      {
        field: "actions",
        type: "actions",
        headerName: "Acciones",
        width: 100,
        cellClassName: "actions",
        getActions: (params: GridRenderCellParams) => {
          const isInEditMode = rowModesModel[params.id]?.mode === GridRowModes.Edit;
          
          if (isInEditMode) {
            return [
              <Tooltip key="save" title="Guardar">
                <GridActionsCellItem
                  icon={<SaveIcon />}
                  label="Save"
                  onClick={() => actionHandlers.handleSaveClick(params.id)}
                  // @ts-ignore
                  sx={{ color: "primary.main" }}
                />
              </Tooltip>,
              <Tooltip key="cancel" title="Cancelar">
                <GridActionsCellItem
                  icon={<CancelIcon />}
                  label="Cancel"
                  onClick={() => actionHandlers.handleCancelClick(params.id)}
                />
              </Tooltip>,
            ];
          }

          const actions = [
            <Tooltip key="edit" title="Editar">
              <GridActionsCellItem
                icon={<EditIcon />}
                label="Edit"
                onClick={() => actionHandlers.handleEditClick(params.id)}
              />
            </Tooltip>,
            <Tooltip key="delete" title="Eliminar">
              <GridActionsCellItem
                icon={<DeleteIcon />}
                label="Delete"
                onClick={() => actionHandlers.handleDeleteClick(params.id)}
                // @ts-ignore
                sx={{ color: "error.main" }}
              />
            </Tooltip>,
          ];

          if (extraActions) {
            actions.push(...extraActions(params.row as T));
          }

          return actions;
        },
      } as ZenttoColDef,
    ];
  }, [columns, rowModesModel, actionHandlers, extraActions]);

  const handleRowClick = React.useCallback(
    (params: any) => {
      if (onRowClick && rowModesModel[params.id]?.mode !== GridRowModes.Edit) {
        onRowClick(params.row as T);
      }
    },
    [onRowClick, rowModesModel]
  );

  return (
    <Box
      sx={{
        // Si se pasa height explícito, usarlo. Si no, usar flex para llenar el espacio.
        ...(height ? { height } : { flex: 1, minHeight: 0 }),
        width: "100%",
        "& .actions": {
          color: "text.secondary",
        },
        "& .MuiDataGrid-row:hover": {
          cursor: onRowClick ? "pointer" : "default",
        },
      }}
    >
      <ZenttoDataGrid
        {...({
          rows: rows as any,
          columns: columnsWithActions,
          editMode: "row",
          rowModesModel,
          onRowModesModelChange: setRowModesModel as any,
          onRowEditStop: handleRowEditStop as any,
          processRowUpdate,
          onProcessRowUpdateError: handleProcessRowUpdateError,
          loading,
          onRowClick: handleRowClick,
          getRowId: getRowId || ((row: any) => row.id),
          showToolbar: !hideAddButton,
          slots: { toolbar: EditToolbar as any },
          slotProps: {
            toolbar: {
              setRows,
              setRowModesModel,
              defaultNewRow,
              title,
              addButtonText,
            } as any,
          },
          initialState: {
            pagination: { paginationModel: { pageSize: 25 } },
            filter: {
              filterModel: {
                items: [],
              },
            },
          },
          pageSizeOptions: [10, 25, 50, 100],
          disableRowSelectionOnClick: !onRowClick,
          filterMode: "client",
          hideToolbar: true,
        } as any)}
      />
    </Box>
  );
}
