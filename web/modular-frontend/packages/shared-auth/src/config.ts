export const AUTH_ROUTES = {
  login: '/authentication/login',
  register: '/authentication/register',
  forgotPassword: '/authentication/forgot-password',
  resetPassword: '/authentication/reset-password',
  verifyEmail: '/authentication/verify-email',
};

export const PUBLIC_ROUTES = [
  AUTH_ROUTES.login, AUTH_ROUTES.register,
  AUTH_ROUTES.forgotPassword, AUTH_ROUTES.resetPassword, AUTH_ROUTES.verifyEmail,
  '/api/register', '/api/auth-test', '/api/check-route', '/authentication',
];

export const isPublicRoute = (route: string): boolean => {
  if (PUBLIC_ROUTES.includes(route)) return true;
  return PUBLIC_ROUTES.some(r => route.startsWith(r));
};

export const getRedirectRoute = (): string => '/';
