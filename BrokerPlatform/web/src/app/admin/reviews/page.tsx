"use client";
import { GridColDef } from "@mui/x-data-grid";
import AdminCrudGrid from "@/components/admin/AdminCrudGrid";
import { Rating, Chip } from "@mui/material";

const columns: GridColDef[] = [
    { field: "id", headerName: "ID", width: 70 },
    { field: "property_name", headerName: "Property", flex: 1 },
    {
        field: "first_name", headerName: "Customer", width: 140,
        renderCell: (p) => `${p.row.first_name || ""} ${p.row.last_name || ""}`
    },
    {
        field: "rating", headerName: "Rating", width: 150,
        renderCell: (p) => <Rating value={p.value} readOnly size="small" />
    },
    { field: "title", headerName: "Title", width: 180 },
    { field: "comment", headerName: "Comment", flex: 1 },
    {
        field: "status", headerName: "Status", width: 100,
        renderCell: (p) => <Chip label={p.value} size="small" color={p.value === "published" ? "success" : "default"} sx={{ textTransform: "capitalize" }} />
    },
    {
        field: "created_at", headerName: "Date", width: 110,
        renderCell: (p) => p.value ? new Date(p.value).toLocaleDateString() : "—"
    },
];

export default function ReviewsPage() {
    return <AdminCrudGrid resource="reviews" title="Reviews" columns={columns} />;
}
