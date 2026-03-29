import express, { Request, Response, NextFunction } from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import swaggerUi from "swagger-ui-express";
import YAML from "yaml";
import { env } from "./config/env.js";
import { healthRouter } from "./modules/health/routes.js";
import { authRouter } from "./modules/usuarios/auth.routes.js";
import { addonsRouter, loadAddons } from "./modules/addons/routes.js";
import { crudRouter } from "./modules/crud/routes.js";
import { clientesRouter } from "./modules/clientes/routes.js";
import { proveedoresRouter } from "./modules/proveedores/routes.js";
import { inventarioRouter } from "./modules/inventario/routes.js";
import { metaRouter } from "./modules/meta/routes.js";
import { abonosRouter } from "./modules/abonos/routes.js";
import { pagosRouter } from "./modules/pagos/routes.js";
import { cuentasPorPagarRouter } from "./modules/cuentas-por-pagar/routes.js";
import { abonosPagosRouter } from "./modules/abonospagos/routes.js";
import { pagosCRouter } from "./modules/pagosc/routes.js";
import { pCobrarRouter } from "./modules/p-cobrar/routes.js";
import { retencionesRouter } from "./modules/retenciones/routes.js";
import { movInventRouter } from "./modules/movinvent/routes.js";
import { cxcRouter } from "./modules/cxc/routes.js";
import cxpRouter from "./modules/cxp/routes.js";
import { bancosRouter } from "./modules/bancos/routes.js";
import { categoriasRouter } from "./modules/categorias/routes.js";
import { almacenRouter } from "./modules/almacen/routes.js";
import { vendedoresRouter } from "./modules/vendedores/routes.js";
import { empleadosRouter } from "./modules/empleados/routes.js";
import { cuentasRouter } from "./modules/cuentas/routes.js";
import { centroCostoRouter } from "./modules/centro-costo/routes.js";
import { marcasRouter } from "./modules/marcas/routes.js";
import { unidadesRouter } from "./modules/unidades/routes.js";
import { lineasRouter } from "./modules/lineas/routes.js";
import { clasesRouter } from "./modules/clases/routes.js";
import { gruposRouter } from "./modules/grupos/routes.js";
import { tiposRouter } from "./modules/tipos/routes.js";
import { usuariosRouter } from "./modules/usuarios/routes.js";
import { empresaRouter } from "./modules/empresa/routes.js";
import { documentosVentaRouter } from "./modules/documentos-venta/routes.js";
import { documentosCompraRouter } from "./modules/documentos-compra/routes.js";
import { nominaRouter } from "./modules/nomina/routes.js";
import { contabilidadRouter } from "./modules/contabilidad/routes.js";
import { auditoriaRouter } from "./modules/auditoria/routes.js";
import { maestrosRouter } from "./modules/maestros/routes.js";
import { posRouter } from "./modules/pos/routes.js";
import { posEsperaRouter } from "./modules/pos/espera.routes.js";
import { restauranteRouter } from "./modules/restaurante/routes.js";
import { restauranteAdminRouter } from "./modules/restaurante/admin.routes.js";
import { configRouter } from "./modules/config/routes.js";
import { reportesRouter } from "./modules/reportes/routes.js";
import { sistemaRouter } from "./modules/sistema/sistema.routes.js";
import { fiscalRouter } from "./modules/fiscal/routes.js";
import { paymentsRouter } from "./modules/payments/routes.js";
import { settingsRouter } from "./modules/settings/routes.js";
import { mediaRouter } from "./modules/media/routes.js";
import { supervisionRouter } from "./modules/supervision/routes.js";
import { storeRouter } from "./modules/ecommerce/routes.js";
import { landingRouter } from "./modules/landing/routes.js";
import rrhhRouter from "./modules/rrhh/routes.js";
import { flotaRouter } from "./modules/flota/routes.js";
import { permisosRouter } from "./modules/permisos/routes.js";
import { inventarioAvanzadoRouter } from "./modules/inventario-avanzado/routes.js";
import { logisticaRouter } from "./modules/logistica/routes.js";
import { shippingRouter } from "./modules/shipping/routes.js";
import { crmRouter } from "./modules/crm/routes.js";
import { manufacturaRouter } from "./modules/manufactura/routes.js";
import { comprasAnalyticsRouter } from "./modules/compras/analytics.routes.js";
import { ventasAnalyticsRouter } from "./modules/ventas/analytics.routes.js";
import { tenantsRouter } from "./modules/tenants/tenant.routes.js";
import { paddleWebhookRouter } from "./modules/webhooks/paddle.routes.js";
import { githubSupportWebhookRouter } from "./modules/webhooks/github-support.routes.js";
import { billingRouter, billingWebhookHandler } from "./modules/billing/billing.routes.js";
import devicesRouter from "./modules/devices/routes.js";
import zohoRouter from "./modules/integrations/zoho.routes.js";
import { supportRouter } from "./modules/integrations/support.routes.js";
import { analyticsRouter } from "./modules/integrations/analytics.routes.js";
import byocRouter from "./modules/byoc/byoc.routes.js";
import licenseRouter from "./modules/license/license.routes.js";
import backofficeRouter from "./modules/backoffice/backoffice.routes.js";
import backofficeAuthRouter from "./modules/backoffice/backoffice-auth.routes.js";
import { startResourceCleanupJob } from "./jobs/resource-cleanup.job.js";
import { requireJwt } from "./middleware/auth.js";
import {
  localizeResponseDateTimes,
  normalizeRequestDateTimesToUtc,
} from "./middleware/datetime.js";
import { observabilityMiddleware } from "./middleware/observability.js";

function resolveOpenApiPath() {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const candidates = [
    path.resolve(here, "..", "..", "contracts", "openapi.yaml"),
    path.resolve(process.cwd(), "..", "contracts", "openapi.yaml"),
    path.resolve(process.cwd(), "contracts", "openapi.yaml"),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }

  return candidates[0];
}

function loadOpenApiDoc() {
  const openApiPath = resolveOpenApiPath();
  if (!fs.existsSync(openApiPath)) {
    return {};
  }
  const yamlText = fs.readFileSync(openApiPath, "utf8");
  const doc = (YAML.parse(yamlText) as Record<string, unknown>) ?? {};
  const paths = (doc.paths as Record<string, unknown> | undefined) ?? {};
  const legacyPrefixes = [
    "/v1/facturas",
    "/v1/compras",
    "/v1/pedidos",
    "/v1/cotizaciones",
    "/v1/cotizaciones-tx",
    "/v1/ordenes",
    "/v1/presupuestos",
    "/v1/notas"
  ];
  for (const key of Object.keys(paths)) {
    if (legacyPrefixes.some((prefix) => key === prefix || key.startsWith(`${prefix}/`))) {
      delete paths[key];
    }
  }
  doc.paths = paths;
  return doc;
}
export async function createApp() {
  const app = express();
  app.disable("etag");
  app.use(helmet());
  // CORS: origins locales + produccion + subdominios dinamicos de tenants
  const corsWhitelist = new Set([
    'http://localhost:3000', 'http://localhost:3100',
    'http://127.0.0.1:3000', 'http://127.0.0.1:3100',
    ...Array.from({ length: 10 }, (_, i) => `http://localhost:${3001 + i}`),
    ...Array.from({ length: 10 }, (_, i) => `http://127.0.0.1:${3001 + i}`),
  ]);
  if (process.env.CORS_ORIGINS) {
    for (const o of process.env.CORS_ORIGINS.split(',').map(s => s.trim()).filter(Boolean)) {
      corsWhitelist.add(o);
    }
  }
  app.use(cors({
    origin(origin, callback) {
      // Permitir requests sin origin (Postman, curl, server-to-server)
      if (!origin) return callback(null, true);
      // Whitelist explicita
      if (corsWhitelist.has(origin)) return callback(null, true);
      // Cualquier subdominio *.zentto.net (tenants dinamicos)
      if (/^https:\/\/[a-z0-9-]+\.zentto\.net$/.test(origin)) return callback(null, true);
      callback(new Error(`CORS: origin ${origin} no permitido`));
    },
    credentials: true,
  }));
  fs.mkdirSync(env.media.storagePath, { recursive: true });
  app.use(
    "/media-files",
    express.static(env.media.storagePath, {
      fallthrough: true,
      setHeaders(res) {
        res.setHeader("Cache-Control", "public, max-age=31536000, immutable");
        // Allow media embedding from modular frontends running on other localhost ports.
        res.setHeader("Cross-Origin-Resource-Policy", "cross-origin");
        res.setHeader("Access-Control-Allow-Origin", "*");
        res.removeHeader("Content-Security-Policy");
      },
    })
  );
  app.use((_req, res, next) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    next();
  });
  // Webhooks externos — ANTES de express.json() para preservar raw body
  app.use("/api/webhooks", paddleWebhookRouter);
  app.use("/api/webhooks", githubSupportWebhookRouter);
  app.use("/v1/billing/webhook", billingWebhookHandler);

  app.use(express.json({ limit: "2mb" }));
  app.use(morgan("dev"));
  app.use(observabilityMiddleware);

  app.get("/", (_req, res) => {
    res.json({ name: "Zentto ERP API", env: env.nodeEnv, version: "v2" });
  });

  // Basic auth para proteger documentación API
  const docsAuth = (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Basic ")) {
      res.setHeader("WWW-Authenticate", 'Basic realm="Zentto API Docs"');
      return res.status(401).send("Autenticación requerida");
    }
    const decoded = Buffer.from(authHeader.slice(6), "base64").toString();
    const [user, pass] = decoded.split(":");
    const docsUser = process.env.DOCS_USER || "zentto";
    const docsPass = process.env.DOCS_PASS || "docs2026";
    if (user !== docsUser || pass !== docsPass) {
      res.setHeader("WWW-Authenticate", 'Basic realm="Zentto API Docs"');
      return res.status(401).send("Credenciales inválidas");
    }
    next();
  };

  app.get("/openapi.json", docsAuth, (_req, res) => {
    res.json(loadOpenApiDoc());
  });
  app.use("/docs", docsAuth, swaggerUi.serve, (req: Request, res: Response, next: NextFunction) => {
    const handler = swaggerUi.setup(loadOpenApiDoc(), {
      explorer: true,
      customSiteTitle: "Zentto ERP API",
      customCss: ".swagger-ui .topbar { background-color: #1a1a2e; }",
      swaggerOptions: { persistAuthorization: true }
    });
    return handler(req, res, next);
  });

  app.use("/health", healthRouter);

  // Landing page — público (sin JWT)
  app.use("/api/landing", landingRouter);

  // Ecommerce storefront — público (sin JWT)
  app.use("/store", storeRouter);

  // Shipping portal — público (auth propio del cliente shipping)
  app.use("/shipping", shippingRouter);

  // Tenant provisioning — protegido por master key, sin JWT
  app.use("/api/tenants", tenantsRouter);

  // Licencias — /validate es público (BYOC servers); resto protegido por Master-Key, sin JWT
  app.use("/v1/license", licenseRouter);

  // Backoffice Zentto — protegido por Master-Key, sin JWT
  app.use("/v1/backoffice/auth", backofficeAuthRouter); // sin master-key (es el endpoint de login)
  app.use("/v1/backoffice", backofficeRouter);

  // Paddle client token — público para inicializar checkout en frontend
  app.get("/v1/billing/config", (_req, res) => {
    const clientToken = process.env.PADDLE_CLIENT_TOKEN;
    if (!clientToken) { res.status(500).json({ error: "paddle_not_configured" }); return; }
    res.json({ ok: true, clientToken, environment: "production" });
  });

  // Startup: fix funciones sec si tienen type mismatch (text vs varchar)
  (async () => {
    try {
      const { getPgPool } = await import("./db/pg.js");
      const pool = getPgPool();
      // Test si la función funciona
      await pool.query("SELECT * FROM usp_sec_user_listcompanyaccesses_default() LIMIT 1");
    } catch (err: any) {
      if (err.message?.includes("structure of query does not match")) {
        console.warn("[startup] Fixing sec functions (text vs varchar mismatch)...");
        try {
          const { getPgPool } = await import("./db/pg.js");
          const pool = getPgPool();
          await pool.query(`
            DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses_default() CASCADE;
            DROP FUNCTION IF EXISTS public.usp_sec_user_listcompanyaccesses(character varying) CASCADE;
            DROP FUNCTION IF EXISTS public.usp_sec_user_getcompanyaccesses(character varying) CASCADE;
          `);
          await pool.query(`
            CREATE FUNCTION public.usp_sec_user_listcompanyaccesses_default()
            RETURNS TABLE("companyId" integer, "companyCode" character varying, "companyName" character varying,
              "branchId" integer, "branchCode" character varying, "branchName" character varying,
              "countryCode" character varying, "timeZone" character varying, "isDefault" boolean)
            LANGUAGE plpgsql AS $fn$
            BEGIN
              RETURN QUERY
              SELECT c."CompanyId"::integer, c."CompanyCode"::varchar,
                COALESCE(NULLIF(c."TradeName"::varchar, ''::varchar), c."LegalName"::varchar)::varchar,
                b."BranchId"::integer, b."BranchCode"::varchar, b."BranchName"::varchar,
                UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar))::varchar,
                COALESCE(NULLIF(ct."TimeZoneIana"::varchar, ''::varchar),
                  CASE UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar))
                    WHEN 'VE' THEN 'America/Caracas' WHEN 'ES' THEN 'Europe/Madrid'
                    WHEN 'CO' THEN 'America/Bogota' WHEN 'MX' THEN 'America/Mexico_City' ELSE 'UTC' END)::varchar,
                (c."CompanyCode" = 'DEFAULT' AND b."BranchCode" = 'MAIN')::boolean
              FROM cfg."Company" c
              JOIN cfg."Branch" b ON b."CompanyId" = c."CompanyId"
              LEFT JOIN cfg."Country" ct ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar)) AND ct."IsActive" = TRUE
              WHERE c."IsActive" = TRUE AND c."IsDeleted" = FALSE
              ORDER BY c."CompanyId", b."BranchId";
            END; $fn$;
          `);
          await pool.query(`
            CREATE FUNCTION public.usp_sec_user_listcompanyaccesses(p_cod_usuario character varying)
            RETURNS TABLE("companyId" integer, "companyCode" character varying, "companyName" character varying,
              "branchId" integer, "branchCode" character varying, "branchName" character varying,
              "countryCode" character varying, "timeZone" character varying, "isDefault" boolean)
            LANGUAGE plpgsql AS $fn$
            BEGIN
              RETURN QUERY
              SELECT c."CompanyId"::integer, c."CompanyCode"::varchar,
                COALESCE(NULLIF(c."TradeName"::varchar, ''::varchar), c."LegalName"::varchar)::varchar,
                b."BranchId"::integer, b."BranchCode"::varchar, b."BranchName"::varchar,
                UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar))::varchar,
                COALESCE(NULLIF(ct."TimeZoneIana"::varchar, ''::varchar),
                  CASE UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar))
                    WHEN 'VE' THEN 'America/Caracas' WHEN 'ES' THEN 'Europe/Madrid'
                    WHEN 'CO' THEN 'America/Bogota' WHEN 'MX' THEN 'America/Mexico_City' ELSE 'UTC' END)::varchar,
                COALESCE(uca."IsDefault", FALSE)::boolean
              FROM sec."UserCompanyAccess" uca
              JOIN cfg."Company" c ON c."CompanyId" = uca."CompanyId"
              JOIN cfg."Branch" b ON b."BranchId" = uca."BranchId"
              LEFT JOIN cfg."Country" ct ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar)) AND ct."IsActive" = TRUE
              WHERE uca."CodUsuario" = p_cod_usuario AND uca."IsActive" = TRUE AND c."IsActive" = TRUE AND c."IsDeleted" = FALSE
              ORDER BY CASE WHEN uca."IsDefault" = TRUE THEN 0 ELSE 1 END, c."CompanyId", b."BranchId";
            END; $fn$;
          `);
          await pool.query(`
            CREATE FUNCTION public.usp_sec_user_getcompanyaccesses(p_cod_usuario character varying)
            RETURNS TABLE("companyId" integer, "companyCode" character varying, "companyName" character varying,
              "branchId" integer, "branchCode" character varying, "branchName" character varying,
              "countryCode" character varying, "timeZone" character varying, "isDefault" boolean)
            LANGUAGE plpgsql AS $fn$
            BEGIN
              RETURN QUERY
              SELECT a."CompanyId"::integer, c."CompanyCode"::varchar,
                COALESCE(NULLIF(c."TradeName"::varchar, ''::varchar), c."LegalName"::varchar)::varchar,
                a."BranchId"::integer, b."BranchCode"::varchar, b."BranchName"::varchar,
                UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar))::varchar,
                COALESCE(NULLIF(ct."TimeZoneIana"::varchar, ''::varchar),
                  CASE UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar))
                    WHEN 'VE' THEN 'America/Caracas' WHEN 'ES' THEN 'Europe/Madrid'
                    WHEN 'CO' THEN 'America/Bogota' WHEN 'MX' THEN 'America/Mexico_City' ELSE 'UTC' END)::varchar,
                a."IsDefault"::boolean
              FROM sec."UserCompanyAccess" a
              JOIN cfg."Company" c ON c."CompanyId" = a."CompanyId" AND c."IsActive" = TRUE AND c."IsDeleted" = FALSE
              JOIN cfg."Branch" b ON b."BranchId" = a."BranchId" AND b."CompanyId" = a."CompanyId" AND b."IsActive" = TRUE AND b."IsDeleted" = FALSE
              LEFT JOIN cfg."Country" ct ON ct."CountryCode" = UPPER(COALESCE(NULLIF(b."CountryCode"::varchar, ''::varchar), c."FiscalCountryCode"::varchar)) AND ct."IsActive" = TRUE
              WHERE UPPER(a."CodUsuario") = UPPER(p_cod_usuario) AND a."IsActive" = TRUE
              ORDER BY CASE WHEN a."IsDefault" = TRUE THEN 0 ELSE 1 END, a."CompanyId", a."BranchId";
            EXCEPTION WHEN OTHERS THEN RETURN;
            END; $fn$;
          `);
          console.log("[startup] ✓ Sec functions fixed");
        } catch (fixErr: any) {
          console.error("[startup] Failed to fix sec functions:", fixErr.message);
        }
      }
    }
  })().catch(() => {});

  // JWT required for all /v1 routes
  app.use("/v1", requireJwt);
  app.use("/v1", normalizeRequestDateTimesToUtc);
  app.use("/v1", localizeResponseDateTimes);

  // Audit trail — registra automáticamente POST/PUT/PATCH/DELETE exitosos
  const { auditTrailMiddleware } = await import("./middleware/audit-trail.js");
  app.use("/v1", auditTrailMiddleware);
  app.use("/v1/auth", authRouter);

  // Subscription check — después de auth, antes de rutas de negocio
  // Excluye: /v1/auth, /v1/billing, /v1/config (necesarios para renovar suscripción)
  {
    const { requireSubscription } = await import("./middleware/subscription.js");
    app.use("/v1", (req, res, next) => {
      const path = req.path;
      // Rutas exentas de verificación de suscripción
      if (path.startsWith("/auth") || path.startsWith("/billing") || path.startsWith("/config") || path.startsWith("/settings")) {
        return next();
      }
      return requireSubscription(req, res, next);
    });
  }

  // Documentos Unificados (reemplazan a facturas, pedidos, cotizaciones, presupuestos, notas, compras, ordenes)
  app.use("/v1/documentos-venta", documentosVentaRouter);
  app.use("/v1/documentos-compra", documentosCompraRouter);
  app.use("/v1/compras/analytics", comprasAnalyticsRouter);
  app.use("/v1/ventas/analytics", ventasAnalyticsRouter);

  // Pagos y Cobros
  app.use("/v1/abonos", abonosRouter);
  app.use("/v1/pagos", pagosRouter);
  app.use("/v1/abonospagos", abonosPagosRouter);
  app.use("/v1/pagosc", pagosCRouter);
  app.use("/v1/p-cobrar", pCobrarRouter);
  app.use("/v1/cuentas-por-pagar", cuentasPorPagarRouter);

  // Cuentas por Cobrar/Pagar
  app.use("/v1/cxc", cxcRouter);
  app.use("/v1/cxp", cxpRouter);

  // Configuración y Maestros
  app.use("/v1/retenciones", retencionesRouter);
  app.use("/v1/movinvent", movInventRouter);
  app.use("/v1/bancos", bancosRouter);
  app.use("/v1/categorias", categoriasRouter);
  app.use("/v1/almacen", almacenRouter);
  app.use("/v1/vendedores", vendedoresRouter);
  app.use("/v1/empleados", empleadosRouter);
  app.use("/v1/nomina", nominaRouter);
  app.use("/v1/rrhh", rrhhRouter);
  app.use("/v1/contabilidad", contabilidadRouter);
  app.use("/v1/auditoria", auditoriaRouter);
  app.use("/v1/cuentas", cuentasRouter);
  app.use("/v1/centro-costo", centroCostoRouter);
  app.use("/v1/marcas", marcasRouter);
  app.use("/v1/unidades", unidadesRouter);
  app.use("/v1/lineas", lineasRouter);
  app.use("/v1/clases", clasesRouter);
  app.use("/v1/grupos", gruposRouter);
  app.use("/v1/tipos", tiposRouter);
  app.use("/v1/usuarios", usuariosRouter);
  app.use("/v1/empresa", empresaRouter);
  app.use("/v1/maestros", maestrosRouter);

  // Terceros y Productos
  app.use("/v1/clientes", clientesRouter);
  app.use("/v1/proveedores", proveedoresRouter);
  app.use("/v1/inventario", inventarioRouter);
  app.use("/v1/articulos", inventarioRouter);

  app.use("/v1/addons", addonsRouter);
  app.use("/v1/crud", crudRouter);
  app.use("/v1/meta", metaRouter);

  // POS y Restaurante
  app.use("/v1/pos", posRouter);
  app.use("/v1/pos", posEsperaRouter);
  app.use("/v1/restaurante", restauranteRouter);
  app.use("/v1/restaurante/admin", restauranteAdminRouter);

  // Reportes Crystal Reports (proxy al .NET Report Server)
  app.use("/v1/reportes", reportesRouter);

  // Payment Gateway (multi-country, multi-provider)
  app.use("/v1/payments", paymentsRouter);

  // Configuraciones Globales (BD, Tasas, Licencias)
  app.use("/v1/config", configRouter);
  app.use("/v1/settings", settingsRouter);
  app.use("/v1/media", mediaRouter);
  app.use("/v1/supervision", supervisionRouter);
  app.use("/v1/fiscal", fiscalRouter);
  app.use("/v1/sistema", sistemaRouter); // Added this line
  app.use("/v1/flota", flotaRouter);
  app.use("/v1/permisos", permisosRouter);
  app.use("/v1/inventario-avanzado", inventarioAvanzadoRouter);
  app.use("/v1/logistica", logisticaRouter);
  app.use("/v1/crm", crmRouter);
  app.use("/v1/manufactura", manufacturaRouter);
  app.use("/v1/devices", devicesRouter);
  app.use("/v1/integrations/zoho", zohoRouter);
  app.use("/v1/support", supportRouter);
  app.use("/v1/analytics", analyticsRouter);

  // BYOC — Bring Your Own Cloud
  app.use("/v1/byoc", byocRouter);

  // Billing SaaS (Paddle)
  app.use("/v1/billing", billingRouter);

  app.use("/api/v1/config", configRouter);

  // Duplicate routes under /api/v1 for backward compatibility
  app.use("/api/v1", requireJwt);
  app.use("/api/v1", normalizeRequestDateTimesToUtc);
  app.use("/api/v1", localizeResponseDateTimes);
  app.use("/api/v1/auth", authRouter);
  app.use("/api/v1/documentos-venta", documentosVentaRouter);
  app.use("/api/v1/documentos-compra", documentosCompraRouter);
  app.use("/api/v1/compras/analytics", comprasAnalyticsRouter);
  app.use("/api/v1/ventas/analytics", ventasAnalyticsRouter);
  app.use("/api/v1/abonos", abonosRouter);
  app.use("/api/v1/pagos", pagosRouter);
  app.use("/api/v1/abonospagos", abonosPagosRouter);
  app.use("/api/v1/pagosc", pagosCRouter);
  app.use("/api/v1/p-cobrar", pCobrarRouter);
  app.use("/api/v1/cuentas-por-pagar", cuentasPorPagarRouter);
  app.use("/api/v1/cxc", cxcRouter);
  app.use("/api/v1/cxp", cxpRouter);
  app.use("/api/v1/retenciones", retencionesRouter);
  app.use("/api/v1/movinvent", movInventRouter);
  app.use("/api/v1/bancos", bancosRouter);
  app.use("/api/v1/categorias", categoriasRouter);
  app.use("/api/v1/almacen", almacenRouter);
  app.use("/api/v1/vendedores", vendedoresRouter);
  app.use("/api/v1/empleados", empleadosRouter);
  app.use("/api/v1/nomina", nominaRouter);
  app.use("/api/v1/rrhh", rrhhRouter);
  app.use("/api/v1/contabilidad", contabilidadRouter);
  app.use("/api/v1/auditoria", auditoriaRouter);
  app.use("/api/v1/cuentas", cuentasRouter);
  app.use("/api/v1/centro-costo", centroCostoRouter);
  app.use("/api/v1/marcas", marcasRouter);
  app.use("/api/v1/unidades", unidadesRouter);
  app.use("/api/v1/lineas", lineasRouter);
  app.use("/api/v1/clases", clasesRouter);
  app.use("/api/v1/grupos", gruposRouter);
  app.use("/api/v1/tipos", tiposRouter);
  app.use("/api/v1/usuarios", usuariosRouter);
  app.use("/api/v1/empresa", empresaRouter);
  app.use("/api/v1/maestros", maestrosRouter);
  app.use("/api/v1/clientes", clientesRouter);
  app.use("/api/v1/proveedores", proveedoresRouter);
  app.use("/api/v1/inventario", inventarioRouter);
  app.use("/api/v1/articulos", inventarioRouter);
  app.use("/api/v1/addons", addonsRouter);
  app.use("/api/v1/crud", crudRouter);
  app.use("/api/v1/meta", metaRouter);
  app.use("/api/v1/pos", posRouter);
  app.use("/api/v1/pos", posEsperaRouter);
  app.use("/api/v1/restaurante", restauranteRouter);
  app.use("/api/v1/restaurante/admin", restauranteAdminRouter);
  app.use("/api/v1/reportes", reportesRouter);
  app.use("/api/v1/payments", paymentsRouter);
  app.use("/api/v1/media", mediaRouter);
  app.use("/api/v1/supervision", supervisionRouter);
  app.use("/api/v1/fiscal", fiscalRouter);
  app.use("/api/v1/sistema", sistemaRouter); // Added this line
  app.use("/api/v1/inventario-avanzado", inventarioAvanzadoRouter);
  app.use("/api/v1/logistica", logisticaRouter);
  app.use("/api/v1/crm", crmRouter);
  app.use("/api/v1/manufactura", manufacturaRouter);
  app.use("/api/v1/flota", flotaRouter);

  await loadAddons(app);

  // ── Jobs periódicos — solo en producción/desarrollo, nunca en tests ──
  if (process.env.NODE_ENV !== 'test') {
    startResourceCleanupJob();
  }

  // ── Global error handler — NUNCA retornar 502, siempre JSON ──
  app.use((err: any, _req: any, res: any, _next: any) => {
    console.error("[UNHANDLED]", err?.message || err, err?.stack?.split("\n").slice(0, 3).join("\n"));
    if (!res.headersSent) {
      res.status(500).json({
        error: "internal_server_error",
        message: err?.message || "Error interno del servidor",
        ...(process.env.NODE_ENV !== "production" ? { stack: err?.stack?.split("\n").slice(0, 5) } : {}),
      });
    }
  });

  // Catch unhandled promise rejections para que no crasheen el proceso
  process.on("unhandledRejection", (reason: any) => {
    console.error("[UNHANDLED REJECTION]", reason?.message || reason);
  });

  return app;
}
