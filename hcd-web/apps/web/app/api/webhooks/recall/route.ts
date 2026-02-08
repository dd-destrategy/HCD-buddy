// =============================================================================
// Recall.ai Webhook Handler
// Receives real-time events from Recall.ai about bot status and media
// =============================================================================

import { NextRequest, NextResponse } from 'next/server';
import { RecallClient, type RecallWebhookEvent } from '@/lib/recall-client';
import { getWSManager } from '@/lib/ws-server';

// =============================================================================
// POST /api/webhooks/recall
// =============================================================================

export async function POST(request: NextRequest): Promise<NextResponse> {
  // ---------------------------------------------------------------------------
  // Verify webhook signature
  // ---------------------------------------------------------------------------

  const signature = request.headers.get('x-recall-signature') || '';
  const rawBody = await request.text();

  if (process.env.RECALL_WEBHOOK_SECRET) {
    const isValid = RecallClient.verifyWebhookSignature(
      rawBody,
      signature,
      process.env.RECALL_WEBHOOK_SECRET
    );

    if (!isValid) {
      console.warn('[Webhook/Recall] Invalid webhook signature');
      return NextResponse.json(
        { error: 'Invalid signature' },
        { status: 401 }
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Parse and route the event
  // ---------------------------------------------------------------------------

  let event: RecallWebhookEvent;
  try {
    event = JSON.parse(rawBody) as RecallWebhookEvent;
  } catch {
    console.error('[Webhook/Recall] Failed to parse webhook body');
    return NextResponse.json(
      { error: 'Invalid JSON body' },
      { status: 400 }
    );
  }

  const botId = event.data?.bot_id;
  if (!botId) {
    console.warn('[Webhook/Recall] Event missing bot_id:', event.event);
    return NextResponse.json(
      { error: 'Missing bot_id' },
      { status: 400 }
    );
  }

  console.log(`[Webhook/Recall] Event: ${event.event} for bot ${botId}`);

  // Find the session room that owns this bot
  const wsManager = getWSManager();
  const room = findRoomByBotId(wsManager, botId);

  switch (event.event) {
    // -------------------------------------------------------------------------
    // Bot joined the meeting call
    // -------------------------------------------------------------------------
    case 'bot.join_call': {
      console.log(`[Webhook/Recall] Bot ${botId} joined the call`);
      if (room) {
        room.broadcastToAll({
          type: 'session.status',
          status: 'running',
          sessionId: room.sessionId,
        });
      }
      break;
    }

    // -------------------------------------------------------------------------
    // Bot left the meeting call
    // -------------------------------------------------------------------------
    case 'bot.leave_call': {
      console.log(`[Webhook/Recall] Bot ${botId} left the call`);
      if (room) {
        room.broadcastToAll({
          type: 'session.status',
          status: 'ending',
          sessionId: room.sessionId,
        });
      }
      break;
    }

    // -------------------------------------------------------------------------
    // Bot status changed
    // -------------------------------------------------------------------------
    case 'bot.status_change': {
      const statusCode = event.data.status?.code;
      const statusMessage = event.data.status?.message;
      console.log(
        `[Webhook/Recall] Bot ${botId} status: ${statusCode} - ${statusMessage || ''}`
      );

      if (room) {
        // Map Recall status to our session status
        const sessionStatus = mapRecallStatus(statusCode);
        if (sessionStatus) {
          room.broadcastToAll({
            type: 'session.status',
            status: sessionStatus,
            sessionId: room.sessionId,
          });
        }

        // Forward errors
        if (statusCode === 'fatal') {
          room.broadcastToAll({
            type: 'session.error',
            code: 'RECALL_BOT_FATAL',
            message: statusMessage || 'Meeting bot encountered a fatal error',
          });
        }
      }
      break;
    }

    // -------------------------------------------------------------------------
    // Recording/media processing complete
    // -------------------------------------------------------------------------
    case 'bot.media.done': {
      const recordingUrl = event.data.recording?.url;
      console.log(
        `[Webhook/Recall] Bot ${botId} media done. Recording: ${recordingUrl ? 'available' : 'not available'}`
      );

      if (room) {
        room.broadcastToAll({
          type: 'session.status',
          status: 'ended',
          sessionId: room.sessionId,
        });
      }
      break;
    }

    // -------------------------------------------------------------------------
    // Real-time transcript from Recall's own transcription
    // -------------------------------------------------------------------------
    case 'bot.transcription': {
      const transcript = event.data.transcript;
      if (transcript && room) {
        room.broadcastToAll({
          type: 'transcript.utterance',
          utterance: {
            id: `recall_${Date.now()}`,
            sessionId: room.sessionId,
            speaker: transcript.speaker === 'User' ? 'interviewer' : 'participant',
            text: transcript.text,
            startTime: transcript.start_time * 1000,
            endTime: transcript.end_time * 1000,
          },
        });
      }
      break;
    }

    // -------------------------------------------------------------------------
    // Real-time audio data from Recall
    // -------------------------------------------------------------------------
    case 'bot.audio': {
      const audioBase64 = event.data.audio as string | undefined;
      if (audioBase64 && room) {
        const audioBuffer = Buffer.from(audioBase64, 'base64');
        room.handleRecallAudio(audioBuffer);
      }
      break;
    }

    default:
      console.log(`[Webhook/Recall] Unhandled event: ${event.event}`);
  }

  // Always return 200 to acknowledge receipt
  return NextResponse.json({ received: true });
}

// =============================================================================
// Helpers
// =============================================================================

/**
 * Find the session room associated with a Recall bot ID.
 */
function findRoomByBotId(
  wsManager: ReturnType<typeof getWSManager>,
  botId: string
) {
  const states = wsManager.getRoomStates();
  for (const state of states) {
    if (state.recallBotId === botId) {
      return wsManager.getRoom(state.sessionId);
    }
  }
  return undefined;
}

/**
 * Map Recall.ai bot status codes to our session status.
 */
function mapRecallStatus(statusCode: string | undefined): string | null {
  switch (statusCode) {
    case 'ready':
      return 'ready';
    case 'joining_call':
    case 'in_waiting_room':
      return 'ready';
    case 'in_call_not_recording':
      return 'ready';
    case 'in_call_recording':
      return 'running';
    case 'call_ended':
    case 'done':
    case 'analysis_done':
      return 'ended';
    case 'fatal':
      return 'ended';
    default:
      return null;
  }
}
