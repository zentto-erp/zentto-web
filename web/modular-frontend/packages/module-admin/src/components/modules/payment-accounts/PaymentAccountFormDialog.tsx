"use client";

import * as React from "react";
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button, Box,
  TextField, MenuItem, FormControlLabel, Checkbox, Typography, Stack,
  CircularProgress, Alert,
} from "@mui/material";
import {
  usePaymentProviders,
  usePaymentProviderConfig,
  useUpsertPaymentAccount,
} from "../../../hooks/usePaymentAccounts";

export default function PaymentAccountFormDialog({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const [providerCode, setProviderCode] = React.useState<string>("");
  const [environment, setEnvironment] = React.useState<"sandbox" | "production">("production");
  const [displayName, setDisplayName] = React.useState("");
  const [isDefault, setIsDefault] = React.useState(false);
  const [credentials, setCredentials] = React.useState<Record<string, string>>({});
  const [error, setError] = React.useState<string | null>(null);

  const { data: providersData, isLoading: providersLoading } = usePaymentProviders();
  const { data: configData, isLoading: configLoading } = usePaymentProviderConfig(providerCode || null);
  const upsertMut = useUpsertPaymentAccount();

  const providers = providersData?.providers ?? [];
  const fields = configData?.fields ?? [];
  const selectedProvider = providers.find((p) => p.code === providerCode);

  // Reset on close
  React.useEffect(() => {
    if (!open) {
      setProviderCode("");
      setEnvironment("production");
      setDisplayName("");
      setIsDefault(false);
      setCredentials({});
      setError(null);
    }
  }, [open]);

  // Reset credentials cuando cambia el provider
  React.useEffect(() => {
    setCredentials({});
  }, [providerCode]);

  async function handleSubmit() {
    setError(null);
    try {
      await upsertMut.mutateAsync({
        providerCode,
        environment,
        displayName: displayName.trim() || undefined,
        credentials,
        isDefault,
      });
      onClose();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      setError(msg);
    }
  }

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>Nueva cuenta de pago</DialogTitle>
      <DialogContent dividers>
        <Stack spacing={2.5}>
          {/* Selector provider */}
          <TextField
            select
            label="Proveedor de pago"
            value={providerCode}
            onChange={(e) => setProviderCode(e.target.value)}
            disabled={providersLoading}
            fullWidth
            required
            helperText={selectedProvider ? `${selectedProvider.providerType} · ${selectedProvider.countries.join(", ")}` : "Selecciona el proveedor que usará tu empresa"}
          >
            {providers.map((p) => (
              <MenuItem key={p.code} value={p.code}>
                {p.name} <Typography component="span" variant="caption" sx={{ ml: 1, color: "text.secondary" }}>· {p.code}</Typography>
              </MenuItem>
            ))}
          </TextField>

          {selectedProvider ? (
            <>
              <TextField
                select
                label="Ambiente"
                value={environment}
                onChange={(e) => setEnvironment(e.target.value as "sandbox" | "production")}
                fullWidth
              >
                <MenuItem value="sandbox">Sandbox (pruebas)</MenuItem>
                <MenuItem value="production">Producción</MenuItem>
              </TextField>

              <TextField
                label="Nombre descriptivo (opcional)"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder={`Mi ${selectedProvider.name}`}
                fullWidth
              />

              {configLoading ? (
                <Box sx={{ display: "flex", justifyContent: "center", py: 2 }}>
                  <CircularProgress size={24} />
                </Box>
              ) : (
                <Box>
                  <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 700 }}>
                    Credenciales del proveedor
                  </Typography>
                  <Stack spacing={2}>
                    {fields.map((f) => (
                      <TextField
                        key={f.key}
                        label={f.label + (f.required ? " *" : "")}
                        type={f.type === "password" ? "password" : (f.type === "number" ? "number" : "text")}
                        value={credentials[f.key] ?? ""}
                        onChange={(e) => setCredentials({ ...credentials, [f.key]: e.target.value })}
                        placeholder={f.placeholder}
                        helperText={f.helpText}
                        fullWidth
                        required={f.required}
                        select={f.type === "select"}
                      >
                        {f.type === "select" && f.options
                          ? f.options.map((o) => (
                              <MenuItem key={o.value} value={o.value}>{o.label}</MenuItem>
                            ))
                          : null}
                      </TextField>
                    ))}
                  </Stack>
                </Box>
              )}

              <FormControlLabel
                control={<Checkbox checked={isDefault} onChange={(e) => setIsDefault(e.target.checked)} />}
                label="Usar como cuenta por defecto (será el provider principal de cobro)"
              />
            </>
          ) : null}

          {error ? <Alert severity="error">{error}</Alert> : null}
        </Stack>
      </DialogContent>
      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose}>Cancelar</Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={!providerCode || upsertMut.isPending}
        >
          {upsertMut.isPending ? <CircularProgress size={18} sx={{ color: "#fff" }} /> : "Guardar cuenta"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
