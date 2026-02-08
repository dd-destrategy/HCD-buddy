import { NextRequest, NextResponse } from 'next/server';
import {
  db,
  sessions,
  utterances,
  insights,
  topicStatuses,
  coachingEvents,
} from '@hcd/db';

// =============================================================================
// POST /api/import — Import a session from macOS app JSON export
// =============================================================================

/**
 * Expected JSON shape from the macOS HCD Interview Coach export:
 *
 * {
 *   session: { title, sessionMode, startedAt, endedAt, durationSeconds, ... },
 *   utterances: [ { speaker, text, startTime, endTime, ... } ],
 *   insights: [ { source, note, timestamp } ],
 *   topics: [ { topicName, status, coveredAt? } ],
 *   coachingEvents: [ { promptType, promptText, confidence, displayedAt, ... } ]
 * }
 */

interface ImportedUtterance {
  speaker: string;
  text: string;
  startTime: number;
  endTime?: number;
  confidence?: number;
  sentimentScore?: number;
  sentimentPolarity?: string;
  questionType?: string;
}

interface ImportedInsight {
  source: string;
  note?: string;
  timestamp: number;
}

interface ImportedTopic {
  topicName: string;
  status: string;
  coveredAt?: string;
}

interface ImportedCoachingEvent {
  promptType: string;
  promptText: string;
  confidence?: number;
  response?: string;
  displayedAt: string;
  respondedAt?: string;
  culturalContext?: string;
}

interface ImportPayload {
  session: {
    title: string;
    sessionMode?: string;
    startedAt?: string;
    endedAt?: string;
    durationSeconds?: number;
    consentStatus?: string;
    coachingEnabled?: boolean;
    metadata?: Record<string, unknown>;
    summary?: Record<string, unknown>;
  };
  utterances?: ImportedUtterance[];
  insights?: ImportedInsight[];
  topics?: ImportedTopic[];
  coachingEvents?: ImportedCoachingEvent[];
}

export async function POST(request: NextRequest) {
  try {
    const contentType = request.headers.get('content-type') || '';

    let payload: ImportPayload;

    if (contentType.includes('multipart/form-data')) {
      // Handle file upload
      const formData = await request.formData();
      const file = formData.get('file') as File | null;

      if (!file) {
        return NextResponse.json(
          { error: 'No file provided. Attach a JSON file as "file" in form data.' },
          { status: 400 }
        );
      }

      if (!file.name.endsWith('.json')) {
        return NextResponse.json(
          { error: 'Only JSON files are supported for import.' },
          { status: 400 }
        );
      }

      const text = await file.text();
      try {
        payload = JSON.parse(text);
      } catch {
        return NextResponse.json(
          { error: 'Invalid JSON in uploaded file.' },
          { status: 400 }
        );
      }
    } else {
      // Handle direct JSON body
      payload = await request.json();
    }

    // Validate required fields
    if (!payload.session || !payload.session.title) {
      return NextResponse.json(
        { error: 'Import data must contain a session object with at least a title.' },
        { status: 400 }
      );
    }

    // Placeholder ownerId — in production from auth
    const ownerId = '00000000-0000-0000-0000-000000000000';

    // Insert session
    const [newSession] = await db
      .insert(sessions)
      .values({
        title: payload.session.title,
        sessionMode: payload.session.sessionMode || 'interview',
        status: 'ended', // Imported sessions are already complete
        ownerId,
        startedAt: payload.session.startedAt ? new Date(payload.session.startedAt) : null,
        endedAt: payload.session.endedAt ? new Date(payload.session.endedAt) : null,
        durationSeconds: payload.session.durationSeconds ?? null,
        consentStatus: payload.session.consentStatus || 'not_obtained',
        coachingEnabled: payload.session.coachingEnabled ?? false,
        metadata: payload.session.metadata || {},
        summary: payload.session.summary || null,
      })
      .returning();

    const sessionId = newSession.id;
    const stats = { utterances: 0, insights: 0, topics: 0, coachingEvents: 0 };

    // Insert utterances in batches
    if (payload.utterances && payload.utterances.length > 0) {
      const BATCH_SIZE = 500;
      for (let i = 0; i < payload.utterances.length; i += BATCH_SIZE) {
        const batch = payload.utterances.slice(i, i + BATCH_SIZE);
        await db.insert(utterances).values(
          batch.map((u) => ({
            sessionId,
            speaker: u.speaker,
            text: u.text,
            startTime: u.startTime,
            endTime: u.endTime ?? null,
            confidence: u.confidence ?? null,
            sentimentScore: u.sentimentScore ?? null,
            sentimentPolarity: u.sentimentPolarity ?? null,
            questionType: u.questionType ?? null,
          }))
        );
      }
      stats.utterances = payload.utterances.length;
    }

    // Insert insights
    if (payload.insights && payload.insights.length > 0) {
      await db.insert(insights).values(
        payload.insights.map((ins) => ({
          sessionId,
          source: ins.source,
          note: ins.note ?? null,
          timestamp: ins.timestamp,
        }))
      );
      stats.insights = payload.insights.length;
    }

    // Insert topic statuses
    if (payload.topics && payload.topics.length > 0) {
      await db.insert(topicStatuses).values(
        payload.topics.map((t) => ({
          sessionId,
          topicName: t.topicName,
          status: t.status,
          coveredAt: t.coveredAt ? new Date(t.coveredAt) : null,
        }))
      );
      stats.topics = payload.topics.length;
    }

    // Insert coaching events
    if (payload.coachingEvents && payload.coachingEvents.length > 0) {
      await db.insert(coachingEvents).values(
        payload.coachingEvents.map((ce) => ({
          sessionId,
          promptType: ce.promptType,
          promptText: ce.promptText,
          confidence: ce.confidence ?? null,
          response: ce.response ?? null,
          displayedAt: new Date(ce.displayedAt),
          respondedAt: ce.respondedAt ? new Date(ce.respondedAt) : null,
          culturalContext: ce.culturalContext ?? null,
        }))
      );
      stats.coachingEvents = payload.coachingEvents.length;
    }

    return NextResponse.json(
      {
        data: {
          sessionId,
          title: newSession.title,
          imported: stats,
        },
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('[API] POST /api/import error:', error);
    return NextResponse.json(
      { error: 'Failed to import session data' },
      { status: 500 }
    );
  }
}
