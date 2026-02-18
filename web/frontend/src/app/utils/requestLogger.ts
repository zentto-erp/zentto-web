'use client';

export interface RequestLog {
  id: string;
  timestamp: string;
  user: {
    userName: string | null;
    userEmail: string | null;
  };
  method: string;
  url: string;
  request: {
    data?: any;
    headers?: any;
  };
  response: {
    status?: number;
    statusText?: string;
    data?: any;
    headers?: any;
  };
  error?: {
    message?: string;
    code?: string;
    response?: {
      status?: number;
      data?: any;
    };
  };
  duration?: number; // en milisegundos
  success: boolean;
}

class RequestLogger {
  private logs: RequestLog[] = [];
  private maxLogs = 1000; // Máximo de logs en memoria
  private isInitialized = false;

  /**
   * Inicializa el logger
   * NOTA: Ya no carga desde localStorage porque usamos SQLite en el servidor
   * localStorage solo se usa como fallback si SQLite falla
   */
  init() {
    if (this.isInitialized) return;
    
    // Ya no cargamos desde localStorage porque usamos SQLite
    // Los logs se cargan desde el servidor cuando se necesitan
    // Esto evita duplicidad y problemas de cuota excedida
    this.logs = [];
    
    this.isInitialized = true;
  }

  /**
   * Guarda logs en localStorage
   */
  private saveToLocalStorage() {
    try {
      localStorage.setItem('requestLogs', JSON.stringify(this.logs));
    } catch (error) {
      console.error('Error al guardar logs en localStorage:', error);
      // Si localStorage está lleno, eliminar los logs más antiguos
      if (this.logs.length > 100) {
        this.logs = this.logs.slice(-100);
        try {
          localStorage.setItem('requestLogs', JSON.stringify(this.logs));
        } catch (e) {
          console.error('Error crítico al guardar logs:', e);
        }
      }
    }
  }

  /**
   * Guarda logs en el servidor mediante API route (SQLite)
   */
  private async saveToServer(log: RequestLog) {
    try {
      // Log en desarrollo para verificar qué se está enviando
      if (process.env.NODE_ENV === 'development') {
        console.log('[RequestLogger] Intentando guardar log en SQLite:', {
          id: log.id,
          method: log.method,
          url: log.url,
          user: log.user,
          hasUser: !!(log.user.userName || log.user.userEmail),
        });
      }
      
      // Intentar guardar en servidor (SQLite)
      const response = await fetch('/api/logs', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(log),
      });
      
      if (!response.ok) {
        let errorText = '';
        try {
          errorText = await response.text();
          const errorData = JSON.parse(errorText);
          throw new Error(`HTTP ${response.status}: ${errorData.error || errorText}`);
        } catch (parseError) {
          throw new Error(`HTTP ${response.status}: ${errorText || response.statusText}`);
        }
      }
      
      // Verificar que la respuesta sea válida
      try {
        const result = await response.json();
        if (!result.success) {
          throw new Error(result.error || 'Error desconocido al guardar log');
        }
      } catch (jsonError) {
        // Si no hay JSON, asumir éxito si el status fue 200
        if (response.ok) {
          // Log exitoso (solo en desarrollo)
          if (process.env.NODE_ENV === 'development') {
            console.log('[RequestLogger] Log guardado exitosamente en SQLite:', log.id);
          }
          return; // Éxito
        }
        throw jsonError;
      }
      
      // Log exitoso (solo en desarrollo para no saturar logs en producción)
      if (process.env.NODE_ENV === 'development') {
        console.log('[RequestLogger] Log guardado exitosamente en SQLite:', log.id);
      }
    } catch (error: any) {
      // Siempre registrar errores críticos (tanto en desarrollo como producción)
      // pero con menos detalle en producción
      const errorMessage = error?.message || error?.toString() || 'Error desconocido';
      const errorDetails = {
        message: errorMessage,
        logId: log.id,
        url: log.url,
        method: log.method,
        user: log.user,
      };
      
      // Usar console.log en lugar de console.error para evitar problemas con Next.js
      // SIEMPRE registrar errores para debugging
      console.log('[RequestLogger] ERROR al guardar log en servidor (SQLite):', errorDetails);
      if (process.env.NODE_ENV === 'development') {
        console.log('[RequestLogger] Error completo:', error);
      }
      // Los logs se mantienen en localStorage como respaldo
      // IMPORTANTE: El sistema sigue funcionando aunque falle el guardado en SQLite
    }
  }

  /**
   * Registra un request/response
   */
  async logRequest(
    method: string,
    url: string,
    requestData: any,
    response: any,
    error: any,
    duration: number,
    user: { userName: string | null; userEmail: string | null }
  ) {
    const log: RequestLog = {
      id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      timestamp: new Date().toISOString(),
      user,
      method: method.toUpperCase(),
      url,
      request: {
        data: this.sanitizeData(requestData),
        headers: this.sanitizeHeaders(requestData?.headers),
      },
      response: response
        ? {
            status: response.status,
            statusText: response.statusText,
            data: this.sanitizeData(response.data),
            headers: this.sanitizeHeaders(response.headers),
          }
        : undefined,
      error: error
        ? {
            message: error.message,
            code: error.code,
            response: error.response
              ? {
                  status: error.response.status,
                  data: this.sanitizeData(error.response.data),
                }
              : undefined,
          }
        : undefined,
      duration,
      success: !error && response?.status >= 200 && response?.status < 300,
    };

    // Agregar a memoria (solo para estadísticas y filtrado en memoria)
    this.logs.push(log);

    // Mantener solo los últimos maxLogs en memoria
    if (this.logs.length > this.maxLogs) {
      this.logs = this.logs.slice(-this.maxLogs);
    }

    // Intentar guardar en servidor (SQLite) primero
    // Solo usar localStorage como fallback si falla SQLite
    this.saveToServer(log)
      .then(() => {
        // Si se guardó exitosamente en SQLite, NO guardar en localStorage
        // Esto evita duplicidad y problemas de cuota
      })
      .catch(() => {
        // Solo si falla SQLite, guardar en localStorage como respaldo
        // Pero con manejo de errores para evitar cuota excedida
        try {
          this.saveToLocalStorage();
        } catch (storageError) {
          // Si localStorage también falla (cuota excedida), limpiar logs antiguos
          if (this.logs.length > 100) {
            this.logs = this.logs.slice(-100);
            try {
              this.saveToLocalStorage();
            } catch (e) {
              // Si aún falla, simplemente no guardar en localStorage
              // Los logs se mantienen en memoria y en SQLite
            }
          }
        }
      });

    return log;
  }

  /**
   * Sanitiza datos sensibles antes de guardar
   */
  private sanitizeData(data: any): any {
    if (!data) return data;
    
    try {
      const dataStr = JSON.stringify(data);
      // Eliminar tokens y contraseñas
      const sanitized = dataStr
        .replace(/"password":\s*"[^"]*"/gi, '"password": "***"')
        .replace(/"token":\s*"[^"]*"/gi, '"token": "***"')
        .replace(/"accessToken":\s*"[^"]*"/gi, '"accessToken": "***"')
        .replace(/"authorization":\s*"[^"]*"/gi, '"authorization": "***"');
      
      return JSON.parse(sanitized);
    } catch {
      return data;
    }
  }

  /**
   * Sanitiza headers sensibles
   */
  private sanitizeHeaders(headers: any): any {
    if (!headers) return headers;
    
    const sanitized = { ...headers };
    if (sanitized.Authorization) {
      sanitized.Authorization = 'Bearer ***';
    }
    if (sanitized.authorization) {
      sanitized.authorization = 'Bearer ***';
    }
    return sanitized;
  }

  /**
   * Obtiene todos los logs
   */
  getLogs(): RequestLog[] {
    return [...this.logs];
  }

  /**
   * Filtra logs por criterios
   */
  filterLogs(filters: {
    method?: string;
    url?: string;
    success?: boolean;
    userEmail?: string;
    startDate?: string;
    endDate?: string;
  }): RequestLog[] {
    return this.logs.filter((log) => {
      if (filters.method && log.method !== filters.method.toUpperCase()) {
        return false;
      }
      if (filters.url && !log.url.includes(filters.url)) {
        return false;
      }
      if (filters.success !== undefined && log.success !== filters.success) {
        return false;
      }
      if (filters.userEmail && log.user.userEmail !== filters.userEmail) {
        return false;
      }
      if (filters.startDate && log.timestamp < filters.startDate) {
        return false;
      }
      if (filters.endDate && log.timestamp > filters.endDate) {
        return false;
      }
      return true;
    });
  }

  /**
   * Limpia logs antiguos
   * NOTA: Solo limpia logs en memoria. Los logs en SQLite se limpian desde el servidor.
   */
  clearOldLogs(daysToKeep: number = 7) {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
    
    this.logs = this.logs.filter(
      (log) => new Date(log.timestamp) >= cutoffDate
    );
    
    // Solo guardar en localStorage si hay logs (y si no falla)
    // Como usamos SQLite, esto es solo un respaldo
    if (this.logs.length > 0) {
      try {
        this.saveToLocalStorage();
      } catch (error) {
        // Si falla, no hacer nada (los logs en SQLite se mantienen)
      }
    } else {
      // Si no hay logs, limpiar localStorage
      try {
        localStorage.removeItem('requestLogs');
      } catch (error) {
        // Ignorar errores al limpiar
      }
    }
  }

  /**
   * Limpia todos los logs
   */
  clearAllLogs() {
    this.logs = [];
    localStorage.removeItem('requestLogs');
  }

  /**
   * Obtiene estadísticas de los logs
   */
  getStats() {
    const total = this.logs.length;
    const successful = this.logs.filter((log) => log.success).length;
    const failed = total - successful;
    const methods = this.logs.reduce((acc, log) => {
      acc[log.method] = (acc[log.method] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return {
      total,
      successful,
      failed,
      successRate: total > 0 ? ((successful / total) * 100).toFixed(2) : '0',
      methods,
    };
  }
}

// Instancia singleton
export const requestLogger = new RequestLogger();

// Inicializar al cargar el módulo
if (typeof window !== 'undefined') {
  requestLogger.init();
}
