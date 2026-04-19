/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
    reactStrictMode: true,
    basePath: '/inventario',
    transpilePackages: ['@zentto/design-tokens', '@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api', '@zentto/shared-reports', '@zentto/module-inventario'],
};

export default nextConfig;
