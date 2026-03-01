'use client';

import { requestLogger } from '@/app/utils/requestLogger';
import { getSession } from 'next-auth/react';

const API_BASE = process.env.NEXT_PUBLIC_API_BASE || "http://localhost:4000";

// Función para obtener el token JWT de la sesión de NextAuth
async function getAuthToken(): Promise<string | null> {
  try {
    const session = await getSession();
    // @ts-ignore - accessToken es añadido por nosotros en el callback JWT
    return session?.accessToken || null;
  } catch {
    return null;
  }
}

// Función para obtener el usuario actual: evitamos `localStorage`.
// El flujo de autenticación usa `next-auth` y cookies httpOnly; por tanto
// no leemos tokens desde el cliente. Para logging dejamos un placeholder null.
function getCurrentUser(): { userName: string | null; userEmail: string | null } {
  return { userName: null, userEmail: null };
}

export async function apiGet(path: string) {
  const startTime = Date.now();
  const fullUrl = `${API_BASE}${path}`;
  const user = getCurrentUser();
  
  try {
    const res = await fetch(fullUrl, {
      headers: await authHeader(),
      credentials: 'include'
    });
    
    const duration = Date.now() - startTime;
    const responseData = await res.json().catch(() => ({}));
    
    if (!res.ok) {
      // Registrar error
      await requestLogger.logRequest(
        'GET',
        fullUrl,
        undefined,
        null,
        new Error(res.statusText),
        duration,
        user
      );
      throw new Error(await res.text());
    }
    
    // Registrar éxito
    await requestLogger.logRequest(
      'GET',
      fullUrl,
      undefined,
      {
        status: res.status,
        statusText: res.statusText,
        data: responseData,
        headers: Object.fromEntries(res.headers.entries()),
      },
      null,
      duration,
      user
    );
    
    return responseData;
  } catch (error: any) {
    const duration = Date.now() - startTime;
    
    // Registrar el error si aún no se ha registrado
    if (error.message !== 'Network error') {
      await requestLogger.logRequest(
        'GET',
        fullUrl,
        undefined,
        null,
        {
          message: error.message,
          code: error.code,
          response: error.response ? {
            status: error.response.status,
            data: error.response.data,
          } : undefined,
        },
        duration,
        user
      );
    }
    
    throw error;
  }
}

export async function apiPost(path: string, body: unknown) {
  const startTime = Date.now();
  const fullUrl = `${API_BASE}${path}`;
  const user = getCurrentUser();
  
  try {
    const res = await fetch(fullUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json", ...(await authHeader()) },
      credentials: 'include',
      body: JSON.stringify(body)
    });
    
    const duration = Date.now() - startTime;
    const responseData = await res.json().catch(() => ({}));
    
    if (!res.ok) {
      // Registrar error
      await requestLogger.logRequest(
        'POST',
        fullUrl,
        body,
        null,
        new Error(res.statusText),
        duration,
        user
      );
      throw new Error(await res.text());
    }
    
    // Registrar éxito
    await requestLogger.logRequest(
      'POST',
      fullUrl,
      body,
      {
        status: res.status,
        statusText: res.statusText,
        data: responseData,
        headers: Object.fromEntries(res.headers.entries()),
      },
      null,
      duration,
      user
    );
    
    return responseData;
  } catch (error: any) {
    const duration = Date.now() - startTime;
    
    // Registrar el error
    await requestLogger.logRequest(
      'POST',
      fullUrl,
      body,
      null,
      {
        message: error.message,
        code: error.code,
        response: error.response ? {
          status: error.response.status,
          data: error.response.data,
        } : undefined,
      },
      duration,
      user
    );
    
    throw error;
  }
}

export async function apiPut(path: string, body: unknown) {
  const startTime = Date.now();
  const fullUrl = `${API_BASE}${path}`;
  const user = getCurrentUser();
  
  try {
    const res = await fetch(fullUrl, {
      method: "PUT",
      headers: { "Content-Type": "application/json", ...(await authHeader()) },
      credentials: 'include',
      body: JSON.stringify(body)
    });
    
    const duration = Date.now() - startTime;
    const responseData = await res.json().catch(() => ({}));
    
    if (!res.ok) {
      await requestLogger.logRequest(
        'PUT',
        fullUrl,
        body,
        null,
        new Error(res.statusText),
        duration,
        user
      );
      throw new Error(await res.text());
    }
    
    await requestLogger.logRequest(
      'PUT',
      fullUrl,
      body,
      {
        status: res.status,
        statusText: res.statusText,
        data: responseData,
        headers: Object.fromEntries(res.headers.entries()),
      },
      null,
      duration,
      user
    );
    
    return responseData;
  } catch (error: any) {
    const duration = Date.now() - startTime;
    await requestLogger.logRequest(
      'PUT',
      fullUrl,
      body,
      null,
      {
        message: error.message,
        code: error.code,
        response: error.response ? {
          status: error.response.status,
          data: error.response.data,
        } : undefined,
      },
      duration,
      user
    );
    throw error;
  }
}

export async function apiDelete(path: string) {
  const startTime = Date.now();
  const fullUrl = `${API_BASE}${path}`;
  const user = getCurrentUser();
  
  try {
    const res = await fetch(fullUrl, {
      method: "DELETE",
      headers: await authHeader(),
      credentials: 'include'
    });
    
    const duration = Date.now() - startTime;
    const responseData = await res.json().catch(() => ({}));
    
    if (!res.ok) {
      await requestLogger.logRequest(
        'DELETE',
        fullUrl,
        undefined,
        null,
        new Error(res.statusText),
        duration,
        user
      );
      throw new Error(await res.text());
    }
    
    await requestLogger.logRequest(
      'DELETE',
      fullUrl,
      undefined,
      {
        status: res.status,
        statusText: res.statusText,
        data: responseData,
        headers: Object.fromEntries(res.headers.entries()),
      },
      null,
      duration,
      user
    );
    
    return responseData;
  } catch (error: any) {
    const duration = Date.now() - startTime;
    await requestLogger.logRequest(
      'DELETE',
      fullUrl,
      undefined,
      null,
      {
        message: error.message,
        code: error.code,
        response: error.response ? {
          status: error.response.status,
          data: error.response.data,
        } : undefined,
      },
      duration,
      user
    );
    throw error;
  }
}

async function authHeader(): Promise<Record<string, string>> {
  try {
    const session = await getSession();
    const headers: Record<string, string> = {};
    // @ts-ignore
    const token = session?.accessToken as string | undefined;
    if (token) headers.Authorization = `Bearer ${token}`;

    // @ts-ignore
    const activeCompany = session?.company as { companyId?: number; branchId?: number } | undefined;
    // @ts-ignore
    const accesses = (session?.companyAccesses as Array<{ companyId?: number; branchId?: number }> | undefined) ?? [];

    const companyId = Number(activeCompany?.companyId ?? accesses[0]?.companyId);
    const branchId = Number(activeCompany?.branchId ?? accesses[0]?.branchId);

    if (Number.isFinite(companyId) && companyId > 0) {
      headers['x-company-id'] = String(companyId);
    }
    if (Number.isFinite(branchId) && branchId > 0) {
      headers['x-branch-id'] = String(branchId);
    }

    return headers;
  } catch {
    const token = await getAuthToken();
    return token ? { Authorization: `Bearer ${token}` } : {};
  }
}
