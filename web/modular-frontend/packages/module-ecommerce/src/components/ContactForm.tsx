"use client";

import React, { useState } from "react";
import {
  Alert,
  Box,
  Button,
  CircularProgress,
  Paper,
  Stack,
  TextField,
} from "@mui/material";
import { useSubmitContactMessage } from "../hooks/useCmsPage";

export function ContactForm() {
  const mut = useSubmitContactMessage();
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    subject: "",
    message: "",
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  function setField<K extends keyof typeof form>(key: K, value: string) {
    setForm((s) => ({ ...s, [key]: value }));
    setErrors((e) => ({ ...e, [key]: "" }));
  }

  function validate(): boolean {
    const e: Record<string, string> = {};
    if (!form.name.trim()) e.name = "Requerido";
    if (!form.email.trim()) e.email = "Requerido";
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) e.email = "Email inválido";
    if (!form.message.trim()) e.message = "Requerido";
    setErrors(e);
    return Object.keys(e).length === 0;
  }

  function onSubmit(ev: React.FormEvent) {
    ev.preventDefault();
    if (!validate()) return;
    mut.mutate({
      name: form.name.trim(),
      email: form.email.trim(),
      phone: form.phone.trim() || null,
      subject: form.subject.trim() || null,
      message: form.message.trim(),
    });
  }

  return (
    <Paper elevation={0} sx={{ p: { xs: 2, md: 4 }, borderRadius: 3, bgcolor: "#fff" }}>
      {mut.isSuccess && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Mensaje enviado. Te responderemos pronto.
        </Alert>
      )}
      {mut.isError && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {(mut.error as Error)?.message || "No se pudo enviar el mensaje."}
        </Alert>
      )}
      <Box component="form" onSubmit={onSubmit} noValidate>
        <Stack spacing={2}>
          <TextField
            label="Nombre"
            value={form.name}
            onChange={(e) => setField("name", e.target.value)}
            error={!!errors.name}
            helperText={errors.name}
            required
            fullWidth
          />
          <TextField
            label="Email"
            type="email"
            value={form.email}
            onChange={(e) => setField("email", e.target.value)}
            error={!!errors.email}
            helperText={errors.email}
            required
            fullWidth
          />
          <TextField
            label="Teléfono (opcional)"
            value={form.phone}
            onChange={(e) => setField("phone", e.target.value)}
            fullWidth
          />
          <TextField
            label="Asunto (opcional)"
            value={form.subject}
            onChange={(e) => setField("subject", e.target.value)}
            fullWidth
          />
          <TextField
            label="Mensaje"
            value={form.message}
            onChange={(e) => setField("message", e.target.value)}
            error={!!errors.message}
            helperText={errors.message}
            required
            multiline
            minRows={4}
            fullWidth
          />
          <Button
            type="submit"
            variant="contained"
            disabled={mut.isPending}
            sx={{
              bgcolor: "#ff9900",
              color: "#131921",
              fontWeight: 700,
              textTransform: "none",
              px: 4,
              py: 1.5,
              "&:hover": { bgcolor: "#e88a00" },
            }}
          >
            {mut.isPending ? <CircularProgress size={20} sx={{ color: "#131921" }} /> : "Enviar mensaje"}
          </Button>
        </Stack>
      </Box>
    </Paper>
  );
}

export default ContactForm;
