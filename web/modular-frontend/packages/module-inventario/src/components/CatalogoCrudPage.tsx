'use client';

import { apiDelete, apiGet, apiPost, apiPut } from '@datqbox/shared-api';
import CatalogoCrudBase, { CatalogField, CatalogoCrudApiClient } from './CatalogoCrudBase';

interface CatalogoCrudPageProps {
  endpoint: string;
  title: string;
  fields?: CatalogField[];
  tableName?: string;
  schema?: string;
}

const apiClient: CatalogoCrudApiClient = {
  list: (endpoint, params) => apiGet(`/api/v1/${endpoint}`, params),
  create: (endpoint, payload) => apiPost(`/api/v1/${endpoint}`, payload),
  update: (endpoint, key, payload) => apiPut(`/api/v1/${endpoint}/${encodeURIComponent(String(key))}`, payload),
  remove: (endpoint, key) => apiDelete(`/api/v1/${endpoint}/${encodeURIComponent(String(key))}`),
  describe: async (table, schema) => {
    try {
      return await apiGet(`/api/v1/crud/${encodeURIComponent(table)}/describe`, {
        schema: schema || 'dbo',
      });
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
