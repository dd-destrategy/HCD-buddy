// =============================================================================
// Zustand Store for Live Interview Session
// Manages all real-time session state on the client side
// =============================================================================

import { create } from 'zustand';
import type {
  Utterance,
  CoachingEvent,
  TopicUpdate,
  TalkTimeRatio,
  BiasAlert,
  PIIDetection,
  Comment,
  SessionSummary,
  ServerMessage,
  ClientMessage,
} from '@hcd/ws-protocol';

// =============================================================================
// Types
// =============================================================================

export type SessionStatus = 'idle' | 'ready' | 'running' | 'paused' | 'ending' | 'ended';

export type ConnectionQuality = 'good' | 'degraded' | 'poor';

export interface Insight {
  id: string;
  timestamp: number;
  note?: string;
  createdAt: string;
}

export interface SessionState {
  // ---------------------------------------------------------------------------
  // Session Status
  // ---------------------------------------------------------------------------
  sessionId: string | null;
  status: SessionStatus;
  startedAt: number | null;
  endedAt: number | null;

  // ---------------------------------------------------------------------------
  // Transcript
  // ---------------------------------------------------------------------------
  utterances: Utterance[];
  currentSpeaker: 'interviewer' | 'participant';

  // ---------------------------------------------------------------------------
  // Coaching
  // ---------------------------------------------------------------------------
  coachingEvents: CoachingEvent[];
  activeCoachingEvent: CoachingEvent | null;
  coachingQueue: CoachingEvent[];

  // ---------------------------------------------------------------------------
  // Analysis
  // ---------------------------------------------------------------------------
  talkTimeRatio: TalkTimeRatio | null;
  topicStatuses: TopicUpdate[];
  biasAlerts: BiasAlert[];
  piiDetections: Map<string, PIIDetection[]>;

  // ---------------------------------------------------------------------------
  // Observer
  // ---------------------------------------------------------------------------
  observerComments: Comment[];
  observerCount: number;

  // ---------------------------------------------------------------------------
  // Insights
  // ---------------------------------------------------------------------------
  insights: Insight[];

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------
  connectionQuality: ConnectionQuality;
  latency: number;

  // ---------------------------------------------------------------------------
  // Session Summary (post-session)
  // ---------------------------------------------------------------------------
  summary: SessionSummary | null;

  // ---------------------------------------------------------------------------
  // Error State
  // ---------------------------------------------------------------------------
  lastError: { code: string; message: string } | null;
}

export interface SessionActions {
  // ---------------------------------------------------------------------------
  // Session Lifecycle Actions
  // ---------------------------------------------------------------------------
  /** Initialize the store for a new session */
  initSession: (sessionId: string) => void;
  /** Start the session (sends session.start via WebSocket) */
  startSession: (sendFn: (msg: ClientMessage) => void, meetingUrl?: string, useLocalMic?: boolean) => void;
  /** Pause a running session */
  pauseSession: (sendFn: (msg: ClientMessage) => void) => void;
  /** Resume a paused session */
  resumeSession: (sendFn: (msg: ClientMessage) => void) => void;
  /** Stop the session */
  stopSession: (sendFn: (msg: ClientMessage) => void) => void;
  /** Reset the store to initial state */
  resetSession: () => void;

  // ---------------------------------------------------------------------------
  // Interaction Actions
  // ---------------------------------------------------------------------------
  /** Flag an insight moment */
  flagInsight: (sendFn: (msg: ClientMessage) => void, note?: string) => void;
  /** Respond to a coaching prompt */
  respondToCoaching: (
    sendFn: (msg: ClientMessage) => void,
    eventId: string,
    response: 'accepted' | 'dismissed' | 'snoozed'
  ) => void;
  /** Request a coaching pull */
  pullCoaching: (sendFn: (msg: ClientMessage) => void) => void;
  /** Toggle the current speaker label */
  toggleSpeaker: (sendFn: (msg: ClientMessage) => void) => void;
  /** Update a topic status */
  updateTopic: (sendFn: (msg: ClientMessage) => void, topicName: string, status: string) => void;
  /** Send an observer comment */
  sendObserverComment: (sendFn: (msg: ClientMessage) => void, text: string) => void;
  /** Send an observer question to the interviewer */
  sendObserverQuestion: (sendFn: (msg: ClientMessage) => void, text: string) => void;

  // ---------------------------------------------------------------------------
  // Message Handler
  // ---------------------------------------------------------------------------
  /** Process a message received from the WebSocket server */
  handleServerMessage: (message: ServerMessage) => void;

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------
  /** Update connection quality metrics */
  updateConnectionQuality: (latency: number, quality: ConnectionQuality) => void;
}

export type SessionStore = SessionState & SessionActions;

// =============================================================================
// Initial State
// =============================================================================

const initialState: SessionState = {
  sessionId: null,
  status: 'idle',
  startedAt: null,
  endedAt: null,
  utterances: [],
  currentSpeaker: 'interviewer',
  coachingEvents: [],
  activeCoachingEvent: null,
  coachingQueue: [],
  talkTimeRatio: null,
  topicStatuses: [],
  biasAlerts: [],
  piiDetections: new Map(),
  observerComments: [],
  observerCount: 0,
  insights: [],
  connectionQuality: 'good',
  latency: 0,
  summary: null,
  lastError: null,
};

// =============================================================================
// Store
// =============================================================================

export const useSessionStore = create<SessionStore>((set, get) => ({
  ...initialState,

  // ---------------------------------------------------------------------------
  // Session Lifecycle
  // ---------------------------------------------------------------------------

  initSession: (sessionId: string) => {
    set({
      ...initialState,
      sessionId,
      status: 'ready',
      piiDetections: new Map(),
    });
  },

  startSession: (sendFn, meetingUrl?, useLocalMic?) => {
    const { sessionId } = get();
    if (!sessionId) return;

    sendFn({
      type: 'session.start',
      sessionId,
      meetingUrl,
      useLocalMic,
    });

    set({ status: 'running', startedAt: Date.now() });
  },

  pauseSession: (sendFn) => {
    sendFn({ type: 'session.pause' });
    set({ status: 'paused' });
  },

  resumeSession: (sendFn) => {
    sendFn({ type: 'session.resume' });
    set({ status: 'running' });
  },

  stopSession: (sendFn) => {
    sendFn({ type: 'session.stop' });
    set({ status: 'ending' });
  },

  resetSession: () => {
    set({ ...initialState, piiDetections: new Map() });
  },

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  flagInsight: (sendFn, note?) => {
    const timestamp = Date.now();
    sendFn({ type: 'insight.flag', timestamp, note });

    const insight: Insight = {
      id: `insight_${timestamp}`,
      timestamp,
      note,
      createdAt: new Date().toISOString(),
    };

    set((state) => ({
      insights: [...state.insights, insight],
    }));
  },

  respondToCoaching: (sendFn, eventId, response) => {
    sendFn({ type: 'coaching.respond', eventId, response });

    set((state) => {
      const updates: Partial<SessionState> = {};

      if (state.activeCoachingEvent?.id === eventId) {
        // Pop the next coaching event from the queue
        const nextEvent = state.coachingQueue[0] || null;
        updates.activeCoachingEvent = nextEvent;
        updates.coachingQueue = nextEvent
          ? state.coachingQueue.slice(1)
          : state.coachingQueue;
      }

      return updates;
    });
  },

  pullCoaching: (sendFn) => {
    sendFn({ type: 'coaching.pull' });
  },

  toggleSpeaker: (sendFn) => {
    sendFn({ type: 'speaker.toggle' });
    set((state) => ({
      currentSpeaker: state.currentSpeaker === 'interviewer' ? 'participant' : 'interviewer',
    }));
  },

  updateTopic: (sendFn, topicName, status) => {
    sendFn({ type: 'topic.update', topicName, status });
  },

  sendObserverComment: (sendFn, text) => {
    sendFn({ type: 'observer.comment', text, timestamp: Date.now() });
  },

  sendObserverQuestion: (sendFn, text) => {
    sendFn({ type: 'observer.question', text });
  },

  // ---------------------------------------------------------------------------
  // Server Message Handler
  // ---------------------------------------------------------------------------

  handleServerMessage: (message: ServerMessage) => {
    switch (message.type) {
      // Session status
      case 'session.status':
        set({
          status: message.status as SessionStatus,
          sessionId: message.sessionId,
          ...(message.status === 'ended' ? { endedAt: Date.now() } : {}),
        });
        break;

      // Session error
      case 'session.error':
        set({ lastError: { code: message.code, message: message.message } });
        break;

      // New utterance (partial or streaming)
      case 'transcript.utterance':
        set((state) => {
          // Check if this utterance already exists (update vs add)
          const existingIndex = state.utterances.findIndex(
            (u) => u.id === message.utterance.id
          );

          if (existingIndex >= 0) {
            const updated = [...state.utterances];
            updated[existingIndex] = message.utterance;
            return { utterances: updated };
          }

          return {
            utterances: [...state.utterances, message.utterance],
            currentSpeaker: message.utterance.speaker,
          };
        });
        break;

      // Utterance text update (partial transcription)
      case 'transcript.update':
        set((state) => {
          const updated = state.utterances.map((u) =>
            u.id === message.utteranceId ? { ...u, text: message.text } : u
          );
          return { utterances: updated };
        });
        break;

      // Finalized utterance
      case 'transcript.finalized':
        set((state) => {
          const updated = state.utterances.map((u) =>
            u.id === message.utteranceId ? message.utterance : u
          );
          return { utterances: updated };
        });
        break;

      // Coaching prompt
      case 'coaching.prompt':
        set((state) => {
          const events = [...state.coachingEvents, message.event];

          // If no active coaching event, show this one immediately
          if (!state.activeCoachingEvent) {
            return {
              coachingEvents: events,
              activeCoachingEvent: message.event,
            };
          }

          // Otherwise, queue it
          return {
            coachingEvents: events,
            coachingQueue: [...state.coachingQueue, message.event],
          };
        });
        break;

      // Coaching dismiss
      case 'coaching.dismiss':
        set((state) => {
          if (state.activeCoachingEvent?.id === message.eventId) {
            const nextEvent = state.coachingQueue[0] || null;
            return {
              activeCoachingEvent: nextEvent,
              coachingQueue: nextEvent ? state.coachingQueue.slice(1) : state.coachingQueue,
            };
          }
          return {};
        });
        break;

      // Coaching queue
      case 'coaching.queue':
        set({
          coachingQueue: message.events,
          activeCoachingEvent: message.events[0] || null,
        });
        break;

      // Talk time analysis
      case 'analysis.talktime':
        set({ talkTimeRatio: message.ratio });
        break;

      // Sentiment analysis
      case 'analysis.sentiment':
        set((state) => {
          const updated = state.utterances.map((u) =>
            u.id === message.utteranceId
              ? {
                  ...u,
                  sentimentScore: message.score,
                  sentimentPolarity: message.polarity as Utterance['sentimentPolarity'],
                }
              : u
          );
          return { utterances: updated };
        });
        break;

      // Topic update
      case 'analysis.topic':
        set((state) => {
          const existingIndex = state.topicStatuses.findIndex(
            (t) => t.topicName === message.topic.topicName
          );

          if (existingIndex >= 0) {
            const updated = [...state.topicStatuses];
            updated[existingIndex] = message.topic;
            return { topicStatuses: updated };
          }

          return { topicStatuses: [...state.topicStatuses, message.topic] };
        });
        break;

      // PII detection
      case 'analysis.pii':
        set((state) => {
          const newMap = new Map(state.piiDetections);
          newMap.set(message.utteranceId, message.detections);
          return { piiDetections: newMap };
        });
        break;

      // Bias alert
      case 'analysis.bias':
        set((state) => ({
          biasAlerts: [...state.biasAlerts, message.alert],
        }));
        break;

      // Question type analysis
      case 'analysis.questionType':
        set((state) => {
          const updated = state.utterances.map((u) =>
            u.id === message.utteranceId
              ? { ...u, questionType: message.questionType as Utterance['questionType'] }
              : u
          );
          return { utterances: updated };
        });
        break;

      // Observer comment
      case 'observer.comment':
        set((state) => ({
          observerComments: [...state.observerComments, message.comment],
        }));
        break;

      // Observer question (interviewer receives this)
      case 'observer.question':
        // This is handled by the UI directly; no state change needed
        break;

      // Observer count
      case 'observer.count':
        set({ observerCount: message.count });
        break;

      // Session summary
      case 'session.summary':
        set({ summary: message.summary });
        break;

      // Connection quality
      case 'connection.quality':
        set({
          latency: message.latency,
          connectionQuality: message.status,
        });
        break;

      // General error
      case 'error':
        set({ lastError: { code: message.code, message: message.message } });
        break;

      // Pong is handled by the hook, not the store
      case 'pong':
        break;
    }
  },

  // ---------------------------------------------------------------------------
  // Connection Quality
  // ---------------------------------------------------------------------------

  updateConnectionQuality: (latency: number, quality: ConnectionQuality) => {
    set({ latency, connectionQuality: quality });
  },
}));

// =============================================================================
// Selectors (for optimized re-renders)
// =============================================================================

/** Select just the session status */
export const selectStatus = (state: SessionStore) => state.status;

/** Select the utterances array */
export const selectUtterances = (state: SessionStore) => state.utterances;

/** Select the active coaching event */
export const selectActiveCoaching = (state: SessionStore) => state.activeCoachingEvent;

/** Select talk time ratio */
export const selectTalkTimeRatio = (state: SessionStore) => state.talkTimeRatio;

/** Select topic statuses */
export const selectTopicStatuses = (state: SessionStore) => state.topicStatuses;

/** Select observer comments */
export const selectObserverComments = (state: SessionStore) => state.observerComments;

/** Select insights */
export const selectInsights = (state: SessionStore) => state.insights;

/** Select connection quality info */
export const selectConnectionInfo = (state: SessionStore) => ({
  quality: state.connectionQuality,
  latency: state.latency,
});

/** Select whether the session is actively recording */
export const selectIsRecording = (state: SessionStore) =>
  state.status === 'running';

/** Select the last error */
export const selectLastError = (state: SessionStore) => state.lastError;

/** Select session summary */
export const selectSummary = (state: SessionStore) => state.summary;

/** Select bias alerts */
export const selectBiasAlerts = (state: SessionStore) => state.biasAlerts;

/** Select observer count */
export const selectObserverCount = (state: SessionStore) => state.observerCount;
