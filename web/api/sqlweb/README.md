# DatqBoxWeb SQLWeb

Base de datos nueva y canónica para DatqBox con capa de compatibilidad API.

## Ejecucion rapida

```powershell
sqlcmd -S DELLXEONE31545 -U sa -P 1234 -i web/api/sqlweb/run_all.sql
```

## Orden de ejecucion detallado

1. `00_create_database_datqboxweb.sql`
2. `01_core_foundation.sql`
3. `02_master_data.sql`
4. `03_accounting_core.sql`
5. `04_operations_core.sql`
6. `05_api_compat_bridge.sql`
7. `06_seed_reference_data.sql`
8. `07_pos_rest_extensions.sql`
9. `08_fin_hr_rest_admin_extensions.sql`
10. `09_legacy_api_tables_compat.sql`
11. `10_legacy_api_sps_compat.sql`
12. `11_legacy_cleanup_upsize_ts.sql`

## Objetivo de diseno

- Modelo canónico por dominio: `sec`, `cfg`, `master`, `acct`, `ar`, `ap`, `pos`, `rest`, `fiscal`.
- Estandar unico de usuarios/auditoria por `UserId`.
- Compatibilidad transicional en `dbo` para API actual:
  - `Asientos`, `Asientos_Detalle`, `DtllAsiento`
  - `sp_CxC_Documentos_List`, `sp_CxP_Documentos_List`
  - `FiscalCountryConfig`, `FiscalTaxRates`, `FiscalInvoiceTypes`, `FiscalRecords`
  - `TasasDiarias`
  - Tablas legacy clave usadas por endpoints actuales (ventas, compras, maestros)
  - SPs `usp_*` y `sp_*` requeridos por módulos pendientes de migración

## Notas

- SQL Server objetivo validado: `SQL Server 2012 SP4`.
- El bridge `dbo` permite migrar endpoints por fases sin sacrificar el modelo canónico.
- Diagrama ER: `ER_DATQBOXWEB.mmd`.
