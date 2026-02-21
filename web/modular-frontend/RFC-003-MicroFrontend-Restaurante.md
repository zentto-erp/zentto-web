# RFC 003: Subsistema Restaurante - Gestión de Salón y Cocina

## 1. Visión General

**Estado:** Implementado  
**Puerto:** 3008  
**Base Path:** `/restaurante`

El subsistema Restaurante es una extensión especializada del POS diseñada específicamente para la gestión de restaurantes, incluyendo:
- Mapa de mesas configurable con drag & drop
- Gestión de ambientes (Salón, Terraza, Barra, etc.)
- Pedidos con productos compuestos
- Comandas a cocina
- Vista de cocina para preparación de órdenes

## 2. Estructura de Carpetas

```
apps/restaurante/
├── src/
│   ├── app/
│   │   ├── layout.tsx          # Layout con navegación Odoo
│   │   ├── page.tsx            # Página principal (Mapa de mesas)
│   │   ├── nav.tsx             # Configuración de navegación
│   │   └── cocina/
│   │       └── page.tsx        # Vista de cocina
│   ├── components/
│   │   ├── MapaMesas.tsx       # Grid de mesas configurable
│   │   ├── MesaCard.tsx        # Tarjeta de mesa individual
│   │   ├── PanelPedido.tsx     # Panel de pedido + menú táctil
│   │   └── VistaCocina.tsx     # Vista para cocineros
│   └── hooks/
│       └── useRestaurante.ts   # Lógica de negocio + mock data
├── package.json
├── next.config.mjs
└── tsconfig.json
```

## 3. Características Implementadas

### Mapa de Mesas Configurable
- **Drag & Drop:** Las mesas se pueden mover como "fichas de dominó"
- **Grid flexible:** Distribución automática con grid CSS
- **Estados visuales:** 
  - 🟢 Verde: Libre
  - 🔴 Rojo: Ocupada (muestra cliente y monto)
  - 🟠 Naranja: Reservada
  - 🟣 Púrpura: Por cobrar
- **Modo edición:** Agregar nuevas mesas y reorganizar

### Gestión de Pedidos
- **Apertura de mesa:** Con datos opcionales del cliente
- **Menú táctil:** Productos rápidos con categorías
- **Sugerencias del día:** Productos destacados
- **Productos compuestos:** 
  - Opciones configurables (ej: punto de cocción, guarnición)
  - Sub-artículos y extras
- **Comentarios:** Notas especiales para cocina

### Comandas a Cocina
- **Envío parcial:** Solo los items pendientes
- **Estados:** Pendiente → En preparación → Listo → Entregado
- **Tiempos:** Tracking de tiempo de preparación

### Vista de Cocina
- **Tablero de pedidos:** Organizado por ambiente
- **Prioridades:** 
  - Normal (verde)
  - Alta/Demorado (naranja)
  - Urgente/Vencido (rojo)
- **Tiempo transcurrido:** Contador en tiempo real
- **Marcar listo:** Un click para indicar que está listo

## 4. Mock Data Incluida

### Ambientes
1. **Salón Principal** (color verde) - 5 mesas
2. **Terraza** (color naranja) - 2 mesas
3. **Barra** (color púrpura) - 3 mesas

### Productos de Ejemplo
- Entradas: Bruschetta, Calamares Fritos
- Pastas: Pasta Carbonara (compuesta), Lasagna
- Carnes: Filete de Res (compuesto)
- Bebidas: Coca Cola, Agua Mineral
- Postres: Tiramisú

### Mesas Pre-configuradas
- Mesa 3: Ocupada con pedido de ejemplo (Juan Pérez, $36)
- Resto: Distribuidas entre libres, reservadas y por cobrar

## 5. Configuración

### Puerto
```javascript
// apps/restaurante/package.json
"dev": "next dev -p 3008"
```

### Shell Rewrite
```javascript
// apps/shell/next.config.mjs
{
  source: '/restaurant',
  destination: `http://localhost:3008/restaurant`,
},
{
  source: '/restaurant/:path*',
  destination: `http://localhost:3008/restaurant/:path*`,
}
```

## 6. Cómo Ejecutar

```bash
# Terminal 1 - Restaurante
cd web/modular-frontend
npm run dev:restaurant

# Terminal 2 - Shell
cd web/modular-frontend
npm run dev:shell
```

### URLs
- Directo: http://localhost:3008/restaurant
- Vía Shell: http://localhost:3000/restaurant

## 7. Dependencias Adicionales

```bash
npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities uuid
npm install -D @types/uuid
```

## 8. Próximas Mejoras

- [ ] Integración con impresora de comandas
- [ ] Notificaciones push para cocina
- [ ] Reservas con fecha/hora
- [ ] Mesas compartidas (split bill)
- [ ] Propinas y servicio
- [ ] Integración con delivery
- [ ] Reportes de ventas por ambiente

## 9. Integración con POS

El restaurante comparte la misma arquitectura que el POS:
- Autenticación compartida vía cookie
- Hooks de API similares (useRestaurante vs usePosApi)
- Diseño UI consistente (Odoo Layout)
- Componentes compartidos de shared-ui

## 10. Flujo de Uso

1. **Mesero:** Abre mesa → Ingresa cliente (opcional) → Agrega productos
2. **Envío a cocina:** Clic en "Enviar a cocina"
3. **Cocina:** Ve pedido en tablero → Prepara → Marca como listo
4. **Mesero:** Entrega comida → Cierra cuenta → Genera factura
