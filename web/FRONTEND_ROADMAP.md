# Frontend Roadmap - DatqBox Web

## Contexto
- **Proyecto Base**: `web/frontend` (Next.js 14, React 18, TypeScript)
- **Referencia**: `D:\SpainInside_WEB` (Proyecto con misma stack, más maduro)
- **Regla Oro**: Copiar código reutilizable SIN modificar SpainInside_WEB

## Stack Confirmado
- Next.js 14.2.5
- React 18.3.1
- TypeScript 5.7.3
- Material-UI 5.16.7
- TanStack Router 1.71.12
- TanStack React Query 5.51.15
- TanStack React Table 8.20.5

## Tareas Frontend (Según Backlog en STATUS.md)

### 1. Layout Principal con Navegación Modular
**Estado**: Backlog  
**Prioridad**: Alta  
**Ref SpainInside**: `app/layout.tsx`, `app/(dashboard)/` folder, `app/components/dashboard/`

**Subtareas**:
- [ ] Crear estructura de layout con Sidebar + Header
- [ ] Implementar Provider wrappers (Theme, Auth, Query)
- [ ] Ruta `/dashboard` como entry point post-login
- [ ] Copiar componentes base: `StatCard.tsx`, diálogos confirmación
- [ ] Sistema de navegación modular por rol/permiso

**Archivos a copiar**:
- `app/layout.tsx` (estructura)
- `app/components/dashboard/` (componentes reusables)
- `app/providers/` (AuthProvider, QueryProvider, ThemeProvider)

---

### 2. Login con Guard de Rutas
**Estado**: Backlog  
**Prioridad**: Alta  
**Ref SpainInside**: `app/authentication/`, `middleware.ts`

**Subtareas**:
- [ ] Crear página `/login` - formulario Next-Auth compatible
- [ ] Configurar middleware de autenticación
- [ ] Proteger rutas `/dashboard/*` con ProtectedRoute/Guard
- [ ] Persistencia de sesión en localStorage/cookies
- [ ] Redirección automática login→dashboard

**Archivos a copiar**:
- `auth.ts` (configuración de autenticación)
- `middleware.ts` (protección de rutas)
- Componentes de login reutilizables

---

### 3. Listado + Detalle de Facturas
**Estado**: Backlog (parcialmente hecho base)  
**Prioridad**: Alta  
**Ref SpainInside**: `app/components/tables/`, `app/components/CustomDataGrid.tsx`

**Subtareas**:
- [ ] Tabla de facturas con CustomDataGrid (de referencia)
- [ ] Filtros: Rango fecha, cliente, estado
- [ ] Paginación desde API `/v1/facturas?page=1&limit=10`
- [ ] Búsqueda por número de factura
- [ ] Drawer/Modal detalle factura (lectura)
- [ ] Actions: Ver PDF, Duplicar, Exportar

**Archivos a copiar**:
- `app/components/CustomDataGrid.tsx` (tabla customizada)
- `app/components/DateRangeSelector.tsx` (selector fechas)
- Hooks de data-fetching con React Query

---

### 4. Módulo Clientes
**Estado**: Backlog  
**Prioridad**: Media  
**Ref SpainInside**: `app/components/tables/` (TableActions pattern)

**Subtareas**:
- [ ] Tabla clientes sin paginación (inicial)
- [ ] CRUD básico: Ver, Editar, Eliminar
- [ ] Form de cliente reutilizable
- [ ] Validaciones con React Hook Form
- [ ] Dialogs de confirmación (DeleteDialog, etc)

**Archivos a copiar**:
- `app/components/DeleteDialog.tsx`
- `app/components/ConfirmDialog.tsx`
- Form patterns con react-hook-form

---

### 5. Estado de Sesión y Permisos
**Estado**: Backlog  
**Prioridad**: Media  
**Ref SpainInside**: `app/store/` (si usa Zustand/Context)

**Subtareas**:
- [ ] Context/Store global de usuario (sesión activa)
- [ ] Verificar permisos antes de renderizar acciones
- [ ] Rol-based access control (RBAC)
- [ ] Logout y limpiar sesión
- [ ] Refresh token automático

---

## Archivos Críticos a Revisar en SpainInside

### Structure
```
D:\SpainInside_WEB\
├── app/
│   ├── authentication/       ← Login patterns
│   ├── (dashboard)/          ← Layout protegido
│   ├── components/
│   │   ├── common/           ← Componentes base
│   │   ├── dashboard/        ← Cards, widgets
│   │   ├── tables/           ← Tablas con actions
│   │   └── pdf/              ← Exportación PDF
│   ├── hooks/                ← Custom hooks reutilizables
│   ├── store/                ← Estado global
│   ├── types/                ← Type definitions compartidas
│   └── utils/                ← Funciones helpers
├── auth.ts                   ← NextAuth config
├── middleware.ts             ← Protección de rutas
└── package.json              ← Dependencias recomendadas
```

### Componentes de Alto Impacto
1. **CustomDataGrid** - Tabla flexible con Actions
2. **Dialogs** (Confirm, Delete) - Reutilizables
3. **DateRangeSelector** - Selector fechas
4. **StatCard** - Card para métricas
5. **Providers** - Auth + Query + Theme

---

## Checklist de Implementación

- [ ] Revisar estructura `SpainInside_WEB/app`
- [ ] Copiar `auth.ts` y `middleware.ts` adaptado
- [ ] Copiar providers (Auth, Query, Theme)
- [ ] Crear layout principal con Sidebar
- [ ] Implementar login page
- [ ] Copiar CustomDataGrid y componentes de tabla
- [ ] Crear tabla de facturas con filtros
- [ ] Crear tabla de clientes
- [ ] Implementar guards de rutas
- [ ] Sincronizar en STATUS.md

---

## Convención de Commits

```bash
# Frontend feature
git commit -m "feat(frontend): <módulo> - <descripción>"

# Copiar componente de referencia
git commit -m "refactor(frontend): adopt <ComponentName> from SpainInside"

# Actualizar estado
git commit -m "docs(status): mark <task> as done"
```

---

## Comandos Útiles

```bash
# Desde web/
npm run dev           # Levantar todo
npm run dev:web      # Solo frontend
npm run dev:api      # Solo API

# Instalar deps
npm run install:all  # Si existe script

# Build
npm run build
```

---

## Próximas Sincronizaciones

Cada que termines tarea:
1. Actualizar `STATUS.md` carril frontend
2. Si modifica contrato, sincronizar `contracts/openapi.yaml`
3. Commit con patrón anterior
4. Notificar al backend para ajustes de API si es necesario

