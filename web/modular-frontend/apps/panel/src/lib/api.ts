const API_BASE = process.env.NEXT_PUBLIC_SITES_API || 'http://localhost:4100';

async function fetchAPI<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(err.message || 'API error');
  }
  return res.json();
}

// Sites
export const sitesApi = {
  list: () => fetchAPI<any>('/v1/sites'),
  get: (id: string) => fetchAPI<any>(`/v1/sites/${id}`),
  create: (data: any) => fetchAPI<any>('/v1/sites', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: any) => fetchAPI<any>(`/v1/sites/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (id: string) => fetchAPI<any>(`/v1/sites/${id}`, { method: 'DELETE' }),
  publish: (id: string) => fetchAPI<any>(`/v1/sites/${id}/publish`, { method: 'POST' }),
  unpublish: (id: string) => fetchAPI<any>(`/v1/sites/${id}/unpublish`, { method: 'POST' }),
};

// Pages
export const pagesApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/pages`),
  create: (siteId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/pages`, { method: 'POST', body: JSON.stringify(data) }),
  update: (siteId: string, pageId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/pages/${pageId}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (siteId: string, pageId: string) => fetchAPI<any>(`/v1/sites/${siteId}/pages/${pageId}`, { method: 'DELETE' }),
};

// Media
export const mediaApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/media`),
  upload: async (siteId: string, file: File) => {
    const form = new FormData();
    form.append('file', file);
    const res = await fetch(`${API_BASE}/v1/sites/${siteId}/media`, { method: 'POST', body: form });
    return res.json();
  },
  delete: (siteId: string, mediaId: string) => fetchAPI<any>(`/v1/sites/${siteId}/media/${mediaId}`, { method: 'DELETE' }),
};

// Forms
export const formsApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/submissions`),
};

// Domains
export const domainsApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/domains`),
  add: (siteId: string, domain: string) => fetchAPI<any>(`/v1/sites/${siteId}/domains`, { method: 'POST', body: JSON.stringify({ domain }) }),
  remove: (siteId: string, domainId: string) => fetchAPI<any>(`/v1/sites/${siteId}/domains/${domainId}`, { method: 'DELETE' }),
};

// Revisions
export const revisionsApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/revisions`),
  restore: (siteId: string, revisionId: string) => fetchAPI<any>(`/v1/sites/${siteId}/revisions/${revisionId}/restore`, { method: 'POST' }),
};
