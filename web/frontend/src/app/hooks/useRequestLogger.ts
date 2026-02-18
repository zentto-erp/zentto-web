'use client';

import { useEffect, useState, useCallback } from 'react';
import { requestLogger, RequestLog } from '@/app/utils/requestLogger';

export interface LogFilters {
  method?: string;
  endpoint?: string;
  url?: string;
  success?: boolean;
  userEmail?: string;
  startDate?: string;
  endDate?: string;
  limit?: number;
  offset?: number;
}

export const useRequestLogger = () => {
  const [logs, setLogs] = useState<RequestLog[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  // Cargar logs desde localStorage
  const loadLogs = useCallback(() => {
    const allLogs = requestLogger.getLogs();
    setLogs(allLogs);
  }, []);

  // Obtener estadísticas (definir primero para evitar referencia circular)
  const getStats = useCallback(() => {
    return requestLogger.getStats();
  }, []);

  // Cargar logs desde servidor (SQLite)
  const loadLogsFromServer = useCallback(async (filters?: LogFilters & { endpoint?: string; limit?: number; offset?: number }) => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      
      if (filters?.method) params.append('method', filters.method);
      if (filters?.endpoint) params.append('endpoint', filters.endpoint);
      if (filters?.url) params.append('url', filters.url);
      if (filters?.success !== undefined) params.append('success', String(filters.success));
      if (filters?.userEmail) params.append('userEmail', filters.userEmail);
      if (filters?.startDate) params.append('startDate', filters.startDate);
      if (filters?.endDate) params.append('endDate', filters.endDate);
      
      params.append('limit', String(filters?.limit || 1000));
      params.append('offset', String(filters?.offset || 0));
      
      const response = await fetch(`/api/logs?${params.toString()}`);
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Error desconocido' }));
        throw new Error(errorData.error || `HTTP ${response.status}`);
      }
      
      const data = await response.json();
      
      if (data.logs && Array.isArray(data.logs)) {
        // Siempre establecer los logs, incluso si el array está vacío
        // Esto asegura que cuando no hay resultados, se muestre el mensaje correcto
        setLogs(data.logs);
        // Log solo en desarrollo
        if (process.env.NODE_ENV === 'development') {
          console.log(`[useRequestLogger] ${data.logs.length} logs cargados desde SQLite con filtros:`, filters);
        }
      } else {
        // Warning siempre (para detectar problemas en producción también)
        console.warn('[useRequestLogger] Respuesta inválida de la API:', data);
        // Establecer array vacío para no mostrar datos antiguos
        setLogs([]);
      }
      
      return data; // Retornar también total y paginación
    } catch (error: any) {
      console.error('[useRequestLogger] Error al cargar logs desde servidor:', {
        error: error.message,
        filters,
      });
      // NO hacer fallback a localStorage cuando hay filtros activos
      // Esto evitaría mostrar datos incorrectos
      // En su lugar, establecer array vacío
      setLogs([]);
      return { logs: [], total: 0, returned: 0 };
    } finally {
      setIsLoading(false);
    }
  }, [loadLogs]);
  
  // Cargar estadísticas desde servidor
  const loadStatsFromServer = useCallback(async () => {
    try {
      const response = await fetch('/api/logs/stats');
      const data = await response.json();
      return data;
    } catch (error) {
      console.error('Error al cargar estadísticas:', error);
      return getStats(); // Fallback a estadísticas locales
    }
  }, [getStats]);

  // Filtrar logs localmente
  const filterLogs = useCallback((filters: LogFilters) => {
    const filtered = requestLogger.filterLogs(filters);
    setLogs(filtered);
  }, []);

  // Limpiar logs antiguos
  const clearOldLogs = useCallback(async (daysToKeep: number = 7) => {
    try {
      requestLogger.clearOldLogs(daysToKeep);
      
      // También limpiar en servidor
      await fetch(`/api/logs?daysToKeep=${daysToKeep}`, {
        method: 'DELETE',
      });
      
      loadLogs();
    } catch (error) {
      console.error('Error al limpiar logs:', error);
    }
  }, [loadLogs]);

  // Limpiar todos los logs
  const clearAllLogs = useCallback(() => {
    requestLogger.clearAllLogs();
    setLogs([]);
  }, []);

  // Cargar logs al montar
  useEffect(() => {
    loadLogs();
  }, [loadLogs]);

  return {
    logs,
    isLoading,
    loadLogs,
    loadLogsFromServer,
    loadStatsFromServer,
    filterLogs,
    clearOldLogs,
    clearAllLogs,
    getStats,
  };
};
