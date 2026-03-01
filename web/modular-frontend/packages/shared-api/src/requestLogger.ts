'use client';

export interface RequestLog {
  id: string;
  timestamp: string;
  user: { userName: string | null; userEmail: string | null };
  method: string;
  url: string;
  request: { data?: unknown; headers?: Record<string, unknown> };
  response?: { status?: number; statusText?: string; data?: unknown; headers?: Record<string, unknown> };
  error?: { message?: string; code?: string; response?: { status?: number; data?: unknown } };
  duration?: number;
  success: boolean;
}

class RequestLogger {
  private logs: RequestLog[] = [];
  private maxLogs = 1000;

  async logRequest(
    method: string, url: string, requestData: unknown,
    response: { status?: number; statusText?: string; data?: unknown } | null,
    error: { message?: string; code?: string } | null,
    duration: number,
    user: { userName: string | null; userEmail: string | null }
  ) {
    const log: RequestLog = {
      id: `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
      timestamp: new Date().toISOString(),
      user, method: method.toUpperCase(), url,
      request: { data: requestData },
      response: response ? { status: response.status, statusText: response.statusText, data: response.data } : undefined,
      error: error ? { message: error.message, code: error.code } : undefined,
      duration,
      success: !error && (response?.status ?? 0) >= 200 && (response?.status ?? 0) < 300,
    };
    this.logs.push(log);
    if (this.logs.length > this.maxLogs) this.logs = this.logs.slice(-this.maxLogs);
    return log;
  }

  getLogs(): RequestLog[] { return [...this.logs]; }
  clearAllLogs() { this.logs = []; }
  getStats() {
    const total = this.logs.length;
    const successful = this.logs.filter((l) => l.success).length;
    return { total, successful, failed: total - successful, successRate: total > 0 ? ((successful / total) * 100).toFixed(2) : '0' };
  }
}

export const requestLogger = new RequestLogger();
