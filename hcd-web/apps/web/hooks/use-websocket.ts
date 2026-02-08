'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import type {
  ClientMessage,
  ServerMessage,
  Utterance,
  CoachingEvent,
  TopicUpdate,
  TalkTimeRatio,
  PIIDetection,
  BiasAlert,
  SessionSummary,
  Comment,
} from '@hcd/ws-protocol';

// =============================================================================
// Types
// =============================================================================

export type ConnectionStatus = 'disconnected' | 'connecting' | 'connected' | 'error';
export type ConnectionQuality = 'good' | 'degraded' | 'poor';

export interface WebSocketState {
  status: ConnectionStatus;
  quality: ConnectionQuality;
  latency: number;
  sessionStatus: string | null;
  utterances: Utterance[];
  coachingEvents: CoachingEvent[];
  topics: TopicUpdate[];
  talkTimeRatio: TalkTimeRatio | null;
  piiDetections: Map<string, PIIDetection[]>;
  biasAlerts: BiasAlert[];
  comments: Comment[];
  observerCount: number;
  summary: SessionSummary | null;
  error: string | null;
}

export interface WebSocketActions {
  connect: (sessionId: string, meetingUrl?: string, useLocalMic?: boolean) => void;
  disconnect: () => void;
  sendAudioChunk: (base64Data: string) => void;
  flagInsight: (timestamp: number, note?: string) => void;
  respondToCoaching: (eventId: string, response: 'accepted' | 'dismissed' | 'snoozed') => void;
  pullCoaching: () => void;
  updateTopic: (topicName: string, status: string) => void;
  toggleSpeaker: () => void;
  pauseSession: () => void;
  resumeSession: () => void;
  stopSession: () => void;
  joinAsObserver: (sessionId: string) => void;
  sendComment: (text: string, timestamp: number) => void;
  sendQuestion: (text: string) => void;
}

// =============================================================================
// Hook
// =============================================================================

const INITIAL_STATE: WebSocketState = {
  status: 'disconnected',
  quality: 'good',
  latency: 0,
  sessionStatus: null,
  utterances: [],
  coachingEvents: [],
  topics: [],
  talkTimeRatio: null,
  piiDetections: new Map(),
  biasAlerts: [],
  comments: [],
  observerCount: 0,
  summary: null,
  error: null,
};

export function useWebSocket(wsUrl?: string): WebSocketState & WebSocketActions {
  const [state, setState] = useState<WebSocketState>({ ...INITIAL_STATE });
  const wsRef = useRef<WebSocket | null>(null);
  const pingIntervalRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const reconnectAttemptsRef = useRef(0);

  const url = wsUrl || process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:3001';

  // --- Send message helper ---
  const send = useCallback((msg: ClientMessage) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(msg));
    }
  }, []);

  // --- Handle incoming server messages ---
  const handleMessage = useCallback((event: MessageEvent) => {
    let msg: ServerMessage;
    try {
      msg = JSON.parse(event.data as string);
    } catch {
      return;
    }

    setState((prev) => {
      switch (msg.type) {
        case 'session.status':
          return { ...prev, sessionStatus: msg.status };

        case 'session.error':
          return { ...prev, error: `${msg.code}: ${msg.message}` };

        case 'transcript.utterance':
          return {
            ...prev,
            utterances: [...prev.utterances, msg.utterance],
          };

        case 'transcript.update': {
          const updated = prev.utterances.map((u) =>
            u.id === msg.utteranceId ? { ...u, text: msg.text } : u
          );
          return { ...prev, utterances: updated };
        }

        case 'transcript.finalized': {
          const finalized = prev.utterances.map((u) =>
            u.id === msg.utteranceId ? msg.utterance : u
          );
          return { ...prev, utterances: finalized };
        }

        case 'coaching.prompt':
          return {
            ...prev,
            coachingEvents: [...prev.coachingEvents, msg.event],
          };

        case 'coaching.dismiss': {
          const filtered = prev.coachingEvents.filter((e) => e.id !== msg.eventId);
          return { ...prev, coachingEvents: filtered };
        }

        case 'coaching.queue':
          return { ...prev, coachingEvents: msg.events };

        case 'analysis.talktime':
          return { ...prev, talkTimeRatio: msg.ratio };

        case 'analysis.sentiment': {
          const withSentiment = prev.utterances.map((u) =>
            u.id === msg.utteranceId
              ? { ...u, sentimentScore: msg.score, sentimentPolarity: msg.polarity as Utterance['sentimentPolarity'] }
              : u
          );
          return { ...prev, utterances: withSentiment };
        }

        case 'analysis.topic': {
          const existingIdx = prev.topics.findIndex(
            (t) => t.topicName === msg.topic.topicName
          );
          const newTopics = [...prev.topics];
          if (existingIdx >= 0) {
            newTopics[existingIdx] = msg.topic;
          } else {
            newTopics.push(msg.topic);
          }
          return { ...prev, topics: newTopics };
        }

        case 'analysis.pii': {
          const newPii = new Map(prev.piiDetections);
          newPii.set(msg.utteranceId, msg.detections);
          return { ...prev, piiDetections: newPii };
        }

        case 'analysis.bias':
          return { ...prev, biasAlerts: [...prev.biasAlerts, msg.alert] };

        case 'analysis.questionType': {
          const withQt = prev.utterances.map((u) =>
            u.id === msg.utteranceId
              ? { ...u, questionType: msg.questionType as Utterance['questionType'] }
              : u
          );
          return { ...prev, utterances: withQt };
        }

        case 'observer.comment':
          return { ...prev, comments: [...prev.comments, msg.comment] };

        case 'observer.count':
          return { ...prev, observerCount: msg.count };

        case 'session.summary':
          return { ...prev, summary: msg.summary };

        case 'connection.quality':
          return {
            ...prev,
            quality: msg.status,
            latency: msg.latency,
          };

        case 'pong':
          return prev;

        case 'error':
          return { ...prev, error: `${msg.code}: ${msg.message}` };

        default:
          return prev;
      }
    });
  }, []);

  // --- Connect ---
  const connect = useCallback(
    (sessionId: string, meetingUrl?: string, useLocalMic?: boolean) => {
      // Clean up existing connection
      if (wsRef.current) {
        wsRef.current.close();
        wsRef.current = null;
      }

      setState((prev) => ({ ...prev, status: 'connecting', error: null }));

      const ws = new WebSocket(`${url}?sessionId=${sessionId}`);
      wsRef.current = ws;

      ws.onopen = () => {
        setState((prev) => ({ ...prev, status: 'connected' }));
        reconnectAttemptsRef.current = 0;

        // Start the session
        send({
          type: 'session.start',
          sessionId,
          meetingUrl,
          useLocalMic,
        });

        // Start ping interval for keep-alive
        pingIntervalRef.current = setInterval(() => {
          send({ type: 'ping' });
        }, 30000);
      };

      ws.onmessage = handleMessage;

      ws.onerror = () => {
        setState((prev) => ({
          ...prev,
          status: 'error',
          error: 'WebSocket connection error',
        }));
      };

      ws.onclose = () => {
        setState((prev) => ({ ...prev, status: 'disconnected' }));

        if (pingIntervalRef.current) {
          clearInterval(pingIntervalRef.current);
          pingIntervalRef.current = null;
        }

        // Auto-reconnect with exponential backoff (max 5 attempts)
        if (reconnectAttemptsRef.current < 5) {
          const delay = Math.min(1000 * Math.pow(2, reconnectAttemptsRef.current), 30000);
          reconnectAttemptsRef.current++;
          reconnectTimeoutRef.current = setTimeout(() => {
            connect(sessionId, meetingUrl, useLocalMic);
          }, delay);
        }
      };
    },
    [url, send, handleMessage]
  );

  // --- Disconnect ---
  const disconnect = useCallback(() => {
    reconnectAttemptsRef.current = 999; // Prevent auto-reconnect
    if (reconnectTimeoutRef.current) {
      clearTimeout(reconnectTimeoutRef.current);
    }
    if (pingIntervalRef.current) {
      clearInterval(pingIntervalRef.current);
    }
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
    setState({ ...INITIAL_STATE });
  }, []);

  // --- Action methods ---
  const sendAudioChunk = useCallback(
    (data: string) => send({ type: 'audio.chunk', data }),
    [send]
  );

  const flagInsight = useCallback(
    (timestamp: number, note?: string) => send({ type: 'insight.flag', timestamp, note }),
    [send]
  );

  const respondToCoaching = useCallback(
    (eventId: string, response: 'accepted' | 'dismissed' | 'snoozed') =>
      send({ type: 'coaching.respond', eventId, response }),
    [send]
  );

  const pullCoaching = useCallback(() => send({ type: 'coaching.pull' }), [send]);

  const updateTopic = useCallback(
    (topicName: string, status: string) =>
      send({ type: 'topic.update', topicName, status }),
    [send]
  );

  const toggleSpeaker = useCallback(() => send({ type: 'speaker.toggle' }), [send]);
  const pauseSession = useCallback(() => send({ type: 'session.pause' }), [send]);
  const resumeSession = useCallback(() => send({ type: 'session.resume' }), [send]);
  const stopSession = useCallback(() => send({ type: 'session.stop' }), [send]);

  const joinAsObserver = useCallback(
    (sessionId: string) => send({ type: 'observer.join', sessionId }),
    [send]
  );

  const sendComment = useCallback(
    (text: string, timestamp: number) =>
      send({ type: 'observer.comment', text, timestamp }),
    [send]
  );

  const sendQuestion = useCallback(
    (text: string) => send({ type: 'observer.question', text }),
    [send]
  );

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (reconnectTimeoutRef.current) clearTimeout(reconnectTimeoutRef.current);
      if (pingIntervalRef.current) clearInterval(pingIntervalRef.current);
      if (wsRef.current) wsRef.current.close();
    };
  }, []);

  return {
    ...state,
    connect,
    disconnect,
    sendAudioChunk,
    flagInsight,
    respondToCoaching,
    pullCoaching,
    updateTopic,
    toggleSpeaker,
    pauseSession,
    resumeSession,
    stopSession,
    joinAsObserver,
    sendComment,
    sendQuestion,
  };
}
