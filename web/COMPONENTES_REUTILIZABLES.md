# Arquitectura de Componentes Reutilizables

## 📋 Análisis Completo de la Migración VB6 → Web

### Módulos Legacy Identificados
| Módulo | Forms | Usuarios | Función Principal |
|--------|-------|----------|-------------------|
| **Admin** | 60 | Administrativos | Gestión cuentas, reportes, configuración |
| **PtoVenta** | 40 | Vendedores | Facturación, ventas, punto de venta |
| **Compras** | 35 | Gestores Compra | Compras, inventario, proveedores |
| **Configurador** | - | Admin Técnico | Configuración sistema |

### Entidades Principales (del análisis SQL)
```
CLIENTES          ← Gestión de clientes
PROVEEDORES       ← Gestión de proveedores
ARTICULOS         ← Catálogo de artículos
INVENTARIO        ← Stock y movimientos
FACTURAS          ← Documentos de venta
COMPRAS           ← Órdenes de compra
VENTAS            ← Transacciones de venta
PAGOS             ← Pagos de clientes
PAGOSC            ← Pagos a crédito
ABONOS            ← Abonos y devoluciones
P_PAGAR           ← Cuentas por pagar
```

### Patrones UI Recurrentes (de 135+ formularios)
1. **Tabla + Búsqueda** (60% de forms)
   - Lista de registros con filtros
   - Acciones: Ver, Editar, Eliminar
   - Paginación
   
2. **Formulario CRUD** (25% de forms)
   - Alta/Baja, modificación
   - Validaciones
   - Guardado/Cancelación

3. **Reportes y Exports** (10% de forms)
   - Listados con datos agregados
   - Excel, PDF, Vista previa

4. **Dialogs/Pickers** (5% de forms)
   - Selección de período
   - Confirmaciones
   - Búsqueda modal

---

## 🏗️ Arquitectura de Componentes - Niveles

### Nivel 1: Primitivos (Base)
```
components/
├── primitives/
│   ├── Button.tsx
│   ├── Input.tsx
│   ├── Select.tsx
│   ├── DatePicker.tsx
│   ├── Dialog.tsx
│   └── Card.tsx
```

### Nivel 2: Componentes Reutilizables
```
components/
├── common/
│   ├── DataGrid.tsx              ← Tabla genérica con paginación
│   ├── SearchBar.tsx             ← Búsqueda/Filtros
│   ├── CrudForm.tsx              ← Formulario genérico C-R-U-D
│   ├── ConfirmDialog.tsx         ← Dialogo de confirmación
│   ├── DateRangeSelector.tsx    ← Selector período
│   └── ExportButton.tsx          ← Exportar a CSV/PDF
```

### Nivel 3: Módulos Específicos
```
components/
├── modules/
│   ├── clientes/
│   │   ├── ClientesTable.tsx     ← Tabla clientes
│   │   ├── ClienteForm.tsx       ← Formulario cliente
│   │   └── useClientes.ts        ← Hook CRUD cliente
│   ├── proveedores/
│   │   ├── ProveedoresTable.tsx
│   │   ├── ProveedorForm.tsx
│   │   └── useProveedores.ts
│   ├── facturas/
│   │   ├── FacturasTable.tsx
│   │   ├── FacturaForm.tsx
│   │   └── useFacturas.ts
│   ├── articulos/
│   │   ├── ArticulosTable.tsx
│   │   ├── ArticuloForm.tsx
│   │   └── useArticulos.ts
│   ├── inventario/
│   │   ├── InventarioTable.tsx
│   │   ├── InventarioForm.tsx
│   │   └── useInventario.ts
│   └── ... (más módulos)
```

### Nivel 4: Páginas (App Router)
```
app/
├── (dashboard)/
│   ├── clientes/
│   │   ├── page.tsx              ← Listado
│   │   └── [id]/page.tsx         ← Detalle
│   ├── proveedores/
│   ├── facturas/
│   ├── articulos/
│   ├── inventario/
│   └── ...
```

---

## 🔄 Patrón de Reutilización por Módulo

### Ejemplo: Módulo CLIENTES

#### 1. Entity Type (TypeScript)
```typescript
// lib/types/clientes.ts
export interface Cliente {
  codigo: string;
  nombre: string;
  rif: string;
  direccion: string;
  telefono: string;
  email: string;
  estado: 'Activo' | 'Inactivo';
  fechaCreacion: Date;
  saldo: number;
}

export interface CreateClienteDTO {
  nombre: string;
  rif: string;
  direccion: string;
  telefono: string;
  email: string;
}

export interface UpdateClienteDTO extends Partial<CreateClienteDTO> {}

export interface ClienteFilter {
  search?: string;
  estado?: 'Activo' | 'Inactivo';
  fechaDesde?: Date;
  fechaHasta?: Date;
}
```

#### 2. API Hook (TanStack Query)
```typescript
// hooks/useClientes.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';

export function useClientesList(filter?: ClienteFilter) {
  return useQuery({
    queryKey: ['clientes', filter],
    queryFn: async () => {
      const res = await fetch('/api/v1/clientes', {
        params: filter
      });
      return res.json();
    }
  });
}

export function useClienteById(codigo: string) {
  return useQuery({
    queryKey: ['clientes', codigo],
    queryFn: async () => {
      const res = await fetch(`/api/v1/clientes/${codigo}`);
      return res.json();
    }
  });
}

export function useCreateCliente() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateClienteDTO) =>
      fetch('/api/v1/clientes', { method: 'POST', body: JSON.stringify(data) }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['clientes'] })
  });
}

export function useUpdateCliente(codigo: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: UpdateClienteDTO) =>
      fetch(`/api/v1/clientes/${codigo}`, { method: 'PUT', body: JSON.stringify(data) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clientes'] });
      queryClient.invalidateQueries({ queryKey: ['clientes', codigo] });
    }
  });
}

export function useDeleteCliente(codigo: string) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: () =>
      fetch(`/api/v1/clientes/${codigo}`, { method: 'DELETE' }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['clientes'] })
  });
}
```

#### 3. Tabla Genérica Adaptada
```typescript
// components/modules/clientes/ClientesTable.tsx
import { useClientesList, useDeleteCliente } from '@/hooks/useClientes';
import DataGrid from '@/components/common/DataGrid';
import { Cliente } from '@/lib/types/clientes';

export default function ClientesTable() {
  const { data, isLoading } = useClientesList();
  const { mutate: deleteCliente } = useDeleteCliente('');

  const columns = [
    { accessor: 'codigo', Header: 'Código' },
    { accessor: 'nombre', Header: 'Nombre' },
    { accessor: 'rif', Header: 'RIF' },
    { accessor: 'email', Header: 'Email' },
    { accessor: 'saldo', Header: 'Saldo', formatFn: (v) => `$${v.toFixed(2)}` },
    { accessor: 'estado', Header: 'Estado' },
  ];

  const actions = [
    {
      label: 'Ver',
      icon: 'eye',
      onClick: (row: Cliente) => router.push(`/clientes/${row.codigo}`)
    },
    {
      label: 'Editar',
      icon: 'edit',
      onClick: (row: Cliente) => openEdit(row)
    },
    {
      label: 'Eliminar',
      icon: 'trash',
      onClick: (row: Cliente) => confirmDelete(row.codigo),
      color: 'error'
    }
  ];

  return (
    <DataGrid
      columns={columns}
      data={data?.items || []}
      totalRecords={data?.total}
      isLoading={isLoading}
      actions={actions}
      onAction={handleAction}
    />
  );
}
```

#### 4. Formulario Genérico Adaptado
```typescript
// components/modules/clientes/ClienteForm.tsx
import CrudForm from '@/components/common/CrudForm';
import { useCreateCliente, useUpdateCliente } from '@/hooks/useClientes';
import { CreateClienteDTO } from '@/lib/types/clientes';

const schema = zod.object({
  nombre: zod.string().min(1, 'Nombre requerido'),
  rif: zod.string().min(1, 'RIF requerido'),
  direccion: zod.string(),
  telefono: zod.string(),
  email: zod.string().email('Email inválido')
});

export default function ClienteForm({ initial, onSuccess }: Props) {
  const { mutate: create } = useCreateCliente();
  const { mutate: update } = useUpdateCliente(initial?.codigo || '');

  const fields = [
    { name: 'nombre', label: 'Nombre', type: 'text', required: true },
    { name: 'rif', label: 'RIF', type: 'text', required: true },
    { name: 'direccion', label: 'Dirección', type: 'textarea' },
    { name: 'telefono', label: 'Teléfono', type: 'tel' },
    { name: 'email', label: 'Email', type: 'email' },
  ];

  return (
    <CrudForm
      fields={fields}
      schema={schema}
      initialValues={initial}
      onSave={(data) => initial ? update(data) : create(data)}
      onSuccess={onSuccess}
    />
  );
}
```

---

## 📦 Componentes Genéricos - Especificaciones

### DataGrid (Tabla Genérica)
```typescript
// components/common/DataGrid.tsx
interface DataGridProps<T> {
  columns: Column<T>[];
  data: T[];
  totalRecords?: number;
  pageSize?: number;
  isLoading?: boolean;
  actions?: Action<T>[];
  filters?: Filter[];
  onRowClick?: (row: T) => void;
  onAction?: (action: string, row: T) => void;
  sortable?: boolean;
  selectable?: boolean;
  exportable?: boolean;
}

// Características:
// - Paginación
// - Ordenamiento
// - Búsqueda
// - Filtros
// - Actions (Ver, Editar, Eliminar)
// - Exportar a CSV
// - Selección múltiple
```

### CrudForm (Formulario Genérico)
```typescript
// components/common/CrudForm.tsx
interface CrudFormProps {
  fields: FormField[];
  schema: ZodSchema;
  initialValues?: Record<string, any>;
  onSave: (data: any) => Promise<void>;
  onCancel?: () => void;
  onSuccess?: (result: any) => void;
  isLoading?: boolean;
}

// Características:
// - Validación con Zod
// - Campos dinámicos
// - Mensajes de error
// - Submit/Cancel
// - Estados (errores, loading, success)
```

### SearchBar (Búsqueda Reutilizable)
```typescript
// components/common/SearchBar.tsx
interface SearchBarProps {
  placeholder?: string;
  onSearch: (query: string) => void;
  filters?: FilterOption[];
  onFilterChange?: (filters: Record<string, any>) => void;
  debounce?: number;
}

// Características:
// - Input de búsqueda
// - Filtros dropdown
// - Búsqueda en tiempo real (debounce)
```

---

## 🎯 Reutilización Práctica - 3 Ejemplos

### ✅ Ejemplo 1: PROVEEDORES (igual que CLIENTES)
- Usar **DataGrid** + **CrudForm** + **useProveedores** hook
- Cambiar solo: tipos, URLs de API, campos del formulario
- Código: ~200 líneas

### ✅ Ejemplo 2: ARTÍCULOS (con variantes)
- Usar **DataGrid** + **CrudForm** + **useArticulos** hook
- Agregar: categoría, precio, stock
- Código: ~250 líneas

### ✅ Ejemplo 3: INVENTARIO (lectura + reporte)
- Usar **DataGrid** + **SearchBar** (sin formulario)
- Agregar: búsqueda por código, filtro por almacén
- Códig: ~150 líneas

---

## 🔗 Integración con API (Flujo)

### Backend (NestJS/Express) genera:
```
GET    /v1/clientes?page=1&limit=10&search=juan
POST   /v1/clientes
GET    /v1/clientes/:codigo
PUT    /v1/clientes/:codigo
DELETE /v1/clientes/:codigo
```

### Frontend (React) consume:
```
useClientesList(filter)     → GET /v1/clientes
useClienteById(codigo)      → GET /v1/clientes/:codigo
useCreateCliente()          → POST /v1/clientes
useUpdateCliente(codigo)    → PUT /v1/clientes/:codigo
useDeleteCliente(codigo)    → DELETE /v1/clientes/:codigo
```

---

## 📋 Checklist de Implementación

### Fase 1: Primitivos
- [ ] Button, Input, Select, DatePicker, Dialog, Card

### Fase 2: Componentes Genéricos
- [ ] DataGrid con sorting, paginación, búsqueda
- [ ] CrudForm con validación Zod
- [ ] SearchBar con filtros
- [ ] ConfirmDialog
- [ ] DateRangeSelector
- [ ] ExportButton (CSV)

### Fase 3: Tipos Compartidos
- [ ] Cliente, Proveedor, Articulo, Inventario, etc.
- [ ] DTO para C-R-U-D
- [ ] Filter interfaces

### Fase 4: Hooks Reutilizables
- [ ] useClientesList / useProveedoresList / useArticulosList
- [ ] useCreate / useUpdate / useDelete pattern

### Fase 5: Módulos Específicos
- [ ] Clientes (Tabla + Form)
- [ ] Proveedores (Tabla + Form)
- [ ] Artículos (Tabla + Form)
- [ ] Inventario (Tabla + Búsqueda)
- [ ] Facturas (Tabla + Detalle)
- [ ] ... (resto de módulos)

---

## 🚀 Ventajas de esta Arquitectura

1. **DRY** - Escribe una vez, usa en todos los módulos
2. **Escalable** - Agregar módulo = 50-100 líneas
3. **Mantenible** - Cambios en DataGrid se propagan automáticamente
4. **Type-Safe** - TypeScript para todas las entidades
5. **Performante** - React Query cachea automáticamente
6. **Observable** - Todos los módulos siguen el mismo patrón

