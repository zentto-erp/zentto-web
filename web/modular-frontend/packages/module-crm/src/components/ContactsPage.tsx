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
import ContactDetailPanel from "./ContactDetailPanel";
import {
  useContactsList,
  useDeleteContact,
  useUpsertContact,
  type Contact,
  type ContactFilter,
} from "../hooks/useContacts";
import { useCompaniesList } from "../hooks/useCompanies";

const GRID_ID = "module-crm:contacts:list";
const RECORD_TYPE = "contact";

const QS_KEYS = {
  search: "q",
  company: "company",
  active: "active",
} as const;

const emptyContact = {
  firstName: "",
  lastName: "",
  email: "",
  phone: "",
  mobile: "",
  title: "",
  department: "",
  linkedIn: "",
  notes: "",
  crmCompanyId: "" as number | "",
  isActive: true,
};

type FilterDraft = Partial<Record<keyof typeof QS_KEYS, string>>;

export default function ContactsPage() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { showToast } = useToast();

  /* ─── Filtros desde URL ─── */
  const filterFromUrl = useMemo<FilterDraft>(() => {
    const out: FilterDraft = {};
    (Object.keys(QS_KEYS) as Array<keyof typeof QS_KEYS>).forEach((k) => {
      const v = searchParams?.get(QS_KEYS[k]);
      if (v) out[k] = v;
    });
    return out;
  }, [searchParams]);

  const filter: ContactFilter = useMemo(
    () => ({
      page: 1,
      limit: 50,
      search: filterFromUrl.search || undefined,
      crmCompanyId: filterFromUrl.company ? Number(filterFromUrl.company) : undefined,
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

  /* ─── Drawer ─── */
  const contactDrawer = useDrawerQueryParam("contact");
  const drawerContactId = contactDrawer.id ? Number(contactDrawer.id) : null;

  /* ─── Data ─── */
  const { data, isLoading, error, refetch } = useContactsList(filter);
  const { data: companiesData } = useCompaniesList({ active: true, limit: 200 });
  const companies =
    (companiesData as any)?.data ??
    (companiesData as any)?.rows ??
    companiesData ??
    [];

  const rows = (data as any)?.data ?? (data as any)?.rows ?? [];
  const totalCount = (data as any)?.totalCount ?? (data as any)?.TotalCount ?? rows.length;
  const typedRows = rows as Contact[];

  /* ─── Dialog ─── */
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editId, setEditId] = useState<number | null>(null);
  const [form, setForm] = useState(emptyContact);
  const upsertContact = useUpsertContact();
  const deleteContact = useDeleteContact();

  const [deleteTarget, setDeleteTarget] = useState<Contact | null>(null);
  const [bulkDeleteIds, setBulkDeleteIds] = useState<Array<string | number>>([]);
  const [bulkDeleteOpen, setBulkDeleteOpen] = useState(false);

  /* ─── Columnas ─── */
  const columns: ColumnSpec[] = useMemo(
    () => [
      { field: "ContactId", header: "ID", width: 70 },
      {
        field: "FullName",
        header: "Nombre",
        flex: 1,
        minWidth: 180,
        renderCell: ((_v: unknown, row: unknown) => {
          const r = row as Contact;
          return `${r.FirstName ?? ""} ${r.LastName ?? ""}`.trim();
        }) as unknown,
      } as ColumnSpec,
      { field: "Email", header: "Email", width: 200 },
      { field: "Phone", header: "Teléfono", width: 130 },
      { field: "Mobile", header: "Móvil", width: 130 },
      { field: "Title", header: "Cargo", width: 140 },
      { field: "CompanyName", header: "Empresa", width: 180 },
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

  /* ─── Filtros ─── */
  const filterFields: FilterFieldDef[] = useMemo(
    () => [
      {
        field: "company",
        label: "Empresa",
        type: "select",
        options: (companies as Array<any>).map((c) => ({
          value: String(c.CrmCompanyId),
          label: c.Name,
        })),
      },
      {
        field: "active",
        label: "Estado",
        type: "select",
        options: [
          { value: "true", label: "Activos" },
          { value: "false", label: "Inactivos" },
        ],
      },
    ],
    [companies],
  );

  const filterValues: Record<string, string> = useMemo(
    () => ({
      company: filterFromUrl.company ?? "",
      active: filterFromUrl.active ?? "",
    }),
    [filterFromUrl],
  );

  const handleFilterChange = useCallback(
    (next: Record<string, string>) => {
      updateQuery({ company: next.company, active: next.active });
    },
    [updateQuery],
  );

  const handleSearchChange = useCallback(
    (v: string) => updateQuery({ search: v }),
    [updateQuery],
  );

  /* ─── Dialog handlers ─── */
  const handleOpenNew = useCallback(() => {
    setEditId(null);
    setForm(emptyContact);
    setDialogOpen(true);
  }, []);

  const handleEdit = useCallback((c: Contact) => {
    setEditId(c.ContactId);
    setForm({
      firstName: c.FirstName ?? "",
      lastName: c.LastName ?? "",
      email: c.Email ?? "",
      phone: c.Phone ?? "",
      mobile: c.Mobile ?? "",
      title: c.Title ?? "",
      department: c.Department ?? "",
      linkedIn: c.LinkedIn ?? "",
      notes: c.Notes ?? "",
      crmCompanyId: c.CrmCompanyId ?? "",
      isActive: c.IsActive,
    });
    setDialogOpen(true);
  }, []);

  const handleSave = useCallback(() => {
    const payload = {
      id: editId ?? undefined,
      firstName: form.firstName.trim(),
      lastName: form.lastName || undefined,
      email: form.email || undefined,
      phone: form.phone || undefined,
      mobile: form.mobile || undefined,
      title: form.title || undefined,
      department: form.department || undefined,
      linkedIn: form.linkedIn || undefined,
      notes: form.notes || undefined,
      crmCompanyId: form.crmCompanyId ? Number(form.crmCompanyId) : undefined,
      isActive: form.isActive,
    };
    upsertContact.mutate(payload, {
      onSuccess: () => {
        setDialogOpen(false);
        showToast(editId ? "Contacto actualizado" : "Contacto creado", "success");
      },
    });
  }, [editId, form, upsertContact, showToast]);

  /* ─── Row handlers ─── */
  const handleOpenRecord = useCallback(
    (id: string | number) => contactDrawer.openDrawer(id),
    [contactDrawer],
  );

  const handleActionClick = useCallback(
    (row: Contact, action: string) => {
      if (action === "view") contactDrawer.openDrawer(row.ContactId);
      else if (action === "edit") handleEdit(row);
      else if (action === "delete") setDeleteTarget(row);
    },
    [contactDrawer, handleEdit],
  );

  useEffect(() => {
    const el = document.querySelector<HTMLElement>(`zentto-grid[grid-id="${GRID_ID}"]`);
    if (!el) return;
    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail as { action?: string; row?: Contact };
      if (!detail?.action || !detail?.row) return;
      handleActionClick(detail.row, detail.action);
    };
    el.addEventListener("action-click", handler as EventListener);
    return () => el.removeEventListener("action-click", handler as EventListener);
  }, [handleActionClick]);

  /* ─── Delete ─── */
  const confirmDelete = useCallback(() => {
    if (!deleteTarget) return;
    deleteContact.mutate(deleteTarget.ContactId, {
      onSuccess: () => {
        showToast("Contacto eliminado", "success");
        setDeleteTarget(null);
      },
    });
  }, [deleteContact, deleteTarget, showToast]);

  const runBulkDelete = useCallback(async () => {
    const numeric = bulkDeleteIds.map((id) => Number(id));
    await Promise.all(numeric.map((id) => deleteContact.mutateAsync(id)));
    showToast(`${numeric.length} contactos eliminados`, "success");
    setBulkDeleteOpen(false);
    setBulkDeleteIds([]);
  }, [bulkDeleteIds, deleteContact, showToast]);

  const exportCsv = useCallback(
    (ids: Array<string | number>) => {
      const selected = typedRows.filter((r) => ids.includes(r.ContactId));
      if (!selected.length) return;
      const headers = ["ContactId", "FirstName", "LastName", "Email", "Phone", "Mobile", "Title", "CompanyName"];
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
      a.download = `crm-contactos-${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      showToast(`${selected.length} contactos exportados`, "success");
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

  /* ─── Render ─── */
  return (
    <ModulePageShell sx={{ flex: 1, display: "flex", flexDirection: "column", minHeight: 0 }}>
      <Box sx={{ flex: 1, minHeight: 0 }}>
        <ZenttoRecordTable
          recordType={RECORD_TYPE}
          gridId={GRID_ID}
          rowKey="ContactId"
          rows={typedRows as unknown as Record<string, unknown>[]}
          columns={columns}
          loading={isLoading}
          error={error ? String((error as any)?.message ?? error) : null}
          onRetry={() => refetch()}
          totalCount={totalCount}
          onOpenRecord={handleOpenRecord}
          onCreate={handleOpenNew}
          createLabel="Nuevo contacto"
          bulkActions={bulkActions}
          emptyState={{
            title: "Sin contactos todavía",
            description:
              "Crea tu primer contacto para empezar a construir tu base de clientes potenciales.",
            primaryAction: {
              label: "Crear primer contacto",
              onClick: handleOpenNew,
            },
            secondaryAction: {
              label: "Importar CSV",
              onClick: () => showToast("Importación CSV pendiente (follow-up)", "info"),
            },
          }}
          gridAttrs={{
            "export-filename": "crm-contactos-list",
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
              searchPlaceholder="Buscar contacto (nombre, email, teléfono…)"
              searchValue={filterFromUrl.search ?? ""}
              onSearchChange={handleSearchChange}
            />
          }
        />
      </Box>

      {/* Drawer detalle */}
      <RightDetailDrawer
        open={contactDrawer.open && drawerContactId !== null}
        onClose={contactDrawer.closeDrawer}
        title="Detalle del contacto"
        subtitle={drawerContactId ? `#${drawerContactId}` : undefined}
        width={{ desktop: 560 }}
      >
        {drawerContactId && (
          <ContactDetailPanel
            contactId={drawerContactId}
            onClose={contactDrawer.closeDrawer}
            onEdit={() => {
              const row = typedRows.find((r) => r.ContactId === drawerContactId);
              if (row) handleEdit(row);
            }}
          />
        )}
      </RightDetailDrawer>

      {/* FormDialog crear/editar */}
      <FormDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        title={editId ? "Editar contacto" : "Nuevo contacto"}
        mode={editId ? "edit" : "create"}
        onSave={handleSave}
        loading={upsertContact.isPending}
        disableSave={!form.firstName.trim()}
        saveLabel={editId ? "Guardar" : "Crear"}
      >
        <Stack spacing={2} sx={{ mt: 1 }}>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Nombre"
              fullWidth
              required
              value={form.firstName}
              onChange={(e) => setForm({ ...form, firstName: e.target.value })}
            />
            <TextField
              label="Apellido"
              fullWidth
              value={form.lastName}
              onChange={(e) => setForm({ ...form, lastName: e.target.value })}
            />
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
            <TextField
              label="Móvil"
              fullWidth
              value={form.mobile}
              onChange={(e) => setForm({ ...form, mobile: e.target.value })}
            />
          </Stack>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <TextField
              label="Cargo"
              fullWidth
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
            />
            <TextField
              label="Departamento"
              fullWidth
              value={form.department}
              onChange={(e) => setForm({ ...form, department: e.target.value })}
            />
          </Stack>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2}>
            <FormControl fullWidth>
              <InputLabel>Empresa</InputLabel>
              <Select
                value={form.crmCompanyId}
                label="Empresa"
                onChange={(e) =>
                  setForm({ ...form, crmCompanyId: e.target.value === "" ? "" : Number(e.target.value) })
                }
              >
                <MenuItem value="">Sin empresa</MenuItem>
                {(companies as Array<any>).map((c) => (
                  <MenuItem key={c.CrmCompanyId} value={c.CrmCompanyId}>
                    {c.Name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="LinkedIn"
              fullWidth
              value={form.linkedIn}
              onChange={(e) => setForm({ ...form, linkedIn: e.target.value })}
            />
          </Stack>
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

      {/* Delete individual */}
      <DeleteDialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        onConfirm={confirmDelete}
        itemName={
          deleteTarget
            ? `el contacto "${deleteTarget.FirstName} ${deleteTarget.LastName ?? ""}".trim()`
            : "este contacto"
        }
        loading={deleteContact.isPending}
      />

      {/* Bulk delete */}
      <DeleteDialog
        open={bulkDeleteOpen}
        onClose={() => setBulkDeleteOpen(false)}
        onConfirm={runBulkDelete}
        itemName={`${bulkDeleteIds.length} contacto${bulkDeleteIds.length === 1 ? "" : "s"}`}
        loading={deleteContact.isPending}
      />
    </ModulePageShell>
  );
}
