"use client";

import React, { useState } from "react";
import { Autocomplete, TextField, Box, Typography, Chip } from "@mui/material";
import PersonIcon from "@mui/icons-material/Person";
import { useEmpleadosList } from "../hooks/useEmpleados";

/** Minimal row shape returned by GET /v1/empleados */
export interface EmpleadoRow {
  CEDULA?: string;
  cedula?: string;
  EmployeeCode?: string;
  NOMBRE?: string;
  nombre?: string;
  EmployeeName?: string;
  CARGO?: string;
  cargo?: string;
  GRUPO?: string;
  grupo?: string;
  STATUS?: string;
  status?: string;
  [key: string]: unknown;
}

/* ── field normalizers (backend may return UPPER, lower, or PascalCase) ── */
const empCode = (e: EmpleadoRow) => e.CEDULA ?? e.cedula ?? e.EmployeeCode ?? "";
const empName = (e: EmpleadoRow) => e.NOMBRE ?? e.nombre ?? e.EmployeeName ?? "";
const empCargo = (e: EmpleadoRow) => e.CARGO ?? e.cargo ?? "";
const empGrupo = (e: EmpleadoRow) => e.GRUPO ?? e.grupo ?? "";

export interface EmployeeSelectorProps {
  /** Current employee code value */
  value: string;
  /** Called with the selected employee code (or "" when cleared) */
  onChange: (code: string) => void;
  /** Called with the full employee row when selected */
  onSelect?: (employee: EmpleadoRow | null) => void;
  /** Field label */
  label?: string;
  /** MUI size */
  size?: "small" | "medium";
  /** Full width */
  fullWidth?: boolean;
  /** Disabled */
  disabled?: boolean;
  /** Only show active employees (default true) */
  activeOnly?: boolean;
  /** Error state */
  error?: boolean;
  /** Helper text */
  helperText?: string;
}

export default function EmployeeSelector({
  value,
  onChange,
  onSelect,
  label = "Empleado",
  size = "medium",
  fullWidth = true,
  disabled = false,
  activeOnly = true,
  error,
  helperText,
}: EmployeeSelectorProps) {
  const [inputValue, setInputValue] = useState("");

  const { data, isLoading } = useEmpleadosList({
    status: activeOnly ? "ACTIVO" : undefined,
    search: inputValue || undefined,
    limit: 50,
  });

  const empleados: EmpleadoRow[] = data?.rows ?? (Array.isArray(data) ? data : []);

  // Find the currently-selected employee object (if any)
  const selectedObj = value
    ? empleados.find((e) => empCode(e) === value) ?? null
    : null;

  return (
    <Autocomplete
      value={selectedObj}
      inputValue={inputValue}
      onInputChange={(_e, newInput) => setInputValue(newInput)}
      onChange={(_e, newVal: EmpleadoRow | null) => {
        onChange(newVal ? empCode(newVal) : "");
        onSelect?.(newVal);
      }}
      options={empleados}
      loading={isLoading}
      getOptionLabel={(opt: EmpleadoRow) =>
        `${empCode(opt)} — ${empName(opt)}`
      }
      isOptionEqualToValue={(opt, val) => empCode(opt) === empCode(val)}
      filterOptions={(x) => x} // server-side filtering via search param
      noOptionsText="No se encontraron empleados"
      loadingText="Buscando..."
      disabled={disabled}
      fullWidth={fullWidth}
      size={size}
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          error={error}
          helperText={helperText}
          placeholder="Buscar por cédula o nombre..."
          InputProps={{
            ...params.InputProps,
            startAdornment: (
              <>
                <PersonIcon sx={{ color: "text.secondary", fontSize: 20, mr: 0.5 }} />
                {params.InputProps.startAdornment}
              </>
            ),
          }}
        />
      )}
      renderOption={(props, option) => {
        const { key, ...rest } = props as any;
        return (
          <Box
            component="li"
            key={empCode(option)}
            {...rest}
            sx={{ display: "flex", flexDirection: "column", alignItems: "flex-start !important", gap: 0.3, py: 1 }}
          >
            <Box sx={{ display: "flex", alignItems: "center", gap: 1, width: "100%" }}>
              <Typography variant="body2" fontWeight={600}>
                {empCode(option)}
              </Typography>
              <Typography variant="body2" sx={{ flex: 1 }}>
                {empName(option)}
              </Typography>
            </Box>
            <Box sx={{ display: "flex", gap: 0.5 }}>
              {empCargo(option) && (
                <Chip label={empCargo(option)} size="small" variant="outlined" sx={{ fontSize: 11, height: 20 }} />
              )}
              {empGrupo(option) && (
                <Chip label={empGrupo(option)} size="small" variant="outlined" color="primary" sx={{ fontSize: 11, height: 20 }} />
              )}
            </Box>
          </Box>
        );
      }}
    />
  );
}
