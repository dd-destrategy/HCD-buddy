'use client';

import { useCallback, useEffect, useState } from 'react';
import { Eye, MessageSquare, BarChart3 } from 'lucide-react';
import { Button } from '@hcd/ui';

// =============================================================================
// FocusModeSwitcher — Toggle between Interview, Coached, and Analysis modes
// =============================================================================

export type FocusMode = 'interview' | 'coached' | 'analysis';

interface FocusModeSwitcherProps {
  /** Current mode */
  value: FocusMode;
  /** Called when mode changes */
  onChange: (mode: FocusMode) => void;
  /** Additional CSS classes */
  className?: string;
}

const MODES: Array<{ id: FocusMode; label: string; shortcut: string; icon: typeof Eye; description: string }> = [
  {
    id: 'interview',
    label: 'Interview',
    shortcut: '1',
    icon: Eye,
    description: 'Transcript only — minimal distractions',
  },
  {
    id: 'coached',
    label: 'Coached',
    shortcut: '2',
    icon: MessageSquare,
    description: 'Transcript with coaching prompts',
  },
  {
    id: 'analysis',
    label: 'Analysis',
    shortcut: '3',
    icon: BarChart3,
    description: 'All panels — full analysis view',
  },
];

const STORAGE_KEY = 'hcd-focus-mode';

export function FocusModeSwitcher({ value, onChange, className = '' }: FocusModeSwitcherProps) {
  // Restore persisted preference on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored && ['interview', 'coached', 'analysis'].includes(stored)) {
      onChange(stored as FocusMode);
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Keyboard shortcuts: Cmd+1, Cmd+2, Cmd+3
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (!e.metaKey && !e.ctrlKey) return;

      const modeMap: Record<string, FocusMode> = {
        '1': 'interview',
        '2': 'coached',
        '3': 'analysis',
      };

      const mode = modeMap[e.key];
      if (mode) {
        e.preventDefault();
        onChange(mode);
        localStorage.setItem(STORAGE_KEY, mode);
      }
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onChange]);

  const handleSelect = useCallback(
    (mode: FocusMode) => {
      onChange(mode);
      localStorage.setItem(STORAGE_KEY, mode);
    },
    [onChange]
  );

  return (
    <div
      className={`inline-flex items-center gap-0.5 rounded-lg border bg-muted p-0.5 ${className}`}
      role="radiogroup"
      aria-label="Focus mode"
    >
      {MODES.map((mode) => {
        const Icon = mode.icon;
        const isActive = value === mode.id;

        return (
          <button
            key={mode.id}
            type="button"
            role="radio"
            aria-checked={isActive}
            aria-label={`${mode.label} mode (${navigator.platform.includes('Mac') ? 'Cmd' : 'Ctrl'}+${mode.shortcut}): ${mode.description}`}
            title={`${mode.label} — ${mode.description} (${navigator.platform.includes('Mac') ? '\u2318' : 'Ctrl'}+${mode.shortcut})`}
            onClick={() => handleSelect(mode.id)}
            className={`
              inline-flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-colors
              ${
                isActive
                  ? 'bg-background text-foreground shadow-sm'
                  : 'text-muted-foreground hover:text-foreground hover:bg-background/50'
              }
            `}
          >
            <Icon className="h-3.5 w-3.5" aria-hidden="true" />
            <span className="hidden sm:inline">{mode.label}</span>
          </button>
        );
      })}
    </div>
  );
}
