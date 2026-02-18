# Agentes MCP para DatQBox

Este directorio contiene agentes especializados MCP (Model Context Protocol) para ayudar en el desarrollo del proyecto DatQBox.

## Agentes Disponibles

### 1. Database Agent (`database-agent/`)
**Propósito**: Gestión completa de la base de datos SQL Server
- Ejecuta migraciones y scripts SQL
- Analiza esquemas y optimiza queries
- Genera stored procedures y funciones
- Valida integridad referencial
- Benchmarking de consultas

### 2. API Agent (`api-agent/`)
**Propósito**: Desarrollo y mantenimiento del backend Express + TypeScript
- Genera endpoints REST
- Valida contratos OpenAPI
- Implementa middleware y autenticación
- Gestiona módulos de negocio
- Testing de APIs

### 3. Frontend Agent (`frontend-agent/`)
**Propósito**: Desarrollo de la interfaz Next.js + React + MUI
- Genera componentes React
- Implementa hooks de TanStack Query
- Configura rutas y layouts
- Valida formularios con Zod
- Optimiza rendimiento del frontend

## Configuración

Los agentes están configurados en `.vscode/settings.json` bajo `github.copilot.chat.mcp.servers`.

## Uso

En VS Code, puedes invocar a cada agente mediante comandos de chat:
- `@database-agent` - Para tareas de base de datos
- `@api-agent` - Para tareas del backend
- `@frontend-agent` - Para tareas del frontend

## Estructura de Cada Agente

Cada agente es un servidor MCP independiente con:
- `server.js` - Servidor MCP con herramientas especializadas
- `package.json` - Dependencias del agente
- `README.md` - Documentación específica del agente
