# Benchmark: Cierre de inventario y MovUnidades

## Que se hizo para acelerar

1. **Indices** (`add_indexes_inventario_cierre.sql`):
   - `IX_MovInvent_Fecha_Anulada`: (Fecha, Anulada) + INCLUDE para filtro por rango de fechas.
   - `IX_MovInvent_Codigo_Fecha_id`: (Codigo, Fecha DESC, id DESC) para ultimo movimiento por producto.
   - `IX_MovInventMes_Periodo_fecha`: (Periodo, fecha, Codigo).
   - `IX_Inventario_CODIGO`: solo si no existe PK/indice en CODIGO.

2. **SPs optimizados**:
   - Filtros por **Fecha** sin `CAST(Fecha AS DATE)` para que usen indice: `Fecha < @FinDateTime` y `Fecha >= @IniDateTime AND Fecha < @FinDateTime`.
   - **Inventario**: subconsultas correlacionadas sustituidas por `LEFT JOIN` para no golpear 60k veces la tabla.

## Como medir la duracion

### Opcion A – sqlcmd (ver tiempo en consola)

```bat
cd "c:\...\web\api\sql"
sqlcmd -S . -d Sanjose -E -i benchmark_cierre_movunidades.sql
```

El script imprime en ms:
- Tiempo de `sp_CerrarMesInventario`
- Tiempo de `sp_MovUnidades`
- Total

Con ~60k articulos y 450k+ MovInvent puede tardar varios minutos. Dejar correr hasta que termine.

### Opcion B – SSMS (tiempo por paso)

1. Abrir `benchmark_cierre_movunidades.sql` (o ejecutar solo los EXEC con periodo deseado).
2. Menu **Consulta** > **Incluir estadísticas de cliente** (Include Client Statistics).
3. Ejecutar (F5).
4. Pestaña **Estadísticas de cliente**: ver “Tiempo transcurrido” por ejecucion.

### Opcion C – Solo cierre (para ver tiempo de un SP)

```bat
sqlcmd -S . -d Sanjose -E -i benchmark_solo_cierre.sql
```

## Scripts de benchmark

| Script | Que mide |
|--------|-----------|
| `benchmark_cierre_movunidades.sql` | CerrarMesInventario + MovUnidades (02/2026) y total en ms |
| `benchmark_solo_cierre.sql` | Solo sp_CerrarMesInventario en ms |

## Orden recomendado

1. Crear indices (una vez): `add_indexes_inventario_cierre.sql`
2. Crear/actualizar SPs: `run_solo_crear_sps.sql`
3. Ejecutar benchmark: `benchmark_cierre_movunidades.sql` y anotar los ms que imprime.

Cuando tengas los tiempos (CerrarMesInventario, MovUnidades y total), se puede afinar mas (por ejemplo estadísticas, mas indices o cambiar estrategia del ROW_NUMBER).
