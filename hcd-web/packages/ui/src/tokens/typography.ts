// Typography tokens ported from Swift Typography.swift

export const typography = {
  display: {
    fontSize: '2.25rem',   // 36px
    lineHeight: '2.5rem',
    fontWeight: '700',
    letterSpacing: '-0.025em',
  },
  heading1: {
    fontSize: '1.5rem',    // 24px
    lineHeight: '2rem',
    fontWeight: '600',
    letterSpacing: '-0.02em',
  },
  heading2: {
    fontSize: '1.25rem',   // 20px
    lineHeight: '1.75rem',
    fontWeight: '600',
    letterSpacing: '-0.01em',
  },
  heading3: {
    fontSize: '1.125rem',  // 18px
    lineHeight: '1.75rem',
    fontWeight: '600',
  },
  body: {
    fontSize: '1rem',      // 16px
    lineHeight: '1.5rem',
    fontWeight: '400',
  },
  bodyMedium: {
    fontSize: '1rem',
    lineHeight: '1.5rem',
    fontWeight: '500',
  },
  caption: {
    fontSize: '0.875rem',  // 14px
    lineHeight: '1.25rem',
    fontWeight: '400',
  },
  small: {
    fontSize: '0.75rem',   // 12px
    lineHeight: '1rem',
    fontWeight: '400',
  },
} as const;

// Tailwind class equivalents
export const typographyClasses = {
  display: 'text-4xl font-bold tracking-tight',
  heading1: 'text-2xl font-semibold tracking-tight',
  heading2: 'text-xl font-semibold',
  heading3: 'text-lg font-semibold',
  body: 'text-base',
  bodyMedium: 'text-base font-medium',
  caption: 'text-sm',
  small: 'text-xs',
} as const;
