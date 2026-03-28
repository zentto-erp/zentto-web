/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
    reactStrictMode: true,
    basePath: '/contabilidad',
    transpilePackages: ['@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api', '@zentto/shared-reports'],
};

export default nextConfig;
