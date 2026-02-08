'use client';

import React, { useCallback } from 'react';
import { cn } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import { Settings, Sparkles } from 'lucide-react';
import { useCoachingStore, type CoachingDeliveryMode } from '@/stores/coaching-store';

// ---------------------------------------------------------------------------
// Cultural presets
// ---------------------------------------------------------------------------

const CULTURAL_PRESETS = [
  { value: 'default', label: 'Default' },
  { value: 'western', label: 'Western' },
  { value: 'east-asian', label: 'East Asian' },
  { value: 'south-asian', label: 'South Asian' },
  { value: 'middle-eastern', label: 'Middle Eastern' },
  { value: 'latin-american', label: 'Latin American' },
] as const;

const AUTO_DISMISS_OPTIONS = [5, 8, 12, 15] as const;

// ---------------------------------------------------------------------------
// Props
// ---------------------------------------------------------------------------

export interface CoachingSettingsPanelProps {
  className?: string;
}

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function CoachingSettingsPanel({ className }: CoachingSettingsPanelProps) {
  const settings = useCoachingStore((s) => s.settings);
  const promptsShownCount = useCoachingStore((s) => s.promptsShownCount);
  const updateSettings = useCoachingStore((s) => s.updateSettings);

  const remainingPrompts = Math.max(0, settings.maxPrompts - promptsShownCount);

  const handleToggleEnabled = useCallback(() => {
    updateSettings({ enabled: !settings.enabled });
  }, [settings.enabled, updateSettings]);

  const handleDeliveryModeChange = useCallback(
    (mode: CoachingDeliveryMode) => {
      updateSettings({ deliveryMode: mode });
    },
    [updateSettings],
  );

  const handleAutoDismissChange = useCallback(
    (duration: number) => {
      updateSettings({ autoDismissDuration: duration });
    },
    [updateSettings],
  );

  const handleCulturalPresetChange = useCallback(
    (preset: string) => {
      updateSettings({ culturalPreset: preset });
    },
    [updateSettings],
  );

  return (
    <div
      className={cn('flex flex-col gap-4 p-4', className)}
      role="region"
      aria-label="Coaching settings"
    >
      {/* Header */}
      <div className="flex items-center gap-2">
        <Settings className="h-4 w-4 text-muted-foreground" />
        <h3 className="text-sm font-semibold">Coaching Settings</h3>
      </div>

      {/* Enable/Disable toggle */}
      <div className="flex items-center justify-between">
        <label
          htmlFor="coaching-enabled"
          className="text-sm font-medium cursor-pointer flex items-center gap-2"
        >
          <Sparkles className="h-4 w-4 text-purple-500" />
          Enable coaching
        </label>
        <button
          id="coaching-enabled"
          role="switch"
          aria-checked={settings.enabled}
          onClick={handleToggleEnabled}
          className={cn(
            'relative inline-flex h-6 w-11 items-center rounded-full transition-colors',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2',
            settings.enabled ? 'bg-purple-600' : 'bg-muted',
          )}
          aria-label={`Coaching is ${settings.enabled ? 'enabled' : 'disabled'}`}
        >
          <span
            className={cn(
              'inline-block h-4 w-4 rounded-full bg-white transition-transform shadow-sm',
              settings.enabled ? 'translate-x-6' : 'translate-x-1',
            )}
          />
        </button>
      </div>

      {/* Remaining prompts */}
      <div className="flex items-center justify-between">
        <span className="text-sm text-muted-foreground">Prompts remaining</span>
        <Badge
          variant={remainingPrompts > 0 ? 'secondary' : 'destructive'}
          className="tabular-nums"
          aria-label={`${remainingPrompts} of ${settings.maxPrompts} prompts remaining`}
        >
          {remainingPrompts} / {settings.maxPrompts}
        </Badge>
      </div>

      {/* Delivery mode toggle */}
      <fieldset className="space-y-2" disabled={!settings.enabled}>
        <legend className="text-sm font-medium">Delivery mode</legend>
        <div className="flex rounded-lg overflow-hidden border" role="radiogroup">
          {(['realtime', 'pull'] as const).map((mode) => (
            <button
              key={mode}
              role="radio"
              aria-checked={settings.deliveryMode === mode}
              onClick={() => handleDeliveryModeChange(mode)}
              className={cn(
                'flex-1 px-3 py-2 text-sm font-medium transition-colors capitalize',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-ring',
                settings.deliveryMode === mode
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-background text-muted-foreground hover:bg-muted',
              )}
            >
              {mode === 'realtime' ? 'Real-time' : 'Pull'}
            </button>
          ))}
        </div>
        <p className="text-xs text-muted-foreground">
          {settings.deliveryMode === 'realtime'
            ? 'Prompts appear automatically when triggered'
            : 'Prompts queue up; pull when ready'}
        </p>
      </fieldset>

      {/* Auto-dismiss duration */}
      <fieldset className="space-y-2" disabled={!settings.enabled}>
        <legend className="text-sm font-medium">Auto-dismiss (seconds)</legend>
        <div className="flex gap-1.5" role="radiogroup">
          {AUTO_DISMISS_OPTIONS.map((duration) => (
            <button
              key={duration}
              role="radio"
              aria-checked={settings.autoDismissDuration === duration}
              onClick={() => handleAutoDismissChange(duration)}
              className={cn(
                'flex-1 px-2 py-1.5 text-sm rounded-md font-medium transition-colors tabular-nums',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
                settings.autoDismissDuration === duration
                  ? 'bg-primary text-primary-foreground'
                  : 'bg-muted text-muted-foreground hover:bg-muted/80',
              )}
            >
              {duration}s
            </button>
          ))}
        </div>
      </fieldset>

      {/* Cultural preset */}
      <fieldset className="space-y-2" disabled={!settings.enabled}>
        <legend className="text-sm font-medium">Cultural preset</legend>
        <select
          value={settings.culturalPreset}
          onChange={(e) => handleCulturalPresetChange(e.target.value)}
          className={cn(
            'w-full h-9 rounded-lg border border-input bg-background px-3 py-1 text-sm',
            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
            'disabled:cursor-not-allowed disabled:opacity-50',
          )}
          aria-label="Select cultural preset"
        >
          {CULTURAL_PRESETS.map((preset) => (
            <option key={preset.value} value={preset.value}>
              {preset.label}
            </option>
          ))}
        </select>
      </fieldset>
    </div>
  );
}
