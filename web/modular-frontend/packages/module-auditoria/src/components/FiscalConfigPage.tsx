"use client";

import React, { useState, useEffect } from "react";
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
  Stack,
  Switch,
  FormControlLabel,
  Button,
  Alert,
  CircularProgress,
  Divider,
} from "@mui/material";
import SaveIcon from "@mui/icons-material/Save";
import { ContextActionHeader, ZenttoDataGrid, type ZenttoColDef } from "@zentto/shared-ui";
import { useFiscalConfig, useSaveFiscalConfig, useFiscalCountries, useFiscalTaxRates } from "../hooks/useAuditoria";

const taxRateColumns: ZenttoColDef[] = [
  { field: "code", headerName: "Código", flex: 1 },
  { field: "name", headerName: "Nombre", flex: 2 },
  { field: "rate", headerName: "Tasa %", flex: 1, type: "number", renderCell: (p) => `${p.value}%` },
  { field: "surchargeRate", headerName: "Recargo %", flex: 1, type: "number", renderCell: (p) => `${p.value ?? 0}%` },
];

export default function FiscalConfigPage() {
  const [countryCode, setCountryCode] = useState<string>("");
  const countries = useFiscalCountries();
  const config = useFiscalConfig(countryCode ? { countryCode } : undefined);
  const taxRates = useFiscalTaxRates(countryCode || null);
  const saveMutation = useSaveFiscalConfig();

  const countryOptions = Array.isArray(countries.data) ? countries.data : [];
  const taxRateOptions = Array.isArray(taxRates.data) ? taxRates.data : [];

  const [form, setForm] = useState<Record<string, any>>({});
  const [dirty, setDirty] = useState(false);

  useEffect(() => {
    if (config.data) {
      setForm(config.data);
      setDirty(false);
      if (!countryCode && config.data.countryCode) {
        setCountryCode(config.data.countryCode);
      }
    }
  }, [config.data]);

  const update = (key: string, value: any) => {
    setForm((f) => ({ ...f, [key]: value }));
    setDirty(true);
  };

  const handleSave = async () => {
    await saveMutation.mutateAsync({ ...form, countryCode });
  };

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <ContextActionHeader
        title="Configuración Fiscal"
        primaryAction={{
          label: "Guardar",
          onClick: handleSave,
          disabled: !dirty || saveMutation.isPending,
        }}
      />

      <Box sx={{ p: { xs: 2, md: 3 }, flex: 1, overflow: "auto" }}>
        {saveMutation.isSuccess && (
          <Alert severity="success" sx={{ mb: 2 }}>Configuración guardada correctamente</Alert>
        )}
        {saveMutation.isError && (
          <Alert severity="error" sx={{ mb: 2 }}>Error al guardar: {String(saveMutation.error)}</Alert>
        )}

        {/* Country Selector */}
        <Paper variant="outlined" sx={{ p: 3, mb: 3 }}>
          <Typography variant="subtitle1" fontWeight={600} mb={2}>País</Typography>
          <TextField
            select
            label="País"
           
            sx={{ minWidth: 250 }}
            value={countryCode}
            onChange={(e) => setCountryCode(e.target.value)}
          >
            <MenuItem value="">Seleccionar...</MenuItem>
            {countryOptions.map((c: any) => (
              <MenuItem key={c.code} value={c.code}>
                {c.name} ({c.code})
              </MenuItem>
            ))}
          </TextField>
        </Paper>

        {config.isLoading && <CircularProgress />}

        {countryCode && !config.isLoading && (
          <Stack spacing={3}>
            {/* General */}
            <Paper variant="outlined" sx={{ p: 3 }}>
              <Typography variant="subtitle1" fontWeight={600} mb={2}>Configuración General</Typography>
              <Stack direction="row" spacing={2} flexWrap="wrap" useFlexGap>
                <TextField
                  label="Moneda"
                 
                  value={form.currency ?? ""}
                  onChange={(e) => update("currency", e.target.value)}
                  sx={{ width: 120 }}
                />
                <TextField
                  label="Régimen Fiscal"
                 
                  value={form.taxRegime ?? ""}
                  onChange={(e) => update("taxRegime", e.target.value)}
                  sx={{ width: 200 }}
                />
                <TextField
                  label="Código Impuesto por Defecto"
                 
                  value={form.defaultTaxCode ?? ""}
                  onChange={(e) => update("defaultTaxCode", e.target.value)}
                  sx={{ width: 200 }}
                />
                <TextField
                  label="Tasa Impuesto (%)"
                 
                  type="number"
                  value={form.defaultTaxRate ?? ""}
                  onChange={(e) => update("defaultTaxRate", Number(e.target.value))}
                  sx={{ width: 150 }}
                />
              </Stack>
            </Paper>

            {/* Tax Rates */}
            {taxRateOptions.length > 0 && (
              <Paper variant="outlined" sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={600} mb={2}>Tasas de Impuesto ({countryCode})</Typography>
                <ZenttoDataGrid
                  rows={taxRateOptions}
                  columns={taxRateColumns}
                  getRowId={(row: any) => row.code}
                  hideToolbar
                  autoHeight
                />
              </Paper>
            )}

            {/* Impresora Fiscal (VE) */}
            {countryCode === "VE" && (
              <Paper variant="outlined" sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={600} mb={2}>Impresora Fiscal</Typography>
                <Stack spacing={2}>
                  <FormControlLabel
                    control={<Switch checked={!!form.fiscalPrinterEnabled} onChange={(e) => update("fiscalPrinterEnabled", e.target.checked)} />}
                    label="Impresora fiscal habilitada"
                  />
                  {form.fiscalPrinterEnabled && (
                    <Stack direction="row" spacing={2}>
                      <TextField
                        label="Marca"
                       
                        value={form.printerBrand ?? ""}
                        onChange={(e) => update("printerBrand", e.target.value)}
                      />
                      <TextField
                        label="Puerto"
                       
                        value={form.printerPort ?? ""}
                        onChange={(e) => update("printerPort", e.target.value)}
                      />
                      <TextField
                        label="RIF Emisor"
                       
                        value={form.senderRIF ?? ""}
                        onChange={(e) => update("senderRIF", e.target.value)}
                      />
                    </Stack>
                  )}
                </Stack>
              </Paper>
            )}

            {/* Verifactu (ES) */}
            {countryCode === "ES" && (
              <Paper variant="outlined" sx={{ p: 3 }}>
                <Typography variant="subtitle1" fontWeight={600} mb={2}>Verifactu (España)</Typography>
                <Stack spacing={2}>
                  <FormControlLabel
                    control={<Switch checked={!!form.verifactuEnabled} onChange={(e) => update("verifactuEnabled", e.target.checked)} />}
                    label="Verifactu habilitado"
                  />
                  {form.verifactuEnabled && (
                    <>
                      <Stack direction="row" spacing={2}>
                        <TextField
                          label="Modo"
                          select
                         
                          sx={{ width: 150 }}
                          value={form.verifactuMode ?? "manual"}
                          onChange={(e) => update("verifactuMode", e.target.value)}
                        >
                          <MenuItem value="manual">Manual</MenuItem>
                          <MenuItem value="auto">Automático</MenuItem>
                        </TextField>
                        <TextField
                          label="NIF Emisor"
                         
                          value={form.senderNIF ?? ""}
                          onChange={(e) => update("senderNIF", e.target.value)}
                        />
                        <TextField
                          label="Endpoint AEAT"
                         
                          sx={{ flex: 1 }}
                          value={form.aeatEndpoint ?? ""}
                          onChange={(e) => update("aeatEndpoint", e.target.value)}
                        />
                      </Stack>
                      <Stack direction="row" spacing={2}>
                        <TextField
                          label="Ruta Certificado"
                         
                          sx={{ flex: 1 }}
                          value={form.certificatePath ?? ""}
                          onChange={(e) => update("certificatePath", e.target.value)}
                        />
                        <TextField
                          label="Password Certificado"
                         
                          type="password"
                          value={form.certificatePassword ?? ""}
                          onChange={(e) => update("certificatePassword", e.target.value)}
                        />
                      </Stack>
                    </>
                  )}
                </Stack>
              </Paper>
            )}

            {/* Software Info */}
            <Paper variant="outlined" sx={{ p: 3 }}>
              <Typography variant="subtitle1" fontWeight={600} mb={2}>Información del Software</Typography>
              <Stack direction="row" spacing={2}>
                <TextField label="ID Software" value={form.softwareId ?? ""} onChange={(e) => update("softwareId", e.target.value)} />
                <TextField label="Nombre Software" value={form.softwareName ?? ""} onChange={(e) => update("softwareName", e.target.value)} />
                <TextField label="Versión" value={form.softwareVersion ?? ""} onChange={(e) => update("softwareVersion", e.target.value)} />
              </Stack>
            </Paper>
          </Stack>
        )}
      </Box>
    </Box>
  );
}
