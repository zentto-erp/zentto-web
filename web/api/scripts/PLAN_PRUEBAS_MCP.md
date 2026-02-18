# Plan de Pruebas con Agentes MCP

## Instrucciones

Abre VS Code con GitHub Copilot activado y ejecuta los siguientes comandos con los agentes MCP:

---

## 1️⃣ Database Agent - Verificar Base de Datos

```
@database-agent lista todas las tablas de nómina
```

```
@database-agent ejecuta el archivo sp_nomina_conceptolegal_adapter.sql
```

```
@database-agent verifica que la tabla NominaConceptoLegal tiene datos
```

---

## 2️⃣ API Agent - Pruebas de Endpoints

### Autenticación
```
@api-agent prueba el endpoint POST /v1/auth/login con datos: {"usuario":"SUP","clave":"SUP"}
```

### Documentos Unificados (Venta)
```
@api-agent prueba el endpoint GET /v1/documentos-venta
```

```
@api-agent prueba el endpoint GET /v1/documentos-venta?tipoOperacion=FACT
```

```
@api-agent prueba el endpoint POST /v1/documentos-venta/emitir-tx con datos: {"tipoOperacion":"FACT","documento":{"codCliente":"C0001","fecha":"2024-02-15"},"detalle":[{"codArticulo":"ART001","cantidad":1,"precio":100}]}
```

### Documentos Unificados (Compra)
```
@api-agent prueba el endpoint GET /v1/documentos-compra
```

```
@api-agent prueba el endpoint POST /v1/documentos-compra/emitir-tx con datos: {"tipoOperacion":"ORDEN","documento":{"codProveedor":"P0001","fecha":"2024-02-15"},"detalle":[{"codArticulo":"ART001","cantidad":10,"precio":50}]}
```

### Bancos y Conciliación
```
@api-agent prueba el endpoint GET /v1/bancos
```

```
@api-agent prueba el endpoint GET /v1/bancos/conciliaciones
```

```
@api-agent prueba el endpoint GET /v1/bancos/movimientos-cuenta
```

### Nómina (ConceptoLegal)
```
@api-agent prueba el endpoint GET /v1/nomina/conceptos-legales
```

```
@api-agent prueba el endpoint GET /v1/nomina/convenciones
```

```
@api-agent prueba el endpoint POST /v1/nomina/procesar-conceptolegal con datos: {"nomina":"NOM_TEST_001","cedula":"V12345678","fechaInicio":"2024-02-01","fechaHasta":"2024-02-29","convencion":"LOT","tipoCalculo":"MENSUAL"}
```

### CxC / CxP
```
@api-agent prueba el endpoint GET /v1/cxc/documentos-pendientes?codCliente=C0001
```

```
@api-agent prueba el endpoint GET /v1/cxp/documentos-pendientes?codProveedor=P0001
```

```
@api-agent prueba el endpoint POST /v1/cxc/aplicar-cobro-tx con datos: {"requestId":"req-test-001","codCliente":"C0001","fecha":"2024-02-15","montoTotal":1000,"codUsuario":"API","documentos":[{"tipoDoc":"FACT","numDoc":"000001","montoAplicar":1000}],"formasPago":[{"formaPago":"EFECTIVO","monto":1000}]}
```

### Contabilidad
```
@api-agent prueba el endpoint GET /v1/contabilidad/plan-cuentas
```

```
@api-agent prueba el endpoint GET /v1/contabilidad/asientos
```

```
@api-agent prueba el endpoint GET /v1/contabilidad/balance-general?fechaCorte=2024-02-15
```

```
@api-agent prueba el endpoint GET /v1/contabilidad/estado-resultados?fechaDesde=2024-01-01&fechaHasta=2024-02-29
```

### Catálogos
```
@api-agent prueba el endpoint GET /v1/clientes
```

```
@api-agent prueba el endpoint GET /v1/proveedores
```

```
@api-agent prueba el endpoint GET /v1/inventario
```

```
@api-agent prueba el endpoint GET /v1/empleados
```

### CRUD Genérico
```
@api-agent prueba el endpoint GET /v1/meta/Clientes
```

```
@api-agent prueba el endpoint POST /v1/crud/Feriados con datos: {"Fecha":"2024-12-25","Descripcion":"Navidad 2024"}
```

---

## 3️⃣ Validaciones Específicas

### Validar OpenAPI
```
@api-agent valida que el endpoint GET /v1/documentos-venta cumpla con el contrato OpenAPI
```

### Analizar Rutas
```
@api-agent analiza todas las rutas registradas en la API
```

### Listar Módulos
```
@api-agent lista todos los módulos disponibles en la API
```

---

## 📋 Checklist de Resultados

| Endpoint | Método | Status Esperado | Resultado |
|----------|--------|-----------------|-----------|
| /v1/auth/login | POST | 200 | ⬜ |
| /v1/documentos-venta | GET | 200 | ⬜ |
| /v1/documentos-venta/emitir-tx | POST | 201 | ⬜ |
| /v1/documentos-compra | GET | 200 | ⬜ |
| /v1/bancos | GET | 200 | ⬜ |
| /v1/bancos/conciliaciones | GET | 200 | ⬜ |
| /v1/nomina/conceptos-legales | GET | 200 | ⬜ |
| /v1/nomina/procesar-conceptolegal | POST | 200 | ⬜ |
| /v1/cxc/documentos-pendientes | GET | 200 | ⬜ |
| /v1/cxp/documentos-pendientes | GET | 200 | ⬜ |
| /v1/contabilidad/plan-cuentas | GET | 200 | ⬜ |
| /v1/contabilidad/balance-general | GET | 200 | ⬜ |
| /v1/clientes | GET | 200 | ⬜ |
| /v1/proveedores | GET | 200 | ⬜ |
| /v1/empleados | GET | 200 | ⬜ |

---

## 🔧 Si Hay Errores

### Reiniciar la API
```
@database-agent reinicia el servicio de la API
```

### Ver Logs
```
@api-agent muestra los últimos errores de la API
```

### Verificar Conexión BD
```
@database-agent verifica la conexión a la base de datos
```

---

## 📊 Resumen de Módulos Construidos

1. **Documentos Venta Unificados** - `/v1/documentos-venta`
2. **Documentos Compra Unificados** - `/v1/documentos-compra`
3. **Bancos y Conciliación** - `/v1/bancos`
4. **Nómina (ConceptoLegal)** - `/v1/nomina`
5. **CxC / CxP** - `/v1/cxc` y `/v1/cxp`
6. **Contabilidad** - `/v1/contabilidad`
7. **Catálogos** - CRUDs de maestros
8. **CRUD Genérico** - `/v1/crud` y `/v1/meta`

---

## 📝 Notas

- Asegúrate de que la API esté corriendo en `http://localhost:3001`
- Si un test falla, anota el error y continúa con los demás
- Al finalizar, revisa el checklist y reporta los fallos encontrados
- Para corregir errores, usa los agentes para identificar el problema y luego aplicar la solución
