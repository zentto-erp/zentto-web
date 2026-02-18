# 🚀 Guía de Inicio Rápido - Agentes MCP DatQBox

## ¿Qué son los Agentes MCP?

Los **MCP Agents** (Model Context Protocol) son servidores especializados que extienden las capacidades de GitHub Copilot en VS Code, proporcionándote herramientas específicas para trabajar con:

- **Database Agent** 🗄️: Base de datos SQL Server
- **API Agent** 🔌: Backend Express + TypeScript
- **Frontend Agent** 🎨: Next.js + React + MUI

## ✅ Instalación Completada

Los agentes ya están instalados y configurados. Solo necesitas **reiniciar VS Code** para activarlos.

## 🎯 Cómo Usar los Agentes

### En el Chat de GitHub Copilot

Cada agente se invoca con `@` seguido del nombre del agente:

```
@database-agent [tu pregunta o comando]
@api-agent [tu pregunta o comando]
@frontend-agent [tu pregunta o comando]
```

## 📚 Ejemplos Prácticos

### Database Agent 🗄️

```
@database-agent lista todas las tablas de la base de datos

@database-agent muéstrame el esquema de la tabla Facturas

@database-agent ejecuta el archivo sp_crud_clientes.sql

@database-agent haz un backup de la tabla Clientes antes de modificarla

@database-agent analiza el plan de ejecución de: SELECT * FROM Facturas WHERE fecha > '2024-01-01'
```

### API Agent 🔌

```
@api-agent lista todos los módulos disponibles en la API

@api-agent crea un módulo nuevo llamado "ventas" con endpoints CRUD

@api-agent prueba el endpoint GET /v1/clientes

@api-agent genera endpoints CRUD para la entidad "articulo" con tabla "Articulos"

@api-agent analiza todas las rutas registradas
```

### Frontend Agent 🎨

```
@frontend-agent crea una página para gestionar clientes en el dashboard

@frontend-agent genera un hook de TanStack Query para facturas con CRUD completo

@frontend-agent crea un formulario para registrar nuevos proveedores con campos: codigo, nombre, rif, telefono

@frontend-agent crea un DataGrid para mostrar artículos con columnas: codigo, descripcion, precio

@frontend-agent crea un módulo CRUD completo para "vehiculos"
```

## 🔥 Flujo de Trabajo Típico

### Ejemplo: Agregar módulo "Vehículos"

**1. Crear tabla en BD con Database Agent:**
```
@database-agent ejecuta este script:
CREATE TABLE Vehiculos (
  id INT PRIMARY KEY IDENTITY,
  placa VARCHAR(20) NOT NULL,
  marca VARCHAR(100),
  modelo VARCHAR(100),
  anno INT
)
```

**2. Crear API con API Agent:**
```
@api-agent genera endpoints CRUD para la entidad "vehiculo" con tabla "Vehiculos" y campos: placa (string), marca (string), modelo (string), anno (number)
```

**3. Crear Frontend con Frontend Agent:**
```
@frontend-agent crea un módulo CRUD completo para "vehiculo" (singular) y "vehiculos" (plural) con campos: placa, marca, modelo, anno
```

**4. Agregar al menú:**
```
@frontend-agent agrega la ruta "/vehiculos" al menú con título "Vehículos" e ícono "DirectionsCar"
```

## 🛠️ Herramientas Más Útiles por Agente

### Database Agent
| Herramienta | Uso Común |
|-------------|-----------|
| `execute_sql_query` | Consultas rápidas |
| `run_sql_file` | Ejecutar migraciones |
| `get_table_schema` | Explorar estructura |
| `backup_table` | Respaldo antes de cambios |

### API Agent
| Herramienta | Uso Común |
|-------------|-----------|
| `test_api_endpoint` | Testing sin Postman |
| `create_api_module` | Scaffolding rápido |
| `generate_crud_endpoints` | CRUD automático |
| `list_api_modules` | Exploración |

### Frontend Agent
| Herramienta | Uso Común |
|-------------|-----------|
| `create_crud_module` | Módulo completo |
| `create_tanstack_hook` | Hooks de datos |
| `create_form_component` | Formularios validados |
| `create_data_grid` | Tablas de datos |

## 🎓 Tips y Mejores Prácticas

1. **Sé específico**: Los agentes funcionan mejor con instrucciones claras
2. **Combina agentes**: Puedes usar varios agentes en secuencia para un flujo completo
3. **Revisa el código**: Los agentes generan código, pero siempre revísalo antes de usarlo
4. **Experimenta**: Los agentes pueden crear, listar, analizar y más

## 🐛 Solución de Problemas

### Los agentes no aparecen en el chat

1. Verifica que VS Code está actualizado
2. Reinicia VS Code completamente
3. Verifica que GitHub Copilot está activo
4. Revisa que los archivos en `.vscode/settings.json` están correctos

### Error al ejecutar un agente

1. Verifica que las dependencias están instaladas (`npm install` en cada carpeta)
2. Asegúrate de que la API está corriendo (para api-agent)
3. Verifica las credenciales de BD en `api/.env` (para database-agent)

## 📖 Documentación Detallada

Cada agente tiene su README con documentación completa:

- [Database Agent README](./database-agent/README.md)
- [API Agent README](./api-agent/README.md)
- [Frontend Agent README](./frontend-agent/README.md)

## 🎉 ¡Listo para Empezar!

Reinicia VS Code y empieza a usar tus nuevos agentes MCP. ¡Aumenta tu productividad significativamente!

---

**Nota**: Los agentes leen la configuración de tu proyecto automáticamente desde:
- Base de datos: `api/.env` (DB_SERVER, DB_DATABASE, etc.)
- API: Puerto desde `api/.env` (default: 4000)
- Frontend: Estructura de carpetas estándar Next.js
