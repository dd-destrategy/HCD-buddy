import { NextRequest, NextResponse } from 'next/server';
import {
  db,
  sessions,
  utterances,
  insights,
  topicStatuses,
  coachingEvents,
  highlights,
  studies,
  participants,
  consentRecords,
} from '@hcd/db';
import { eq, and } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// =============================================================================
// GET /api/sessions/[id] — Fetch full session with related data
// =============================================================================

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const { id } = await params;

    // Fetch session with study and participant info
    const sessionRows = await db
      .select({
        id: sessions.id,
        title: sessions.title,
        sessionMode: sessions.sessionMode,
        status: sessions.status,
        startedAt: sessions.startedAt,
        endedAt: sessions.endedAt,
        durationSeconds: sessions.durationSeconds,
        templateId: sessions.templateId,
        participantId: sessions.participantId,
        participantName: participants.name,
        participantEmail: participants.email,
        participantRole: participants.role,
        studyId: sessions.studyId,
        studyTitle: studies.title,
        consentStatus: sessions.consentStatus,
        coachingEnabled: sessions.coachingEnabled,
        meetingUrl: sessions.meetingUrl,
        metadata: sessions.metadata,
        summary: sessions.summary,
        createdAt: sessions.createdAt,
        updatedAt: sessions.updatedAt,
      })
      .from(sessions)
      .leftJoin(participants, eq(sessions.participantId, participants.id))
      .leftJoin(studies, eq(sessions.studyId, studies.id))
      .where(eq(sessions.id, id))
      .limit(1);

    if (sessionRows.length === 0) {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    const session = sessionRows[0];

    // Fetch related data in parallel
    const [
      utteranceRows,
      insightRows,
      topicRows,
      coachingRows,
      highlightRows,
      consentRows,
    ] = await Promise.all([
      db
        .select()
        .from(utterances)
        .where(eq(utterances.sessionId, id))
        .orderBy(utterances.startTime),
      db
        .select()
        .from(insights)
        .where(eq(insights.sessionId, id))
        .orderBy(insights.timestamp),
      db
        .select()
        .from(topicStatuses)
        .where(eq(topicStatuses.sessionId, id)),
      db
        .select()
        .from(coachingEvents)
        .where(eq(coachingEvents.sessionId, id))
        .orderBy(coachingEvents.displayedAt),
      db
        .select()
        .from(highlights)
        .where(eq(highlights.sessionId, id))
        .orderBy(highlights.createdAt),
      db
        .select()
        .from(consentRecords)
        .where(eq(consentRecords.sessionId, id)),
    ]);

    return NextResponse.json({
      data: {
        ...session,
        utterances: utteranceRows,
        insights: insightRows,
        topics: topicRows,
        coachingEvents: coachingRows,
        highlights: highlightRows,
        consent: consentRows,
      },
    });
  } catch (error) {
    console.error('[API] GET /api/sessions/[id] error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch session' },
      { status: 500 }
    );
  }
}

// =============================================================================
// PATCH /api/sessions/[id] — Update session metadata
// =============================================================================

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const { id } = await params;
    const body = await request.json();

    // Validate title is not empty string
    if (body.title !== undefined && typeof body.title === 'string' && body.title.trim().length === 0) {
      return NextResponse.json(
        { error: 'Title cannot be empty' },
        { status: 400 }
      );
    }

    // Only allow updating safe fields
    const allowedFields: Record<string, unknown> = {};
    const updatable = [
      'title',
      'sessionMode',
      'status',
      'studyId',
      'participantId',
      'templateId',
      'coachingEnabled',
      'meetingUrl',
      'consentStatus',
      'metadata',
      'summary',
      'startedAt',
      'endedAt',
      'durationSeconds',
    ] as const;

    for (const field of updatable) {
      if (body[field] !== undefined) {
        allowedFields[field] = body[field];
      }
    }

    if (Object.keys(allowedFields).length === 0) {
      return NextResponse.json(
        { error: 'No valid fields to update' },
        { status: 400 }
      );
    }

    // Always update the updatedAt timestamp
    allowedFields.updatedAt = new Date();

    const [updated] = await db
      .update(sessions)
      .set(allowedFields)
      .where(eq(sessions.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: updated });
  } catch (error) {
    console.error('[API] PATCH /api/sessions/[id] error:', error);
    return NextResponse.json(
      { error: 'Failed to update session' },
      { status: 500 }
    );
  }
}

// =============================================================================
// DELETE /api/sessions/[id] — Delete session and all cascading data
// =============================================================================

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const { id } = await params;

    // The cascade rules on the DB schema handle deleting related records
    // (utterances, insights, topics, coaching_events, highlights, consent_records, redactions)
    const [deleted] = await db
      .delete(sessions)
      .where(eq(sessions.id, id))
      .returning({ id: sessions.id });

    if (!deleted) {
      return NextResponse.json(
        { error: 'Session not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: { id: deleted.id, deleted: true } });
  } catch (error) {
    console.error('[API] DELETE /api/sessions/[id] error:', error);
    return NextResponse.json(
      { error: 'Failed to delete session' },
      { status: 500 }
    );
  }
}
