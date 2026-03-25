/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  reactStrictMode: true,
  transpilePackages: [
    '@zentto/shared-ui',
    '@zentto/shared-auth',
    '@zentto/shared-api',
    '@zentto/module-admin',
    '@zentto/datagrid',
    '@zentto/datagrid-core',
    'lit',
  ],
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
