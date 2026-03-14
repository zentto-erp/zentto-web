# Esquema: tablas DocumentosVenta y DocumentosCompra

Referencia rápida para mapear las APIs a las nuevas tablas.

## Tablas y relaciones

```
TipoOperacion (Codigo PK)  ←—— DocumentosVenta.TIPO_OPERACION
                              ←—— DocumentosCompra.TIPO_OPERACION

Clientes (CODIGO PK)       ←—— DocumentosVenta.CODIGO

DocumentosVenta (NUM_FACT, SERIALTIPO, Tipo_Orden PK)
    ←—— DocumentosVentaDetalle (NUM_FACT, SERIALTIPO, Tipo_Orden)
    ←—— DocumentosVentaFormaPago (NUM_FACT, SerialFiscal, Memoria)

Proveedores (CODIGO PK)    ←—— DocumentosCompra.COD_PROVEEDOR

DocumentosCompra (NUM_FACT, COD_PROVEEDOR PK)
    ←—— DocumentosCompraDetalle (NUM_FACT, COD_PROVEEDOR)

Inventario (CODIGO)        ←—— DocumentosVentaDetalle.COD_SERV
                              ←—— DocumentosCompraDetalle.CODIGO
```

## DocumentosVenta (cabecera)

| Columna            | Tipo           | Descripción |
|--------------------|----------------|-------------|
| NUM_FACT           | NVARCHAR(60)   | PK. Número de documento |
| SERIALTIPO         | NVARCHAR(60)   | PK. Serial fiscal |
| Tipo_Orden         | NVARCHAR(6)    | PK. Memoria fiscal |
| TIPO_OPERACION     | NVARCHAR(20)   | FACT, PRESUP, PEDIDO, COTIZ, NOTACRED, NOTADEB, NOTA_ENT |
| CODIGO             | NVARCHAR(12)   | FK Clientes |
| FECHA              | DATETIME       | |
| FECHA_REPORTE      | DATETIME       | |
| PAGO               | NVARCHAR(30)   | CONTADO, CREDITO, etc. |
| TOTAL              | DECIMAL(18,4)  | |
| COD_USUARIO        | NVARCHAR(60)   | |
| OBSERV             | NVARCHAR(4000) | |
| CANCELADA          | CHAR(1)        | S/N |
| MONEDA | NVARCHAR(20) | Tipo de moneda (BS, USD, etc.). Por defecto BS |
| TASA_CAMBIO | FLOAT | Tasa de cambio del día al emitir (valor de tasa_moneda/tasa_dolar). Sin FK; se rellena con el valor del día según moneda principal |
| Monto_Efect, Monto_Cheque, Monto_Tarjeta, Abono, Saldo, Tarjeta, Cta, BANCO_CHEQUE, Banco_Tarjeta, FECHA_REPORTE_FISCAL | | Igual que Facturas/Presupuestos |

## DocumentosVentaDetalle (líneas)

| Columna         | Tipo          |
|-----------------|---------------|
| Id              | INT IDENTITY PK |
| NUM_FACT        | NVARCHAR(60)  |
| SERIALTIPO      | NVARCHAR(60)  |
| Tipo_Orden      | NVARCHAR(6)   |
| COD_SERV        | NVARCHAR(60)  FK Inventario |
| CANTIDAD        | DECIMAL(18,4) |
| PRECIO          | DECIMAL(18,4) |
| ALICUOTA        | DECIMAL(18,4) |
| TOTAL           | DECIMAL(18,4) |
| PRECIO_DESCUENTO| DECIMAL(18,4) |
| Relacionada     | INT           |
| Cod_Alterno     | NVARCHAR(60)  |

## DocumentosVentaFormaPago

| Columna    | Tipo          | Referencia a DocumentosVenta |
|------------|---------------|------------------------------|
| NUM_FACT   | NVARCHAR(60)  | = NUM_FACT                   |
| SerialFiscal| NVARCHAR(60) | = SERIALTIPO                 |
| Memoria    | NVARCHAR(6)   | = Tipo_Orden                 |
| TIPO, MONTO, BANCO, CUENTA, NUMERO, tasacambio/TASA_CAMBIO, FECHA_RETENCION | | tasacambio/TASA_CAMBIO = tasa del día para el pago (tasa_moneda/tasa_dolar) |

## DocumentosCompra (cabecera)

| Columna        | Tipo           |
|----------------|----------------|
| NUM_FACT       | NVARCHAR(60)   PK |
| COD_PROVEEDOR  | NVARCHAR(10)   PK, FK Proveedores |
| TIPO_OPERACION | NVARCHAR(20)   ORDEN, COMPRA |
| MONEDA         | NVARCHAR(20)   Tipo de moneda (BS, USD, etc.). Por defecto BS |
| TASA_CAMBIO    | FLOAT          Tasa del día al emitir (tasa_moneda/tasa_dolar). Se rellena con el valor del día según moneda principal |
| FECHA, NOMBRE, RIF, TOTAL, TIPO, CONCEPTO, COD_USUARIO, ANULADA, FECHARECIBO | |
| SERIALTIPO, Tipo_Orden | NULL para COMPRA; opcional para ORDEN |

## DocumentosCompraDetalle (líneas)

| Columna       | Tipo          |
|---------------|---------------|
| Id            | INT IDENTITY PK |
| NUM_FACT      | NVARCHAR(60)  |
| COD_PROVEEDOR | NVARCHAR(10)  |
| CODIGO        | NVARCHAR(60)  FK Inventario |
| Referencia, DESCRIPCION, FECHA, CANTIDAD, PRECIO_COSTO, Alicuota, Co_Usuario | |

## TipoOperacion (catálogo)

| Codigo   | Nombre            | Lado    |
|----------|-------------------|---------|
| FACT     | Factura           | VENTA   |
| PRESUP   | Presupuesto       | VENTA   |
| PEDIDO   | Pedido            | VENTA   |
| COTIZ    | Cotización        | VENTA   |
| NOTACRED | Nota de crédito   | VENTA   |
| NOTADEB  | Nota de débito    | VENTA   |
| NOTA_ENT | Nota de entrega   | VENTA   |
| ORDEN    | Orden (proveedor) | COMPRA  |
| COMPRA   | Compra            | COMPRA  |

---

**Tasa de cambio:** En cabecera (DocumentosVenta, DocumentosCompra) y en formas de pago se guarda **MONEDA** y **TASA_CAMBIO**. No hay FK a `tasa_moneda`/`tasa_dolar`; al emitir el documento se debe consultar la tasa del día según la moneda principal y guardar ese valor en TASA_CAMBIO.

**Script de creación:** `create_documentos_unificado.sql`  
**Añadir tasa a tablas existentes:** `add_tasa_cambio_documentos.sql`  
**Migración desde tablas actuales:** `migrate_to_documentos_unificado.sql`
