"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Chip } from "@mui/material";

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "name", headerName: "Name", flex: 1, editable: true },
    {
        field: "type", headerName: "Type", width: 100, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" sx={{ textTransform: "capitalize" }} />
    },
    { field: "provider_name", headerName: "Provider", width: 160 },
    { field: "city", headerName: "City", width: 120, editable: true },
    { field: "country", headerName: "Country", width: 80, editable: true },
    { field: "max_guests", headerName: "Guests", width: 80, editable: true, type: "number" },
    {
        field: "base_price", headerName: "Price", width: 100, type: "number",
        renderCell: (p) => p.value ? `$${p.value}` : "—"
    },
    {
        field: "status", headerName: "Status", width: 100, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" color={p.value === "active" ? "success" : "default"} />
    },
];

const createFields = [
    { name: "provider_id", label: "Provider ID", type: "number", required: true },
    { name: "name", label: "Property Name", required: true },
    { name: "type", label: "Type (room/vehicle/boat/flight/unit)", required: true },
    { name: "description", label: "Description" },
    { name: "city", label: "City" },
    { name: "country", label: "Country Code" },
    { name: "max_guests", label: "Max Guests", type: "number" },
    { name: "address", label: "Address" },
];

export default function PropertiesPage() {
    return <AdminCrudGrid resource="properties" title="Properties" columns={columns} createFields={createFields} defaultValues={{ type: "room", max_guests: "2" }} />;
}
