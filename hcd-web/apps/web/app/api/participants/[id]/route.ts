import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { participants, sessions, consentRecords, utterances, highlights, redactions, insights, topicStatuses, coachingEvents, comments } from '@hcd/db';
import { eq, desc, sql } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// ─── GET /api/participants/[id] ─────────────────────────────────────────────
// Get participant with session history
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { id } = await params;

    // Fetch participant
    const [participant] = await db
      .select()
      .from(participants)
      .where(eq(participants.id, id))
      .limit(1);

    if (!participant) {
      return NextResponse.json(
        { error: 'Participant not found' },
        { status: 404 }
      );
    }

    // Fetch session history
    const sessionHistory = await db
      .select({
        id: sessions.id,
        title: sessions.title,
        status: sessions.status,
        startedAt: sessions.startedAt,
        endedAt: sessions.endedAt,
        durationSeconds: sessions.durationSeconds,
        consentStatus: sessions.consentStatus,
      })
      .from(sessions)
      .where(eq(sessions.participantId, id))
      .orderBy(desc(sessions.createdAt));

    // Fetch consent records
    const consentHistory = await db
      .select()
      .from(consentRecords)
      .where(eq(consentRecords.participantId, id))
      .orderBy(desc(consentRecords.createdAt));

    return NextResponse.json({
      participant,
      sessions: sessionHistory,
      consentRecords: consentHistory,
    });
  } catch (error) {
    console.error('Failed to fetch participant:', error);
    return NextResponse.json(
      { error: 'Failed to fetch participant' },
      { status: 500 }
    );
  }
}

// ─── PATCH /api/participants/[id] ───────────────────────────────────────────
// Update participant
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
    const { name, email, role, department, experienceLevel, metadata } = body;

    const updateData: Record<string, any> = {
      updatedAt: new Date(),
    };

    if (name !== undefined) updateData.name = name;
    if (email !== undefined) updateData.email = email;
    if (role !== undefined) updateData.role = role;
    if (department !== undefined) updateData.department = department;
    if (experienceLevel !== undefined) updateData.experienceLevel = experienceLevel;
    if (metadata !== undefined) updateData.metadata = metadata;

    const [updated] = await db
      .update(participants)
      .set(updateData)
      .where(eq(participants.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: 'Participant not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ participant: updated });
  } catch (error) {
    console.error('Failed to update participant:', error);
    return NextResponse.json(
      { error: 'Failed to update participant' },
      { status: 500 }
    );
  }
}

// ─── DELETE /api/participants/[id] ──────────────────────────────────────────
// Delete participant and all associated data (GDPR right to erasure)
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { id } = await params;

    // Verify participant exists
    const [existing] = await db
      .select()
      .from(participants)
      .where(eq(participants.id, id))
      .limit(1);

    if (!existing) {
      return NextResponse.json(
        { error: 'Participant not found' },
        { status: 404 }
      );
    }

    // Delete consent records
    await db
      .delete(consentRecords)
      .where(eq(consentRecords.participantId, id));

    // Get all sessions for this participant to clean up related data
    const participantSessions = await db
      .select({ id: sessions.id })
      .from(sessions)
      .where(eq(sessions.participantId, id));

    // For each session, delete related data
    for (const session of participantSessions) {
      await db.delete(insights).where(eq(insights.sessionId, session.id));
      await db.delete(topicStatuses).where(eq(topicStatuses.sessionId, session.id));
      await db.delete(coachingEvents).where(eq(coachingEvents.sessionId, session.id));
      await db.delete(comments).where(eq(comments.sessionId, session.id));
      await db.delete(utterances).where(eq(utterances.sessionId, session.id));
      await db.delete(highlights).where(eq(highlights.sessionId, session.id));
      await db.delete(redactions).where(eq(redactions.sessionId, session.id));
    }

    // Unlink sessions (don't delete them, just remove participant reference)
    await db
      .update(sessions)
      .set({ participantId: null })
      .where(eq(sessions.participantId, id));

    // Delete the participant
    const [deleted] = await db
      .delete(participants)
      .where(eq(participants.id, id))
      .returning();

    return NextResponse.json({
      deleted: true,
      participant: deleted,
      message: 'Participant and all associated data have been permanently deleted (GDPR erasure)',
    });
  } catch (error) {
    console.error('Failed to delete participant:', error);
    return NextResponse.json(
      { error: 'Failed to delete participant' },
      { status: 500 }
    );
  }
}
