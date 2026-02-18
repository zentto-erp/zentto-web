# Clave compuesta en Facturas y documentos fiscales

## Campos: NUM_FACT, SERIALTIPO, Tipo_Orden

Las tablas **Facturas**, **NOTACREDITO**, **NOTADEBITO** y sus detalles usan una **clave compuesta** para identificar de forma única un documento fiscal:

| Campo       | Significado |
|------------|-------------|
| **NUM_FACT**   | Número de factura (o documento) dentro de una misma máquina fiscal y memoria. |
| **SERIALTIPO** | Serial de la **máquina fiscal**. Identifica el equipo; si se cambia la memoria, el serial sigue siendo el mismo. |
| **Tipo_Orden** | Número de **memoria física** del equipo fiscal. Si a una máquina se le reemplaza la memoria, el serial no cambia pero la numeración de facturas vuelve a empezar desde 1 en esa nueva memoria. Tipo_Orden 1 = primera memoria, 2 = segunda (tras reemplazo), etc. |

Así una misma máquina (mismo `SERIALTIPO`) puede tener varias “memorias” (`Tipo_Orden` 1, 2, 3…), cada una con su propia secuencia de números de factura.

## Tablas que usan esta clave

- **Facturas** (PK: NUM_FACT, SERIALTIPO, Tipo_Orden)
- **Detalle_facturas** (FK con NUM_FACT, SERIALTIPO, Tipo_Orden; por comodidad también **Id** como identificador de fila)
- **Detalle_FormaPagoFacturas** (FK a Facturas con **Num_fact**, **SerialFiscal**, **Memoria** = NUM_FACT, SERIALTIPO, Tipo_Orden) — muy importante para integridad de formas de pago
- **NOTACREDITO** / **Detalle_notacredito** (con Tipo_Orden y FK compuesta)
- **NOTADEBITO** / **Detalle_notadebito** (Tipo_Orden añadido y FK compuesta por `cleanup_normalize_phase2.sql`)

Otras cabeceras (Cotizacion, Pedidos, Presupuestos, Ordenes) usan **(NUM_FACT, SERIALTIPO)** en su PK.  
**Detalle_FormaPagoCotizacion** se relaciona con Cotizacion por **(Num_fact, SerialFiscal)** = (NUM_FACT, SERIALTIPO).

### Cuentas por cobrar y pagos

Para poder relacionar correctamente cada documento con su serial fiscal y memoria:

- **P_Cobrar** y **P_Cobrarc**: tienen **SERIALTIPO** y **Tipo_Orden** (añadidos por `cleanup_add_serialtipo_memoria.sql`). Se rellenan desde Facturas (TIPO='FACT'), Presupuestos (TIPO='PRESUP'), etc. Los SPs `sp_emitir_factura_tx` y `sp_emitir_presupuesto_tx` insertan ya SERIALTIPO y Tipo_Orden al generar CxC.
- **DetallePago**: tiene **SerialFiscal** y **Memoria** (rellenados desde Facturas por Num_Fact).
- **AbonosPagos** y **AbonosPagosClientes**: tienen **SerialFiscal** y **Memoria** para vincular al documento fiscal cuando el abono referencia una factura (Num_fact).

El **número de memoria** (Tipo_Orden / Memoria) es clave para cualquier documento **emitido por nosotros** (facturas, presupuestos, etc.), igual que el **SERIALTIPO** (serial fiscal): sin ellos no se puede relacionar de forma unívoca con la cabecera del documento.

---

## Cuentas por pagar y Compras (sin SERIALTIPO ni Memoria)

**Compras** no debe tener SERIALTIPO ni Memoria: la factura es **emitida por el proveedor** y solo la cargamos. No es documento fiscal nuestro, por tanto no hay serial de máquina fiscal ni número de memoria.

La identificación única de una compra se hace por:

| Campo            | Significado |
|------------------|-------------|
| **NUM_FACT**     | Número de factura del proveedor (documento que él emitió). |
| **COD_PROVEEDOR**| Código del proveedor en nuestro sistema. |
| **NUM_COMPRA**   | (Si existe) Número de compra interno; con NUM_FACT + COD_PROVEEDOR ya suele ser única. |

La combinación **(NUM_FACT, COD_PROVEEDOR)** —o **(NUM_FACT, NUM_COMPRA, COD_PROVEEDOR)** si se usa NUM_COMPRA— **nunca se repite**: un mismo proveedor no nos dará dos facturas con el mismo número.

- **P_Pagar** y **P_Pagarc** (cuentas por pagar): no llevan SERIALTIPO ni Tipo_Orden. La relación con el documento es por **CODIGO** (proveedor) + **DOCUMENTO** (NUM_FACT de Compras) + **TIPO** (ej. 'FACT'). No se añaden columnas de serial/memoria; la clave del documento de compra es suficiente.
- **Detalle_FormaPagoCompras** y detalles de pago de compras se relacionan con **Compras** por **(Num_fact, Cod_Proveedor)** = (NUM_FACT, COD_PROVEEDOR).

Resumen: en **documentos emitidos por nosotros** (ventas, presupuestos) usamos SERIALTIPO y Memoria; en **compras** (documentos del proveedor) la clave es NUM_FACT + COD_PROVEEDOR (y opcionalmente NUM_COMPRA).

### Recibos de cobro y pagos a proveedores

- **Pagos** (recibos de cobro a clientes): **CODIGO** → Clientes. Relación con **Pagos_Detalle** por (CODIGO, RECNUM). Normalización en `cleanup_normalize_phase2.sql`: FKs Pagos→Clientes, Pagos_Detalle→Pagos.
- **Abonos** (pagos a proveedores): **CODIGO** → Proveedores. Relación con **Abonos_Detalle** por (CODIGO, RECNUM). Mismo script: FKs Abonos→Proveedores, Abonos_Detalle→Abonos.

---

La integridad referencial se mantiene con estas claves: los detalles (incluido detalle de forma de pago) referencian a la cabecera por la misma clave compuesta.
