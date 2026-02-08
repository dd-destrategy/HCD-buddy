import { betterAuth } from 'better-auth';
import { drizzleAdapter } from 'better-auth/adapters/drizzle';
import { organization } from 'better-auth/plugins';
import { db } from '@hcd/db';
import {
  users,
  authSessions,
  accounts,
  verifications,
  organizations,
  organizationMembers,
  invitations,
} from '@hcd/db';

export const auth = betterAuth({
  database: drizzleAdapter(db, {
    provider: 'pg',
    schema: {
      user: users,
      session: authSessions,
      account: accounts,
      verification: verifications,
      organization: organizations,
      member: organizationMembers,
      invitation: invitations,
    },
  }),
  emailAndPassword: {
    enabled: true,
    minPasswordLength: 8,
  },
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID || '',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
    },
  },
  plugins: [
    organization({
      allowUserToCreateOrganization: true,
    }),
  ],
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 days
    updateAge: 60 * 60 * 24,      // 1 day
  },
});

export type Auth = typeof auth;
export type Session = typeof auth.$Infer.Session;
