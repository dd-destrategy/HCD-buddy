import { pgTable, uuid, text, timestamp } from 'drizzle-orm/pg-core';
import { sessions, utterances } from './sessions';
import { users } from './users';

export const redactions = pgTable('redactions', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  utteranceId: uuid('utterance_id').notNull().references(() => utterances.id, { onDelete: 'cascade' }),
  piiType: text('pii_type').notNull(),
  originalText: text('original_text').notNull(),
  replacement: text('replacement').default('[REDACTED]'),
  decision: text('decision').notNull().default('pending'),
  decidedBy: uuid('decided_by').references(() => users.id, { onDelete: 'set null' }),
  decidedAt: timestamp('decided_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
