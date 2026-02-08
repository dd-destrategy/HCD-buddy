'use client';

import { useCallback, useState, useRef } from 'react';
import {
  Flag,
  Highlighter,
  Tag,
  Copy,
  Check,
} from 'lucide-react';
import { Badge } from '@hcd/ui';
import type { Utterance, PIIDetection } from '@hcd/ws-protocol';

// =============================================================================
// UtteranceRow — Single utterance in the transcript
// =============================================================================

interface UtteranceRowProps {
  /** Utterance data */
  utterance: Utterance;
  /** Whether this utterance is currently selected */
  isSelected?: boolean;
  /** Called when user clicks the utterance to select it */
  onSelect?: (utteranceId: string) => void;
  /** Called when user wants to flag an insight */
  onFlag?: (utteranceId: string, timestamp: number) => void;
  /** Called when user wants to highlight text */
  onHighlight?: (utteranceId: string, text: string) => void;
  /** Called when user wants to tag the utterance */
  onTag?: (utteranceId: string) => void;
  /** PII detections for this utterance */
  piiDetections?: PIIDetection[];
  /** Tags applied to this utterance */
  tags?: Array<{ id: string; name: string; color?: string }>;
  /** Search term to highlight in text */
  searchHighlight?: string;
  /** Whether this is the current search match */
  isCurrentMatch?: boolean;
  /** Additional CSS classes */
  className?: string;
}

export function UtteranceRow({
  utterance,
  isSelected = false,
  onSelect,
  onFlag,
  onHighlight,
  onTag,
  piiDetections = [],
  tags = [],
  searchHighlight,
  isCurrentMatch = false,
  className = '',
}: UtteranceRowProps) {
  const [copied, setCopied] = useState(false);
  const [showActions, setShowActions] = useState(false);
  const rowRef = useRef<HTMLDivElement>(null);

  const formatTime = useCallback((seconds: number): string => {
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }, []);

  const handleCopy = useCallback(async () => {
    await navigator.clipboard.writeText(utterance.text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }, [utterance.text]);

  const handleContextMenu = useCallback(
    (e: React.MouseEvent) => {
      e.preventDefault();
      // In a real app this would show a custom context menu
      // For now, toggle the action buttons visibility
      setShowActions((prev) => !prev);
    },
    []
  );

  // Render text with PII highlights and search highlights
  const renderText = useCallback(() => {
    let text = utterance.text;

    // If there are PII detections, highlight them
    if (piiDetections.length > 0) {
      // Sort by start index descending so we can replace from the end
      const sorted = [...piiDetections].sort((a, b) => b.startIndex - a.startIndex);
      const chars = text.split('');

      // Build segments
      const segments: Array<{ text: string; isPII: boolean; piiType?: string }> = [];
      let lastEnd = text.length;

      for (const det of sorted) {
        if (det.endIndex < lastEnd) {
          segments.unshift({ text: text.slice(det.endIndex, lastEnd), isPII: false });
        }
        segments.unshift({
          text: text.slice(det.startIndex, det.endIndex),
          isPII: true,
          piiType: det.piiType,
        });
        lastEnd = det.startIndex;
      }
      if (lastEnd > 0) {
        segments.unshift({ text: text.slice(0, lastEnd), isPII: false });
      }

      return (
        <span>
          {segments.map((seg, i) =>
            seg.isPII ? (
              <span
                key={i}
                className="bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300 rounded px-0.5"
                title={`PII detected: ${seg.piiType}`}
              >
                {highlightSearchInText(seg.text, searchHighlight, isCurrentMatch)}
              </span>
            ) : (
              <span key={i}>{highlightSearchInText(seg.text, searchHighlight, isCurrentMatch)}</span>
            )
          )}
        </span>
      );
    }

    return highlightSearchInText(text, searchHighlight, isCurrentMatch);
  }, [utterance.text, piiDetections, searchHighlight, isCurrentMatch]);

  // Sentiment indicator
  const sentimentDot = (() => {
    if (!utterance.sentimentPolarity) return null;
    const colors: Record<string, string> = {
      positive: 'bg-green-500',
      negative: 'bg-red-500',
      neutral: 'bg-gray-400',
      mixed: 'bg-yellow-500',
    };
    return (
      <span
        className={`inline-block h-2 w-2 rounded-full ${colors[utterance.sentimentPolarity] || 'bg-gray-400'}`}
        title={`Sentiment: ${utterance.sentimentPolarity}`}
        aria-label={`Sentiment: ${utterance.sentimentPolarity}`}
      />
    );
  })();

  return (
    <div
      ref={rowRef}
      data-utterance-id={utterance.id}
      role="listitem"
      onClick={() => onSelect?.(utterance.id)}
      onContextMenu={handleContextMenu}
      className={`
        group flex gap-3 px-3 py-2 rounded-lg transition-colors cursor-pointer
        ${isSelected ? 'bg-primary/5 ring-1 ring-primary/20' : 'hover:bg-muted/50'}
        ${isCurrentMatch ? 'ring-2 ring-yellow-400' : ''}
        ${className}
      `}
      aria-selected={isSelected}
      aria-label={`${utterance.speaker} at ${formatTime(utterance.startTime)}: ${utterance.text}`}
    >
      {/* Timestamp */}
      <span className="text-xs text-muted-foreground font-mono tabular-nums shrink-0 mt-0.5 w-12">
        {formatTime(utterance.startTime)}
      </span>

      {/* Speaker badge */}
      <Badge
        variant={utterance.speaker === 'interviewer' ? 'interviewer' : 'participant'}
        className="shrink-0 mt-0.5 h-5"
      >
        {utterance.speaker === 'interviewer' ? 'You' : 'P'}
      </Badge>

      {/* Content column */}
      <div className="flex-1 min-w-0">
        {/* Text */}
        <p className="text-sm leading-relaxed break-words">
          {renderText()}
        </p>

        {/* Metadata row */}
        <div className="flex items-center gap-2 mt-1 flex-wrap">
          {sentimentDot}

          {utterance.questionType && utterance.questionType !== 'none' && (
            <Badge variant="outline" className="text-[10px] px-1.5 py-0 h-4">
              {utterance.questionType.replace('_', ' ')}
            </Badge>
          )}

          {tags.map((tag) => (
            <Badge
              key={tag.id}
              variant="secondary"
              className="text-[10px] px-1.5 py-0 h-4"
              style={tag.color ? { backgroundColor: tag.color + '20', color: tag.color } : undefined}
            >
              {tag.name}
            </Badge>
          ))}
        </div>
      </div>

      {/* Hover actions */}
      <div
        className={`
          flex items-start gap-1 shrink-0
          ${showActions ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}
          transition-opacity
        `}
      >
        {onFlag && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onFlag(utterance.id, utterance.startTime);
            }}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground"
            aria-label="Flag as insight"
            title="Flag as insight"
          >
            <Flag className="h-3.5 w-3.5" />
          </button>
        )}
        {onHighlight && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onHighlight(utterance.id, utterance.text);
            }}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground"
            aria-label="Highlight"
            title="Highlight"
          >
            <Highlighter className="h-3.5 w-3.5" />
          </button>
        )}
        {onTag && (
          <button
            type="button"
            onClick={(e) => {
              e.stopPropagation();
              onTag(utterance.id);
            }}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground"
            aria-label="Add tag"
            title="Add tag"
          >
            <Tag className="h-3.5 w-3.5" />
          </button>
        )}
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            handleCopy();
          }}
          className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground"
          aria-label="Copy text"
          title="Copy text"
        >
          {copied ? (
            <Check className="h-3.5 w-3.5 text-green-500" />
          ) : (
            <Copy className="h-3.5 w-3.5" />
          )}
        </button>
      </div>
    </div>
  );
}

// =============================================================================
// Helper: Highlight search term in text
// =============================================================================

function highlightSearchInText(
  text: string,
  searchTerm: string | undefined,
  isCurrentMatch: boolean
): React.ReactNode {
  if (!searchTerm || searchTerm.length === 0) return text;

  const regex = new RegExp(`(${escapeRegex(searchTerm)})`, 'gi');
  const parts = text.split(regex);

  if (parts.length <= 1) return text;

  return (
    <>
      {parts.map((part, i) =>
        regex.test(part) ? (
          <mark
            key={i}
            className={`rounded px-0.5 ${
              isCurrentMatch
                ? 'bg-yellow-300 dark:bg-yellow-600'
                : 'bg-yellow-200/60 dark:bg-yellow-700/40'
            }`}
          >
            {part}
          </mark>
        ) : (
          <span key={i}>{part}</span>
        )
      )}
    </>
  );
}

function escapeRegex(str: string): string {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
