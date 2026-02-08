import { pgTable, uuid, text, timestamp, real } from 'drizzle-orm/pg-core';
import { sessions, utterances } from './sessions';
import { users } from './users';

export const comments = pgTable('comments', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  utteranceId: uuid('utterance_id').references(() => utterances.id, { onDelete: 'set null' }),
  authorId: uuid('author_id').notNull().references(() => users.id),
  text: text('text').notNull(),
  timestamp: real('timestamp'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});
