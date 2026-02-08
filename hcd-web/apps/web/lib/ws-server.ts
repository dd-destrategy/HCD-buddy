// =============================================================================
// WebSocket Session Manager
// Manages session rooms, client connections, and message routing
// =============================================================================

import { WebSocket, WebSocketServer } from 'ws';
import type { IncomingMessage } from 'http';
import type {
  ClientMessage,
  ServerMessage,
  Utterance,
  CoachingEvent,
  TalkTimeRatio,
  TopicUpdate,
} from '@hcd/ws-protocol';
import { encodeMessage, decodeClientMessage } from '@hcd/ws-protocol';
import { OpenAIRelay } from './openai-relay';
import { RecallClient } from './recall-client';
import { base64ToPcm } from './audio-processor';

// =============================================================================
// Types
// =============================================================================

export type ClientRole = 'interviewer' | 'observer';

export interface ConnectedClient {
  ws: WebSocket;
  id: string;
  role: ClientRole;
  sessionId: string;
  joinedAt: number;
  lastPingAt: number;
  isAlive: boolean;
  /** User display name (for observer comments) */
  userName?: string;
}

export type SessionStatus = 'idle' | 'ready' | 'running' | 'paused' | 'ending' | 'ended';

export interface SessionRoomState {
  sessionId: string;
  status: SessionStatus;
  interviewerConnected: boolean;
  observerCount: number;
  startedAt?: number;
  utteranceCount: number;
  coachingEventCount: number;
  recallBotId?: string;
}

// =============================================================================
// SessionRoom
// =============================================================================

/**
 * A SessionRoom manages all WebSocket clients participating in a single
 * interview session. It coordinates message routing, OpenAI relay, and
 * Recall.ai bot management.
 */
export class SessionRoom {
  readonly sessionId: string;
  private clients: Map<string, ConnectedClient> = new Map();
  private status: SessionStatus = 'idle';
  private openaiRelay: OpenAIRelay | null = null;
  private recallClient: RecallClient | null = null;
  private recallBotId: string | null = null;
  private startedAt?: number;
  private utteranceCount = 0;
  private coachingEventCount = 0;
  private coachingCooldownTimer: ReturnType<typeof setTimeout> | null = null;
  private lastCoachingTime = 0;
  private readonly coachingCooldownMs = 120_000; // 2 minutes between prompts
  private readonly maxCoachingPerSession = 3;
  private talkTime: { interviewer: number; participant: number } = { interviewer: 0, participant: 0 };
  private currentSpeaker: 'interviewer' | 'participant' = 'interviewer';

  constructor(sessionId: string) {
    this.sessionId = sessionId;

    // Initialize Recall client if API key is available
    if (process.env.RECALL_API_KEY) {
      try {
        this.recallClient = new RecallClient();
      } catch {
        console.warn(`[SessionRoom ${sessionId}] Recall client not available`);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Client Management
  // ---------------------------------------------------------------------------

  /**
   * Add a client to the session room.
   */
  addClient(client: ConnectedClient): void {
    this.clients.set(client.id, client);

    // Send current session status to the newly connected client
    this.sendToClient(client, {
      type: 'session.status',
      status: this.status,
      sessionId: this.sessionId,
    });

    // Notify all clients of updated observer count
    this.broadcastObserverCount();

    console.log(
      `[SessionRoom ${this.sessionId}] Client ${client.id} (${client.role}) joined. ` +
      `Total: ${this.clients.size}`
    );
  }

  /**
   * Remove a client from the session room.
   * @returns true if the room is now empty and should be cleaned up.
   */
  removeClient(clientId: string): boolean {
    const client = this.clients.get(clientId);
    if (!client) return this.clients.size === 0;

    this.clients.delete(clientId);
    this.broadcastObserverCount();

    console.log(
      `[SessionRoom ${this.sessionId}] Client ${clientId} (${client.role}) left. ` +
      `Total: ${this.clients.size}`
    );

    // If the interviewer disconnects during a running session, pause
    if (client.role === 'interviewer' && this.status === 'running') {
      this.handlePause();
    }

    return this.clients.size === 0;
  }

  /**
   * Get the current state of the room.
   */
  getState(): SessionRoomState {
    const interviewer = Array.from(this.clients.values()).find(c => c.role === 'interviewer');
    const observerCount = Array.from(this.clients.values()).filter(c => c.role === 'observer').length;

    return {
      sessionId: this.sessionId,
      status: this.status,
      interviewerConnected: !!interviewer,
      observerCount,
      startedAt: this.startedAt,
      utteranceCount: this.utteranceCount,
      coachingEventCount: this.coachingEventCount,
      recallBotId: this.recallBotId || undefined,
    };
  }

  /** Get number of connected clients. */
  get clientCount(): number {
    return this.clients.size;
  }

  // ---------------------------------------------------------------------------
  // Message Routing
  // ---------------------------------------------------------------------------

  /**
   * Handle an incoming message from a client.
   */
  async handleMessage(clientId: string, raw: string): Promise<void> {
    const client = this.clients.get(clientId);
    if (!client) return;

    let message: ClientMessage;
    try {
      message = decodeClientMessage(raw);
    } catch {
      this.sendToClient(client, {
        type: 'error',
        code: 'INVALID_MESSAGE',
        message: 'Failed to parse message',
      });
      return;
    }

    switch (message.type) {
      case 'session.start':
        await this.handleStart(client, message.meetingUrl, message.useLocalMic);
        break;

      case 'session.pause':
        this.handlePause();
        break;

      case 'session.resume':
        this.handleResume();
        break;

      case 'session.stop':
        await this.handleStop();
        break;

      case 'audio.chunk':
        this.handleAudioChunk(message.data);
        break;

      case 'insight.flag':
        this.handleInsightFlag(client, message.timestamp, message.note);
        break;

      case 'coaching.respond':
        this.handleCoachingResponse(message.eventId, message.response);
        break;

      case 'coaching.pull':
        this.handleCoachingPull();
        break;

      case 'topic.update':
        this.handleTopicUpdate(message.topicName, message.status);
        break;

      case 'speaker.toggle':
        this.handleSpeakerToggle();
        break;

      case 'observer.join':
        // Already handled during connection; just acknowledge
        break;

      case 'observer.comment':
        this.handleObserverComment(client, message.text, message.timestamp);
        break;

      case 'observer.question':
        this.handleObserverQuestion(client, message.text);
        break;

      case 'ping':
        this.sendToClient(client, { type: 'pong' });
        client.lastPingAt = Date.now();
        client.isAlive = true;
        break;

      default:
        this.sendToClient(client, {
          type: 'error',
          code: 'UNKNOWN_MESSAGE',
          message: `Unknown message type: ${(message as { type: string }).type}`,
        });
    }
  }

  // ---------------------------------------------------------------------------
  // Session Lifecycle
  // ---------------------------------------------------------------------------

  private async handleStart(
    client: ConnectedClient,
    meetingUrl?: string,
    useLocalMic?: boolean
  ): Promise<void> {
    if (client.role !== 'interviewer') {
      this.sendToClient(client, {
        type: 'session.error',
        code: 'UNAUTHORIZED',
        message: 'Only the interviewer can start a session',
      });
      return;
    }

    if (this.status !== 'idle' && this.status !== 'ready') {
      this.sendToClient(client, {
        type: 'session.error',
        code: 'INVALID_STATE',
        message: `Cannot start session in ${this.status} state`,
      });
      return;
    }

    this.status = 'running';
    this.startedAt = Date.now();
    this.broadcastStatus();

    // Start Recall.ai bot if meeting URL is provided
    if (meetingUrl && this.recallClient) {
      try {
        const webhookBaseUrl = process.env.WEBHOOK_BASE_URL || process.env.NEXT_PUBLIC_APP_URL;
        const bot = await this.recallClient.createBot({
          meetingUrl,
          botName: 'HCD Interview Coach',
          recordAudio: true,
          webhookUrl: webhookBaseUrl
            ? `${webhookBaseUrl}/api/webhooks/recall`
            : undefined,
        });
        this.recallBotId = bot.id;
        console.log(`[SessionRoom ${this.sessionId}] Recall bot created: ${bot.id}`);
      } catch (error) {
        console.error(`[SessionRoom ${this.sessionId}] Failed to create Recall bot:`, error);
        this.sendToClient(client, {
          type: 'session.error',
          code: 'RECALL_ERROR',
          message: 'Failed to create meeting bot. Audio capture may be limited.',
        });
      }
    }

    // Connect to OpenAI Realtime API
    try {
      this.openaiRelay = new OpenAIRelay({
        sessionId: this.sessionId,
        onUtterance: (utterance) => this.handleUtterance(utterance),
        onUtteranceUpdate: (id, text) => this.handleUtteranceUpdate(id, text),
        onCoachingEvent: (event) => this.handleCoachingEvent(event),
        onError: (error) => {
          console.error(`[SessionRoom ${this.sessionId}] OpenAI relay error:`, error);
          this.broadcastToAll({
            type: 'session.error',
            code: 'OPENAI_ERROR',
            message: 'AI connection error. Transcription may be interrupted.',
          });
        },
        onStateChange: (state) => {
          console.log(`[SessionRoom ${this.sessionId}] OpenAI relay state: ${state}`);
        },
      });

      await this.openaiRelay.connect();
      console.log(`[SessionRoom ${this.sessionId}] OpenAI relay connected`);
    } catch (error) {
      console.error(`[SessionRoom ${this.sessionId}] Failed to connect OpenAI relay:`, error);
      this.sendToClient(client, {
        type: 'session.error',
        code: 'OPENAI_ERROR',
        message: 'Failed to connect to AI service. Try starting again.',
      });
      this.status = 'ready';
      this.broadcastStatus();
    }
  }

  private handlePause(): void {
    if (this.status !== 'running') return;
    this.status = 'paused';
    this.broadcastStatus();
  }

  private handleResume(): void {
    if (this.status !== 'paused') return;
    this.status = 'running';
    this.broadcastStatus();
  }

  private async handleStop(): Promise<void> {
    if (this.status === 'ended' || this.status === 'idle') return;

    this.status = 'ending';
    this.broadcastStatus();

    // Stop Recall bot
    if (this.recallBotId && this.recallClient) {
      try {
        await this.recallClient.stopBot(this.recallBotId);
        console.log(`[SessionRoom ${this.sessionId}] Recall bot stopped`);
      } catch (error) {
        console.error(`[SessionRoom ${this.sessionId}] Error stopping Recall bot:`, error);
      }
    }

    // Disconnect OpenAI relay
    if (this.openaiRelay) {
      this.openaiRelay.disconnect();
      this.openaiRelay = null;
    }

    this.status = 'ended';
    this.broadcastStatus();

    // Clear coaching cooldown
    if (this.coachingCooldownTimer) {
      clearTimeout(this.coachingCooldownTimer);
      this.coachingCooldownTimer = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Audio Handling
  // ---------------------------------------------------------------------------

  private handleAudioChunk(base64Audio: string): void {
    if (this.status !== 'running') return;
    if (!this.openaiRelay) return;

    const pcmData = base64ToPcm(base64Audio);
    this.openaiRelay.sendAudio(pcmData);
  }

  /**
   * Handle audio data received from Recall.ai webhook.
   * Called by the webhook handler when real-time audio arrives.
   */
  handleRecallAudio(audioData: Buffer): void {
    if (this.status !== 'running') return;
    if (!this.openaiRelay) return;

    this.openaiRelay.sendAudio(audioData);
  }

  // ---------------------------------------------------------------------------
  // Transcription
  // ---------------------------------------------------------------------------

  private handleUtterance(utterance: Utterance): void {
    this.utteranceCount++;

    // Update talk time tracking
    const duration = (utterance.endTime || Date.now()) - utterance.startTime;
    if (utterance.speaker === 'interviewer') {
      this.talkTime.interviewer += duration;
    } else {
      this.talkTime.participant += duration;
    }

    // Broadcast utterance to all clients
    this.broadcastToAll({
      type: 'transcript.utterance',
      utterance,
    });

    // Broadcast finalized version
    this.broadcastToAll({
      type: 'transcript.finalized',
      utteranceId: utterance.id,
      utterance,
    });

    // Update talk time ratio
    this.broadcastTalkTime();

    // Consider coaching after each utterance (with cooldown)
    this.maybeRequestCoaching();
  }

  private handleUtteranceUpdate(utteranceId: string, text: string): void {
    this.broadcastToAll({
      type: 'transcript.update',
      utteranceId,
      text,
    });
  }

  // ---------------------------------------------------------------------------
  // Coaching
  // ---------------------------------------------------------------------------

  private handleCoachingEvent(event: CoachingEvent): void {
    if (this.coachingEventCount >= this.maxCoachingPerSession) return;

    const now = Date.now();
    if (now - this.lastCoachingTime < this.coachingCooldownMs) return;

    this.coachingEventCount++;
    this.lastCoachingTime = now;

    // Send coaching only to the interviewer
    this.broadcastToRole('interviewer', {
      type: 'coaching.prompt',
      event,
    });
  }

  private handleCoachingResponse(eventId: string, response: 'accepted' | 'dismissed' | 'snoozed'): void {
    if (response === 'dismissed') {
      this.broadcastToRole('interviewer', {
        type: 'coaching.dismiss',
        eventId,
      });
    }
    // Log the response for analytics
    console.log(`[SessionRoom ${this.sessionId}] Coaching ${eventId}: ${response}`);
  }

  private handleCoachingPull(): void {
    if (!this.openaiRelay) return;
    this.openaiRelay.requestCoaching();
  }

  private maybeRequestCoaching(): void {
    if (!this.openaiRelay) return;
    if (this.coachingEventCount >= this.maxCoachingPerSession) return;

    const now = Date.now();
    if (now - this.lastCoachingTime < this.coachingCooldownMs) return;

    // Only request coaching every few utterances to avoid excessive API calls
    if (this.utteranceCount % 5 === 0) {
      this.openaiRelay.requestCoaching();
    }
  }

  // ---------------------------------------------------------------------------
  // Topics, Insights, and Analysis
  // ---------------------------------------------------------------------------

  private handleTopicUpdate(topicName: string, status: string): void {
    const update: TopicUpdate = {
      topicName,
      status: status as TopicUpdate['status'],
    };

    this.broadcastToAll({
      type: 'analysis.topic',
      topic: update,
    });
  }

  private handleInsightFlag(
    client: ConnectedClient,
    timestamp: number,
    note?: string
  ): void {
    // Broadcast insight to all clients (observers can see interviewer's flags)
    // The actual persistence happens on the client side via API calls
    console.log(
      `[SessionRoom ${this.sessionId}] Insight flagged by ${client.role} at ${timestamp}${note ? `: ${note}` : ''}`
    );
  }

  private handleSpeakerToggle(): void {
    this.currentSpeaker = this.currentSpeaker === 'interviewer' ? 'participant' : 'interviewer';
  }

  private broadcastTalkTime(): void {
    const total = this.talkTime.interviewer + this.talkTime.participant;
    if (total === 0) return;

    const interviewerRatio = this.talkTime.interviewer / total;
    const participantRatio = this.talkTime.participant / total;

    let talkTimeStatus: TalkTimeRatio['status'] = 'good';
    // If interviewer is talking more than 40% of the time, it is a warning
    if (interviewerRatio > 0.4) talkTimeStatus = 'warning';
    if (interviewerRatio > 0.55) talkTimeStatus = 'over_talking';

    this.broadcastToAll({
      type: 'analysis.talktime',
      ratio: {
        interviewer: Math.round(interviewerRatio * 100),
        participant: Math.round(participantRatio * 100),
        status: talkTimeStatus,
      },
    });
  }

  // ---------------------------------------------------------------------------
  // Observer Features
  // ---------------------------------------------------------------------------

  private handleObserverComment(
    client: ConnectedClient,
    text: string,
    timestamp: number
  ): void {
    if (client.role !== 'observer') return;

    this.broadcastToAll({
      type: 'observer.comment',
      comment: {
        id: `comment_${Date.now()}_${client.id}`,
        authorId: client.id,
        authorName: client.userName || 'Observer',
        text,
        timestamp,
        createdAt: new Date().toISOString(),
      },
    });
  }

  private handleObserverQuestion(client: ConnectedClient, text: string): void {
    if (client.role !== 'observer') return;

    // Questions from observers are only sent to the interviewer
    this.broadcastToRole('interviewer', {
      type: 'observer.question',
      question: text,
      from: client.userName || 'Observer',
    });
  }

  // ---------------------------------------------------------------------------
  // Broadcasting
  // ---------------------------------------------------------------------------

  /**
   * Send a message to all connected clients.
   */
  broadcastToAll(message: ServerMessage): void {
    const encoded = encodeMessage(message);
    for (const client of this.clients.values()) {
      if (client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(encoded);
      }
    }
  }

  /**
   * Send a message to all clients with a specific role.
   */
  broadcastToRole(role: ClientRole, message: ServerMessage): void {
    const encoded = encodeMessage(message);
    for (const client of this.clients.values()) {
      if (client.role === role && client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(encoded);
      }
    }
  }

  /**
   * Send a message to a specific client.
   */
  private sendToClient(client: ConnectedClient, message: ServerMessage): void {
    if (client.ws.readyState === WebSocket.OPEN) {
      client.ws.send(encodeMessage(message));
    }
  }

  private broadcastStatus(): void {
    this.broadcastToAll({
      type: 'session.status',
      status: this.status,
      sessionId: this.sessionId,
    });
  }

  private broadcastObserverCount(): void {
    const count = Array.from(this.clients.values()).filter(c => c.role === 'observer').length;
    this.broadcastToAll({
      type: 'observer.count',
      count,
    });
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /**
   * Clean up all resources for this room.
   */
  async destroy(): Promise<void> {
    await this.handleStop();

    // Close all client connections
    for (const client of this.clients.values()) {
      if (client.ws.readyState === WebSocket.OPEN) {
        client.ws.close(1000, 'Session room closing');
      }
    }
    this.clients.clear();
  }
}

// =============================================================================
// WebSocket Server Manager
// =============================================================================

/**
 * Manages the WebSocket server, session rooms, and client connections.
 * Works in `noServer` mode — the HTTP server handles the upgrade request
 * and passes connections here.
 */
export class WSServerManager {
  private readonly wss: WebSocketServer;
  private readonly rooms: Map<string, SessionRoom> = new Map();
  private heartbeatInterval: ReturnType<typeof setInterval> | null = null;
  private readonly heartbeatIntervalMs = 30_000; // 30s ping interval
  private readonly clientTimeoutMs = 60_000; // 60s before considering disconnected
  private clientIdCounter = 0;

  constructor() {
    this.wss = new WebSocketServer({ noServer: true });
    this.startHeartbeat();
  }

  /**
   * Handle a WebSocket upgrade request.
   * Called from the HTTP server when a request to /ws is received.
   */
  handleUpgrade(
    request: IncomingMessage,
    socket: import('stream').Duplex,
    head: Buffer
  ): void {
    // Authenticate the connection
    const params = this.parseConnectionParams(request);
    if (!params) {
      socket.write('HTTP/1.1 401 Unauthorized\r\n\r\n');
      socket.destroy();
      return;
    }

    this.wss.handleUpgrade(request, socket, head, (ws) => {
      this.onConnection(ws, params);
    });
  }

  /**
   * Handle a new WebSocket connection after upgrade.
   */
  private onConnection(
    ws: WebSocket,
    params: { sessionId: string; role: ClientRole; token: string; userName?: string }
  ): void {
    const clientId = `client_${++this.clientIdCounter}_${Date.now()}`;

    const client: ConnectedClient = {
      ws,
      id: clientId,
      role: params.role,
      sessionId: params.sessionId,
      joinedAt: Date.now(),
      lastPingAt: Date.now(),
      isAlive: true,
      userName: params.userName,
    };

    // Get or create session room
    let room = this.rooms.get(params.sessionId);
    if (!room) {
      room = new SessionRoom(params.sessionId);
      this.rooms.set(params.sessionId, room);
      console.log(`[WSServer] Created room for session ${params.sessionId}`);
    }

    room.addClient(client);

    // Handle messages
    ws.on('message', (data: WebSocket.Data) => {
      const raw = typeof data === 'string' ? data : data.toString();
      room!.handleMessage(clientId, raw).catch((error) => {
        console.error(`[WSServer] Error handling message from ${clientId}:`, error);
      });
    });

    // Handle pong (response to our heartbeat ping)
    ws.on('pong', () => {
      client.isAlive = true;
      client.lastPingAt = Date.now();
    });

    // Handle close
    ws.on('close', (code: number, reason: Buffer) => {
      console.log(`[WSServer] Client ${clientId} disconnected: ${code} ${reason.toString()}`);
      const isEmpty = room!.removeClient(clientId);

      // Clean up empty rooms after a delay (allow reconnection)
      if (isEmpty) {
        setTimeout(() => {
          const currentRoom = this.rooms.get(params.sessionId);
          if (currentRoom && currentRoom.clientCount === 0) {
            currentRoom.destroy().catch(console.error);
            this.rooms.delete(params.sessionId);
            console.log(`[WSServer] Cleaned up empty room ${params.sessionId}`);
          }
        }, 30_000);
      }
    });

    // Handle errors
    ws.on('error', (error: Error) => {
      console.error(`[WSServer] Client ${clientId} error:`, error.message);
    });
  }

  // ---------------------------------------------------------------------------
  // Connection Authentication
  // ---------------------------------------------------------------------------

  private parseConnectionParams(
    request: IncomingMessage
  ): { sessionId: string; role: ClientRole; token: string; userName?: string } | null {
    const url = new URL(request.url || '', `http://${request.headers.host || 'localhost'}`);

    const sessionId = url.searchParams.get('sessionId');
    const token = url.searchParams.get('token');
    const roleParam = url.searchParams.get('role') || 'observer';
    const userName = url.searchParams.get('userName') || undefined;

    if (!sessionId) {
      console.warn('[WSServer] Connection rejected: missing sessionId');
      return null;
    }

    if (!token) {
      // Also check for token in cookies
      const cookieToken = this.extractTokenFromCookies(request);
      if (!cookieToken) {
        console.warn('[WSServer] Connection rejected: missing token');
        return null;
      }
      return {
        sessionId,
        role: roleParam === 'interviewer' ? 'interviewer' : 'observer',
        token: cookieToken,
        userName,
      };
    }

    // Validate the token
    if (!this.validateToken(token, sessionId)) {
      console.warn('[WSServer] Connection rejected: invalid token');
      return null;
    }

    return {
      sessionId,
      role: roleParam === 'interviewer' ? 'interviewer' : 'observer',
      token,
      userName,
    };
  }

  private extractTokenFromCookies(request: IncomingMessage): string | null {
    const cookieHeader = request.headers.cookie;
    if (!cookieHeader) return null;

    const cookies = cookieHeader.split(';').reduce(
      (acc, cookie) => {
        const [key, value] = cookie.trim().split('=');
        if (key && value) {
          acc[key] = decodeURIComponent(value);
        }
        return acc;
      },
      {} as Record<string, string>
    );

    return cookies['session-token'] || cookies['better-auth.session_token'] || null;
  }

  private validateToken(token: string, _sessionId: string): boolean {
    // In production, validate the token against your auth system (e.g., better-auth).
    // For now, accept any non-empty token. The actual auth validation should be
    // integrated with the @hcd/auth package.
    if (!token || token.length < 1) {
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Room Access
  // ---------------------------------------------------------------------------

  /**
   * Get a session room by ID. Used by webhook handlers to forward events.
   */
  getRoom(sessionId: string): SessionRoom | undefined {
    return this.rooms.get(sessionId);
  }

  /**
   * Get all active session room states.
   */
  getRoomStates(): SessionRoomState[] {
    return Array.from(this.rooms.values()).map((room) => room.getState());
  }

  /**
   * Get the total number of active rooms.
   */
  get roomCount(): number {
    return this.rooms.size;
  }

  /**
   * Get the total number of connected clients across all rooms.
   */
  get totalClientCount(): number {
    let count = 0;
    for (const room of this.rooms.values()) {
      count += room.clientCount;
    }
    return count;
  }

  // ---------------------------------------------------------------------------
  // Heartbeat
  // ---------------------------------------------------------------------------

  private startHeartbeat(): void {
    this.heartbeatInterval = setInterval(() => {
      for (const room of this.rooms.values()) {
        // The room doesn't expose clients directly; we use wss.clients instead
      }

      // Use the underlying wss to iterate all clients
      this.wss.clients.forEach((ws) => {
        if (ws.readyState !== WebSocket.OPEN) return;

        // The ws library supports ping/pong natively
        ws.ping();
      });
    }, this.heartbeatIntervalMs);
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  /**
   * Gracefully shut down the WebSocket server and all sessions.
   */
  async shutdown(): Promise<void> {
    console.log('[WSServer] Shutting down...');

    if (this.heartbeatInterval) {
      clearInterval(this.heartbeatInterval);
      this.heartbeatInterval = null;
    }

    // Destroy all rooms
    const destroyPromises = Array.from(this.rooms.values()).map((room) =>
      room.destroy().catch(console.error)
    );
    await Promise.all(destroyPromises);
    this.rooms.clear();

    // Close the WebSocket server
    return new Promise((resolve) => {
      this.wss.close(() => {
        console.log('[WSServer] WebSocket server closed');
        resolve();
      });
    });
  }
}

// =============================================================================
// Singleton
// =============================================================================

let wsManager: WSServerManager | null = null;

/**
 * Get or create the global WSServerManager instance.
 */
export function getWSManager(): WSServerManager {
  if (!wsManager) {
    wsManager = new WSServerManager();
  }
  return wsManager;
}
