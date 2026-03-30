/**
 * DataFetchProvider implementation that uses apiGet from @zentto/shared-api
 * to fetch real data from the Zentto API when previewing report templates
 * that have endpoint-based dataSources.
 */
import { apiGet } from '@zentto/shared-api';
import type { DataFetchProvider } from '@zentto/report-core';

export const zenttoDataFetchProvider: DataFetchProvider = {
  async fetch(
    endpoint: string,
    params?: Record<string, string>,
  ): Promise<Record<string, unknown> | Record<string, unknown>[]> {
    let url = endpoint;
    if (params) {
      for (const [key, val] of Object.entries(params)) {
        url = url.replace(`:${key}`, encodeURIComponent(val));
      }
    }
    const res = await apiGet(url);
    // The API may return data in different shapes — normalise
    return (res as Record<string, unknown>).data ??
      (res as Record<string, unknown>).rows ??
      res;
  },
};
