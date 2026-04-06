/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  transpilePackages: [
    '@zentto/shared-auth',
    '@zentto/shared-i18n',
    '@zentto/shared-ui',
    '@zentto/shared-api', '@zentto/shared-reports',
    '@zentto/module-admin',
    '@zentto/module-bancos',
    '@zentto/module-compras',
    '@zentto/module-inventario',
    '@zentto/module-contabilidad',
    '@zentto/module-nomina',
    '@zentto/pos',
    '@zentto/restaurante',
    '@zentto/studio',
    '@zentto/studio-core',
    '@zentto/studio-react',
    'lit',
  ],
};

export default nextConfig;
