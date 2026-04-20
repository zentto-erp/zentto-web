"use client";

import React, { useCallback, useEffect, useMemo, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import {
  Box,
  Chip,
  FormControl,
  InputLabel,
  MenuItem,
  Select,
  Stack,
  TextField,
} from "@mui/material";
import DeleteOutlineIcon from "@mui/icons-material/DeleteOutline";
import DownloadIcon from "@mui/icons-material/Download";
import {
  ModulePageShell,
  DeleteDialog,
  FormDialog,
  RightDetailDrawer,
  useDrawerQueryParam,
  useToast,
  ZenttoFilterPanel,
  ZenttoRecordTable,
  type BulkAction,
  type ColumnSpec,
  type FilterFieldDef,
} from "@zentto/shared-ui";
import CompanyDetailPanel from "./CompanyDetailPanel";
import {
  useCompaniesList,
  useDeleteCompany,
  useUpsertCompany,
  type Company,
  type CompanyFilter,
  type CompanySize,
} from "../hooks/useCompanies";

const GRID_ID = "module-crm:companies:list";
const RECORD_TYPE = "company";

const QS_KEYS = {
  search: "q",
  industry: "industry",
  active: "active",
} as const;

const SIZES: Array<{ value: CompanySize; label: string }> = [
  { value: "1-10", label: "1-10" },
  { value: "11-50", label: "11-50" },
  { value: "51-200", label: "51-200" },
  { value: "201-500", label: "201-500" },
  { value: "501-1000", label: "501-1000" },
  { value: "1000+", label: "1000+" },
];

const emptyCompany = {
  name: "",
  legalName: "",
  taxId: "",
  industry: "",
  size: "" as CompanySize | "",
  website: "",
  phone: "",
  email: "",
  notes: "",
  isActive: true,
};

type FilterDraft = Partial<Record<keyof typeof QS_KEYS, string>>;

export default function CompaniesPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { showToast } = useToast();

  const filterFromUrl = useMemo<FilterDraft>(() => {
    const out: FilterDraft = {};
    (Object.keys(QS_KEYS) as Array<keyof typeof QS_KEYS>).forEach((k) => {
      const v = searchParams?.get(QS_KEYS[k]);
      if (v) out[k] = v;
    });
    return out;
  }, [searchParams]);

  const filter: CompanyFilter = useMemo(
    () => ({
      page: 1,
      limit: 50,
      search: filterFromUrl.search || undefined,
      industry: filterFromUrl.industry || undefined,
      active:
        filterFromUrl.active === "true"
          ? true
          : filterFromUrl.active === "false"
            ? false
            : undefined,
    }),
    [filterFromUrl],
  );

  const updateQuery = useCallback(
    (patch: FilterDraft) => {
      const params = new URLSearchParams(searchParams?.toString() ?? "");
      (Object.keys(patch) as Array<keyof typeof QS_KEYS>).forEach((k) => {
        const qsKey = QS_KEYS[k];
        const v = patch[k];
        if (v == null || v === "") params.delete(qsKey);
        else params.set(qsKey, v);
      });
      const qs = params.toString();
      router.push(qs ? `${pathname}?${qs}` : pathname, { scroll: false });
    },
    [pathname, router, searchParams],
  );

  const companyDrawer = useDrawerQueryParam("company");
  const drawerCompanyId = companyDrawer.id ? Number(companyDrawer.id) : null;

  const { data, isLoading, error, refetch } = useCompaniesList(filter);
  const rows = (data as any)?.data ?? (data as any)?.rows ?? [];
  const totalCount = (data as any)?.totalCount ?? (data as any)?.TotalCount ?? rows.length;
  const typedRows = rows as Company[];

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyCompany);
  const upsertCompany = useUpsertCompany();
  const deleteCompany = useDeleteCompany();

  const [deleteTarget, setDeleteTarget] = useState<Company | null>(null);
  const [bulkDeleteIds, setBulkDeleteIds] = useState<Array<string | number>>([]);
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);

  const columns: ColumnSpec[] = useMemo(
    () => [
      { field: "CrmCompanyId", header: "ID", width: 70 },
      { field: "Name", header: "Nombre", flex: 1, minWidth: 200 },
      { field: "Industry", header: "Industria", width: 160 },
      { field: "Size", header: "Tamaño", width: 110 },
      { field: "Email", header: "Email", width: 200 },
      { field: "Phone", header: "Teléfono", width: 130 },
      { field: "Website", header: "Website", width: 180 },
      {
        field: "IsActive",
        header: "Activo",
        width: 90,
        renderCell: ((value: unknown) => (
          <Chip
            label={value ? "Activo" : "Inactivo"}
            size="small"
            color={value ? "success" : "default"}
          />
        )) as unknown,
      } as ColumnSpec,
      {
        field: "actions",
        header: "Acciones",
        type: "actions",
        width: 130,
        pin: "right",
        actions: [
          { icon: "view", label: "Ver", action: "view", color: "#6b7280" },
          { icon: "edit", label: "Editar", action: "edit", color: "#1976d2" },
          { icon: "delete", label: "Eliminar", action: "delete", color: "#dc2626" },
        ],
      } as ColumnSpec,
    ],
    [],
  );

  const filterFields: FilterFieldDef[] = useMemo(
    () => [
      { field: "industry", label: "Industria", type: "text", placeholder: "Industria" },
      {
        field: "active",
        label: "Estado",
        type: "select",
        options: [
          { value: "true", label: "Activas" },
          { value: "false", label: "Inactivas" },
        ],
      },
    ],
    [],
  );

  const filterValues: Record<string, string> = useMemo(
    () => ({
      industry: filterFromUrl.industry ?? "",
      active: filterFromUrl.active ?? "",
    }),
    [filterFromUrl],
  );

  const handleFilterChange = useCallback(
    (next: Record<string, string>) => {
      updateQuery({ industry: next.industry, active: next.active });
    },
    [updateQuery],
  );

  const handleSearchChange = useCallback(
    (v: string) => updateQuery({ search: v }),
    [updateQuery],
  );

  const handleOpenNew = useCallback(() => {
    setEditId(null);
    setForm(emptyCompany);
    setDialogOpen(true);
  }, []);

  const handleEdit = useCallback((c: Company) => {
    setEditId(c.CrmCompanyId);
    setForm({
      name: c.Name ?? "",
      legalName: c.LegalName ?? "",
      taxId: c.TaxId ?? "",
      industry: c.Industry ?? "",
      size: (c.Size ?? "") as CompanySize | "",
      website: c.Website ?? "",
      phone: c.Phone ?? "",
      email: c.Email ?? "",
      notes: c.Notes ?? "",
      isActive: c.IsActive,
    });
    setDialogOpen(true);
  }, []);

  const handleSave = useCallback(() => {
    const payload = {
      id: editId ?? undefined,
      name: form.name.trim(),
      legalName: form.legalName || undefined,
      taxId: form.taxId || undefined,
      industry: form.industry || undefined,
      size: form.size || undefined,
      website: form.website || undefined,
      phone: form.phone || undefined,
      email: form.email || undefined,
      notes: form.notes || undefined,
      isActive: form.isActive,
    };
    upsertCompany.mutate(payload, {
      onSuccess: () => {
        setDialogOpen(false);
        showToast(editId ? "Empresa actualizada" : "Empresa creada", "success");
      },
    });
  }, [editId, form, upsertCompany, showToast]);

  const handleOpenRecord = useCallback(
    (id: string | number) => companyDrawer.openDrawer(id),
    [companyDrawer],
  );

  const handleActionClick = useCallback(
    (row: Company, action: string) => {
      if (action === "view") companyDrawer.openDrawer(row.CrmCompanyId);
      else if (action === "edit") handleEdit(row);
      else if (action === "delete") setDeleteTarget(row);
    },
    [companyDrawer, handleEdit],
  );

  useEffect(() => {
    const el = document.querySelector<HTMLElement>(`zentto-grid[grid-id="${GRID_ID}"]`);
    if (!el) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as { action?: string; row?: Company };
      if (!detail?.action || !detail?.row) return;
      handleActionClick(detail.row, detail.action);
    };
    el.addEventListener("action-click", handler as EventListener);
    return () => el.removeEventListener("action-click", handler as EventListener);
  }, [handleActionClick]);

  const confirmDelete = useCallback(() => {
    if (!deleteTarget) return;
    deleteCompany.mutate(deleteTarget.CrmCompanyId, {
      onSuccess: () => {
        showToast("Empresa eliminada", "success");
        setDeleteTarget(null);
      },
    });
  }, [deleteCompany, deleteTarget, showToast]);

  const runBulkDelete = useCallback(async () => {
    const numeric = bulkDeleteIds.map((id) => Number(id));
    await Promise.all(numeric.map((id) => deleteCompany.mutateAsync(id)));
    showToast(`${numeric.length} empresas eliminadas`, "success");
    setBulkDeleteOpen(false);
    setBulkDeleteIds([]);
  }, [bulkDeleteIds, deleteCompany, showToast]);

  const exportCsv = useCallback(
    (ids: Array<string | number>) => {
      const selected = typedRows.filter((r) => ids.includes(r.CrmCompanyId));
      if (!selected.length) return;
      const headers = ["CrmCompanyId", "Name", "Industry", "Size", "Email", "Phone", "Website"];
      const escape = (v: unknown) => {
        const s = v == null ? "" : String(v);
        return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
      };
      const lines = [
        headers.join(","),
        ...selected.map((r) => headers.map((h) => escape((r as any)[h])).join(",")),
      ];
      const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `crm-empresas-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      showToast(`${selected.length} empresas exportadas`, "success");
    },
    [typedRows, showToast],
  );

  const bulkActions: BulkAction[] = useMemo(
    () => [
      {
        id: "export-csv",
        label: "Exportar CSV",
        icon: <DownloadIcon fontSize="small" />,
        onClick: (ids) => exportCsv(ids),
      },
      {
        id: "delete",
        label: "Eliminar",
        icon: <DeleteOutlineIcon fontSize="small" />,
        variant: "danger",
        onClick: (ids) => {
          setBulkDeleteIds(ids);
          setBulkDeleteOpen(true);
        },
      },
    ],
    [exportCsv],
  );

  return (
    <ModulePageShell sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <ZenttoRecordTable
          recordType={RECORD_TYPE}
          gridId={GRID_ID}
          rowKey="CrmCompanyId"
          rows={typedRows as unknown as Record<string, unknown>[]}
          columns={columns}
          loading={isLoading}
          error={error ? String((error as any)?.message ?? error) : null}
          onRetry={() => refetch()}
          totalCount={totalCount}
          onOpenRecord={handleOpenRecord}
          onCreate={handleOpenNew}
          createLabel="Nueva empresa"
          bulkActions={bulkActions}
          emptyState={{
            title: "Sin empresas todavía",
            description: "Registra empresas para agrupar contactos y deals.",
            primaryAction: {
              label: "Crear primera empresa",
              onClick: handleOpenNew,
            },
            secondaryAction: {
              label: "Importar CSV",
              onClick: () => showToast("Importación CSV pendiente (follow-up)", "info"),
            },
          }}
          gridAttrs={{
            "export-filename": "crm-empresas-list",
            "enable-header-menu": true,
            "enable-header-filters": true,
            "enable-clipboard": true,
            "enable-context-menu": true,
            "enable-configurator": true,
            "enable-grouping": true,
            "enable-pivot": true,
          }}
          filterPanel={
            <ZenttoFilterPanel
              filters={filterFields}
              values={filterValues}
              onChange={handleFilterChange}
              searchPlaceholder="Buscar empresa (nombre, tax id, email…)"
              searchValue={filterFromUrl.search ?? ""}
              onSearchChange={handleSearchChange}
            />
          }
        />
      </Box>

      <RightDetailDrawer
        open={companyDrawer.open && drawerCompanyId !== null}
        onClose={companyDrawer.closeDrawer}
        title="Detalle de empresa"
        subtitle={drawerCompanyId ? `#${drawerCompanyId}` : undefined}
        width={{ desktop: 560 }}
      >
        {drawerCompanyId && (
          <CompanyDetailPanel
            companyId={drawerCompanyId}
            onClose={companyDrawer.closeDrawer}
            onEdit={() => {
              const row = typedRows.find((r) => r.CrmCompanyId === drawerCompanyId);
              if (row) handleEdit(row);
            }}
          />
        )}
      </RightDetailDrawer>

      <FormDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        title={editId ? "Editar empresa" : "Nueva empresa"}
        mode={editId ? "edit" : "create"}
        onSave={handleSave}
        loading={upsertCompany.isPending}
        disableSave={!form.name.trim()}
        saveLabel={editId ? "Guardar" : "Crear"}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <TextField
            label="Nombre"
            fullWidth
            required
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
          />
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Razón social"
              fullWidth
              value={form.legalName}
              onChange={(e) => setForm({ ...form, legalName: e.target.value })}
            />
            <TextField
              label="Tax ID / RFC / RIF"
              fullWidth
              value={form.taxId}
              onChange={(e) => setForm({ ...form, taxId: e.target.value })}
            />
          </Stack>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Industria"
              fullWidth
              value={form.industry}
              onChange={(e) => setForm({ ...form, industry: e.target.value })}
            />
            <FormControl fullWidth>
              <InputLabel>Tamaño</InputLabel>
              <Select
                value={form.size}
                label="Tamaño"
                onChange={(e) =>
                  setForm({ ...form, size: e.target.value as CompanySize | "" })
                }
              >
                <MenuItem value="">Sin especificar</MenuItem>
                {SIZES.map((s) => (
                  <MenuItem key={s.value} value={s.value}>
                    {s.label}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          </Stack>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Email"
              fullWidth
              type="email"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
            <TextField
              label="Teléfono"
              fullWidth
              value={form.phone}
              onChange={(e) => setForm({ ...form, phone: e.target.value })}
            />
          </Stack>
          <TextField
            label="Website"
            fullWidth
            value={form.website}
            onChange={(e) => setForm({ ...form, website: e.target.value })}
          />
          <TextField
            label="Notas"
            fullWidth
            multiline
            rows={2}
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
          />
        </Stack>
      </FormDialog>

      <DeleteDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        itemName={deleteTarget ? `la empresa "${deleteTarget.Name}"` : "esta empresa"}
        loading={deleteCompany.isPending}
      />

      <DeleteDialog
        open={bulkDeleteOpen}
        onClose={() => setBulkDeleteOpen(false)}
        onConfirm={runBulkDelete}
        itemName={`${bulkDeleteIds.length} empresa${bulkDeleteIds.length === 1 ? "" : "s"}`}
        loading={deleteCompany.isPending}
      />
    </ModulePageShell>
  );
}
