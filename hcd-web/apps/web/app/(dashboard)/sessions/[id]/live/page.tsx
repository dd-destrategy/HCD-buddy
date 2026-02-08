'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import {
  Pause,
  Play,
  Square,
  Flag,
  Users,
  Wifi,
  WifiOff,
  AlertTriangle,
  MessageSquare,
  Check,
  X,
  Clock,
  Loader2,
} from 'lucide-react';
import { Button, Card, Badge } from '@hcd/ui';
import { useWebSocket } from '@/hooks/use-websocket';
import { TranscriptPanel } from '@/components/transcript/transcript-panel';
import { SessionTimer } from '@/components/session/session-timer';
import { TalkTimeIndicator } from '@/components/session/talk-time-indicator';
import { TopicTracker } from '@/components/session/topic-tracker';
import { FocusModeSwitcher, type FocusMode } from '@/components/session/focus-mode-switcher';

// =============================================================================
// Live Session Page — Real-time session interface
// =============================================================================

export default function LiveSessionPage() {
  const params = useParams();
  const router = useRouter();
  const sessionId = params.id as string;

  // Session metadata (fetched once on mount)
  const [sessionMeta, setSessionMeta] = useState<{
    title: string;
    participantName: string | null;
    meetingUrl: string | null;
    startedAt: string | null;
    coachingEnabled: boolean;
  } | null>(null);

  const [focusMode, setFocusMode] = useState<FocusMode>('coached');
  const [isPaused, setIsPaused] = useState(false);
  const [isEnded, setIsEnded] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  // WebSocket connection
  const ws = useWebSocket();

  // Fetch session metadata
  useEffect(() => {
    fetch(`/api/sessions/${sessionId}`)
      .then((r) => (r.ok ? r.json() : null))
      .then((data) => {
        if (data?.data) {
          setSessionMeta({
            title: data.data.title,
            participantName: data.data.participantName,
            meetingUrl: data.data.meetingUrl,
            startedAt: data.data.startedAt,
            coachingEnabled: data.data.coachingEnabled,
          });
        }
        setIsLoading(false);
      })
      .catch(() => setIsLoading(false));
  }, [sessionId]);

  // Connect WebSocket on mount
  useEffect(() => {
    if (sessionMeta) {
      ws.connect(
        sessionId,
        sessionMeta.meetingUrl || undefined,
        !sessionMeta.meetingUrl
      );
    }
    return () => {
      ws.disconnect();
    };
  }, [sessionId, sessionMeta]); // eslint-disable-line react-hooks/exhaustive-deps

  // Track session status from server
  useEffect(() => {
    if (ws.sessionStatus === 'paused') setIsPaused(true);
    if (ws.sessionStatus === 'running') setIsPaused(false);
    if (ws.sessionStatus === 'ended') setIsEnded(true);
  }, [ws.sessionStatus]);

  // Keyboard shortcuts
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (!e.metaKey && !e.ctrlKey) return;

      switch (e.key.toLowerCase()) {
        case 'i': // Flag insight
          e.preventDefault();
          handleFlagInsight();
          break;
        case 'p': // Pause/Resume
          e.preventDefault();
          handleTogglePause();
          break;
        case 'r': // Stop
          e.preventDefault();
          handleStop();
          break;
        case 't': // Toggle speaker
          e.preventDefault();
          ws.toggleSpeaker();
          break;
      }
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isPaused, isEnded]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleFlagInsight = useCallback(() => {
    const timestamp = sessionMeta?.startedAt
      ? (Date.now() - new Date(sessionMeta.startedAt).getTime()) / 1000
      : 0;
    ws.flagInsight(timestamp);
  }, [ws, sessionMeta]);

  const handleTogglePause = useCallback(() => {
    if (isEnded) return;
    if (isPaused) {
      ws.resumeSession();
      setIsPaused(false);
    } else {
      ws.pauseSession();
      setIsPaused(true);
    }
  }, [ws, isPaused, isEnded]);

  const handleStop = useCallback(() => {
    if (isEnded) return;
    ws.stopSession();
    setIsEnded(true);
  }, [ws, isEnded]);

  const handleCoachingRespond = useCallback(
    (eventId: string, response: 'accepted' | 'dismissed' | 'snoozed') => {
      ws.respondToCoaching(eventId, response);
    },
    [ws]
  );

  // Connection quality icon
  const ConnectionIcon = useMemo(() => {
    if (ws.status === 'disconnected' || ws.status === 'error') return WifiOff;
    if (ws.quality === 'poor') return AlertTriangle;
    return Wifi;
  }, [ws.status, ws.quality]);

  const connectionColor = useMemo(() => {
    if (ws.status !== 'connected') return 'text-red-500';
    if (ws.quality === 'poor') return 'text-red-500';
    if (ws.quality === 'degraded') return 'text-yellow-500';
    return 'text-green-500';
  }, [ws.status, ws.quality]);

  // Active coaching prompts (only the latest few)
  const activePrompts = ws.coachingEvents.slice(-3);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" aria-label="Loading session" />
      </div>
    );
  }

  if (!sessionMeta) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-muted-foreground gap-3">
        <AlertTriangle className="h-8 w-8" aria-hidden="true" />
        <p className="text-sm font-medium">Session not found</p>
        <Button variant="outline" size="sm" onClick={() => router.push('/sessions')}>
          Back to sessions
        </Button>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-[calc(100vh-var(--header-height))] overflow-hidden -m-6">
      {/* Top bar */}
      <header className="flex items-center justify-between px-4 py-2 border-b bg-background shrink-0">
        <div className="flex items-center gap-3">
          <SessionTimer
            startedAt={sessionMeta.startedAt}
            isPaused={isPaused}
            isEnded={isEnded}
          />
          <div className="hidden sm:block">
            <TalkTimeIndicator ratio={ws.talkTimeRatio} className="w-48" />
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* Connection quality */}
          <div
            className={`flex items-center gap-1 text-xs ${connectionColor}`}
            title={`Connection: ${ws.status} (${ws.quality}, ${ws.latency}ms)`}
            aria-label={`Connection status: ${ws.status}, quality: ${ws.quality}`}
          >
            <ConnectionIcon className="h-4 w-4" aria-hidden="true" />
            {ws.latency > 0 && <span className="tabular-nums">{ws.latency}ms</span>}
          </div>

          {/* Observer count */}
          {ws.observerCount > 0 && (
            <div className="flex items-center gap-1 text-xs text-muted-foreground" aria-label={`${ws.observerCount} observer${ws.observerCount !== 1 ? 's' : ''}`}>
              <Users className="h-3.5 w-3.5" aria-hidden="true" />
              <span>{ws.observerCount}</span>
            </div>
          )}

          {/* Focus mode switcher */}
          <FocusModeSwitcher value={focusMode} onChange={setFocusMode} />

          {/* Action buttons */}
          <div className="flex items-center gap-1 ml-2">
            <Button
              variant="outline"
              size="icon"
              onClick={handleFlagInsight}
              disabled={isEnded}
              aria-label="Flag insight (Cmd+I)"
              title="Flag insight (Cmd+I)"
            >
              <Flag className="h-4 w-4" />
            </Button>

            <Button
              variant="outline"
              size="icon"
              onClick={handleTogglePause}
              disabled={isEnded}
              aria-label={isPaused ? 'Resume session (Cmd+P)' : 'Pause session (Cmd+P)'}
              title={isPaused ? 'Resume (Cmd+P)' : 'Pause (Cmd+P)'}
            >
              {isPaused ? <Play className="h-4 w-4" /> : <Pause className="h-4 w-4" />}
            </Button>

            <Button
              variant="destructive"
              size="icon"
              onClick={handleStop}
              disabled={isEnded}
              aria-label="Stop session (Cmd+R)"
              title="Stop session (Cmd+R)"
            >
              <Square className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </header>

      {/* Session ended banner */}
      {isEnded && (
        <div className="bg-muted px-4 py-2 text-center text-sm">
          Session ended.{' '}
          <button
            type="button"
            onClick={() => router.push(`/sessions/${sessionId}`)}
            className="text-primary hover:underline font-medium"
          >
            View review
          </button>
        </div>
      )}

      {/* Error banner */}
      {ws.error && (
        <div className="bg-destructive/10 text-destructive px-4 py-2 text-center text-sm">
          {ws.error}
        </div>
      )}

      {/* Main content area — three-panel layout */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left panel: Topics + Participant info */}
        {focusMode === 'analysis' && (
          <aside className="w-64 border-r flex flex-col overflow-y-auto shrink-0 bg-muted/20">
            {/* Participant info */}
            <div className="p-4 border-b">
              <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2">
                Participant
              </h2>
              <p className="text-sm font-medium">
                {sessionMeta.participantName || 'Unknown'}
              </p>
            </div>

            {/* Topic tracker */}
            <div className="p-4 flex-1">
              <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-3">
                Topics
              </h2>
              <TopicTracker
                topics={ws.topics}
                onTopicUpdate={ws.updateTopic}
                editable={!isEnded}
              />
            </div>

            {/* Talk time (mobile fallback) */}
            <div className="p-4 border-t sm:hidden">
              <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-2">
                Talk Time
              </h2>
              <TalkTimeIndicator ratio={ws.talkTimeRatio} />
            </div>
          </aside>
        )}

        {/* Center panel: Live transcript */}
        <main className="flex-1 flex flex-col overflow-hidden relative">
          <TranscriptPanel
            utterances={ws.utterances}
            isLive={!isEnded}
            piiDetections={ws.piiDetections}
            onFlag={(utteranceId, timestamp) => ws.flagInsight(timestamp)}
            className="flex-1"
          />
        </main>

        {/* Right panel: Coaching prompts + Insights */}
        {(focusMode === 'coached' || focusMode === 'analysis') && (
          <aside className="w-72 border-l flex flex-col overflow-y-auto shrink-0 bg-muted/20">
            {/* Coaching prompts */}
            <div className="p-4">
              <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-3">
                Coaching
              </h2>

              {activePrompts.length === 0 ? (
                <div className="text-center py-6 text-muted-foreground">
                  <MessageSquare className="h-6 w-6 mx-auto mb-2 opacity-40" aria-hidden="true" />
                  <p className="text-xs">No coaching prompts yet</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {activePrompts.map((event) => (
                    <Card
                      key={event.id}
                      className="p-3 bg-[hsl(var(--coaching-background))] border-[hsl(var(--coaching-prompt))]/20 animate-slide-in"
                    >
                      <div className="flex items-start justify-between gap-2 mb-2">
                        <Badge variant="outline" className="text-[10px] capitalize">
                          {event.promptType}
                        </Badge>
                        {event.confidence && (
                          <span className="text-[10px] text-muted-foreground">
                            {Math.round(event.confidence * 100)}%
                          </span>
                        )}
                      </div>
                      <p className="text-sm leading-relaxed">{event.promptText}</p>
                      {event.explanation && (
                        <p className="text-xs text-muted-foreground mt-1">{event.explanation}</p>
                      )}
                      <div className="flex items-center gap-1 mt-2">
                        <button
                          type="button"
                          onClick={() => handleCoachingRespond(event.id, 'accepted')}
                          className="inline-flex items-center gap-1 rounded px-2 py-1 text-xs bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 hover:bg-green-200 dark:hover:bg-green-900/50"
                          aria-label="Accept coaching prompt"
                        >
                          <Check className="h-3 w-3" aria-hidden="true" />
                          Use
                        </button>
                        <button
                          type="button"
                          onClick={() => handleCoachingRespond(event.id, 'dismissed')}
                          className="inline-flex items-center gap-1 rounded px-2 py-1 text-xs bg-muted text-muted-foreground hover:bg-muted/80"
                          aria-label="Dismiss coaching prompt"
                        >
                          <X className="h-3 w-3" aria-hidden="true" />
                          Dismiss
                        </button>
                        <button
                          type="button"
                          onClick={() => handleCoachingRespond(event.id, 'snoozed')}
                          className="inline-flex items-center gap-1 rounded px-2 py-1 text-xs bg-muted text-muted-foreground hover:bg-muted/80"
                          aria-label="Snooze coaching prompt"
                        >
                          <Clock className="h-3 w-3" aria-hidden="true" />
                          Later
                        </button>
                      </div>
                    </Card>
                  ))}
                </div>
              )}
            </div>

            {/* Bias alerts */}
            {ws.biasAlerts.length > 0 && (
              <div className="p-4 border-t">
                <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-3">
                  Bias Alerts
                </h2>
                <div className="space-y-2">
                  {ws.biasAlerts.slice(-3).map((alert) => (
                    <Card
                      key={alert.id}
                      className={`p-3 text-sm ${
                        alert.severity === 'high'
                          ? 'border-red-300 bg-red-50 dark:bg-red-950/20'
                          : alert.severity === 'medium'
                          ? 'border-yellow-300 bg-yellow-50 dark:bg-yellow-950/20'
                          : 'border-border'
                      }`}
                    >
                      <div className="flex items-center gap-1.5 mb-1">
                        <AlertTriangle className="h-3.5 w-3.5 text-yellow-600" aria-hidden="true" />
                        <span className="text-xs font-medium capitalize">{alert.biasType}</span>
                        <Badge
                          variant={
                            alert.severity === 'high'
                              ? 'destructive'
                              : alert.severity === 'medium'
                              ? 'warning'
                              : 'secondary'
                          }
                          className="text-[10px] ml-auto"
                        >
                          {alert.severity}
                        </Badge>
                      </div>
                      <p className="text-xs">{alert.message}</p>
                      <p className="text-xs text-muted-foreground mt-1 italic">{alert.suggestion}</p>
                    </Card>
                  ))}
                </div>
              </div>
            )}

            {/* Observer comments */}
            {ws.comments.length > 0 && (
              <div className="p-4 border-t">
                <h2 className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-3">
                  Observer Notes
                </h2>
                <div className="space-y-2">
                  {ws.comments.slice(-5).map((comment) => (
                    <div key={comment.id} className="text-xs">
                      <span className="font-medium">{comment.authorName}</span>
                      <span className="text-muted-foreground">: {comment.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </aside>
        )}
      </div>
    </div>
  );
}
