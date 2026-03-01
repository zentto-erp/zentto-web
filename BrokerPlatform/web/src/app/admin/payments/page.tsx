"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Chip } from "@mui/material";

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "booking_code", headerName: "Booking", width: 120 },
    {
        field: "customer_first", headerName: "Customer", width: 140,
        renderCell: (p) => `${p.row.customer_first || ""} ${p.row.customer_last || ""}`
    },
    {
        field: "amount", headerName: "Amount", width: 110, type: "number",
        renderCell: (p) => `$${p.value || 0}`
    },
    { field: "currency", headerName: "Curr.", width: 70 },
    {
        field: "payment_method", headerName: "Method", width: 110,
        renderCell: (p) => <Chip label={p.value} size="small" sx={{ textTransform: "capitalize" }} />
    },
    { field: "gateway_ref", headerName: "Ref.", width: 120 },
    {
        field: "status", headerName: "Status", width: 120,
        renderCell: (p) => <Chip label={p.value} size="small" color={p.value === "completed" ? "success" : p.value === "failed" ? "error" : "warning"} sx={{ textTransform: "capitalize" }} />
    },
    {
        field: "paid_at", headerName: "Paid At", width: 150,
        renderCell: (p) => p.value ? new Date(p.value).toLocaleString() : "—"
    },
];

export default function PaymentsPage() {
    return <AdminCrudGrid resource="payments" title="Payments" columns={columns} />;
}
