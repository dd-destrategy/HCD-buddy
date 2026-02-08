"use client";

import { useState, useEffect, useCallback, createContext, useContext } from "react";

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

interface AuthError {
  message: string;
  code?: string;
}

// ─── API Helpers ─────────────────────────────────────────────────────────────

async function authFetch<T>(
  endpoint: string,
  options?: RequestInit
): Promise<{ data: T | null; error: AuthError | null }> {
  try {
    const response = await fetch(`/api/auth${endpoint}`, {
      headers: {
        "Content-Type": "application/json",
        ...options?.headers,
      },
      credentials: "include",
      ...options,
    });

    const data = await response.json();

    if (!response.ok) {
      return {
        data: null,
        error: {
          message: data.message || "An error occurred",
          code: data.code,
        },
      };
    }

    return { data, error: null };
  } catch (err) {
    return {
      data: null,
      error: {
        message: err instanceof Error ? err.message : "Network error",
        code: "NETWORK_ERROR",
      },
    };
  }
}

// ─── Auth Functions ──────────────────────────────────────────────────────────

export async function signIn(email: string, password: string) {
  return authFetch<AuthSession>("/sign-in/email", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
}

export async function signUp(
  name: string,
  email: string,
  password: string
) {
  return authFetch<AuthSession>("/sign-up/email", {
    method: "POST",
    body: JSON.stringify({ name, email, password }),
  });
}

export async function signOut() {
  return authFetch<{ success: boolean }>("/sign-out", {
    method: "POST",
  });
}

export async function signInWithGoogle() {
  // Redirect to Google OAuth flow
  window.location.href = "/api/auth/sign-in/social?provider=google";
}

export async function getCurrentUser(): Promise<User | null> {
  const { data } = await authFetch<{ user: User }>("/get-session");
  return data?.user ?? null;
}

// ─── useAuth Hook ────────────────────────────────────────────────────────────

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
  const [state, setState] = useState<AuthState>({
    user: null,
    isLoading: true,
    isAuthenticated: false,
  });

  const refresh = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true }));
    try {
      const user = await getCurrentUser();
      setState({
        user,
        isLoading: false,
        isAuthenticated: !!user,
      });
    } catch {
      setState({
        user: null,
        isLoading: false,
        isAuthenticated: false,
      });
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const handleSignOut = useCallback(async () => {
    await signOut();
    setState({
      user: null,
      isLoading: false,
      isAuthenticated: false,
    });
  }, []);

  return {
    ...state,
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
