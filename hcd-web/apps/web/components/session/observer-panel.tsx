'use client';

import React, { useState, useCallback, useRef, useEffect, useMemo } from 'react';
import { Card, CardHeader, CardTitle, CardContent } from '@hcd/ui';
import { Button } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import { Input, Textarea } from '@hcd/ui';
import { cn } from '@hcd/ui';
import {
  Eye,
  MessageSquare,
  Send,
  Lightbulb,
  Users,
  Clock,
} from 'lucide-react';
import type { Comment, Utterance } from '@hcd/ws-protocol';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ObserverPanelProps {
  /** Number of observers currently watching */
  observerCount: number;
  /** Live comments from all observers */
  comments: Comment[];
  /** Read-only transcript utterances */
  utterances: Utterance[];
  /** Current session elapsed time in seconds */
  sessionTime: number;
  /** Called when observer submits a comment */
  onSubmitComment?: (text: string, timestamp: number) => void;
  /** Called when observer suggests a follow-up question */
  onSuggestQuestion?: (text: string) => void;
  className?: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
}

function formatTimestamp(isoString: string): string {
  const date = new Date(isoString);
  return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}

// ---------------------------------------------------------------------------
// Comment item
// ---------------------------------------------------------------------------

function CommentItem({ comment }: { comment: Comment }) {
  return (
    <div className="flex gap-2 py-2 px-1 animate-fade-in">
      <div className="flex-shrink-0 h-6 w-6 rounded-full bg-muted flex items-center justify-center">
        <span className="text-xs font-medium text-muted-foreground">
          {comment.authorName.charAt(0).toUpperCase()}
        </span>
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className="text-xs font-medium text-foreground truncate">
            {comment.authorName}
          </span>
          <span className="text-xs text-muted-foreground tabular-nums font-mono">
            {formatTimestamp(comment.createdAt)}
          </span>
        </div>
        <p className="text-sm text-foreground mt-0.5">{comment.text}</p>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function ObserverPanel({
  observerCount,
  comments,
  utterances,
  sessionTime,
  onSubmitComment,
  onSuggestQuestion,
  className,
}: ObserverPanelProps) {
  const [activeTab, setActiveTab] = useState<'comments' | 'transcript'>('comments');
  const [commentText, setCommentText] = useState('');
  const [questionText, setQuestionText] = useState('');

  const commentsEndRef = useRef<HTMLDivElement>(null);
  const transcriptEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll comments to bottom
  useEffect(() => {
    commentsEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [comments.length]);

  // Auto-scroll transcript to bottom
  useEffect(() => {
    transcriptEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [utterances.length]);

  const handleSubmitComment = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const trimmed = commentText.trim();
      if (!trimmed || !onSubmitComment) return;
      onSubmitComment(trimmed, sessionTime);
      setCommentText('');
    },
    [commentText, sessionTime, onSubmitComment],
  );

  const handleSuggestQuestion = useCallback(
    (e: React.FormEvent) => {
      e.preventDefault();
      const trimmed = questionText.trim();
      if (!trimmed || !onSuggestQuestion) return;
      onSuggestQuestion(trimmed);
      setQuestionText('');
    },
    [questionText, onSuggestQuestion],
  );

  // Recent utterances (last 50 for performance)
  const recentUtterances = useMemo(
    () => utterances.slice(-50),
    [utterances],
  );

  return (
    <Card
      className={cn('flex flex-col h-full overflow-hidden', className)}
      role="region"
      aria-label="Observer panel"
    >
      {/* Header */}
      <CardHeader className="flex-shrink-0 pb-3 border-b">
        <div className="flex items-center justify-between">
          <CardTitle className="text-base flex items-center gap-2">
            <Eye className="h-4 w-4 text-muted-foreground" />
            Observer View
          </CardTitle>
          <Badge variant="secondary" className="text-xs" aria-label={`${observerCount} observers`}>
            <Users className="h-3 w-3 mr-1" />
            {observerCount}
          </Badge>
        </div>

        {/* Session time */}
        <div className="flex items-center gap-1.5 mt-2 text-xs text-muted-foreground">
          <Clock className="h-3 w-3" />
          <span className="tabular-nums font-mono">{formatTime(sessionTime)}</span>
        </div>

        {/* Tab switcher */}
        <div className="flex mt-3 border rounded-lg overflow-hidden" role="tablist">
          <button
            role="tab"
            aria-selected={activeTab === 'comments'}
            aria-controls="tab-comments"
            onClick={() => setActiveTab('comments')}
            className={cn(
              'flex-1 px-3 py-1.5 text-xs font-medium transition-colors',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring',
              activeTab === 'comments'
                ? 'bg-primary text-primary-foreground'
                : 'bg-background text-muted-foreground hover:bg-muted',
            )}
          >
            <MessageSquare className="h-3 w-3 inline mr-1" />
            Comments ({comments.length})
          </button>
          <button
            role="tab"
            aria-selected={activeTab === 'transcript'}
            aria-controls="tab-transcript"
            onClick={() => setActiveTab('transcript')}
            className={cn(
              'flex-1 px-3 py-1.5 text-xs font-medium transition-colors',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring',
              activeTab === 'transcript'
                ? 'bg-primary text-primary-foreground'
                : 'bg-background text-muted-foreground hover:bg-muted',
            )}
          >
            Transcript
          </button>
        </div>
      </CardHeader>

      {/* Content */}
      <CardContent className="flex-1 overflow-hidden p-0 flex flex-col">
        {/* Comments tab */}
        {activeTab === 'comments' && (
          <div
            id="tab-comments"
            role="tabpanel"
            className="flex-1 flex flex-col overflow-hidden"
          >
            {/* Comments feed */}
            <div className="flex-1 overflow-y-auto px-4 py-2" aria-label="Comments feed" role="log">
              {comments.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-center">
                  <MessageSquare className="h-6 w-6 text-muted-foreground/40 mb-2" />
                  <p className="text-xs text-muted-foreground">
                    No comments yet. Add timestamped notes below.
                  </p>
                </div>
              ) : (
                <>
                  {comments.map((comment) => (
                    <CommentItem key={comment.id} comment={comment} />
                  ))}
                  <div ref={commentsEndRef} />
                </>
              )}
            </div>

            {/* Comment input */}
            <form
              onSubmit={handleSubmitComment}
              className="flex-shrink-0 border-t p-3 flex gap-2"
            >
              <Input
                value={commentText}
                onChange={(e) => setCommentText(e.target.value)}
                placeholder="Add a comment..."
                className="flex-1 h-9 text-sm"
                aria-label="Comment input"
              />
              <Button
                type="submit"
                size="icon"
                disabled={!commentText.trim()}
                aria-label="Send comment"
                className="h-9 w-9"
              >
                <Send className="h-4 w-4" />
              </Button>
            </form>

            {/* Suggest follow-up */}
            <form
              onSubmit={handleSuggestQuestion}
              className="flex-shrink-0 border-t p-3 space-y-2"
            >
              <label className="text-xs font-medium text-muted-foreground flex items-center gap-1">
                <Lightbulb className="h-3 w-3 text-amber-500" />
                Suggest a follow-up question
              </label>
              <div className="flex gap-2">
                <Textarea
                  value={questionText}
                  onChange={(e) => setQuestionText(e.target.value)}
                  placeholder="What question should the interviewer ask?"
                  className="flex-1 min-h-[60px] text-sm resize-none"
                  aria-label="Suggest follow-up question"
                  rows={2}
                />
              </div>
              <Button
                type="submit"
                size="sm"
                variant="outline"
                disabled={!questionText.trim()}
                className="w-full"
              >
                <Lightbulb className="h-4 w-4 mr-1" />
                Suggest Follow-up
              </Button>
            </form>
          </div>
        )}

        {/* Transcript tab (read-only) */}
        {activeTab === 'transcript' && (
          <div
            id="tab-transcript"
            role="tabpanel"
            className="flex-1 overflow-y-auto px-4 py-2"
            aria-label="Live transcript (read-only)"
          >
            {recentUtterances.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-8 text-center">
                <MessageSquare className="h-6 w-6 text-muted-foreground/40 mb-2" />
                <p className="text-xs text-muted-foreground">
                  Transcript will appear here as the interview proceeds
                </p>
              </div>
            ) : (
              <>
                {recentUtterances.map((utterance) => (
                  <div
                    key={utterance.id}
                    className="py-2 border-b last:border-b-0"
                    role="listitem"
                  >
                    <div className="flex items-center gap-2 mb-0.5">
                      <Badge
                        variant={utterance.speaker === 'interviewer' ? 'interviewer' : 'participant'}
                        className="text-xs"
                      >
                        {utterance.speaker === 'interviewer' ? 'Interviewer' : 'Participant'}
                      </Badge>
                      <span className="text-xs text-muted-foreground tabular-nums font-mono">
                        {formatTime(utterance.startTime)}
                      </span>
                    </div>
                    <p className="text-sm text-foreground">{utterance.text}</p>
                  </div>
                ))}
                <div ref={transcriptEndRef} />
              </>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}
