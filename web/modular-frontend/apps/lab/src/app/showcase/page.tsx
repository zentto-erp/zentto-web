'use client';
import { useEffect, useRef, useState } from 'react';
import {
  Box,
  Typography,
  Chip,
  CircularProgress,
  Switch,
  FormControlLabel,
  Paper,
  Divider,
} from '@mui/material';
import type { ColumnDef, GridRow } from '@zentto/datagrid-core';

// ─── Mock Data: 50 products in tree structure ─────────────────────────────────
// Categories (level 0)
// Subcategories (level 1)
// Products (level 2)

const MOCK_DATA: GridRow[] = [
  // ── Alimentos ───────────────────────────────────────
  { id: 'cat-1', parentId: null, codigo: '', descripcion: 'Alimentos', categoria: 'Alimentos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 'sub-1-1', parentId: 'cat-1', codigo: '', descripcion: 'Cereales', categoria: 'Alimentos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 1, parentId: 'sub-1-1', codigo: 'ALI-001', descripcion: 'Arroz Premium 1kg', categoria: 'Alimentos', precioCompra: 32.00, precioVenta: 45.00, stock: 150, estado: 'Activo', email: 'proveedor1@zentto.net', historialEstados: [{ status: 'Pendiente', date: '2026-01-10' }, { status: 'Activo', date: '2026-01-15' }] },
  { id: 2, parentId: 'sub-1-1', codigo: 'ALI-002', descripcion: 'Harina de Trigo 1kg', categoria: 'Alimentos', precioCompra: 25.00, precioVenta: 35.00, stock: 8, estado: 'Activo', email: 'harina@proveedor.com', historialEstados: [{ status: 'Pendiente', date: '2026-01-05' }, { status: 'Activo', date: '2026-01-08' }] },
  { id: 3, parentId: 'sub-1-1', codigo: 'ALI-003', descripcion: 'Avena Integral 500g', categoria: 'Alimentos', precioCompra: 18.00, precioVenta: 28.00, stock: 45, estado: 'Activo', email: 'avena@distribuidora.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 'sub-1-2', parentId: 'cat-1', codigo: '', descripcion: 'Aceites', categoria: 'Alimentos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 4, parentId: 'sub-1-2', codigo: 'ALI-004', descripcion: 'Aceite de Oliva Extra Virgen 500ml', categoria: 'Alimentos', precioCompra: 85.00, precioVenta: 120.00, stock: 5, estado: 'Activo', email: 'olivar@aceites.com', historialEstados: [{ status: 'Pendiente', date: '2026-01-20' }, { status: 'Activo', date: '2026-01-25' }] },
  { id: 5, parentId: 'sub-1-2', codigo: 'ALI-005', descripcion: 'Aceite de Girasol 1L', categoria: 'Alimentos', precioCompra: 30.00, precioVenta: 42.00, stock: 200, estado: 'Activo', email: 'girasol@aceites.com', historialEstados: [{ status: 'Activo', date: '2026-02-10' }] },
  { id: 'sub-1-3', parentId: 'cat-1', codigo: '', descripcion: 'Pastas', categoria: 'Alimentos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 6, parentId: 'sub-1-3', codigo: 'ALI-006', descripcion: 'Pasta Espagueti 500g', categoria: 'Alimentos', precioCompra: 18.00, precioVenta: 28.00, stock: 3, estado: 'Inactivo', email: 'pasta@zentto.net', historialEstados: [{ status: 'Activo', date: '2025-12-01' }, { status: 'Inactivo', date: '2026-03-01' }] },
  { id: 7, parentId: 'sub-1-3', codigo: 'ALI-007', descripcion: 'Macarrones Cortos 500g', categoria: 'Alimentos', precioCompra: 16.00, precioVenta: 25.00, stock: 30, estado: 'Activo', email: 'macarrones@distribuidora.com', historialEstados: [{ status: 'Activo', date: '2026-01-20' }] },

  // ── Bebidas ─────────────────────────────────────────
  { id: 'cat-2', parentId: null, codigo: '', descripcion: 'Bebidas', categoria: 'Bebidas', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 'sub-2-1', parentId: 'cat-2', codigo: '', descripcion: 'Aguas', categoria: 'Bebidas', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 8, parentId: 'sub-2-1', codigo: 'BEB-001', descripcion: 'Agua Mineral 1.5L', categoria: 'Bebidas', precioCompra: 8.00, precioVenta: 15.00, stock: 500, estado: 'Activo', email: 'agua@distribuidora.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 9, parentId: 'sub-2-1', codigo: 'BEB-002', descripcion: 'Agua con Gas 500ml', categoria: 'Bebidas', precioCompra: 10.00, precioVenta: 18.00, stock: 120, estado: 'Activo', email: 'gas@agua.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 'sub-2-2', parentId: 'cat-2', codigo: '', descripcion: 'Jugos', categoria: 'Bebidas', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 10, parentId: 'sub-2-2', codigo: 'BEB-003', descripcion: 'Jugo de Naranja Natural 1L', categoria: 'Bebidas', precioCompra: 35.00, precioVenta: 55.00, stock: 7, estado: 'Activo', email: 'jugos@zentto.net', historialEstados: [{ status: 'Pendiente', date: '2026-02-01' }, { status: 'Activo', date: '2026-02-05' }] },
  { id: 11, parentId: 'sub-2-2', codigo: 'BEB-004', descripcion: 'Jugo de Manzana 1L', categoria: 'Bebidas', precioCompra: 32.00, precioVenta: 50.00, stock: 25, estado: 'Activo', email: 'manzana@jugos.com', historialEstados: [{ status: 'Activo', date: '2026-02-10' }] },
  { id: 'sub-2-3', parentId: 'cat-2', codigo: '', descripcion: 'Refrescos', categoria: 'Bebidas', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 12, parentId: 'sub-2-3', codigo: 'BEB-005', descripcion: 'Refresco Cola 2L', categoria: 'Bebidas', precioCompra: 20.00, precioVenta: 35.00, stock: 180, estado: 'Activo', email: 'refrescos@distribuidora.com', historialEstados: [{ status: 'Activo', date: '2026-01-15' }] },
  { id: 13, parentId: 'sub-2-3', codigo: 'BEB-006', descripcion: 'Refresco Limon 600ml', categoria: 'Bebidas', precioCompra: 12.00, precioVenta: 20.00, stock: 0, estado: 'Inactivo', email: 'limon@refrescos.com', historialEstados: [{ status: 'Activo', date: '2025-11-01' }, { status: 'Inactivo', date: '2026-02-15' }] },

  // ── Lacteos ─────────────────────────────────────────
  { id: 'cat-3', parentId: null, codigo: '', descripcion: 'Lacteos', categoria: 'Lacteos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 'sub-3-1', parentId: 'cat-3', codigo: '', descripcion: 'Leches', categoria: 'Lacteos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 14, parentId: 'sub-3-1', codigo: 'LAC-001', descripcion: 'Leche Completa UHT 1L', categoria: 'Lacteos', precioCompra: 28.00, precioVenta: 42.00, stock: 90, estado: 'Activo', email: 'leche@lacteos.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 15, parentId: 'sub-3-1', codigo: 'LAC-002', descripcion: 'Leche Descremada 1L', categoria: 'Lacteos', precioCompra: 30.00, precioVenta: 45.00, stock: 60, estado: 'Activo', email: 'descremada@lacteos.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 'sub-3-2', parentId: 'cat-3', codigo: '', descripcion: 'Quesos', categoria: 'Lacteos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 16, parentId: 'sub-3-2', codigo: 'LAC-003', descripcion: 'Queso Blanco Llanero 500g', categoria: 'Lacteos', precioCompra: 55.00, precioVenta: 85.00, stock: 4, estado: 'Pendiente', email: 'queso@lacteos.com', historialEstados: [{ status: 'Pendiente', date: '2026-03-01' }] },
  { id: 17, parentId: 'sub-3-2', codigo: 'LAC-004', descripcion: 'Queso Mozzarella 400g', categoria: 'Lacteos', precioCompra: 60.00, precioVenta: 95.00, stock: 15, estado: 'Activo', email: 'mozzarella@lacteos.com', historialEstados: [{ status: 'Activo', date: '2026-02-20' }] },
  { id: 'sub-3-3', parentId: 'cat-3', codigo: '', descripcion: 'Yogures', categoria: 'Lacteos', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 18, parentId: 'sub-3-3', codigo: 'LAC-005', descripcion: 'Yogurt Natural 500ml', categoria: 'Lacteos', precioCompra: 30.00, precioVenta: 48.00, stock: 35, estado: 'Activo', email: 'yogurt@lacteos.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 19, parentId: 'sub-3-3', codigo: 'LAC-006', descripcion: 'Yogurt Fresa 500ml', categoria: 'Lacteos', precioCompra: 32.00, precioVenta: 50.00, stock: 9, estado: 'Activo', email: 'fresa@lacteos.com', historialEstados: [{ status: 'Pendiente', date: '2026-01-15' }, { status: 'Activo', date: '2026-01-20' }] },

  // ── Limpieza ────────────────────────────────────────
  { id: 'cat-4', parentId: null, codigo: '', descripcion: 'Limpieza', categoria: 'Limpieza', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 'sub-4-1', parentId: 'cat-4', codigo: '', descripcion: 'Detergentes', categoria: 'Limpieza', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 20, parentId: 'sub-4-1', codigo: 'LIM-001', descripcion: 'Detergente Liquido 2L', categoria: 'Limpieza', precioCompra: 50.00, precioVenta: 75.00, stock: 110, estado: 'Activo', email: 'detergente@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 21, parentId: 'sub-4-1', codigo: 'LIM-002', descripcion: 'Detergente en Polvo 1kg', categoria: 'Limpieza', precioCompra: 35.00, precioVenta: 55.00, stock: 75, estado: 'Activo', email: 'polvo@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-01-10' }] },
  { id: 'sub-4-2', parentId: 'cat-4', codigo: '', descripcion: 'Jabones', categoria: 'Limpieza', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 22, parentId: 'sub-4-2', codigo: 'LIM-003', descripcion: 'Jabon de Manos Antibacterial 400ml', categoria: 'Limpieza', precioCompra: 22.00, precioVenta: 35.00, stock: 2, estado: 'Pendiente', email: 'jabon@limpieza.com', historialEstados: [{ status: 'Activo', date: '2025-12-01' }, { status: 'Pendiente', date: '2026-03-10' }] },
  { id: 23, parentId: 'sub-4-2', codigo: 'LIM-004', descripcion: 'Jabon en Barra Pack x3', categoria: 'Limpieza', precioCompra: 15.00, precioVenta: 25.00, stock: 50, estado: 'Activo', email: 'barra@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 'sub-4-3', parentId: 'cat-4', codigo: '', descripcion: 'Desinfectantes', categoria: 'Limpieza', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 24, parentId: 'sub-4-3', codigo: 'LIM-005', descripcion: 'Cloro Concentrado 1L', categoria: 'Limpieza', precioCompra: 12.00, precioVenta: 22.00, stock: 300, estado: 'Activo', email: 'cloro@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 25, parentId: 'sub-4-3', codigo: 'LIM-006', descripcion: 'Desinfectante Multiusos 750ml', categoria: 'Limpieza', precioCompra: 28.00, precioVenta: 45.00, stock: 6, estado: 'Activo', email: 'multi@limpieza.com', historialEstados: [{ status: 'Pendiente', date: '2026-02-10' }, { status: 'Activo', date: '2026-02-15' }] },

  // ── Verduras ────────────────────────────────────────
  { id: 'cat-5', parentId: null, codigo: '', descripcion: 'Verduras', categoria: 'Verduras', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 'sub-5-1', parentId: 'cat-5', codigo: '', descripcion: 'Tuberculos', categoria: 'Verduras', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 26, parentId: 'sub-5-1', codigo: 'VER-001', descripcion: 'Papa 1kg', categoria: 'Verduras', precioCompra: 18.00, precioVenta: 28.00, stock: 250, estado: 'Activo', email: 'papa@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-03-01' }] },
  { id: 27, parentId: 'sub-5-1', codigo: 'VER-002', descripcion: 'Yuca 1kg', categoria: 'Verduras', precioCompra: 15.00, precioVenta: 25.00, stock: 40, estado: 'Activo', email: 'yuca@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-03-01' }] },
  { id: 'sub-5-2', parentId: 'cat-5', codigo: '', descripcion: 'Hortalizas', categoria: 'Verduras', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 28, parentId: 'sub-5-2', codigo: 'VER-003', descripcion: 'Tomate Perita 1kg', categoria: 'Verduras', precioCompra: 20.00, precioVenta: 32.00, stock: 1, estado: 'Pendiente', email: 'tomate@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }, { status: 'Pendiente', date: '2026-03-15' }] },
  { id: 29, parentId: 'sub-5-2', codigo: 'VER-004', descripcion: 'Cebolla Blanca 1kg', categoria: 'Verduras', precioCompra: 16.00, precioVenta: 25.00, stock: 130, estado: 'Activo', email: 'cebolla@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 30, parentId: 'sub-5-2', codigo: 'VER-005', descripcion: 'Pimenton Rojo 1kg', categoria: 'Verduras', precioCompra: 25.00, precioVenta: 40.00, stock: 18, estado: 'Activo', email: 'pimenton@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-02-15' }] },
  { id: 'sub-5-3', parentId: 'cat-5', codigo: '', descripcion: 'Hojas Verdes', categoria: 'Verduras', precioCompra: 0, precioVenta: 0, stock: 0, estado: 'Activo', email: '', historialEstados: [] },
  { id: 31, parentId: 'sub-5-3', codigo: 'VER-006', descripcion: 'Lechuga Romana', categoria: 'Verduras', precioCompra: 10.00, precioVenta: 18.00, stock: 0, estado: 'Inactivo', email: 'lechuga@verduras.com', historialEstados: [{ status: 'Activo', date: '2025-12-01' }, { status: 'Inactivo', date: '2026-03-10' }] },
  { id: 32, parentId: 'sub-5-3', codigo: 'VER-007', descripcion: 'Espinaca 250g', categoria: 'Verduras', precioCompra: 12.00, precioVenta: 22.00, stock: 20, estado: 'Activo', email: 'espinaca@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-03-01' }] },

  // ── Productos adicionales para llegar a 50+ ─────────
  { id: 33, parentId: 'sub-1-1', codigo: 'ALI-008', descripcion: 'Maiz Precocido 1kg', categoria: 'Alimentos', precioCompra: 22.00, precioVenta: 35.00, stock: 85, estado: 'Activo', email: 'maiz@alimentos.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 34, parentId: 'sub-1-2', codigo: 'ALI-009', descripcion: 'Aceite de Coco 250ml', categoria: 'Alimentos', precioCompra: 45.00, precioVenta: 70.00, stock: 12, estado: 'Activo', email: 'coco@aceites.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 35, parentId: 'sub-1-3', codigo: 'ALI-010', descripcion: 'Fideos Cabello de Angel 250g', categoria: 'Alimentos', precioCompra: 14.00, precioVenta: 22.00, stock: 55, estado: 'Activo', email: 'fideos@pastas.com', historialEstados: [{ status: 'Activo', date: '2026-01-15' }] },
  { id: 36, parentId: 'sub-2-1', codigo: 'BEB-007', descripcion: 'Agua Saborizada Durazno 500ml', categoria: 'Bebidas', precioCompra: 14.00, precioVenta: 22.00, stock: 95, estado: 'Activo', email: 'saborizada@agua.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 37, parentId: 'sub-2-2', codigo: 'BEB-008', descripcion: 'Jugo de Pera 1L', categoria: 'Bebidas', precioCompra: 30.00, precioVenta: 48.00, stock: 6, estado: 'Pendiente', email: 'pera@jugos.com', historialEstados: [{ status: 'Pendiente', date: '2026-03-10' }] },
  { id: 38, parentId: 'sub-3-1', codigo: 'LAC-007', descripcion: 'Leche de Almendras 1L', categoria: 'Lacteos', precioCompra: 40.00, precioVenta: 65.00, stock: 22, estado: 'Activo', email: 'almendras@lacteos.com', historialEstados: [{ status: 'Activo', date: '2026-02-15' }] },
  { id: 39, parentId: 'sub-3-2', codigo: 'LAC-008', descripcion: 'Queso Parmesano Rallado 200g', categoria: 'Lacteos', precioCompra: 70.00, precioVenta: 110.00, stock: 8, estado: 'Activo', email: 'parmesano@lacteos.com', historialEstados: [{ status: 'Activo', date: '2026-01-20' }] },
  { id: 40, parentId: 'sub-4-1', codigo: 'LIM-007', descripcion: 'Suavizante de Ropa 2L', categoria: 'Limpieza', precioCompra: 38.00, precioVenta: 60.00, stock: 42, estado: 'Activo', email: 'suavizante@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-01-05' }] },
  { id: 41, parentId: 'sub-4-2', codigo: 'LIM-008', descripcion: 'Jabon Liquido Lavaplatos 750ml', categoria: 'Limpieza', precioCompra: 18.00, precioVenta: 30.00, stock: 160, estado: 'Activo', email: 'lavaplatos@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 42, parentId: 'sub-4-3', codigo: 'LIM-009', descripcion: 'Alcohol Isopropilico 500ml', categoria: 'Limpieza', precioCompra: 20.00, precioVenta: 35.00, stock: 70, estado: 'Activo', email: 'alcohol@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }] },
  { id: 43, parentId: 'sub-5-1', codigo: 'VER-008', descripcion: 'Batata 1kg', categoria: 'Verduras', precioCompra: 14.00, precioVenta: 24.00, stock: 3, estado: 'Pendiente', email: 'batata@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-01-01' }, { status: 'Pendiente', date: '2026-03-20' }] },
  { id: 44, parentId: 'sub-5-2', codigo: 'VER-009', descripcion: 'Zanahoria 1kg', categoria: 'Verduras', precioCompra: 12.00, precioVenta: 20.00, stock: 105, estado: 'Activo', email: 'zanahoria@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-03-01' }] },
  { id: 45, parentId: 'sub-5-3', codigo: 'VER-010', descripcion: 'Acelga Fresca 300g', categoria: 'Verduras', precioCompra: 8.00, precioVenta: 15.00, stock: 11, estado: 'Activo', email: 'acelga@verduras.com', historialEstados: [{ status: 'Activo', date: '2026-02-20' }] },
  { id: 46, parentId: 'sub-1-1', codigo: 'ALI-011', descripcion: 'Lentejas 500g', categoria: 'Alimentos', precioCompra: 20.00, precioVenta: 32.00, stock: 48, estado: 'Activo', email: 'lentejas@alimentos.com', historialEstados: [{ status: 'Activo', date: '2026-01-10' }] },
  { id: 47, parentId: 'sub-2-3', codigo: 'BEB-009', descripcion: 'Te Frio Melocoton 500ml', categoria: 'Bebidas', precioCompra: 15.00, precioVenta: 25.00, stock: 140, estado: 'Activo', email: 'te@bebidas.com', historialEstados: [{ status: 'Activo', date: '2026-02-01' }] },
  { id: 48, parentId: 'sub-3-3', codigo: 'LAC-009', descripcion: 'Yogurt Griego 170g', categoria: 'Lacteos', precioCompra: 25.00, precioVenta: 42.00, stock: 7, estado: 'Activo', email: 'griego@lacteos.com', historialEstados: [{ status: 'Pendiente', date: '2026-02-01' }, { status: 'Activo', date: '2026-02-10' }] },
  { id: 49, parentId: 'sub-4-3', codigo: 'LIM-010', descripcion: 'Ambientador Spray Lavanda 300ml', categoria: 'Limpieza', precioCompra: 22.00, precioVenta: 38.00, stock: 33, estado: 'Activo', email: 'lavanda@limpieza.com', historialEstados: [{ status: 'Activo', date: '2026-01-15' }] },
  { id: 50, parentId: 'sub-5-2', codigo: 'VER-011', descripcion: 'Calabacin 1kg', categoria: 'Verduras', precioCompra: 18.00, precioVenta: 30.00, stock: 0, estado: 'Inactivo', email: 'calabacin-no-valido', historialEstados: [{ status: 'Activo', date: '2025-11-01' }, { status: 'Inactivo', date: '2026-03-05' }] },
];

// Only product rows (exclude category/subcategory nodes) for flat mode
const FLAT_DATA: GridRow[] = MOCK_DATA.filter((r) => typeof r.id === 'number');

// Pinned summary row for bottom
const TOTALS_ROW: GridRow = {
  id: 'totals',
  codigo: '',
  descripcion: 'TOTALES',
  categoria: '',
  precioCompra: FLAT_DATA.reduce((s, r) => s + Number(r.precioCompra || 0), 0),
  precioVenta: FLAT_DATA.reduce((s, r) => s + Number(r.precioVenta || 0), 0),
  stock: FLAT_DATA.reduce((s, r) => s + Number(r.stock || 0), 0),
  estado: '',
  email: '',
  historialEstados: [],
};

// Pre-populated cell comments/notes
const CELL_NOTES: Record<string, string> = {
  '4:stock': 'Stock critico - hacer pedido urgente',
  '6:estado': 'Descontinuado por proveedor desde marzo',
  '16:estado': 'Esperando aprobacion sanitaria',
  '22:stock': 'Ultimo lote - verificar reposicion',
  '28:stock': 'Agotado en almacen principal',
  '50:email': 'Email invalido - contactar proveedor',
};

// ─── Column Definitions with ALL v0.4-v1.0 features ──────────────────────────

const COLUMNS: ColumnDef[] = [
  {
    field: 'codigo',
    header: 'Codigo',
    width: 150,
    sortable: true,
    // v0.8: Barcode rendering
    barcode: 'code128',
    // v0.8: Hyperlink
    hyperlink: true,
    hyperlinkPattern: '/showcase/product/{id}',
    hyperlinkTarget: '_self',
  },
  {
    field: 'descripcion',
    header: 'Descripcion',
    flex: 1,
    minWidth: 200,
    sortable: true,
  },
  {
    field: 'categoria',
    header: 'Categoria',
    width: 140,
    sortable: true,
    groupable: true,
    // v0.5: Cell merge — consecutive same values are merged
    merge: true,
  },
  {
    field: 'precioCompra',
    header: 'Costo',
    width: 120,
    type: 'number',
    currency: 'VES',
    sortable: true,
    aggregation: 'avg',
    aggregationLabel: 'Promedio',
  },
  {
    field: 'precioVenta',
    header: 'Precio Venta',
    width: 130,
    type: 'number',
    currency: 'VES',
    sortable: true,
    aggregation: 'avg',
    aggregationLabel: 'Promedio',
  },
  {
    field: 'margen',
    header: 'Margen %',
    width: 120,
    type: 'percentage',
    sortable: true,
    // v0.4: Formula — auto-recalculates when precioVenta or precioCompra change
    formula: '=({precioVenta}-{precioCompra})/{precioCompra}*100',
    // v0.4: Conditional formatting on margen
    conditionalFormat: [
      { condition: 'lt', value: 20, style: { backgroundColor: '#fef2f2', color: '#dc2626', fontWeight: '600' } },
      { condition: 'between', value: [20, 50], style: { backgroundColor: '#fffbeb', color: '#d97706', fontWeight: '600' } },
      { condition: 'gt', value: 50, style: { backgroundColor: '#f0fdf4', color: '#16a34a', fontWeight: '600' } },
    ],
  },
  {
    field: 'stock',
    header: 'Stock',
    width: 110,
    type: 'number',
    sortable: true,
    aggregation: 'count',
    aggregationLabel: 'Registros',
    // v0.4: Conditional formatting — red < 10, yellow 10-50, green > 100
    conditionalFormat: [
      { condition: 'lt', value: 10, style: { backgroundColor: '#fef2f2', color: '#dc2626', fontWeight: '700' } },
      { condition: 'between', value: [10, 50], style: { backgroundColor: '#fffbeb', color: '#d97706' } },
      { condition: 'gt', value: 100, style: { backgroundColor: '#f0fdf4', color: '#16a34a', fontWeight: '600' } },
    ],
    // v0.4: Data validation — stock must be 0-99999
    validation: {
      type: 'number',
      min: 0,
      max: 99999,
      message: 'Stock debe ser entre 0 y 99.999',
    },
  },
  {
    field: 'estado',
    header: 'Estado',
    width: 140,
    sortable: true,
    groupable: true,
    // Status chip colors
    statusColors: { Activo: 'success', Inactivo: 'error', Pendiente: 'warning' },
    statusVariant: 'outlined',
    // v0.4: Dropdown for inline edit
    dropdown: [
      { value: 'Activo', label: 'Activo', color: '#16a34a' },
      { value: 'Inactivo', label: 'Inactivo', color: '#dc2626' },
      { value: 'Pendiente', label: 'Pendiente', color: '#d97706' },
    ],
    // v0.8: Status timeline
    timeline: true,
    timelineField: 'historialEstados',
  },
  {
    field: 'email',
    header: 'Email Proveedor',
    width: 200,
    sortable: true,
    // v0.4: Email validation
    validation: {
      type: 'email',
      message: 'Formato de email invalido',
    },
  },
  {
    field: 'aiSummary',
    header: 'AI Resumen',
    width: 180,
    // v0.8: AI Column (mock — no real API, shows placeholder)
    ai: {
      prompt: 'Resume este producto en 10 palabras: {descripcion}, categoria {categoria}, stock {stock}',
      fields: ['descripcion', 'categoria', 'stock'],
      cache: true,
    },
  },
  {
    field: 'actions',
    header: 'Acciones',
    type: 'actions',
    width: 130,
    pin: 'right',
    actions: [
      { icon: 'view', label: 'Ver', action: 'view' },
      { icon: 'edit', label: 'Editar', action: 'edit', color: '#e67e22' },
      { icon: 'delete', label: 'Eliminar', action: 'delete', color: '#dc2626' },
    ],
  },
];

const FILTER_PANEL = [
  { field: 'categoria', type: 'select', label: 'Categoria' },
  { field: 'estado', type: 'select', label: 'Estado' },
  { field: 'precioVenta', type: 'range', label: 'Precio' },
  { field: 'stock', type: 'range', label: 'Stock' },
  { field: 'descripcion', type: 'text', label: 'Buscar', placeholder: 'Nombre del producto...' },
];

// ─── Feature toggles ─────────────────────────────────────────────────────────

interface FeatureToggles {
  treeData: boolean;
  charts: boolean;
  print: boolean;
  audit: boolean;
  serverSide: boolean;
  comments: boolean;
  cellMerge: boolean;
  pinnedRows: boolean;
}

const DEFAULT_TOGGLES: FeatureToggles = {
  treeData: false,
  charts: true,
  print: true,
  audit: true,
  serverSide: false,
  comments: true,
  cellMerge: true,
  pinnedRows: true,
};

export default function ShowcasePage() {
  const gridRef = useRef<any>(null);
  const [registered, setRegistered] = useState(false);
  const [toggles, setToggles] = useState<FeatureToggles>(DEFAULT_TOGGLES);

  // Register web component
  useEffect(() => {
    import('@zentto/datagrid').then(() => setRegistered(true));
  }, []);

  // Choose data based on tree mode
  const activeRows = toggles.treeData ? MOCK_DATA : FLAT_DATA;

  // Build columns — toggle merge on/off
  const activeColumns = COLUMNS.map((col) => {
    if (col.field === 'categoria') {
      return { ...col, merge: toggles.cellMerge };
    }
    return col;
  });

  // Bind data to web component whenever dependencies change
  useEffect(() => {
    const el = gridRef.current;
    if (!el || !registered) return;

    el.columns = activeColumns;
    el.rows = activeRows;
    el.loading = false;
    el.filterPanel = FILTER_PANEL;

    // v0.5: Row pinning — summary row at bottom
    if (toggles.pinnedRows) {
      el.pinnedRows = { top: [], bottom: [TOTALS_ROW] };
    } else {
      el.pinnedRows = { top: [], bottom: [] };
    }

    // v0.7: Cell comments with pre-populated notes
    if (toggles.comments) {
      el.cellNotes = CELL_NOTES;
    } else {
      el.cellNotes = {};
    }

    // v0.5: Tree data
    if (toggles.treeData) {
      el.setAttribute('enable-tree-data', '');
      el.setAttribute('tree-id-field', 'id');
      el.setAttribute('tree-parent-field', 'parentId');
    } else {
      el.removeAttribute('enable-tree-data');
    }

    // v0.7: Charts
    if (toggles.charts) {
      el.setAttribute('enable-charts', '');
    } else {
      el.removeAttribute('enable-charts');
    }

    // v0.7: Print
    if (toggles.print) {
      el.setAttribute('enable-print', '');
    } else {
      el.removeAttribute('enable-print');
    }

    // v0.7: Comments
    if (toggles.comments) {
      el.setAttribute('enable-comments', '');
    } else {
      el.removeAttribute('enable-comments');
    }

    // v0.8: Audit
    if (toggles.audit) {
      el.setAttribute('enable-audit', '');
      el.auditUser = 'Lab User';
    } else {
      el.removeAttribute('enable-audit');
    }

    // v0.6: Server-side mode
    if (toggles.serverSide) {
      el.setAttribute('pagination-mode', 'server');
      el.totalRows = activeRows.length;
    } else {
      el.removeAttribute('pagination-mode');
    }
  }, [activeRows, activeColumns, registered, toggles]);

  const handleToggle = (key: keyof FeatureToggles) => {
    setToggles((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  if (!registered) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', mt: 10 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1, flexWrap: 'wrap' }}>
        <Typography variant="h5" fontWeight={700} sx={{ fontSize: { xs: 16, sm: 24 } }}>
          Showcase v1.0 — Todas las features
        </Typography>
        <Chip label="@zentto/datagrid v1.0" sx={{ bgcolor: '#7c3aed', color: '#fff' }} size="small" />
        <Chip label="17 features" variant="outlined" size="small" />
        <Chip label={`${activeRows.length} registros`} size="small" />
      </Box>

      {/* Feature toggles */}
      <Paper
        variant="outlined"
        sx={{ px: 2, py: 1, mb: 1.5, display: 'flex', flexWrap: 'wrap', gap: 0.5, alignItems: 'center' }}
      >
        <Typography variant="caption" fontWeight={600} sx={{ mr: 1, color: '#7c3aed' }}>
          CONTROLES:
        </Typography>
        <FormControlLabel
          control={<Switch size="small" checked={toggles.treeData} onChange={() => handleToggle('treeData')} color="secondary" />}
          label={<Typography variant="caption">Tree Data</Typography>}
        />
        <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.charts} onChange={() => handleToggle('charts')} color="secondary" />}
          label={<Typography variant="caption">Charts</Typography>}
        />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.print} onChange={() => handleToggle('print')} color="secondary" />}
          label={<Typography variant="caption">Print</Typography>}
        />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.audit} onChange={() => handleToggle('audit')} color="secondary" />}
          label={<Typography variant="caption">Audit Trail</Typography>}
        />
        <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.comments} onChange={() => handleToggle('comments')} color="secondary" />}
          label={<Typography variant="caption">Comments</Typography>}
        />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.cellMerge} onChange={() => handleToggle('cellMerge')} color="secondary" />}
          label={<Typography variant="caption">Cell Merge</Typography>}
        />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.pinnedRows} onChange={() => handleToggle('pinnedRows')} color="secondary" />}
          label={<Typography variant="caption">Row Pinning</Typography>}
        />
        <Divider orientation="vertical" flexItem sx={{ mx: 0.5 }} />
        <FormControlLabel
          control={<Switch size="small" checked={toggles.serverSide} onChange={() => handleToggle('serverSide')} color="secondary" />}
          label={<Typography variant="caption">Server-Side</Typography>}
        />
      </Paper>

      {/* Feature legend */}
      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5, mb: 1.5 }}>
        {[
          { label: 'Conditional Formatting', v: 'v0.4' },
          { label: 'Data Validation', v: 'v0.4' },
          { label: 'Dropdown Cells', v: 'v0.4' },
          { label: 'Live Formulas', v: 'v0.4' },
          { label: 'Tree Data', v: 'v0.5' },
          { label: 'Row Pinning', v: 'v0.5' },
          { label: 'Cell Merge', v: 'v0.5' },
          { label: 'Server-Side Mode', v: 'v0.6' },
          { label: 'Charts', v: 'v0.7' },
          { label: 'Print', v: 'v0.7' },
          { label: 'Custom Summaries', v: 'v0.7' },
          { label: 'Cell Comments', v: 'v0.7' },
          { label: 'Audit Trail', v: 'v0.8' },
          { label: 'Barcode', v: 'v0.8' },
          { label: 'Status Timeline', v: 'v0.8' },
          { label: 'AI Column', v: 'v0.8' },
          { label: 'Hyperlinks', v: 'v0.8' },
        ].map((f) => (
          <Chip
            key={f.label}
            label={`${f.v}: ${f.label}`}
            size="small"
            variant="outlined"
            sx={{ fontSize: 10, height: 22 }}
          />
        ))}
      </Box>

      {/* The Grid */}
      <zentto-grid
        ref={gridRef}
        default-currency="VES"
        export-filename="showcase-v1"
        height="calc(100vh - 290px)"
        grid-id="showcase-v1-lab"
        show-totals
        enable-toolbar
        enable-header-menu
        enable-header-filters
        enable-clipboard
        enable-find
        enable-quick-search
        enable-context-menu
        enable-status-bar
        enable-row-selection
        enable-filter-panel
        enable-import
        enable-configurator
        enable-drag-drop
        enable-undo-redo
        enable-range-selection
        enable-paste
        enable-editing
        enable-create
      ></zentto-grid>
    </Box>
  );
}

declare global {
  namespace JSX {
    interface IntrinsicElements {
      'zentto-grid': React.DetailedHTMLProps<React.HTMLAttributes<HTMLElement> & Record<string, any>, HTMLElement>;
    }
  }
}
