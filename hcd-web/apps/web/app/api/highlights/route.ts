import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { highlights } from '@hcd/db';
import { sessions } from '@hcd/db';
import { eq, and, desc, ilike, sql } from 'drizzle-orm';

// ─── GET /api/highlights ────────────────────────────────────────────────────
// List highlights with filters: sessionId, category, starred, search, studyId, dateFrom, dateTo
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const sessionId = searchParams.get('sessionId');
    const category = searchParams.get('category');
    const starred = searchParams.get('starred');
    const searchQuery = searchParams.get('search');
    const studyId = searchParams.get('studyId');
    const dateFrom = searchParams.get('dateFrom');
    const dateTo = searchParams.get('dateTo');
    const sortBy = searchParams.get('sortBy') || 'date';
    const limit = parseInt(searchParams.get('limit') || '50', 10);
    const offset = parseInt(searchParams.get('offset') || '0', 10);

    const conditions = [];

    if (sessionId) {
      conditions.push(eq(highlights.sessionId, sessionId));
    }

    if (category) {
      conditions.push(eq(highlights.category, category));
    }

    if (starred === 'true') {
      conditions.push(eq(highlights.isStarred, true));
    }

    if (searchQuery) {
      conditions.push(
        sql`(${highlights.textSelection} ILIKE ${`%${searchQuery}%`} OR ${highlights.title} ILIKE ${`%${searchQuery}%`} OR ${highlights.notes} ILIKE ${`%${searchQuery}%`})`
      );
    }

    if (dateFrom) {
      conditions.push(sql`${highlights.createdAt} >= ${new Date(dateFrom)}`);
    }

    if (dateTo) {
      conditions.push(sql`${highlights.createdAt} <= ${new Date(dateTo)}`);
    }

    // Build the query with optional study filter through sessions join
    let query;
    if (studyId) {
      query = db
        .select({
          id: highlights.id,
          sessionId: highlights.sessionId,
          utteranceId: highlights.utteranceId,
          ownerId: highlights.ownerId,
          title: highlights.title,
          category: highlights.category,
          textSelection: highlights.textSelection,
          notes: highlights.notes,
          isStarred: highlights.isStarred,
          createdAt: highlights.createdAt,
          sessionTitle: sessions.title,
        })
        .from(highlights)
        .innerJoin(sessions, eq(highlights.sessionId, sessions.id))
        .where(
          and(
            eq(sessions.studyId, studyId),
            ...conditions
          )
        );
    } else {
      query = db
        .select({
          id: highlights.id,
          sessionId: highlights.sessionId,
          utteranceId: highlights.utteranceId,
          ownerId: highlights.ownerId,
          title: highlights.title,
          category: highlights.category,
          textSelection: highlights.textSelection,
          notes: highlights.notes,
          isStarred: highlights.isStarred,
          createdAt: highlights.createdAt,
          sessionTitle: sessions.title,
        })
        .from(highlights)
        .leftJoin(sessions, eq(highlights.sessionId, sessions.id))
        .where(conditions.length > 0 ? and(...conditions) : undefined);
    }

    // Sorting
    let orderClause;
    switch (sortBy) {
      case 'category':
        orderClause = highlights.category;
        break;
      case 'session':
        orderClause = sessions.title;
        break;
      case 'date':
      default:
        orderClause = desc(highlights.createdAt);
        break;
    }

    const results = await (query as any)
      .orderBy(orderClause)
      .limit(limit)
      .offset(offset);

    // Get total count for pagination
    const countResult = await db
      .select({ count: sql<number>`count(*)` })
      .from(highlights)
      .where(conditions.length > 0 ? and(...conditions) : undefined);

    return NextResponse.json({
      highlights: results,
      total: Number(countResult[0]?.count || 0),
      limit,
      offset,
    });
  } catch (error) {
    console.error('Failed to fetch highlights:', error);
    return NextResponse.json(
      { error: 'Failed to fetch highlights' },
      { status: 500 }
    );
  }
}

// ─── POST /api/highlights ───────────────────────────────────────────────────
// Create a new highlight
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { sessionId, utteranceId, ownerId, title, category, textSelection, notes, isStarred } = body;

    if (!sessionId || !title || !category || !textSelection) {
      return NextResponse.json(
        { error: 'sessionId, title, category, and textSelection are required' },
        { status: 400 }
      );
    }

    const validCategories = [
      'Pain Point',
      'User Need',
      'Delight',
      'Workaround',
      'Feature Request',
      'Key Quote',
    ];

    if (!validCategories.includes(category)) {
      return NextResponse.json(
        { error: `Invalid category. Must be one of: ${validCategories.join(', ')}` },
        { status: 400 }
      );
    }

    const [highlight] = await db
      .insert(highlights)
      .values({
        sessionId,
        utteranceId: utteranceId || null,
        ownerId: ownerId || null,
        title,
        category,
        textSelection,
        notes: notes || null,
        isStarred: isStarred || false,
      })
      .returning();

    return NextResponse.json({ highlight }, { status: 201 });
  } catch (error) {
    console.error('Failed to create highlight:', error);
    return NextResponse.json(
      { error: 'Failed to create highlight' },
      { status: 500 }
    );
  }
}

// ─── PATCH /api/highlights ──────────────────────────────────────────────────
// Update a highlight (star, notes, category)
export async function PATCH(request: NextRequest) {
  try {
    const body = await request.json();
    const { id, isStarred, notes, category, title } = body;

    if (!id) {
      return NextResponse.json(
        { error: 'id is required' },
        { status: 400 }
      );
    }

    const updateData: Record<string, any> = {};
    if (typeof isStarred === 'boolean') updateData.isStarred = isStarred;
    if (notes !== undefined) updateData.notes = notes;
    if (category) updateData.category = category;
    if (title) updateData.title = title;

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json(
        { error: 'No fields to update' },
        { status: 400 }
      );
    }

    const [updated] = await db
      .update(highlights)
      .set(updateData)
      .where(eq(highlights.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: 'Highlight not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ highlight: updated });
  } catch (error) {
    console.error('Failed to update highlight:', error);
    return NextResponse.json(
      { error: 'Failed to update highlight' },
      { status: 500 }
    );
  }
}

// ─── DELETE /api/highlights ─────────────────────────────────────────────────
// Delete a highlight
export async function DELETE(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const ids = searchParams.get('ids'); // comma-separated for bulk delete

    if (!id && !ids) {
      return NextResponse.json(
        { error: 'id or ids parameter is required' },
        { status: 400 }
      );
    }

    if (ids) {
      const idList = ids.split(',').map((s) => s.trim());
      for (const deleteId of idList) {
        await db.delete(highlights).where(eq(highlights.id, deleteId));
      }
      return NextResponse.json({ deleted: idList.length });
    }

    const [deleted] = await db
      .delete(highlights)
      .where(eq(highlights.id, id!))
      .returning();

    if (!deleted) {
      return NextResponse.json(
        { error: 'Highlight not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ deleted: 1 });
  } catch (error) {
    console.error('Failed to delete highlight:', error);
    return NextResponse.json(
      { error: 'Failed to delete highlight' },
      { status: 500 }
    );
  }
}
