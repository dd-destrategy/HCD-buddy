// Spacing tokens ported from Swift Spacing.swift

export const spacing = {
  xxs: '0.125rem',  // 2px
  xs: '0.25rem',    // 4px
  sm: '0.5rem',     // 8px
  md: '0.75rem',    // 12px
  lg: '1rem',       // 16px
  xl: '1.5rem',     // 24px
  xxl: '2.5rem',    // 40px
} as const;

export const cornerRadius = {
  small: '0.25rem',   // 4px
  medium: '0.5rem',   // 8px
  large: '0.75rem',   // 12px
  xl: '1rem',         // 16px
  pill: '9999px',
} as const;

// Touch target minimum (44px for WCAG)
export const touchTarget = '2.75rem';
