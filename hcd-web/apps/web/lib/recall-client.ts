// =============================================================================
// Recall.ai Meeting Bot API Client
// Manages bot lifecycle for meeting audio capture
// https://docs.recall.ai/reference
// =============================================================================

import { createHmac } from 'crypto';

const RECALL_BASE_URL = 'https://api.recall.ai/api/v1';

// =============================================================================
// Types
// =============================================================================

export interface RecallBotConfig {
  /** The meeting URL to join (Zoom, Google Meet, Teams, etc.) */
  meetingUrl: string;
  /** Display name for the bot in the meeting */
  botName?: string;
  /** Whether to record the meeting audio */
  recordAudio?: boolean;
  /** Whether to record the meeting video */
  recordVideo?: boolean;
  /** Webhook URL for real-time events */
  webhookUrl?: string;
  /** Real-time transcription configuration */
  transcription?: {
    provider: 'assembly_ai' | 'deepgram' | 'rev' | 'default';
    language?: string;
  };
  /** Output media configuration */
  outputMedia?: {
    camera?: {
      kind: 'jpeg';
      config?: Record<string, unknown>;
    };
  };
}

export interface RecallBot {
  id: string;
  meeting_url: string;
  bot_name: string;
  status: RecallBotStatus;
  status_changes: Array<{
    code: string;
    message: string;
    created_at: string;
  }>;
  created_at: string;
  recording?: {
    id: string;
    url?: string;
    status: string;
  };
  media_retention_end?: string;
}

export type RecallBotStatus =
  | 'ready'
  | 'joining_call'
  | 'in_waiting_room'
  | 'in_call_not_recording'
  | 'in_call_recording'
  | 'call_ended'
  | 'done'
  | 'fatal'
  | 'analysis_done';

export interface RecallRecording {
  id: string;
  bot_id: string;
  url: string;
  duration?: number;
  transcript?: RecallTranscriptSegment[];
}

export interface RecallTranscriptSegment {
  speaker: string;
  text: string;
  start_time: number;
  end_time: number;
  language?: string;
}

export interface RecallWebhookEvent {
  event: string;
  data: {
    bot_id: string;
    status?: {
      code: string;
      message?: string;
    };
    recording?: {
      id: string;
      url?: string;
    };
    transcript?: RecallTranscriptSegment;
    [key: string]: unknown;
  };
}

export interface RecallListResponse<T> {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
}

// =============================================================================
// Recall.ai Client
// =============================================================================

export class RecallClient {
  private readonly apiKey: string;
  private readonly baseUrl: string;

  constructor(apiKey?: string, baseUrl?: string) {
    this.apiKey = apiKey || process.env.RECALL_API_KEY || '';
    this.baseUrl = baseUrl || RECALL_BASE_URL;

    if (!this.apiKey) {
      throw new Error(
        'Recall API key is required. Set RECALL_API_KEY environment variable or pass it to the constructor.'
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Bot Management
  // ---------------------------------------------------------------------------

  /**
   * Create a bot and have it join a meeting.
   * @param config - Bot configuration including meeting URL
   * @returns The created bot object
   */
  async createBot(config: RecallBotConfig): Promise<RecallBot> {
    const body: Record<string, unknown> = {
      meeting_url: config.meetingUrl,
      bot_name: config.botName || 'HCD Interview Coach',
      recording_mode: config.recordAudio !== false ? 'audio_only' : 'none',
    };

    if (config.webhookUrl) {
      body.real_time_media = {
        websocket_audio_output_url: config.webhookUrl,
      };
    }

    if (config.transcription) {
      body.transcription_options = {
        provider: config.transcription.provider,
        language: config.transcription.language || 'en',
      };
    }

    if (config.outputMedia) {
      body.output_media = config.outputMedia;
    }

    return this.request<RecallBot>('POST', '/bot/', body);
  }

  /**
   * Get the current status and details of a bot.
   * @param botId - The bot ID
   */
  async getBotStatus(botId: string): Promise<RecallBot> {
    return this.request<RecallBot>('GET', `/bot/${botId}/`);
  }

  /**
   * List all bots, optionally filtered.
   * @param params - Optional query parameters for filtering
   */
  async listBots(params?: {
    meeting_url?: string;
    status?: RecallBotStatus;
    created_after?: string;
    created_before?: string;
    limit?: number;
    offset?: number;
  }): Promise<RecallListResponse<RecallBot>> {
    const query = params ? this.buildQueryString(params) : '';
    return this.request<RecallListResponse<RecallBot>>('GET', `/bot/${query}`);
  }

  /**
   * Stop the bot and remove it from the meeting.
   * @param botId - The bot ID
   */
  async stopBot(botId: string): Promise<void> {
    await this.request<void>('POST', `/bot/${botId}/leave_call/`);
  }

  /**
   * Send a chat message via the bot (if supported by the meeting platform).
   * @param botId - The bot ID
   * @param message - The message to send
   */
  async sendChat(botId: string, message: string): Promise<void> {
    await this.request<void>('POST', `/bot/${botId}/send_chat_message/`, {
      message,
    });
  }

  // ---------------------------------------------------------------------------
  // Recording
  // ---------------------------------------------------------------------------

  /**
   * Get the recording for a bot after the meeting has ended.
   * @param botId - The bot ID
   * @returns Recording details including download URL
   */
  async getRecording(botId: string): Promise<RecallRecording> {
    const bot = await this.getBotStatus(botId);
    if (!bot.recording) {
      throw new RecallError('No recording available for this bot', 'NO_RECORDING');
    }

    return this.request<RecallRecording>('GET', `/recording/${bot.recording.id}/`);
  }

  /**
   * Get the transcript for a completed recording.
   * @param botId - The bot ID
   */
  async getTranscript(botId: string): Promise<RecallTranscriptSegment[]> {
    const response = await this.request<{ results: RecallTranscriptSegment[] }>(
      'GET',
      `/bot/${botId}/transcript/`
    );
    return response.results;
  }

  // ---------------------------------------------------------------------------
  // Webhook Verification
  // ---------------------------------------------------------------------------

  /**
   * Verify a Recall.ai webhook signature.
   * @param payload - Raw request body as string
   * @param signature - The signature from the `x-recall-signature` header
   * @param secret - Webhook signing secret (defaults to RECALL_WEBHOOK_SECRET env var)
   * @returns true if the signature is valid
   */
  static verifyWebhookSignature(
    payload: string,
    signature: string,
    secret?: string
  ): boolean {
    const webhookSecret = secret || process.env.RECALL_WEBHOOK_SECRET;
    if (!webhookSecret) {
      console.warn(
        '[RecallClient] No webhook secret configured. Skipping signature verification.'
      );
      return true;
    }

    const expectedSignature = createHmac('sha256', webhookSecret)
      .update(payload)
      .digest('hex');

    // Timing-safe comparison
    if (expectedSignature.length !== signature.length) {
      return false;
    }

    const expectedBuffer = Buffer.from(expectedSignature, 'hex');
    const actualBuffer = Buffer.from(signature, 'hex');

    if (expectedBuffer.length !== actualBuffer.length) {
      return false;
    }

    let result = 0;
    for (let i = 0; i < expectedBuffer.length; i++) {
      result |= expectedBuffer[i]! ^ actualBuffer[i]!;
    }
    return result === 0;
  }

  // ---------------------------------------------------------------------------
  // Internal HTTP
  // ---------------------------------------------------------------------------

  private async request<T>(
    method: string,
    path: string,
    body?: Record<string, unknown>
  ): Promise<T> {
    const url = `${this.baseUrl}${path}`;

    const headers: Record<string, string> = {
      Authorization: `Token ${this.apiKey}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };

    const options: RequestInit = {
      method,
      headers,
    };

    if (body && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
      options.body = JSON.stringify(body);
    }

    let response: Response;
    try {
      response = await fetch(url, options);
    } catch (error) {
      throw new RecallError(
        `Network error communicating with Recall.ai: ${error instanceof Error ? error.message : String(error)}`,
        'NETWORK_ERROR'
      );
    }

    if (!response.ok) {
      let errorBody: string;
      try {
        errorBody = await response.text();
      } catch {
        errorBody = 'Unable to read error response body';
      }

      throw new RecallError(
        `Recall API error ${response.status}: ${errorBody}`,
        `HTTP_${response.status}`,
        response.status
      );
    }

    // Some endpoints return no content (204)
    if (response.status === 204 || response.headers.get('content-length') === '0') {
      return undefined as unknown as T;
    }

    return response.json() as Promise<T>;
  }

  private buildQueryString(params: Record<string, unknown>): string {
    const entries = Object.entries(params).filter(
      ([, value]) => value !== undefined && value !== null
    );
    if (entries.length === 0) return '';

    const queryParts = entries.map(
      ([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`
    );
    return `?${queryParts.join('&')}`;
  }
}

// =============================================================================
// Error Type
// =============================================================================

export class RecallError extends Error {
  readonly code: string;
  readonly statusCode?: number;

  constructor(message: string, code: string, statusCode?: number) {
    super(message);
    this.name = 'RecallError';
    this.code = code;
    this.statusCode = statusCode;
  }
}
