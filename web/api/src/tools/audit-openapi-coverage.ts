import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';

type OpenApiDoc = {
  paths?: Record<string, unknown>;
};

const LEGACY_OPENAPI_PREFIXES = [
  '/v1/facturas',
  '/v1/compras',
  '/v1/pedidos',
  '/v1/cotizaciones',
  '/v1/cotizaciones-tx',
  '/v1/ordenes',
  '/v1/presupuestos',
  '/v1/notas',
];

const IGNORED_ROUTE_PREFIXES = new Set([
  '/',
  '/docs',
  '/openapi.json',
  '/api/landing',
  '/api/tenants',
  '/api/webhooks',
  '/store',
  '/shipping',
  '/api/v1',
  '/health',
  '/v1',
]);

const PENDING_CONTRACT_PREFIXES = new Set([
  '/v1/almacen',
  '/v1/analytics',
  '/v1/backoffice',
  '/v1/backoffice/auth',
  '/v1/backoffice/catalog',
  '/v1/billing',
  '/v1/billing/config',
  '/v1/billing/webhook',
  '/v1/brand',
  '/v1/byoc',
  '/v1/catalog',
  '/v1/categorias',
  '/v1/clases',
  '/v1/compras/analytics',
  '/v1/config/activity-codes',
  '/v1/crm',
  '/v1/cuentas',
  '/v1/devices',
  '/v1/fiscal/declaration-templates',
  '/v1/fiscal/generators',
  '/v1/fiscal/islr-tariff',
  '/v1/fiscal/tax-rates',
  '/v1/flota',
  '/v1/grupos',
  '/v1/iam',
  '/v1/integrations/zoho',
  '/v1/inventario-avanzado',
  '/v1/license',
  '/v1/lineas',
  '/v1/logistica',
  '/v1/maestros',
  '/v1/manufactura',
  '/v1/marcas',
  '/v1/nomina/concept-templates',
  '/v1/partners',
  '/v1/permisos',
  '/v1/pos',
  '/v1/pricing',
  '/v1/registro',
  '/v1/reportes',
  '/v1/roles',
  '/v1/restaurante',
  '/v1/restaurante/admin',
  '/v1/social-security',
  '/v1/status',
  '/v1/subscriptions',
  '/v1/studio',
  '/v1/support',
  '/v1/tipos',
  '/v1/validators',
  '/v1/ventas/analytics',
  '/v1/webhooks-mgmt',
]);

function resolvePath(...segments: string[]): string {
  const here = path.dirname(fileURLToPath(import.meta.url));
  return path.resolve(here, ...segments);
}

function resolveOpenApiPath(): string {
  const candidates = [
    resolvePath('..', '..', '..', 'contracts', 'openapi.yaml'),
    resolvePath('..', '..', 'contracts', 'openapi.yaml'),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }

  throw new Error(`No se encontro openapi.yaml. Candidatos: ${candidates.join(', ')}`);
}

function loadOpenApiPaths(): string[] {
  const yamlText = fs.readFileSync(resolveOpenApiPath(), 'utf8');
  const doc = (YAML.parse(yamlText) as OpenApiDoc | null) ?? {};
  const paths = Object.keys(doc.paths ?? {});

  return paths
    .filter((routePath) => !LEGACY_OPENAPI_PREFIXES.some((prefix) => routePath === prefix || routePath.startsWith(`${prefix}/`)))
    .sort();
}

function loadMountedPrefixes(): string[] {
  const appPath = resolvePath('..', 'app.ts');
  const source = fs.readFileSync(appPath, 'utf8');
  const matches = [...source.matchAll(/app\.(?:use|get|post|put|delete|patch)\("([^"]+)"/g)];
  return [...new Set(matches.map((match) => match[1]).filter(Boolean))].sort();
}

function covers(mountPrefix: string, contractPath: string): boolean {
  return contractPath === mountPrefix || contractPath.startsWith(`${mountPrefix}/`);
}

function assertAllowlistsAreInSync(mountedPrefixes: string[]) {
  const mountedSet = new Set(mountedPrefixes);
  const staleIgnored = [...IGNORED_ROUTE_PREFIXES].filter((prefix) => !mountedSet.has(prefix));
  const stalePending = [...PENDING_CONTRACT_PREFIXES].filter((prefix) => !mountedSet.has(prefix));

  if (staleIgnored.length || stalePending.length) {
    const issues = [
      ...staleIgnored.map((prefix) => `IGNORED_ROUTE_PREFIXES sin uso: ${prefix}`),
      ...stalePending.map((prefix) => `PENDING_CONTRACT_PREFIXES sin uso: ${prefix}`),
    ];
    throw new Error(`Allowlists desalineados:\n- ${issues.join('\n- ')}`);
  }
}

function main() {
  const mountedPrefixes = loadMountedPrefixes();
  const openApiPaths = loadOpenApiPaths();

  assertAllowlistsAreInSync(mountedPrefixes);

  const unexpectedMissingPrefixes = mountedPrefixes.filter((prefix) => {
    if (IGNORED_ROUTE_PREFIXES.has(prefix)) return false;
    if (prefix.startsWith('/api/v1/')) return false;
    if (PENDING_CONTRACT_PREFIXES.has(prefix)) return false;
    if (!prefix.startsWith('/v1/') && !prefix.startsWith('/health')) return false;
    return !openApiPaths.some((contractPath) => covers(prefix, contractPath));
  });

  const orphanedContractPaths = openApiPaths.filter((contractPath) => {
    if (LEGACY_OPENAPI_PREFIXES.some((prefix) => contractPath === prefix || contractPath.startsWith(`${prefix}/`))) {
      return false;
    }
    return !mountedPrefixes.some((prefix) => {
      if (prefix.startsWith('/api/v1/')) return false;
      return covers(prefix, contractPath);
    });
  });

  console.info(`[audit-openapi] rutas montadas: ${mountedPrefixes.length}`);
  console.info(`[audit-openapi] paths OpenAPI normalizados: ${openApiPaths.length}`);
  console.info(`[audit-openapi] prefijos pendientes de documentar: ${PENDING_CONTRACT_PREFIXES.size}`);

  if (PENDING_CONTRACT_PREFIXES.size) {
    console.info('[audit-openapi] pendientes actuales:');
    for (const prefix of [...PENDING_CONTRACT_PREFIXES].sort()) {
      console.info(`  - ${prefix}`);
    }
  }

  if (unexpectedMissingPrefixes.length || orphanedContractPaths.length) {
    const details: string[] = [];

    if (unexpectedMissingPrefixes.length) {
      details.push(
        `Prefijos montados sin contrato ni allowlist:\n- ${unexpectedMissingPrefixes.join('\n- ')}`,
      );
    }

    if (orphanedContractPaths.length) {
      details.push(
        `Paths OpenAPI sin montaje aparente en app.ts:\n- ${orphanedContractPaths.join('\n- ')}`,
      );
    }

    throw new Error(details.join('\n\n'));
  }

  console.info('[audit-openapi] OK - no hay drift inesperado entre app.ts y OpenAPI.');
}

main();
