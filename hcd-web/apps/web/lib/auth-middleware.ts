import { auth } from '@hcd/auth';
import { NextRequest, NextResponse } from 'next/server';

export interface AuthSession {
  user: {
    id: string;
    email: string;
    name: string;
  };
}

/**
 * Verify authentication for API routes.
 * Returns the session if authenticated, or a 401 NextResponse if not.
 */
export async function requireAuth(
  request: NextRequest
): Promise<AuthSession | NextResponse> {
  try {
    const session = await auth.api.getSession({
      headers: request.headers,
    });

    if (!session?.user?.id) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      );
    }

    return session as AuthSession;
  } catch {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }
}

/**
 * Type guard to check if requireAuth returned an error response.
 */
export function isAuthError(
  result: AuthSession | NextResponse
): result is NextResponse {
  return result instanceof NextResponse;
}
