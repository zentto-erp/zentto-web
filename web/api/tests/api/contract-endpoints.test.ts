/**
 * contract-endpoints.test.ts
 *
 * Ejecuta una pasada no destructiva sobre todos los GET documentados en OpenAPI
 * y falla si la API responde 5xx. El objetivo es detectar errores reales de
 * SP/funciones/DB despues de un despliegue.
 *
 * Variables de entorno:
 *   API_BASE_URL      (default: http://localhost:4000)
 *   AUTH_TOKEN        (opcional; si existe, evita el login)
 *   TEST_USER         (default: ADMIN)
 *   TEST_PASSWORD     (requerido si no se pasa AUTH_TOKEN)
 *   TEST_COMPANY_ID   (default: 1)
 *   TEST_BRANCH_ID    (default: 1)
 *
 * Uso:
 *   API_BASE_URL=https://api.zentto.net TEST_PASSWORD=xxx npm run test:contract
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import YAML from 'yaml';
import { beforeAll, describe, expect, it } from 'vitest';

type HttpMethod = 'get' | 'post' | 'put' | 'patch' | 'delete';

type OpenApiOperation = {
  deprecated?: boolean;
  security?: unknown[];
};

type OpenApiPathItem = {
  parameters?: unknown[];
  security?: unknown[];
} & Partial<Record<HttpMethod, OpenApiOperation>>;

type OpenApiDoc = {
  paths?: Record<string, OpenApiPathItem>;
  security?: unknown[];
};

type ContractEndpoint = {
  auth: boolean;
  path: string;
};

const BASE = process.env.API_BASE_URL ?? 'http://localhost:4000';
const GLOBAL_SECURITY_KEYS = new Set(['bearerAuth', 'BearerAuth', 'jwtAuth']);

let session: { token: string; companyId: number; branchId: number } | null = null;

function resolveOpenApiPath(): string {
  const here = path.dirname(fileURLToPath(import.meta.url));
  const candidates = [
    path.resolve(here, '..', '..', '..', 'contracts', 'openapi.yaml'),
    path.resolve(here, '..', '..', 'contracts', 'openapi.yaml'),
  ];

  for (const candidate of candidates) {
    if (fs.existsSync(candidate)) return candidate;
  }

  throw new Error(`No se encontro openapi.yaml. Candidatos: ${candidates.join(', ')}`);
}

function loadOpenApiDoc(): OpenApiDoc {
  const yamlText = fs.readFileSync(resolveOpenApiPath(), 'utf8');
  return (YAML.parse(yamlText) as OpenApiDoc | null) ?? {};
}

function hasAuthRequirement(security: unknown[] | undefined, fallback: unknown[] | undefined): boolean {
  const effective = security ?? fallback;
  if (!effective) return false;
  if (effective.length === 0) return false;

  return effective.some((entry) => {
    if (!entry || typeof entry !== 'object') return false;
    return Object.keys(entry as Record<string, unknown>).some((key) => GLOBAL_SECURITY_KEYS.has(key));
  });
}

function buildPath(template: string): string {
  const preset: Record<string, string> = {
    boxId: '999999',
    cedula: 'V-99999999',
    code: 'XX',
    codCuenta: 'NOEXISTE',
    codigo: 'NOEXISTE',
    companyId: '1',
    countryCode: 'XX',
    employeeCode: 'NOEXISTE',
    employeeId: '999999',
    entityId: '999999',
    entityImageId: '999999',
    entityType: 'product',
    filingId: '999999',
    id: '999999',
    key: 'NOEXISTE',
    loanId: '999999',
    memberId: '999999',
    module: 'pos',
    nroCta: 'NOEXISTE',
    numFact: 'NOEXISTE',
    orderId: '999999',
    pedidoId: '999999',
    table: 'clientes',
    tipoOperacion: 'factura',
    userId: '999999',
    ventaId: '999999',
  };

  return template.replace(/\{([^}]+)\}/g, (_full, rawName: string) => {
    const name = String(rawName);
    if (preset[name]) return preset[name];
    const normalized = name.toLowerCase();
    if (normalized.includes('email')) return 'test@invalid.local';
    if (normalized.includes('code') || normalized.includes('codigo') || normalized.includes('key')) {
      return 'NOEXISTE';
    }
    if (normalized.includes('id') || normalized.includes('num') || normalized.includes('nro')) {
      return '999999';
    }
    return 'NOEXISTE';
  });
}

function getDocumentedGetEndpoints(): ContractEndpoint[] {
  const doc = loadOpenApiDoc();
  const globalSecurity = doc.security;
  const endpoints: ContractEndpoint[] = [];

  for (const [routePath, pathItem] of Object.entries(doc.paths ?? {})) {
    const operation = pathItem.get;
    if (!operation || operation.deprecated) continue;
    if (!routePath.startsWith('/')) continue;

    endpoints.push({
      auth: hasAuthRequirement(operation.security, pathItem.security ?? globalSecurity),
      path: routePath,
    });
  }

  return endpoints.sort((a, b) => a.path.localeCompare(b.path));
}

async function authGet(routePath: string, token?: string): Promise<Response> {
  const headers: Record<string, string> = { Accept: 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  return fetch(`${BASE}${routePath}`, {
    headers,
    signal: AbortSignal.timeout(15_000),
  });
}

const CONTRACT_ENDPOINTS = getDocumentedGetEndpoints();

beforeAll(async () => {
  const existingToken = process.env.AUTH_TOKEN ?? process.env.TEST_AUTH_TOKEN;
  if (existingToken) {
    session = {
      branchId: Number(process.env.TEST_BRANCH_ID ?? 1),
      companyId: Number(process.env.TEST_COMPANY_ID ?? 1),
      token: existingToken,
    };
    console.info(
      `[contract] Session inyectada via AUTH_TOKEN en ${BASE} - company=${session.companyId} branch=${session.branchId}`,
    );
    console.info(`[contract] GETs documentados en OpenAPI: ${CONTRACT_ENDPOINTS.length}`);
    return;
  }

  const pwd = process.env.TEST_PASSWORD;
  if (!pwd) {
    throw new Error('TEST_PASSWORD o AUTH_TOKEN es requerido para ejecutar npm run test:contract');
  }

  const loginRes = await fetch(`${BASE}/v1/auth/login`, {
    body: JSON.stringify({
      branchId: Number(process.env.TEST_BRANCH_ID ?? 1),
      clave: pwd,
      companyId: Number(process.env.TEST_COMPANY_ID ?? 1),
      usuario: process.env.TEST_USER ?? 'ADMIN',
    }),
    headers: { 'Content-Type': 'application/json' },
    method: 'POST',
    signal: AbortSignal.timeout(15_000),
  });

  if (!loginRes.ok) {
    throw new Error(`[contract] Login fallido en ${BASE}/v1/auth/login (${loginRes.status})`);
  }

  const payload = (await loginRes.json()) as {
    company: { branchId: number; companyId: number };
    token: string;
  };

  session = {
    branchId: payload.company.branchId,
    companyId: payload.company.companyId,
    token: payload.token,
  };

  if (!session.token) {
    throw new Error('[contract] Login exitoso pero la respuesta no devolvio token');
  }

  console.info(
    `[contract] Session activa en ${BASE} - company=${session.companyId} branch=${session.branchId}`,
  );
  console.info(`[contract] GETs documentados en OpenAPI: ${CONTRACT_ENDPOINTS.length}`);
}, 20_000);

describe('Contrato OpenAPI - GETs documentados', () => {
  it('OpenAPI expone endpoints GET documentados', () => {
    expect(CONTRACT_ENDPOINTS.length).toBeGreaterThan(0);
  });

  for (const endpoint of CONTRACT_ENDPOINTS) {
    const resolvedPath = buildPath(endpoint.path);

    it(`GET ${endpoint.path} -> no retorna 5xx`, async () => {
      const res = await authGet(resolvedPath, endpoint.auth ? session?.token : undefined);
      expect([500, 502, 503, 504]).not.toContain(res.status);
    });
  }
});
