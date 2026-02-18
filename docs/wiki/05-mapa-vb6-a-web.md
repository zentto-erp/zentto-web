# 05 - Mapa VB6 → Web/.NET

## Fuentes legacy consideradas

- `DatQBox Admin`
- `DatQBox Admin Gym`
- `DatQBox Compras`
- `DatQBox Configurador`
- `DatQBox DB`
- `DatQBox FormDesingner`
- `DatqBox MenuDocking`
- `DatQBox PtoVenta`
- `Spooler Fiscal Dll`
- `Spooler Fiscal HKA`
- `Spooler Fiscal Rigazsa Dll`
- `Spooler Fiscal OCX`
- `Spooler Fiscal HKA .NET DatqBox`
- `Spooler Fiscal HKA .NET Tally`
- `Visor SQL Server`

## Evidencia de inventario

En `docs/legacy-inventory/` ya existe inventario estructurado por proyecto (Admin, Compras, Configurador, PtoVenta), incluyendo forms, modules y classes.

## Relación funcional recomendada

- Formularios VB6 administrativos/comerciales ↔ módulos web API + frontend
- SQL legacy y reportes ↔ capa API + scripts SQL versionados
- Integraciones fiscales ↔ spoolers y servicios dedicados (mantener separación de responsabilidades)

## Reglas para migrar lógica heredada

1. Identificar la fuente VB6 exacta (form + módulo + clase).
2. Extraer reglas de negocio y validaciones, no copiar UI legacy.
3. Re-implementar en servicios backend (API) y hooks/frontend.
4. Verificar equivalencia funcional con casos reales de negocio.
5. Documentar el mapeo en PR/wiki para trazabilidad.
