// =============================================================================
// OpenAI Realtime API Relay
// Server-side WebSocket connection to OpenAI for transcription and coaching
// =============================================================================

import WebSocket from 'ws';
import { VoiceActivityDetector, pcmToBase64, base64ToPcm, measureAudioLevel } from './audio-processor';
import type { ServerMessage, Utterance, CoachingEvent } from '@hcd/ws-protocol';

// =============================================================================
// Types
// =============================================================================

const OPENAI_REALTIME_URL = 'wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview';

export interface OpenAIRelayConfig {
  /** OpenAI API key. Defaults to OPENAI_API_KEY env var. */
  apiKey?: string;
  /** Session ID this relay is associated with. */
  sessionId: string;
  /** Interview topics for contextual coaching. */
  topics?: string[];
  /** Cultural context hints for coaching. */
  culturalContext?: string;
  /** Callback when a transcription utterance is produced. */
  onUtterance?: (utterance: Utterance) => void;
  /** Callback when an utterance is updated (partial). */
  onUtteranceUpdate?: (utteranceId: string, text: string) => void;
  /** Callback when a coaching event is generated. */
  onCoachingEvent?: (event: CoachingEvent) => void;
  /** Callback when an error occurs. */
  onError?: (error: Error) => void;
  /** Callback when the connection state changes. */
  onStateChange?: (state: RelayState) => void;
  /** Energy threshold for VAD silence detection. Default: 0.008 */
  vadThreshold?: number;
  /** Maximum consecutive silent frames before stopping audio relay. Default: 150 (~3s) */
  maxSilentFrames?: number;
}

export type RelayState = 'disconnected' | 'connecting' | 'connected' | 'configured' | 'error' | 'closed';

interface OpenAIRealtimeEvent {
  type: string;
  [key: string]: unknown;
}

// =============================================================================
// Coaching System Prompt
// =============================================================================

function buildSystemPrompt(topics?: string[], culturalContext?: string): string {
  const topicList = topics && topics.length > 0
    ? `\n\nInterview Topics to Cover:\n${topics.map((t, i) => `${i + 1}. ${t}`).join('\n')}`
    : '';

  const culturalNote = culturalContext
    ? `\n\nCultural Context: ${culturalContext}`
    : '';

  return `You are an expert UX research interview coach operating in "silence-first" mode. You are listening to a live interview between a UX researcher (interviewer) and a participant.

Your role is to provide brief, actionable coaching prompts ONLY when genuinely needed. Most of the time, you should remain silent and let the conversation flow naturally.

Guidelines:
- Stay silent unless you detect a clear coaching opportunity
- When you do speak, keep prompts under 20 words
- Focus on: missed follow-up opportunities, leading questions, topic coverage gaps, rapport building
- Never interrupt or suggest interrupting the participant
- Respect the interviewer's expertise — they may have good reasons for their approach
- Flag potential bias in question framing
- Track which topics have been covered vs missed

Coaching prompt types:
- FOLLOW_UP: "Consider asking: [brief follow-up question]"
- PROBE_DEEPER: "They mentioned [X] — could explore further"
- TOPIC_GAP: "Haven't covered [topic] yet"
- LEADING_ALERT: "That question may be leading — try rephrasing"
- SILENCE_OK: "Good pause — let them think"
- RAPPORT: "Good rapport building moment"

When providing coaching, respond with a JSON object:
{
  "type": "coaching",
  "promptType": "FOLLOW_UP|PROBE_DEEPER|TOPIC_GAP|LEADING_ALERT|SILENCE_OK|RAPPORT",
  "promptText": "Brief coaching text",
  "confidence": 0.0-1.0,
  "explanation": "Why this coaching is relevant"
}

When providing transcription corrections or speaker identification, respond with:
{
  "type": "transcription",
  "speaker": "interviewer|participant",
  "correction": "corrected text if needed"
}${topicList}${culturalNote}`;
}

// =============================================================================
// OpenAI Realtime Relay
// =============================================================================

export class OpenAIRelay {
  private ws: WebSocket | null = null;
  private readonly config: Required<
    Pick<OpenAIRelayConfig, 'sessionId' | 'vadThreshold' | 'maxSilentFrames'>
  > & OpenAIRelayConfig;
  private readonly apiKey: string;
  private state: RelayState = 'disconnected';
  private vad: VoiceActivityDetector;
  private consecutiveSilentFrames = 0;
  private isSendingAudio = false;
  private utteranceCounter = 0;
  private reconnectAttempts = 0;
  private readonly maxReconnectAttempts = 3;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private pendingUtteranceId: string | null = null;
  private pendingUtteranceText = '';
  private pendingUtteranceStartTime = 0;

  constructor(config: OpenAIRelayConfig) {
    this.apiKey = config.apiKey || process.env.OPENAI_API_KEY || '';
    if (!this.apiKey) {
      throw new Error(
        'OpenAI API key is required. Set OPENAI_API_KEY environment variable or pass it to the constructor.'
      );
    }

    this.config = {
      vadThreshold: 0.008,
      maxSilentFrames: 150,
      ...config,
    };

    this.vad = new VoiceActivityDetector({
      energyThreshold: this.config.vadThreshold,
      silenceFrames: this.config.maxSilentFrames,
    });
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /**
   * Connect to the OpenAI Realtime API via WebSocket.
   */
  async connect(): Promise<void> {
    if (this.state === 'connected' || this.state === 'configured') {
      return;
    }

    this.setState('connecting');

    return new Promise((resolve, reject) => {
      try {
        this.ws = new WebSocket(OPENAI_REALTIME_URL, {
          headers: {
            Authorization: `Bearer ${this.apiKey}`,
            'OpenAI-Beta': 'realtime=v1',
          },
        });

        const connectionTimeout = setTimeout(() => {
          if (this.state === 'connecting') {
            this.ws?.close();
            reject(new Error('Connection to OpenAI Realtime API timed out'));
          }
        }, 15000);

        this.ws.on('open', () => {
          clearTimeout(connectionTimeout);
          this.setState('connected');
          this.reconnectAttempts = 0;
          this.configureSession();
          resolve();
        });

        this.ws.on('message', (data: WebSocket.Data) => {
          try {
            const event = JSON.parse(data.toString()) as OpenAIRealtimeEvent;
            this.handleRealtimeEvent(event);
          } catch (error) {
            console.error('[OpenAIRelay] Failed to parse message:', error);
          }
        });

        this.ws.on('error', (error: Error) => {
          clearTimeout(connectionTimeout);
          console.error('[OpenAIRelay] WebSocket error:', error.message);
          this.config.onError?.(error);

          if (this.state === 'connecting') {
            reject(error);
          }
        });

        this.ws.on('close', (code: number, reason: Buffer) => {
          clearTimeout(connectionTimeout);
          const reasonStr = reason.toString();
          console.log(`[OpenAIRelay] Connection closed: ${code} ${reasonStr}`);

          if (this.state !== 'closed') {
            this.setState('disconnected');
            this.attemptReconnect();
          }
        });
      } catch (error) {
        this.setState('error');
        reject(error);
      }
    });
  }

  /**
   * Configure the OpenAI Realtime session with coaching prompt and audio settings.
   */
  private configureSession(): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;

    const sessionConfig: OpenAIRealtimeEvent = {
      type: 'session.update',
      session: {
        modalities: ['text'],
        instructions: buildSystemPrompt(this.config.topics, this.config.culturalContext),
        input_audio_format: 'pcm16',
        input_audio_transcription: {
          model: 'whisper-1',
        },
        turn_detection: {
          type: 'server_vad',
          threshold: 0.5,
          prefix_padding_ms: 300,
          silence_duration_ms: 500,
        },
        temperature: 0.6,
        max_response_output_tokens: 300,
      },
    };

    this.sendEvent(sessionConfig);
    this.setState('configured');
  }

  /**
   * Send audio data to OpenAI for transcription and coaching.
   * Includes VAD-based silence detection to avoid sending silent audio.
   * @param pcmData - PCM 16-bit LE audio buffer
   */
  sendAudio(pcmData: Buffer): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;
    if (this.state !== 'configured') return;

    // Run VAD to detect speech vs silence
    const vadResult = this.vad.processFrame(pcmData);

    if (vadResult.isSpeech) {
      this.consecutiveSilentFrames = 0;

      if (!this.isSendingAudio) {
        this.isSendingAudio = true;
      }

      // Send audio to OpenAI
      this.sendEvent({
        type: 'input_audio_buffer.append',
        audio: pcmToBase64(pcmData),
      });
    } else {
      this.consecutiveSilentFrames++;

      // Continue sending for a short grace period after speech ends
      if (this.isSendingAudio && this.consecutiveSilentFrames < 25) {
        this.sendEvent({
          type: 'input_audio_buffer.append',
          audio: pcmToBase64(pcmData),
        });
      } else if (this.isSendingAudio) {
        // Commit the audio buffer after sustained silence
        this.isSendingAudio = false;
        this.sendEvent({ type: 'input_audio_buffer.commit' });
      }
      // If not currently sending audio, skip (cost optimization)
    }
  }

  /**
   * Request a coaching response from OpenAI based on the current conversation context.
   */
  requestCoaching(): void {
    if (!this.ws || this.ws.readyState !== WebSocket.OPEN) return;

    this.sendEvent({
      type: 'response.create',
      response: {
        modalities: ['text'],
        instructions: 'Analyze the recent conversation and provide a coaching prompt if appropriate. If no coaching is needed, respond with {"type": "coaching", "promptType": "SILENCE_OK", "promptText": "Conversation flowing well", "confidence": 0.3}',
      },
    });
  }

  /**
   * Disconnect from the OpenAI Realtime API.
   */
  disconnect(): void {
    this.setState('closed');

    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.ws) {
      this.ws.removeAllListeners();
      if (this.ws.readyState === WebSocket.OPEN || this.ws.readyState === WebSocket.CONNECTING) {
        this.ws.close(1000, 'Client disconnect');
      }
      this.ws = null;
    }

    this.vad.reset();
    this.consecutiveSilentFrames = 0;
    this.isSendingAudio = false;
  }

  /** Get current relay state. */
  getState(): RelayState {
    return this.state;
  }

  // ---------------------------------------------------------------------------
  // Event Handling
  // ---------------------------------------------------------------------------

  private handleRealtimeEvent(event: OpenAIRealtimeEvent): void {
    switch (event.type) {
      case 'session.created':
        console.log('[OpenAIRelay] Session created');
        break;

      case 'session.updated':
        console.log('[OpenAIRelay] Session configured');
        break;

      case 'conversation.item.input_audio_transcription.completed': {
        const transcript = event.transcript as string | undefined;
        if (transcript && transcript.trim()) {
          this.handleTranscription(transcript.trim());
        }
        break;
      }

      case 'conversation.item.input_audio_transcription.delta': {
        const delta = event.delta as string | undefined;
        if (delta && this.pendingUtteranceId) {
          this.pendingUtteranceText += delta;
          this.config.onUtteranceUpdate?.(this.pendingUtteranceId, this.pendingUtteranceText);
        }
        break;
      }

      case 'input_audio_buffer.speech_started':
        this.pendingUtteranceId = `utt_${this.config.sessionId}_${++this.utteranceCounter}`;
        this.pendingUtteranceText = '';
        this.pendingUtteranceStartTime = Date.now();
        break;

      case 'input_audio_buffer.speech_stopped':
        // Audio buffer will be committed by the server
        break;

      case 'response.text.delta': {
        // Coaching response coming in
        break;
      }

      case 'response.text.done': {
        const text = event.text as string | undefined;
        if (text) {
          this.handleCoachingResponse(text);
        }
        break;
      }

      case 'response.done': {
        const response = event.response as Record<string, unknown> | undefined;
        if (response?.output) {
          const outputs = response.output as Array<Record<string, unknown>>;
          for (const output of outputs) {
            if (output.type === 'message') {
              const content = output.content as Array<Record<string, unknown>> | undefined;
              if (content) {
                for (const item of content) {
                  if (item.type === 'text' && typeof item.text === 'string') {
                    this.handleCoachingResponse(item.text);
                  }
                }
              }
            }
          }
        }
        break;
      }

      case 'error': {
        const errorMsg = (event.error as Record<string, unknown> | undefined)?.message as string
          || 'Unknown OpenAI Realtime error';
        console.error('[OpenAIRelay] Error event:', errorMsg);
        this.config.onError?.(new Error(errorMsg));
        break;
      }

      case 'rate_limits.updated':
        // Track rate limit info if needed
        break;

      default:
        // Unhandled event type — ignore
        break;
    }
  }

  private handleTranscription(text: string): void {
    const utteranceId = this.pendingUtteranceId
      || `utt_${this.config.sessionId}_${++this.utteranceCounter}`;

    const utterance: Utterance = {
      id: utteranceId,
      sessionId: this.config.sessionId,
      speaker: 'participant', // Default — can be corrected by coaching response
      text,
      startTime: this.pendingUtteranceStartTime || Date.now(),
      endTime: Date.now(),
      confidence: 0.9,
    };

    this.config.onUtterance?.(utterance);

    // Reset pending state
    this.pendingUtteranceId = null;
    this.pendingUtteranceText = '';
    this.pendingUtteranceStartTime = 0;
  }

  private handleCoachingResponse(text: string): void {
    try {
      // Try to parse as JSON coaching response
      const parsed = JSON.parse(text) as Record<string, unknown>;

      if (parsed.type === 'coaching') {
        const event: CoachingEvent = {
          id: `coach_${this.config.sessionId}_${Date.now()}`,
          sessionId: this.config.sessionId,
          promptType: (parsed.promptType as string) || 'FOLLOW_UP',
          promptText: (parsed.promptText as string) || text,
          confidence: (parsed.confidence as number) || 0.5,
          explanation: parsed.explanation as string | undefined,
          displayedAt: new Date().toISOString(),
        };

        // Only forward coaching events above the confidence threshold (0.85)
        if ((event.confidence || 0) >= 0.85) {
          this.config.onCoachingEvent?.(event);
        }
      }
      // Ignore transcription-type responses; they are handled via the transcription events
    } catch {
      // If not valid JSON, treat as a plain-text coaching suggestion
      if (text.length > 5 && text.length < 200) {
        const event: CoachingEvent = {
          id: `coach_${this.config.sessionId}_${Date.now()}`,
          sessionId: this.config.sessionId,
          promptType: 'FOLLOW_UP',
          promptText: text,
          confidence: 0.7,
          displayedAt: new Date().toISOString(),
        };

        this.config.onCoachingEvent?.(event);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  private sendEvent(event: OpenAIRealtimeEvent): void {
    if (this.ws && this.ws.readyState === WebSocket.OPEN) {
      this.ws.send(JSON.stringify(event));
    }
  }

  private setState(state: RelayState): void {
    if (this.state !== state) {
      this.state = state;
      this.config.onStateChange?.(state);
    }
  }

  private attemptReconnect(): void {
    if (this.state === 'closed') return;
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.error('[OpenAIRelay] Max reconnect attempts reached');
      this.setState('error');
      this.config.onError?.(new Error('Failed to reconnect to OpenAI Realtime API'));
      return;
    }

    this.reconnectAttempts++;
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts), 16000);
    console.log(`[OpenAIRelay] Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    this.reconnectTimer = setTimeout(async () => {
      try {
        await this.connect();
      } catch (error) {
        console.error('[OpenAIRelay] Reconnect failed:', error);
      }
    }, delay);
  }
}
