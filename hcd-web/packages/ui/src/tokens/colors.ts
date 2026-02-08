// Design tokens ported from Swift Colors.swift
// Used as CSS custom properties via Tailwind

export const colors = {
  // Primary brand
  primary: '222 47% 31%',
  primaryForeground: '0 0% 100%',

  // Backgrounds
  background: '0 0% 100%',
  foreground: '222 47% 11%',

  // Cards
  card: '0 0% 100%',
  cardForeground: '222 47% 11%',

  // Secondary
  secondary: '210 40% 96%',
  secondaryForeground: '222 47% 11%',

  // Muted
  muted: '210 40% 96%',
  mutedForeground: '215 16% 47%',

  // Accent
  accent: '210 40% 96%',
  accentForeground: '222 47% 11%',

  // Destructive
  destructive: '0 84% 60%',
  destructiveForeground: '0 0% 100%',

  // Borders
  border: '214 32% 91%',
  input: '214 32% 91%',
  ring: '222 47% 31%',

  // Semantic colors (from hcdSuccess, hcdError, etc.)
  success: '142 71% 45%',
  warning: '38 92% 50%',
  info: '217 91% 60%',

  // Sentiment colors
  sentimentPositive: '142 71% 45%',
  sentimentNegative: '0 84% 60%',
  sentimentNeutral: '215 16% 47%',
  sentimentMixed: '38 92% 50%',

  // Speaker colors
  speakerInterviewer: '217 91% 60%',
  speakerParticipant: '142 71% 45%',

  // Coaching
  coachingPrompt: '262 83% 58%',
  coachingBackground: '262 83% 97%',
} as const;

export const darkColors = {
  background: '222 47% 11%',
  foreground: '210 40% 98%',
  card: '222 47% 15%',
  cardForeground: '210 40% 98%',
  secondary: '217 33% 17%',
  secondaryForeground: '210 40% 98%',
  muted: '217 33% 17%',
  mutedForeground: '215 20% 65%',
  accent: '217 33% 17%',
  accentForeground: '210 40% 98%',
  border: '217 33% 17%',
  input: '217 33% 17%',
} as const;
