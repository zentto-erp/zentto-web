/**
 * Crea usuario SUP de prueba en PostgreSQL.
 * El SP usp_sec_user_authenticate lee PasswordHash directamente de sec.User.
 */
import bcrypt from "bcrypt";
import { Pool } from "pg";

async function main() {
  const pool = new Pool({
    host: "localhost", port: 5432,
    database: "datqboxweb", user: "postgres", password: "1234",
  });

  const hash = await bcrypt.hash("SUP", 10);
  console.log("hash:", hash.substring(0, 20) + "...");

  // Insertar/actualizar usuario SUP en sec.User
  await pool.query(`
    INSERT INTO sec."User"
      ("UserCode","UserName","PasswordHash","Email","IsAdmin","IsActive",
       "CanUpdate","CanCreate","CanDelete","CanChangePwd","CanChangePrice","CanGiveCredit",
       "UserType","IsDeleted","CreatedAt","UpdatedAt")
    VALUES
      ('SUP','Supervisor',$1,'sup@datqbox.local',true,true,
       true,true,true,true,true,true,
       'ADMIN',false,NOW(),NOW())
    ON CONFLICT ("UserCode") DO UPDATE
      SET "PasswordHash"=$1, "IsActive"=true, "IsDeleted"=false, "UpdatedAt"=NOW()
  `, [hash]);
  console.log("sec.User SUP: OK");

  // Verificar que el authenticate SP lo encuentra
  const res = await pool.query(
    `SELECT * FROM usp_sec_user_authenticate($1)`, ["SUP"]
  );
  if (res.rows.length > 0) {
    const r = res.rows[0] as any;
    console.log("SP auth check → Cod_Usuario:", r.Cod_Usuario, "| tiene hash:", r.Password?.substring(0, 7) === "$2b$10$" ? "SI (bcrypt)" : "NO");
  } else {
    console.log("SP auth check: NO encontró el usuario");
  }

  console.log("\n✅ Usuario SUP listo. Login: usuario=SUP, clave=SUP");
  await pool.end();
}
main().catch(console.error);
