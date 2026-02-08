// Glassmorphism tokens ported from Swift LiquidGlass.swift

export const glass = {
  ultraThin: {
    background: 'rgba(255, 255, 255, 0.05)',
    backdropFilter: 'blur(4px)',
    border: '1px solid rgba(255, 255, 255, 0.08)',
  },
  thin: {
    background: 'rgba(255, 255, 255, 0.1)',
    backdropFilter: 'blur(8px)',
    border: '1px solid rgba(255, 255, 255, 0.12)',
  },
  regular: {
    background: 'rgba(255, 255, 255, 0.15)',
    backdropFilter: 'blur(12px)',
    border: '1px solid rgba(255, 255, 255, 0.2)',
  },
  thick: {
    background: 'rgba(255, 255, 255, 0.25)',
    backdropFilter: 'blur(16px)',
    border: '1px solid rgba(255, 255, 255, 0.25)',
  },
  ultraThick: {
    background: 'rgba(255, 255, 255, 0.35)',
    backdropFilter: 'blur(24px)',
    border: '1px solid rgba(255, 255, 255, 0.3)',
  },
} as const;

// Tailwind class equivalents
export const glassClasses = {
  panel: 'backdrop-blur-lg bg-white/5 border border-white/10 dark:bg-black/20',
  card: 'backdrop-blur-sm bg-white/15 border border-white/20 rounded-xl dark:bg-black/30',
  button: 'backdrop-blur-md bg-white/20 hover:bg-white/30 rounded-lg dark:bg-black/20 dark:hover:bg-black/30',
  toolbar: 'backdrop-blur-xl bg-white/30 border-b border-white/20 dark:bg-black/40',
  overlay: 'backdrop-blur-2xl bg-black/40',
} as const;
