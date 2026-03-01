"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Chip } from "@mui/material";

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "name", headerName: "Name", flex: 1, editable: true },
    {
        field: "type", headerName: "Type", width: 120, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" sx={{ textTransform: "capitalize" }} />
    },
    { field: "email", headerName: "Email", width: 200, editable: true },
    { field: "phone", headerName: "Phone", width: 140, editable: true },
    { field: "city", headerName: "City", width: 120, editable: true },
    { field: "country", headerName: "Country", width: 80, editable: true },
    { field: "commission_pct", headerName: "Comm %", width: 90, editable: true, type: "number" },
    { field: "rating", headerName: "Rating", width: 80, type: "number" },
    {
        field: "status", headerName: "Status", width: 100, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" color={p.value === "active" ? "success" : "default"} />
    },
    { field: "contact_person", headerName: "Contact", width: 140, editable: true },
];

const createFields = [
    { name: "name", label: "Provider Name", required: true },
    { name: "type", label: "Type (hotel/car_rental/marina/airline/lodge/tour)", required: true },
    { name: "email", label: "Email" },
    { name: "phone", label: "Phone" },
    { name: "tax_id", label: "Tax ID" },
    { name: "city", label: "City" },
    { name: "country", label: "Country Code (3-letter)" },
    { name: "contact_person", label: "Contact Person" },
    { name: "commission_pct", label: "Commission %", type: "number" },
];

export default function ProvidersPage() {
    return <AdminCrudGrid resource="providers" title="Providers" columns={columns} createFields={createFields} defaultValues={{ type: "hotel", commission_pct: "10" }} />;
}
