/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  reactStrictMode: true,
  basePath: '/bancos',
  transpilePackages: ['@zentto/design-tokens', '@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api', '@zentto/shared-reports'],
  // jspdf v4 + fflate use Node Worker dynamic eval that Turbopack cannot resolve
  // during SSR analysis. Externalize them so Next loads them at runtime in the browser only.
  serverExternalPackages: ['jspdf', 'fflate'],
};

export default nextConfig;
