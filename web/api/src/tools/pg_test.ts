/**
 * Prueba rápida de conectividad con PostgreSQL.
 */
import { Pool } from "pg";

async function main() {
  const pool = new Pool({
    host: "localhost", port: 5432,
    database: "datqboxweb",
    user: "postgres", password: "1234",
  });
  try {
    const ver = await pool.query("SELECT version()");
    console.log("✓ Conectado:", (ver.rows[0] as any).version.split(" ").slice(0, 2).join(" "));

    // Usa el nombre exacto que usa el servicio (PG lo lowercase automáticamente)
    const paises = await pool.query("SELECT * FROM usp_cfg_country_list(p_active_only => $1)", [1]);
    console.log(`✓ usp_cfg_country_list — ${paises.rows.length} filas:`, paises.rows.map((r: any) => r.country_code));

    const emp = await pool.query('SELECT "LegalName", "FiscalId" FROM cfg."Company" LIMIT 3');
    console.log(`✓ cfg.Company — ${emp.rows.length} filas:`, emp.rows.map((r: any) => r.LegalName));

    console.log("\n✅ PostgreSQL OK — la API puede operar con DB_TYPE=postgres");
  } catch (e: any) {
    console.error("✗ ERROR:", e.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}
main();
