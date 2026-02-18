/** @type {import('next').NextConfig} */
const nextConfig = {
  transpilePackages: [
    '@datqbox/shared-auth',
    '@datqbox/shared-ui',
    '@datqbox/shared-api',
    '@datqbox/module-admin',
    '@datqbox/module-bancos',
    '@datqbox/module-contabilidad',
    '@datqbox/module-nomina',
  ],
};

export default nextConfig;
