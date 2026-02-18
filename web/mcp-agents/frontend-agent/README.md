# Frontend Agent - DatQBox

Agente MCP especializado para desarrollo Next.js + React + MUI.

## Herramientas Disponibles

### 1. `create_page`
Crea una nueva página en el App Router de Next.js.

**Parámetros:**
- `path` (string): Ruta de la página (ej: "clientes", "facturas/nueva")
- `isDashboard` (boolean): Si debe estar en el layout del dashboard
- `title` (string): Título de la página

**Ejemplo:**
```typescript
{
  path: "clientes",
  isDashboard: true,
  title: "Gestión de Clientes"
}
```

### 2. `create_component`
Crea un nuevo componente React.

**Parámetros:**
- `name` (string): Nombre del componente (PascalCase)
- `type` (string): Tipo (common, module, form, table, dialog)
- `moduleName` (string, opcional): Nombre del módulo si es tipo module

**Ejemplo:**
```typescript
{
  name: "ClienteCard",
  type: "module",
  moduleName: "clientes"
}
```

### 3. `create_tanstack_hook`
Crea un hook de TanStack Query para consumir la API.

**Parámetros:**
- `entityName` (string): Nombre de la entidad (ej: "facturas", "clientes")
- `endpoints` (array): Endpoints a implementar

**Ejemplo:**
```typescript
{
  entityName: "clientes",
  endpoints: [
    { type: "list", name: "useClientesList", path: "/v1/clientes" },
    { type: "create", name: "useCreateCliente", path: "/v1/clientes" },
    { type: "update", name: "useUpdateCliente", path: "/v1/clientes" }
  ]
}
```

### 4. `create_form_component`
Crea un formulario con React Hook Form + Zod.

**Parámetros:**
- `name` (string): Nombre del formulario
- `fields` (array): Campos del formulario

**Ejemplo:**
```typescript
{
  name: "ClienteForm",
  fields: [
    { name: "codigo", type: "text", label: "Código", required: true },
    { name: "nombre", type: "text", label: "Nombre", required: true },
    { name: "telefono", type: "text", label: "Teléfono", required: false }
  ]
}
```

### 5. `create_data_grid`
Crea un DataGrid de MUI X para mostrar datos.

**Parámetros:**
- `entityName` (string): Nombre de la entidad
- `columns` (array): Columnas del grid

**Ejemplo:**
```typescript
{
  entityName: "clientes",
  columns: [
    { field: "codigo", headerName: "Código", width: 100 },
    { field: "nombre", headerName: "Nombre", width: 200 },
    { field: "telefono", headerName: "Teléfono", width: 150 }
  ]
}
```

### 6. `add_route_to_menu`
Agrega una nueva ruta al menú de navegación.

**Parámetros:**
- `title` (string): Título del menú
- `href` (string): Ruta (ej: "/clientes")
- `icon` (string): Nombre del ícono de MUI (ej: "People", "ShoppingCart")
- `requiresAdmin` (boolean): Si requiere permisos de admin

### 7. `list_components`
Lista todos los componentes del proyecto.

**Parámetros:**
- `type` (string): Tipo de componentes (all, common, modules)

### 8. `analyze_component_usage`
Analiza dónde se usa un componente específico.

**Parámetros:**
- `componentName` (string): Nombre del componente

### 9. `create_crud_module`
Crea un módulo CRUD completo (página, componentes, hooks).

**Parámetros:**
- `entityName` (string): Nombre de la entidad (singular)
- `entityNamePlural` (string): Nombre de la entidad (plural)
- `fields` (array): Campos de la entidad

**Ejemplo:**
```typescript
{
  entityName: "articulo",
  entityNamePlural: "articulos",
  fields: [
    { name: "codigo", label: "Código", type: "text", required: true },
    { name: "descripcion", label: "Descripción", type: "text", required: true },
    { name: "precio", label: "Precio", type: "number", required: true }
  ]
}
```

## Configuración

El frontend se ejecuta en:
```
http://localhost:3000
```

## Uso en VS Code

```
@frontend-agent crea una página para gestionar clientes en el dashboard
@frontend-agent crea un hook de TanStack Query para facturas con CRUD completo
@frontend-agent genera un formulario para crear nuevos artículos
@frontend-agent lista todos los componentes del módulo clientes
@frontend-agent crea un módulo CRUD completo para proveedores
```

## Instalación

```bash
cd "DatqBox Administrativo ADO SQL net/web/mcp-agents/frontend-agent"
npm install
```

## Casos de Uso

1. **Scaffolding rápido**: `create_crud_module` para módulos completos
2. **Hooks de datos**: `create_tanstack_hook` para consumir APIs
3. **Formularios**: `create_form_component` con validación Zod
4. **Grids**: `create_data_grid` para mostrar datos tabulares
5. **Navegación**: `add_route_to_menu` para agregar rutas al menú
6. **Exploración**: `list_components` + `analyze_component_usage`

## Estructura Generada

Un módulo CRUD completo genera:
```
src/
├── hooks/
│   └── useClientes.ts          # TanStack Query hooks
├── components/
│   └── modules/
│       └── clientes/
│           ├── ClienteTable.tsx    # DataGrid
│           └── ClienteForm.tsx     # Formulario
└── app/
    └── (dashboard)/
        └── clientes/
            └── page.tsx        # Página principal
```
