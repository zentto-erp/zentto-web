/**
 * ssh.provider.ts — Valida conectividad SSH a un VPS propio
 * Para clientes BYOC con servidor existente (no cloud)
 */
import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

export async function validateSshDirect(
  host: string,
  port: number,
  username: string,
  privateKey: string
): Promise<{ serverIp: string }> {
  // Escribir clave privada a archivo temporal
  const tmpDir = os.tmpdir();
  const keyFile = path.join(tmpDir, `byoc_key_${Date.now()}.pem`);

  try {
    fs.writeFileSync(keyFile, privateKey, { mode: 0o600 });

    // Verificar conectividad SSH ejecutando un comando simple
    const result = execSync(
      `ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes -i "${keyFile}" -p ${port} ${username}@${host} "echo OK"`,
      { timeout: 20_000, encoding: "utf8" }
    ).trim();

    if (result !== "OK") {
      throw new Error(`[ssh] Respuesta inesperada del servidor: ${result}`);
    }

    console.log(`[ssh] Conectividad SSH validada: ${username}@${host}:${port}`);
    return { serverIp: host };
  } finally {
    // Limpiar clave temporal siempre
    try {
      fs.unlinkSync(keyFile);
    } catch {
      // ignorar error de limpieza
    }
  }
}
