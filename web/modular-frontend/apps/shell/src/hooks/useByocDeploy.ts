'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

// ─── Tipos ────────────────────────────────────────────────────────────────────

export type ByocProvider = 'hetzner' | 'digitalocean' | 'ssh' | 'aws' | 'gcp' | 'azure';

export type DeployStatus = 'PENDING' | 'RUNNING' | 'SUCCESS' | 'FAILED';

export interface ByocCredentials {
  apiToken?: string;
  ip?: string;
  sshPort?: number;
  sshUser?: string;
  sshKey?: string;
}

export interface ByocConfig {
  region?: string;
  size?: string;
  domain?: string;
  useZenttoDomain?: boolean;
}

export interface ByocState {
  provider: ByocProvider | '';
  credentials: ByocCredentials;
  config: ByocConfig;
  jobId: number | null;
  companyId: number | null;
  companyName: string;
  planLabel: string;
}

const STORAGE_KEY = 'byoc_wizard_state';

const DEFAULT_STATE: ByocState = {
  provider: '',
  credentials: {},
  config: { useZenttoDomain: true },
  jobId: null,
  companyId: null,
  companyName: '',
  planLabel: '',
};

// ─── Hook principal ───────────────────────────────────────────────────────────

export function useByocDeploy() {
  const [state, setState] = useState<ByocState>(DEFAULT_STATE);
  const [logs, setLogs] = useState<string[]>([]);
  const [status, setStatus] = useState<DeployStatus>('PENDING');
  const [progress, setProgress] = useState(0);
  const eventSourceRef = useRef<EventSource | null>(null);

  const API_URL = process.env.NEXT_PUBLIC_API_URL || '';

  // Cargar estado persistido al montar
  useEffect(() => {
    try {
      const raw = sessionStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as Partial<ByocState>;
        setState(prev => ({ ...prev, ...parsed }));
      }
    } catch {
      // sessionStorage no disponible (SSR) — ignorar
    }
  }, []);

  // Persistir estado en cada cambio
  const persistState = useCallback((newState: ByocState) => {
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(newState));
    } catch {
      // ignorar
    }
  }, []);

  const setProvider = useCallback((provider: ByocProvider) => {
    setState(prev => {
      const next = { ...prev, provider };
      persistState(next);
      return next;
    });
  }, [persistState]);

  const setCredentials = useCallback((credentials: ByocCredentials) => {
    setState(prev => {
      const next = { ...prev, credentials };
      persistState(next);
      return next;
    });
  }, [persistState]);

  const setConfig = useCallback((config: ByocConfig) => {
    setState(prev => {
      const next = { ...prev, config };
      persistState(next);
      return next;
    });
  }, [persistState]);

  const setCompanyInfo = useCallback((companyId: number, companyName: string, planLabel: string) => {
    setState(prev => {
      const next = { ...prev, companyId, companyName, planLabel };
      persistState(next);
      return next;
    });
  }, [persistState]);

  const setJobId = useCallback((jobId: number) => {
    setState(prev => {
      const next = { ...prev, jobId };
      persistState(next);
      return next;
    });
  }, [persistState]);

  // Iniciar el deploy — llama al endpoint y guarda el jobId
  const startDeploy = useCallback(async (token: string): Promise<number> => {
    const payload = {
      token,
      provider: state.provider,
      credentials: state.credentials,
      config: state.config,
    };

    const res = await fetch(`${API_URL}/v1/byoc/wizard/start`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({ message: 'Error al iniciar deploy' }));
      throw new Error(err.message || 'Error al iniciar deploy');
    }

    const data = await res.json() as { jobId: number };
    setJobId(data.jobId);
    setStatus('RUNNING');
    return data.jobId;
  }, [API_URL, state.provider, state.credentials, state.config, setJobId]);

  // Conectar al SSE stream para recibir logs en tiempo real
  const connectToStream = useCallback((jobId: number, token: string, onComplete?: (tenantUrl: string) => void) => {
    // Cerrar conexion previa si existe
    if (eventSourceRef.current) {
      eventSourceRef.current.close();
    }

    const url = `${API_URL}/v1/byoc/wizard/stream/${jobId}?token=${encodeURIComponent(token)}`;
    const es = new EventSource(url);
    eventSourceRef.current = es;

    es.addEventListener('status', (e: MessageEvent) => {
      const data = JSON.parse(e.data) as { status: string; serverIp?: string; tenantUrl?: string };
      if (data.status) {
        setStatus(data.status as DeployStatus);
      }
    });

    es.addEventListener('log', (e: MessageEvent) => {
      const data = JSON.parse(e.data) as { lines: string };
      setLogs(prev => [...prev, data.lines]);
      // Incrementar progreso estimado durante logs
      setProgress(prev => Math.min(prev + 1, 90));
    });

    es.addEventListener('done', (e: MessageEvent) => {
      const data = JSON.parse(e.data) as { status: string; tenantUrl?: string };
      if (data.status === 'DONE') {
        setStatus('SUCCESS');
        setProgress(100);
        es.close();
        onComplete?.(data.tenantUrl ?? '');
      } else {
        setStatus('FAILED');
        setLogs(prev => [...prev, '[ERROR] El deploy finalizó con estado fallido.']);
        es.close();
      }
    });

    es.addEventListener('error', () => {
      setStatus('FAILED');
      setLogs(prev => [...prev, '[ERROR] Se perdio la conexion con el servidor de deploy.']);
      es.close();
    });

    es.onerror = () => {
      if (es.readyState === EventSource.CLOSED) {
        setStatus('FAILED');
      }
    };
  }, [API_URL]);

  // Limpiar el estado del wizard (al completar o cancelar)
  const clearState = useCallback(() => {
    try {
      sessionStorage.removeItem(STORAGE_KEY);
    } catch {
      // ignorar
    }
    setState(DEFAULT_STATE);
    setLogs([]);
    setStatus('PENDING');
    setProgress(0);
  }, []);

  // Limpiar EventSource al desmontar
  useEffect(() => {
    return () => {
      if (eventSourceRef.current) {
        eventSourceRef.current.close();
      }
    };
  }, []);

  return {
    // Estado del wizard
    provider: state.provider,
    credentials: state.credentials,
    config: state.config,
    jobId: state.jobId,
    companyId: state.companyId,
    companyName: state.companyName,
    planLabel: state.planLabel,
    // Estado del deploy
    logs,
    status,
    progress,
    // Setters
    setProvider,
    setCredentials,
    setConfig,
    setCompanyInfo,
    // Acciones
    startDeploy,
    connectToStream,
    clearState,
  };
}
