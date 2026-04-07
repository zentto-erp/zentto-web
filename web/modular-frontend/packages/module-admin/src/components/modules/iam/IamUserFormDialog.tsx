"use client";

import React, { useEffect, useState } from "react";
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Stack,
  FormControlLabel,
  Switch,
  MenuItem,
  Alert,
} from "@mui/material";
import {
  useCreateIamUser,
  useUpdateIamUser,
  type IamUser,
  type CreateUserInput,
} from "../../../hooks/useIam";

interface Props {
  open: boolean;
  user: IamUser | null;
  onClose: () => void;
}

const EMPTY: CreateUserInput = {
  username: "",
  email: "",
  password: "",
  displayName: "",
  isAdmin: false,
  userType: "staff",
};

export default function IamUserFormDialog({ open, user, onClose }: Props) {
  const isEdit = !!user;
  const create = useCreateIamUser();
  const update = useUpdateIamUser();
  const pending = create.isPending || update.isPending;

  const [form, setForm] = useState<CreateUserInput>(EMPTY);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open) return;
    if (user) {
      setForm({
        username: user.Username,
        email: user.Email ?? "",
        password: "",
        displayName: user.DisplayName ?? "",
        isAdmin: user.IsAdmin,
        userType: (user.UserType as "staff" | "customer") ?? "staff",
      });
    } else {
      setForm(EMPTY);
    }
    setError(null);
  }, [open, user]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    try {
      if (isEdit && user) {
        await update.mutateAsync({
          userId: user.UserId,
          email: form.email || null,
          displayName: form.displayName || null,
          isAdmin: form.isAdmin,
          userType: form.userType,
        });
      } else {
        if (form.password.length < 8) {
          setError("La contrasena debe tener al menos 8 caracteres");
          return;
        }
        await create.mutateAsync({
          username: form.username.trim().toUpperCase(),
          email: form.email || null,
          password: form.password,
          displayName: form.displayName || null,
          isAdmin: form.isAdmin,
          userType: form.userType,
        });
      }
      onClose();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Error desconocido");
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <form onSubmit={handleSubmit}>
        <DialogTitle>{isEdit ? "Editar usuario" : "Nuevo usuario"}</DialogTitle>
        <DialogContent>
          <Stack spacing={2.5} sx={{ mt: 1 }}>
            {error && <Alert severity="error">{error}</Alert>}

            <TextField
              label="Usuario"
              fullWidth
              required
              value={form.username}
              onChange={(e) => setForm({ ...form, username: e.target.value })}
              disabled={isEdit || pending}
              helperText={isEdit ? "El username no se puede cambiar" : "Se guardara en MAYUSCULAS"}
            />

            <TextField
              label="Nombre completo"
              fullWidth
              value={form.displayName ?? ""}
              onChange={(e) => setForm({ ...form, displayName: e.target.value })}
              disabled={pending}
            />

            <TextField
              label="Email"
              type="email"
              fullWidth
              value={form.email ?? ""}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
              disabled={pending}
            />

            {!isEdit && (
              <TextField
                label="Contrasena"
                type="password"
                fullWidth
                required
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
                helperText="Minimo 8 caracteres"
                disabled={pending}
              />
            )}

            <TextField
              select
              label="Tipo de usuario"
              fullWidth
              value={form.userType}
              onChange={(e) =>
                setForm({ ...form, userType: e.target.value as "staff" | "customer" })
              }
              disabled={pending}
            >
              <MenuItem value="staff">Staff (interno)</MenuItem>
              <MenuItem value="customer">Cliente externo</MenuItem>
            </TextField>

            <FormControlLabel
              control={
                <Switch
                  checked={form.isAdmin ?? false}
                  onChange={(e) => setForm({ ...form, isAdmin: e.target.checked })}
                  disabled={pending}
                />
              }
              label="Es administrador (acceso total)"
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={onClose} disabled={pending}>
            Cancelar
          </Button>
          <Button type="submit" variant="contained" disabled={pending}>
            {isEdit ? "Guardar" : "Crear"}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
}
