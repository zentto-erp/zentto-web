/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  eslint: { ignoreDuringBuilds: true },
  transpilePackages: [
    '@zentto/shared-auth',
    '@zentto/shared-ui',
    '@zentto/shared-api',
    '@zentto/module-admin',
    '@zentto/module-bancos',
    '@zentto/module-compras',
    '@zentto/module-inventario',
    '@zentto/module-contabilidad',
    '@zentto/module-nomina',
    '@zentto/pos',
    '@zentto/restaurante',
  ],
};

export default nextConfig;
