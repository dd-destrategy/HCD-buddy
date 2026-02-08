import { NextRequest, NextResponse } from 'next/server';
import { db, sessions, studies, participants } from '@hcd/db';
import { eq, desc, asc, and, gte, lte, ilike, sql, count } from 'drizzle-orm';

// =============================================================================
// GET /api/sessions — List sessions with pagination, filters, and sorting
// =============================================================================

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);

    // Pagination
    const page = Math.max(1, parseInt(searchParams.get('page') || '1', 10));
    const limit = Math.min(100, Math.max(1, parseInt(searchParams.get('limit') || '20', 10)));
    const offset = (page - 1) * limit;

    // Filters
    const status = searchParams.get('status');
    const studyId = searchParams.get('studyId');
    const participantId = searchParams.get('participantId');
    const search = searchParams.get('search');
    const dateFrom = searchParams.get('dateFrom');
    const dateTo = searchParams.get('dateTo');

    // Sorting
    const sortBy = searchParams.get('sortBy') || 'date';
    const sortOrder = searchParams.get('sortOrder') || 'desc';

    // Build where conditions
    const conditions = [];

    if (status) {
      conditions.push(eq(sessions.status, status));
    }

    if (studyId) {
      conditions.push(eq(sessions.studyId, studyId));
    }

    if (participantId) {
      conditions.push(eq(sessions.participantId, participantId));
    }

    if (search) {
      conditions.push(ilike(sessions.title, `%${search}%`));
    }

    if (dateFrom) {
      conditions.push(gte(sessions.createdAt, new Date(dateFrom)));
    }

    if (dateTo) {
      conditions.push(lte(sessions.createdAt, new Date(dateTo)));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    // Determine sort column and direction
    const sortColumn = (() => {
      switch (sortBy) {
        case 'title':
          return sessions.title;
        case 'duration':
          return sessions.durationSeconds;
        case 'date':
        default:
          return sessions.createdAt;
      }
    })();

    const orderDirection = sortOrder === 'asc' ? asc : desc;

    // Execute queries in parallel: data + count
    const [rows, totalResult] = await Promise.all([
      db
        .select({
          id: sessions.id,
          title: sessions.title,
          sessionMode: sessions.sessionMode,
          status: sessions.status,
          startedAt: sessions.startedAt,
          endedAt: sessions.endedAt,
          durationSeconds: sessions.durationSeconds,
          participantId: sessions.participantId,
          participantName: participants.name,
          studyId: sessions.studyId,
          studyTitle: studies.title,
          consentStatus: sessions.consentStatus,
          coachingEnabled: sessions.coachingEnabled,
          createdAt: sessions.createdAt,
          updatedAt: sessions.updatedAt,
        })
        .from(sessions)
        .leftJoin(participants, eq(sessions.participantId, participants.id))
        .leftJoin(studies, eq(sessions.studyId, studies.id))
        .where(whereClause)
        .orderBy(orderDirection(sortColumn))
        .limit(limit)
        .offset(offset),
      db
        .select({ total: count() })
        .from(sessions)
        .where(whereClause),
    ]);

    const total = totalResult[0]?.total ?? 0;

    return NextResponse.json({
      data: rows,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('[API] GET /api/sessions error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch sessions' },
      { status: 500 }
    );
  }
}

// =============================================================================
// POST /api/sessions — Create a new session
// =============================================================================

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    const {
      title,
      sessionMode = 'interview',
      studyId,
      templateId,
      participantId,
      coachingEnabled = false,
      meetingUrl,
      metadata = {},
    } = body;

    if (!title || typeof title !== 'string' || title.trim().length === 0) {
      return NextResponse.json(
        { error: 'Title is required' },
        { status: 400 }
      );
    }

    // For now use a placeholder ownerId — in production this comes from the auth session
    const ownerId = body.ownerId || '00000000-0000-0000-0000-000000000000';

    const [newSession] = await db
      .insert(sessions)
      .values({
        title: title.trim(),
        sessionMode,
        status: 'draft',
        ownerId,
        studyId: studyId || null,
        templateId: templateId || null,
        participantId: participantId || null,
        coachingEnabled,
        meetingUrl: meetingUrl || null,
        metadata,
      })
      .returning();

    return NextResponse.json({ data: newSession }, { status: 201 });
  } catch (error) {
    console.error('[API] POST /api/sessions error:', error);
    return NextResponse.json(
      { error: 'Failed to create session' },
      { status: 500 }
    );
  }
}
