"use client";

import { useEffect, useState } from "react";
import {
  Dialog, DialogTitle, DialogContent, DialogActions, Button, TextField,
  Stack, FormControl, InputLabel, Select, MenuItem, FormControlLabel,
  Switch, Alert, Chip, Box, Typography,
} from "@mui/material";
import Grid from "@mui/material/Grid2";
import DeleteIcon from "@mui/icons-material/DeleteOutline";
import AddIcon from "@mui/icons-material/Add";
import { apiFetch } from "../context";
import type { PlanAdmin } from "./types";
import { VERTICAL_OPTIONS, PRODUCT_OPTIONS } from "./types";

interface Props {
  open: boolean;
  initial: PlanAdmin | null;
  masterKey: string;
  onClose: () => void;
  onSaved: () => void;
}

const EMPTY: Omit<PlanAdmin, "PricingPlanId"> = {
  Name: "", Slug: "", VerticalType: "erp", ProductCode: "erp-core",
  Description: "",
  MonthlyPrice: 0, AnnualPrice: 0, BillingCycleDefault: "monthly",
  MaxUsers: 5, MaxTransactions: 0,
  Features: [], ModuleCodes: [], Limits: {},
  IsAddon: false, IsTrialOnly: false, TrialDays: 0,
  SortOrder: 100,
  PaddlePriceIdMonthly: "", PaddlePriceIdAnnual: "",
  PaddleSyncStatus: "draft",
  IsActive: true,
};

export function PlanFormModal({ open, initial, masterKey, onClose, onSaved }: Props) {
  const [form, setForm] = useState<Omit<PlanAdmin, "PricingPlanId">>(EMPTY);
  const [featureInput, setFeatureInput] = useState("");
  const [moduleInput, setModuleInput] = useState("");
  const [limitsRaw, setLimitsRaw] = useState("{}");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (open) {
      if (initial) {
        const { PricingPlanId, ...rest } = initial;
        setForm({
          ...rest,
          Features: Array.isArray(rest.Features) ? rest.Features : [],
          ModuleCodes: Array.isArray(rest.ModuleCodes) ? rest.ModuleCodes : [],
          Limits: rest.Limits ?? {},
        });
        setLimitsRaw(JSON.stringify(rest.Limits ?? {}, null, 2));
      } else {
        setForm(EMPTY);
        setLimitsRaw("{}");
      }
      setFeatureInput("");
      setModuleInput("");
      setError("");
    }
  }, [open, initial]);

  function update<K extends keyof typeof form>(key: K, value: (typeof form)[K]) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  function addFeature() {
    const v = featureInput.trim();
    if (!v) return;
    update("Features", [...form.Features, v]);
    setFeatureInput("");
  }

  function addModule() {
    const v = moduleInput.trim();
    if (!v) return;
    update("ModuleCodes", [...form.ModuleCodes, v]);
    setModuleInput("");
  }

  async function handleSave() {
    setLoading(true);
    setError("");

    let limitsParsed: Record<string, number | boolean> = {};
    try {
      limitsParsed = JSON.parse(limitsRaw || "{}");
    } catch {
      setError("Limits debe ser JSON válido");
      setLoading(false);
      return;
    }

    try {
      const body = {
        slug: form.Slug.trim(),
        name: form.Name.trim(),
        verticalType: form.VerticalType,
        productCode: form.ProductCode,
        description: form.Description,
        monthlyPrice: Number(form.MonthlyPrice),
        annualPrice: Number(form.AnnualPrice),
        billingCycleDefault: form.BillingCycleDefault,
        maxUsers: Number(form.MaxUsers),
        maxTransactions: Number(form.MaxTransactions),
        features: form.Features,
        moduleCodes: form.ModuleCodes,
        limits: limitsParsed,
        isAddon: form.IsAddon,
        isTrialOnly: form.IsTrialOnly,
        trialDays: Number(form.TrialDays),
        sortOrder: Number(form.SortOrder),
        isActive: form.IsActive,
      };
      await apiFetch("/v1/backoffice/catalog/plans", masterKey, {
        method: "POST",
        body: JSON.stringify(body),
      });
      onSaved();
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setLoading(false);
    }
  }

  const isEdit = Boolean(initial);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>{isEdit ? `Editar plan — ${initial!.Slug}` : "Nuevo plan"}</DialogTitle>
      <DialogContent dividers>
        {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

        <Grid container spacing={2} sx={{ mt: 0.5 }}>
          <Grid size={{ xs: 12, md: 6 }}>
            <TextField
              label="Slug (identificador único)"
              value={form.Slug}
              onChange={(e) => update("Slug", e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ""))}
              fullWidth required disabled={isEdit}
              helperText={isEdit ? "El slug no se puede cambiar" : "Minúsculas, números, guiones"}
            />
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            <TextField label="Nombre" value={form.Name} onChange={(e) => update("Name", e.target.value)} fullWidth required />
          </Grid>

          <Grid size={{ xs: 12 }}>
            <TextField label="Descripción" value={form.Description} onChange={(e) => update("Description", e.target.value)} fullWidth multiline rows={2} />
          </Grid>

          <Grid size={{ xs: 12, md: 6 }}>
            <FormControl fullWidth>
              <InputLabel>Vertical</InputLabel>
              <Select label="Vertical" value={form.VerticalType} onChange={(e) => update("VerticalType", e.target.value)}>
                {VERTICAL_OPTIONS.map((v) => <MenuItem key={v.value} value={v.value}>{v.label}</MenuItem>)}
              </Select>
            </FormControl>
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            <FormControl fullWidth>
              <InputLabel>Producto</InputLabel>
              <Select label="Producto" value={form.ProductCode} onChange={(e) => update("ProductCode", e.target.value)}>
                {PRODUCT_OPTIONS.map((p) => <MenuItem key={p} value={p}>{p}</MenuItem>)}
              </Select>
            </FormControl>
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField label="Precio mensual (USD)" type="number" value={form.MonthlyPrice}
              onChange={(e) => update("MonthlyPrice", Number(e.target.value))}
              fullWidth inputProps={{ step: "0.01", min: 0 }} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <TextField label="Precio anual (USD)" type="number" value={form.AnnualPrice}
              onChange={(e) => update("AnnualPrice", Number(e.target.value))}
              fullWidth inputProps={{ step: "0.01", min: 0 }} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <FormControl fullWidth>
              <InputLabel>Ciclo default</InputLabel>
              <Select label="Ciclo default" value={form.BillingCycleDefault}
                onChange={(e) => update("BillingCycleDefault", e.target.value as any)}>
                <MenuItem value="monthly">Mensual</MenuItem>
                <MenuItem value="annual">Anual</MenuItem>
                <MenuItem value="both">Ambos</MenuItem>
              </Select>
            </FormControl>
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <TextField label="Max usuarios" type="number" value={form.MaxUsers}
              onChange={(e) => update("MaxUsers", Number(e.target.value))} fullWidth inputProps={{ min: 0 }} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <TextField label="Max transacciones (0 = ilimitado)" type="number" value={form.MaxTransactions}
              onChange={(e) => update("MaxTransactions", Number(e.target.value))} fullWidth inputProps={{ min: 0 }} />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <TextField label="Orden" type="number" value={form.SortOrder}
              onChange={(e) => update("SortOrder", Number(e.target.value))} fullWidth />
          </Grid>

          <Grid size={{ xs: 12, md: 4 }}>
            <FormControlLabel control={<Switch checked={form.IsAddon} onChange={(e) => update("IsAddon", e.target.checked)} />} label="Es add-on vertical" />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <FormControlLabel control={<Switch checked={form.IsTrialOnly} onChange={(e) => update("IsTrialOnly", e.target.checked)} />} label="Solo trial" />
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <FormControlLabel control={<Switch checked={form.IsActive} onChange={(e) => update("IsActive", e.target.checked)} />} label="Activo" />
          </Grid>

          {form.IsTrialOnly && (
            <Grid size={{ xs: 12, md: 4 }}>
              <TextField label="Días de trial" type="number" value={form.TrialDays}
                onChange={(e) => update("TrialDays", Number(e.target.value))} fullWidth inputProps={{ min: 1, max: 365 }} />
            </Grid>
          )}

          <Grid size={{ xs: 12 }}>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>Features (texto mostrado al usuario)</Typography>
            <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap", mb: 1 }}>
              {form.Features.map((f, i) => (
                <Chip key={i} label={f} onDelete={() => update("Features", form.Features.filter((_, j) => j !== i))} sx={{ mb: 0.5 }} />
              ))}
            </Stack>
            <Stack direction="row" spacing={1}>
              <TextField size="small" value={featureInput} onChange={(e) => setFeatureInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && (e.preventDefault(), addFeature())}
                placeholder="Ej: Hasta 15 usuarios" fullWidth />
              <Button startIcon={<AddIcon />} onClick={addFeature}>Añadir</Button>
            </Stack>
          </Grid>

          <Grid size={{ xs: 12 }}>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>Module codes (entitlements)</Typography>
            <Stack direction="row" spacing={1} sx={{ flexWrap: "wrap", mb: 1 }}>
              {form.ModuleCodes.map((m, i) => (
                <Chip key={i} label={m} size="small" color="primary"
                  onDelete={() => update("ModuleCodes", form.ModuleCodes.filter((_, j) => j !== i))} sx={{ mb: 0.5 }} />
              ))}
            </Stack>
            <Stack direction="row" spacing={1}>
              <TextField size="small" value={moduleInput} onChange={(e) => setModuleInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && (e.preventDefault(), addModule())}
                placeholder="Ej: dashboard, facturas, pos" fullWidth />
              <Button startIcon={<AddIcon />} onClick={addModule}>Añadir</Button>
            </Stack>
          </Grid>

          <Grid size={{ xs: 12 }}>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>Limits (JSON)</Typography>
            <TextField value={limitsRaw} onChange={(e) => setLimitsRaw(e.target.value)} fullWidth multiline rows={5}
              placeholder='{"branches":3,"storage_gb":50,"invoices_month":0}'
              helperText="Objeto JSON con límites del plan (users, branches, warehouses, storage_gb, etc.)"
              sx={{ fontFamily: "monospace" }} />
          </Grid>

          {initial && (
            <Grid size={{ xs: 12 }}>
              <Alert severity={form.PaddleSyncStatus === "synced" ? "success" : form.PaddleSyncStatus === "error" ? "error" : "info"}>
                <Box sx={{ fontSize: 13 }}>
                  <strong>Estado Paddle:</strong> {form.PaddleSyncStatus}
                  {form.PaddleProductId && <> · <strong>Product:</strong> {form.PaddleProductId}</>}
                  {form.PaddlePriceIdMonthly && <> · <strong>Precio mensual:</strong> {form.PaddlePriceIdMonthly}</>}
                  {form.PaddlePriceIdAnnual && <> · <strong>Precio anual:</strong> {form.PaddlePriceIdAnnual}</>}
                </Box>
                {(!form.PaddleProductId || form.PaddleSyncStatus === "draft") && !form.IsTrialOnly && (
                  <Box sx={{ mt: 1, fontSize: 12 }}>
                    Sincroniza este plan desde la pestaña "Paddle Sync" para crear Product + Prices en Paddle.
                  </Box>
                )}
              </Alert>
            </Grid>
          )}
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} disabled={loading}>Cancelar</Button>
        <Button onClick={handleSave} variant="contained" disabled={loading || !form.Slug || !form.Name}>
          {loading ? "Guardando..." : isEdit ? "Guardar cambios" : "Crear plan"}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
