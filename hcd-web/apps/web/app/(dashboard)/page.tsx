"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import {
  Plus,
  Upload,
  BarChart3,
  Clock,
  Mic,
  Sparkles,
  ArrowRight,
  CalendarDays,
  Timer,
  Highlighter,
} from "lucide-react";
import { useAuth } from "@/lib/auth-client";

interface QuickStat {
  label: string;
  value: string;
  icon: React.ReactNode;
  trend?: string;
}

interface RecentSession {
  id: string;
  title: string;
  date: string;
  duration: string;
  highlights: number;
  status: "completed" | "in-progress" | "draft";
}

// Placeholder data -- will be replaced with real API calls
const placeholderStats: QuickStat[] = [
  {
    label: "Total Sessions",
    value: "0",
    icon: <Mic className="h-5 w-5" />,
  },
  {
    label: "Total Hours",
    value: "0h",
    icon: <Timer className="h-5 w-5" />,
  },
  {
    label: "Highlights",
    value: "0",
    icon: <Highlighter className="h-5 w-5" />,
  },
];

const placeholderSessions: RecentSession[] = [];

export default function DashboardHomePage() {
  const { user } = useAuth();
  const [stats] = useState<QuickStat[]>(placeholderStats);
  const [recentSessions] = useState<RecentSession[]>(placeholderSessions);

  const firstName = user?.name?.split(" ")[0] || "there";
  const greeting = getGreeting();

  return (
    <div className="mx-auto max-w-5xl space-y-8">
      {/* Welcome header */}
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">
          {greeting}, {firstName}
        </h1>
        <p className="mt-1 text-muted-foreground">
          Here is what is happening with your research.
        </p>
      </div>

      {/* Quick actions */}
      <div className="grid gap-4 sm:grid-cols-3">
        <QuickAction
          href="/sessions/new"
          icon={<Plus className="h-5 w-5" />}
          label="New Session"
          description="Start a new interview session"
          primary
        />
        <QuickAction
          href="/sessions/import"
          icon={<Upload className="h-5 w-5" />}
          label="Import Session"
          description="Upload an existing recording"
        />
        <QuickAction
          href="/analytics"
          icon={<BarChart3 className="h-5 w-5" />}
          label="View Analytics"
          description="Cross-session insights"
        />
      </div>

      {/* Stats */}
      <div className="grid gap-4 sm:grid-cols-3">
        {stats.map((stat) => (
          <div
            key={stat.label}
            className="rounded-xl border border-border bg-card p-5"
          >
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">{stat.label}</span>
              <span className="text-muted-foreground/50">{stat.icon}</span>
            </div>
            <div className="mt-2 flex items-end gap-2">
              <span className="text-3xl font-bold tracking-tight">
                {stat.value}
              </span>
              {stat.trend && (
                <span className="mb-1 text-xs text-green-600 dark:text-green-400">
                  {stat.trend}
                </span>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Recent sessions */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold">Recent Sessions</h2>
          <Link
            href="/sessions"
            className="flex items-center gap-1 text-sm text-primary hover:underline"
          >
            View all
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>

        {recentSessions.length === 0 ? (
          <div className="rounded-xl border border-dashed border-border bg-card/50 p-12 text-center">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
              <Sparkles className="h-6 w-6 text-primary" />
            </div>
            <h3 className="text-lg font-medium">No sessions yet</h3>
            <p className="mt-2 text-sm text-muted-foreground max-w-sm mx-auto">
              Start your first interview session to begin capturing insights
              and receiving AI-powered coaching.
            </p>
            <Link
              href="/sessions/new"
              className="mt-6 inline-flex h-10 items-center justify-center gap-2 rounded-lg bg-primary px-6 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
            >
              <Plus className="h-4 w-4" />
              New Session
            </Link>
          </div>
        ) : (
          <div className="rounded-xl border border-border bg-card divide-y divide-border">
            {recentSessions.map((session) => (
              <Link
                key={session.id}
                href={`/sessions/${session.id}/review`}
                className="flex items-center gap-4 p-4 hover:bg-accent/50 transition-colors first:rounded-t-xl last:rounded-b-xl"
              >
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-primary/10 text-primary">
                  <Mic className="h-5 w-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium truncate">{session.title}</p>
                  <div className="flex items-center gap-3 mt-0.5 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <CalendarDays className="h-3 w-3" />
                      {session.date}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      {session.duration}
                    </span>
                    <span className="flex items-center gap-1">
                      <Highlighter className="h-3 w-3" />
                      {session.highlights} highlights
                    </span>
                  </div>
                </div>
                <SessionStatusBadge status={session.status} />
                <ArrowRight className="h-4 w-4 text-muted-foreground" />
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function QuickAction({
  href,
  icon,
  label,
  description,
  primary = false,
}: {
  href: string;
  icon: React.ReactNode;
  label: string;
  description: string;
  primary?: boolean;
}) {
  return (
    <Link
      href={href}
      className={`group flex items-center gap-4 rounded-xl border p-4 transition-colors ${
        primary
          ? "border-primary/20 bg-primary/5 hover:bg-primary/10"
          : "border-border bg-card hover:bg-accent/50"
      }`}
      aria-label={label}
    >
      <div
        className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${
          primary
            ? "bg-primary text-primary-foreground"
            : "bg-muted text-muted-foreground group-hover:text-foreground"
        }`}
      >
        {icon}
      </div>
      <div>
        <p className="font-medium">{label}</p>
        <p className="text-xs text-muted-foreground">{description}</p>
      </div>
    </Link>
  );
}

function SessionStatusBadge({
  status,
}: {
  status: "completed" | "in-progress" | "draft";
}) {
  const styles = {
    completed:
      "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400",
    "in-progress":
      "bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-400",
    draft:
      "bg-muted text-muted-foreground",
  };

  const labels = {
    completed: "Completed",
    "in-progress": "In Progress",
    draft: "Draft",
  };

  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${styles[status]}`}
    >
      {labels[status]}
    </span>
  );
}

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return "Good morning";
  if (hour < 17) return "Good afternoon";
  return "Good evening";
}
