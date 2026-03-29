/** @type {import('next').NextConfig} */
const nextConfig = {
  typescript: { ignoreBuildErrors: true },
    reactStrictMode: true,
    basePath: '/flota',
    transpilePackages: ['@zentto/shared-ui', '@zentto/shared-auth', '@zentto/shared-api', '@zentto/module-flota'],
};

export default nextConfig;
