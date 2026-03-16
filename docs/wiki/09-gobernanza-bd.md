# 09 - Gobernanza de Base de Datos (Fase 1)

## Objetivo

Establecer una base de datos robusta y trazable sin romper la operacion actual:

- medir deuda estructural (PK, auditoria, duplicidad),
- estandarizar auditoria en tablas criticas,
- vigilar dependencias de endpoints por modulo.

## Scripts SQL

Ubicacion: `web/api/sql/governance`

1. `00_governance_baseline.sql`
- crea catalogo de decisiones y snapshots de calidad (`SchemaGovernanceDecision`, `SchemaGovernanceSnapshot`),
- crea vistas:
  - `vw_Governance_AuditCoverage`
  - `vw_Governance_DuplicateNameCandidates`
  - `vw_Governance_TableSimilarityCandidates`,
- crea `usp_Governance_CaptureSnapshot`.

2. `10_audit_columns_phase1.sql`
- agrega columnas estandar de auditoria en tablas criticas (POS, Restaurante, Contabilidad, Fiscal, Documentos):
  - `CreatedAt`, `UpdatedAt`, `CreatedBy`, `UpdatedBy`,
  - `IsDeleted`, `DeletedAt`, `DeletedBy`,
  - `RowVer`,
- crea triggers `TR_Audit_*_UpdatedAt` para mantener `UpdatedAt`.

3. `20_endpoint_dependency_readiness.sql`
- crea matriz `EndpointDependency`,
- crea vistas:
  - `vw_Governance_EndpointReadiness`
  - `vw_Governance_EndpointReadinessSummary`.

4. `30_phase2_canonical_consolidation.sql`
- define consolidaciones canónicas por dominio para duplicados clave,
- migra datos y crea vistas legacy:
  - `Categoria` -> `Categorias` (con triggers INSTEAD OF),
  - `Cliente` -> `Clientes`,
  - `Inventarios` -> `Inventario`,
  - `Monedas` -> `MonedaDenominacion` (vista `Monedas` legacy).

5. `31_phase2_auto_consolidate_empty_duplicates.sql`
- consolida de forma automatica pares con `similarity_ratio=1.0` cuando una tabla está vacia y su par tiene datos,
- reemplaza la tabla vacia por vista de compatibilidad.

6. `11_audit_columns_phase2_maestros.sql`
- crea helper `usp_Governance_ApplyAuditColumns`,
- aplica auditoria por lote de maestros/core.

7. `12_audit_columns_phase3_movimientos.sql`
- aplica auditoria al resto de tablas de usuario pendientes.

8. `13_audit_decision_reconciliation.sql`
- reconcilia decisiones `AUDIT` rechazadas por conflicto de `timestamp` legacy cuando la tabla ya cumple auditoria base.

9. `14_cleanup_legacy_backup_decisions.sql`
- marca como `DONE` decisiones de tablas backup (`__legacy_backup_phase2`) para limpiar el tablero.

## Ejecucion

Desde la raiz del repo:

```powershell
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/00_governance_baseline.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/30_phase2_canonical_consolidation.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/31_phase2_auto_consolidate_empty_duplicates.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/10_audit_columns_phase1.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/11_audit_columns_phase2_maestros.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/12_audit_columns_phase3_movimientos.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/13_audit_decision_reconciliation.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/14_cleanup_legacy_backup_decisions.sql
sqlcmd -S <SERVER> -d <DB> -U <USER> -P <PASS> -b -i web/api/sql/governance/20_endpoint_dependency_readiness.sql
```

## Reporte automatizado

En `web/api`:

```bash
npm run db:governance:report
```

El comando:
- toma snapshot de calidad de esquema,
- muestra readiness por modulo (POS/RESTAURANTE/CONTABILIDAD/FISCAL),
- falla (`exit 1`) si faltan dependencias criticas.

## CI

Se agregó workflow de GitHub Actions:

- `.github/workflows/db-governance.yml`

Ejecuta `npm run db:governance:report` en PR/push cuando existan secretos de BD (`DB_SERVER`, `DB_DATABASE`, `DB_USER`, `DB_PASSWORD`).

## Siguiente fase recomendada

1. Registrar decisiones de consolidacion para tablas duplicadas (`Cliente/Clientes`, `Categoria/Categorias`, etc).
2. Normalizar maestros y tablas de movimiento con estrategia `canonica + vista compatibilidad`.
3. Mover soft-delete de forma consistente a endpoints de API.
4. Incorporar `db:governance:report` en CI/CD previo a despliegue.
