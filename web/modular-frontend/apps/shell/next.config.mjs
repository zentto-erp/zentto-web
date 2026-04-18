// Sprint 4 del plan de seguridad auth — security headers en el shell.
//
// CSP arrancado en Report-Only para no romper cosas. Después de monitorear
// violaciones (via /api/csp-report o consola del browser) y limpiar inline
// scripts/styles, promover a 'Content-Security-Policy' enforcement.
//
// Notas:
//  - 'unsafe-inline' y 'unsafe-eval' habilitados temporalmente porque Next.js
//    inline-injecta runtime + Material UI usa Emotion (CSS-in-JS sin nonces).
//    Para enforcement real hay que setear nonces via middleware o usar
//    Next.js 'strict-dynamic'. Eso es trabajo de varios días.
//  - 'data:' permitido en img-src para los QR de MFA y avatars base64.
//  - connect-src incluye los endpoints de auth/api/notify/cache que el shell
//    consume. Si añades un nuevo backend, lo metes acá.
const isProd = process.env.NODE_ENV === 'production';

const cspDirectives = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://challenges.cloudflare.com https://www.google.com https://www.gstatic.com",
  "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
  "img-src 'self' data: blob: https:",
  "font-src 'self' data: https://fonts.gstatic.com",
  "connect-src 'self' https://*.zentto.net wss://*.zentto.net https://challenges.cloudflare.com http://localhost:* http://127.0.0.1:*",
  "frame-src 'self' https://challenges.cloudflare.com https://www.google.com",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "frame-ancestors 'none'",
  "upgrade-insecure-requests",
].join('; ');

const securityHeaders = [
  // CSP en Report-Only durante la fase de monitoreo. Una vez validado, cambiar
  // 'Content-Security-Policy-Report-Only' por 'Content-Security-Policy'.
  { key: 'Content-Security-Policy-Report-Only', value: cspDirectives },
  // Refuerzos de helmet equivalentes en el frontend
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'same-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(), payment=(self)' },
  // HSTS solo en prod (en dev rompe localhost http)
  ...(isProd
    ? [{ key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains; preload' }]
    : []),
];

/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  async headers() {
    return [
      {
        source: '/:path*',
        headers: securityHeaders,
      },
    ];
  },
  transpilePackages: [
    '@zentto/shared-auth',
    '@zentto/shared-i18n',
    '@zentto/shared-ui',
    '@zentto/shared-api',
    '@zentto/shared-reports',
    '@zentto/module-admin',
    '@zentto/module-compras',
    '@zentto/studio',
    '@zentto/studio-core',
    '@zentto/studio-react',
    'lit',
  ],
};

export default nextConfig;
