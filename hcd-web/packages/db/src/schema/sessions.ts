import { pgTable, uuid, text, timestamp, integer, boolean, jsonb, real } from 'drizzle-orm/pg-core';
import { users } from './users';
import { studies } from './studies';
import { participants } from './participants';
import { templates } from './templates';

export const sessions = pgTable('sessions', {
  id: uuid('id').primaryKey().defaultRandom(),
  studyId: uuid('study_id').references(() => studies.id, { onDelete: 'set null' }),
  ownerId: uuid('owner_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull(),
  sessionMode: text('session_mode').notNull().default('interview'),
  status: text('status').notNull().default('draft'),
  startedAt: timestamp('started_at', { withTimezone: true }),
  endedAt: timestamp('ended_at', { withTimezone: true }),
  durationSeconds: integer('duration_seconds'),
  templateId: uuid('template_id').references(() => templates.id, { onDelete: 'set null' }),
  participantId: uuid('participant_id').references(() => participants.id, { onDelete: 'set null' }),
  consentStatus: text('consent_status').default('not_obtained'),
  coachingEnabled: boolean('coaching_enabled').default(false),
  meetingUrl: text('meeting_url'),
  metadata: jsonb('metadata').default({}),
  summary: jsonb('summary'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const utterances = pgTable('utterances', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  speaker: text('speaker').notNull(),
  text: text('text').notNull(),
  startTime: real('start_time').notNull(),
  endTime: real('end_time'),
  confidence: real('confidence'),
  sentimentScore: real('sentiment_score'),
  sentimentPolarity: text('sentiment_polarity'),
  questionType: text('question_type'),
  isRedacted: boolean('is_redacted').default(false),
  redactedText: text('redacted_text'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const insights = pgTable('insights', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  utteranceId: uuid('utterance_id').references(() => utterances.id, { onDelete: 'set null' }),
  source: text('source').notNull(),
  note: text('note'),
  timestamp: real('timestamp').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});

export const topicStatuses = pgTable('topic_statuses', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  topicName: text('topic_name').notNull(),
  status: text('status').notNull().default('not_covered'),
  coveredAt: timestamp('covered_at', { withTimezone: true }),
});

export const coachingEvents = pgTable('coaching_events', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  promptType: text('prompt_type').notNull(),
  promptText: text('prompt_text').notNull(),
  confidence: real('confidence'),
  response: text('response'),
  displayedAt: timestamp('displayed_at', { withTimezone: true }).notNull(),
  respondedAt: timestamp('responded_at', { withTimezone: true }),
  culturalContext: text('cultural_context'),
});
