# Plan Ejecutivo - Frontend DatqBox Web

## Estado Actual del Proyecto
✅ **Base instalada**:
- Next.js 14 con TypeScript
- Material-UI 5
- TanStack Router + Query
- `src/app/layout.tsx` configurado con AppProviders
- `src/app/login/` existe
- `src/app/facturas/` existe (base)
- `src/components/FacturaTable.tsx` existe (base)

## Tu Rol
**Owner Frontend**: Responsable de pantallas, formularios, tablas, navegación

**Recursos disponibles**:
- 📚 `D:\SpainInside_WEB` - Proyecto de referencia con soluciones maduras
- 🔄 Código de SpainInside puedes **COPIAR** (sin modificar original)
- 🚀 Sigues el backlog de `STATUS.md`

## Tareas Inmediatas (Prioridad)

### 🔴 Crítico - Esta Semana
1. **Revisar estructura SpainInside**
   - Revisar `D:\SpainInside_WEB\app\layout.tsx` (layout con Sidebar)
   - Revisar `D:\SpainInside_WEB\app\components\` (componentes reutilizables)
   - Revisar `D:\SpainInside_WEB\app\authentication\` (login patterns)

2. **Mejorar Layout Principal**
   - Copiar patrón de Layout protegido (Sidebar + Header)
   - Crear estructura `/dashboard` como punto de entrada
   - Implementar navegación modular

3. **Fortalecer Login**
   - Revisar guards de rutas en SpainInside `middleware.ts`
   - Implementar protección de `/dashboard/*`
   - Redirección automática

### 🟡 Alto - Este Sprint
4. **Tabla de Facturas**
   - Copiar `CustomDataGrid.tsx` de SpainInside
   - Adaptar para endpoint `/v1/facturas`
   - Agregar filtros (fecha, cliente, estado)

5. **Módulo Clientes**
   - Tabla básica de clientes
   - Diálogos de confirmación (DeleteDialog, etc)

### 🟢 Medio
6. **Estado Global**
   - Setup de store para sesión + permisos
   - RBAC básico

---

## Cómo Copiar Código SIN Modificar SpainInside

**Archivo que quieres copiar**: `D:\SpainInside_WEB\app\components\CustomDataGrid.tsx`

```bash
# Paso 1: Leer el archivo (desde workspace)
cat "D:\SpainInside_WEB\app\components\CustomDataGrid.tsx"

# Paso 2: Copiar el contenido íntegro

# Paso 3: Crear en tu proyecto
cp "D:\SpainInside_WEB\app\components\CustomDataGrid.tsx" \
   "C:\Users\Dell\...\web\frontend\src\components\CustomDataGrid.tsx"

# Paso 4: ADAPTAR si necesario (cambios locales solo)
# - Ajustar imports si paths son diferentes
# - Cambiar colores/temas si es necesario
# - NUNCA modificar SpainInside_WEB original
```

**Nota**: Cuando copias un componente, hazlo en commit separado:
```bash
git add src/components/CustomDataGrid.tsx
git commit -m "refactor(frontend): adopt CustomDataGrid from SpainInside"
```

---

## Archivo de Seguimiento

Cada que termines una tarea:
1. ✏️ **Actualizar STATUS.md** - Mover item de "Backlog" a "En curso" → "Hecho"
2. 📄 **Actualizar FRONTEND_ROADMAP.md** - Marcar ✅ subtareas completadas
3. 🔄 **Git commit** con patrón: `git commit -m "feat(frontend): <módulo> - <descripción>"`

**Ejemplo**:
```bash
# Terminas tabla de facturas
git commit -m "feat(frontend): facturas - implement data grid with filters and pagination"

# Luego actualizas STATUS.md
git add STATUS.md
git commit -m "docs(status): mark facturas table as done"
```

---

## Sincronización con Backend

Cada que backend termine un endpoint:
- Lee el contrato en `web/contracts/openapi.yaml`
- Ajusta tu consumer de API (TanStack Query)
- Valida tipos TypeScript contra DTO

**Ejemplo**: Backend crea `POST /v1/facturas`
```yaml
# web/contracts/openapi.yaml
/v1/facturas:
  post:
    requestBody:
      schema:
        $ref: '#/components/schemas/CreateFacturaDTO'
    responses:
      201:
        schema:
          $ref: '#/components/schemas/FacturaDTO'
```

Tu frente adapsa:
```typescript
// src/hooks/useFacturas.ts
const { mutate: createFactura } = useMutation({
  mutationFn: (data: CreateFacturaDTO) =>
    api.post('/v1/facturas', data)
});
```

---

## Comandos Clave

```bash
# Desde web/
npm run dev         # Levanta frontend + API locales
npm run dev:web     # Solo frontend
npm run dev:api     # Solo API (backend)
npm run build       # Compilar prod

# Chequeo
npm run sync:check  # Valida sincronización API/Frontend
```

---

## Contacto Backend

Cuando necesites un endpoint:
```
subagente backend: crear endpoint GET /v1/clientes con paginacion
```

Backend te actualizará el contrato OpenAPI y tú adaptas el frontend.

---

## Resumen Visual

```
├── 🎯 Tareas Prioritarias
│   ├── ✅ Base instalada
│   ├── 🔄 Layout principal
│   ├── 🔄 Login + guards
│   ├── 🔄 Tabla facturas
│   ├── ⭕ Módulo clientes
│   └── ⭕ Estado global
│
├── 📚 Referencias (SpainInside_WEB)
│   ├── Layout patterns
│   ├── Componentes reutilizables
│   ├── Authentication
│   └── Custom hooks
│
└── 📋 Archivos Seguimiento
    ├── STATUS.md ← Actualizar cada tarea
    ├── FRONTEND_ROADMAP.md ← Tu guía
    └── AGENTS.md ← Protocolo general
```

---

## Próximo Paso
1. Revisa `D:\SpainInside_WEB\app\layout.tsx` → copia estructura
2. Actualiza tu `frontend/src/app/layout.tsx` 
3. Crea `/dashboard` layout protegido
4. Commit: `"feat(frontend): add protected dashboard layout"`
5. Actualiza STATUS.md → `[ ] layout principal` ✓ → "Hecho"

¿Quieres que comience con el layout? 🚀

