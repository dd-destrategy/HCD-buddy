'use client';

import { useState, useCallback } from 'react';
import {
  MessageSquare,
  BarChart3,
  Flag,
  Highlighter,
  Download,
  Star,
} from 'lucide-react';
import { Card, Badge, Button } from '@hcd/ui';
import { TranscriptPanel } from '@/components/transcript/transcript-panel';
import { TopicTracker } from '@/components/session/topic-tracker';
import { ExportDialog } from '@/components/export/export-dialog';
import type { Utterance, TopicUpdate } from '@hcd/ws-protocol';

// =============================================================================
// SessionDetailClient — Tabbed content for session review
// =============================================================================

type Tab = 'transcript' | 'analysis' | 'insights' | 'highlights' | 'export';

interface SessionDetailClientProps {
  session: {
    id: string;
    title: string;
    utterances: Array<{
      id: string;
      speaker: string;
      text: string;
      startTime: number;
      endTime: number | null;
      sentimentScore: number | null;
      sentimentPolarity: string | null;
      questionType: string | null;
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
    summary: Record<string, unknown> | null;
  };
}

const TABS: Array<{ id: Tab; label: string; icon: typeof MessageSquare }> = [
  { id: 'transcript', label: 'Transcript', icon: MessageSquare },
  { id: 'analysis', label: 'Analysis', icon: BarChart3 },
  { id: 'insights', label: 'Insights', icon: Flag },
  { id: 'highlights', label: 'Highlights', icon: Highlighter },
  { id: 'export', label: 'Export', icon: Download },
];

export function SessionDetailClient({ session }: SessionDetailClientProps) {
  const [activeTab, setActiveTab] = useState<Tab>('transcript');
  const [exportDialogOpen, setExportDialogOpen] = useState(false);

  // Map utterances to the shape expected by TranscriptPanel
  const utterancesForPanel: Utterance[] = session.utterances.map((u) => ({
    id: u.id,
    sessionId: session.id,
    speaker: u.speaker as 'interviewer' | 'participant',
    text: u.text,
    startTime: u.startTime,
    endTime: u.endTime ?? undefined,
    sentimentScore: u.sentimentScore ?? undefined,
    sentimentPolarity: (u.sentimentPolarity as Utterance['sentimentPolarity']) ?? undefined,
    questionType: (u.questionType as Utterance['questionType']) ?? undefined,
  }));

  // Map topics
  const topicsForTracker: TopicUpdate[] = session.topics.map((t) => ({
    topicName: t.topicName,
    status: t.status as TopicUpdate['status'],
  }));

  const formatTime = useCallback((seconds: number): string => {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }, []);

  // Compute analysis data
  const questionDistribution = session.utterances.reduce<Record<string, number>>((acc, u) => {
    if (u.questionType && u.questionType !== 'none') {
      acc[u.questionType] = (acc[u.questionType] || 0) + 1;
    }
    return acc;
  }, {});

  const sentimentCounts = session.utterances.reduce<Record<string, number>>((acc, u) => {
    if (u.sentimentPolarity) {
      acc[u.sentimentPolarity] = (acc[u.sentimentPolarity] || 0) + 1;
    }
    return acc;
  }, {});

  const interviewerUtterances = session.utterances.filter((u) => u.speaker === 'interviewer');
  const participantUtterances = session.utterances.filter((u) => u.speaker === 'participant');
  const talkRatioPct = session.utterances.length > 0
    ? Math.round((interviewerUtterances.length / session.utterances.length) * 100)
    : 50;

  return (
    <>
      {/* Tabs */}
      <div
        className="flex items-center gap-1 border-b"
        role="tablist"
        aria-label="Session detail tabs"
      >
        {TABS.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;

          return (
            <button
              key={tab.id}
              type="button"
              role="tab"
              aria-selected={isActive}
              aria-controls={`panel-${tab.id}`}
              id={`tab-${tab.id}`}
              onClick={() => {
                if (tab.id === 'export') {
                  setExportDialogOpen(true);
                } else {
                  setActiveTab(tab.id);
                }
              }}
              className={`
                flex items-center gap-1.5 px-4 py-2.5 text-sm font-medium transition-colors border-b-2 -mb-px
                ${isActive
                  ? 'border-primary text-primary'
                  : 'border-transparent text-muted-foreground hover:text-foreground hover:border-border'
                }
              `}
            >
              <Icon className="h-4 w-4" aria-hidden="true" />
              {tab.label}
              {tab.id === 'insights' && session.insights.length > 0 && (
                <Badge variant="secondary" className="text-[10px] px-1.5 h-4 ml-1">
                  {session.insights.length}
                </Badge>
              )}
              {tab.id === 'highlights' && session.highlights.length > 0 && (
                <Badge variant="secondary" className="text-[10px] px-1.5 h-4 ml-1">
                  {session.highlights.length}
                </Badge>
              )}
            </button>
          );
        })}
      </div>

      {/* Tab panels */}
      <div className="min-h-[400px]">
        {/* Transcript panel */}
        {activeTab === 'transcript' && (
          <div
            id="panel-transcript"
            role="tabpanel"
            aria-labelledby="tab-transcript"
            className="h-[600px]"
          >
            <TranscriptPanel
              utterances={utterancesForPanel}
              isLive={false}
              className="h-full rounded-lg border"
            />
          </div>
        )}

        {/* Analysis panel */}
        {activeTab === 'analysis' && (
          <div
            id="panel-analysis"
            role="tabpanel"
            aria-labelledby="tab-analysis"
            className="space-y-6"
          >
            {/* Talk time ratio */}
            <Card className="p-6">
              <h3 className="text-sm font-semibold mb-3">Talk Time Ratio</h3>
              <div className="flex items-center gap-4">
                <div className="flex-1">
                  <div className="flex items-center justify-between text-xs mb-1">
                    <span className="text-blue-600">Interviewer: {talkRatioPct}%</span>
                    <span className="text-emerald-600">Participant: {100 - talkRatioPct}%</span>
                  </div>
                  <div className="h-4 w-full rounded-full bg-emerald-200 dark:bg-emerald-900 overflow-hidden flex">
                    <div
                      className={`h-full transition-all ${
                        talkRatioPct > 40 ? 'bg-red-500' : talkRatioPct >= 30 ? 'bg-yellow-500' : 'bg-blue-500'
                      }`}
                      style={{ width: `${talkRatioPct}%` }}
                    />
                  </div>
                </div>
              </div>
            </Card>

            {/* Question types */}
            <Card className="p-6">
              <h3 className="text-sm font-semibold mb-3">Question Types</h3>
              {Object.keys(questionDistribution).length > 0 ? (
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                  {Object.entries(questionDistribution).map(([type, count]) => (
                    <div key={type} className="flex items-center justify-between rounded-lg border p-3">
                      <span className="text-sm capitalize">{type.replace('_', ' ')}</span>
                      <Badge variant="secondary">{count}</Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">No question types detected.</p>
              )}
            </Card>

            {/* Sentiment overview */}
            <Card className="p-6">
              <h3 className="text-sm font-semibold mb-3">Sentiment Distribution</h3>
              {Object.keys(sentimentCounts).length > 0 ? (
                <div className="flex items-center gap-3 flex-wrap">
                  {Object.entries(sentimentCounts).map(([polarity, count]) => {
                    const variant = polarity as 'positive' | 'negative' | 'neutral' | 'mixed';
                    return (
                      <Badge key={polarity} variant={variant} className="text-sm px-3 py-1">
                        {polarity}: {count}
                      </Badge>
                    );
                  })}
                </div>
              ) : (
                <p className="text-sm text-muted-foreground">No sentiment data available.</p>
              )}
            </Card>

            {/* Topics */}
            <Card className="p-6">
              <h3 className="text-sm font-semibold mb-3">Topic Coverage</h3>
              <TopicTracker topics={topicsForTracker} editable={false} />
            </Card>

            {/* Summary */}
            {session.summary && (
              <Card className="p-6">
                <h3 className="text-sm font-semibold mb-3">AI Summary</h3>
                <div className="space-y-3 text-sm">
                  {(session.summary as any).themes && (
                    <div>
                      <p className="font-medium text-xs text-muted-foreground uppercase tracking-wide mb-1">Themes</p>
                      <div className="flex flex-wrap gap-1.5">
                        {((session.summary as any).themes as string[]).map((theme) => (
                          <Badge key={theme} variant="outline">{theme}</Badge>
                        ))}
                      </div>
                    </div>
                  )}
                  {(session.summary as any).painPoints && (
                    <div>
                      <p className="font-medium text-xs text-muted-foreground uppercase tracking-wide mb-1">Pain Points</p>
                      <ul className="list-disc list-inside text-muted-foreground">
                        {((session.summary as any).painPoints as string[]).map((point, i) => (
                          <li key={i}>{point}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                  {(session.summary as any).followUpQuestions && (
                    <div>
                      <p className="font-medium text-xs text-muted-foreground uppercase tracking-wide mb-1">Follow-Up Questions</p>
                      <ul className="list-disc list-inside text-muted-foreground">
                        {((session.summary as any).followUpQuestions as string[]).map((q, i) => (
                          <li key={i}>{q}</li>
                        ))}
                      </ul>
                    </div>
                  )}
                </div>
              </Card>
            )}
          </div>
        )}

        {/* Insights panel */}
        {activeTab === 'insights' && (
          <div
            id="panel-insights"
            role="tabpanel"
            aria-labelledby="tab-insights"
          >
            {session.insights.length === 0 ? (
              <Card className="flex flex-col items-center justify-center py-16">
                <Flag className="h-10 w-10 text-muted-foreground/40 mb-3" aria-hidden="true" />
                <p className="text-sm font-medium">No insights flagged</p>
                <p className="text-xs text-muted-foreground mt-1">
                  Insights are created during live sessions with Cmd+I
                </p>
              </Card>
            ) : (
              <div className="space-y-2">
                {session.insights.map((insight) => (
                  <Card key={insight.id} className="flex items-start gap-3 p-4">
                    <Flag className="h-4 w-4 text-primary shrink-0 mt-0.5" aria-hidden="true" />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-mono text-muted-foreground">
                          {formatTime(insight.timestamp)}
                        </span>
                        <Badge variant="outline" className="text-[10px]">
                          {insight.source}
                        </Badge>
                      </div>
                      {insight.note && (
                        <p className="text-sm mt-1">{insight.note}</p>
                      )}
                    </div>
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}

        {/* Highlights panel */}
        {activeTab === 'highlights' && (
          <div
            id="panel-highlights"
            role="tabpanel"
            aria-labelledby="tab-highlights"
          >
            {session.highlights.length === 0 ? (
              <Card className="flex flex-col items-center justify-center py-16">
                <Highlighter className="h-10 w-10 text-muted-foreground/40 mb-3" aria-hidden="true" />
                <p className="text-sm font-medium">No highlights yet</p>
                <p className="text-xs text-muted-foreground mt-1">
                  Highlights can be created from the transcript view
                </p>
              </Card>
            ) : (
              <div className="space-y-2">
                {session.highlights.map((highlight) => (
                  <Card key={highlight.id} className="p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <h4 className="text-sm font-medium">{highlight.title}</h4>
                      <Badge variant="outline" className="text-[10px]">
                        {highlight.category}
                      </Badge>
                      {highlight.isStarred && (
                        <Star className="h-3.5 w-3.5 text-yellow-500 fill-yellow-500" aria-label="Starred" />
                      )}
                    </div>
                    <blockquote className="text-sm text-muted-foreground border-l-2 border-primary/30 pl-3 italic">
                      {highlight.textSelection}
                    </blockquote>
                    {highlight.notes && (
                      <p className="text-xs text-muted-foreground mt-2">{highlight.notes}</p>
                    )}
                  </Card>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Export dialog */}
      <ExportDialog
        sessionId={session.id}
        sessionTitle={session.title}
        isOpen={exportDialogOpen}
        onClose={() => setExportDialogOpen(false)}
      />
    </>
  );
}
