/** @type {import('next').NextConfig} */
const nextConfig = {
    reactStrictMode: true,
    basePath: '/auditoria',
    transpilePackages: ['@datqbox/shared-ui', '@datqbox/shared-auth', '@datqbox/shared-api', '@datqbox/module-auditoria'],
};

export default nextConfig;
