'use client';

import {
  default as CatalogoCrudBase,
  CatalogField,
  CatalogoCrudApiClient,
} from '@datqbox/module-admin/components/modules/inventario/CatalogoCrudBase';
import { apiDelete, apiGet, apiPost, apiPut } from '@/lib/api';

interface CatalogoCrudPageProps {
  endpoint: string;
  title: string;
  fields?: CatalogField[];
  tableName?: string;
  schema?: string;
}

const apiClient: CatalogoCrudApiClient = {
  list: async (endpoint, params) => {
    const query = new URLSearchParams({
      page: String(params.page),
      limit: String(params.limit),
    });
    if (params.search?.trim()) {
      query.set('search', params.search.trim());
    }
    return apiGet(`/api/v1/${endpoint}?${query.toString()}`);
  },
  create: (endpoint, payload) => apiPost(`/api/v1/${endpoint}`, payload),
  update: (endpoint, key, payload) => apiPut(`/api/v1/${endpoint}/${encodeURIComponent(String(key))}`, payload),
  remove: (endpoint, key) => apiDelete(`/api/v1/${endpoint}/${encodeURIComponent(String(key))}`),
  describe: async (table, schema) => {
    const query = new URLSearchParams({ schema: schema || 'dbo' });
    try {
      return apiGet(`/api/v1/crud/${encodeURIComponent(table)}/describe?${query.toString()}`);
    } catch {
      return null;
    }
  },
};

export default function CatalogoCrudPage({ endpoint, title, fields, tableName, schema }: CatalogoCrudPageProps) {
  return (
    <CatalogoCrudBase
      endpoint={endpoint}
      title={title}
      fields={fields}
      tableName={tableName}
      schema={schema}
      apiClient={apiClient}
    />
  );
}
