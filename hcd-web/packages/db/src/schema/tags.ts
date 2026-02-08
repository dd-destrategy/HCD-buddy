import { pgTable, uuid, text } from 'drizzle-orm/pg-core';
import { organizations } from './users';
import { utterances } from './sessions';

export const tags = pgTable('tags', {
  id: uuid('id').primaryKey().defaultRandom(),
  organizationId: uuid('organization_id').references(() => organizations.id, { onDelete: 'cascade' }),
  name: text('name').notNull(),
  color: text('color'),
  parentId: uuid('parent_id').references((): any => tags.id, { onDelete: 'set null' }),
});

export const utteranceTags = pgTable('utterance_tags', {
  id: uuid('id').primaryKey().defaultRandom(),
  utteranceId: uuid('utterance_id').notNull().references(() => utterances.id, { onDelete: 'cascade' }),
  tagId: uuid('tag_id').notNull().references(() => tags.id, { onDelete: 'cascade' }),
});
