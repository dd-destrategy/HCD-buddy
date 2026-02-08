'use client';

import React, { useState, useCallback } from 'react';
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@hcd/ui';
import { Button } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import { cn } from '@hcd/ui';
import {
  RefreshCw,
  Download,
  Pencil,
  Check,
  X,
  Lightbulb,
  AlertTriangle,
  Sparkles,
  HelpCircle,
  Target,
  Clock,
} from 'lucide-react';
import type { SessionSummary, TalkTimeRatio } from '@hcd/ws-protocol';

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

export interface SessionSummaryCardProps {
  summary: SessionSummary | null;
  /** Whether the summary is currently being generated */
  isLoading?: boolean;
  onRegenerate?: () => void;
  onExport?: () => void;
  onSummaryEdit?: (edited: SessionSummary) => void;
  className?: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function TalkTimeStatus({ ratio }: { ratio: TalkTimeRatio }) {
  const interviewerPercent = Math.round(ratio.interviewer * 100);
  const participantPercent = Math.round(ratio.participant * 100);

  return (
    <div className="flex items-center gap-3">
      <div className="flex-1">
        <div className="flex items-center justify-between mb-1">
          <span className="text-xs text-blue-600 font-medium">Interviewer {interviewerPercent}%</span>
          <span className="text-xs text-green-600 font-medium">Participant {participantPercent}%</span>
        </div>
        <div className="h-2 rounded-full bg-muted overflow-hidden flex">
          <div
            className="bg-blue-500 transition-all"
            style={{ width: `${interviewerPercent}%` }}
          />
          <div
            className="bg-green-500 transition-all"
            style={{ width: `${participantPercent}%` }}
          />
        </div>
      </div>
      <Badge
        variant={ratio.status === 'good' ? 'success' : ratio.status === 'warning' ? 'warning' : 'destructive'}
        className="text-xs"
      >
        {ratio.status}
      </Badge>
    </div>
  );
}

function TopicStatusBadge({ status }: { status: 'covered' | 'missed' }) {
  if (status === 'covered') {
    return (
      <Badge variant="success" className="text-xs">
        <Check className="h-3 w-3 mr-0.5" />
        Covered
      </Badge>
    );
  }
  return (
    <Badge variant="warning" className="text-xs">
      <X className="h-3 w-3 mr-0.5" />
      Missed
    </Badge>
  );
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function SessionSummaryCard({
  summary,
  isLoading = false,
  onRegenerate,
  onExport,
  onSummaryEdit,
  className,
}: SessionSummaryCardProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [editedSummary, setEditedSummary] = useState<SessionSummary | null>(null);

  const handleStartEdit = useCallback(() => {
    if (!summary) return;
    setEditedSummary({ ...summary });
    setIsEditing(true);
  }, [summary]);

  const handleSaveEdit = useCallback(() => {
    if (editedSummary && onSummaryEdit) {
      onSummaryEdit(editedSummary);
    }
    setIsEditing(false);
    setEditedSummary(null);
  }, [editedSummary, onSummaryEdit]);

  const handleCancelEdit = useCallback(() => {
    setIsEditing(false);
    setEditedSummary(null);
  }, []);

  const updateEditField = useCallback(
    <K extends keyof SessionSummary>(field: K, value: SessionSummary[K]) => {
      setEditedSummary((prev) => (prev ? { ...prev, [field]: value } : null));
    },
    [],
  );

  const activeSummary = isEditing && editedSummary ? editedSummary : summary;

  // Loading state
  if (isLoading) {
    return (
      <Card className={cn('animate-pulse', className)}>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-purple-500 animate-spin" />
            Generating summary...
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-4 bg-muted rounded w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  // Empty state
  if (!activeSummary) {
    return (
      <Card className={className}>
        <CardContent className="flex flex-col items-center justify-center py-12">
          <Sparkles className="h-8 w-8 text-muted-foreground/40 mb-3" />
          <p className="text-sm text-muted-foreground mb-3">
            Session summary will appear here after the session ends
          </p>
          {onRegenerate && (
            <Button variant="outline" size="sm" onClick={onRegenerate}>
              <RefreshCw className="h-4 w-4 mr-1" />
              Generate Summary
            </Button>
          )}
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={cn('overflow-hidden', className)} role="region" aria-label="Session summary">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-3">
        <CardTitle className="text-lg font-semibold flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-purple-500" />
          Session Summary
        </CardTitle>
        <div className="flex items-center gap-1">
          {isEditing ? (
            <>
              <Button
                size="sm"
                variant="ghost"
                onClick={handleCancelEdit}
                aria-label="Cancel editing"
              >
                <X className="h-4 w-4" />
              </Button>
              <Button
                size="sm"
                onClick={handleSaveEdit}
                aria-label="Save edits"
              >
                <Check className="h-4 w-4 mr-1" />
                Save
              </Button>
            </>
          ) : (
            <>
              {onSummaryEdit && (
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={handleStartEdit}
                  aria-label="Edit summary"
                >
                  <Pencil className="h-4 w-4" />
                </Button>
              )}
              {onRegenerate && (
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={onRegenerate}
                  aria-label="Regenerate summary"
                >
                  <RefreshCw className="h-4 w-4" />
                </Button>
              )}
              {onExport && (
                <Button
                  size="icon"
                  variant="ghost"
                  onClick={onExport}
                  aria-label="Export summary"
                >
                  <Download className="h-4 w-4" />
                </Button>
              )}
            </>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-5">
        {/* Key Themes */}
        <section aria-label="Key themes">
          <h4 className="text-sm font-semibold flex items-center gap-1.5 mb-2">
            <Lightbulb className="h-4 w-4 text-amber-500" />
            Key Themes
          </h4>
          {isEditing ? (
            <textarea
              value={editedSummary?.themes.join('\n') ?? ''}
              onChange={(e) => updateEditField('themes', e.target.value.split('\n').filter(Boolean))}
              className="w-full min-h-[80px] rounded-lg border border-input bg-background px-3 py-2 text-sm"
              aria-label="Edit key themes, one per line"
            />
          ) : (
            <ul className="space-y-1" role="list">
              {activeSummary.themes.map((theme, i) => (
                <li key={i} className="text-sm text-foreground flex items-start gap-2">
                  <span className="text-muted-foreground mt-0.5">-</span>
                  {theme}
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Pain Points */}
        <section aria-label="Pain points">
          <h4 className="text-sm font-semibold flex items-center gap-1.5 mb-2">
            <AlertTriangle className="h-4 w-4 text-red-500" />
            Pain Points
          </h4>
          {isEditing ? (
            <textarea
              value={editedSummary?.painPoints.join('\n') ?? ''}
              onChange={(e) =>
                updateEditField('painPoints', e.target.value.split('\n').filter(Boolean))
              }
              className="w-full min-h-[80px] rounded-lg border border-input bg-background px-3 py-2 text-sm"
              aria-label="Edit pain points, one per line"
            />
          ) : (
            <ul className="space-y-1" role="list">
              {activeSummary.painPoints.map((point, i) => (
                <li key={i} className="text-sm text-foreground flex items-start gap-2">
                  <span className="text-red-400 mt-0.5">-</span>
                  {point}
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Follow-up Questions */}
        <section aria-label="Follow-up questions">
          <h4 className="text-sm font-semibold flex items-center gap-1.5 mb-2">
            <HelpCircle className="h-4 w-4 text-blue-500" />
            Follow-up Questions
          </h4>
          {isEditing ? (
            <textarea
              value={editedSummary?.followUpQuestions.join('\n') ?? ''}
              onChange={(e) =>
                updateEditField('followUpQuestions', e.target.value.split('\n').filter(Boolean))
              }
              className="w-full min-h-[80px] rounded-lg border border-input bg-background px-3 py-2 text-sm"
              aria-label="Edit follow-up questions, one per line"
            />
          ) : (
            <ol className="space-y-1 list-decimal list-inside" role="list">
              {activeSummary.followUpQuestions.map((q, i) => (
                <li key={i} className="text-sm text-foreground">
                  {q}
                </li>
              ))}
            </ol>
          )}
        </section>

        {/* Topic Coverage */}
        <section aria-label="Topic coverage">
          <h4 className="text-sm font-semibold flex items-center gap-1.5 mb-2">
            <Target className="h-4 w-4 text-green-500" />
            Topic Coverage
          </h4>
          <div className="flex flex-wrap gap-2">
            {activeSummary.topicsCovered.map((topic, i) => (
              <div key={`covered-${i}`} className="flex items-center gap-1">
                <TopicStatusBadge status="covered" />
                <span className="text-xs">{topic}</span>
              </div>
            ))}
            {activeSummary.topicsMissed.map((topic, i) => (
              <div key={`missed-${i}`} className="flex items-center gap-1">
                <TopicStatusBadge status="missed" />
                <span className="text-xs">{topic}</span>
              </div>
            ))}
          </div>
        </section>

        {/* Talk Time */}
        <section aria-label="Talk time ratio">
          <h4 className="text-sm font-semibold flex items-center gap-1.5 mb-2">
            <Clock className="h-4 w-4 text-purple-500" />
            Talk Time
          </h4>
          <TalkTimeStatus ratio={activeSummary.talkTimeRatio} />
        </section>

        {/* Emotional Arc */}
        {activeSummary.emotionalArc && (
          <section aria-label="Emotional arc">
            <h4 className="text-sm font-semibold flex items-center gap-1.5 mb-2">
              <Sparkles className="h-4 w-4 text-purple-500" />
              Emotional Arc
            </h4>
            {isEditing ? (
              <textarea
                value={editedSummary?.emotionalArc ?? ''}
                onChange={(e) => updateEditField('emotionalArc', e.target.value)}
                className="w-full min-h-[60px] rounded-lg border border-input bg-background px-3 py-2 text-sm"
                aria-label="Edit emotional arc summary"
              />
            ) : (
              <p className="text-sm text-muted-foreground">{activeSummary.emotionalArc}</p>
            )}
          </section>
        )}
      </CardContent>

      <CardFooter className="border-t pt-4">
        <p className="text-xs text-muted-foreground">
          AI-generated summary. Review for accuracy before sharing.
        </p>
      </CardFooter>
    </Card>
  );
}
