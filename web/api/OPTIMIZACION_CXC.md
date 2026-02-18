# Optimización Endpoint CxC - Resumen

## Cambios Realizados

### 1. Stored Procedure: `usp_CxC_AplicarCobro`
**Archivo:** `sql/sp_cxc_aplicar_cobro.sql`

**Características:**
- ✅ Compatible con SQL Server 2012 (sin TRY_CONVERT, sin OPENJSON)
- ✅ Usa XML para pasar arrays de documentos y formas de pago
- ✅ Transacción atómica (BEGIN TRAN / COMMIT / ROLLBACK)
- ✅ SET XACT_ABORT ON para rollback automático en errores
- ✅ Manejo de errores con TRY/CATCH
- ✅ Genera número de recibo automáticamente

**Parámetros:**
```sql
@RequestId VARCHAR(100)         -- ID único de la transacción
@CodCliente VARCHAR(20)         -- Código del cliente
@Fecha VARCHAR(10)              -- Fecha del cobro (YYYY-MM-DD)
@MontoTotal DECIMAL(18,2)       -- Monto total del cobro
@CodUsuario VARCHAR(20)         -- Usuario que realiza el cobro
@Observaciones VARCHAR(500)     -- Observaciones opcionales
@DocumentosXml NVARCHAR(MAX)    -- XML con documentos a pagar
@FormasPagoXml NVARCHAR(MAX)    -- XML con formas de pago
@NumRecibo VARCHAR(50) OUTPUT   -- Número de recibo generado
@Resultado INT OUTPUT           -- 1=éxito, negativo=error
@Mensaje VARCHAR(500) OUTPUT    -- Mensaje de resultado
```

**XML de Documentos:**
```xml
<documentos>
  <row tipoDoc="FACT" numDoc="F001" montoAplicar="1000.00"/>
  <row tipoDoc="FACT" numDoc="F002" montoAplicar="500.00"/>
</documentos>
```

**XML de Formas de Pago:**
```xml
<formasPago>
  <row formaPago="EFECTIVO" monto="800.00"/>
  <row formaPago="CHEQUE" monto="700.00" banco="Banco" numCheque="CHK001"/>
</formasPago>
```

### 2. Servicio Node.js: `cxc.service.ts`
**Cambios clave:**
- Funciones `documentosToXml()` y `formasPagoToXml()` para convertir arrays a XML
- Función `aplicarCobro()` usa `request.execute()` para llamar al SP
- Eliminadas múltiples queries - ahora todo es una sola llamada al SP

### 3. Rutas: `routes.ts`
- Endpoint POST `/v1/cxc/aplicar-cobro-tx` ahora usa el SP
- Agregados endpoints GET para consultar documentos pendientes y saldo

## Tablas Afectadas

| Tabla | Operación | Descripción |
|-------|-----------|-------------|
| `Pagos` | INSERT | Cabecera del recibo |
| `Pagos_Detalle` | INSERT | Formas de pago detalladas |
| `P_Cobrar` | UPDATE | Reduce el pendiente de cada documento |
| `Movimiento_Cuenta` | INSERT | Registro contable del cobro |
| `Clientes` | UPDATE | Actualiza saldo total |

## Rendimiento Esperado

| Métrica | Antes | Después |
|---------|-------|---------|
| Round-trips a BD | 5-8 queries | 1 SP call |
| Tiempo estimado | ~8 segundos | <500ms |
| Atomicidad | Manual | Automática (XACT_ABORT) |

## Prueba

```powershell
# Ejecutar script de prueba
.\test-cxc-sp.ps1
```

## Compatibilidad SQL Server 2012

El SP usa solo características disponibles en SQL Server 2012:
- `CAST()` en lugar de `TRY_CONVERT()`
- `ISNULL()` en lugar de `COALESCE()` (donde aplica)
- XML parsing con `.nodes()` y `.value()`
- `ISDATE()` para validar fechas
- Tablas temporales para evitar XML methods en GROUP BY
