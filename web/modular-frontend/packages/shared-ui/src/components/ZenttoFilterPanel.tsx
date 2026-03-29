// components/ZenttoFilterPanel.tsx
// Panel de filtros reutilizable para cualquier tabla ZenttoDataGrid.
// Incluye: barra de busqueda, boton toggle, badge, panel colapsable, limpiar.
"use client";

import React, { useState, useCallback, useMemo } from "react";
import {
  Box,
  Button,
  TextField,
  InputAdornment,
  MenuItem,
  Collapse,
  Paper,
  Badge,
  Stack,
  ToggleButtonGroup,
  ToggleButton,
} from "@mui/material";
import {
  Search as SearchIcon,
  FilterList as FilterIcon,
  Clear as ClearIcon,
} from "@mui/icons-material";
import { debounce } from "lodash";

// ─── Types ──────────────────────────────────────────────

export type FilterFieldType = "text" | "select" | "date" | "toggle";

export type FilterSelectOption = {
  value: string;
  label: string;
};

export type FilterFieldDef = {
  field: string;
  label: string;
  type: FilterFieldType;
  /** Options for 'select' and 'toggle' types */
  options?: FilterSelectOption[];
  /** Placeholder for text/date inputs */
  placeholder?: string;
  /** Min width in px (default: 140 for select, 200 for text, 155 for date) */
  minWidth?: number;
  /** Flex grow (default: 1 for text, undefined for others) */
  flex?: number;
  /** Debounce ms for text inputs (default: 400) */
  debounceMs?: number;
};

export type ZenttoFilterPanelProps = {
  /** Array of filter field definitions */
  filters: FilterFieldDef[];
  /** Current filter values (controlled) */
  values: Record<string, string>;
  /** Called when any filter changes */
  onChange: (values: Record<string, string>) => void;
  /** Search bar placeholder (if provided, shows search bar) */
  searchPlaceholder?: string;
  /** Search value (controlled) */
  searchValue?: string;
  /** Called when search changes (debounced internally) */
  onSearchChange?: (value: string) => void;
  /** Search debounce in ms (default: 400) */
  searchDebounceMs?: number;
  /** Start open? (default: false) */
  defaultOpen?: boolean;
  /** Hide the filter toggle button (default: false) */
  hideToggle?: boolean;
};

// ─── Component ──────────────────────────────────────────

export function ZenttoFilterPanel({
  filters,
  values,
  onChange,
  searchPlaceholder,
  searchValue,
  onSearchChange,
  searchDebounceMs = 400,
  defaultOpen = false,
  hideToggle = false,
}: ZenttoFilterPanelProps) {
  const [showFilters, setShowFilters] = useState(defaultOpen);
  const [searchInput, setSearchInput] = useState(searchValue ?? "");

  // Debounced search
  // eslint-disable-next-line react-hooks/exhaustive-deps
  const debouncedSearch = useCallback(
    debounce((val: string) => {
      onSearchChange?.(val);
    }, searchDebounceMs),
    [onSearchChange, searchDebounceMs]
  );

  // Per-field debounced handlers (for text fields)
  const debouncedFieldHandlers = useMemo(() => {
    const handlers: Record<string, (val: string) => void> = {};
    filters.forEach((f) => {
      if (f.type === "text") {
        handlers[f.field] = debounce((val: string) => {
          onChange({ ...values, [f.field]: val });
        }, f.debounceMs ?? 400);
      }
    });
    return handlers;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters.map((f) => f.field).join(",")]);

  // Track local text input values for controlled display
  const [localTextValues, setLocalTextValues] = useState<Record<string, string>>({});

  // Count active filters
  const activeFilterCount = useMemo(() => {
    let c = 0;
    if (searchValue) c++;
    for (const f of filters) {
      if (values[f.field]) c++;
    }
    return c;
  }, [searchValue, values, filters]);

  const clearAll = () => {
    setSearchInput("");
    onSearchChange?.("");
    setLocalTextValues({});
    const cleared: Record<string, string> = {};
    filters.forEach((f) => {
      cleared[f.field] = "";
    });
    onChange(cleared);
  };

  const handleFieldChange = (field: string, val: string, type: FilterFieldType) => {
    if (type === "text") {
      setLocalTextValues((prev) => ({ ...prev, [field]: val }));
      debouncedFieldHandlers[field]?.(val);
    } else {
      onChange({ ...values, [field]: val });
    }
  };

  const getTextValue = (field: string) =>
    localTextValues[field] !== undefined ? localTextValues[field] : values[field] ?? "";

  return (
    <Box sx={{ mb: 1.5 }}>
      {/* Search bar + Filter toggle */}
      <Box sx={{ display: "flex", gap: 1, mb: showFilters ? 1 : 0, alignItems: "center" }}>
        {searchPlaceholder && (
          <TextField
            placeholder={searchPlaceholder}
            value={searchInput}
            onChange={(e) => {
              setSearchInput(e.target.value);
              debouncedSearch(e.target.value);
            }}
            fullWidth
            size="small"
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon fontSize="small" />
                </InputAdornment>
              ),
            }}
          />
        )}
        {!hideToggle && filters.length > 0 && (
          <Badge badgeContent={activeFilterCount} color="primary">
            <Button
              variant={showFilters ? "contained" : "outlined"}
              startIcon={<FilterIcon />}
              onClick={() => setShowFilters(!showFilters)}
              sx={{ whiteSpace: "nowrap" }}
            >
              Filtros
            </Button>
          </Badge>
        )}
        {activeFilterCount > 0 && (
          <Button
            size="small"
            startIcon={<ClearIcon />}
            onClick={clearAll}
            color="error"
            sx={{ whiteSpace: "nowrap" }}
          >
            Limpiar ({activeFilterCount})
          </Button>
        )}
      </Box>

      {/* Collapsible filter panel */}
      {filters.length > 0 && (
        <Collapse in={showFilters}>
          <Paper variant="outlined" sx={{ p: 1.5 }}>
            <Stack direction="row" spacing={1.5} flexWrap="wrap" useFlexGap>
              {filters.map((f) => {
                const defaultMinWidth =
                  f.type === "text" ? 200 : f.type === "date" ? 155 : 140;

                switch (f.type) {
                  case "text":
                    return (
                      <TextField
                        key={f.field}
                        label={f.label}
                        value={getTextValue(f.field)}
                        onChange={(e) =>
                          handleFieldChange(f.field, e.target.value, "text")
                        }
                        size="small"
                        placeholder={f.placeholder}
                        sx={{
                          minWidth: f.minWidth ?? defaultMinWidth,
                          flex: f.flex ?? 1,
                        }}
                      />
                    );

                  case "select":
                    return (
                      <TextField
                        key={f.field}
                        select
                        label={f.label}
                        value={values[f.field] ?? ""}
                        onChange={(e) =>
                          handleFieldChange(f.field, e.target.value, "select")
                        }
                        size="small"
                        sx={{
                          minWidth: f.minWidth ?? defaultMinWidth,
                          flex: f.flex,
                        }}
                      >
                        <MenuItem value="">
                          <em>Todos</em>
                        </MenuItem>
                        {(f.options ?? []).map((o) => (
                          <MenuItem key={o.value} value={o.value}>
                            {o.label}
                          </MenuItem>
                        ))}
                      </TextField>
                    );

                  case "date":
                    return (
                      <TextField
                        key={f.field}
                        label={f.label}
                        type="date"
                        value={values[f.field] ?? ""}
                        onChange={(e) =>
                          handleFieldChange(f.field, e.target.value, "date")
                        }
                        size="small"
                        sx={{ minWidth: f.minWidth ?? defaultMinWidth }}
                        InputLabelProps={{ shrink: true }}
                      />
                    );

                  case "toggle":
                    return (
                      <Box key={f.field} sx={{ display: "flex", alignItems: "center", gap: 1 }}>
                        <span style={{ fontSize: "0.875rem", color: "rgba(0,0,0,0.6)" }}>
                          {f.label}:
                        </span>
                        <ToggleButtonGroup
                          value={values[f.field] ?? ""}
                          exclusive
                          onChange={(_e, val) =>
                            handleFieldChange(f.field, val ?? "", "toggle")
                          }
                          size="small"
                        >
                          <ToggleButton value="">Todos</ToggleButton>
                          {(f.options ?? []).map((o) => (
                            <ToggleButton key={o.value} value={o.value}>
                              {o.label}
                            </ToggleButton>
                          ))}
                        </ToggleButtonGroup>
                      </Box>
                    );

                  default:
                    return null;
                }
              })}
            </Stack>
          </Paper>
        </Collapse>
      )}
    </Box>
  );
}

export default ZenttoFilterPanel;
