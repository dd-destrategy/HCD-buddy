"use client";

import { createAuthClient } from "better-auth/react";
import { organizationClient } from "better-auth/client/plugins";
import { useState, useEffect, useCallback } from "react";

// ─── Better Auth Client ─────────────────────────────────────────────────────

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_APP_URL || "",
  plugins: [organizationClient()],
});

// ─── Types ───────────────────────────────────────────────────────────────────

export interface User {
  id: string;
  name: string;
  email: string;
  image?: string | null;
  emailVerified: boolean;
  createdAt: string;
}

export interface AuthSession {
  user: User;
  session: {
    id: string;
    expiresAt: string;
    token: string;
  };
}

// ─── Auth Functions ──────────────────────────────────────────────────────────
// Thin wrappers around authClient to maintain the same API surface.

export async function signIn(email: string, password: string) {
  const result = await authClient.signIn.email({ email, password });
  if (result.error) {
    return {
      data: null,
      error: { message: result.error.message || "Sign in failed", code: result.error.code },
    };
  }
  return { data: result.data as AuthSession | null, error: null };
}

export async function signUp(name: string, email: string, password: string) {
  const result = await authClient.signUp.email({ name, email, password });
  if (result.error) {
    return {
      data: null,
      error: { message: result.error.message || "Sign up failed", code: result.error.code },
    };
  }
  return { data: result.data as AuthSession | null, error: null };
}

export async function signInWithGoogle() {
  await authClient.signIn.social({ provider: "google" });
}

// ─── useAuth Hook ────────────────────────────────────────────────────────────
// Uses Better Auth's useSession() under the hood but maintains our API surface.

interface AuthState {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
}

export function useAuth(): AuthState & {
  signIn: typeof signIn;
  signUp: typeof signUp;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
} {
  const session = authClient.useSession();

  const user = session.data?.user
    ? {
        id: session.data.user.id,
        name: session.data.user.name,
        email: session.data.user.email,
        image: session.data.user.image,
        emailVerified: session.data.user.emailVerified,
        createdAt: String(session.data.user.createdAt),
      }
    : null;

  const handleSignOut = useCallback(async () => {
    await authClient.signOut();
  }, []);

  const refresh = useCallback(async () => {
    // Better Auth's useSession auto-refreshes; this is a no-op for compatibility.
    // Force a re-fetch by calling getSession.
    await authClient.getSession();
  }, []);

  return {
    user,
    isLoading: session.isPending,
    isAuthenticated: !!session.data?.user,
    signIn,
    signUp,
    signOut: handleSignOut,
    refresh,
  };
}

// ─── Protected Route Wrapper ─────────────────────────────────────────────────

export function withAuth<P extends object>(
  Component: React.ComponentType<P & { user: User }>
): React.ComponentType<P> {
  return function ProtectedRoute(props: P) {
    const { user, isLoading, isAuthenticated } = useAuth();

    useEffect(() => {
      if (!isLoading && !isAuthenticated) {
        window.location.href = "/sign-in";
      }
    }, [isLoading, isAuthenticated]);

    if (isLoading) {
      return null;
    }

    if (!isAuthenticated || !user) {
      return null;
    }

    return <Component {...props} user={user} />;
  };
}
