// ============================================================
// WebSocket Message Protocol — Shared between client and server
// ============================================================

// --- Shared Types ---

export interface Utterance {
  id: string;
  sessionId: string;
  speaker: 'interviewer' | 'participant';
  text: string;
  startTime: number;
  endTime?: number;
  confidence?: number;
  sentimentScore?: number;
  sentimentPolarity?: 'positive' | 'negative' | 'neutral' | 'mixed';
  questionType?: 'open' | 'closed' | 'leading' | 'double_barreled' | 'follow_up' | 'none';
}

export interface CoachingEvent {
  id: string;
  sessionId: string;
  promptType: string;
  promptText: string;
  confidence?: number;
  culturalContext?: string;
  explanation?: string;
  displayedAt: string;
}

export interface PIIDetection {
  id: string;
  utteranceId: string;
  piiType: 'email' | 'phone' | 'ssn' | 'name' | 'company' | 'address' | 'credit_card';
  text: string;
  startIndex: number;
  endIndex: number;
}

export interface BiasAlert {
  id: string;
  biasType: string;
  severity: 'low' | 'medium' | 'high';
  message: string;
  suggestion: string;
}

export interface TopicUpdate {
  topicName: string;
  status: 'not_covered' | 'partial' | 'covered';
}

export interface TalkTimeRatio {
  interviewer: number;
  participant: number;
  status: 'good' | 'warning' | 'over_talking';
}

export interface Comment {
  id: string;
  authorId: string;
  authorName: string;
  text: string;
  timestamp: number;
  createdAt: string;
}

export interface SessionSummary {
  themes: string[];
  painPoints: string[];
  followUpQuestions: string[];
  emotionalArc: string;
  topicsCovered: string[];
  topicsMissed: string[];
  talkTimeRatio: TalkTimeRatio;
  questionDistribution: Record<string, number>;
}

// --- Client → Server Messages ---

export type ClientMessage =
  | { type: 'session.start'; sessionId: string; meetingUrl?: string; useLocalMic?: boolean }
  | { type: 'session.pause' }
  | { type: 'session.resume' }
  | { type: 'session.stop' }
  | { type: 'audio.chunk'; data: string }
  | { type: 'insight.flag'; timestamp: number; note?: string }
  | { type: 'coaching.respond'; eventId: string; response: 'accepted' | 'dismissed' | 'snoozed' }
  | { type: 'coaching.pull' }
  | { type: 'topic.update'; topicName: string; status: string }
  | { type: 'speaker.toggle' }
  | { type: 'observer.join'; sessionId: string }
  | { type: 'observer.comment'; text: string; timestamp: number }
  | { type: 'observer.question'; text: string }
  | { type: 'ping' };

// --- Server → Client Messages ---

export type ServerMessage =
  | { type: 'session.status'; status: string; sessionId: string }
  | { type: 'session.error'; code: string; message: string }
  | { type: 'transcript.utterance'; utterance: Utterance }
  | { type: 'transcript.update'; utteranceId: string; text: string }
  | { type: 'transcript.finalized'; utteranceId: string; utterance: Utterance }
  | { type: 'coaching.prompt'; event: CoachingEvent }
  | { type: 'coaching.dismiss'; eventId: string }
  | { type: 'coaching.queue'; events: CoachingEvent[] }
  | { type: 'analysis.talktime'; ratio: TalkTimeRatio }
  | { type: 'analysis.sentiment'; utteranceId: string; score: number; polarity: string }
  | { type: 'analysis.topic'; topic: TopicUpdate }
  | { type: 'analysis.pii'; utteranceId: string; detections: PIIDetection[] }
  | { type: 'analysis.bias'; alert: BiasAlert }
  | { type: 'analysis.questionType'; utteranceId: string; questionType: string }
  | { type: 'observer.comment'; comment: Comment }
  | { type: 'observer.question'; question: string; from: string }
  | { type: 'observer.count'; count: number }
  | { type: 'session.summary'; summary: SessionSummary }
  | { type: 'connection.quality'; latency: number; status: 'good' | 'degraded' | 'poor' }
  | { type: 'pong' }
  | { type: 'error'; code: string; message: string };

// --- Codec Utilities ---

export function encodeMessage(msg: ClientMessage | ServerMessage): string {
  return JSON.stringify(msg);
}

export function decodeClientMessage(data: string): ClientMessage {
  return JSON.parse(data) as ClientMessage;
}

export function decodeServerMessage(data: string): ServerMessage {
  return JSON.parse(data) as ServerMessage;
}

export function isClientMessage(msg: unknown): msg is ClientMessage {
  return typeof msg === 'object' && msg !== null && 'type' in msg;
}

export function isServerMessage(msg: unknown): msg is ServerMessage {
  return typeof msg === 'object' && msg !== null && 'type' in msg;
}
