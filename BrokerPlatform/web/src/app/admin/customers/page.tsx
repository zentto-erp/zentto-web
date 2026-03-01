"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Chip } from "@mui/material";

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "first_name", headerName: "First Name", width: 130, editable: true },
    { field: "last_name", headerName: "Last Name", width: 130, editable: true },
    { field: "email", headerName: "Email", flex: 1, editable: true },
    { field: "phone", headerName: "Phone", width: 140, editable: true },
    { field: "document_type", headerName: "Doc Type", width: 100, editable: true },
    { field: "document_number", headerName: "Doc #", width: 120, editable: true },
    { field: "nationality", headerName: "Nat.", width: 70 },
    { field: "city", headerName: "City", width: 120, editable: true },
    { field: "loyalty_points", headerName: "Points", width: 80, type: "number", editable: true },
    {
        field: "status", headerName: "Status", width: 100, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" color={p.value === "active" ? "success" : "default"} />
    },
];

const createFields = [
    { name: "first_name", label: "First Name", required: true },
    { name: "last_name", label: "Last Name", required: true },
    { name: "email", label: "Email" },
    { name: "phone", label: "Phone" },
    { name: "document_type", label: "Document Type (passport/id_card)" },
    { name: "document_number", label: "Document Number" },
    { name: "nationality", label: "Nationality (3-letter code)" },
    { name: "city", label: "City" },
];

export default function CustomersPage() {
    return <AdminCrudGrid resource="customers" title="Customers" columns={columns} createFields={createFields} />;
}
