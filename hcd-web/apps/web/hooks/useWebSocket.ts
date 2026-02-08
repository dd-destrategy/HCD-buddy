// =============================================================================
// Client-side WebSocket Hook
// React hook for real-time WebSocket communication with the server
// =============================================================================

'use client';

import { useEffect, useRef, useCallback, useState } from 'react';
import type { ClientMessage, ServerMessage } from '@hcd/ws-protocol';
import { encodeMessage, decodeServerMessage } from '@hcd/ws-protocol';

// =============================================================================
// Types
// =============================================================================

export type ConnectionState = 'connecting' | 'connected' | 'disconnected' | 'error';

export interface UseWebSocketOptions {
  /** Session ID to connect to */
  sessionId: string;
  /** Auth token for the connection */
  token: string;
  /** Client role */
  role?: 'interviewer' | 'observer';
  /** User display name (for observer comments) */
  userName?: string;
  /** Callback when a message is received from the server */
  onMessage?: (message: ServerMessage) => void;
  /** Callback when connection state changes */
  onStateChange?: (state: ConnectionState) => void;
  /** Callback when an error occurs */
  onError?: (error: Event | Error) => void;
  /** Whether to automatically connect. Default: true */
  autoConnect?: boolean;
  /** Ping interval in ms. Default: 25000 */
  pingInterval?: number;
  /** Maximum reconnection attempts. Default: 10 */
  maxReconnectAttempts?: number;
}

export interface UseWebSocketReturn {
  /** Current connection state */
  connectionState: ConnectionState;
  /** Send a typed message to the server */
  send: (message: ClientMessage) => void;
  /** Manually connect to the WebSocket server */
  connect: () => void;
  /** Manually disconnect from the WebSocket server */
  disconnect: () => void;
  /** Whether the connection is currently active */
  isConnected: boolean;
  /** Number of reconnection attempts made */
  reconnectAttempts: number;
  /** Measured latency in ms (from ping/pong) */
  latency: number;
}

// =============================================================================
// Hook Implementation
// =============================================================================

export function useWebSocket(options: UseWebSocketOptions): UseWebSocketReturn {
  const {
    sessionId,
    token,
    role = 'observer',
    userName,
    onMessage,
    onStateChange,
    onError,
    autoConnect = true,
    pingInterval = 25_000,
    maxReconnectAttempts = 10,
  } = options;

  const [connectionState, setConnectionState] = useState<ConnectionState>('disconnected');
  const [reconnectAttempts, setReconnectAttempts] = useState(0);
  const [latency, setLatency] = useState(0);

  const wsRef = useRef<WebSocket | null>(null);
  const pingTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const reconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pingSentAtRef = useRef<number>(0);
  const intentionalCloseRef = useRef(false);
  const reconnectAttemptsRef = useRef(0);
  const mountedRef = useRef(true);

  // Keep callbacks in refs to avoid reconnections on callback changes
  const onMessageRef = useRef(onMessage);
  const onStateChangeRef = useRef(onStateChange);
  const onErrorRef = useRef(onError);

  useEffect(() => {
    onMessageRef.current = onMessage;
  }, [onMessage]);
  useEffect(() => {
    onStateChangeRef.current = onStateChange;
  }, [onStateChange]);
  useEffect(() => {
    onErrorRef.current = onError;
  }, [onError]);

  // ---------------------------------------------------------------------------
  // State Management
  // ---------------------------------------------------------------------------

  const updateState = useCallback((state: ConnectionState) => {
    if (!mountedRef.current) return;
    setConnectionState(state);
    onStateChangeRef.current?.(state);
  }, []);

  // ---------------------------------------------------------------------------
  // Ping / Heartbeat
  // ---------------------------------------------------------------------------

  const startPing = useCallback(() => {
    stopPing();
    pingTimerRef.current = setInterval(() => {
      if (wsRef.current?.readyState === WebSocket.OPEN) {
        pingSentAtRef.current = Date.now();
        const pingMessage: ClientMessage = { type: 'ping' };
        wsRef.current.send(encodeMessage(pingMessage));
      }
    }, pingInterval);
  }, [pingInterval]);

  const stopPing = useCallback(() => {
    if (pingTimerRef.current) {
      clearInterval(pingTimerRef.current);
      pingTimerRef.current = null;
    }
  }, []);

  // ---------------------------------------------------------------------------
  // Reconnection
  // ---------------------------------------------------------------------------

  const scheduleReconnect = useCallback(() => {
    if (intentionalCloseRef.current) return;
    if (reconnectAttemptsRef.current >= maxReconnectAttempts) {
      console.error('[useWebSocket] Max reconnection attempts reached');
      updateState('error');
      return;
    }

    // Exponential backoff: 2s, 4s, 8s, 16s (capped)
    const delay = Math.min(
      2000 * Math.pow(2, reconnectAttemptsRef.current),
      16_000
    );

    console.log(
      `[useWebSocket] Reconnecting in ${delay}ms ` +
      `(attempt ${reconnectAttemptsRef.current + 1}/${maxReconnectAttempts})`
    );

    reconnectTimerRef.current = setTimeout(() => {
      reconnectAttemptsRef.current++;
      if (mountedRef.current) {
        setReconnectAttempts(reconnectAttemptsRef.current);
      }
      connectWebSocket();
    }, delay);
  }, [maxReconnectAttempts, updateState]);

  const cancelReconnect = useCallback(() => {
    if (reconnectTimerRef.current) {
      clearTimeout(reconnectTimerRef.current);
      reconnectTimerRef.current = null;
    }
  }, []);

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  const connectWebSocket = useCallback(() => {
    // Close existing connection if any
    if (wsRef.current) {
      wsRef.current.onopen = null;
      wsRef.current.onmessage = null;
      wsRef.current.onclose = null;
      wsRef.current.onerror = null;
      if (wsRef.current.readyState === WebSocket.OPEN || wsRef.current.readyState === WebSocket.CONNECTING) {
        wsRef.current.close();
      }
      wsRef.current = null;
    }

    intentionalCloseRef.current = false;
    updateState('connecting');

    // Build WebSocket URL
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const host = window.location.host;
    const params = new URLSearchParams({
      sessionId,
      token,
      role,
    });
    if (userName) {
      params.set('userName', userName);
    }
    const url = `${protocol}//${host}/ws?${params.toString()}`;

    let ws: WebSocket;
    try {
      ws = new WebSocket(url);
    } catch (error) {
      console.error('[useWebSocket] Failed to create WebSocket:', error);
      updateState('error');
      scheduleReconnect();
      return;
    }

    wsRef.current = ws;

    ws.onopen = () => {
      console.log('[useWebSocket] Connected');
      reconnectAttemptsRef.current = 0;
      if (mountedRef.current) {
        setReconnectAttempts(0);
      }
      updateState('connected');
      startPing();
    };

    ws.onmessage = (event: MessageEvent) => {
      try {
        const message = decodeServerMessage(
          typeof event.data === 'string' ? event.data : event.data.toString()
        );

        // Handle pong for latency measurement
        if (message.type === 'pong') {
          if (pingSentAtRef.current > 0) {
            const roundTrip = Date.now() - pingSentAtRef.current;
            if (mountedRef.current) {
              setLatency(roundTrip);
            }
            pingSentAtRef.current = 0;
          }
          return;
        }

        onMessageRef.current?.(message);
      } catch (error) {
        console.error('[useWebSocket] Failed to parse message:', error);
      }
    };

    ws.onclose = (event: CloseEvent) => {
      console.log(`[useWebSocket] Closed: ${event.code} ${event.reason}`);
      stopPing();
      wsRef.current = null;

      if (intentionalCloseRef.current) {
        updateState('disconnected');
      } else {
        updateState('disconnected');
        scheduleReconnect();
      }
    };

    ws.onerror = (event: Event) => {
      console.error('[useWebSocket] Error:', event);
      onErrorRef.current?.(event);
      // The close event will fire after this, triggering reconnection
    };
  }, [sessionId, token, role, userName, updateState, startPing, stopPing, scheduleReconnect]);

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  const send = useCallback((message: ClientMessage) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(encodeMessage(message));
    } else {
      console.warn('[useWebSocket] Cannot send: not connected');
    }
  }, []);

  const connect = useCallback(() => {
    cancelReconnect();
    reconnectAttemptsRef.current = 0;
    setReconnectAttempts(0);
    connectWebSocket();
  }, [connectWebSocket, cancelReconnect]);

  const disconnect = useCallback(() => {
    intentionalCloseRef.current = true;
    cancelReconnect();
    stopPing();

    if (wsRef.current) {
      wsRef.current.close(1000, 'Client disconnect');
      wsRef.current = null;
    }

    updateState('disconnected');
  }, [cancelReconnect, stopPing, updateState]);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  useEffect(() => {
    mountedRef.current = true;

    if (autoConnect && sessionId && token) {
      connectWebSocket();
    }

    return () => {
      mountedRef.current = false;
      intentionalCloseRef.current = true;
      cancelReconnect();
      stopPing();

      if (wsRef.current) {
        wsRef.current.onopen = null;
        wsRef.current.onmessage = null;
        wsRef.current.onclose = null;
        wsRef.current.onerror = null;
        wsRef.current.close(1000, 'Component unmount');
        wsRef.current = null;
      }
    };
    // We intentionally only re-run this when session/token changes
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sessionId, token]);

  return {
    connectionState,
    send,
    connect,
    disconnect,
    isConnected: connectionState === 'connected',
    reconnectAttempts,
    latency,
  };
}
