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
13. `12_seed_smoke_test_data.sql`
14. `13_auth_compat_and_seed.sql`
15. `14_rest_order_ticket_audit_compat.sql`
16. `15_inventario_id_compat.sql`
17. `16_sistema_tables_seed.sql`
18. `17_media_assets.sql`
19. `18_media_asset_key_length_fix.sql`
20. `../sql/sqlweb/001_user_company_access.sql`
21. `../sql/sqlweb/003_branch_country_support.sql`
22. `../sql/sqlweb/004_country_timezone_support.sql`
23. `../sql/sqlweb/005_auth_security_hardening.sql`
24. `../sql/sqlweb/002_seed_multicompany_demo.sql`

## Seed opcional multiempresa (demo)

Para probar selector de empresa/sucursal en login:

- `../sql/sqlweb/002_seed_multicompany_demo.sql`

Este script agrega empresa `SPAIN01/MAIN` y tambien una sucursal `ES01` dentro de `DEFAULT`
para validar escenario multi-pais en una misma empresa (scope por sucursal).

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
