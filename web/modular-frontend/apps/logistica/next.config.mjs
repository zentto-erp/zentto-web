/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
    reactStrictMode: true,
    basePath: '/logistica',
    transpilePackages: ['@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api', '@zentto/shared-reports', '@zentto/module-logistica'],
};

export default nextConfig;
