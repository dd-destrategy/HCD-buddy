import { pgTable, uuid, text, timestamp, boolean, jsonb } from 'drizzle-orm/pg-core';
import { organizations, users } from './users';

export const templates = pgTable('templates', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id').references(() => organizations.id, { onDelete: 'cascade' }),
  ownerId: uuid('owner_id').references(() => users.id),
  name: text('name').notNull(),
  description: text('description'),
  topics: text('topics').array().default([]),
  coachingPrompts: jsonb('coaching_prompts').default([]),
  isShared: boolean('is_shared').default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});
