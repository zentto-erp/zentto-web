# Database Agent - DatQBox

Agente MCP especializado para operaciones de base de datos SQL Server.

## Herramientas Disponibles

### 1. `execute_sql_query`
Ejecuta una consulta SQL SELECT y retorna los resultados.

**Parámetros:**
- `query` (string): La consulta SQL SELECT
- `parameters` (object, opcional): Parámetros para la consulta

**Ejemplo:**
```typescript
{
  query: "SELECT * FROM Clientes WHERE codCliente = @codigo",
  parameters: { codigo: "CLI001" }
}
```

### 2. `execute_sql_script`
Ejecuta un script SQL completo (CREATE, INSERT, UPDATE, DELETE, ALTER, etc.).

**Parámetros:**
- `script` (string): El script SQL a ejecutar
- `transaction` (boolean, default: true): Si debe ejecutarse en transacción

### 3. `run_sql_file`
Ejecuta un archivo SQL desde la carpeta `api/sql`.

**Parámetros:**
- `filename` (string): Nombre del archivo (ej: "sp_crud_clientes.sql")

**Ejemplo:**
```typescript
{ filename: "sp_crud_clientes.sql" }
```

### 4. `get_table_schema`
Obtiene el esquema completo de una tabla (columnas, tipos, constraints, índices).

**Parámetros:**
- `tableName` (string): Nombre de la tabla

### 5. `list_tables`
Lista todas las tablas de la base de datos.

**Parámetros:**
- `pattern` (string, opcional): Patrón para filtrar tablas

### 6. `get_foreign_keys`
Obtiene todas las foreign keys de una tabla.

**Parámetros:**
- `tableName` (string): Nombre de la tabla

### 7. `analyze_query_plan`
Analiza el plan de ejecución de una consulta para optimización.

**Parámetros:**
- `query` (string): La consulta SQL a analizar

### 8. `backup_table`
Crea una copia de respaldo de una tabla.

**Parámetros:**
- `tableName` (string): Nombre de la tabla a respaldar
- `backupName` (string, opcional): Nombre para la tabla de respaldo

## Configuración

El agente lee la configuración de conexión desde `api/.env`:

```env
DB_SERVER=localhost
DB_DATABASE=sanjose
DB_USER=sa
DB_PASSWORD=****
DB_ENCRYPT=false
DB_TRUST_CERT=true
```

## Uso en VS Code

Una vez instalado, puedes invocar al agente en el chat de GitHub Copilot:

```
@database-agent ejecuta el archivo sp_crud_clientes.sql
@database-agent muéstrame el esquema de la tabla Facturas
@database-agent lista todas las tablas que empiezan con "Mov"
```

## Instalación

```bash
cd "DatqBox Administrativo ADO SQL net/web/mcp-agents/database-agent"
npm install
```

## Casos de Uso

1. **Ejecutar migraciones**: `run_sql_file` con scripts de la carpeta sql/
2. **Análisis de esquema**: `get_table_schema` + `get_foreign_keys`
3. **Optimización**: `analyze_query_plan` para queries lentas
4. **Respaldos**: `backup_table` antes de modificaciones críticas
5. **Exploración**: `list_tables` para descubrir estructura de BD
