import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { tags } from '@hcd/db';
import { eq, and, isNull } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// GET /api/tags — List all tags for an organization (with hierarchy)
export async function GET(request: NextRequest) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const { searchParams } = new URL(request.url);
    const organizationId = searchParams.get('organizationId');

    if (!organizationId) {
      return NextResponse.json(
        { error: 'organizationId is required' },
        { status: 400 }
      );
    }

    // Fetch all tags for the organization
    const allTags = await db
      .select()
      .from(tags)
      .where(eq(tags.organizationId, organizationId));

    // Build hierarchical structure
    const tagMap = new Map<string, typeof allTags[0] & { children: typeof allTags }>();
    const rootTags: Array<typeof allTags[0] & { children: typeof allTags }> = [];

    // First pass: index all tags
    for (const tag of allTags) {
      tagMap.set(tag.id, { ...tag, children: [] });
    }

    // Second pass: build tree
    for (const tag of allTags) {
      const node = tagMap.get(tag.id)!;
      if (tag.parentId && tagMap.has(tag.parentId)) {
        tagMap.get(tag.parentId)!.children.push(node);
      } else {
        rootTags.push(node);
      }
    }

    return NextResponse.json({ tags: rootTags });
  } catch (error) {
    console.error('Failed to fetch tags:', error);
    return NextResponse.json(
      { error: 'Failed to fetch tags' },
      { status: 500 }
    );
  }
}

// POST /api/tags — Create a new tag
export async function POST(request: NextRequest) {
  const authResult = await requireAuth(request);
  if (isAuthError(authResult)) return authResult;
  const { user } = authResult;

  try {
    const body = await request.json();
    const { name, color, parentId, organizationId } = body;

    if (!name || !organizationId) {
      return NextResponse.json(
        { error: 'name and organizationId are required' },
        { status: 400 }
      );
    }

    // Validate parent exists if provided
    if (parentId) {
      const parent = await db
        .select()
        .from(tags)
        .where(and(eq(tags.id, parentId), eq(tags.organizationId, organizationId)))
        .limit(1);

      if (parent.length === 0) {
        return NextResponse.json(
          { error: 'Parent tag not found' },
          { status: 404 }
        );
      }
    }

    const [newTag] = await db
      .insert(tags)
      .values({
        name,
        color: color || '#6366f1',
        parentId: parentId || null,
        organizationId,
      })
      .returning();

    return NextResponse.json({ tag: newTag }, { status: 201 });
  } catch (error) {
    console.error('Failed to create tag:', error);
    return NextResponse.json(
      { error: 'Failed to create tag' },
      { status: 500 }
    );
  }
}
