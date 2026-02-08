import { pgTable, uuid, text, timestamp, jsonb } from 'drizzle-orm/pg-core';
import { sessions } from './sessions';
import { participants } from './participants';

export const consentRecords = pgTable('consent_records', {
  id: uuid('id').primaryKey().defaultRandom(),
  sessionId: uuid('session_id').notNull().references(() => sessions.id, { onDelete: 'cascade' }),
  participantId: uuid('participant_id').references(() => participants.id, { onDelete: 'set null' }),
  templateVersion: text('template_version').notNull(),
  status: text('status').notNull(),
  permissions: jsonb('permissions').notNull(),
  signatureName: text('signature_name'),
  obtainedAt: timestamp('obtained_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
});
