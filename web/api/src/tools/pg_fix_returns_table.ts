/**
 * pg_fix_returns_table.ts  (v2)
 *
 * Problema raíz en PostgreSQL 18:
 *   - RETURNS TABLE("col" character varying)  +  SELECT que devuelve `text`
 *     (COALESCE/NULLIF/UPPER) → ERROR "type mismatch"
 *   - No se puede cambiar return type con CREATE OR REPLACE; hay que DROP + CREATE.
 *
 * Solución elegida:
 *   1. Mantener RETURNS TABLE con los tipos originales (character varying, etc.)
 *   2. Corregir los cuerpos SELECT:
 *      a) NULLIF(col, '')  →  NULLIF(col, ''::character varying)
 *         → NULLIF devuelve character varying → COALESCE(varchar, varchar) = varchar ✓
 *      b) UPPER(...)  →  UPPER(...)::character varying
 *         → UPPER siempre devuelve text en PG; castear explícito ✓
 *
 * Esta versión NO modifica RETURNS TABLE, sólo los cuerpos.
 *
 * Uso:  DB_TYPE=postgres npx tsx src/tools/pg_fix_returns_table.ts
 */

import { Pool } from "pg";

const pool = new Pool({
  host: "localhost",
  port: 5432,
  database: "datqboxweb",
  user: "postgres",
  password: "1234",
});

// ── Helpers de transformación ─────────────────────────────────────────────────

/**
 * Reemplaza `NULLIF(expr, '')` → `NULLIF(expr, ''::character varying)`
 * para que el resultado sea character varying en vez de text.
 */
function fixNullif(body: string): string {
  // Reemplaza '', (o  '',  con espacios) cuando es 2do arg de NULLIF
  // NULLIF( <expr> , '' )  →  NULLIF( <expr> , ''::character varying )
  return body.replace(/\bNULLIF\s*\(([^)]+?),\s*''\s*\)/g, (match, expr) => {
    // Si ya tiene ::character varying o ::varchar, no tocar
    if (match.includes("::character varying") || match.includes("::varchar")) return match;
    return `NULLIF(${expr}, ''::character varying)`;
  });
}

/**
 * Busca el cierre de la expresión UPPER(...) o COALESCE(...) con parens balanceados.
 * Devuelve el índice del ')' de cierre (ya incluido) o -1 si no encontrado.
 */
function findClosingParen(s: string, openAt: number): number {
  let depth = 0;
  for (let i = openAt; i < s.length; i++) {
    if (s[i] === "(") depth++;
    else if (s[i] === ")") {
      depth--;
      if (depth === 0) return i;
    }
  }
  return -1;
}

/**
 * Agrega `::character varying` después de cada llamada a la función dada (UPPER, COALESCE)
 * que NO tenga ya un cast de tipo.
 * Para COALESCE solo lo hace si el cuerpo interior contiene NULLIF (señal de columna de texto).
 */
function fixFunctionCall(body: string, funcName: string): string {
  let result = "";
  let i = 0;
  const pattern = new RegExp(`\\b${funcName}\\s*\\(`, "i");
  while (i < body.length) {
    const match = body.slice(i).match(pattern);
    if (!match || match.index == null) {
      result += body.slice(i);
      break;
    }
    const relIdx = match.index;
    const beforeFunc = body.slice(i, i + relIdx);
    result += beforeFunc;
    const openAt = i + relIdx + match[0].length - 1;
    const closeAt = findClosingParen(body, openAt);
    if (closeAt === -1) {
      result += body.slice(i + relIdx);
      break;
    }
    const innerContent = body.slice(openAt + 1, closeAt); // contenido dentro de los parens
    const fullExpr = body.slice(i + relIdx, closeAt + 1);
    result += fullExpr;
    // Para COALESCE: solo agregar cast si contiene NULLIF (es columna de texto)
    const shouldCast =
      funcName.toUpperCase() !== "COALESCE" ||
      innerContent.toUpperCase().includes("NULLIF");
    if (shouldCast) {
      const after = body.slice(closeAt + 1).trimStart();
      if (!after.startsWith("::character varying") && !after.startsWith("::varchar") && !after.startsWith("::text")) {
        result += "::character varying";
      }
    }
    i = closeAt + 1;
  }
  return result;
}

/**
 * Agrega `::character varying` después de cada UPPER(...)
 * que NO tenga ya un cast de tipo.
 */
function fixUpper(body: string): string {
  return fixFunctionCall(body, "UPPER");
}

/**
 * Agrega `::character varying` después de COALESCE(...) que contienen NULLIF.
 * COALESCE(varchar(n), varchar(m)) → text en PG cuando los lengths difieren.
 */
function fixCoalesceWithNullif(body: string): string {
  return fixFunctionCall(body, "COALESCE");
}

/**
 * Revierte cualquier "text" que nuestro script anterior puso en RETURNS TABLE.
 * Recupera el tipo original "character varying" (sin longitud).
 */
function revertReturnsTableTextToVarchar(def: string): string {
  // Solo reemplaza dentro de la sección RETURNS TABLE(...)
  return def.replace(
    /(RETURNS\s+TABLE\s*\()([^)]+)(\))/i,
    (_, open, cols, close) => {
      // Reemplaza `text` (sólo palabras completas, no parte de 'timestamp' etc.)
      // No reemplazar 'text' si está dentro de comillas dobles (nombre de columna)
      const fixedCols = cols.replace(/(?<!")\btext\b(?!")/gi, "character varying");
      return `${open}${fixedCols}${close}`;
    }
  );
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const client = await pool.connect();
  try {
    // Obtener todas las funciones del schema public que tengan COALESCE/NULLIF o UPPER en el body
    const { rows: funcs } = await client.query<{
      proname: string;
      oid: number;
      def: string;
    }>(`
      SELECT p.proname, p.oid, pg_get_functiondef(p.oid) AS def
      FROM pg_proc p
      WHERE p.pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
        AND p.prokind = 'f'
        AND (
          p.prosrc LIKE '%NULLIF%'
          OR p.prosrc LIKE '%UPPER(%'
          -- también las que tienen text en RETURNS TABLE (nuestro script previo las tocó)
          OR pg_get_functiondef(p.oid) LIKE '%RETURNS TABLE%text%'
        )
      ORDER BY p.proname
    `);

    console.log(`Funciones a revisar: ${funcs.length}`);

    let fixed = 0;
    let skipped = 0;
    let errors = 0;

    for (const fn of funcs) {
      let modified = fn.def;

      // 1. Revertir cualquier 'text' que pusimos en RETURNS TABLE → 'character varying'
      modified = revertReturnsTableTextToVarchar(modified);

      // 2. Corregir NULLIF(expr, '') → NULLIF(expr, ''::character varying)
      modified = fixNullif(modified);

      // 3. Corregir UPPER(...) → UPPER(...)::character varying
      modified = fixUpper(modified);

      // 4. Corregir COALESCE(NULLIF(...), ...) → COALESCE(...)::character varying
      //    (COALESCE con varchar de distintas longitudes devuelve text en PG)
      modified = fixCoalesceWithNullif(modified);

      if (modified === fn.def) {
        skipped++;
        continue;
      }

      // DROP + CREATE para permitir cambio de firma/body
      try {
        const { rows: sigRows } = await client.query<{ sig: string }>(
          `SELECT pg_get_function_identity_arguments($1) AS sig`,
          [fn.oid]
        );
        const sig = sigRows[0]?.sig ?? "";
        await client.query(
          `DROP FUNCTION IF EXISTS public."${fn.proname}"(${sig})`
        );
        await client.query(modified);
        console.log(`  ✅ ${fn.proname}`);
        fixed++;
      } catch (err: any) {
        console.error(`  ❌ ${fn.proname}: ${err.message}`);
        errors++;
        // Intentar restaurar el original si DROP ya se ejecutó
        try {
          await client.query(fn.def);
        } catch (_) { /* ignorar */ }
      }
    }

    console.log(`\nResultado: ${fixed} corregidas, ${skipped} sin cambios, ${errors} errores.`);
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((err) => {
  console.error("Error fatal:", err);
  process.exit(1);
});
