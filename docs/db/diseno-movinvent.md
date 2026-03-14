# MovInvent: diseño y uso para reporte SENIAT

La tabla **MovInvent** registra cada entrada y salida de inventario con la cantidad que había antes del movimiento, la cantidad movida y la cantidad resultante, más **precio de costo** y **precio de venta** al momento de la operación, requeridos para el reporte de inventario que exige el SENIAT (entradas, salidas, autoconsumo, ajustes, etc.).

## Objetivo

- Saber **qué cantidad había antes** del movimiento, **cuánto se movió** y **cuánto quedó**.
- Guardar **precio de costo** y **precio de venta** en el instante de la operación (no el actual), para reportes fiscales y auditoría.
- Un registro por línea de documento que afecte stock (compras, ventas, devoluciones, anulaciones, y en el futuro: ajustes, autoconsumo, retiro por defectuosos).

## Enfoque: transaccional en línea (recomendado)

El registro se hace **en la misma transacción** que el documento (emitir factura, compra, anulación, etc.):

- **Ventaja:** El costo y precio de venta son los del momento de la operación; no hay que recalcular por fechas.
- **Ventaja:** Si el documento hace rollback, no queda ningún movimiento huérfano.
- **Ventaja:** Orden cronológico y consistencia con Inventario en una sola transacción.

**Alternativa “por fechas”:** Un proceso batch que recalculase movimientos desde documentos por rango de fechas sería más complejo y podría perder el costo/precio histórico de la línea. No se recomienda para el registro primario; solo tiene sentido para agregados (ej. **MovInventMes**) o reportes derivados.

## Columnas relevantes

| Columna           | Uso |
|-------------------|-----|
| CODIGO / PRODUCT  | Código del ítem en Inventario. |
| DOCUMENTO         | Número del documento que origina el movimiento (factura, compra, nota crédito, etc.). En anulaciones suele usarse `NUM_DOC + '_ANUL'`. |
| FECHA             | Fecha del movimiento (normalmente la del documento). |
| MOTIVO            | Texto descriptivo: `'COMPRA:123'`, `'FACT:456'`, `'NotaCredito:789'`, `'Anulacion COMPRA:123'`, etc. |
| TIPO              | **Ingreso** / **Egreso** / **Anulacion Egreso** / **Anulacion Ingreso**. Define si suma o resta stock. |
| CANTIDAD_ACTUAL   | Existencia **antes** del movimiento. |
| CANTIDAD          | Cantidad que se movió (positiva). |
| CANTIDAD_NUEVA    | Existencia **después** del movimiento. |
| PRECIO_COMPRA     | Costo unitario al momento de la operación (para entradas y para reporte SENIAT en salidas). |
| PRECIO_VENTA      | Precio de venta unitario al momento de la operación (para egresos por venta y reporte SENIAT). |
| ALICUOTA          | % IVA de la línea, si aplica. |
| CO_USUARIO        | Usuario que registra. |
| ANULADA           | (Opcional) 1 si el movimiento es una reversión por anulación. |

## Cuándo se registra

| Operación              | TIPO MovInvent   | PRECIO_COMPRA      | PRECIO_VENTA   |
|------------------------|------------------|--------------------|----------------|
| Compra (entrada)       | Ingreso          | Precio/costo línea | Inventario     |
| Venta / Pedido / Nota entrega | Egreso       | Costo ref. inventario | Precio línea |
| Nota de crédito (devolución) | Ingreso      | Costo ref. inventario | Precio ref.  |
| Anulación compra       | Egreso           | Precio línea doc   | Inventario     |
| Anulación venta/pedido/nota entrega | Ingreso | Costo ref. inventario | Precio línea doc |
| Ajuste (futuro)        | Ingreso/Egreso   | Según tipo         | -              |
| Autoconsumo / Retiro defectuosos (futuro) | Egreso | Costo ref.   | 0 o N/A        |

## Tipos de movimiento (TIPO / MOTIVO)

- **Ingreso:** Compra, nota de crédito (devolución), anulación de egreso (devolver stock).
- **Egreso:** Venta (factura), pedido, nota de entrega, anulación de compra, ajuste negativo, autoconsumo, retiro por defectuosos.
- **Anulacion Egreso / Anulacion Ingreso:** Reversión de un documento; se registra con DOCUMENTO = `NUM_DOC + '_ANUL'` para trazabilidad.

Para el reporte SENIAT se pueden filtrar por **TIPO** y **MOTIVO** para separar entradas, salidas por venta, devoluciones, ajustes y autoconsumo/retiros.

## Dónde se escribe MovInvent

- **Documentos unificados:** `sp_emitir_documento_compra_tx`, `sp_emitir_documento_venta_tx`, `sp_anular_documento_compra_tx`, `sp_anular_documento_venta_tx` (con PRECIO_COMPRA, PRECIO_VENTA, ALICUOTA).
- **Legacy (si se siguen usando):** `sp_emitir_factura_tx`, `sp_emitir_compra_tx`, `sp_emitir_presupuesto_tx`, `sp_emitir_pedido_tx` y sus `sp_anular_*`.
- **Notas (API):** módulo notas (nota crédito, nota entrega, anulación) en `web/api/src/modules/notas/service.ts`.

## MovInventMes y Libro Auxiliar (Art. 177 LISR)

La tabla **MovInventMes** es la tabla auxiliar de salida para el reporte **Libro Auxiliar de Entradas y Salidas del Inventario** (Art. 177 LISR, método PEPS). Se rellena desde **MovInvent** con:

- **sp_MovUnidades** `@Periodo = 'MM/YYYY'` o `@FechaDesde`, `@FechaHasta`: recalcula y rellena MovInventMes para ese período. Clasifica cada movimiento en Entradas, Salidas, Autoconsumo, Retiros según TIPO y MOTIVO (ver abajo). El **inventario inicial del mes** se obtiene del cierre del mes anterior (último `cantidad_nueva` en MovInvent antes del primer día del período).
- **sp_MovUnidadesMes** `@Periodo = 'MM/YYYY'`: llama a sp_MovUnidades para ese mes. Con `@RefrescarSiguiente = 1` además refresca el mes siguiente para que su "inicial" sea el cierre de este mes.

Flujo recomendado: al cerrar el mes M, ejecutar `EXEC sp_MovUnidadesMes @Periodo = 'MM/YYYY'`. Para el reporte del mes M+1, volver a ejecutar sp_MovUnidadesMes de M+1 (el inicial de M+1 será el cierre de M calculado desde MovInvent).

### Clasificación TIPO / MOTIVO → columnas del reporte

| MovInvent TIPO   | MOTIVO (ejemplos)                          | Columna MovInventMes |
|------------------|--------------------------------------------|----------------------|
| Ingreso          | COMPRA, NotaCredito, Anulacion ... Egreso   | **Entradas**         |
| Egreso           | FACT, Doc:, PEDIDO, NOTA_ENTREGA, Presup    | **Salidas**          |
| Egreso           | Autoconsumo                                 | **AutoConsumo**      |
| Egreso           | Anulacion COMPRA, Retiro, Ajuste, defectuoso| **Retiros**          |

Los movimientos con `Anulada = 1` se excluyen para no duplicar efecto (la anulación ya está registrada como movimiento inverso).

## Scripts relacionados

- **add_movinvent_precios.sql:** Añade columnas PRECIO_COMPRA, PRECIO_VENTA, ALICUOTA, ANULADA a MovInvent si no existen (ejecutar en bases antiguas).
- **sp_MovUnidades.sql:** Rellena MovInventMes desde MovInvent para un período; clasifica Entradas/Salidas/AutoConsumo/Retiros; inventario inicial = cierre mes anterior. **Integridad:** si un artículo no tuvo movimiento en el mes pero está en Inventario (existencia > 0) y no tiene historial en MovInvent antes del período, se incluye igual desde Inventario como existencia inicial (para que el reporte "entradas menos salidas" refleje la existencia actual).
- **sp_MovUnidadesMes.sql:** Cierra el mes anterior (sp_CerrarMesInventario) y rellena MovInventMes para el mes dado; opcionalmente refresca el mes siguiente.
- **create_cierre_mensual_inventario.sql:** Crea la tabla CierreMensualInventario (cierre por mes/producto).
- **sp_CerrarMesInventario.sql:** Calcula y guarda el cierre de un mes; ese cierre es el inventario inicial del mes siguiente. Ver **FLUJO_INVENTARIO_CIERRE_MENSUAL.md**.

**Convención:** Todos los scripts de SP usan `IF OBJECT_ID(...) DROP PROCEDURE` y luego `CREATE PROCEDURE` para reemplazar el procedimiento al ejecutar el script.
- FK MovInvent.CODIGO → Inventario.CODIGO: `cleanup_fix_fk_datqbox.sql` / `cleanup_create_fk_datqbox.sql`.
