"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Chip } from "@mui/material";

const statusColors: Record<string, "success" | "warning" | "error" | "info" | "default"> = {
    pending: "warning", confirmed: "success", checked_in: "info", checked_out: "default", cancelled: "error", no_show: "error",
};

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "booking_code", headerName: "Code", width: 120 },
    {
        field: "customer_first", headerName: "Customer", width: 140,
        renderCell: (p) => `${p.row.customer_first || ""} ${p.row.customer_last || ""}`
    },
    { field: "property_name", headerName: "Property", flex: 1 },
    { field: "provider_name", headerName: "Provider", width: 150 },
    {
        field: "check_in", headerName: "Check In", width: 110,
        renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "—"
    },
    {
        field: "check_out", headerName: "Check Out", width: 110,
        renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "—"
    },
    { field: "guests", headerName: "Guests", width: 70, type: "number" },
    {
        field: "total_amount", headerName: "Total", width: 100, type: "number",
        renderCell: (p) => `$${p.value || 0}`
    },
    {
        field: "status", headerName: "Status", width: 120, editable: true,
        renderCell: (p) => <Chip label={p.value} size="small" color={statusColors[p.value] || "default"} sx={{ textTransform: "capitalize" }} />
    },
];

const createFields = [
    { name: "customer_id", label: "Customer ID", type: "number", required: true },
    { name: "property_id", label: "Property ID", type: "number", required: true },
    { name: "provider_id", label: "Provider ID", type: "number", required: true },
    { name: "check_in", label: "Check In (YYYY-MM-DD)", required: true },
    { name: "check_out", label: "Check Out (YYYY-MM-DD)", required: true },
    { name: "guests", label: "Guests", type: "number" },
    { name: "total_amount", label: "Total Amount", type: "number", required: true },
];

export default function BookingsPage() {
    return <AdminCrudGrid resource="bookings" title="Bookings" columns={columns} createFields={createFields} defaultValues={{ guests: "1", currency: "USD" }} />;
}
