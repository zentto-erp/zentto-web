"use client";

/**
 * AdminProductForm — formulario tabs para crear/editar producto del store.
 *
 * Designer Ola 2:
 *   - Orden canónico de tabs: Info → SEO → Galería → Highlights → Specs → Variantes → Reviews
 *   - Layout 8/12 (panel principal) + 4/12 (sidebar sticky derecho con
 *     Estado, Organización, Precio, Inventario).
 *   - Galería: drop-zone 2px dashed (border-color hover naranja) + alt-text
 *     obligatorio por WCAG (si falta, el guardado se bloquea con mensaje claro).
 *   - Tokens: radius 8px, shadows MUI default elevation=1.
 */

import React, { useEffect, useMemo, useRef, useState } from "react";
import {
    Box, Tabs, Tab, TextField, Typography, Paper, Button, Stack, Grid,
    FormControlLabel, Switch, MenuItem, IconButton, Chip, Alert, CircularProgress,
    Autocomplete,
} from "@mui/material";
import DeleteIcon from "@mui/icons-material/Delete";
import StarIcon from "@mui/icons-material/Star";
import StarBorderIcon from "@mui/icons-material/StarBorder";
import UploadFileIcon from "@mui/icons-material/UploadFile";
import ArrowUpwardIcon from "@mui/icons-material/ArrowUpward";
import ArrowDownwardIcon from "@mui/icons-material/ArrowDownward";
import SaveIcon from "@mui/icons-material/Save";
import AddIcon from "@mui/icons-material/Add";
import CloudUploadIcon from "@mui/icons-material/CloudUpload";
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

// Orden canónico de tabs — designer Ola 2 §2.2
const TABS = [
    { id: "info", label: "Info" },
    { id: "seo", label: "SEO" },
    { id: "gallery", label: "Galería" },
    { id: "highlights", label: "Highlights" },
    { id: "specs", label: "Specs" },
    { id: "variants", label: "Variantes" },
    { id: "reviews", label: "Reviews" },
] as const;

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
    const [dragActive, setDragActive] = useState(false);

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

    // WCAG — alt-text obligatorio en cada imagen; bloquea guardado global de
    // galería si alguno está vacío.
    const missingAltImages = useMemo(
        () => images.filter((img) => !(img.altText ?? "").trim()).length,
        [images]
    );
    const canSaveGallery = images.length > 0 && missingAltImages === 0;

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
        if (missingAltImages > 0) {
            setSavedMessage(null);
            return; // UI muestra alert bloqueante
        }
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
                    altText: "", // el usuario debe completar — obligatorio por WCAG
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

    // ═══ Sidebar derecho — sticky (md+) con Estado / Organización / Precio / Inventario ═══
    const renderSidebar = () => (
        <Stack spacing={2} sx={{ position: { md: "sticky" }, top: 80 }}>
            <Paper elevation={1} sx={{ p: 2, borderRadius: 2 }}>
                <Typography variant="overline" color="text.secondary">Estado</Typography>
                <FormControlLabel
                    sx={{ mt: 0.5 }}
                    control={
                        <Switch
                            checked={!!basic.isPublished}
                            onChange={(e) => setBasic({ ...basic, isPublished: e.target.checked })}
                        />
                    }
                    label={basic.isPublished ? "Publicado" : "Borrador"}
                />
            </Paper>

            <Paper elevation={1} sx={{ p: 2, borderRadius: 2 }}>
                <Typography variant="overline" color="text.secondary">Organización</Typography>
                <Stack spacing={1.5} sx={{ mt: 1 }}>
                    <Autocomplete
                        size="small"
                        fullWidth
                        options={(catData?.rows ?? []) as Array<{ code: string; name: string }>}
                        getOptionLabel={(o) => o.name ?? ""}
                        isOptionEqualToValue={(opt, val) => opt.code === val.code}
                        value={(catData?.rows ?? []).find((c: any) => c.code === basic.category) ?? null}
                        onChange={(_, v) => setBasic({ ...basic, category: v?.code ?? "" })}
                        renderInput={(params) => <TextField {...params} label="Categoría" placeholder="Buscar categoría..." />}
                        noOptionsText="Sin resultados"
                        clearOnEscape
                    />
                    <Autocomplete
                        size="small"
                        fullWidth
                        options={(brandData?.rows ?? []) as Array<{ code: string; name: string }>}
                        getOptionLabel={(o) => o.name ?? ""}
                        isOptionEqualToValue={(opt, val) => opt.code === val.code}
                        value={(brandData?.rows ?? []).find((b: any) => b.code === basic.brand) ?? null}
                        onChange={(_, v) => setBasic({ ...basic, brand: v?.code ?? "" })}
                        renderInput={(params) => <TextField {...params} label="Marca" placeholder="Buscar marca..." />}
                        noOptionsText="Sin resultados"
                        clearOnEscape
                    />
                </Stack>
            </Paper>

            <Paper elevation={1} sx={{ p: 2, borderRadius: 2 }}>
                <Typography variant="overline" color="text.secondary">Precio</Typography>
                <Stack spacing={1.5} sx={{ mt: 1 }}>
                    <TextField
                        size="small" label="Precio" type="number" fullWidth
                        value={basic.price}
                        onChange={(e) => setBasic({ ...basic, price: Number(e.target.value) })}
                    />
                    <TextField
                        size="small" label="Precio comparativo" type="number" fullWidth
                        value={basic.compareAtPrice ?? ""}
                        onChange={(e) => setBasic({ ...basic, compareAtPrice: e.target.value ? Number(e.target.value) : undefined })}
                    />
                    <TextField
                        size="small" label="Costo" type="number" fullWidth
                        value={basic.costPrice ?? 0}
                        onChange={(e) => setBasic({ ...basic, costPrice: Number(e.target.value) })}
                    />
                </Stack>
            </Paper>

            <Paper elevation={1} sx={{ p: 2, borderRadius: 2 }}>
                <Typography variant="overline" color="text.secondary">Inventario</Typography>
                <Stack spacing={1.5} sx={{ mt: 1 }}>
                    <TextField
                        size="small" label="SKU" fullWidth
                        value={basic.code}
                        disabled={isEdit}
                        onChange={(e) => setBasic({ ...basic, code: e.target.value })}
                    />
                    <TextField
                        size="small" label="Stock" type="number" fullWidth
                        value={basic.stockQty ?? 0}
                        onChange={(e) => setBasic({ ...basic, stockQty: Number(e.target.value) })}
                    />
                    <FormControlLabel
                        control={
                            <Switch
                                checked={!!basic.isService}
                                onChange={(e) => setBasic({ ...basic, isService: e.target.checked })}
                            />
                        }
                        label="Es servicio (no descuenta stock)"
                    />
                </Stack>
            </Paper>
        </Stack>
    );

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

            <Grid container spacing={3}>
                {/* ── Panel principal (8/12) ── */}
                <Grid item xs={12} md={8}>
                    <Paper elevation={1} sx={{ p: 2, borderRadius: 2 }}>
                        <Tabs
                            value={tab}
                            onChange={(_, v) => setTab(v)}
                            variant="scrollable"
                            scrollButtons="auto"
                            sx={{ borderBottom: 1, borderColor: "divider", mb: 2 }}
                        >
                            {TABS.map((t, i) => (
                                <Tab key={t.id} label={t.label} disabled={i >= 2 && !isEdit && !basic.code} />
                            ))}
                        </Tabs>

                        {/* Tab 0 — Info */}
                        {tab === 0 && (
                            <FormGrid spacing={2}>
                                <FormField xs={12} sm={6}>
                                    <TextField label="Código (SKU)" fullWidth required value={basic.code}
                                        disabled={isEdit}
                                        onChange={(e) => setBasic({ ...basic, code: e.target.value })}
                                    />
                                </FormField>
                                <FormField xs={12} sm={6}>
                                    <TextField label="Nombre" fullWidth required value={basic.name}
                                        onChange={(e) => setBasic({ ...basic, name: e.target.value })}
                                    />
                                </FormField>
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
                                <FormField xs={12} sm={4}>
                                    <TextField label="Peso (kg)" type="number" fullWidth value={basic.weightKg ?? ""}
                                        onChange={(e) => setBasic({ ...basic, weightKg: e.target.value ? Number(e.target.value) : undefined })}
                                    />
                                </FormField>
                                <FormField xs={12}>
                                    <TextField label="Código de barras" fullWidth value={basic.barcode ?? ""}
                                        onChange={(e) => setBasic({ ...basic, barcode: e.target.value })}
                                    />
                                </FormField>
                            </FormGrid>
                        )}

                        {/* Tab 1 — SEO */}
                        {tab === 1 && (
                            <FormGrid spacing={2}>
                                <FormField xs={12} sm={6}>
                                    <TextField label="Meta Title" fullWidth value={basic.metaTitle ?? ""}
                                        onChange={(e) => setBasic({ ...basic, metaTitle: e.target.value })}
                                        inputProps={{ maxLength: 200 }}
                                        helperText={`${(basic.metaTitle ?? "").length} / 200 (recomendado 50-60)`}
                                    />
                                </FormField>
                                <FormField xs={12} sm={6}>
                                    <TextField label="Slug (URL)" fullWidth value={basic.slug ?? ""}
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
                                        helperText={`${(basic.metaDescription ?? "").length} / 320 (recomendado 140-160)`}
                                    />
                                </FormField>
                            </FormGrid>
                        )}

                        {/* Tab 2 — Galería */}
                        {tab === 2 && (
                            <Box>
                                {/* Drop-zone 2px dashed + hover/drag naranja */}
                                <Box
                                    onDragOver={(e) => { e.preventDefault(); setDragActive(true); }}
                                    onDragLeave={() => setDragActive(false)}
                                    onDrop={(e) => {
                                        e.preventDefault();
                                        setDragActive(false);
                                        handleFileUpload(e.dataTransfer.files);
                                    }}
                                    sx={{
                                        border: "2px dashed",
                                        borderColor: dragActive ? "#ff9900" : "#d5d9d9",
                                        borderRadius: 2,
                                        bgcolor: dragActive ? "rgba(255, 153, 0, 0.06)" : "transparent",
                                        textAlign: "center",
                                        py: 4, px: 2, mb: 2,
                                        transition: "all 150ms",
                                        "&:hover": { borderColor: "#ff9900" },
                                    }}
                                >
                                    <CloudUploadIcon sx={{ fontSize: 48, color: dragActive ? "#ff9900" : "#6b7280" }} />
                                    <Typography variant="body1" sx={{ mt: 1, fontWeight: 500 }}>
                                        Arrastra imágenes aquí o haz clic
                                    </Typography>
                                    <Typography variant="caption" color="text.secondary">
                                        JPG, PNG, WebP · máx 5 MB cada una
                                    </Typography>
                                    <Box sx={{ mt: 2 }}>
                                        <Button
                                            component="label"
                                            variant="outlined"
                                            startIcon={<UploadFileIcon />}
                                            disabled={uploadMut.isPending}
                                        >
                                            {uploadMut.isPending ? "Subiendo…" : "Seleccionar archivos"}
                                            <input
                                                type="file"
                                                hidden
                                                accept="image/*"
                                                multiple
                                                onChange={(e) => handleFileUpload(e.target.files)}
                                            />
                                        </Button>
                                    </Box>
                                </Box>

                                {missingAltImages > 0 && (
                                    <Alert severity="warning" sx={{ mb: 2 }}>
                                        {missingAltImages} imagen{missingAltImages === 1 ? "" : "es"} sin alt-text.
                                        Accesibilidad (WCAG) lo exige. Completa los campos en rojo antes de guardar.
                                    </Alert>
                                )}

                                <Box sx={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(180px, 1fr))", gap: 2 }}>
                                    {images.map((img, idx) => {
                                        const missingAlt = !(img.altText ?? "").trim();
                                        return (
                                            <Paper
                                                key={`${img.url}-${idx}`}
                                                elevation={1}
                                                sx={{
                                                    p: 1,
                                                    position: "relative",
                                                    borderRadius: 2,
                                                    border: img.isPrimary ? "2px solid #ff9900" : "1px solid transparent",
                                                }}
                                            >
                                                {img.isPrimary && (
                                                    <Chip
                                                        size="small"
                                                        icon={<StarIcon fontSize="small" />}
                                                        label="Primaria"
                                                        sx={{
                                                            position: "absolute",
                                                            top: 6, left: 6, zIndex: 1,
                                                            bgcolor: "#ff9900",
                                                            color: "#0f1111",
                                                            fontWeight: 700,
                                                        }}
                                                    />
                                                )}
                                                <Box
                                                    component="img"
                                                    src={img.url}
                                                    alt={img.altText ?? ""}
                                                    sx={{ width: "100%", height: 140, objectFit: "cover", borderRadius: 1 }}
                                                />
                                                <TextField
                                                    size="small"
                                                    label="Alt text *"
                                                    fullWidth
                                                    required
                                                    value={img.altText ?? ""}
                                                    error={missingAlt}
                                                    helperText={missingAlt ? "Añade texto alternativo (accesibilidad)" : " "}
                                                    onChange={(e) =>
                                                        setImages((prev) => prev.map((im, i) => (i === idx ? { ...im, altText: e.target.value } : im)))
                                                    }
                                                    sx={{ mt: 1 }}
                                                />
                                                <Stack direction="row" spacing={0.5} justifyContent="space-between" sx={{ mt: 0.5 }}>
                                                    <IconButton size="small" onClick={() => setPrimary(idx)}
                                                        color={img.isPrimary ? "warning" : "default"}
                                                        title="Marcar como primaria"
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
                                        );
                                    })}
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

                        {/* Tab 5 — Variantes (placeholder) */}
                        {tab === 5 && (
                            <Alert severity="info">
                                El editor de variantes (atributos Color/Talla → combinaciones SKU)
                                llega en una Ola siguiente. Usa por ahora productos individuales con
                                SKU único.
                            </Alert>
                        )}

                        {/* Tab 6 — Reviews */}
                        {tab === 6 && (
                            <Alert severity="info">
                                Usa la sección <b>Contenido → Reseñas</b> del sidebar para moderar
                                las reseñas de este y todos los productos.
                            </Alert>
                        )}

                        {/* Save bar */}
                        <Stack direction="row" spacing={2} sx={{ mt: 3, pt: 2, borderTop: "1px solid #eee" }}>
                            {(tab === 0 || tab === 1) && (
                                <Button
                                    variant="contained"
                                    startIcon={<SaveIcon />}
                                    onClick={saveBasic}
                                    disabled={!canSave || upsertMut.isPending}
                                    sx={{ bgcolor: "#ff9900", "&:hover": { bgcolor: "#e68a00" } }}
                                >
                                    {upsertMut.isPending ? "Guardando…" : "Guardar"}
                                </Button>
                            )}
                            {tab === 2 && (
                                <Button
                                    variant="contained"
                                    startIcon={<SaveIcon />}
                                    onClick={saveImages}
                                    disabled={imagesMut.isPending || !canSaveGallery}
                                    title={missingAltImages > 0 ? "Completa alt-text en todas las imágenes" : undefined}
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
                </Grid>

                {/* ── Sidebar sticky (4/12) ── */}
                <Grid item xs={12} md={4}>
                    {renderSidebar()}
                </Grid>
            </Grid>
        </Box>
    );
}
