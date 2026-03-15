/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    basePath: '/ecommerce',
    transpilePackages: ['@datqbox/shared-ui', '@datqbox/shared-auth', '@datqbox/shared-api', '@datqbox/module-ecommerce'],
};

export default nextConfig;
