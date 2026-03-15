/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    basePath: '/compras',
    transpilePackages: ['@datqbox/shared-ui', '@datqbox/shared-auth', '@datqbox/shared-api', '@datqbox/module-compras'],
};

export default nextConfig;
