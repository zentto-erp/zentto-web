"use client";
import { useState, useCallback } from "react";
import { DataGrid, GridColDef, GridRowModel, GridToolbar } from "@mui/x-data-grid";
import { Box, Button, Typography, Stack, TextField, Dialog, DialogTitle, DialogContent, DialogActions, Alert, useTheme, alpha } from "@mui/material";
import AddIcon from "@mui/icons-material/Add";
import DeleteIcon from "@mui/icons-material/Delete";
import { useCrudList, useCrudCreate, useCrudUpdate, useCrudDelete } from "@/hooks/useApi";

type Props = {
    resource: string;
    title: string;
    columns: GridColDef[];
    defaultValues?: Record<string, unknown>;
    createFields?: Array<{ name: string; label: string; type?: string; required?: boolean }>;
    queryParams?: Record<string, string>;
};

export default function AdminCrudGrid({ resource, title, columns, defaultValues = {}, createFields = [], queryParams }: Props) {
    const theme = useTheme();
    const [page, setPage] = useState(0);
    const [pageSize, setPageSize] = useState(25);
    const [search, setSearch] = useState("");
    const [createOpen, setCreateOpen] = useState(false);
    const [formData, setFormData] = useState<Record<string, unknown>>(defaultValues);
    const [error, setError] = useState("");

    const params: Record<string, string> = {
        page: String(page + 1),
        limit: String(pageSize),
        ...queryParams,
    };
    if (search) params.search = search;

    const { data, isLoading } = useCrudList(resource, params);
    const createMutation = useCrudCreate(resource);
    const updateMutation = useCrudUpdate(resource);
    const deleteMutation = useCrudDelete(resource);

    const processRowUpdate = useCallback(async (newRow: GridRowModel, oldRow: GridRowModel) => {
        try {
            await updateMutation.mutateAsync({ id: newRow.id, ...newRow });
            return newRow;
        } catch (err) {
            setError(String(err));
            return oldRow;
        }
    }, [updateMutation]);

    const handleCreate = async () => {
        try {
            setError("");
            await createMutation.mutateAsync(formData);
            setCreateOpen(false);
            setFormData(defaultValues);
        } catch (err: any) {
            setError(err.message || String(err));
        }
    };

    const handleDelete = async (id: number | string) => {
        if (!confirm("Are you sure you want to delete this record?")) return;
        try {
            await deleteMutation.mutateAsync(id);
        } catch (err: any) {
            setError(err.message || String(err));
        }
    };

    const allColumns: GridColDef[] = [
        ...columns,
        {
            field: "actions",
            headerName: "",
            width: 80,
            sortable: false,
            filterable: false,
            renderCell: (params) => (
                <Button size="small" color="error" onClick={() => handleDelete(params.row.id)} sx={{ minWidth: 32 }}>
                    <DeleteIcon fontSize="small" />
                </Button>
            ),
        },
    ];

    return (
        <Box>
            <Stack direction="row" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h5" fontWeight={700}>{title}</Typography>
                <Stack direction="row" gap={1}>
                    <TextField size="small" placeholder="Search..." value={search} onChange={(e) => setSearch(e.target.value)} sx={{ width: 200 }} />
                    {createFields.length > 0 && (
                        <Button variant="contained" startIcon={<AddIcon />} onClick={() => setCreateOpen(true)}>New</Button>
                    )}
                </Stack>
            </Stack>

            {error && <Alert severity="error" onClose={() => setError("")} sx={{ mb: 2 }}>{error}</Alert>}

            <Box sx={{ height: 600, bgcolor: alpha(theme.palette.background.paper, 0.5), borderRadius: 2, border: "1px solid rgba(255,255,255,0.06)" }}>
                <DataGrid
                    rows={data?.rows || []}
                    columns={allColumns}
                    rowCount={data?.total || 0}
                    loading={isLoading}
                    pageSizeOptions={[10, 25, 50, 100]}
                    paginationMode="server"
                    paginationModel={{ page, pageSize }}
                    onPaginationModelChange={(m) => { setPage(m.page); setPageSize(m.pageSize); }}
                    processRowUpdate={processRowUpdate}
                    onProcessRowUpdateError={(err) => setError(String(err))}
                    disableRowSelectionOnClick
                    slots={{ toolbar: GridToolbar }}
                    slotProps={{ toolbar: { showQuickFilter: false } }}
                    sx={{
                        border: "none",
                        "& .MuiDataGrid-cell": { borderColor: "rgba(255,255,255,0.04)" },
                        "& .MuiDataGrid-columnHeaders": { bgcolor: alpha(theme.palette.primary.main, 0.05), borderColor: "rgba(255,255,255,0.06)" },
                        "& .MuiDataGrid-row:hover": { bgcolor: alpha(theme.palette.primary.main, 0.04) },
                    }}
                />
            </Box>

            {/* Create Dialog */}
            <Dialog open={createOpen} onClose={() => setCreateOpen(false)} maxWidth="sm" fullWidth PaperProps={{ sx: { bgcolor: "background.paper", backgroundImage: "none" } }}>
                <DialogTitle>Create {title.replace(/s$/, "")}</DialogTitle>
                <DialogContent>
                    <Stack gap={2} pt={1}>
                        {createFields.map((f) => (
                            <TextField
                                key={f.name}
                                label={f.label}
                                type={f.type || "text"}
                                required={f.required}
                                value={formData[f.name] ?? ""}
                                onChange={(e) => setFormData({ ...formData, [f.name]: e.target.value })}
                                fullWidth
                                size="small"
                            />
                        ))}
                    </Stack>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setCreateOpen(false)}>Cancel</Button>
                    <Button variant="contained" onClick={handleCreate} disabled={createMutation.isPending}>
                        {createMutation.isPending ? "Creating..." : "Create"}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
}
