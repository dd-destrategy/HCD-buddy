import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { studies, sessions } from '@hcd/db';
import { eq, and, desc, sql } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// ─── GET /api/studies ───────────────────────────────────────────────────────
// List studies for an organization
export async function GET(request: NextRequest) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { searchParams } = new URL(request.url);
    const organizationId = searchParams.get('organizationId');
    const ownerId = searchParams.get('ownerId');
    const limit = parseInt(searchParams.get('limit') || '50', 10);
    const offset = parseInt(searchParams.get('offset') || '0', 10);

    const conditions = [];

    if (organizationId) {
      conditions.push(eq(studies.organizationId, organizationId));
    }

    if (ownerId) {
      conditions.push(eq(studies.ownerId, ownerId));
    }

    const whereClause = conditions.length > 0 ? and(...conditions) : undefined;

    const results = await db
      .select({
        id: studies.id,
        organizationId: studies.organizationId,
        ownerId: studies.ownerId,
        title: studies.title,
        description: studies.description,
        createdAt: studies.createdAt,
        updatedAt: studies.updatedAt,
        sessionCount: sql<number>`(SELECT COUNT(*) FROM sessions WHERE sessions.study_id = ${studies.id})`.as('session_count'),
      })
      .from(studies)
      .where(whereClause)
      .orderBy(desc(studies.updatedAt))
      .limit(limit)
      .offset(offset);

    const countResult = await db
      .select({ count: sql<number>`count(*)` })
      .from(studies)
      .where(whereClause);

    return NextResponse.json({
      studies: results,
      total: Number(countResult[0]?.count || 0),
      limit,
      offset,
    });
  } catch (error) {
    console.error('Failed to fetch studies:', error);
    return NextResponse.json(
      { error: 'Failed to fetch studies' },
      { status: 500 }
    );
  }
}

// ─── POST /api/studies ──────────────────────────────────────────────────────
// Create a new study
export async function POST(request: NextRequest) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const body = await request.json();
    const { title, description, organizationId } = body;

    if (!title) {
      return NextResponse.json(
        { error: 'title is required' },
        { status: 400 }
      );
    }

    const [study] = await db
      .insert(studies)
      .values({
        title,
        description: description || null,
        ownerId: user.id,
        organizationId: organizationId || null,
      })
      .returning();

    return NextResponse.json({ study }, { status: 201 });
  } catch (error) {
    console.error('Failed to create study:', error);
    return NextResponse.json(
      { error: 'Failed to create study' },
      { status: 500 }
    );
  }
}
