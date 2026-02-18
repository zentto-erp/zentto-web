# SQL Migration Notes

## Conexion actual
- Servidor: `DELLXEONE31545\SQLEXPRESS`
- Base: `DatqBoxExpress`
- Driver legado: `SQLNCLI10`

## Criterio de migracion de SQL embebido VB6
1. Catalogar cada sentencia SQL por formulario/modulo.
2. Normalizar nombres y parametros.
3. Migrar consultas criticas a Stored Procedures.
4. Consumir SP desde `DatqBox.Infrastructure.Data.SqlClientExecutor`.
5. Validar resultados contra VB6 con datos de prueba.

## Convencion sugerida para SP
- Lectura: `usp_<Modulo>_<Entidad>_Get`
- Escritura: `usp_<Modulo>_<Entidad>_Save`
- Reporte: `usp_<Modulo>_<Reporte>_List`

## Inventario de esquema
- Ejecutar: `database/scripts/Export-DbInventory.ps1`
- Salida: `database/snapshots/*.csv`
