# Sistema de Debug con SQLite - Integración Completada

Esta es una integración del módulo avanzado de debug desde SpainInside. El sistema registra automáticamente todos los requests POST y PATCH en una base de datos SQLite local.

## ✅ Características Implementadas

### 1. **Logging Automático de Requests**
- Captura todos los requests POST, PATCH y GET
- Registra respuestas exitosas y errores
- Almacenamiento dual: SQLite (servidor) + LocalStorage (respaldo)
- Sanitización automática de datos sensibles (contraseñas, tokens)

### 2. **Panel de Debug Visual**
- Interfaz web bajo `/dashboard/debug`
- Visor de logs con filtros avanzados
- Estadísticas en tiempo real
- Copiar/descargar logs en JSON

### 3. **Base de Datos SQLite**
- Almacenamiento local en `data/request-logs.db`
- Índices optimizados para búsquedas rápidas
- Manejo automático de permisos de escritura
- Write-Ahead Logging (WAL) para mejor rendimiento

### 4. **API REST para Logs**
- `GET /api/logs` - Obtener logs con filtros
- `POST /api/logs` - Guardar nuevo log
- `GET /api/logs/stats` - Estadísticas

## 📦 Instalación de Dependencias

```bash
cd frontend
npm install
```

Esto instalará:
- `better-sqlite3` - Base de datos SQLite
- `dayjs` - Utilidades de fecha (opcional)
- `@types/better-sqlite3` - Types para TypeScript

### Nota para Windows
Si encuentras problemas con `better-sqlite3` en Windows, asegúrate de tener instalado:
- Python 3.x
- Visual Studio Build Tools (o las herramientas de compilación de C++)

## 🚀 Cómo Usar

### 1. Acceder al Panel de Debug
```
http://localhost:3000/dashboard/debug
```

### 2. Filtrar Logs
- **Por Método**: POST, PATCH, GET
- **Por Endpoint**: Ruta específica del API
- **Por Estado**: Exitosos, Fallidos, Todos
- **Por Usuario**: Email del usuario
- **Por Fecha**: Rango de fechas

### 3. Ver Detalles de un Log
Haz clic en "Ver" para abrir el dialog completo con:
- Información general (hora, usuario, duración)
- Request completo
- Response completo
- Errores (si aplica)
- Botones para copiar cada sección

## 📁 Estructura de Archivos Creados

```
frontend/
├── src/
│   ├── app/
│   │   ├── utils/
│   │   │   ├── requestLogger.ts        # Clase principal de logging
│   │   │   ├── db.ts                   # Gestión de SQLite
│   │   │   └── logger.ts               # Logger personalizado
│   │   ├── hooks/
│   │   │   └── useRequestLogger.ts     # Hook React para logs
│   │   ├── api/
│   │   │   └── logs/
│   │   │       ├── route.ts            # GET/POST logs
│   │   │       └── stats/
│   │   │           └── route.ts        # GET estadísticas
│   │   ├── (dashboard)/
│   │   │   └── debug/
│   │   │       ├── page.tsx            # Página principal
│   │   │       └── components/
│   │   │           ├── DebugContent.tsx
│   │   │           ├── RequestLogsViewer.tsx  # Visor principal
│   │   │           └── JsonViewer.tsx
│   │   └── lib/
│   │       └── api.ts                  # Integración con requestLogger
│   └── ...
└── data/
    └── request-logs.db                 # Base de datos SQLite (se crea automáticamente)
```

## 🔧 Integración con tu API

El archivo `src/lib/api.ts` ya está actualizado para:

1. **Capturar automáticamente** cada request POST y PATCH
2. **Registrar respuestas** exitosas y errores
3. **Incluir usuario** en cada log (desde localStorage)
4. **Medir duración** de cada request

### Ejemplo de Log Capturado

```json
{
  "id": "1707312345678-abc123",
  "timestamp": "2024-02-13T10:35:45.678Z",
  "method": "POST",
  "url": "http://localhost:4000/api/abonos",
  "user": {
    "userName": "Juan Pérez",
    "userEmail": "juan@empresa.com"
  },
  "request": {
    "data": {
      "clienteId": 123,
      "monto": 5000,
      "concepto": "Pago abono"
    }
  },
  "response": {
    "status": 201,
    "statusText": "Created",
    "data": {
      "id": 456,
      "success": true
    }
  },
  "duration": 234,
  "success": true
}
```

## 🔐 Características de Seguridad

- ✅ Sanitización de datos sensibles
- ✅ Tokens y contraseñas reemplazadas por `***`
- ✅ Headers de autorización enmascarados
- ✅ Datos almacenados localmente (no se envían a servidores externos)

## 📊 Estadísticas Disponibles

En el panel de debug puedes ver:
- Total de requests
- Requests exitosos vs fallidos
- Tasa de éxito (%)
- Desglose por método (POST, PATCH, GET, etc.)
- Top 20 endpoints más utilizados

## 🛠️ Mantenimiento

### Limpiar Logs Antiguos
Botón en el panel: "Limpiar logs > 7 días"

### Eliminar Todos los Logs
Botón en el panel: "Eliminar todos" (requiere confirmación)

### Información de la BD

La BD automáticamente:
- Se crea en `data/request-logs.db`
- Crea índices para búsquedas rápidas
- Usa WAL mode para mejor rendimiento
- Genera tablas necesarias al inicializar

## 📝 Notas Importantes

1. **Primera Ejecución**: El sistema creará automáticamente el archivo `data/request-logs.db`
2. **Permisos de Carpeta**: Asegúrate que la aplicación tenga permisos para crear/escribir en `data/`
3. **LocalStorage como Respaldo**: Si SQLite falla, los logs se guardan en localStorage (máx 1000)
4. **Productos Reutilizables**: Todos los componentes están diseñados para ser reutilizables en otros módulos

## 🐛 Solución de Problemas

### "Cannot find module 'better-sqlite3'"
```bash
npm install better-sqlite3 --save
npm install @types/better-sqlite3 --save-dev
```

### "No hay permisos de escritura en data/"
Verifica que la carpeta `data/` exista y tenga permisos de escritura.

### Los logs no se guardan
1. Verifica la consola del servidor para error messages
2. Comprueba que los requests sean POST o PATCH
3. Asegúrate que el usuario esté autenticado (userEmail debe estar en localStorage)

## 📞 Soporte

Para agregar logs a nuevos endpoints, simplemente:
1. Asegúrate que el endpoint use `apiPost` o `apiGet` desde `lib/api.ts`
2. Los logs se capturan automáticamente
3. Aparecerán en el panel de debug en tiempo real
