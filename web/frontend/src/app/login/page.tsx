"use client";

import { useState } from "react";
import { Box, Button, Card, CardContent, Stack, TextField, Typography } from "@mui/material";
import { apiPost } from "../../lib/api";

export default function LoginPage() {
  const [usuario, setUsuario] = useState("");
  const [clave, setClave] = useState("");
  const [status, setStatus] = useState<string | null>(null);

  async function onSubmit() {
    setStatus(null);
    try {
      const response = await apiPost("/v1/auth/login", { usuario, clave });
      localStorage.setItem("datqbox_token", response.token);
      setStatus(`OK: ${response.usuario?.codUsuario}`);
    } catch (err) {
      setStatus(String(err));
    }
  }

  return (
    <Box sx={{ minHeight: "100vh", p: 4 }}>
      <Card sx={{ maxWidth: 480, mx: "auto" }}>
        <CardContent>
          <Stack spacing={2}>
            <Typography variant="h5" fontWeight={600}>
              Login
            </Typography>
            <TextField label="Usuario" value={usuario} onChange={(e) => setUsuario(e.target.value)} />
            <TextField
              label="Clave"
              type="password"
              value={clave}
              onChange={(e) => setClave(e.target.value)}
            />
            <Button variant="contained" onClick={onSubmit}>
              Entrar
            </Button>
            {status ? <Typography color="text.secondary">{status}</Typography> : null}
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
