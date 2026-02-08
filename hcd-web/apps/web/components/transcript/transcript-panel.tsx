'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { ArrowDown, Search as SearchIcon } from 'lucide-react';
import { Button } from '@hcd/ui';
import type { Utterance, PIIDetection } from '@hcd/ws-protocol';
import { UtteranceRow } from './utterance-row';
import { TranscriptSearch } from './transcript-search';

// =============================================================================
// TranscriptPanel — Main transcript viewer with virtualization and search
// =============================================================================

interface TranscriptPanelProps {
  /** Full list of utterances */
  utterances: Utterance[];
  /** Whether this is a live session (enables auto-scroll) */
  isLive?: boolean;
  /** PII detection data keyed by utterance ID */
  piiDetections?: Map<string, PIIDetection[]>;
  /** Called when user flags an insight */
  onFlag?: (utteranceId: string, timestamp: number) => void;
  /** Called when user highlights text */
  onHighlight?: (utteranceId: string, text: string) => void;
  /** Called when user wants to tag an utterance */
  onTag?: (utteranceId: string) => void;
  /** Additional CSS classes */
  className?: string;
}

const ITEM_HEIGHT = 72; // Approximate height of each utterance row
const OVERSCAN = 5; // Extra items rendered above/below viewport

export function TranscriptPanel({
  utterances,
  isLive = false,
  piiDetections = new Map(),
  onFlag,
  onHighlight,
  onTag,
  className = '',
}: TranscriptPanelProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [autoScroll, setAutoScroll] = useState(isLive);
  const [isUserScrolling, setIsUserScrolling] = useState(false);

  // Search state
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentMatchIdx, setCurrentMatchIdx] = useState(0);

  // Virtualization state
  const [scrollTop, setScrollTop] = useState(0);
  const [containerHeight, setContainerHeight] = useState(0);

  // --- Search matching ---
  const matchingIndices = useMemo(() => {
    if (!searchTerm || searchTerm.length === 0) return [];
    const term = searchTerm.toLowerCase();
    return utterances.reduce<number[]>((acc, u, i) => {
      if (u.text.toLowerCase().includes(term)) {
        acc.push(i);
      }
      return acc;
    }, []);
  }, [utterances, searchTerm]);

  const matchingUtteranceIds = useMemo(() => {
    return new Set(matchingIndices.map((i) => utterances[i]?.id));
  }, [matchingIndices, utterances]);

  const currentMatchUtteranceId = matchingIndices.length > 0
    ? utterances[matchingIndices[currentMatchIdx]]?.id
    : null;

  // --- Virtualization ---
  const totalHeight = utterances.length * ITEM_HEIGHT;
  const startIdx = Math.max(0, Math.floor(scrollTop / ITEM_HEIGHT) - OVERSCAN);
  const endIdx = Math.min(
    utterances.length,
    Math.ceil((scrollTop + containerHeight) / ITEM_HEIGHT) + OVERSCAN
  );
  const visibleUtterances = utterances.slice(startIdx, endIdx);

  // Handle scroll
  const handleScroll = useCallback(() => {
    const el = containerRef.current;
    if (!el) return;

    setScrollTop(el.scrollTop);

    // Detect if user is scrolling near the bottom
    const isNearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 100;
    setIsUserScrolling(!isNearBottom);

    if (isNearBottom && isLive) {
      setAutoScroll(true);
    }
  }, [isLive]);

  // Observe container size
  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;

    const observer = new ResizeObserver((entries) => {
      for (const entry of entries) {
        setContainerHeight(entry.contentRect.height);
      }
    });
    observer.observe(el);

    // Initialize
    setContainerHeight(el.clientHeight);

    return () => observer.disconnect();
  }, []);

  // Auto-scroll on new utterances
  useEffect(() => {
    if (autoScroll && isLive && containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
    }
  }, [utterances.length, autoScroll, isLive]);

  // Scroll to match when navigating search results
  useEffect(() => {
    if (currentMatchUtteranceId && containerRef.current) {
      const matchGlobalIdx = matchingIndices[currentMatchIdx];
      if (matchGlobalIdx !== undefined) {
        containerRef.current.scrollTop = matchGlobalIdx * ITEM_HEIGHT - containerHeight / 2;
      }
    }
  }, [currentMatchIdx, currentMatchUtteranceId, matchingIndices, containerHeight]);

  // --- Search handlers ---
  const handleSearch = useCallback((term: string) => {
    setSearchTerm(term);
    setCurrentMatchIdx(0);
  }, []);

  const handleNextMatch = useCallback(() => {
    setCurrentMatchIdx((prev) => (prev + 1) % matchingIndices.length);
  }, [matchingIndices.length]);

  const handlePrevMatch = useCallback(() => {
    setCurrentMatchIdx((prev) =>
      prev === 0 ? matchingIndices.length - 1 : prev - 1
    );
  }, [matchingIndices.length]);

  const handleCloseSearch = useCallback(() => {
    setSearchOpen(false);
    setSearchTerm('');
    setCurrentMatchIdx(0);
  }, []);

  // Manual scroll-to-bottom
  const scrollToBottom = useCallback(() => {
    if (containerRef.current) {
      containerRef.current.scrollTop = containerRef.current.scrollHeight;
      setAutoScroll(true);
    }
  }, []);

  // Empty state
  if (utterances.length === 0) {
    return (
      <div className={`flex flex-col items-center justify-center h-full text-muted-foreground ${className}`}>
        <SearchIcon className="h-12 w-12 opacity-30 mb-3" aria-hidden="true" />
        <p className="text-sm font-medium">No transcript yet</p>
        <p className="text-xs mt-1">
          {isLive ? 'Waiting for speech...' : 'This session has no transcript data.'}
        </p>
      </div>
    );
  }

  return (
    <div className={`flex flex-col h-full ${className}`}>
      {/* Search bar */}
      <TranscriptSearch
        isOpen={searchOpen}
        onOpen={() => setSearchOpen(true)}
        onClose={handleCloseSearch}
        onSearch={handleSearch}
        matchCount={matchingIndices.length}
        currentMatchIndex={currentMatchIdx}
        onNextMatch={handleNextMatch}
        onPrevMatch={handlePrevMatch}
        className="mx-3 mt-2"
      />

      {/* Toolbar */}
      {!searchOpen && (
        <div className="flex items-center justify-between px-3 py-1.5">
          <span className="text-xs text-muted-foreground">
            {utterances.length} utterance{utterances.length !== 1 ? 's' : ''}
          </span>
          <button
            type="button"
            onClick={() => setSearchOpen(true)}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground"
            aria-label="Search transcript (Cmd+F)"
            title="Search (Cmd+F)"
          >
            <SearchIcon className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* Virtualized transcript list */}
      <div
        ref={containerRef}
        onScroll={handleScroll}
        className="flex-1 overflow-y-auto scrollbar-thin relative"
        role="list"
        aria-label="Transcript"
      >
        {/* Spacer for virtualization */}
        <div style={{ height: totalHeight, position: 'relative' }}>
          <div
            style={{
              position: 'absolute',
              top: startIdx * ITEM_HEIGHT,
              left: 0,
              right: 0,
            }}
          >
            {visibleUtterances.map((utterance, localIdx) => {
              const globalIdx = startIdx + localIdx;
              return (
                <div key={utterance.id} style={{ height: ITEM_HEIGHT }}>
                  <UtteranceRow
                    utterance={utterance}
                    isSelected={selectedId === utterance.id}
                    onSelect={setSelectedId}
                    onFlag={onFlag}
                    onHighlight={onHighlight}
                    onTag={onTag}
                    piiDetections={piiDetections.get(utterance.id)}
                    searchHighlight={
                      matchingUtteranceIds.has(utterance.id) ? searchTerm : undefined
                    }
                    isCurrentMatch={utterance.id === currentMatchUtteranceId}
                  />
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Scroll-to-bottom button (shows when user scrolls up during live session) */}
      {isLive && isUserScrolling && !autoScroll && (
        <div className="absolute bottom-4 left-1/2 -translate-x-1/2 z-10">
          <Button
            variant="secondary"
            size="sm"
            onClick={scrollToBottom}
            className="shadow-lg"
            aria-label="Scroll to latest"
          >
            <ArrowDown className="h-4 w-4 mr-1" aria-hidden="true" />
            Latest
          </Button>
        </div>
      )}
    </div>
  );
}
