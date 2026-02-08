import { pgTable, uuid, text, timestamp, jsonb } from 'drizzle-orm/pg-core';
import { organizations } from './users';

export const participants = pgTable('participants', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id').references(() => organizations.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  email: text('email'),
  role: text('role'),
  department: text('department'),
  experienceLevel: text('experience_level'),
  metadata: jsonb('metadata').default({}),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});
