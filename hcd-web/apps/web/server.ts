// =============================================================================
// Custom Node.js Server
// Wraps Next.js with WebSocket support via ws library (noServer mode)
//
// Architecture:
// HTTP Request -> Next.js handler (pages, API routes)
// WS Upgrade on /ws -> WebSocket handler (live sessions)
// =============================================================================

import { createServer, IncomingMessage, ServerResponse } from 'http';
import { parse } from 'url';
import next from 'next';
import { getWSManager } from './lib/ws-server';
import type { Duplex } from 'stream';

// =============================================================================
// Configuration
// =============================================================================

const dev = process.env.NODE_ENV !== 'production';
const hostname = process.env.HOSTNAME || 'localhost';
const port = parseInt(process.env.PORT || '3000', 10);

// =============================================================================
// Server Initialization
// =============================================================================

async function startServer(): Promise<void> {
  // Initialize Next.js
  const app = next({ dev, hostname, port });
  const nextHandler = app.getRequestHandler();

  await app.prepare();
  console.log('[Server] Next.js prepared');

  // Initialize WebSocket manager
  const wsManager = getWSManager();
  console.log('[Server] WebSocket manager initialized');

  // Create HTTP server
  const server = createServer((req: IncomingMessage, res: ServerResponse) => {
    try {
      const parsedUrl = parse(req.url || '/', true);
      nextHandler(req, res, parsedUrl);
    } catch (error) {
      console.error('[Server] Error handling request:', error);
      res.statusCode = 500;
      res.end('Internal Server Error');
    }
  });

  // ---------------------------------------------------------------------------
  // WebSocket Upgrade Handling
  // ---------------------------------------------------------------------------

  server.on('upgrade', (request: IncomingMessage, socket: Duplex, head: Buffer) => {
    const { pathname } = parse(request.url || '/', true);

    if (pathname === '/ws') {
      // Hand off to our WebSocket manager
      wsManager.handleUpgrade(request, socket, head);
    } else {
      // Not a WebSocket path we handle — let Next.js handle it
      // (Next.js HMR uses its own WebSocket on /_next/webpack-hmr)
      if (dev && pathname?.startsWith('/_next')) {
        // In dev mode, let Next.js handle its own WebSocket connections
        return;
      }

      // Reject unknown WebSocket paths
      socket.write('HTTP/1.1 404 Not Found\r\n\r\n');
      socket.destroy();
    }
  });

  // ---------------------------------------------------------------------------
  // Graceful Shutdown
  // ---------------------------------------------------------------------------

  const shutdown = async (signal: string): Promise<void> => {
    console.log(`[Server] ${signal} received, shutting down gracefully...`);

    // Shut down WebSocket manager (closes all sessions and connections)
    try {
      await wsManager.shutdown();
    } catch (error) {
      console.error('[Server] Error shutting down WebSocket manager:', error);
    }

    // Close HTTP server
    server.close(() => {
      console.log('[Server] HTTP server closed');
      process.exit(0);
    });

    // Force exit after 10 seconds if graceful shutdown fails
    setTimeout(() => {
      console.error('[Server] Forced shutdown after timeout');
      process.exit(1);
    }, 10_000);
  };

  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  // Handle uncaught errors to prevent server crashes
  process.on('uncaughtException', (error: Error) => {
    console.error('[Server] Uncaught exception:', error);
    // In production, we should gracefully shut down
    if (!dev) {
      shutdown('uncaughtException').catch(console.error);
    }
  });

  process.on('unhandledRejection', (reason: unknown) => {
    console.error('[Server] Unhandled rejection:', reason);
  });

  // ---------------------------------------------------------------------------
  // Start Listening
  // ---------------------------------------------------------------------------

  server.listen(port, () => {
    console.log(`[Server] Ready on http://${hostname}:${port}`);
    console.log(`[Server] WebSocket endpoint: ws://${hostname}:${port}/ws`);
    console.log(`[Server] Environment: ${dev ? 'development' : 'production'}`);
  });
}

// =============================================================================
// Entry Point
// =============================================================================

startServer().catch((error) => {
  console.error('[Server] Failed to start:', error);
  process.exit(1);
});
