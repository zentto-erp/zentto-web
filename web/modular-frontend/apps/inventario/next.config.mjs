/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    basePath: '/inventario',
    transpilePackages: ['@datqbox/shared-ui', '@datqbox/shared-auth', '@datqbox/shared-api', '@datqbox/module-inventario'],
};

export default nextConfig;
