/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    '@datqbox/shared-auth',
    '@datqbox/shared-ui',
    '@datqbox/shared-api',
    '@datqbox/module-admin',
    '@datqbox/module-bancos',
    '@datqbox/module-compras',
    '@datqbox/module-inventario',
    '@datqbox/module-contabilidad',
    '@datqbox/module-nomina',
    '@datqbox/pos',
    '@datqbox/restaurante',
  ],
};

export default nextConfig;
