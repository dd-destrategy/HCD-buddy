// =============================================================================
// Health Check Endpoint
// Returns server status, uptime, and connected session count
// =============================================================================

import { NextResponse } from 'next/server';
import { getWSManager } from '@/lib/ws-server';

const startTime = Date.now();

export async function GET(): Promise<NextResponse> {
  const wsManager = getWSManager();

  const uptimeMs = Date.now() - startTime;
  const uptimeSeconds = Math.floor(uptimeMs / 1000);
  const uptimeMinutes = Math.floor(uptimeSeconds / 60);
  const uptimeHours = Math.floor(uptimeMinutes / 60);

  return NextResponse.json(
    {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: {
        ms: uptimeMs,
        formatted: `${uptimeHours}h ${uptimeMinutes % 60}m ${uptimeSeconds % 60}s`,
      },
      connections: {
        activeSessions: wsManager.roomCount,
        totalClients: wsManager.totalClientCount,
      },
      environment: process.env.NODE_ENV || 'development',
      version: process.env.npm_package_version || '0.1.0',
    },
    { status: 200 }
  );
}
