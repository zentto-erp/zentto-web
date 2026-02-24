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
import { maestrosRouter } from "./modules/maestros/routes.js";
import { posRouter } from "./modules/pos/routes.js";
import { posEsperaRouter } from "./modules/pos/espera.routes.js";
import { restauranteRouter } from "./modules/restaurante/routes.js";
import { restauranteAdminRouter } from "./modules/restaurante/admin.routes.js";
import { configRouter } from "./modules/config/routes.js";
import { requireJwt } from "./middleware/auth.js";

function resolveOpenApiPath() {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const candidates = [
    path.resolve(here, "..", "..", "contracts", "openapi.yaml"),
    path.resolve(process.cwd(), "..", "contracts", "openapi.yaml")
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
  app.use(cors({
    origin: [
      'http://localhost:3000',
      'http://localhost:3100',
      'http://127.0.0.1:3000',
      'http://127.0.0.1:3100',
      'http://localhost:3001',
      'http://localhost:3002',
      'http://localhost:3003',
      'http://localhost:3004',
      'http://localhost:3005',
      'http://localhost:3006',
      'http://localhost:3007',
      'http://localhost:3008',
      'http://localhost:3009',
      'http://localhost:3010',
      'http://127.0.0.1:3001',
      'http://127.0.0.1:3002',
      'http://127.0.0.1:3003',
      'http://127.0.0.1:3004',
      'http://127.0.0.1:3005',
      'http://127.0.0.1:3006',
      'http://127.0.0.1:3007',
      'http://127.0.0.1:3008',
      'http://127.0.0.1:3009',
      'http://127.0.0.1:3010',
    ],
    credentials: true,
  }));
  app.use((_req, res, next) => {
    res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate, proxy-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    next();
  });
  app.use(express.json({ limit: "2mb" }));
  app.use(morgan("dev"));

  app.get("/", (_req, res) => {
    res.json({ name: "DatqBox API", env: env.nodeEnv, version: "v1" });
  });

  app.get("/openapi.json", (_req, res) => {
    res.json(loadOpenApiDoc());
  });
  app.use("/docs", swaggerUi.serve, (req: Request, res: Response, next: NextFunction) => {
    const handler = swaggerUi.setup(loadOpenApiDoc(), {
      explorer: true,
      swaggerOptions: { persistAuthorization: true }
    });
    return handler(req, res, next);
  });

  app.use("/health", healthRouter);

  // JWT required for all /v1 routes
  app.use("/v1", requireJwt);
  app.use("/v1/auth", authRouter);

  // Documentos Unificados (reemplazan a facturas, pedidos, cotizaciones, presupuestos, notas, compras, ordenes)
  app.use("/v1/documentos-venta", documentosVentaRouter);
  app.use("/v1/documentos-compra", documentosCompraRouter);

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
  app.use("/v1/contabilidad", contabilidadRouter);
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

  // Configuraciones Globales (BD, Tasas, Licencias)
  app.use("/v1/config", configRouter);
  app.use("/api/v1/config", configRouter);

  // Duplicate routes under /api/v1 for backward compatibility
  app.use("/api/v1", requireJwt);
  app.use("/api/v1/auth", authRouter);
  app.use("/api/v1/documentos-venta", documentosVentaRouter);
  app.use("/api/v1/documentos-compra", documentosCompraRouter);
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
  app.use("/api/v1/contabilidad", contabilidadRouter);
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

  await loadAddons(app);

  return app;
}
