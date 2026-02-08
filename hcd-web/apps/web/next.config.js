/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  transpilePackages: ['@hcd/db', '@hcd/engine', '@hcd/ws-protocol', '@hcd/ui', '@hcd/auth'],
  experimental: {
    outputFileTracingRoot: require('path').join(__dirname, '../../'),
  },
};

module.exports = nextConfig;
