# API Agent - DatQBox

Agente MCP especializado para desarrollo del backend Express + TypeScript.

## Herramientas Disponibles

### 1. `test_api_endpoint`
Prueba un endpoint de la API en desarrollo.

**Parámetros:**
- `method` (string): Método HTTP (GET, POST, PUT, DELETE, PATCH)
- `path` (string): Ruta del endpoint (ej: "/v1/clientes")
- `data` (object, opcional): Datos a enviar (para POST/PUT/PATCH)
- `headers` (object, opcional): Headers personalizados

**Ejemplo:**
```typescript
{
  method: "POST",
  path: "/v1/clientes",
  data: {
    codigo: "CLI001",
    nombre: "Cliente Prueba"
  }
}
```

### 2. `create_api_module`
Crea un nuevo módulo completo de la API (routes.ts, service.ts, types.ts).

**Parámetros:**
- `moduleName` (string): Nombre del módulo (ej: "articulos", "ventas")
- `endpoints` (array): Lista de endpoints a crear

**Ejemplo:**
```typescript
{
  moduleName: "articulos",
  endpoints: [
    { method: "GET", path: "/", description: "Listar artículos" },
    { method: "POST", path: "/", description: "Crear artículo" }
  ]
}
```

### 3. `list_api_modules`
Lista todos los módulos disponibles en la API.

### 4. `get_module_structure`
Obtiene la estructura de archivos de un módulo específico.

**Parámetros:**
- `moduleName` (string): Nombre del módulo

### 5. `generate_crud_endpoints`
Genera endpoints CRUD completos para una entidad.

**Parámetros:**
- `entityName` (string): Nombre de la entidad (ej: "articulo", "proveedor")
- `tableName` (string): Nombre de la tabla SQL
- `fields` (array): Campos de la entidad

**Ejemplo:**
```typescript
{
  entityName: "articulo",
  tableName: "Articulos",
  fields: [
    { name: "codigo", type: "string", required: true },
    { name: "descripcion", type: "string", required: true },
    { name: "precio", type: "number", required: true }
  ]
}
```

### 6. `validate_openapi_contract`
Valida que un endpoint cumpla con el contrato OpenAPI.

**Parámetros:**
- `path` (string): Ruta del endpoint
- `method` (string): Método HTTP

### 7. `create_middleware`
Crea un nuevo middleware para la API.

**Parámetros:**
- `name` (string): Nombre del middleware
- `type` (string): Tipo de middleware (auth, validation, logging, error, custom)

### 8. `analyze_api_routes`
Analiza todas las rutas registradas en la API.

## Configuración

El agente se conecta a la API en:
```
http://localhost:4000
```

Puedes cambiar el puerto en `api/.env`:
```env
PORT=4000
```

## Uso en VS Code

```
@api-agent prueba el endpoint GET /v1/clientes
@api-agent crea un módulo para gestionar ventas con endpoints de CRUD
@api-agent lista todos los módulos disponibles
@api-agent genera CRUD completo para la entidad articulo
```

## Instalación

```bash
cd "DatqBox Administrativo ADO SQL net/web/mcp-agents/api-agent"
npm install
```

## Casos de Uso

1. **Testing rápido**: `test_api_endpoint` para probar endpoints sin Postman
2. **Scaffolding**: `create_api_module` para crear módulos nuevos rápidamente
3. **CRUD automático**: `generate_crud_endpoints` para entidades estándar
4. **Documentación**: `analyze_api_routes` para ver todas las rutas
5. **Estructura**: `list_api_modules` + `get_module_structure` para explorar el código
