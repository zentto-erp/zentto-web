"use client";

/**
 * CRM / Integraciones — gestiona las piezas de integración por tenant:
 *   • Webhooks salientes (reciben eventos del ecosistema en tu sistema).
 *   • Public API Keys (permiten que sitios externos usen tu tenant).
 *
 * Ambas usan zentto-grid + hooks tipados sobre @zentto/shared-api.
 * Los secretos (secret/key plain) se exponen UNA sola vez al crear — la UI
 * muestra un diálogo con copy-to-clipboard antes de cerrar.
 */

import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Box, Typography, Paper, Tabs, Tab, Button, Stack, TextField, MenuItem,
  Dialog, DialogTitle, DialogContent, DialogActions, Alert, Chip, IconButton,
  Tooltip, FormControlLabel, Checkbox,
} from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import ContentCopyIcon from "@mui/icons-material/ContentCopy";
import WebhookIcon from "@mui/icons-material/Webhook";
import VpnKeyIcon from "@mui/icons-material/VpnKey";
import type { ColumnDef } from "@zentto/datagrid-core";
import { useGridLayoutSync } from "@zentto/shared-api";
import { useCRMGridRegistration } from "./zenttoGridPersistence";
import {
  useWebhooksList, useCreateWebhook, useRevokeWebhook, type TenantWebhook,
  usePublicKeysList, useCreatePublicKey, useRevokePublicKey, type PublicApiKey,
} from "../hooks/useIntegrations";

const WEBHOOKS_GRID_ID  = "module-crm:webhooks:list";
const KEYS_GRID_ID      = "module-crm:public-keys:list";

const SCOPE_OPTIONS = [
  { value: "landing:lead:create",     label: "Crear leads" },
  { value: "notify:email:send",       label: "Enviar emails" },
  { value: "notify:otp:send",         label: "Enviar OTP" },
  { value: "notify:contacts:upsert",  label: "Gestionar contactos notify" },
  { value: "cache:read",              label: "Leer cache" },
  { value: "cache:write",             label: "Escribir cache" },
];

export default function IntegrationsPage() {
  const [tab, setTab] = useState(0);

  return (
    <Box sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0, p: 2 }}>
      <Typography variant="h5" sx={{ mb: 2 }}>Integraciones</Typography>
      <Paper sx={{ mb: 2 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)}>
          <Tab icon={<WebhookIcon />} iconPosition="start" label="Webhooks" />
          <Tab icon={<VpnKeyIcon />} iconPosition="start" label="API Keys públicas" />
        </Tabs>
      </Paper>
      {tab === 0 && <WebhooksTab />}
      {tab === 1 && <PublicKeysTab />}
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Webhooks
// ═══════════════════════════════════════════════════════════════════════════
function WebhooksTab() {
  const { data = [], isLoading } = useWebhooksList();
  const createMut = useCreateWebhook();
  const revokeMut = useRevokeWebhook();

  const gridRef = useRef<any>(null);
  const { ready: gridLayoutReady } = useGridLayoutSync(WEBHOOKS_GRID_ID);
  const { registered } = useCRMGridRegistration(gridLayoutReady);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState({ url: "", label: "", eventFilter: "*" });
  const [newSecret, setNewSecret] = useState<{ secret: string; url: string } | null>(null);

  const columns: ColumnDef[] = useMemo(() => [
    { field: "Label", header: "Etiqueta", width: 160 },
    { field: "Url", header: "URL", flex: 1, minWidth: 240 },
    { field: "EventFilter", header: "Eventos", width: 200 },
    {
      field: "IsActive", header: "Estado", width: 120,
      renderCell: ((v: unknown, row: TenantWebhook) => (
        <Chip
          size="small"
          color={v ? "success" : "default"}
          label={v ? "Activo" : row.DisabledReason ? "Desactivado" : "Inactivo"}
        />
      )) as unknown as ColumnDef["renderCell"],
    },
    {
      field: "ConsecutiveFailures", header: "Fallos", width: 100,
      renderCell: ((v: unknown) => (v as number) > 0
        ? <Chip size="small" color="warning" label={String(v)} />
        : <span>0</span>
      ) as unknown as ColumnDef["renderCell"],
    },
    { field: "LastDeliveredAt", header: "Última entrega", width: 170 },
    { field: "CreatedAt", header: "Creado", width: 170 },
  ], []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns;
    el.rows = data;
    el.loading = isLoading;
  }, [data, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail as { action: string; row: TenantWebhook };
      if (action === "delete" && confirm(`¿Revocar el webhook a ${row.Url}?`)) {
        revokeMut.mutate(row.WebhookId);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, revokeMut]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => setDialogOpen(true);
    el.addEventListener("create-click", handler);
    return () => el.removeEventListener("create-click", handler);
  }, [registered]);

  const handleCreate = () => {
    createMut.mutate(form, {
      onSuccess: (r: any) => {
        setDialogOpen(false);
        setForm({ url: "", label: "", eventFilter: "*" });
        setNewSecret({ secret: r.secret, url: form.url });
      },
    });
  };

  return (
    <Box sx={{ flex: 1, minHeight: 0 }}>
      <Alert severity="info" sx={{ mb: 2 }}>
        Los webhooks reciben eventos de tu tenant (crm.lead.created, hotel.reservation.confirmed, etc.) con firma HMAC-SHA256 en <code>X-Zentto-Signature</code>. Verificá con <code>@zentto/platform-client/webhooks</code>.
      </Alert>

      <zentto-grid
        ref={gridRef}
        grid-id={WEBHOOKS_GRID_ID}
        export-filename="crm-webhooks"
        height="calc(100vh - 280px)"
        enable-toolbar enable-header-menu enable-header-filters enable-clipboard
        enable-quick-search enable-context-menu enable-status-bar enable-configurator
        enable-create
        create-label="Nuevo webhook"
      />

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nuevo webhook</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="URL del endpoint" required fullWidth placeholder="https://acme.com/api/zentto-events"
              value={form.url} onChange={(e) => setForm({ ...form, url: e.target.value })}
            />
            <TextField
              label="Etiqueta" fullWidth placeholder="production / staging / ..."
              value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })}
            />
            <TextField
              label="Filtro de eventos" fullWidth
              helperText="CSV con patterns. '*' = todo. 'crm.lead.*' = todos los del CRM. 'hotel.reservation.confirmed' = evento exacto."
              value={form.eventFilter} onChange={(e) => setForm({ ...form, eventFilter: e.target.value })}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCreate} disabled={!form.url || createMut.isPending}>
            Crear
          </Button>
        </DialogActions>
      </Dialog>

      <SecretDialog
        open={!!newSecret}
        onClose={() => setNewSecret(null)}
        title="Webhook creado"
        value={newSecret?.secret ?? ""}
        subtitle={`Este secret se usa para verificar la firma HMAC de los eventos entregados a ${newSecret?.url}.`}
      />
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Public API Keys
// ═══════════════════════════════════════════════════════════════════════════
function PublicKeysTab() {
  const { data = [], isLoading } = usePublicKeysList();
  const createMut = useCreatePublicKey();
  const revokeMut = useRevokePublicKey();

  const gridRef = useRef<any>(null);
  const { ready: gridLayoutReady } = useGridLayoutSync(KEYS_GRID_ID);
  const { registered } = useCRMGridRegistration(gridLayoutReady);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [form, setForm] = useState<{ label: string; selectedScopes: Set<string> }>(
    { label: "", selectedScopes: new Set(["landing:lead:create"]) },
  );
  const [newKey, setNewKey] = useState<{ key: string; prefix: string } | null>(null);

  const columns: ColumnDef[] = useMemo(() => [
    { field: "Label", header: "Etiqueta", width: 180 },
    { field: "KeyPrefix", header: "Prefijo", width: 150 },
    { field: "Scopes", header: "Scopes", flex: 1, minWidth: 260 },
    {
      field: "IsActive", header: "Estado", width: 110,
      renderCell: ((v: unknown) => (
        <Chip size="small" color={v ? "success" : "default"} label={v ? "Activa" : "Revocada"} />
      )) as unknown as ColumnDef["renderCell"],
    },
    { field: "LastUsedAt", header: "Último uso", width: 170 },
    { field: "ExpiresAt", header: "Expira", width: 170 },
    { field: "CreatedAt", header: "Creada", width: 170 },
  ], []);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    el.columns = columns; el.rows = data; el.loading = isLoading;
  }, [data, isLoading, registered, columns]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = (e: CustomEvent) => {
      const { action, row } = e.detail as { action: string; row: PublicApiKey };
      if (action === "delete" && confirm(`¿Revocar la key ${row.KeyPrefix}?`)) {
        revokeMut.mutate(row.KeyId);
      }
    };
    el.addEventListener("action-click", handler);
    return () => el.removeEventListener("action-click", handler);
  }, [registered, revokeMut]);

  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;
    const handler = () => setDialogOpen(true);
    el.addEventListener("create-click", handler);
    return () => el.removeEventListener("create-click", handler);
  }, [registered]);

  const toggleScope = (s: string) => {
    const next = new Set(form.selectedScopes);
    next.has(s) ? next.delete(s) : next.add(s);
    setForm({ ...form, selectedScopes: next });
  };

  const handleCreate = () => {
    const scopes = Array.from(form.selectedScopes).join(",");
    if (!scopes) return;
    createMut.mutate({ label: form.label || "default", scopes }, {
      onSuccess: (r: any) => {
        setDialogOpen(false);
        setForm({ label: "", selectedScopes: new Set(["landing:lead:create"]) });
        setNewKey({ key: r.key, prefix: r.keyPrefix });
      },
    });
  };

  return (
    <Box sx={{ flex: 1, minHeight: 0 }}>
      <Alert severity="info" sx={{ mb: 2 }}>
        Las API keys públicas permiten que sitios externos (ej. acme.com) usen endpoints de tu tenant con <code>X-Tenant-Key</code> limitado por scopes: crear leads, mandar emails, etc.
      </Alert>

      <zentto-grid
        ref={gridRef}
        grid-id={KEYS_GRID_ID}
        export-filename="crm-public-keys"
        height="calc(100vh - 280px)"
        enable-toolbar enable-header-menu enable-header-filters enable-clipboard
        enable-quick-search enable-context-menu enable-status-bar enable-configurator
        enable-create
        create-label="Nueva API key"
      />

      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Nueva API key pública</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Etiqueta" fullWidth placeholder="acme.com contact form"
              value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })}
            />
            <Box>
              <Typography variant="subtitle2" sx={{ mb: 1 }}>Scopes</Typography>
              <Stack>
                {SCOPE_OPTIONS.map((s) => (
                  <FormControlLabel key={s.value}
                    control={<Checkbox
                      checked={form.selectedScopes.has(s.value)}
                      onChange={() => toggleScope(s.value)}
                    />}
                    label={<>{s.label} <code style={{ fontSize: 11, color: "#999" }}>{s.value}</code></>}
                  />
                ))}
              </Stack>
            </Box>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancelar</Button>
          <Button variant="contained" onClick={handleCreate} disabled={form.selectedScopes.size === 0 || createMut.isPending}>
            Crear
          </Button>
        </DialogActions>
      </Dialog>

      <SecretDialog
        open={!!newKey}
        onClose={() => setNewKey(null)}
        title="API key creada"
        value={newKey?.key ?? ""}
        subtitle={`Pasá esta key en el header X-Tenant-Key desde tu sitio externo (prefix ${newKey?.prefix}).`}
      />
    </Box>
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// SecretDialog — muestra un secret UNA sola vez con copy-to-clipboard
// ═══════════════════════════════════════════════════════════════════════════
function SecretDialog({ open, onClose, title, value, subtitle }: {
  open: boolean; onClose: () => void; title: string; value: string; subtitle?: string;
}) {
  const copy = () => { if (value) navigator.clipboard?.writeText(value); };
  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>{title}</DialogTitle>
      <DialogContent>
        <Alert severity="warning" sx={{ mb: 2 }}>
          Guardá este valor ahora — no se puede recuperar después. Si lo perdés, tenés que generar uno nuevo.
        </Alert>
        {subtitle && <Typography variant="body2" sx={{ mb: 2, color: "text.secondary" }}>{subtitle}</Typography>}
        <TextField
          fullWidth
          value={value}
          InputProps={{
            readOnly: true,
            sx: { fontFamily: "monospace", fontSize: 13 },
            endAdornment: (
              <Tooltip title="Copiar">
                <IconButton onClick={copy} size="small"><ContentCopyIcon fontSize="small" /></IconButton>
              </Tooltip>
            ),
          }}
        />
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose} variant="contained">Ya lo copié</Button>
      </DialogActions>
    </Dialog>
  );
}
