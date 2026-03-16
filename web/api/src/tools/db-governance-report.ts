import "dotenv/config";
import { getPool } from "../db/mssql.js";

type ReadinessRow = {
  ModuleName: string;
  ObjectType: string;
  ObjectName: string;
  IsCritical: boolean;
  ObjectExists: boolean;
};

type ReadinessSummaryRow = {
  ModuleName: string;
  TotalDependencies: number;
  AvailableDependencies: number;
  MissingDependencies: number;
  MissingCritical: number;
};

type SnapshotRow = {
  Id: number;
  SnapshotAt: string;
  TotalTables: number;
  TablesWithoutPK: number;
  TablesWithoutCreatedAt: number;
  TablesWithoutUpdatedAt: number;
  TablesWithoutCreatedBy: number;
  TablesWithoutDateColumns: number;
  DuplicateNameCandidatePairs: number;
  SimilarityCandidatePairs: number;
};

async function main() {
  const pool = await getPool();

  const hasGovernanceView = await pool.request().query<{ ok: number }>(`
    SELECT CASE WHEN OBJECT_ID('dbo.vw_Governance_EndpointReadinessSummary', 'V') IS NOT NULL THEN 1 ELSE 0 END AS ok
  `);

  if (Number(hasGovernanceView.recordset?.[0]?.ok ?? 0) !== 1) {
    console.error("[db-governance] Falta baseline de gobernanza. Ejecuta scripts SQL de governance primero.");
    process.exit(2);
  }

  const snapshotQuery = await pool.request().query<SnapshotRow>(`
    IF OBJECT_ID('dbo.usp_Governance_CaptureSnapshot', 'P') IS NOT NULL
      EXEC dbo.usp_Governance_CaptureSnapshot @Notes = N'capturado por db-governance-report.ts';
    SELECT TOP 1
      Id,
      SnapshotAt,
      TotalTables,
      TablesWithoutPK,
      TablesWithoutCreatedAt,
      TablesWithoutUpdatedAt,
      TablesWithoutCreatedBy,
      TablesWithoutDateColumns,
      DuplicateNameCandidatePairs,
      SimilarityCandidatePairs
    FROM dbo.SchemaGovernanceSnapshot
    ORDER BY Id DESC;
  `);
  const snapshot = snapshotQuery.recordsets?.[1]?.[0] ?? snapshotQuery.recordset?.[0];

  const summaryRs = await pool.request().query<ReadinessSummaryRow>(`
    SELECT
      ModuleName,
      TotalDependencies,
      AvailableDependencies,
      MissingDependencies,
      MissingCritical
    FROM dbo.vw_Governance_EndpointReadinessSummary
    ORDER BY ModuleName;
  `);

  const missingRs = await pool.request().query<ReadinessRow>(`
    SELECT
      ModuleName,
      ObjectType,
      ObjectName,
      IsCritical,
      ObjectExists
    FROM dbo.vw_Governance_EndpointReadiness
    WHERE ObjectExists = 0
    ORDER BY IsCritical DESC, ModuleName, ObjectType, ObjectName;
  `);

  if (snapshot) {
    console.log("[db-governance] Snapshot de esquema:");
    console.log(
      JSON.stringify(
        {
          id: snapshot.Id,
          at: snapshot.SnapshotAt,
          totalTables: snapshot.TotalTables,
          tablesWithoutPK: snapshot.TablesWithoutPK,
          tablesWithoutCreatedAt: snapshot.TablesWithoutCreatedAt,
          tablesWithoutUpdatedAt: snapshot.TablesWithoutUpdatedAt,
          tablesWithoutCreatedBy: snapshot.TablesWithoutCreatedBy,
          tablesWithoutDateColumns: snapshot.TablesWithoutDateColumns,
          duplicateNamePairs: snapshot.DuplicateNameCandidatePairs,
          similarityPairs: snapshot.SimilarityCandidatePairs
        },
        null,
        2
      )
    );
  }

  console.log("[db-governance] Readiness por modulo:");
  for (const row of summaryRs.recordset ?? []) {
    console.log(
      `- ${row.ModuleName}: ${row.AvailableDependencies}/${row.TotalDependencies} disponibles, faltantes=${row.MissingDependencies}, faltantes_criticos=${row.MissingCritical}`
    );
  }

  const missing = missingRs.recordset ?? [];
  if (missing.length > 0) {
    console.log("[db-governance] Dependencias faltantes:");
    for (const row of missing) {
      console.log(`- [${row.ModuleName}] ${row.ObjectType} ${row.ObjectName} critical=${row.IsCritical ? "yes" : "no"}`);
    }
  } else {
    console.log("[db-governance] No hay dependencias faltantes.");
  }

  const missingCritical = missing.filter((row) => Boolean(row.IsCritical));
  if (missingCritical.length > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error("[db-governance] Error:", error);
  process.exit(1);
});
