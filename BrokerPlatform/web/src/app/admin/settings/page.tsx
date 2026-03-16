"use client";
import { Box, Card, Typography, Stack, TextField, Button, Alert, CircularProgress, Divider, useTheme, alpha } from "@mui/material";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/lib/api";
import { useState } from "react";

export default function SettingsPage() {
    const theme = useTheme();
    const qc = useQueryClient();
    const { data: settings, isLoading } = useQuery({ queryKey: ["settings"], queryFn: () => api.get("/v1/settings") });
    const { data: commRules } = useQuery({ queryKey: ["commission-rules"], queryFn: () => api.get("/v1/settings/data/commission-rules") });
    const [editValues, setEditValues] = useState<Record<string, string>>({});
    const [success, setSuccess] = useState("");

    const updateSetting = useMutation({
        mutationFn: ({ key, value }: { key: string; value: string }) => api.put(`/v1/settings/${key}`, { value }),
        onSuccess: (_d, v) => { qc.invalidateQueries({ queryKey: ["settings"] }); setSuccess(`Setting "${v.key}" updated`); },
    });

    if (isLoading) return <CircularProgress />;

    const grouped = (settings || []).reduce((acc: Record<string, any[]>, s: any) => {
        (acc[s.category] = acc[s.category] || []).push(s);
        return acc;
    }, {});

    return (
        <Box>
            <Typography variant="h5" fontWeight={700} mb={3}>Settings</Typography>
            {success && <Alert severity="success" onClose={() => setSuccess("")} sx={{ mb: 2 }}>{success}</Alert>}

            {Object.entries(grouped).map(([cat, items]) => (
                <Card key={cat} sx={{ p: 3, mb: 3 }}>
                    <Typography variant="h6" fontWeight={600} gutterBottom sx={{ textTransform: "capitalize" }}>{cat}</Typography>
                    <Divider sx={{ mb: 2 }} />
                    <Stack gap={2}>
                        {(items as any[]).map((s: any) => (
                            <Stack key={s.key} direction="row" alignItems="center" gap={2}>
                                <Box sx={{ minWidth: 200 }}>
                                    <Typography variant="body2" fontWeight={600}>{s.key}</Typography>
                                    {s.description && <Typography variant="caption" color="text.secondary">{s.description}</Typography>}
                                </Box>
                                <TextField
                                    size="small"
                                    value={editValues[s.key] ?? s.value}
                                    onChange={(e) => setEditValues({ ...editValues, [s.key]: e.target.value })}
                                    sx={{ flex: 1 }}
                                />
                                <Button
                                    size="small"
                                    variant="outlined"
                                    disabled={editValues[s.key] === undefined || editValues[s.key] === s.value}
                                    onClick={() => updateSetting.mutate({ key: s.key, value: editValues[s.key] })}
                                >
                                    Save
                                </Button>
                            </Stack>
                        ))}
                    </Stack>
                </Card>
            ))}

            {/* Commission Rules */}
            {commRules && commRules.length > 0 && (
                <Card sx={{ p: 3 }}>
                    <Typography variant="h6" fontWeight={600} gutterBottom>Commission Rules</Typography>
                    <Divider sx={{ mb: 2 }} />
                    <Stack gap={1}>
                        {commRules.map((r: any) => (
                            <Stack key={r.id} direction="row" alignItems="center" gap={2} sx={{ p: 1, borderRadius: 1, bgcolor: alpha(theme.palette.background.default, 0.5) }}>
                                <Typography variant="body2" fontWeight={600} sx={{ minWidth: 120, textTransform: "capitalize" }}>{r.provider_type.replace("_", " ")}</Typography>
                                <Typography variant="body2" color="text.secondary">Min: {r.min_pct}%</Typography>
                                <Typography variant="body2" color="text.secondary">Max: {r.max_pct}%</Typography>
                                <Typography variant="body2" fontWeight={600} color="primary.main">Default: {r.default_pct}%</Typography>
                            </Stack>
                        ))}
                    </Stack>
                </Card>
            )}
        </Box>
    );
}
