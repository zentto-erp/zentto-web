'use client';

import { useState, useEffect, useCallback, useRef } from 'react';

const AGENT_URL = 'http://localhost:7654/';
const FETCH_TIMEOUT_MS = 1500;
const RETRY_INTERVAL_MS = 30_000;

export interface HardwareAgentState {
  isConnected: boolean;
  version: string | null;
  isChecking: boolean;
  retry: () => void;
}

interface AgentHealthResponse {
  Status?: string;
  Mode?: string;
  Version?: string;
}

async function checkAgent(): Promise<{ connected: boolean; version: string | null }> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

  try {
    const response = await fetch(AGENT_URL, {
      method: 'GET',
      signal: controller.signal,
      // No credentials, no cors mode — simple cross-origin request to localhost
      mode: 'cors',
    });

    if (!response.ok) {
      return { connected: false, version: null };
    }

    const data: AgentHealthResponse = await response.json();
    return {
      connected: true,
      version: data.Version ?? null,
    };
  } catch {
    return { connected: false, version: null };
  } finally {
    clearTimeout(timer);
  }
}

export function useHardwareAgent(): HardwareAgentState {
  const [isConnected, setIsConnected] = useState(false);
  const [version, setVersion] = useState<string | null>(null);
  const [isChecking, setIsChecking] = useState(true);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const run = useCallback(async () => {
    setIsChecking(true);
    const result = await checkAgent();
    setIsConnected(result.connected);
    setVersion(result.version);
    setIsChecking(false);
  }, []);

  // Programar reintentos solo cuando no está conectado
  useEffect(() => {
    // Limpiar intervalo anterior
    if (intervalRef.current !== null) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    if (!isConnected && !isChecking) {
      intervalRef.current = setInterval(run, RETRY_INTERVAL_MS);
    }

    return () => {
      if (intervalRef.current !== null) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [isConnected, isChecking, run]);

  // Primer chequeo al montar
  useEffect(() => {
    run();
  }, [run]);

  return { isConnected, version, isChecking, retry: run };
}
