# RFC 002: Migración a Micro-Frontends - Subsistema POS (Punto de Venta)

## 1. Visión General de la Decisión Arquitectónica (ADR)

**Estado Actual:** `apps/shell` contiene las rutas de POS mezcladas con otros módulos. El punto de venta requiere una experiencia especializada y de alta performance que merece su propio espacio aislado.

**Problema:** El POS es un módulo crítico de operación diaria que necesita:
- Baja latencia en respuesta
- Interfaz optimizada para cajeros (touch-friendly)
- Ciclo de despliegue independiente (cambios frecuentes por regulaciones fiscales)
- Aislamiento de errores (un fallo en POS no debe afectar otros módulos)

**Decisión:** Convertir `POS` en su propio servidor Next.js totalmente aislado siguiendo la estrategia **Next.js Multi-Zones** (ya establecida con Contabilidad).

## 2. Estructura de Carpetas Físicas Propuestas

```text
web/modular-frontend/
├── apps/
│   ├── shell/                (Puerto 3000) -> Portal, App Selector y Reverse Proxy
│   ├── contabilidad/         (Puerto 3001) -> App Contabilidad
│   └── pos/                  (Puerto 3002) -> NUEVA APP POS
│       ├── src/app/          (Rutas propias /pos/*)
│       │   ├── page.tsx      (Dashboard/Touch POS)
│       │   ├── facturacion/
│       │   ├── cierre-caja/
│       │   ├── reportes/
│       │   └── layout.tsx
│       ├── package.json
│       └── next.config.mjs
├── packages/
│   ├── shared-ui/            (Componentes compartidos)
│   ├── shared-auth/          (Core de sesión)
│   ├── shared-api/           (Hooks genéricos)
│   └── module-pos/           (Componentes específicos de POS - FUTURO)
```

## 3. Red y Puertos (Next.js Multi-Zones / Rewrites)

El `Shell` actúa como enrutador inteligente. Para el usuario final: `zentto.local/pos`.

**Configuración en `apps/shell/next.config.mjs` (AGREGAR):**
```javascript
async rewrites() {
  return [
    // ... existing contabilidad rewrites ...
    {
      source: '/pos',
      destination: `http://localhost:3002/pos`,
    },
    {
      source: '/pos/:path*',
      destination: `http://localhost:3002/pos/:path*`,
    },
  ]
},
```

**Configuración en `apps/pos/next.config.mjs`:**
```javascript
export default {
  basePath: '/pos', // Aislar estáticos de esta app
  transpilePackages: ['@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api'],
}
```

## 4. Compartición de Sesión (Auth)

Mismo esquema que Contabilidad:
- Cookie de NextAuth (`next-auth.session-token`) compartida vía dominio base
- Ambas apps usan `useAuth()` desde `@zentto/shared-auth`
- Si no hay sesión, redirigir al Shell (login centralizado)

## 5. Funcionalidades del Subsistema POS

Basado en el legado `Zentto PtoVenta` (VB6) y la imagen de referencia:

### Módulos Core:
1. **Facturación Rápida** - Interfaz touch para agregar productos al carrito
2. **Gestión de Carrito** - Items, cantidades, descuentos, totales
3. **Pagos Múltiples** - Efectivo, tarjeta, transferencia, combinados
4. **Cierre de Caja** - Arqueo, cuadre, reporte Z
5. **Reportes POS** - Ventas por período, productos más vendidos
6. **Clientes Rápido** - Búsqueda y registro express

### Diseño UI:
- Layout tipo "cash register" (referencia visual proporcionada)
- Panel izquierdo: Carrito actual + teclado numérico
- Panel derecho: Grid de productos/categorías
- Top bar: Búsqueda, selector de caja, usuario

## 6. Checklist de Implementación

- [x] 1. Crear RFC-002-MicroFrontend-POS.md (este documento)
- [ ] 2. Crear estructura base `apps/pos/`
- [ ] 3. Configurar `apps/pos/package.json` con workspace dependencies
- [ ] 4. Configurar `apps/pos/next.config.mjs` con `basePath: '/pos'`
- [ ] 5. Crear `layout.tsx` con OdooLayout y navegación POS
- [ ] 6. Crear `nav.tsx` con menús: Dashboard, Facturación, Cierre, Reportes
- [ ] 7. Crear páginas base: `/pos`, `/pos/facturacion`, `/pos/cierre`, `/pos/reportes`
- [ ] 8. Agregar rewrites en `apps/shell/next.config.mjs`
- [ ] 9. Validar que el App Selector del Shell incluya POS
- [ ] 10. Probar flujo: Shell → POS → Auth → Funcionalidad

## 7. Dependencias

```json
{
  "dependencies": {
    "@zentto/shared-api": "workspace:*",
    "@zentto/shared-auth": "workspace:*",
    "@zentto/shared-ui": "workspace:*",
    "@emotion/react": "^11.14.0",
    "@emotion/styled": "^11.14.0",
    "@mui/icons-material": "^6.4.1",
    "@mui/material": "^6.4.1",
    "@mui/x-data-grid": "^7.24.0",
    "@tanstack/react-query": "^5.64.1",
    "next": "15.5.12",
    "next-auth": "5.0.0-beta.25",
    "react": "^18.3.1"
  }
}
```

## 8. Prós y Contras

### Pros
- Aislamiento completo del módulo crítico de ventas
- Despliegue independiente para hotfixes fiscales
- Optimización de bundle específica para POS (sin código de otros módulos)
- Equipo de desarrollo dedicado puede trabajar sin colisiones

### Contras
- Overhead de mantener N servidores en desarrollo
- Complejidad adicional en routing/proxy
- Posible duplicación de dependencias base

## 9. Notas de Implementación

- Puerto asignado: **3002** (Shell: 3000, Contabilidad: 3001, POS: 3002)
- Módulo VB6 de referencia: `Zentto PtoVenta/`
- El diseño debe ser touch-friendly (mínimo 44px touch targets)
- Integración futura con spooler fiscal vía API
