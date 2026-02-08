import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { participants, sessions, consentRecords } from '@hcd/db';
import { eq, and, ilike, sql, desc } from 'drizzle-orm';

// ─── GET /api/participants ──────────────────────────────────────────────────
// List participants with search, filter by org
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const organizationId = searchParams.get('organizationId');
    const search = searchParams.get('search');
    const role = searchParams.get('role');
    const department = searchParams.get('department');
    const limit = parseInt(searchParams.get('limit') || '50', 10);
    const offset = parseInt(searchParams.get('offset') || '0', 10);

    const conditions = [];

    if (organizationId) {
      conditions.push(eq(participants.organizationId, organizationId));
    }

    if (search) {
      conditions.push(
        sql`(${participants.name} ILIKE ${`%${search}%`} OR ${participants.email} ILIKE ${`%${search}%`} OR ${participants.role} ILIKE ${`%${search}%`})`
      );
    }

    if (role) {
      conditions.push(eq(participants.role, role));
    }

    if (department) {
      conditions.push(eq(participants.department, department));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    // Fetch participants with session count
    const results = await db
      .select({
        id: participants.id,
        organizationId: participants.organizationId,
        name: participants.name,
        email: participants.email,
        role: participants.role,
        department: participants.department,
        experienceLevel: participants.experienceLevel,
        metadata: participants.metadata,
        createdAt: participants.createdAt,
        updatedAt: participants.updatedAt,
        sessionCount: sql<number>`(SELECT COUNT(*) FROM sessions WHERE sessions.participant_id = ${participants.id})`.as('session_count'),
      })
      .from(participants)
      .where(whereClause)
      .orderBy(desc(participants.createdAt))
      .limit(limit)
      .offset(offset);

    // Total count
    const countResult = await db
      .select({ count: sql<number>`count(*)` })
      .from(participants)
      .where(whereClause);

    return NextResponse.json({
      participants: results,
      total: Number(countResult[0]?.count || 0),
      limit,
      offset,
    });
  } catch (error) {
    console.error('Failed to fetch participants:', error);
    return NextResponse.json(
      { error: 'Failed to fetch participants' },
      { status: 500 }
    );
  }
}

// ─── POST /api/participants ─────────────────────────────────────────────────
// Create a new participant
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, email, role, department, experienceLevel, metadata, organizationId } = body;

    if (!name) {
      return NextResponse.json(
        { error: 'name is required' },
        { status: 400 }
      );
    }

    const [participant] = await db
      .insert(participants)
      .values({
        name,
        email: email || null,
        role: role || null,
        department: department || null,
        experienceLevel: experienceLevel || null,
        metadata: metadata || {},
        organizationId: organizationId || null,
      })
      .returning();

    return NextResponse.json({ participant }, { status: 201 });
  } catch (error) {
    console.error('Failed to create participant:', error);
    return NextResponse.json(
      { error: 'Failed to create participant' },
      { status: 500 }
    );
  }
}
