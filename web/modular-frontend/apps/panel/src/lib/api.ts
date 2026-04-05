import { getToken, logout } from './auth';

const API_BASE = process.env.NEXT_PUBLIC_SITES_API || 'http://localhost:4500';

async function fetchAPI<T>(path: string, options?: RequestInit): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      ...options?.headers,
    },
  });
  if (res.status === 401) {
    logout();
    throw new Error('Session expired');
  }
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

// Posts
export const postsApi = {
  list: (siteId: string, params?: { status?: string; categoryId?: string; search?: string; limit?: number; offset?: number }) => {
    const qs = new URLSearchParams();
    if (params?.status) qs.set('status', params.status);
    if (params?.categoryId) qs.set('categoryId', params.categoryId);
    if (params?.search) qs.set('search', params.search);
    if (params?.limit) qs.set('limit', String(params.limit));
    if (params?.offset) qs.set('offset', String(params.offset));
    return fetchAPI<any>(`/v1/sites/${siteId}/posts?${qs}`);
  },
  get: (siteId: string, postId: string) => fetchAPI<any>(`/v1/sites/${siteId}/posts/${postId}`),
  create: (siteId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/posts`, { method: 'POST', body: JSON.stringify(data) }),
  update: (siteId: string, postId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/posts/${postId}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (siteId: string, postId: string) => fetchAPI<any>(`/v1/sites/${siteId}/posts/${postId}`, { method: 'DELETE' }),
  publish: (siteId: string, postId: string) => fetchAPI<any>(`/v1/sites/${siteId}/posts/${postId}/publish`, { method: 'POST' }),
};

// Categories
export const categoriesApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/categories`),
  create: (siteId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/categories`, { method: 'POST', body: JSON.stringify(data) }),
  update: (siteId: string, categoryId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/categories/${categoryId}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (siteId: string, categoryId: string) => fetchAPI<any>(`/v1/sites/${siteId}/categories/${categoryId}`, { method: 'DELETE' }),
};

// Tags
export const tagsApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/tags`),
  create: (siteId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/tags`, { method: 'POST', body: JSON.stringify(data) }),
  delete: (siteId: string, tagId: string) => fetchAPI<any>(`/v1/sites/${siteId}/tags/${tagId}`, { method: 'DELETE' }),
};

// Integrations
export const integrationsApi = {
  catalog: () => fetchAPI<any>('/v1/sites/integrations/catalog'),
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/integrations`),
  update: (siteId: string, integrations: any[]) => fetchAPI<any>(`/v1/sites/${siteId}/integrations`, { method: 'PUT', body: JSON.stringify({ integrations }) }),
};

// Comments
export const commentsApi = {
  list: (siteId: string, postId: string) => fetchAPI<any>(`/v1/sites/${siteId}/posts/${postId}/comments`),
  moderate: (siteId: string, commentId: string, status: string) => fetchAPI<any>(`/v1/sites/${siteId}/comments/${commentId}`, { method: 'PUT', body: JSON.stringify({ status }) }),
  delete: (siteId: string, commentId: string) => fetchAPI<any>(`/v1/sites/${siteId}/comments/${commentId}`, { method: 'DELETE' }),
};

// Products
export const productsApi = {
  list: (siteId: string, params?: { status?: string; search?: string; limit?: number; offset?: number }) => {
    const qs = new URLSearchParams();
    if (params?.status) qs.set('status', params.status);
    if (params?.search) qs.set('search', params.search);
    if (params?.limit) qs.set('limit', String(params.limit));
    if (params?.offset) qs.set('offset', String(params.offset));
    return fetchAPI<any>(`/v1/sites/${siteId}/products?${qs}`);
  },
  get: (siteId: string, id: string) => fetchAPI<any>(`/v1/sites/${siteId}/products/${id}`),
  create: (siteId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/products`, { method: 'POST', body: JSON.stringify(data) }),
  update: (siteId: string, id: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/products/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (siteId: string, id: string) => fetchAPI<any>(`/v1/sites/${siteId}/products/${id}`, { method: 'DELETE' }),
};

// Orders
export const ordersApi = {
  list: (siteId: string, params?: { paymentStatus?: string; limit?: number; offset?: number }) => {
    const qs = new URLSearchParams();
    if (params?.paymentStatus) qs.set('paymentStatus', params.paymentStatus);
    if (params?.limit) qs.set('limit', String(params.limit));
    if (params?.offset) qs.set('offset', String(params.offset));
    return fetchAPI<any>(`/v1/sites/${siteId}/orders?${qs}`);
  },
  get: (siteId: string, id: string) => fetchAPI<any>(`/v1/sites/${siteId}/orders/${id}`),
  update: (siteId: string, id: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/orders/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
};

// Coupons
export const couponsApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/coupons`),
  create: (siteId: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/coupons`, { method: 'POST', body: JSON.stringify(data) }),
  update: (siteId: string, id: string, data: any) => fetchAPI<any>(`/v1/sites/${siteId}/coupons/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (siteId: string, id: string) => fetchAPI<any>(`/v1/sites/${siteId}/coupons/${id}`, { method: 'DELETE' }),
};

// AI
export const aiApi = {
  generateSite: (data: { prompt: string; locale?: string; style?: string }) =>
    fetchAPI<any>('/v1/ai/generate-site', { method: 'POST', body: JSON.stringify(data) }),
  suggestContent: (data: { sectionType: string; businessDescription: string; locale?: string }) =>
    fetchAPI<any>('/v1/ai/suggest-content', { method: 'POST', body: JSON.stringify(data) }),
};

// Marketplace
export const marketplaceApi = {
  browse: (params?: { category?: string; search?: string; sort?: string; limit?: number; offset?: number }) => {
    const qs = new URLSearchParams();
    if (params?.category) qs.set('category', params.category);
    if (params?.search) qs.set('search', params.search);
    if (params?.sort) qs.set('sort', params.sort || 'downloads');
    if (params?.limit) qs.set('limit', String(params.limit));
    if (params?.offset) qs.set('offset', String(params.offset));
    return fetchAPI<any>(`/v1/marketplace/templates?${qs}`);
  },
  get: (id: string) => fetchAPI<any>(`/v1/marketplace/templates/${id}`),
  featured: () => fetchAPI<any>('/v1/marketplace/featured'),
  categories: () => fetchAPI<any>('/v1/marketplace/categories'),
  use: (id: string) => fetchAPI<any>(`/v1/marketplace/templates/${id}/use`, { method: 'POST' }),
  rate: (id: string, rating: number, review?: string) => fetchAPI<any>(`/v1/marketplace/templates/${id}/rate`, { method: 'POST', body: JSON.stringify({ rating, review }) }),
  submit: (data: any) => fetchAPI<any>('/v1/marketplace/templates', { method: 'POST', body: JSON.stringify(data) }),
};

// Collaborators
export const collaboratorsApi = {
  list: (siteId: string) => fetchAPI<any>(`/v1/sites/${siteId}/collaborators`),
  invite: (siteId: string, email: string, role: string) => fetchAPI<any>(`/v1/sites/${siteId}/collaborators`, { method: 'POST', body: JSON.stringify({ email, role }) }),
  updateRole: (siteId: string, userId: string, role: string) => fetchAPI<any>(`/v1/sites/${siteId}/collaborators/${userId}`, { method: 'PUT', body: JSON.stringify({ role }) }),
  remove: (siteId: string, userId: string) => fetchAPI<any>(`/v1/sites/${siteId}/collaborators/${userId}`, { method: 'DELETE' }),
};
