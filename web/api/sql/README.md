# SQL Scripts - DatqBox API

## Stored Procedures Transaccionales

### 1. usp_CxC_AplicarCobro
Aplica un cobro a cuentas por cobrar en una sola transacción.

**Ubicación:** `sp_cxc_aplicar_cobro.sql`

**Parámetros:**
- `@RequestId` - ID único para idempotencia
- `@CodCliente` - Código del cliente
- `@Fecha` - Fecha del cobro (YYYY-MM-DD)
- `@MontoTotal` - Monto total del cobro
- `@CodUsuario` - Usuario que registra
- `@Observaciones` - Observaciones opcionales
- `@DocumentosJson` - Array de documentos en JSON
- `@FormasPagoJson` - Array de formas de pago en JSON

**Ejemplo de uso:**
```sql
DECLARE @NumRecibo VARCHAR(50), @Resultado INT, @Mensaje VARCHAR(500);

EXEC usp_CxC_AplicarCobro
    @RequestId = 'req-001',
    @CodCliente = 'CLI001',
    @Fecha = '2026-02-14',
    @MontoTotal = 1500.00,
    @CodUsuario = 'SUP',
    @Observaciones = 'Cobro parcial',
    @DocumentosJson = '[{"tipoDoc":"FACT","numDoc":"F001","montoAplicar":1500}]',
    @FormasPagoJson = '[{"formaPago":"EFECTIVO","monto":1500}]',
    @NumRecibo = @NumRecibo OUTPUT,
    @Resultado = @Resultado OUTPUT,
    @Mensaje = @Mensaje OUTPUT;

SELECT @NumRecibo as NumRecibo, @Resultado as Resultado, @Mensaje as Mensaje;
```

## Cómo ejecutar los scripts

### Opción 1: SQL Server Management Studio (SSMS)
1. Abrir SSMS
2. Conectar a: `DELLXEONE31545`
3. Base de datos: `sanjose`
4. Abrir archivo `sp_cxc_aplicar_cobro.sql`
5. Ejecutar (F5)

### Opción 2: sqlcmd
```bash
sqlcmd -S DELLXEONE31545 -d sanjose -U sa -P 1234 -i sp_cxc_aplicar_cobro.sql
```

### Opción 3: Desde la API (automático)
El endpoint `POST /v1/cxc/ensure-sp` creará el SP automáticamente.

## Rendimiento

Antes (Node.js múltiples queries): ~8 segundos  
Después (SP): ~200-500ms

## Stored Procedures CRUD (no transaccionales)

Los endpoints CRUD del contrato que usan "query node" se migran a SP con **fallback** al flujo TS: la API intenta ejecutar el SP primero; si falla, usa el código actual (más lento pero seguro).

### 1. Clientes (`sp_crud_clientes.sql`)

| Procedimiento | Descripción | Parámetros |
|---------------|-------------|-----------|
| `usp_Clientes_List` | Lista paginada con filtros | @Search, @Estado, @Vendedor, @Page, @Limit, @TotalCount OUTPUT |
| `usp_Clientes_GetByCodigo` | Obtiene un cliente | @Codigo |
| `usp_Clientes_Insert` | Inserta fila (XML) | @RowXml, @Resultado OUTPUT, @Mensaje OUTPUT |
| `usp_Clientes_Update` | Actualiza por código | @Codigo, @RowXml, @Resultado OUTPUT, @Mensaje OUTPUT |
| `usp_Clientes_Delete` | Elimina por código | @Codigo, @Resultado OUTPUT, @Mensaje OUTPUT |

- **API**: `GET/POST/PUT/DELETE /v1/clientes` y `GET /v1/clientes/:codigo` intentan SP primero; respuesta incluye `executionMode: "sp"` o `"ts_fallback"`.
- **Reglas**: SQL Server 2012 (XML para filas, sin OPENJSON). Insert/Update alineados con snapshot `Clientes`: CODIGO (12), NOMBRE, RIF, NIT, DIRECCION, DIRECCION1, SUCURSAL, TELEFONO, CONTACTO, VENDEDOR (4), ESTADO, CIUDAD, **CPOSTAL**, **LIMITE**, CREDITO, LISTA_PRECIO, EMAIL, PAGINA_WWW, COD_USUARIO (sin FAX, OBS, PAIS, COD_POSTAL).

### 2. Proveedores (`sp_crud_proveedores.sql`)

| Procedimiento | Descripción | Parámetros |
|---------------|-------------|-----------|
| `usp_Proveedores_List` | Lista paginada con filtros | @Search, @Estado, @Vendedor, @Page, @Limit, @TotalCount OUTPUT |
| `usp_Proveedores_GetByCodigo` | Obtiene un proveedor | @Codigo (NVARCHAR(10)) |
| `usp_Proveedores_Insert` | Inserta fila (XML) | @RowXml, @Resultado OUTPUT, @Mensaje OUTPUT |
| `usp_Proveedores_Update` | Actualiza por código | @Codigo, @RowXml, @Resultado OUTPUT, @Mensaje OUTPUT |
| `usp_Proveedores_Delete` | Elimina por código | @Codigo, @Resultado OUTPUT, @Mensaje OUTPUT |

- **API**: `GET/POST/PUT/DELETE /v1/proveedores` y `GET /v1/proveedores/:codigo` con SP primero y `executionMode`.
- **Snapshot**: CODIGO nvarchar(10), VENDEDOR nvarchar(2), FAX, NOTAS, CPOSTAL, LIMITE, etc.

### 3. Inventario (`sp_crud_inventario.sql`)

| Procedimiento | Descripción | Parámetros |
|---------------|-------------|-----------|
| `usp_Inventario_List` | Lista paginada con filtros | @Search, @Categoria, @Marca, @Page, @Limit, @TotalCount OUTPUT |
| `usp_Inventario_GetByCodigo` | Obtiene un artículo | @Codigo (NVARCHAR(15)) |
| `usp_Inventario_Insert` / `Update` / `Delete` | CRUD por XML / código | @RowXml, @Codigo, @Resultado OUTPUT, @Mensaje OUTPUT |

- **API**: `GET/POST/PUT/DELETE /v1/inventario` con SP primero y `executionMode`. Insert/Update: columnas principales (CODIGO, Referencia, Categoria, Marca, DESCRIPCION, precios, UBICACION, etc.).

### 4. Facturas – solo List + Get (`sp_crud_facturas.sql`)

| Procedimiento | Descripción | Parámetros |
|---------------|-------------|-----------|
| `usp_Facturas_List` | Lista paginada | @NumFact, @CodUsuario, @From, @To, @Page, @Limit, @TotalCount OUTPUT |
| `usp_Facturas_GetByNumFact` | Obtiene una factura | @NumFact (NVARCHAR(20)) |

- **API**: `GET /v1/facturas` y `GET /v1/facturas/:numFact` con SP primero y `executionMode`. Emitir/anular usan `emitirFacturaTx` / `anularFacturaTx` (no SP CRUD).

### 5. Compras – List + Get (`sp_crud_compras.sql`)

| Procedimiento | Descripción | Parámetros |
|---------------|-------------|-----------|
| `usp_Compras_List` | Lista paginada con filtros | @Search, @Proveedor, @Estado, @FechaDesde, @FechaHasta, @Page, @Limit, @TotalCount OUTPUT |
| `usp_Compras_GetByNumFact` | Obtiene una compra | @NumFact (NVARCHAR(25)) |

- **API**: `GET /v1/compras` y `GET /v1/compras/:numFact` con SP primero y `executionMode`. Create/Update/Delete siguen por TS; emitir usa `emitirCompraTx`.

### 6. Cotizacion – List + Get (`sp_crud_cotizacion.sql`)

- `usp_Cotizacion_List`: @Search, @Codigo, @Page, @Limit, @TotalCount OUTPUT.
- `usp_Cotizacion_GetByNumFact`: @NumFact (NVARCHAR(20)).

### 7. Pedidos – List + Get (`sp_crud_pedidos.sql`)

- `usp_Pedidos_List`: @Search, @Codigo, @Page, @Limit, @TotalCount OUTPUT.
- `usp_Pedidos_GetByNumFact`: @NumFact (NVARCHAR(20)).

### Estado de CRUD por módulo

| Módulo | List/Get SP | Create/Update/Delete SP | Notas |
|--------|-------------|--------------------------|--------|
| Clientes | ✅ | ✅ | Completo |
| Proveedores | ✅ | ✅ | Completo |
| Inventario | ✅ | ✅ | Completo |
| Facturas | ✅ | — | Solo list/get; emitir = tx |
| Compras | ✅ | — | Solo list/get; emitir = tx |
| Cotizacion | ✅ | — | List/get SP; CUD por TS |
| Pedidos | ✅ | — | List/get SP; CUD por TS |
| Presupuestos | — | — | Pendiente |
| Ordenes | — | — | Pendiente |
| Notas (CRÉDITO/DÉBITO) | — | — | Pendiente |
| Abonos, Pagos, P_Cobrar, P_Pagar, etc. | — | — | Pendiente |

### Próximos CRUD (mismo patrón)

- [x] Cotizacion, Pedidos (list/get)
- [ ] Presupuestos, Ordenes (list/get o full CRUD SP)
- [ ] Notas, Abonos, Pagos, Cuentas por pagar, P_Cobrar, etc.

## SPs transaccionales (emitir / anular)

- [x] **Facturas**: `sp_emitir_factura_tx`, `sp_anular_factura_tx` – formas de pago, CxC, inventario.
- [x] **Compras**: `sp_emitir_compra_tx` – inventario, CxP.
- [x] **Presupuestos**: `sp_emitir_presupuesto_tx`, `sp_anular_presupuesto_tx` – misma lógica que facturas (clientes, CxC tipo PRESUP, formas pago, inventario). Tablas: Presupuestos, Detalle_Presupuestos. API: `POST /v1/presupuestos/emitir-tx`, `POST /v1/presupuestos/anular-tx`.

## Próximos SPs transaccionales

- [ ] Ordenes: `sp_emitir_orden_tx` (proveedores, CxP) – tabla Ordenes / Detalle_Ordenes.
- [ ] Notas: `sp_emitir_notacredito_tx`, `sp_emitir_notadebito_tx`.
- [ ] `usp_CxP_AplicarPago` - Cuentas por pagar
