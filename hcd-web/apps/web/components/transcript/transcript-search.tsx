'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { Search, ChevronUp, ChevronDown, X } from 'lucide-react';
import { Input } from '@hcd/ui';

// =============================================================================
// TranscriptSearch — Search bar with match navigation
// =============================================================================

interface TranscriptSearchProps {
  /** Called when search term changes */
  onSearch: (term: string) => void;
  /** Total number of matches */
  matchCount: number;
  /** Current match index (0-based) */
  currentMatchIndex: number;
  /** Navigate to next match */
  onNextMatch: () => void;
  /** Navigate to previous match */
  onPrevMatch: () => void;
  /** Called when search is closed */
  onClose: () => void;
  /** Whether the search bar is visible */
  isOpen: boolean;
  /** Called to open the search bar */
  onOpen: () => void;
  /** Additional CSS classes */
  className?: string;
}

export function TranscriptSearch({
  onSearch,
  matchCount,
  currentMatchIndex,
  onNextMatch,
  onPrevMatch,
  onClose,
  isOpen,
  onOpen,
  className = '',
}: TranscriptSearchProps) {
  const [query, setQuery] = useState('');
  const inputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut: Cmd+F to open
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === 'f') {
        e.preventDefault();
        onOpen();
      }

      // Escape to close
      if (e.key === 'Escape' && isOpen) {
        handleClose();
      }

      // Enter to navigate matches
      if (e.key === 'Enter' && isOpen && matchCount > 0) {
        e.preventDefault();
        if (e.shiftKey) {
          onPrevMatch();
        } else {
          onNextMatch();
        }
      }
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, matchCount, onOpen, onNextMatch, onPrevMatch]);

  // Focus input when opened
  useEffect(() => {
    if (isOpen) {
      // Small delay for animation
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  }, [isOpen]);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const val = e.target.value;
      setQuery(val);
      onSearch(val);
    },
    [onSearch]
  );

  const handleClose = useCallback(() => {
    setQuery('');
    onSearch('');
    onClose();
  }, [onSearch, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className={`flex items-center gap-2 rounded-lg border bg-background px-3 py-1.5 shadow-sm animate-fade-in ${className}`}
      role="search"
      aria-label="Search transcript"
    >
      <Search className="h-4 w-4 text-muted-foreground shrink-0" aria-hidden="true" />

      <Input
        ref={inputRef}
        type="text"
        value={query}
        onChange={handleChange}
        placeholder="Search transcript..."
        className="h-7 border-0 bg-transparent px-0 text-sm focus-visible:ring-0 focus-visible:ring-offset-0"
        aria-label="Search text"
      />

      {/* Match count */}
      {query.length > 0 && (
        <span className="text-xs text-muted-foreground shrink-0 tabular-nums">
          {matchCount > 0 ? (
            <>
              {currentMatchIndex + 1} of {matchCount}
            </>
          ) : (
            'No matches'
          )}
        </span>
      )}

      {/* Navigation arrows */}
      {matchCount > 0 && (
        <>
          <button
            type="button"
            onClick={onPrevMatch}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground disabled:opacity-40"
            disabled={matchCount === 0}
            aria-label="Previous match"
            title="Previous match (Shift+Enter)"
          >
            <ChevronUp className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onNextMatch}
            className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground disabled:opacity-40"
            disabled={matchCount === 0}
            aria-label="Next match"
            title="Next match (Enter)"
          >
            <ChevronDown className="h-4 w-4" />
          </button>
        </>
      )}

      {/* Close button */}
      <button
        type="button"
        onClick={handleClose}
        className="p-1 rounded hover:bg-muted text-muted-foreground hover:text-foreground"
        aria-label="Close search"
        title="Close (Esc)"
      >
        <X className="h-4 w-4" />
      </button>
    </div>
  );
}
