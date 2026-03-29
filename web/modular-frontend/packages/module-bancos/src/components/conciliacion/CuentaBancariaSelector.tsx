"use client";

import { TextField, MenuItem } from "@mui/material";

interface CuentaBancariaSelectorProps {
  cuentas: any[];
  selectedNroCta: string;
  onNroCtaChange: (nroCta: string) => void;
  label?: string;
  size?: "small" | "medium";
  sx?: object;
}

export default function CuentaBancariaSelector({
  cuentas,
  selectedNroCta,
  onNroCtaChange,
  label = "Cuenta bancaria",
  size = "small",
  sx,
}: CuentaBancariaSelectorProps) {
  const items = Array.isArray(cuentas) ? cuentas : [];

  return (
    <TextField
      select
      label={label}
      value={selectedNroCta}
      onChange={(e) => onNroCtaChange(e.target.value)}
      size={size}
      sx={{ minWidth: 200, ...sx }}
    >
      <MenuItem value="">Todas</MenuItem>
      {items.map((c: any) => (
        <MenuItem key={c.nroCta ?? c.Nro_Cta} value={c.nroCta ?? c.Nro_Cta}>
          {c.bankName ?? c.Banco ?? c.nroCta ?? c.Nro_Cta}
        </MenuItem>
      ))}
    </TextField>
  );
}
