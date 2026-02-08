import { create } from 'zustand';
import type { CoachingEvent } from '@hcd/ws-protocol';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export type CoachingDeliveryMode = 'realtime' | 'pull';

export type CoachingResponseType = 'accepted' | 'dismissed' | 'snoozed' | 'expired';

export interface CoachingHistoryEntry {
  event: CoachingEvent;
  response: CoachingResponseType;
  respondedAt: string;
}

export interface CoachingSettings {
  enabled: boolean;
  deliveryMode: CoachingDeliveryMode;
  autoDismissDuration: number; // seconds
  maxPrompts: number;
  culturalPreset: string;
}

export interface CoachingState {
  // Current prompt
  activePrompt: CoachingEvent | null;
  activePromptShownAt: number | null;

  // History
  history: CoachingHistoryEntry[];

  // Queue (for pull mode)
  queue: CoachingEvent[];

  // Settings
  settings: CoachingSettings;

  // Stats
  promptsShownCount: number;

  // Auto-dismiss timer id
  _autoDismissTimer: ReturnType<typeof setTimeout> | null;

  // Actions
  showPrompt: (event: CoachingEvent) => void;
  dismissPrompt: (eventId: string) => void;
  acceptPrompt: (eventId: string) => void;
  snoozePrompt: (eventId: string) => void;
  expirePrompt: (eventId: string) => void;
  pullNext: () => CoachingEvent | null;
  enqueuePrompts: (events: CoachingEvent[]) => void;
  updateSettings: (settings: Partial<CoachingSettings>) => void;
  reset: () => void;
}

// ---------------------------------------------------------------------------
// Default settings
// ---------------------------------------------------------------------------

const DEFAULT_SETTINGS: CoachingSettings = {
  enabled: true,
  deliveryMode: 'realtime',
  autoDismissDuration: 8,
  maxPrompts: 3,
  culturalPreset: 'default',
};

// ---------------------------------------------------------------------------
// Helper: record a response in history and clear the active prompt
// ---------------------------------------------------------------------------

function respondToActive(
  state: CoachingState,
  eventId: string,
  response: CoachingResponseType,
): Partial<CoachingState> {
  if (!state.activePrompt || state.activePrompt.id !== eventId) {
    return {};
  }

  // Clear auto-dismiss timer
  if (state._autoDismissTimer) {
    clearTimeout(state._autoDismissTimer);
  }

  return {
    activePrompt: null,
    activePromptShownAt: null,
    _autoDismissTimer: null,
    history: [
      ...state.history,
      {
        event: state.activePrompt,
        response,
        respondedAt: new Date().toISOString(),
      },
    ],
  };
}

// ---------------------------------------------------------------------------
// Store
// ---------------------------------------------------------------------------

export const useCoachingStore = create<CoachingState>((set, get) => ({
  activePrompt: null,
  activePromptShownAt: null,
  history: [],
  queue: [],
  settings: { ...DEFAULT_SETTINGS },
  promptsShownCount: 0,
  _autoDismissTimer: null,

  showPrompt: (event: CoachingEvent) => {
    const state = get();

    // If coaching is disabled, ignore
    if (!state.settings.enabled) return;

    // If max prompts reached, ignore
    if (state.promptsShownCount >= state.settings.maxPrompts) return;

    // In pull mode, enqueue instead of showing
    if (state.settings.deliveryMode === 'pull') {
      set({ queue: [...state.queue, event] });
      return;
    }

    // If there is already an active prompt, enqueue the new one
    if (state.activePrompt) {
      set({ queue: [...state.queue, event] });
      return;
    }

    // Clear any existing timer
    if (state._autoDismissTimer) {
      clearTimeout(state._autoDismissTimer);
    }

    // Start auto-dismiss timer
    const timer = setTimeout(() => {
      get().expirePrompt(event.id);
    }, state.settings.autoDismissDuration * 1000);

    set({
      activePrompt: event,
      activePromptShownAt: Date.now(),
      promptsShownCount: state.promptsShownCount + 1,
      _autoDismissTimer: timer,
    });
  },

  dismissPrompt: (eventId: string) => {
    set((state) => respondToActive(state, eventId, 'dismissed'));
  },

  acceptPrompt: (eventId: string) => {
    set((state) => respondToActive(state, eventId, 'accepted'));
  },

  snoozePrompt: (eventId: string) => {
    const state = get();
    if (!state.activePrompt || state.activePrompt.id !== eventId) return;

    // Clear timer
    if (state._autoDismissTimer) {
      clearTimeout(state._autoDismissTimer);
    }

    // Move to front of queue so it re-appears later
    set({
      activePrompt: null,
      activePromptShownAt: null,
      _autoDismissTimer: null,
      queue: [state.activePrompt, ...state.queue],
      // Decrement shown count since it will be shown again
      promptsShownCount: Math.max(0, state.promptsShownCount - 1),
      history: [
        ...state.history,
        {
          event: state.activePrompt,
          response: 'snoozed',
          respondedAt: new Date().toISOString(),
        },
      ],
    });
  },

  expirePrompt: (eventId: string) => {
    set((state) => respondToActive(state, eventId, 'expired'));
  },

  pullNext: () => {
    const state = get();
    if (state.queue.length === 0) return null;
    if (state.activePrompt) return null;
    if (state.promptsShownCount >= state.settings.maxPrompts) return null;

    const [next, ...remaining] = state.queue;

    // Clear any existing timer
    if (state._autoDismissTimer) {
      clearTimeout(state._autoDismissTimer);
    }

    const timer = setTimeout(() => {
      get().expirePrompt(next.id);
    }, state.settings.autoDismissDuration * 1000);

    set({
      activePrompt: next,
      activePromptShownAt: Date.now(),
      queue: remaining,
      promptsShownCount: state.promptsShownCount + 1,
      _autoDismissTimer: timer,
    });

    return next;
  },

  enqueuePrompts: (events: CoachingEvent[]) => {
    set((state) => ({
      queue: [...state.queue, ...events],
    }));
  },

  updateSettings: (partial: Partial<CoachingSettings>) => {
    set((state) => ({
      settings: { ...state.settings, ...partial },
    }));
  },

  reset: () => {
    const state = get();
    if (state._autoDismissTimer) {
      clearTimeout(state._autoDismissTimer);
    }
    set({
      activePrompt: null,
      activePromptShownAt: null,
      history: [],
      queue: [],
      promptsShownCount: 0,
      _autoDismissTimer: null,
      settings: { ...DEFAULT_SETTINGS },
    });
  },
}));
