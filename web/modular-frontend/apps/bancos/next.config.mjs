/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
  eslint: { ignoreDuringBuilds: true },
    reactStrictMode: true,
    basePath: '/bancos',
    transpilePackages: ['@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api'],
};

export default nextConfig;
