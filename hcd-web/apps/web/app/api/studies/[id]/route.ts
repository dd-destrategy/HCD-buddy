import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { studies, sessions, highlights, utterances } from '@hcd/db';
import { eq, desc, sql, and } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// ─── GET /api/studies/[id] ──────────────────────────────────────────────────
// Get study with sessions
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { id } = await params;

    const [study] = await db
      .select()
      .from(studies)
      .where(eq(studies.id, id))
      .limit(1);

    if (!study) {
      return NextResponse.json(
        { error: 'Study not found' },
        { status: 404 }
      );
    }

    // Fetch sessions in this study
    const studySessions = await db
      .select({
        id: sessions.id,
        title: sessions.title,
        status: sessions.status,
        sessionMode: sessions.sessionMode,
        startedAt: sessions.startedAt,
        endedAt: sessions.endedAt,
        durationSeconds: sessions.durationSeconds,
        participantId: sessions.participantId,
        consentStatus: sessions.consentStatus,
        createdAt: sessions.createdAt,
      })
      .from(sessions)
      .where(eq(sessions.studyId, id))
      .orderBy(desc(sessions.createdAt));

    // Analytics summary
    const totalDuration = studySessions.reduce(
      (sum, s) => sum + (s.durationSeconds || 0),
      0
    );

    const highlightCount = await db
      .select({ count: sql<number>`count(*)` })
      .from(highlights)
      .innerJoin(sessions, eq(highlights.sessionId, sessions.id))
      .where(eq(sessions.studyId, id));

    const utteranceCount = await db
      .select({ count: sql<number>`count(*)` })
      .from(utterances)
      .innerJoin(sessions, eq(utterances.sessionId, sessions.id))
      .where(eq(sessions.studyId, id));

    return NextResponse.json({
      study,
      sessions: studySessions,
      analytics: {
        sessionCount: studySessions.length,
        totalDuration,
        highlightCount: Number(highlightCount[0]?.count || 0),
        utteranceCount: Number(utteranceCount[0]?.count || 0),
        completedSessions: studySessions.filter((s) => s.status === 'completed').length,
      },
    });
  } catch (error) {
    console.error('Failed to fetch study:', error);
    return NextResponse.json(
      { error: 'Failed to fetch study' },
      { status: 500 }
    );
  }
}

// ─── PATCH /api/studies/[id] ────────────────────────────────────────────────
// Update study
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { id } = await params;
    const body = await request.json();
    const { title, description } = body;

    const updateData: Record<string, any> = {
      updatedAt: new Date(),
    };

    if (title !== undefined) updateData.title = title;
    if (description !== undefined) updateData.description = description;

    const [updated] = await db
      .update(studies)
      .set(updateData)
      .where(eq(studies.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: 'Study not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ study: updated });
  } catch (error) {
    console.error('Failed to update study:', error);
    return NextResponse.json(
      { error: 'Failed to update study' },
      { status: 500 }
    );
  }
}

// ─── DELETE /api/studies/[id] ───────────────────────────────────────────────
// Delete study (sessions preserved, just unlinked)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { id } = await params;

    // Unlink sessions from this study
    await db
      .update(sessions)
      .set({ studyId: null })
      .where(eq(sessions.studyId, id));

    // Delete the study
    const [deleted] = await db
      .delete(studies)
      .where(eq(studies.id, id))
      .returning();

    if (!deleted) {
      return NextResponse.json(
        { error: 'Study not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      deleted: true,
      study: deleted,
      message: 'Study deleted. Sessions have been preserved and unlinked.',
    });
  } catch (error) {
    console.error('Failed to delete study:', error);
    return NextResponse.json(
      { error: 'Failed to delete study' },
      { status: 500 }
    );
  }
}

// ─── POST /api/studies/[id] (with action parameter) ────────────────────────
// Add/remove session from study
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { id } = await params;
    const body = await request.json();
    const { action, sessionId } = body;

    if (!sessionId) {
      return NextResponse.json(
        { error: 'sessionId is required' },
        { status: 400 }
      );
    }

    // Verify study exists
    const [study] = await db
      .select()
      .from(studies)
      .where(eq(studies.id, id))
      .limit(1);

    if (!study) {
      return NextResponse.json(
        { error: 'Study not found' },
        { status: 404 }
      );
    }

    if (action === 'remove') {
      // Remove session from study
      const [updated] = await db
        .update(sessions)
        .set({ studyId: null, updatedAt: new Date() })
        .where(and(eq(sessions.id, sessionId), eq(sessions.studyId, id)))
        .returning();

      if (!updated) {
        return NextResponse.json(
          { error: 'Session not found in this study' },
          { status: 404 }
        );
      }

      return NextResponse.json({
        message: 'Session removed from study',
        session: updated,
      });
    } else {
      // Add session to study (default action)
      const [updated] = await db
        .update(sessions)
        .set({ studyId: id, updatedAt: new Date() })
        .where(eq(sessions.id, sessionId))
        .returning();

      if (!updated) {
        return NextResponse.json(
          { error: 'Session not found' },
          { status: 404 }
        );
      }

      return NextResponse.json({
        message: 'Session added to study',
        session: updated,
      });
    }
  } catch (error) {
    console.error('Failed to modify study sessions:', error);
    return NextResponse.json(
      { error: 'Failed to modify study sessions' },
      { status: 500 }
    );
  }
}
