import { pgTable, uuid, text, timestamp, boolean } from 'drizzle-orm/pg-core';
import { sessions, utterances } from './sessions';
import { users } from './users';

export const highlights = pgTable('highlights', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  utteranceId: uuid('utterance_id').references(() => utterances.id, { onDelete: 'set null' }),
  ownerId: uuid('owner_id').references(() => users.id),
  title: text('title').notNull(),
  category: text('category').notNull(),
  textSelection: text('text_selection').notNull(),
  notes: text('notes'),
  isStarred: boolean('is_starred').default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
