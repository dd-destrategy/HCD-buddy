import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as users from './schema/users';
import * as authTables from './schema/auth';
import * as sessions from './schema/sessions';
import * as studies from './schema/studies';
import * as participants from './schema/participants';
import * as highlights from './schema/highlights';
import * as tags from './schema/tags';
import * as redactions from './schema/redactions';
import * as consent from './schema/consent';
import * as comments from './schema/comments';
import * as templates from './schema/templates';
import * as preferences from './schema/preferences';

const schema = {
  ...users,
  ...authTables,
  ...sessions,
  ...studies,
  ...participants,
  ...highlights,
  ...tags,
  ...redactions,
  ...consent,
  ...comments,
  ...templates,
  ...preferences,
};

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL environment variable is required');
}

const client = postgres(connectionString, {
  max: 20,
  idle_timeout: 20,
  connect_timeout: 10,
});

export const db = drizzle(client, { schema });
export type Database = typeof db;
