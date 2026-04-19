/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  reactStrictMode: true,
  basePath: '/report-studio',
  transpilePackages: [
    '@zentto/design-tokens', '@zentto/shared-ui',
    '@zentto/shared-auth',
    '@zentto/shared-api',
    '@zentto/report-core',
    '@zentto/report-viewer',
    '@zentto/report-designer',
    'lit',
  ],
  async rewrites() {
    return [
      {
        source: '/v1/:path*',
        destination: '/api/v1/:path*',
      },
    ];
  },
};

export default nextConfig;
