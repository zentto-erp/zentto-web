/**
 * Utilidad de registro personalizada para evitar el comportamiento de overlay de errores de Next.js
 */

// Determina si estamos en modo de producción
const isProduction = process.env.NODE_ENV === 'production';

// Determina si estamos en el navegador
const isBrowser = typeof window !== 'undefined';

/**
 * Registra un mensaje informativo
 */
export const logger = {
  info: (...args: any[]) => {
    if (!isProduction) {
      console.info(...args);
    }
  },
  error: (...args: any[]) => {
    if (!isProduction) {
      // En el navegador, usamos console.warn para evitar que Next.js intercepte el error
      // En el servidor, seguimos usando console.error
      if (isBrowser) {
        console.warn('[ERROR]', ...args);
      } else {
        console.error(...args);
      }
    }
  },
  warn: (...args: any[]) => {
    if (!isProduction) {
      console.warn(...args);
    }
  },
  debug: (...args: any[]) => {
    if (!isProduction) {
      console.debug(...args);
    }
  },
  // Método específico para errores severos que deben ser registrados siempre con console.error
  // Usar con cautela
  criticalError: (...args: any[]) => {
    if (!isProduction) {
      console.error(...args);
    }
  }
};
