/**
 * `createRevalidateHandler` — factory para el route handler
 * `/api/revalidate/route.ts` que cada vertical expone para invalidar el cache
 * SSG/ISR cuando el CMS publica un nuevo schema.
 *
 * Reemplaza la duplicación de ~60 LOC idénticos en los 7 repos verticales
 * (hotel lo tenía implementado ad hoc antes del rollout CMS Dogfooding).
 *
 * Uso en un vertical (hotel/medical/tickets/…):
 *
 * ```ts
 * // zentto-{vertical}/frontend/src/app/api/revalidate/route.ts
 * import { createRevalidateHandler } from "@zentto/landing-kit/renderer";
 *
 * export const POST = createRevalidateHandler({
 *   secret: process.env.LANDING_REVALIDATE_SECRET,
 *   vertical: "hotel",
 *   // opcional: paths estáticos a revalidar además de los tags
 *   paths: ["/para-hoteles", "/"],
 * });
 * ```
 *
 * Invocado por el backend CMS tras publicar landing/page/post. El body
 * es `{ tag: "landing:hotel" }` o `{ path: "/acerca" }`; el header
 * `x-revalidate-token` debe matchear `secret`.
 *
 * Next 16 requiere llamar a AMBOS `revalidateTag` y `revalidatePath` porque
 * `revalidateTag` solo invalida el fetch-cache y NO regenera el HTML
 * pre-rendered (gotcha documentado en
 * `memoria/project_landing_schemas_cms.md`).
 *
 * Sin dependencias externas — solo `next/cache`. No impone observability ni
 * logging; el caller puede envolver si necesita métricas.
 */

import { revalidateTag, revalidatePath } from "next/cache";

export interface CreateRevalidateHandlerOptions {
  /**
   * Token secreto compartido entre API core y este handler. Validado contra
   * el header `x-revalidate-token` o la query `?token=`.
   *
   * En el env, vive como `LANDING_REVALIDATE_SECRET` (sin `NEXT_PUBLIC_`,
   * server-only para no inlinearse al build).
   */
  secret: string | undefined;

  /**
   * Vertical propio del repo (hotel, medical, tickets, …). Se usa si el
   * body no trae tag explícito — default: `landing:${vertical}`.
   */
  vertical: string;

  /**
   * Paths estáticos a revalidar siempre, además de los tags/paths del body.
   * Útil cuando el vertical tiene páginas SSG que dependen del mismo tag pero
   * viven en rutas múltiples. Ejemplo: `["/para-hoteles", "/", "/acerca"]`.
   */
  paths?: string[];

  /**
   * Tags adicionales a invalidar siempre (además del del body). Raro — la
   * mayoría de los verticales solo necesita el tag por defecto.
   */
  tags?: string[];
}

export interface RevalidateRequestBody {
  tag?: string;
  path?: string;
  /** Reservado para invalidaciones masivas. Ignorado hoy. */
  type?: "landing" | "page" | "post";
}

interface RevalidateResponseOk {
  ok: true;
  revalidated: {
    tags: string[];
    paths: string[];
  };
}

interface RevalidateResponseError {
  ok: false;
  error: string;
}

/**
 * Devuelve un `POST` Route Handler compatible con Next 13+ App Router.
 *
 * El tipo de retorno usa `Request`/`Response` web-nativo (no dependencias de
 * tipos internos de Next) — funciona en Node runtime y Edge runtime.
 */
export function createRevalidateHandler(
  opts: CreateRevalidateHandlerOptions,
): (req: Request) => Promise<Response> {
  const { secret, vertical, paths = [], tags = [] } = opts;

  return async function revalidateHandler(req: Request): Promise<Response> {
    if (!secret) {
      return jsonResponse<RevalidateResponseError>(
        500,
        { ok: false, error: "revalidate_secret_not_configured" },
      );
    }

    const headerToken = req.headers.get("x-revalidate-token");
    let providedToken = headerToken;
    if (!providedToken) {
      try {
        const url = new URL(req.url);
        providedToken = url.searchParams.get("token");
      } catch {
        // ignorar — seguirá comparando con null → 401.
      }
    }

    if (providedToken !== secret) {
      return jsonResponse<RevalidateResponseError>(
        401,
        { ok: false, error: "invalid_token" },
      );
    }

    let body: RevalidateRequestBody = {};
    try {
      body = (await req.json()) as RevalidateRequestBody;
    } catch {
      // Body vacío es OK — revalida con defaults.
    }

    const tagsToInvalidate = new Set<string>();
    tagsToInvalidate.add(body.tag ?? `landing:${vertical}`);
    for (const t of tags) tagsToInvalidate.add(t);

    const pathsToInvalidate = new Set<string>(paths);
    if (body.path && typeof body.path === "string") {
      pathsToInvalidate.add(body.path);
    }

    // Next 16: hay que llamar a revalidateTag Y revalidatePath para que el
    // HTML SSG se regenere. Ver project_landing_schemas_cms.md bug #7.
    // Cast a variadic para compat Next 15 (1 arg) y Next 16 (2 args: profile).
    const revalidateTagCompat = revalidateTag as unknown as (
      tag: string,
      ...rest: unknown[]
    ) => void;
    for (const tag of tagsToInvalidate) {
      try {
        revalidateTagCompat(tag);
      } catch {
        // Invalidaciones son fire-and-forget; no bloqueamos la respuesta.
      }
    }
    for (const p of pathsToInvalidate) {
      try {
        revalidatePath(p);
      } catch {
        // idem — next/cache tira si el path no existe; no lo propagamos.
      }
    }

    return jsonResponse<RevalidateResponseOk>(200, {
      ok: true,
      revalidated: {
        tags: Array.from(tagsToInvalidate),
        paths: Array.from(pathsToInvalidate),
      },
    });
  };
}

function jsonResponse<T>(status: number, payload: T): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
