const { getPool } = require('./dist/db/mssql.js');
async function main() {
  const pool = await getPool();
  const tables = ['ConcNom', 'Empleados', 'EmpleadosNomina', 'EmpleadoSueldo', 'Nomina', 'PagoNomina', 'Tipo_Nomina', 'Utilidad', 'UtilidadesAnuales', 'Vacacion', 'ConstanteNomina', 'DtlNom', 'DtlLiquidacion', 'DtlVacacion', 'Antiguedad', 'Feriados'];
  
  for (const t of tables) {
    try {
      const result = await pool.request().query(`SELECT COUNT(*) as cnt FROM ${t}`);
      console.log(`${t}: ${result.recordset[0].cnt} registros`);
    } catch (e) {
      console.log(`${t}: ERROR - ${e.message}`);
    }
  }
  
  // Ver estructura de ConcNom
  console.log('\n--- ConcNom Structure ---');
  try {
    const cols = await pool.request().query("SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ConcNom' ORDER BY ORDINAL_POSITION");
    console.log(cols.recordset.map(r => `${r.COLUMN_NAME} (${r.DATA_TYPE})`).join('\n'));
  } catch (e) {
    console.log('Error: ' + e.message);
  }
  
  // Ver algunos conceptos
  console.log('\n--- ConcNom Sample ---');
  try {
    const data = await pool.request().query('SELECT TOP 5 * FROM ConcNom');
    console.log(JSON.stringify(data.recordset, null, 2));
  } catch (e) {
    console.log('Error: ' + e.message);
  }
  
  process.exit(0);
}
main().catch(e => { console.error(e); process.exit(1); });
