import { pgTable, uuid, text, timestamp, boolean, jsonb } from 'drizzle-orm/pg-core';
import { users } from './users';

export const userPreferences = pgTable('user_preferences', {
  userId: uuid('user_id').primaryKey().references(() => users.id, { onDelete: 'cascade' }),
  coachingEnabled: boolean('coaching_enabled').default(false),
  autoDismissPreset: text('auto_dismiss_preset').default('standard'),
  coachingDeliveryMode: text('coaching_delivery_mode').default('realtime'),
  culturalPreset: text('cultural_preset').default('western'),
  culturalContext: jsonb('cultural_context').default({}),
  focusMode: text('focus_mode').default('coached'),
  theme: text('theme').default('system'),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});
