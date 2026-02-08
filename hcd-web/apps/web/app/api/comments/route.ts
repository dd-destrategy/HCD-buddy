import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { comments, users } from '@hcd/db';
import { eq, and, desc, sql } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// ─── GET /api/comments ──────────────────────────────────────────────────────
// List comments for a session (with author info)
export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const { searchParams } = new URL(request.url);
    const sessionId = searchParams.get('sessionId');
    const utteranceId = searchParams.get('utteranceId');

    if (!sessionId) {
      return NextResponse.json(
        { error: 'sessionId is required' },
        { status: 400 }
      );
    }

    const conditions = [eq(comments.sessionId, sessionId)];

    if (utteranceId) {
      conditions.push(eq(comments.utteranceId, utteranceId));
    }

    const results = await db
      .select({
        id: comments.id,
        sessionId: comments.sessionId,
        utteranceId: comments.utteranceId,
        authorId: comments.authorId,
        text: comments.text,
        timestamp: comments.timestamp,
        createdAt: comments.createdAt,
        updatedAt: comments.updatedAt,
        authorName: users.name,
        authorEmail: users.email,
        authorImage: users.image,
      })
      .from(comments)
      .leftJoin(users, eq(comments.authorId, users.id))
      .where(and(...conditions))
      .orderBy(desc(comments.createdAt));

    return NextResponse.json({
      comments: results.map((row) => ({
        id: row.id,
        sessionId: row.sessionId,
        utteranceId: row.utteranceId,
        authorId: row.authorId,
        text: row.text,
        timestamp: row.timestamp,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        author: {
          id: row.authorId,
          name: row.authorName,
          email: row.authorEmail,
          image: row.authorImage,
        },
      })),
    });
  } catch (error) {
    console.error('Failed to fetch comments:', error);
    return NextResponse.json(
      { error: 'Failed to fetch comments' },
      { status: 500 }
    );
  }
}

// ─── POST /api/comments ─────────────────────────────────────────────────────
// Create a comment
export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const body = await request.json();
    const { sessionId, utteranceId, text, timestamp } = body;

    if (!sessionId || !text) {
      return NextResponse.json(
        { error: 'sessionId and text are required' },
        { status: 400 }
      );
    }

    const [comment] = await db
      .insert(comments)
      .values({
        sessionId,
        utteranceId: utteranceId || null,
        authorId: user.id,
        text,
        timestamp: timestamp || null,
      })
      .returning();

    // Fetch author info for the response
    const [author] = await db
      .select({ name: users.name, email: users.email, image: users.image })
      .from(users)
      .where(eq(users.id, user.id))
      .limit(1);

    return NextResponse.json(
      {
        comment: {
          ...comment,
          author: author
            ? { id: user.id, name: author.name, email: author.email, image: author.image }
            : { id: user.id, name: 'Unknown', email: null, image: null },
        },
      },
      { status: 201 }
    );
  } catch (error) {
    console.error('Failed to create comment:', error);
    return NextResponse.json(
      { error: 'Failed to create comment' },
      { status: 500 }
    );
  }
}

// ─── PATCH /api/comments ────────────────────────────────────────────────────
// Update comment text
export async function PATCH(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const body = await request.json();
    const { id, text } = body;

    if (!id || !text) {
      return NextResponse.json(
        { error: 'id and text are required' },
        { status: 400 }
      );
    }

    // Verify ownership using authenticated user
    const [existing] = await db
      .select()
      .from(comments)
      .where(and(eq(comments.id, id), eq(comments.authorId, user.id)))
      .limit(1);

    if (!existing) {
      return NextResponse.json(
        { error: 'Comment not found or you do not have permission to edit it' },
        { status: 403 }
      );
    }

    const [updated] = await db
      .update(comments)
      .set({
        text,
        updatedAt: new Date(),
      })
      .where(eq(comments.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: 'Comment not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ comment: updated });
  } catch (error) {
    console.error('Failed to update comment:', error);
    return NextResponse.json(
      { error: 'Failed to update comment' },
      { status: 500 }
    );
  }
}

// ─── DELETE /api/comments ───────────────────────────────────────────────────
// Delete a comment
export async function DELETE(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {
      return NextResponse.json(
        { error: 'id is required' },
        { status: 400 }
      );
    }

    // Verify ownership using authenticated user
    const [existing] = await db
      .select()
      .from(comments)
      .where(and(eq(comments.id, id), eq(comments.authorId, user.id)))
      .limit(1);

    if (!existing) {
      return NextResponse.json(
        { error: 'Comment not found or you do not have permission to delete it' },
        { status: 403 }
      );
    }

    const [deleted] = await db
      .delete(comments)
      .where(eq(comments.id, id))
      .returning();

    if (!deleted) {
      return NextResponse.json(
        { error: 'Comment not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ deleted: true });
  } catch (error) {
    console.error('Failed to delete comment:', error);
    return NextResponse.json(
      { error: 'Failed to delete comment' },
      { status: 500 }
    );
  }
}
