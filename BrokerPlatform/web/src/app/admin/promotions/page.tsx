"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Chip } from "@mui/material";

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "name", headerName: "Promotion Name", flex: 1, editable: true },
    { field: "provider_name", headerName: "Provider", width: 160 },
    { field: "property_name", headerName: "Property", width: 160 },
    { field: "discount_pct", headerName: "Disc %", width: 80, type: "number", editable: true },
    { field: "discount_amount", headerName: "Disc $", width: 80, type: "number", editable: true },
    { field: "promo_code", headerName: "Code", width: 120, editable: true },
    {
        field: "valid_from", headerName: "From", width: 110,
        renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "—"
    },
    {
        field: "valid_to", headerName: "To", width: 110,
        renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "—"
    },
    { field: "usage_limit", headerName: "Limit", width: 70, type: "number" },
    { field: "times_used", headerName: "Used", width: 70, type: "number" },
    {
        field: "status", headerName: "Status", width: 100, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" color={p.value === "active" ? "success" : "default"} sx={{ textTransform: "capitalize" }} />
    },
];

const createFields = [
    { name: "name", label: "Promotion Name", required: true },
    { name: "provider_id", label: "Provider ID", type: "number" },
    { name: "property_id", label: "Property ID (optional)", type: "number" },
    { name: "discount_pct", label: "Discount %", type: "number" },
    { name: "discount_amount", label: "Discount Amount", type: "number" },
    { name: "promo_code", label: "Promo Code" },
    { name: "valid_from", label: "Valid From (YYYY-MM-DD)", required: true },
    { name: "valid_to", label: "Valid To (YYYY-MM-DD)", required: true },
    { name: "usage_limit", label: "Usage Limit", type: "number" },
];

export default function PromotionsPage() {
    return <AdminCrudGrid resource="promotions" title="Promotions" columns={columns} createFields={createFields} defaultValues={{ discount_pct: "0", discount_amount: "0", usage_limit: "0" }} />;
}
