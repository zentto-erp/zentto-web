/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
    reactStrictMode: true,
    basePath: '/compras',
    transpilePackages: ['@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api', '@zentto/module-compras'],
};

export default nextConfig;
