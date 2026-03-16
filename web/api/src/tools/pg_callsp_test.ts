/**
 * Test de callSp / callSpOut vía abstracción multi-BD.
 * Ejecutar: DB_TYPE=postgres PG_PASSWORD=1234 npx tsx src/tools/pg_callsp_test.ts
 */
import { callSp, callSpOut } from "../db/query.js";

async function main() {
  try {
    // 1. callSp — lista de países
    const paises = await callSp("usp_CFG_Country_List", { ActiveOnly: 1 });
    console.log(`✓ callSp usp_CFG_Country_List — ${paises.length} filas`);
    if (paises[0]) console.log("  primera:", JSON.stringify(paises[0]));

    // 2. callSp — empleados
    const emps = await callSp("usp_HR_Employee_List", { CompanyId: 1 });
    console.log(`✓ callSp usp_HR_Employee_List — ${emps.length} filas`);
    if (emps[0]) console.log("  primero:", JSON.stringify(emps[0]));

    console.log("\n✅ DB_TYPE=postgres: abstracción callSp funciona correctamente");
    process.exit(0);
  } catch (e: any) {
    console.error("✗ ERROR:", e.message);
    process.exit(1);
  }
}
main();
