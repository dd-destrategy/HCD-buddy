import Link from 'next/link';
import { Plus, Upload, Search, Filter, Clock, Calendar, ArrowUpDown, FileText } from 'lucide-react';
import { Button, Card, Badge, Input } from '@hcd/ui';

// =============================================================================
// Sessions List Page — Server component with pagination, search, and filters
// =============================================================================

interface SessionListItem {
  id: string;
  title: string;
  sessionMode: string;
  status: string;
  startedAt: string | null;
  endedAt: string | null;
  durationSeconds: number | null;
  participantId: string | null;
  participantName: string | null;
  studyId: string | null;
  studyTitle: string | null;
  consentStatus: string;
  coachingEnabled: boolean;
  createdAt: string;
  updatedAt: string;
}

interface SessionsResponse {
  data: SessionListItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

async function fetchSessions(searchParams: Record<string, string | undefined>): Promise<SessionsResponse> {
  const params = new URLSearchParams();

  if (searchParams.page) params.set('page', searchParams.page);
  if (searchParams.search) params.set('search', searchParams.search);
  if (searchParams.status) params.set('status', searchParams.status);
  if (searchParams.studyId) params.set('studyId', searchParams.studyId);
  if (searchParams.participantId) params.set('participantId', searchParams.participantId);
  if (searchParams.dateFrom) params.set('dateFrom', searchParams.dateFrom);
  if (searchParams.dateTo) params.set('dateTo', searchParams.dateTo);
  if (searchParams.sortBy) params.set('sortBy', searchParams.sortBy);
  if (searchParams.sortOrder) params.set('sortOrder', searchParams.sortOrder);
  params.set('limit', '20');

  const baseUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';
  const res = await fetch(`${baseUrl}/api/sessions?${params.toString()}`, {
    cache: 'no-store',
  });

  if (!res.ok) {
    return { data: [], pagination: { page: 1, limit: 20, total: 0, totalPages: 0 } };
  }

  return res.json();
}

function formatDuration(seconds: number | null): string {
  if (!seconds) return '--';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

function formatDate(dateStr: string | null): string {
  if (!dateStr) return '--';
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function getStatusVariant(status: string): 'default' | 'success' | 'warning' | 'destructive' | 'secondary' | 'info' {
  switch (status) {
    case 'running':
      return 'success';
    case 'paused':
      return 'warning';
    case 'ended':
      return 'secondary';
    case 'draft':
      return 'info';
    case 'failed':
      return 'destructive';
    default:
      return 'default';
  }
}

export default async function SessionsPage({
  searchParams,
}: {
  searchParams: Promise<Record<string, string | undefined>>;
}) {
  const resolvedParams = await searchParams;
  const { data: sessions, pagination } = await fetchSessions(resolvedParams);

  const currentPage = pagination.page;
  const currentSort = resolvedParams.sortBy || 'date';
  const currentOrder = resolvedParams.sortOrder || 'desc';

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Sessions</h1>
          <p className="text-sm text-muted-foreground mt-1">
            {pagination.total} session{pagination.total !== 1 ? 's' : ''} total
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Link href="/sessions/import">
            <Button variant="outline" size="sm" aria-label="Import sessions">
              <Upload className="h-4 w-4 mr-2" aria-hidden="true" />
              Import
            </Button>
          </Link>
          <Link href="/sessions/new">
            <Button size="sm" aria-label="Create new session">
              <Plus className="h-4 w-4 mr-2" aria-hidden="true" />
              New Session
            </Button>
          </Link>
        </div>
      </div>

      {/* Filters bar */}
      <Card className="p-4">
        <form method="get" className="flex flex-wrap items-end gap-3">
          {/* Search */}
          <div className="flex-1 min-w-[200px]">
            <label htmlFor="search" className="text-xs font-medium text-muted-foreground mb-1 block">
              Search
            </label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" aria-hidden="true" />
              <Input
                id="search"
                name="search"
                type="text"
                placeholder="Search by title..."
                defaultValue={resolvedParams.search || ''}
                className="pl-9"
                aria-label="Search sessions by title"
              />
            </div>
          </div>

          {/* Status filter */}
          <div>
            <label htmlFor="status" className="text-xs font-medium text-muted-foreground mb-1 block">
              Status
            </label>
            <select
              id="status"
              name="status"
              defaultValue={resolvedParams.status || ''}
              className="flex h-10 rounded-lg border border-input bg-background px-3 py-2 text-sm"
              aria-label="Filter by status"
            >
              <option value="">All statuses</option>
              <option value="draft">Draft</option>
              <option value="running">Running</option>
              <option value="paused">Paused</option>
              <option value="ended">Ended</option>
              <option value="failed">Failed</option>
            </select>
          </div>

          {/* Date from */}
          <div>
            <label htmlFor="dateFrom" className="text-xs font-medium text-muted-foreground mb-1 block">
              From
            </label>
            <Input
              id="dateFrom"
              name="dateFrom"
              type="date"
              defaultValue={resolvedParams.dateFrom || ''}
              aria-label="Filter from date"
            />
          </div>

          {/* Date to */}
          <div>
            <label htmlFor="dateTo" className="text-xs font-medium text-muted-foreground mb-1 block">
              To
            </label>
            <Input
              id="dateTo"
              name="dateTo"
              type="date"
              defaultValue={resolvedParams.dateTo || ''}
              aria-label="Filter to date"
            />
          </div>

          {/* Sort */}
          <div>
            <label htmlFor="sortBy" className="text-xs font-medium text-muted-foreground mb-1 block">
              Sort by
            </label>
            <select
              id="sortBy"
              name="sortBy"
              defaultValue={currentSort}
              className="flex h-10 rounded-lg border border-input bg-background px-3 py-2 text-sm"
              aria-label="Sort sessions"
            >
              <option value="date">Date</option>
              <option value="title">Title</option>
              <option value="duration">Duration</option>
            </select>
          </div>

          <input type="hidden" name="sortOrder" value={currentOrder} />

          <Button type="submit" variant="secondary" size="sm" aria-label="Apply filters">
            <Filter className="h-4 w-4 mr-1" aria-hidden="true" />
            Filter
          </Button>
        </form>
      </Card>

      {/* Session list */}
      {sessions.length === 0 ? (
        <Card className="flex flex-col items-center justify-center py-16">
          <FileText className="h-12 w-12 text-muted-foreground/40 mb-4" aria-hidden="true" />
          <h2 className="text-lg font-medium">No sessions found</h2>
          <p className="text-sm text-muted-foreground mt-1 max-w-sm text-center">
            {resolvedParams.search || resolvedParams.status
              ? 'Try adjusting your filters or search term.'
              : 'Get started by creating your first interview session.'}
          </p>
          {!resolvedParams.search && !resolvedParams.status && (
            <Link href="/sessions/new" className="mt-4">
              <Button size="sm">
                <Plus className="h-4 w-4 mr-2" aria-hidden="true" />
                Create Session
              </Button>
            </Link>
          )}
        </Card>
      ) : (
        <div className="space-y-2">
          {sessions.map((session) => (
            <Link key={session.id} href={`/sessions/${session.id}`}>
              <Card className="flex items-center gap-4 p-4 hover:bg-muted/30 transition-colors cursor-pointer">
                {/* Title and study */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <h3 className="font-medium truncate">{session.title}</h3>
                    <Badge variant={getStatusVariant(session.status)} className="shrink-0">
                      {session.status}
                    </Badge>
                  </div>
                  <div className="flex items-center gap-3 mt-1 text-xs text-muted-foreground">
                    {session.studyTitle && (
                      <span className="truncate max-w-[200px]">{session.studyTitle}</span>
                    )}
                    {session.participantName && (
                      <span className="truncate">{session.participantName}</span>
                    )}
                  </div>
                </div>

                {/* Date */}
                <div className="flex items-center gap-1.5 text-sm text-muted-foreground shrink-0">
                  <Calendar className="h-3.5 w-3.5" aria-hidden="true" />
                  <span>{formatDate(session.startedAt || session.createdAt)}</span>
                </div>

                {/* Duration */}
                <div className="flex items-center gap-1.5 text-sm text-muted-foreground shrink-0 w-16">
                  <Clock className="h-3.5 w-3.5" aria-hidden="true" />
                  <span>{formatDuration(session.durationSeconds)}</span>
                </div>

                {/* Mode badge */}
                <Badge variant="outline" className="shrink-0 capitalize">
                  {session.sessionMode}
                </Badge>
              </Card>
            </Link>
          ))}
        </div>
      )}

      {/* Pagination */}
      {pagination.totalPages > 1 && (
        <nav className="flex items-center justify-center gap-2" aria-label="Pagination">
          {currentPage > 1 && (
            <Link
              href={`/sessions?page=${currentPage - 1}${resolvedParams.search ? `&search=${resolvedParams.search}` : ''}${resolvedParams.status ? `&status=${resolvedParams.status}` : ''}`}
            >
              <Button variant="outline" size="sm" aria-label="Previous page">
                Previous
              </Button>
            </Link>
          )}

          <span className="text-sm text-muted-foreground px-3">
            Page {currentPage} of {pagination.totalPages}
          </span>

          {currentPage < pagination.totalPages && (
            <Link
              href={`/sessions?page=${currentPage + 1}${resolvedParams.search ? `&search=${resolvedParams.search}` : ''}${resolvedParams.status ? `&status=${resolvedParams.status}` : ''}`}
            >
              <Button variant="outline" size="sm" aria-label="Next page">
                Next
              </Button>
            </Link>
          )}
        </nav>
      )}
    </div>
  );
}
