import Link from 'next/link';
import { notFound } from 'next/navigation';
import {
  Calendar,
  Clock,
  User,
  BookOpen,
  Play,
  MessageSquare,
  Flag,
  Highlighter,
  Download,
  ArrowLeft,
  Shield,
} from 'lucide-react';
import { Button, Card, Badge } from '@hcd/ui';
import { SessionDetailClient } from './session-detail-client';

// =============================================================================
// Session Detail Page — Server component fetching session data, with client tabs
// =============================================================================

interface SessionData {
  id: string;
  title: string;
  sessionMode: string;
  status: string;
  startedAt: string | null;
  endedAt: string | null;
  durationSeconds: number | null;
  participantName: string | null;
  participantEmail: string | null;
  participantRole: string | null;
  studyTitle: string | null;
  consentStatus: string | null;
  coachingEnabled: boolean;
  meetingUrl: string | null;
  summary: Record<string, unknown> | null;
  utterances: Array<{
    id: string;
    speaker: string;
    text: string;
    startTime: number;
    endTime: number | null;
    sentimentScore: number | null;
    sentimentPolarity: string | null;
    questionType: string | null;
    isRedacted: boolean;
  }>;
  insights: Array<{
    id: string;
    source: string;
    note: string | null;
    timestamp: number;
  }>;
  topics: Array<{
    id: string;
    topicName: string;
    status: string;
  }>;
  coachingEvents: Array<{
    id: string;
    promptType: string;
    promptText: string;
    confidence: number | null;
  }>;
  highlights: Array<{
    id: string;
    title: string;
    category: string;
    textSelection: string;
    notes: string | null;
    isStarred: boolean;
  }>;
}

async function fetchSession(id: string): Promise<SessionData | null> {
  const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';
  const res = await fetch(`${baseUrl}/api/sessions/${id}`, { cache: 'no-store' });
  if (!res.ok) return null;
  const json = await res.json();
  return json.data;
}

function formatDuration(seconds: number | null): string {
  if (!seconds) return '--';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = seconds % 60;
  if (h > 0) return `${h}h ${m}m ${s}s`;
  return `${m}m ${s}s`;
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return '--';
  return new Date(dateStr).toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function getStatusVariant(status: string): 'default' | 'success' | 'warning' | 'destructive' | 'secondary' | 'info' {
  switch (status) {
    case 'running': return 'success';
    case 'paused': return 'warning';
    case 'ended': return 'secondary';
    case 'draft': return 'info';
    case 'failed': return 'destructive';
    default: return 'default';
  }
}

export default async function SessionDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const session = await fetchSession(id);

  if (!session) {
    notFound();
  }

  return (
    <div className="flex flex-col gap-6">
      {/* Back link */}
      <Link
        href="/sessions"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors w-fit"
        aria-label="Back to sessions list"
      >
        <ArrowLeft className="h-4 w-4" aria-hidden="true" />
        Back to sessions
      </Link>

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl font-semibold tracking-tight">{session.title}</h1>
            <Badge variant={getStatusVariant(session.status)} className="capitalize">
              {session.status}
            </Badge>
          </div>

          <div className="flex items-center flex-wrap gap-4 mt-2 text-sm text-muted-foreground">
            {session.startedAt && (
              <span className="flex items-center gap-1.5">
                <Calendar className="h-3.5 w-3.5" aria-hidden="true" />
                {formatDate(session.startedAt)}
              </span>
            )}
            <span className="flex items-center gap-1.5">
              <Clock className="h-3.5 w-3.5" aria-hidden="true" />
              {formatDuration(session.durationSeconds)}
            </span>
            {session.participantName && (
              <span className="flex items-center gap-1.5">
                <User className="h-3.5 w-3.5" aria-hidden="true" />
                {session.participantName}
              </span>
            )}
            {session.studyTitle && (
              <span className="flex items-center gap-1.5">
                <BookOpen className="h-3.5 w-3.5" aria-hidden="true" />
                {session.studyTitle}
              </span>
            )}
            {session.consentStatus && session.consentStatus !== 'not_obtained' && (
              <span className="flex items-center gap-1.5">
                <Shield className="h-3.5 w-3.5" aria-hidden="true" />
                Consent: {session.consentStatus}
              </span>
            )}
          </div>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          {session.status === 'running' || session.status === 'paused' ? (
            <Link href={`/sessions/${session.id}/live`}>
              <Button size="sm" aria-label="Rejoin live session">
                <Play className="h-4 w-4 mr-2" aria-hidden="true" />
                Rejoin Live
              </Button>
            </Link>
          ) : null}
          <Badge variant="outline" className="capitalize">
            {session.sessionMode.replace('_', ' ')}
          </Badge>
        </div>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard
          icon={MessageSquare}
          label="Utterances"
          value={session.utterances.length.toString()}
        />
        <StatCard
          icon={Flag}
          label="Insights"
          value={session.insights.length.toString()}
        />
        <StatCard
          icon={Highlighter}
          label="Highlights"
          value={session.highlights.length.toString()}
        />
        <StatCard
          icon={BookOpen}
          label="Topics"
          value={`${session.topics.filter((t) => t.status === 'covered').length}/${session.topics.length}`}
        />
      </div>

      {/* Tabbed content — client component */}
      <SessionDetailClient session={session} />
    </div>
  );
}

// =============================================================================
// StatCard — Small stat display
// =============================================================================

function StatCard({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof MessageSquare;
  label: string;
  value: string;
}) {
  return (
    <Card className="flex items-center gap-3 p-4">
      <div className="rounded-lg bg-muted p-2">
        <Icon className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
      </div>
      <div>
        <p className="text-2xl font-semibold">{value}</p>
        <p className="text-xs text-muted-foreground">{label}</p>
      </div>
    </Card>
  );
}
