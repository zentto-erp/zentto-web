"use client";

import React, { useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Stack,
  TextField,
  Alert,
} from "@mui/material";
import {
  useCreateIamCompany,
  type CreateCompanyInput,
} from "../../../hooks/useIam";

interface Props {
  open: boolean;
  onClose: () => void;
}

const EMPTY: CreateCompanyInput = {
  code: "",
  name: "",
  taxId: "",
  countryCode: "VE",
  timeZone: "America/Caracas",
  currency: "USD",
  email: "",
  phone: "",
};

export default function IamCompanyFormDialog({ open, onClose }: Props) {
  const create = useCreateIamCompany();
  const [form, setForm] = useState<CreateCompanyInput>(EMPTY);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      await create.mutateAsync({
        ...form,
        code: form.code.trim().toUpperCase(),
        taxId: form.taxId || null,
        email: form.email || null,
        phone: form.phone || null,
      });
      setForm(EMPTY);
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error desconocido");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <form onSubmit={handleSubmit}>
        <DialogTitle>Nueva empresa</DialogTitle>
        <DialogContent>
          <Stack spacing={2.5} sx={{ mt: 1 }}>
            {error && <Alert severity="error">{error}</Alert>}

            <TextField
              label="Codigo"
              fullWidth
              required
              value={form.code}
              onChange={(e) => setForm({ ...form, code: e.target.value })}
              helperText="Identificador corto, ej. ACME01"
              disabled={create.isPending}
            />

            <TextField
              label="Razon social"
              fullWidth
              required
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              disabled={create.isPending}
            />

            <TextField
              label="RIF / RFC / CIF"
              fullWidth
              value={form.taxId ?? ""}
              onChange={(e) => setForm({ ...form, taxId: e.target.value })}
              disabled={create.isPending}
            />

            <Stack direction="row" spacing={2}>
              <TextField
                label="Pais"
                value={form.countryCode}
                onChange={(e) => setForm({ ...form, countryCode: e.target.value.toUpperCase() })}
                inputProps={{ maxLength: 2 }}
                disabled={create.isPending}
              />
              <TextField
                label="Moneda"
                value={form.currency}
                onChange={(e) => setForm({ ...form, currency: e.target.value.toUpperCase() })}
                inputProps={{ maxLength: 3 }}
                disabled={create.isPending}
              />
              <TextField
                label="Zona horaria"
                fullWidth
                value={form.timeZone}
                onChange={(e) => setForm({ ...form, timeZone: e.target.value })}
                disabled={create.isPending}
              />
            </Stack>

            <TextField
              label="Email"
              type="email"
              fullWidth
              value={form.email ?? ""}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              disabled={create.isPending}
            />

            <TextField
              label="Telefono"
              fullWidth
              value={form.phone ?? ""}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
              disabled={create.isPending}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose} disabled={create.isPending}>
            Cancelar
          </Button>
          <Button type="submit" variant="contained" disabled={create.isPending}>
            Crear
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}
