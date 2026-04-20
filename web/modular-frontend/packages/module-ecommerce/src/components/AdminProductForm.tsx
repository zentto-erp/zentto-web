"use client";

/**
 * AdminProductForm — formulario tabs para crear/editar producto del store.
 * Tabs: Info básica | Descripción y SEO | Galería | Highlights | Specs | Reseñas
 *
 * Reutilizable desde /admin/productos/nuevo y /admin/productos/[code]/editar.
 */

import React, { useEffect, useMemo, useState } from "react";
import {
    Box, Tabs, Tab, TextField, Typography, Paper, Button, Stack,
    FormControlLabel, Switch, MenuItem, IconButton, Chip, Alert, CircularProgress,
} from "@mui/material";
import DeleteIcon from "@mui/icons-material/Delete";
import StarIcon from "@mui/icons-material/Star";
import StarBorderIcon from "@mui/icons-material/StarBorder";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import ArrowUpwardIcon from "@mui/icons-material/ArrowUpward";
import ArrowDownwardIcon from "@mui/icons-material/ArrowDownward";
import SaveIcon from "@mui/icons-material/Save";
import AddIcon from "@mui/icons-material/Add";
import { FormGrid, FormField } from "@zentto/shared-ui";
import {
    useAdminProductDetail,
    useUpsertAdminProduct,
} from "../hooks/useAdminProducts";
import {
    useSetProductImages,
    useUploadProductImage,
    type ProductImageInput,
} from "../hooks/useAdminImages";
import { useSetProductHighlights, type HighlightInput } from "../hooks/useAdminHighlights";
import { useSetProductSpecs, type SpecInput } from "../hooks/useAdminSpecs";
import { useAdminCategories } from "../hooks/useAdminCategories";
import { useAdminBrands } from "../hooks/useAdminBrands";

interface Props {
    code?: string;  // presente si es edición
    onSaved?: (code: string) => void;
}

interface Basic {
    code: string;
    name: string;
    category?: string;
    brand?: string;
    price: number;
    compareAtPrice?: number;
    costPrice?: number;
    stockQty?: number;
    barcode?: string;
    unitCode?: string;
    taxRate?: number;
    weightKg?: number;
    isService?: boolean;
    isPublished?: boolean;
    shortDescription?: string;
    longDescription?: string;
    metaTitle?: string;
    metaDescription?: string;
    slug?: string;
}

export default function AdminProductForm({ code, onSaved }: Props) {
    const [tab, setTab] = useState(0);
    const { data: detail, isLoading: detailLoading } = useAdminProductDetail(code);
    const { data: catData } = useAdminCategories();
    const { data: brandData } = useAdminBrands();

    const upsertMut = useUpsertAdminProduct();
    const imagesMut = useSetProductImages();
    const highlightsMut = useSetProductHighlights();
    const specsMut = useSetProductSpecs();
    const uploadMut = useUploadProductImage();

    const [basic, setBasic] = useState<Basic>({
        code: "",
        name: "",
        price: 0,
        compareAtPrice: undefined,
        costPrice: 0,
        stockQty: 0,
        unitCode: "UND",
        taxRate: 0,
        isService: false,
        isPublished: false,
    });
    const [images, setImages] = useState<ProductImageInput[]>([]);
    const [highlights, setHighlights] = useState<HighlightInput[]>([]);
    const [specs, setSpecs] = useState<SpecInput[]>([]);
    const [savedMessage, setSavedMessage] = useState<string | null>(null);

    // Cargar detalle existente
    useEffect(() => {
        if (!detail) return;
        setBasic({
            code: detail.code ?? "",
            name: detail.name ?? "",
            category: detail.category ?? "",
            brand: detail.brandCode ?? "",
            price: Number(detail.price ?? 0),
            compareAtPrice: detail.compareAtPrice ?? undefined,
            costPrice: Number(detail.costPrice ?? 0),
            stockQty: Number(detail.stock ?? 0),
            barcode: (detail as any).barCode ?? "",
            unitCode: (detail as any).unitCode ?? "UND",
            taxRate: Number((detail as any).taxRate ?? 0),
            weightKg: (detail as any).weightKg ?? undefined,
            isService: Boolean(detail.isService),
            isPublished: Boolean(detail.isPublished),
            shortDescription: detail.shortDescription ?? "",
            longDescription: detail.longDescription ?? "",
            metaTitle: detail.metaTitle ?? "",
            metaDescription: detail.metaDescription ?? "",
            slug: detail.slug ?? "",
        });
        setImages((detail.images ?? []).map((i: any) => ({
            url: i.url,
            altText: i.altText ?? null,
            role: i.role ?? null,
            isPrimary: Boolean(i.isPrimary),
            sortOrder: i.sortOrder ?? 0,
        })));
        setHighlights((detail.highlights ?? []).map((h: any, i: number) => ({
            text: h.text ?? "",
            sortOrder: h.sortOrder ?? i,
        })));
        setSpecs((detail.specs ?? []).map((s: any, i: number) => ({
            group: s.group ?? "General",
            key: s.key ?? "",
            value: s.value ?? "",
            sortOrder: s.sortOrder ?? i,
        })));
    }, [detail]);

    const isEdit = Boolean(code);
    const canSave = basic.code.trim().length > 0 && basic.name.trim().length > 0;

    const saveBasic = async () => {
        setSavedMessage(null);
        const res = await upsertMut.mutateAsync({
            ...basic,
            isUpdate: isEdit,
        });
        if ((res as any)?.ok) {
            setSavedMessage("Datos guardados");
            if (!isEdit && onSaved) onSaved(basic.code);
        }
    };

    const saveImages = async () => {
        if (!basic.code) return;
        const res = await imagesMut.mutateAsync({ code: basic.code, images });
        if ((res as any)?.ok) setSavedMessage(`${(res as any).count} imagen(es) guardadas`);
    };

    const saveHighlights = async () => {
        if (!basic.code) return;
        const res = await highlightsMut.mutateAsync({ code: basic.code, highlights });
        if ((res as any)?.ok) setSavedMessage("Highlights guardados");
    };

    const saveSpecs = async () => {
        if (!basic.code) return;
        const res = await specsMut.mutateAsync({ code: basic.code, specs });
        if ((res as any)?.ok) setSavedMessage("Especificaciones guardadas");
    };

    const handleFileUpload = async (files: FileList | null) => {
        if (!files || files.length === 0) return;
        const uploaded: ProductImageInput[] = [];
        for (let i = 0; i < files.length; i++) {
            const file = files[i]!;
            const res = await uploadMut.mutateAsync(file);
            if ((res as any)?.url) {
                uploaded.push({
                    url: (res as any).url,
                    altText: file.name,
                    role: "PRODUCT_IMAGE",
                    isPrimary: images.length === 0 && uploaded.length === 0,
                    sortOrder: images.length + uploaded.length,
                    storageKey: (res as any).storageKey,
                    storageProvider: (res as any).storageProvider,
                    mimeType: (res as any).mimeType,
                    originalFileName: file.name,
                });
            }
        }
        setImages((prev) => [...prev, ...uploaded]);
    };

    const moveImage = (idx: number, delta: number) => {
        setImages((prev) => {
            const out = [...prev];
            const target = idx + delta;
            if (target < 0 || target >= out.length) return prev;
            [out[idx], out[target]] = [out[target]!, out[idx]!];
            return out.map((img, i) => ({ ...img, sortOrder: i }));
        });
    };

    const setPrimary = (idx: number) => {
        setImages((prev) => prev.map((img, i) => ({ ...img, isPrimary: i === idx })));
    };

    const removeImage = (idx: number) => {
        setImages((prev) => prev.filter((_, i) => i !== idx).map((img, i) => ({ ...img, sortOrder: i })));
    };

    if (isEdit && detailLoading) {
        return <Box sx={{ display: "flex", justifyContent: "center", mt: 10 }}><CircularProgress /></Box>;
    }

    return (
        <Box>
            {savedMessage && (
                <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSavedMessage(null)}>
                    {savedMessage}
                </Alert>
            )}
            {(upsertMut.error || imagesMut.error || highlightsMut.error || specsMut.error) && (
                <Alert severity="error" sx={{ mb: 2 }}>
                    {String((upsertMut.error as any)?.message || (imagesMut.error as any)?.message || (highlightsMut.error as any)?.message || (specsMut.error as any)?.message)}
                </Alert>
            )}

            <Paper sx={{ p: 2 }}>
                <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: "divider", mb: 2 }}>
                    <Tab label="Información básica" />
                    <Tab label="Descripción y SEO" />
                    <Tab label="Galería" disabled={!isEdit && !basic.code} />
                    <Tab label="Highlights" disabled={!isEdit && !basic.code} />
                    <Tab label="Specs" disabled={!isEdit && !basic.code} />
                    <Tab label="Reseñas" disabled={!isEdit} />
                </Tabs>

                {/* Tab 0 — Info básica */}
                {tab === 0 && (
                    <FormGrid spacing={2}>
                        <FormField xs={12} sm={6}>
                            <TextField label="Código" fullWidth required value={basic.code}
                                disabled={isEdit}
                                onChange={(e) => setBasic({ ...basic, code: e.target.value })}
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField label="Nombre" fullWidth required value={basic.name}
                                onChange={(e) => setBasic({ ...basic, name: e.target.value })}
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField select label="Categoría" fullWidth value={basic.category ?? ""}
                                onChange={(e) => setBasic({ ...basic, category: e.target.value })}
                            >
                                <MenuItem value="">(Sin categoría)</MenuItem>
                                {(catData?.rows ?? []).map((c: any) => (
                                    <MenuItem key={c.code} value={c.code}>{c.name}</MenuItem>
                                ))}
                            </TextField>
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField select label="Marca" fullWidth value={basic.brand ?? ""}
                                onChange={(e) => setBasic({ ...basic, brand: e.target.value })}
                            >
                                <MenuItem value="">(Sin marca)</MenuItem>
                                {(brandData?.rows ?? []).map((b: any) => (
                                    <MenuItem key={b.code} value={b.code}>{b.name}</MenuItem>
                                ))}
                            </TextField>
                        </FormField>
                        <FormField xs={12} sm={4}>
                            <TextField label="Precio" type="number" fullWidth value={basic.price}
                                onChange={(e) => setBasic({ ...basic, price: Number(e.target.value) })}
                            />
                        </FormField>
                        <FormField xs={12} sm={4}>
                            <TextField label="Precio tachado" type="number" fullWidth value={basic.compareAtPrice ?? ""}
                                onChange={(e) => setBasic({ ...basic, compareAtPrice: e.target.value ? Number(e.target.value) : undefined })}
                            />
                        </FormField>
                        <FormField xs={12} sm={4}>
                            <TextField label="Costo" type="number" fullWidth value={basic.costPrice ?? 0}
                                onChange={(e) => setBasic({ ...basic, costPrice: Number(e.target.value) })}
                            />
                        </FormField>
                        <FormField xs={12} sm={4}>
                            <TextField label="Stock" type="number" fullWidth value={basic.stockQty ?? 0}
                                onChange={(e) => setBasic({ ...basic, stockQty: Number(e.target.value) })}
                            />
                        </FormField>
                        <FormField xs={12} sm={4}>
                            <TextField label="Unidad" fullWidth value={basic.unitCode ?? "UND"}
                                onChange={(e) => setBasic({ ...basic, unitCode: e.target.value })}
                            />
                        </FormField>
                        <FormField xs={12} sm={4}>
                            <TextField label="Tasa impuesto (%)" type="number" fullWidth value={basic.taxRate ?? 0}
                                onChange={(e) => setBasic({ ...basic, taxRate: Number(e.target.value) })}
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField label="Código de barras" fullWidth value={basic.barcode ?? ""}
                                onChange={(e) => setBasic({ ...basic, barcode: e.target.value })}
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField label="Peso (kg)" type="number" fullWidth value={basic.weightKg ?? ""}
                                onChange={(e) => setBasic({ ...basic, weightKg: e.target.value ? Number(e.target.value) : undefined })}
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <FormControlLabel
                                control={<Switch checked={!!basic.isService}
                                    onChange={(e) => setBasic({ ...basic, isService: e.target.checked })} />}
                                label="Es un servicio (no descuenta stock)"
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <FormControlLabel
                                control={<Switch checked={!!basic.isPublished}
                                    onChange={(e) => setBasic({ ...basic, isPublished: e.target.checked })} />}
                                label="Publicar en el store"
                            />
                        </FormField>
                    </FormGrid>
                )}

                {/* Tab 1 — Descripción y SEO */}
                {tab === 1 && (
                    <FormGrid spacing={2}>
                        <FormField xs={12}>
                            <TextField label="Descripción corta" fullWidth multiline minRows={2}
                                value={basic.shortDescription ?? ""}
                                onChange={(e) => setBasic({ ...basic, shortDescription: e.target.value })}
                                inputProps={{ maxLength: 500 }}
                                helperText={`${(basic.shortDescription ?? "").length} / 500`}
                            />
                        </FormField>
                        <FormField xs={12}>
                            <TextField label="Descripción larga" fullWidth multiline minRows={6}
                                value={basic.longDescription ?? ""}
                                onChange={(e) => setBasic({ ...basic, longDescription: e.target.value })}
                            />
                        </FormField>
                        <FormField xs={12}>
                            <Typography variant="subtitle2" sx={{ mt: 2, color: '#666' }}>SEO</Typography>
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField label="Meta Title" fullWidth value={basic.metaTitle ?? ""}
                                onChange={(e) => setBasic({ ...basic, metaTitle: e.target.value })}
                                inputProps={{ maxLength: 200 }}
                                helperText={`${(basic.metaTitle ?? "").length} / 200`}
                            />
                        </FormField>
                        <FormField xs={12} sm={6}>
                            <TextField label="Slug" fullWidth value={basic.slug ?? ""}
                                onChange={(e) => setBasic({ ...basic, slug: e.target.value })}
                                inputProps={{ maxLength: 200 }}
                                helperText="URL-friendly. Único por compañía."
                            />
                        </FormField>
                        <FormField xs={12}>
                            <TextField label="Meta Description" fullWidth multiline minRows={2}
                                value={basic.metaDescription ?? ""}
                                onChange={(e) => setBasic({ ...basic, metaDescription: e.target.value })}
                                inputProps={{ maxLength: 320 }}
                                helperText={`${(basic.metaDescription ?? "").length} / 320`}
                            />
                        </FormField>
                    </FormGrid>
                )}

                {/* Tab 2 — Galería */}
                {tab === 2 && (
                    <Box>
                        <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
                            <Button
                                component="label"
                                variant="outlined"
                                startIcon={<UploadFileIcon />}
                                disabled={uploadMut.isPending}
                            >
                                {uploadMut.isPending ? "Subiendo…" : "Subir imágenes"}
                                <input
                                    type="file"
                                    hidden
                                    accept="image/*"
                                    multiple
                                    onChange={(e) => handleFileUpload(e.target.files)}
                                />
                            </Button>
                            <Typography variant="caption" color="text.secondary">
                                JPG / PNG / WebP. Tamaño máximo: 5 MB por imagen.
                            </Typography>
                        </Stack>

                        <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: 2 }}>
                            {images.map((img, idx) => (
                                <Paper key={`${img.url}-${idx}`} sx={{ p: 1, position: "relative" }}>
                                    <Box
                                        component="img"
                                        src={img.url}
                                        alt={img.altText ?? ""}
                                        sx={{ width: "100%", height: 140, objectFit: "cover", borderRadius: 1 }}
                                    />
                                    <TextField
                                        size="small"
                                        label="Alt text"
                                        fullWidth
                                        value={img.altText ?? ""}
                                        onChange={(e) =>
                                            setImages((prev) => prev.map((im, i) => (i === idx ? { ...im, altText: e.target.value } : im)))
                                        }
                                        sx={{ mt: 1 }}
                                    />
                                    <Stack direction="row" spacing={0.5} justifyContent="space-between" sx={{ mt: 1 }}>
                                        <IconButton size="small" onClick={() => setPrimary(idx)}
                                            color={img.isPrimary ? "warning" : "default"}
                                            title="Marcar como principal"
                                        >
                                            {img.isPrimary ? <StarIcon fontSize="small" /> : <StarBorderIcon fontSize="small" />}
                                        </IconButton>
                                        <IconButton size="small" onClick={() => moveImage(idx, -1)} disabled={idx === 0}>
                                            <ArrowUpwardIcon fontSize="small" />
                                        </IconButton>
                                        <IconButton size="small" onClick={() => moveImage(idx, 1)} disabled={idx === images.length - 1}>
                                            <ArrowDownwardIcon fontSize="small" />
                                        </IconButton>
                                        <IconButton size="small" color="error" onClick={() => removeImage(idx)}>
                                            <DeleteIcon fontSize="small" />
                                        </IconButton>
                                    </Stack>
                                </Paper>
                            ))}
                        </Box>
                        {images.length === 0 && (
                            <Typography color="text.secondary" sx={{ textAlign: "center", py: 4 }}>
                                Aún no has subido imágenes para este producto.
                            </Typography>
                        )}
                    </Box>
                )}

                {/* Tab 3 — Highlights */}
                {tab === 3 && (
                    <Box>
                        <Stack spacing={1}>
                            {highlights.map((h, idx) => (
                                <Stack direction="row" spacing={1} key={idx} alignItems="center">
                                    <TextField
                                        size="small"
                                        fullWidth
                                        placeholder="Ej. Envío gratis a todo el país"
                                        value={h.text}
                                        onChange={(e) =>
                                            setHighlights((prev) => prev.map((x, i) => (i === idx ? { ...x, text: e.target.value } : x)))
                                        }
                                        inputProps={{ maxLength: 500 }}
                                    />
                                    <IconButton size="small" color="error"
                                        onClick={() => setHighlights((prev) => prev.filter((_, i) => i !== idx))}
                                    >
                                        <DeleteIcon fontSize="small" />
                                    </IconButton>
                                </Stack>
                            ))}
                            <Button
                                startIcon={<AddIcon />}
                                onClick={() => setHighlights((prev) => [...prev, { text: "", sortOrder: prev.length }])}
                            >
                                Añadir highlight
                            </Button>
                        </Stack>
                    </Box>
                )}

                {/* Tab 4 — Specs */}
                {tab === 4 && (
                    <Box>
                        <Stack spacing={1}>
                            {specs.map((s, idx) => (
                                <Stack direction="row" spacing={1} key={idx} alignItems="center">
                                    <TextField
                                        size="small"
                                        label="Grupo"
                                        value={s.group ?? "General"}
                                        onChange={(e) =>
                                            setSpecs((prev) => prev.map((x, i) => (i === idx ? { ...x, group: e.target.value } : x)))
                                        }
                                        sx={{ width: 160 }}
                                    />
                                    <TextField
                                        size="small"
                                        label="Atributo"
                                        value={s.key}
                                        onChange={(e) =>
                                            setSpecs((prev) => prev.map((x, i) => (i === idx ? { ...x, key: e.target.value } : x)))
                                        }
                                        sx={{ width: 200 }}
                                    />
                                    <TextField
                                        size="small"
                                        label="Valor"
                                        fullWidth
                                        value={s.value}
                                        onChange={(e) =>
                                            setSpecs((prev) => prev.map((x, i) => (i === idx ? { ...x, value: e.target.value } : x)))
                                        }
                                    />
                                    <IconButton size="small" color="error"
                                        onClick={() => setSpecs((prev) => prev.filter((_, i) => i !== idx))}
                                    >
                                        <DeleteIcon fontSize="small" />
                                    </IconButton>
                                </Stack>
                            ))}
                            <Button
                                startIcon={<AddIcon />}
                                onClick={() => setSpecs((prev) => [...prev, { group: "General", key: "", value: "", sortOrder: prev.length }])}
                            >
                                Añadir especificación
                            </Button>
                        </Stack>
                    </Box>
                )}

                {/* Tab 5 — Reseñas */}
                {tab === 5 && (
                    <Box>
                        <Alert severity="info">
                            Usa la sección <b>Contenido → Reseñas</b> del sidebar para moderar las reseñas de este y todos los productos.
                        </Alert>
                    </Box>
                )}

                {/* Save bar */}
                <Stack direction="row" spacing={2} sx={{ mt: 3, pt: 2, borderTop: "1px solid #eee" }}>
                    {tab === 0 || tab === 1 ? (
                        <Button
                            variant="contained"
                            startIcon={<SaveIcon />}
                            onClick={saveBasic}
                            disabled={!canSave || upsertMut.isPending}
                            sx={{ bgcolor: "#ff9900", "&:hover": { bgcolor: "#e68a00" } }}
                        >
                            {upsertMut.isPending ? "Guardando…" : "Guardar"}
                        </Button>
                    ) : null}
                    {tab === 2 && (
                        <Button
                            variant="contained"
                            startIcon={<SaveIcon />}
                            onClick={saveImages}
                            disabled={imagesMut.isPending}
                        >
                            {imagesMut.isPending ? "Guardando…" : "Guardar galería"}
                        </Button>
                    )}
                    {tab === 3 && (
                        <Button
                            variant="contained"
                            startIcon={<SaveIcon />}
                            onClick={saveHighlights}
                            disabled={highlightsMut.isPending}
                        >
                            {highlightsMut.isPending ? "Guardando…" : "Guardar highlights"}
                        </Button>
                    )}
                    {tab === 4 && (
                        <Button
                            variant="contained"
                            startIcon={<SaveIcon />}
                            onClick={saveSpecs}
                            disabled={specsMut.isPending}
                        >
                            {specsMut.isPending ? "Guardando…" : "Guardar specs"}
                        </Button>
                    )}
                </Stack>
            </Paper>
        </Box>
    );
}
