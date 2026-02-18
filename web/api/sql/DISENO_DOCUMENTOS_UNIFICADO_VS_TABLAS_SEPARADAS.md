# Diseño: documento unificado por TIPO vs. tablas separadas

**Implementación (nueva versión):** Se crearon las tablas unificadas y el contrato de API. Ver `create_documentos_unificado.sql`, `migrate_to_documentos_unificado.sql` y en OpenAPI los paths `/v1/documentos-venta` y `/v1/documentos-compra` con `tipoOperacion`.

## Situación actual

Hay mucha **estructura repetida** entre documentos:

| Lado        | Tablas (cabecera + detalle + formas de pago) | Relación      |
|------------|---------------------------------------------|---------------|
| **Clientes** | Facturas, Presupuestos, Pedidos, Cotizacion, NOTACREDITO, NOTADEBITO, (Nota Entrega si aplica) | Todas → Clientes, P_Cobrar |
| **Proveedores** | Ordenes, Compras | → Proveedores, P_Pagar |

Todas comparten un patrón: cabecera (cliente/proveedor, fecha, total, usuario, serial fiscal cuando aplica), detalle (ítems con producto, cantidad, precio), y a veces detalle de forma de pago. La diferencia es sobre todo **semántica** (qué es el documento) y **numeración/legal** (factura fiscal vs. presupuesto vs. pedido).

---

## Opción A: Menos tablas (documento unificado por TIPO_OPERACION)

Idea: una o dos tablas “maestras” de documentos y el tipo de operación indica qué es.

### Variante 1 – Una sola tabla de documentos (venta + compra)

- **Documentos** (o **DocumentosCabecera**):  
  `NUM_DOC`, `SERIALTIPO`, `Tipo_Orden`, **`TIPO_OPERACION`** (FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA, ORDEN, COMPRA), `CODIGO` (cliente o proveedor según tipo), `FECHA`, `TOTAL`, `COD_USUARIO`, etc.
- **DocumentosDetalle**: misma estructura de líneas, FK a cabecera.
- **P_Cobrar / P_Pagar**: ya llevan `TIPO`; la cabecera unificada encajaría con eso.

Ventajas:
- Una sola estructura de cabecera/detalle que mantener.
- Un solo juego de FKs (documento → cliente o proveedor según tipo).
- Reportes “todos los documentos” y lógica genérica más simple en código (un SP o servicio por “emitir documento” parametrizado por tipo).

Desventajas:
- Tabla muy ancha o muchos NULL: campos que solo aplican a factura fiscal, solo a compra, etc.
- Numeración: facturas tienen una secuencia, presupuestos otra, pedidos otra; hay que manejar secuencias por `TIPO_OPERACION` (y por serial/memoria en fiscal).
- Migración grande: unir Facturas, Presupuestos, Pedidos, Cotizacion, NOTACREDITO, NOTADEBITO, Ordenes, Compras en una sola tabla (o dos).
- Riesgo de mezclar reglas de negocio (fiscal, crédito, inventario) si no se disciplina bien por tipo.

### Variante 2 – Dos tablas: ventas (clientes) y compras (proveedores)

- **DocumentosVenta**: `TIPO_OPERACION` = FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA; `CODIGO` → Clientes; resto común (NUM_DOC, SERIALTIPO, Tipo_Orden, FECHA, TOTAL, …).
- **DocumentosCompra**: `TIPO_OPERACION` = ORDEN, COMPRA; `CODIGO` → Proveedores.

Así se reduce duplicación entre documentos de clientes y se mantiene claro el mundo proveedores, con menos columnas irrelevantes en cada lado.

---

## Opción B: Dejar como está (tablas separadas)

Mantener Facturas, Presupuestos, Pedidos, Cotizacion, NOTACREDITO, NOTADEBITO, Ordenes, Compras como tablas distintas.

Ventajas:
- Consultas y reportes por tipo de documento son muy claros (“solo facturas”, “solo presupuestos”).
- Numeración y reglas fiscales por tipo están naturalmente separadas.
- No hay migración masiva ni riesgo de mezclar documentos.
- Ya tienes FKs, SPs y aplicación acoplados a estas tablas.

Desventajas:
- Estructura repetida: mismos patrones en muchas tablas.
- Más scripts de normalización y más SPs parecidos (emitir_factura_tx, emitir_presupuesto_tx, etc.).

---

## Recomendación práctica

- **A corto/medio plazo: mantener tablas separadas (Opción B)**  
  - La base ya está normalizada con estas tablas; el coste y riesgo de unificar ahora es alto.  
  - Se puede **reducir duplicación en la capa de aplicación** sin tocar el modelo de datos:
    - Un “servicio de documentos” o SP genérico que reciba `@TipoOperacion` y llame al SP concreto (emitir factura, emitir presupuesto, …) o que escriba en la tabla que corresponda.
    - DTOs o tipos compartidos (cabecera + detalle + formas de pago) y validaciones comunes en la API.
    - Así la lógica repetida se centraliza en código y el esquema sigue estable y claro por tipo de documento.

- **Unificación física (Opción A)** solo compensa si:
  - Vas a hacer un **rediseño grande** del producto (nueva versión, nueva base), o
  - Necesitas **muchos reportes transversales** (todos los documentos de un cliente en una sola tabla) y quieres simplificar consultas y mantenimiento a largo plazo.

En ese caso, el enfoque más razonable sería **Variante 2**:  
**DocumentosVenta** (FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENTREGA) y **DocumentosCompra** (ORDEN, COMPRA), con `TIPO_OPERACION` en cada una, vistas o lógica de negocio que sigan exponiendo “Facturas”, “Presupuestos”, etc., y secuencias de numeración por (TIPO_OPERACION, SERIALTIPO, Tipo_Orden) donde aplique.

---

## Resumen

| Criterio              | Tablas separadas (actual) | Documento unificado por TIPO      |
|-----------------------|---------------------------|-----------------------------------|
| Claridad por tipo     | Alta                      | Requiere filtro por TIPO_OPERACION |
| Duplicación estructura| Sí                        | No (una o dos tablas)             |
| Migración             | Nada                      | Grande                            |
| Numeración por tipo   | Natural                   | Por TIPO_OPERACION + serial/memoria |
| Donde unificar primero| —                         | Capa aplicación / SPs genéricos   |

La idea de que **Facturas sea la “principal”** y el resto sean “iguales con otro tipo” es correcta a nivel conceptual; la decisión es si quieres que esa unificación sea **solo en la lógica y el código** (recomendado ahora) o también **en las tablas** (más adecuado para un rediseño futuro).
