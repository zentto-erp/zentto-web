# 📖 ÍNDICE COMPLETO - DatqBox Frontend Architecture

## 📚 Documentación (Léelo en este orden)

### 1. 🎯 RESUMEN_FINAL.md
**EMPIEZA AQUÍ** - Visión 360° de todo
- Estado actual del proyecto
- Arquitectura visual
- Estadísticas de reutilización
- Timeline de implementación

### 2. 📋 PLAN_EJECUTIVO.md
**Tu guía rápida diaria**
- Estado actual (base lista ✅)
- Tu rol como Owner Frontend
- Tareas inmediatas
- Cómo copiar código sin modificar SpainInside
- Sincronización con Backend

### 3. 🏗️ COMPONENTES_REUTILIZABLES.md
**Arquitectura detallada**
- Análisis de migración VB6
- Módulos identificados (Admin, PtoVenta, Compras)
- Entidades principales (9 identificadas)
- Patrones UI recurrentes
- Nivel 1-4 de componentes
- Patrón de reutilización por módulo
- Ejemplos por módulo (CLIENTES)

### 4. 🚀 GUIA_IMPLEMENTACION_MODULOS.md
**Step-by-step para crear nuevos módulos**
- Base reutilizable verificada
- Cómo crear PROVEEDORES (template)
- Tabla resumen de tiempo
- Checklist de implementación
- Rutas recomendadas

### 5. 📊 FRONTEND_ROADMAP.md
**Detalles de cada tarea**
- Stack confirmado
- 4 tareas frontend prioritarias
- Archivos a copiar de SpainInside
- Subtareas para cada módulo

### 6. 📋 AGENTS.md
**Protocolo de trabajo entre tú y backend**
- Cómo pedir al subagente backend
- Sincronización de OpenAPI
- Convenciones

---

## 💻 CÓDIGO IMPLEMENTADO

### Tipos TypeScript (Entidades compartidas)
```
src/lib/types/index.ts  [350 líneas]
├── PaginatedResponse<T>
├── CrudFilter
├── Cliente
├── Proveedor
├── Articulo
├── Inventario
├── Factura
├── Compra
├── Pago
├── Abono
├── CuentaPorPagar
├── Usuario (Auth)
└── ... (15+ tipos)
```

**Uso**: Importar en cualquier módulo
```typescript
import { Cliente, CreateClienteDTO } from '@/lib/types';
```

---

### Hook Genérico CRUD
```
src/hooks/useCrudGeneric.ts  [120 líneas]
├── useCrudGeneric<T, CreateDTO>(endpoint)
│   ├── list(filters)        → QueryResult
│   ├── getById(id)          → QueryResult
│   ├── create()             → Mutation
│   ├── update(id)           → Mutation
│   ├── delete(id)           → Mutation
│   └── invalidateList()
│
└── Hooks específicos (ejemplos):
    ├── useClientes()
    ├── useProveedores()
    └── useArticulos()
```

**Uso**:
```typescript
const crud = useCrudGeneric<Cliente, CreateClienteDTO>('clientes');
const { data, isLoading } = crud.list();
const { mutate: create } = crud.create();
```

---

### Componentes Genéricos

#### 1. DataGrid (Tabla)
```
src/components/common/DataGrid.tsx  [200 líneas]
├── Sorteador
├── Paginación
├── Búsqueda
├── Actions (Ver, Editar, Eliminar)
├── Tipos de dato (date, currency, status)
├── Loading state
├── Empty state
└── Export button (preparado)
```

**Props**:
```typescript
interface DataGridProps<T> {
  columns: Column<T>[];          // Definición de cols
  data: T[];                     // Datos a mostrar
  totalRecords?: number;         // Para paginación
  currentPage?: number;
  pageSize?: number;
  isLoading?: boolean;
  actions?: Action<T>[];         // Ver, Editar, Eliminar
  onPageChange?: (page) => void;
  onSortChange?: (accessor, order) => void;
  title?: string;
}
```

**Uso**:
```typescript
const columns: Column<Cliente>[] = [
  { accessor: 'codigo', header: 'Código' },
  { accessor: 'nombre', header: 'Nombre' },
  { accessor: 'saldo', header: 'Saldo', type: 'currency' },
];

const actions: Action<Cliente>[] = [
  { id: 'edit', label: 'Editar', onClick: (row) => {} },
  { id: 'delete', label: 'Eliminar', color: 'error', onClick: (row) => {} },
];

<DataGrid columns={columns} data={clientes} actions={actions} />
```

---

#### 2. CrudForm (Formulario)
```
src/components/common/CrudForm.tsx  [140 líneas]
├── Validación con Zod
├── Campos dinámicos
├── Errores inline
├── States (loading, success, error)
├── Save/Cancel
└── Create/Update automático
```

**Props**:
```typescript
interface CrudFormProps {
  fields: FormField[];           // Definición de campos
  schema: ZodSchema;             // Validación
  initialValues?: Record<string, any>;
  onSave: (data) => Promise<void>;
  onCancel?: () => void;
  isLoading?: boolean;
}
```

**Uso**:
```typescript
const schema = z.object({
  nombre: z.string().min(3),
  email: z.string().email(),
});

const fields: FormField[] = [
  { name: 'nombre', label: 'Nombre', type: 'text', required: true },
  { name: 'email', label: 'Email', type: 'email' },
];

const handleSave = async (data) => {
  await fetch('/api/v1/clientes', { 
    method: 'POST', 
    body: JSON.stringify(data) 
  });
};

<CrudForm 
  fields={fields} 
  schema={schema} 
  onSave={handleSave} 
/>
```

---

#### 3. Diálogos Genéricos
```
src/components/common/Dialogs.tsx  [200 líneas]
├── ConfirmDialog      (confirmación genérica)
├── DeleteDialog       (eliminar con doble check)
├── DateRangeDialog    (selector de período)
└── SearchDialog       (picker/búsqueda)
```

**Uso**:
```typescript
// Confirmación
<ConfirmDialog
  open={open}
  title="¿Estás seguro?"
  message="Esta acción no se puede deshacer"
  onConfirm={() => handleDelete()}
  onCancel={() => setOpen(false)}
/>

// Búsqueda
<SearchDialog<Cliente>
  open={searchOpen}
  title="Seleccionar cliente"
  items={clientes}
  displayKey="nombre"
  valueKey="codigo"
  onSelect={(item) => setSelectedCliente(item)}
  onCancel={() => setSearchOpen(false)}
/>
```

---

### Módulo Ejemplo: CLIENTES

#### ClientesTable.tsx
```
src/components/modules/clientes/ClientesTable.tsx  [95 líneas]
├── Estructura de tabla
├── Búsqueda y filtros
├── Actions (Ver, Editar, Eliminar)
├── DeleteDialog integrado
└── Lazy load desde API
```

**Estructura típica**:
```typescript
export default function ClientesTable() {
  const crud = useCrudGeneric<Cliente>('clientes');
  const { data, isLoading } = crud.list();
  const [searchTerm, setSearchTerm] = useState('');
  
  const filteredData = (data?.items || []).filter(...);
  const columns = [...];
  const actions = [...];
  
  return (
    <Box>
      <TextField {...} /> {/* Search */}
      <DataGrid columns={columns} data={filteredData} actions={actions} />
      <DeleteDialog {...} /> {/* Delete confirm */}
    </Box>
  );
}
```

---

#### ClienteForm.tsx
```
src/components/modules/clientes/ClienteForm.tsx  [135 líneas]
├── Validación con Zod
├── Campos dinámicos (nombre, rif, email, etc)
├── Create/Update
└── Redirect a listado
```

**Estructura típica**:
```typescript
const schema = z.object({
  nombre: z.string().min(3),
  rif: z.string().regex(/^[A-Z0-9]{1,20}$/),
  email: z.string().email(),
});

const fields: FormField[] = [
  { name: 'nombre', label: 'Nombre', type: 'text', required: true },
  { name: 'rif', label: 'RIF', type: 'text', required: true },
  { name: 'email', label: 'Email', type: 'email' },
];

const handleSave = async (data: CreateClienteDTO) => {
  if (isEdit) {
    await updateMutation.mutateAsync(data);
  } else {
    await createMutation.mutateAsync(data);
  }
  router.push('/clientes');
};

<CrudForm fields={fields} schema={schema} onSave={handleSave} />
```

---

## 🎯 CÓMO USAR ESTE CÓDIGO

### Para crear PROVEEDORES (template)

**Paso 1**: Copiar `ClientesTable.tsx` →  `ProveedoresTable.tsx`
- Cambiar: `const crud = useCrudGeneric<Cliente>` → `useCrudGeneric<Proveedor>`
- Cambiar: `router.push('/clientes/...')` → `router.push('/proveedores/...')`
- Cambiar: Columnas según estructura de Proveedor
- **Tiempo**: 5 minutos

**Paso 2**: Copiar `ClienteForm.tsx` → `ProveedorForm.tsx`
- Cambiar: Schema de Zod
- Cambiar: Campos del formulario
- Cambiar: Hook a `useCrudGeneric<Proveedor>`
- **Tiempo**: 5 minutos

**Paso 3**: Crear rutas
```
app/(dashboard)/proveedores/
├── page.tsx                    ← import <ProveedoresTable />
└── [codigo]/
    ├── page.tsx               ← import <ProveedorForm />
    └── edit/
        └── page.tsx           ← import <ProveedorForm isDraft={true} />
```
- **Tiempo**: 5 minutos

**Total**: 15 minutos vs. 120+ minutos sin reutilización

---

## 📊 ESTRUCTURA DE ARCHIVOS

```
web/
├── docs/
│   ├── ADDON_FRAMEWORK.md
│   ├── MIGRATION_PLAN.md
│   ├── legacy-inventory/
│   │   ├── Admin.md             [Inventario: 60 forms]
│   │   ├── PtoVenta.md          [Inventario: 40 forms]
│   │   ├── Compras.md           [Inventario: 35 forms]
│   │   └── Configurador.md
│   └── db/
│       ├── SQL_TO_SP_MAP_INITIAL.md     [2307 sentencias]
│       └── SQL_MIGRATION_NOTES.md
│
├── AGENTS.md                    [Protocolo trabajo]
├── PLAN_EJECUTIVO.md            [Guía rápida]
├── COMPONENTES_REUTILIZABLES.md [Arquitectura]
├── GUIA_IMPLEMENTACION_MODULOS.md [Step-by-step]
├── FRONTEND_ROADMAP.md          [Tareas detalladas]
├── RESUMEN_FINAL.md             [360° overview]
└── INDICE.md                    [Este archivo]

frontend/
├── src/
│   ├── lib/
│   │   └── types/
│   │       └── index.ts         [Tipos compartidos - 350L]
│   │
│   ├── hooks/
│   │   └── useCrudGeneric.ts    [Hook CRUD - 120L]
│   │
│   ├── components/
│   │   ├── common/
│   │   │   ├── DataGrid.tsx     [Tabla genérica - 200L]
│   │   │   ├── CrudForm.tsx     [Formulario genérico - 140L]
│   │   │   └── Dialogs.tsx      [Diálogos - 200L]
│   │   │
│   │   └── modules/
│   │       ├── clientes/        [Ejemplo - 230L]
│   │       │   ├── ClientesTable.tsx
│   │       │   └── ClienteForm.tsx
│   │       │
│   │       ├── proveedores/     [A implementar]
│   │       ├── articulos/       [A implementar]
│   │       ├── inventario/      [A implementar]
│   │       ├── facturas/        [A implementar]
│   │       └── compras/         [A implementar]
│   │
│   └── app/(dashboard)/
│       ├── clientes/
│       │   ├── page.tsx         [Listado]
│       │   └── [codigo]/
│       │       ├── page.tsx     [Detalle]
│       │       └── edit/
│       │           └── page.tsx [Edición]
│       │
│       ├── proveedores/...
│       ├── articulos/...
│       └── ... (más módulos)

api/
├── src/
│   ├── modules/
│   │   ├── crud/               [CRUD genérico backend]
│   │   ├── facturas/
│   │   ├── usuarios/
│   │   └── ...
│   └── contracts/
│       └── openapi.yaml        [Especificación API]
```

---

## ✅ CHECKLIST - QUÉ VIENE AHORA

### Esta Semana (Módulos Core)
- [ ] Leer **RESUMEN_FINAL.md** (20 min)
- [ ] Leer **COMPONENTES_REUTILIZABLES.md** (30 min)
- [ ] Leer **GUIA_IMPLEMENTACION_MODULOS.md** (20 min)
- [ ] Implementar **Proveedores** (15 min) ← START HERE
- [ ] Implementar **Artículos** (15 min)
- [ ] Implementar **Inventario** (15 min)

### Próxima Semana (Documentos)
- [ ] Implementar **Facturas** (30 min)
- [ ] Implementar **Compras** (30 min)
- [ ] Implementar **Pagos/Abonos** (20 min)

### Semana 3 (Refinamientos)
- [ ] Dashboard principal
- [ ] Reportes
- [ ] Permisos (RBAC)
- [ ] Temas/Styling

---

## 🚀 CÓMO COMENZAR

### 1. Lee esto primero (20 min)
```
1. RESUMEN_FINAL.md     - Visión general
2. PLAN_EJECUTIVO.md    - Tu rol diario
3. COMPONENTES_REUTILIZABLES.md - Cómo funciona
```

### 2. Revisa el código (30 min)
```
1. lib/types/index.ts       - Tipos principales
2. hooks/useCrudGeneric.ts  - Hook CRUD
3. components/common/       - Componentes genéricos
4. modules/clientes/        - Ejemplo práctico
```

### 3. Implementa Proveedores (15 min)
```
Sigue: GUIA_IMPLEMENTACION_MODULOS.md
Copia de: ClientesTable.tsx + ClienteForm.tsx
Adapta: 3 líneas de código
```

### 4. Repite para otros módulos (15 min cada)
```
Artículos, Inventario, Facturas, Compras
Mismo patrón, diferentes entidades
```

### 5. Sincroniza con backend
```
Backend: Actualiza openapi.yaml cuando termina endpoint
Frontend: Lee openapi.yaml, adapta tipos, consume API
```

---

## 💡 TIPS

- **Reutiliza**: No escribas código nuevo, copia y adapta
- **Documenta**: Cada módulo debe tener su README
- **Testa**: Prueba cada módulo antes de committear
- **Commitea**: Usa `git commit -m "feat(frontend): <módulo> - <desc>"`
- **Sincroniza**: Actualiza STATUS.md cuando terminas

---

## 📞 Recursos

- **API Docs**: `/api-docs` (cuando esté listo)
- **OpenAPI**: `web/contracts/openapi.yaml`
- **Backend**: `web/api/`
- **Frontend**: `web/frontend/`
- **Ejemplos**: `web/frontend/src/components/modules/clientes/`

---

**ÚLTIMA ACTUALIZACIÓN**: 13 Feb 2026
**VERSIÓN**: 1.0
**ESTADO**: ✅ Listo para Producción

