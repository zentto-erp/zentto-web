# Flujo: operaciones → movimientos → cierre mensual → reporte SENIAT

La **base de la verdad** son las **operaciones de venta y compra** (detalle por tipo: facturas, compras, notas de crédito, ajustes, etc.). A partir de ahí se generan los movimientos y el cierre mensual para que **el final de cada artículo en un mes sea el inicio del siguiente**.

## 1. Origen: detalle de operaciones

- **Ventas:** DocumentosVentaDetalle (o legacy: Detalle_facturas, Detalle_Pedidos, etc.) con fecha, producto, cantidad, precio/costo.
- **Compras:** DocumentosCompraDetalle (o legacy: Detalle_Compras, Detalle_Ordenes).
- **Ajustes / autoconsumo / retiros:** según cómo se registren (MovInvent directo o documentos de tipo ajuste).

Cada vez que se emite o anula un documento que afecta stock, se escribe en **MovInvent** (en el mismo SP de emisión/anulación): una fila por línea con Tipo (Ingreso/Egreso), Motivo, Cantidad, cantidad_nueva, Precio_Compra, etc.

## 2. MovInvent (registro de movimientos)

- Se alimenta **en línea** con cada operación (emitir factura, compra, nota crédito, anulación, etc.).
- Cada fila tiene: producto, fecha, tipo (Ingreso/Egreso), motivo, cantidad, cantidad_actual, cantidad_nueva, precio_compra, precio_venta.
- Es la base para el reporte y para el **cierre mensual**.

## 3. Cierre mensual (fin de mes = inicio del mes siguiente)

Para que **el final de enero sea el inicio de febrero** (y así cada mes):

1. **Tabla CierreMensualInventario**  
   Guarda, por período (MM/YYYY) y producto: CantidadFinal, MontoFinal, CostoUnitario.  
   Script: `create_cierre_mensual_inventario.sql` (ejecutar una vez).

2. **sp_CerrarMesInventario @Periodo = '01/2026'**  
   Al cierre de enero:
   - Calcula por producto el último movimiento en MovInvent hasta el 31/01 (último `cantidad_nueva`).
   - Inserta/actualiza en CierreMensualInventario (Periodo = '01/2026', Codigo, CantidadFinal, MontoFinal, CostoUnitario).
   - Incluye productos con existencia en Inventario que no tengan movimientos (ej. nuevos o sin historial).

3. **sp_MovUnidades @Periodo = '02/2026'** (reporte febrero)  
   - Toma el **inventario inicial de febrero** desde CierreMensualInventario donde Periodo = '01/2026' (cierre de enero).
   - Si no hay cierre guardado (ej. primer mes), usa el último movimiento en MovInvent antes del 01/02 y, si hace falta, Inventario.

Así se cumple: **cierre enero = inicio febrero**, y lo mismo para cada mes.

## 4. Primer mes de operaciones (ej. 01/01/2026)

- No hay “mes anterior”, por tanto no hay filas en CierreMensualInventario para 12/2025.
- El inventario inicial de enero puede venir de:
  - Compras o ajustes ya registrados en MovInvent antes del 01/01, o
  - Productos con existencia en Inventario (creación de productos nuevos, carga inicial).
- Se ejecuta **sp_MovUnidades '01/2026'** (o **sp_MovUnidadesMes '01/2026'** con @CerrarMesAnterior = 0).  
  El inicial se arma desde MovInvent (último antes del 01/01) + Inventario.
- Al terminar enero: **EXEC sp_CerrarMesInventario '01/2026'** para guardar el cierre.

## 5. Uso recomendado

| Acción | Comando |
|--------|--------|
| Crear tabla de cierre (una vez) | Ejecutar `create_cierre_mensual_inventario.sql` |
| Cerrar enero | `EXEC sp_CerrarMesInventario @Periodo = '01/2026'` |
| Reporte febrero (inicio feb = cierre ene) | `EXEC sp_MovUnidadesMes @Periodo = '02/2026', @CerrarMesAnterior = 1` (opcionalmente cerrar enero si no se hizo antes) |
| Solo rellenar reporte sin cerrar anterior | `EXEC sp_MovUnidades @Periodo = '02/2026'` (usa cierre ya guardado de enero si existe) |

## 6. Scripts implicados

- **create_cierre_mensual_inventario.sql** – Crea la tabla de cierre.
- **sp_CerrarMesInventario.sql** – Cierra un mes y llena CierreMensualInventario.
- **sp_MovUnidades.sql** – Rellena MovInventMes para el reporte; usa CierreMensualInventario del mes anterior como inicial.
- **sp_MovUnidadesMes.sql** – Opción de cerrar el mes anterior y rellenar el mes; llama a sp_CerrarMesInventario y sp_MovUnidades.

Con esto, la estructura y los SP garantizan que **el final de cada artículo en un mes sea el inicio del siguiente**, aunque en febrero no se venda todo lo comprado en enero.
