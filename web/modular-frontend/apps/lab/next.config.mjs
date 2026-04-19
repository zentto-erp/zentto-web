/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  reactStrictMode: true,
  transpilePackages: [
    '@zentto/design-tokens', '@zentto/shared-ui',
    '@zentto/shared-auth',
    '@zentto/shared-api', '@zentto/shared-reports',
    '@zentto/module-admin',
    '@zentto/datagrid',
    '@zentto/datagrid-core',
    '@zentto/report-core',
    '@zentto/report-viewer',
    '@zentto/report-designer',
    '@zentto/studio',
    '@zentto/studio-core',
    '@zentto/studio-react',
    'lit',
  ],
  turbopack: {},
  async rewrites() {
    return [
      // shared-api calls /v1/* — rewrite to our proxy at /api/v1/*
      {
        source: '/v1/:path*',
        destination: '/api/v1/:path*',
      },
    ];
  },
};

export default nextConfig;
