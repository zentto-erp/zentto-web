# Guía de Implementación de Módulos Frontend - Template Reutilizable

## ✅ Arquitectura Implementada

Ya tenemos la **base reutilizable lista**:

```
src/
├── lib/types/index.ts              ← Tipos para todas las entidades
├── hooks/useCrudGeneric.ts         ← Hook genérico CRUD
├── components/common/
│   ├── DataGrid.tsx                ← Tabla reutilizable
│   ├── CrudForm.tsx                ← Formulario reutilizable
│   └── Dialogs.tsx                 ← Diálogos (Confirm, Delete, DateRange)
└── components/modules/clientes/    ← EJEMPLO COMPLETO (plantilla)
    ├── ClientesTable.tsx           ← Tabla adaptada
    └── ClienteForm.tsx             ← Formulario adaptado
```

---

## 🚀 Cómo crear un NUEVO MÓDULO (Ej: PROVEEDORES)

### Paso 1: Extender los TIPOS (lib/types/index.ts)

✅ **YA ESTÁ HECHO** - Los tipos para Proveedor ya existen:

```typescript
// Ya en lib/types/index.ts
export interface Proveedor { ... }
export interface CreateProveedorDTO { ... }
export interface UpdateProveedorDTO { ... }
export interface ProveedorFilter { ... }
```

### Paso 2: Crear la TABLA (components/modules/proveedores/ProveedoresTable.tsx)

```bash
mkdir -p src/components/modules/proveedores
```

**Copiar y adaptar desde**: `components/modules/clientes/ClientesTable.tsx`

Cambios necesarios:

```typescript
// De:
const crud = useCrudGeneric<Cliente>('clientes');

// A:
const crud = useCrudGeneric<Proveedor>('proveedores');

// ========

// De:
const columns: Column<Cliente>[] = [
  { accessor: 'codigo', header: 'Código', ... },
  { accessor: 'nombre', header: 'Nombre', ... },
  // ... columnas cliente
];

// A:
const columns: Column<Proveedor>[] = [
  { accessor: 'codigo', header: 'Código', ... },
  { accessor: 'nombre', header: 'Nombre', ... },
  { accessor: 'razonSocial', header: 'Razón Social', ... },
  // ... columnas proveedor (adaptar según estructura)
];

// ========

// De:
router.push(\`/clientes/\${row.codigo}\`)

// A:
router.push(\`/proveedores/\${row.codigo}\`)
```

**ProveedoresTable.tsx** (80% del código es idéntico a ClientesTable.tsx):

```typescript
'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Box, Button, TextField, Stack } from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import DataGrid, { Column, Action } from '@/components/common/DataGrid';
import { DeleteDialog } from '@/components/common/Dialogs';
import { useCrudGeneric } from '@/hooks/useCrudGeneric';
import { Proveedor } from '@/lib/types';

export default function ProveedoresTable() {
  const router = useRouter();
  const crud = useCrudGeneric<Proveedor>('proveedores');
  const { data, isLoading } = crud.list();
  const [searchTerm, setSearchTerm] = useState('');
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState<Proveedor | null>(null);
  const { mutate: deleteProveedor, isPending: isDeleting } = crud.delete('');

  const filteredData = (data?.items || []).filter(
    (item) =>
      item.nombre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.rif.includes(searchTerm)
  );

  const columns: Column<Proveedor>[] = [
    { accessor: 'codigo', header: 'Código', sortable: true, width: '80px' },
    { accessor: 'nombre', header: 'Nombre', sortable: true },
    { accessor: 'rif', header: 'RIF', sortable: true, width: '100px' },
    { accessor: 'email', header: 'Email' },
    { accessor: 'saldo', header: 'Saldo', type: 'currency', width: '120px' },
  ];

  const actions: Action<Proveedor>[] = [
    {
      id: 'view',
      label: 'Ver',
      onClick: (row) => router.push(\`/proveedores/\${row.codigo}\`),
    },
    {
      id: 'edit',
      label: 'Editar',
      onClick: (row) => router.push(\`/proveedores/\${row.codigo}/edit\`),
    },
    {
      id: 'delete',
      label: 'Eliminar',
      color: 'error',
      onClick: (row) => {
        setSelectedItem(row);
        setDeleteOpen(true);
      },
    },
  ];

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 3 }}>
        <h1>Gestión de Proveedores</h1>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => router.push('/proveedores/new')}
        >
          Nuevo Proveedor
        </Button>
      </Box>

      <TextField
        placeholder="Buscar por nombre o RIF..."
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
        fullWidth
        size="small"
        sx={{ mb: 3 }}
      />

      <DataGrid<Proveedor>
        columns={columns}
        data={filteredData}
        isLoading={isLoading}
        actions={actions}
        title={`${filteredData.length} proveedores`}
      />

      <DeleteDialog
        open={deleteOpen}
        itemName={selectedItem?.nombre || ''}
        onConfirm={() => {
          if (selectedItem) deleteProveedor(selectedItem.codigo);
          setDeleteOpen(false);
        }}
        onCancel={() => setDeleteOpen(false)}
        isLoading={isDeleting}
      />
    </Box>
  );
}
```

**Líneas: ~80** (95% copiado de ClientesTable.tsx)

---

### Paso 3: Crear el FORMULARIO (components/modules/proveedores/ProveedorForm.tsx)

**Copiar y adaptar desde**: `components/modules/clientes/ClienteForm.tsx`

Cambios necesarios:

```typescript
// De:
const clienteSchema = z.object({
  nombre: z.string().min(3),
  rif: z.string(),
  direccion: z.string(),
  telefono: z.string(),
  email: z.string().email(),
});

// A:
const proveedorSchema = z.object({
  nombre: z.string().min(3),
  rif: z.string(),
  razonSocial: z.string(),
  direccion: z.string(),
  telefono: z.string(),
  email: z.string().email(),
  // agregar campos específicos si los hay
});

// ========

// De:
const crud = useCrudGeneric<Cliente, CreateClienteDTO>('clientes');

// A:
const crud = useCrudGeneric<Proveedor, CreateProveedorDTO>('proveedores');
```

**ProveedorForm.tsx** (90% idéntico a ClienteForm.tsx):

```typescript
'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { z } from 'zod';
import { Box, CircularProgress, Alert } from '@mui/material';
import CrudForm from '@/components/common/CrudForm';
import { useCrudGeneric } from '@/hooks/useCrudGeneric';
import { Proveedor, CreateProveedorDTO, FormField } from '@/lib/types';

const proveedorSchema = z.object({
  nombre: z.string().min(3, 'Mínimo 3 caracteres'),
  rif: z.string().regex(/^[A-Z0-9]{1,20}$/, 'RIF inválido'),
  razonSocial: z.string().min(3),
  direccion: z.string().min(5),
  telefono: z.string().optional(),
  email: z.string().email().optional(),
});

type ProveedorFormData = z.infer<typeof proveedorSchema>;

const formFields: FormField[] = [
  { name: 'nombre', label: 'Nombre', type: 'text', required: true },
  { name: 'rif', label: 'RIF', type: 'text', required: true },
  { name: 'razonSocial', label: 'Razón Social', type: 'text', required: true },
  { name: 'direccion', label: 'Dirección', type: 'textarea', required: true },
  { name: 'telefono', label: 'Teléfono', type: 'tel' },
  { name: 'email', label: 'Email', type: 'email' },
];

export default function ProveedorForm({ proveedorCodigo }: { proveedorCodigo?: string }) {
  const router = useRouter();
  const crud = useCrudGeneric<Proveedor, CreateProveedorDTO>('proveedores');
  const [initialData, setInitialData] = useState<ProveedorFormData | null>(null);
  const [isLoading, setIsLoading] = useState(!!proveedorCodigo);

  useEffect(() => {
    if (!proveedorCodigo) {
      setIsLoading(false);
      return;
    }

    (async () => {
      try {
        const res = await fetch(\`/api/v1/proveedores/\${proveedorCodigo}\`);
        const data = await res.json();
        setInitialData(data);
      } finally {
        setIsLoading(false);
      }
    })();
  }, [proveedorCodigo]);

  const createMutation = crud.create();
  const updateMutation = proveedorCodigo ? crud.update(proveedorCodigo) : null;

  const handleSave = async (data: CreateProveedorDTO) => {
    const mutation = proveedorCodigo ? updateMutation : createMutation;
    await new Promise((resolve, reject) => {
      mutation?.mutate(data, {
        onSuccess: () => {
          router.push('/proveedores');
          resolve(null);
        },
        onError: reject,
      });
    });
  };

  if (isLoading) return <CircularProgress />;

  return (
    <Box>
      <h1>{proveedorCodigo ? 'Editar Proveedor' : 'Nuevo Proveedor'}</h1>
      <CrudForm
        fields={formFields}
        schema={proveedorSchema}
        initialValues={initialData || {}}
        onSave={handleSave}
        onCancel={() => router.push('/proveedores')}
      />
    </Box>
  );
}
```

**Líneas: ~90** (95% copiado de ClienteForm.tsx)

---

## 📊 Tabla Resumen - Tiempo de Desarrollo

| Módulo | Tabla | Formulario | Total | Basado en |
|--------|-------|-----------|-------|-----------|
| **Clientes** | 80 L (nuevo) | 120 L (nuevo) | **200 L** | - |
| **Proveedores** | 80 L (copia) | 90 L (copia) | **170 L** | Clientes |
| **Artículos** | 85 L (adapta) | 100 L (adapta) | **185 L** | Clientes |
| **Inventario** | 90 L (lectura) | - | **90 L** | DataGrid |
| **Facturas** | 100 L (detalles) | 150 L (múltiple) | **250 L** | Clientes + Custom |

**Total para todos los módulos: ~1,000 líneas de UI**
- 70% reutilización de código
- 30% adaptaciones específicas

---

## 🎯 Checklist: Implementar PROVEEDORES (20 min)

- [ ] Crear carpeta: `src/components/modules/proveedores/`
- [ ] Copiar `ClientesTable.tsx` → `ProveedoresTable.tsx` (adaptar)
- [ ] Copiar `ClienteForm.tsx` → `ProveedorForm.tsx` (adaptar)
- [ ] Crear rutas en `app/(dashboard)/proveedores/`
- [ ] Crear `page.tsx` que importe `ProveedoresTable`
- [ ] Crear `[codigo]/page.tsx` que importe `ProveedorForm`
- [ ] Crear `[codigo]/edit/page.tsx`
- [ ] Actualizar `STATUS.md` → "Proveedores: Hecho"

---

## 🔗 Rutas a Crear (App Router)

```
app/(dashboard)/
├── clientes/
│   ├── page.tsx              ← <ClientesTable />
│   └── [codigo]/
│       ├── page.tsx          ← <ClienteForm clienteCodigo={codigo} />
│       └── edit/
│           └── page.tsx      ← <ClienteForm clienteCodigo={codigo} isDraft={true} />
├── proveedores/
│   ├── page.tsx              ← <ProveedoresTable />
│   └── [codigo]/
│       ├── page.tsx          ← <ProveedorForm proveedorCodigo={codigo} />
│       └── edit/
│           └── page.tsx
├── articulos/
├── inventario/
├── facturas/
└── compras/
```

---

## ✨ Ventajas de Esta Arquitectura

1. **DRY**: 70% código reutilizable
2. **Escalable**: Agregar módulo = 30 min trabajo
3. **Consistente**: Todos los módulos igual UI/UX
4. **Mantenible**: Cambios en DataGrid = automático en todos
5. **Type-Safe**: TypeScript para todas las entidades
6. **Performante**: React Query cachea automáticamente

---

## 📋 Próximas Etapas

### Implementadas ✅
- [x] Tipos compartidos
- [x] Hook genérico CRUD
- [x] DataGrid reutilizable
- [x] CrudForm reutilizable
- [x] Diálogos genéricos
- [x] Ejemplo completo: CLIENTES

### A Implementar
- [ ] Módulo PROVEEDORES (20 min)
- [ ] Módulo ARTÍCULOS (20 min)
- [ ] Módulo INVENTARIO (15 min - solo lectura)
- [ ] Módulo FACTURAS (30 min - con detalles)
- [ ] Módulo COMPRAS (30 min)
- [ ] Dashboard principal
- [ ] Reportes

---

## 🚀 Comenzar AHORA

1. Lee `COMPONENTES_REUTILIZABLES.md` para entender la arquitectura
2. Revisa `components/modules/clientes/` para ver ejemplo completo
3. Crea `components/modules/proveedores/` copiando de clientes
4. Adapta tipos y rutas según necesario
5. Prueba en `http://localhost:3000/proveedores`

¿Empezamos con PROVEEDORES? 🎯

