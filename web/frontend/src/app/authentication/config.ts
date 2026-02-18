/**
 * Configuración de rutas de autenticación para la aplicación
 */

export const AUTH_ROUTES = {
  login: '/authentication/login',
  register: '/authentication/register',
  forgotPassword: '/authentication/forgot-password',
  resetPassword: '/authentication/reset-password',
};

// Rutas disponibles sin autenticación (públicas)
export const PUBLIC_ROUTES = [
  AUTH_ROUTES.login,
  AUTH_ROUTES.register,
  AUTH_ROUTES.forgotPassword,
  AUTH_ROUTES.resetPassword,
  '/api/register',
  '/api/auth-test',
  '/api/check-route',
  '/authentication', // Toda la carpeta de autenticación debe ser pública
];

// Detectar si una ruta es pública o requiere autenticación
export const isPublicRoute = (route: string): boolean => {
  // Primero chequeamos si la ruta está exactamente en las rutas públicas
  if (PUBLIC_ROUTES.includes(route)) {
    return true;
  }
  
  // Luego verificamos si comienza con alguna de las rutas públicas
  return PUBLIC_ROUTES.some(publicRoute => route.startsWith(publicRoute));
};

// Obtener la ruta de redirección después del inicio de sesión
export const getRedirectRoute = (): string => {
  return '/';  // Ruta por defecto a la que redirigir tras el inicio de sesión
};
