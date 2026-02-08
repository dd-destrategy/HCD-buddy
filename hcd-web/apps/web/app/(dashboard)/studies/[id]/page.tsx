"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import { Card, CardContent, CardHeader, CardTitle } from "@hcd/ui";
import {
  BookOpen,
  Calendar,
  Clock,
  FileText,
  Highlighter,
  MessageSquare,
  Plus,
  Trash2,
  Edit3,
  Save,
  X,
  Download,
  ChevronLeft,
  BarChart3,
  Link2,
  Unlink,
  Search,
} from "lucide-react";
import { format } from "date-fns";
import * as Dialog from "@radix-ui/react-dialog";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Study {
  id: string;
  organizationId: string | null;
  ownerId: string;
  title: string;
  description: string | null;
  createdAt: string;
  updatedAt: string;
}

interface StudySession {
  id: string;
  title: string;
  status: string;
  sessionMode: string;
  startedAt: string | null;
  endedAt: string | null;
  durationSeconds: number | null;
  participantId: string | null;
  consentStatus: string | null;
  createdAt: string;
}

interface Analytics {
  sessionCount: number;
  totalDuration: number;
  highlightCount: number;
  utteranceCount: number;
  completedSessions: number;
}

const STATUS_COLORS: Record<string, string> = {
  draft: "bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200",
  active: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
  completed: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
  archived: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
};

// ─── Study Detail Page ──────────────────────────────────────────────────────

export default function StudyDetailPage() {
  const params = useParams();
  const router = useRouter();
  const studyId = params.id as string;

  const [study, setStudy] = useState<Study | null>(null);
  const [sessions, setSessions] = useState<StudySession[]>([]);
  const [analytics, setAnalytics] = useState<Analytics | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState("");
  const [editDescription, setEditDescription] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  // Add session dialog
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [availableSessions, setAvailableSessions] = useState<StudySession[]>([]);
  const [sessionSearch, setSessionSearch] = useState("");
  const [isLoadingSessions, setIsLoadingSessions] = useState(false);

  // ─── Fetch Study ────────────────────────────────────────────────────────

  const fetchStudy = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`/api/studies/${studyId}`);
      if (response.ok) {
        const data = await response.json();
        setStudy(data.study);
        setSessions(data.sessions);
        setAnalytics(data.analytics);
      } else if (response.status === 404) {
        router.push("/studies");
      }
    } catch (error) {
      console.error("Failed to fetch study:", error);
    } finally {
      setIsLoading(false);
    }
  }, [studyId, router]);

  useEffect(() => {
    fetchStudy();
  }, [fetchStudy]);

  // ─── Edit Study ─────────────────────────────────────────────────────────

  const startEditing = useCallback(() => {
    if (!study) return;
    setIsEditing(true);
    setEditTitle(study.title);
    setEditDescription(study.description || "");
  }, [study]);

  const saveChanges = useCallback(async () => {
    setIsSaving(true);
    try {
      const response = await fetch(`/api/studies/${studyId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: editTitle.trim(),
          description: editDescription.trim() || null,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setStudy(data.study);
        setIsEditing(false);
      }
    } catch (error) {
      console.error("Failed to save study:", error);
    } finally {
      setIsSaving(false);
    }
  }, [studyId, editTitle, editDescription]);

  // ─── Delete Study ───────────────────────────────────────────────────────

  const handleDelete = useCallback(async () => {
    if (!confirm("Delete this study? Sessions will be preserved but unlinked.")) return;

    try {
      const response = await fetch(`/api/studies/${studyId}`, {
        method: "DELETE",
      });

      if (response.ok) {
        router.push("/studies");
      }
    } catch (error) {
      console.error("Failed to delete study:", error);
    }
  }, [studyId, router]);

  // ─── Session Management ─────────────────────────────────────────────────

  const fetchAvailableSessions = useCallback(async () => {
    setIsLoadingSessions(true);
    try {
      const params = new URLSearchParams();
      if (sessionSearch) params.set("search", sessionSearch);
      params.set("limit", "50");

      const response = await fetch(`/api/sessions?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        // Filter out sessions already in this study
        const studySessionIds = new Set(sessions.map((s) => s.id));
        setAvailableSessions(
          (data.sessions || []).filter(
            (s: any) => !studySessionIds.has(s.id) && !s.studyId
          )
        );
      }
    } catch (error) {
      console.error("Failed to fetch sessions:", error);
    } finally {
      setIsLoadingSessions(false);
    }
  }, [sessionSearch, sessions]);

  useEffect(() => {
    if (showAddDialog) {
      const debounce = setTimeout(fetchAvailableSessions, 300);
      return () => clearTimeout(debounce);
    }
  }, [showAddDialog, fetchAvailableSessions]);

  const addSession = useCallback(
    async (sessionId: string) => {
      try {
        const response = await fetch(`/api/studies/${studyId}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action: "add", sessionId }),
        });

        if (response.ok) {
          await fetchStudy();
          setShowAddDialog(false);
        }
      } catch (error) {
        console.error("Failed to add session:", error);
      }
    },
    [studyId, fetchStudy]
  );

  const removeSession = useCallback(
    async (sessionId: string) => {
      if (!confirm("Remove this session from the study? The session data will be preserved.")) return;

      try {
        const response = await fetch(`/api/studies/${studyId}`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ action: "remove", sessionId }),
        });

        if (response.ok) {
          setSessions((prev) => prev.filter((s) => s.id !== sessionId));
          if (analytics) {
            setAnalytics({
              ...analytics,
              sessionCount: analytics.sessionCount - 1,
            });
          }
        }
      } catch (error) {
        console.error("Failed to remove session:", error);
      }
    },
    [studyId, analytics]
  );

  // ─── Export Study ───────────────────────────────────────────────────────

  const handleExport = useCallback(() => {
    if (!study || !analytics) return;

    const exportData = {
      study: {
        title: study.title,
        description: study.description,
        createdAt: study.createdAt,
      },
      analytics,
      sessions: sessions.map((s) => ({
        title: s.title,
        status: s.status,
        mode: s.sessionMode,
        startedAt: s.startedAt,
        durationMinutes: s.durationSeconds ? Math.round(s.durationSeconds / 60) : null,
      })),
    };

    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `study-${study.title.toLowerCase().replace(/\s+/g, "-")}-${format(new Date(), "yyyy-MM-dd")}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [study, analytics, sessions]);

  // ─── Helpers ────────────────────────────────────────────────────────────

  function formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  }

  // ─── Loading State ──────────────────────────────────────────────────────

  if (isLoading || !study) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-sm text-muted-foreground">Loading study...</div>
      </div>
    );
  }

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      {/* Back button */}
      <Button
        variant="ghost"
        size="sm"
        onClick={() => router.push("/studies")}
      >
        <ChevronLeft className="h-4 w-4 mr-1" />
        All Studies
      </Button>

      {/* Study Header */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-start justify-between">
            <div className="flex items-start gap-4 flex-1">
              <div className="h-12 w-12 rounded-lg bg-primary/10 flex items-center justify-center shrink-0">
                <BookOpen className="h-6 w-6 text-primary" />
              </div>
              {isEditing ? (
                <div className="flex-1 space-y-2">
                  <Input
                    value={editTitle}
                    onChange={(e) => setEditTitle(e.target.value)}
                    className="text-xl font-semibold"
                    aria-label="Study title"
                    autoFocus
                  />
                  <textarea
                    value={editDescription}
                    onChange={(e) => setEditDescription(e.target.value)}
                    placeholder="Add a description..."
                    rows={3}
                    className="flex w-full rounded-lg border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring resize-none"
                    aria-label="Study description"
                  />
                </div>
              ) : (
                <div className="flex-1">
                  <h1 className="text-2xl font-semibold">{study.title}</h1>
                  {study.description && (
                    <p className="text-sm text-muted-foreground mt-1">
                      {study.description}
                    </p>
                  )}
                  <div className="flex items-center gap-3 mt-2 text-xs text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Calendar className="h-3 w-3" />
                      Created {format(new Date(study.createdAt), "MMM d, yyyy")}
                    </span>
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" />
                      Updated {format(new Date(study.updatedAt), "MMM d, yyyy")}
                    </span>
                  </div>
                </div>
              )}
            </div>

            <div className="flex items-center gap-2 shrink-0 ml-4">
              {isEditing ? (
                <>
                  <Button
                    size="sm"
                    onClick={saveChanges}
                    disabled={isSaving || !editTitle.trim()}
                  >
                    <Save className="h-4 w-4 mr-1.5" />
                    {isSaving ? "Saving..." : "Save"}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setIsEditing(false)}
                  >
                    <X className="h-4 w-4" />
                  </Button>
                </>
              ) : (
                <>
                  <Button variant="outline" size="sm" onClick={startEditing}>
                    <Edit3 className="h-4 w-4 mr-1.5" />
                    Edit
                  </Button>
                  <Button variant="outline" size="sm" onClick={handleExport}>
                    <Download className="h-4 w-4 mr-1.5" />
                    Export
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-destructive hover:text-destructive"
                    onClick={handleDelete}
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Analytics Summary */}
      {analytics && (
        <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
          <Card>
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold">{analytics.sessionCount}</div>
              <div className="text-xs text-muted-foreground mt-1">Sessions</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold">{analytics.completedSessions}</div>
              <div className="text-xs text-muted-foreground mt-1">Completed</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold">
                {formatDuration(analytics.totalDuration)}
              </div>
              <div className="text-xs text-muted-foreground mt-1">Total Time</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold">{analytics.highlightCount}</div>
              <div className="text-xs text-muted-foreground mt-1">Highlights</div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="p-4 text-center">
              <div className="text-2xl font-bold">{analytics.utteranceCount}</div>
              <div className="text-xs text-muted-foreground mt-1">Utterances</div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Sessions List */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">
              Sessions ({sessions.length})
            </CardTitle>
            <Button size="sm" onClick={() => setShowAddDialog(true)}>
              <Plus className="h-4 w-4 mr-1.5" />
              Add Session
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {sessions.length === 0 ? (
            <div className="text-center py-8">
              <div className="rounded-full bg-muted p-3 mx-auto w-fit mb-3">
                <FileText className="h-6 w-6 text-muted-foreground" />
              </div>
              <p className="text-sm text-muted-foreground mb-3">
                No sessions in this study yet
              </p>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowAddDialog(true)}
              >
                <Link2 className="h-4 w-4 mr-1.5" />
                Link Existing Session
              </Button>
            </div>
          ) : (
            <div className="space-y-2">
              {sessions.map((session) => (
                <div
                  key={session.id}
                  className="group flex items-center gap-3 rounded-lg border p-3 hover:bg-accent/30 transition-colors"
                >
                  <FileText className="h-4 w-4 text-muted-foreground shrink-0" />
                  <button
                    type="button"
                    onClick={() => router.push(`/sessions/${session.id}`)}
                    className="flex-1 min-w-0 text-left"
                  >
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium truncate">
                        {session.title}
                      </span>
                      <Badge
                        className={`text-xs border-0 ${STATUS_COLORS[session.status] || STATUS_COLORS.draft}`}
                      >
                        {session.status}
                      </Badge>
                      <Badge variant="outline" className="text-xs">
                        {session.sessionMode}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground mt-0.5">
                      {session.startedAt && (
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          {format(new Date(session.startedAt), "MMM d, yyyy")}
                        </span>
                      )}
                      {session.durationSeconds && (
                        <span className="flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {formatDuration(session.durationSeconds)}
                        </span>
                      )}
                    </div>
                  </button>
                  <Button
                    variant="ghost"
                    size="icon"
                    className="h-7 w-7 opacity-0 group-hover:opacity-100 transition-opacity shrink-0"
                    onClick={() => removeSession(session.id)}
                    aria-label={`Remove ${session.title} from study`}
                  >
                    <Unlink className="h-3.5 w-3.5 text-muted-foreground" />
                  </Button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Add Session Dialog */}
      <Dialog.Root open={showAddDialog} onOpenChange={setShowAddDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50" />
          <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-lg rounded-xl border bg-card p-6 shadow-xl z-50 focus:outline-none">
            <Dialog.Title className="text-lg font-semibold mb-4">
              Add Session to Study
            </Dialog.Title>

            <div className="relative mb-4">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                value={sessionSearch}
                onChange={(e) => setSessionSearch(e.target.value)}
                placeholder="Search sessions..."
                className="pl-9"
                aria-label="Search available sessions"
              />
            </div>

            <div className="max-h-64 overflow-y-auto space-y-2 scrollbar-thin">
              {isLoadingSessions ? (
                <div className="text-sm text-muted-foreground text-center py-4">
                  Loading sessions...
                </div>
              ) : availableSessions.length === 0 ? (
                <div className="text-sm text-muted-foreground text-center py-4">
                  No available sessions found
                </div>
              ) : (
                availableSessions.map((session) => (
                  <button
                    key={session.id}
                    type="button"
                    onClick={() => addSession(session.id)}
                    className="w-full flex items-center gap-3 rounded-lg border p-3 text-left hover:bg-accent/30 transition-colors"
                  >
                    <FileText className="h-4 w-4 text-muted-foreground shrink-0" />
                    <div className="flex-1 min-w-0">
                      <span className="text-sm font-medium truncate block">
                        {session.title}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {session.startedAt
                          ? format(new Date(session.startedAt), "MMM d, yyyy")
                          : format(new Date(session.createdAt), "MMM d, yyyy")}
                      </span>
                    </div>
                    <Badge variant="outline" className="text-xs shrink-0">
                      {session.status}
                    </Badge>
                    <Link2 className="h-3.5 w-3.5 text-muted-foreground shrink-0" />
                  </button>
                ))
              )}
            </div>

            <div className="flex justify-end mt-4">
              <Dialog.Close asChild>
                <Button variant="ghost">Cancel</Button>
              </Dialog.Close>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  );
}
