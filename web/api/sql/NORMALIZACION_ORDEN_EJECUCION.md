# Orden de ejecución de scripts de normalización (DatqBox / Sanjose)

Ejecutar en la base de datos **Sanjose** en este orden:

| Paso | Script | Descripción |
|------|--------|-------------|
| 1 | `cleanup_drop_integration_tables.sql` | Elimina tablas de integración en inglés si existen. |
| 2 | `cleanup_create_fk_datqbox.sql` | Limpieza de huérfanos (detalles sin cabecera, cabeceras sin padre) y creación de FKs básicas. |
| 3 | `cleanup_fix_fk_datqbox.sql` | Ajuste de longitudes de columnas, claves compuestas (NUM_FACT, SERIALTIPO, Tipo_Orden), FKs compuestas y limpieza por clave fiscal. |
| 4 | `cleanup_add_serialtipo_memoria.sql` | Añade SERIALTIPO y Tipo_Orden a P_Cobrar/P_Cobrarc; SerialFiscal y Memoria a DetallePago, AbonosPagos, AbonosPagosClientes. Rellena desde Facturas/Presupuestos. |
| 5 | `cleanup_normalize_phase2.sql` | Pagos/Abonos: huérfanos, FKs a Clientes/Proveedores, FKs de detalles a cabecera. NOTADEBITO/Detalle_notadebito: Tipo_Orden y FK compuesta. |

## Notas

- Hacer **copia de seguridad** antes del primer script.
- Si alguna FK falla por datos inconsistentes, corregir datos y volver a ejecutar el script (los scripts usan `IF NOT EXISTS` para no duplicar restricciones).
- Los índices únicos **UQ_Pagos_CODIGO_RECNUM** y **UQ_Abonos_CODIGO_RECNUM** pueden fallar si hay duplicados; en ese caso limpiar duplicados antes de ejecutar de nuevo.
- Documentación de claves fiscales y Compras: `esquema_clave_fiscal.md`.
- Diseño: unificar documentos por TIPO_OPERACION vs. tablas separadas: `DISENO_DOCUMENTOS_UNIFICADO_VS_TABLAS_SEPARADAS.md`.
- **Documentos unificados (nueva versión):** `create_documentos_unificado.sql` crea DocumentosVenta, DocumentosCompra y detalles; `migrate_to_documentos_unificado.sql` copia datos desde las tablas actuales. API: `/v1/documentos-venta` y `/v1/documentos-compra` (ver OpenAPI).
- **Eliminar tablas legacy (opcional, después de migrar):** `drop_documentos_legacy_tables.sql` elimina físicamente Facturas, Presupuestos, Pedidos, Cotizacion, NOTACREDITO, NOTADEBITO, Compras, Ordenes y sus detalles/formas de pago, ya cubiertas por las tablas unificadas. Ejecutar solo cuando la app use solo las tablas unificadas y con backup previo.
