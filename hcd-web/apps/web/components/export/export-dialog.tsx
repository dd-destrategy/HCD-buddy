'use client';

import { useCallback, useEffect, useState } from 'react';
import {
  FileText,
  FileJson,
  Table,
  Download,
  Copy,
  Check,
  X,
  Eye,
  Loader2,
} from 'lucide-react';
import { Button, Card, Badge } from '@hcd/ui';

// =============================================================================
// ExportDialog — Format selection, options, preview, and download
// =============================================================================

export type ExportFormat = 'markdown' | 'json' | 'csv';

interface ExportDialogProps {
  /** Session ID to export */
  sessionId: string;
  /** Session title for display */
  sessionTitle: string;
  /** Whether the dialog is open */
  isOpen: boolean;
  /** Called to close the dialog */
  onClose: () => void;
  /** Additional CSS classes */
  className?: string;
}

interface ExportOptions {
  format: ExportFormat;
  includeInsights: boolean;
  includeHighlights: boolean;
  applyRedactions: boolean;
  includeTimestamps: boolean;
}

const FORMAT_OPTIONS: Array<{
  id: ExportFormat;
  label: string;
  description: string;
  icon: typeof FileText;
  mime: string;
}> = [
  {
    id: 'markdown',
    label: 'Markdown',
    description: 'Formatted document with headers and structure',
    icon: FileText,
    mime: 'text/markdown',
  },
  {
    id: 'json',
    label: 'JSON',
    description: 'Structured data for programmatic use',
    icon: FileJson,
    mime: 'application/json',
  },
  {
    id: 'csv',
    label: 'CSV',
    description: 'Spreadsheet-compatible transcript data',
    icon: Table,
    mime: 'text/csv',
  },
];

export function ExportDialog({
  sessionId,
  sessionTitle,
  isOpen,
  onClose,
  className = '',
}: ExportDialogProps) {
  const [options, setOptions] = useState<ExportOptions>({
    format: 'markdown',
    includeInsights: true,
    includeHighlights: true,
    applyRedactions: false,
    includeTimestamps: true,
  });

  const [preview, setPreview] = useState<string>('');
  const [isLoadingPreview, setIsLoadingPreview] = useState(false);
  const [isDownloading, setIsDownloading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [showPreview, setShowPreview] = useState(false);

  // Build query string from options
  const buildQueryString = useCallback(
    (opts: ExportOptions): string => {
      const params = new URLSearchParams({
        format: opts.format,
        includeInsights: opts.includeInsights.toString(),
        includeHighlights: opts.includeHighlights.toString(),
        applyRedactions: opts.applyRedactions.toString(),
        includeTimestamps: opts.includeTimestamps.toString(),
      });
      return params.toString();
    },
    []
  );

  // Fetch preview
  const fetchPreview = useCallback(async () => {
    setIsLoadingPreview(true);
    try {
      const qs = buildQueryString(options);
      const res = await fetch(`/api/export/${sessionId}?${qs}`);
      if (!res.ok) throw new Error('Failed to fetch export');
      const text = await res.text();
      // Show first 20 lines
      const lines = text.split('\n').slice(0, 20);
      setPreview(lines.join('\n') + (text.split('\n').length > 20 ? '\n...' : ''));
    } catch (err) {
      setPreview('Failed to load preview.');
    } finally {
      setIsLoadingPreview(false);
    }
  }, [sessionId, options, buildQueryString]);

  // Load preview when toggled or options change
  useEffect(() => {
    if (showPreview) {
      fetchPreview();
    }
  }, [showPreview, options.format, fetchPreview]);

  // Download handler
  const handleDownload = useCallback(async () => {
    setIsDownloading(true);
    try {
      const qs = buildQueryString(options);
      const res = await fetch(`/api/export/${sessionId}?${qs}`);
      if (!res.ok) throw new Error('Export failed');

      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');

      const ext = options.format === 'markdown' ? 'md' : options.format;
      a.href = url;
      a.download = `${slugify(sessionTitle)}-export.${ext}`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err) {
      console.error('Export download failed:', err);
    } finally {
      setIsDownloading(false);
    }
  }, [sessionId, sessionTitle, options, buildQueryString]);

  // Copy to clipboard
  const handleCopy = useCallback(async () => {
    try {
      const qs = buildQueryString(options);
      const res = await fetch(`/api/export/${sessionId}?${qs}`);
      if (!res.ok) throw new Error('Export failed');
      const text = await res.text();
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Copy failed:', err);
    }
  }, [sessionId, options, buildQueryString]);

  // Close on Escape
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    }
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center"
      role="dialog"
      aria-modal="true"
      aria-label="Export session"
    >
      {/* Backdrop */}
      <div
        className="absolute inset-0 glass-overlay"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Dialog content */}
      <Card className={`relative z-10 w-full max-w-lg mx-4 max-h-[85vh] overflow-y-auto ${className}`}>
        {/* Header */}
        <div className="flex items-center justify-between p-6 pb-4">
          <div>
            <h2 className="text-lg font-semibold">Export Session</h2>
            <p className="text-sm text-muted-foreground mt-0.5 truncate max-w-xs">
              {sessionTitle}
            </p>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-muted text-muted-foreground hover:text-foreground"
            aria-label="Close dialog"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        <div className="px-6 pb-6 space-y-5">
          {/* Format selection */}
          <div>
            <label className="text-sm font-medium mb-2 block">Format</label>
            <div className="grid grid-cols-3 gap-2">
              {FORMAT_OPTIONS.map((fmt) => {
                const Icon = fmt.icon;
                const isActive = options.format === fmt.id;

                return (
                  <button
                    key={fmt.id}
                    type="button"
                    onClick={() => setOptions((prev) => ({ ...prev, format: fmt.id }))}
                    className={`
                      flex flex-col items-center gap-1.5 rounded-lg border p-3 text-center transition-colors
                      ${isActive
                        ? 'border-primary bg-primary/5 text-primary'
                        : 'border-border hover:border-primary/40 hover:bg-muted/50'
                      }
                    `}
                    aria-pressed={isActive}
                    aria-label={`${fmt.label}: ${fmt.description}`}
                  >
                    <Icon className="h-5 w-5" aria-hidden="true" />
                    <span className="text-sm font-medium">{fmt.label}</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* Options */}
          <div>
            <label className="text-sm font-medium mb-2 block">Options</label>
            <div className="space-y-2">
              <ToggleOption
                label="Include timestamps"
                checked={options.includeTimestamps}
                onChange={(v) => setOptions((prev) => ({ ...prev, includeTimestamps: v }))}
              />
              <ToggleOption
                label="Include insights"
                checked={options.includeInsights}
                onChange={(v) => setOptions((prev) => ({ ...prev, includeInsights: v }))}
                disabled={options.format === 'csv'}
              />
              <ToggleOption
                label="Include highlights"
                checked={options.includeHighlights}
                onChange={(v) => setOptions((prev) => ({ ...prev, includeHighlights: v }))}
                disabled={options.format === 'csv'}
              />
              <ToggleOption
                label="Apply PII redactions"
                checked={options.applyRedactions}
                onChange={(v) => setOptions((prev) => ({ ...prev, applyRedactions: v }))}
              />
            </div>
          </div>

          {/* Preview toggle */}
          <div>
            <button
              type="button"
              onClick={() => setShowPreview((prev) => !prev)}
              className="flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors"
              aria-expanded={showPreview}
              aria-controls="export-preview"
            >
              <Eye className="h-4 w-4" aria-hidden="true" />
              {showPreview ? 'Hide preview' : 'Show preview (first 20 lines)'}
            </button>

            {showPreview && (
              <div
                id="export-preview"
                className="mt-2 rounded-lg border bg-muted/50 p-3 max-h-48 overflow-y-auto"
              >
                {isLoadingPreview ? (
                  <div className="flex items-center gap-2 text-sm text-muted-foreground">
                    <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                    Loading preview...
                  </div>
                ) : (
                  <pre className="text-xs font-mono whitespace-pre-wrap break-words">
                    {preview}
                  </pre>
                )}
              </div>
            )}
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-2 pt-2">
            <Button
              onClick={handleDownload}
              disabled={isDownloading}
              className="flex-1"
              aria-label="Download export file"
            >
              {isDownloading ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" aria-hidden="true" />
              ) : (
                <Download className="h-4 w-4 mr-2" aria-hidden="true" />
              )}
              Download
            </Button>
            <Button
              variant="outline"
              onClick={handleCopy}
              aria-label="Copy export to clipboard"
            >
              {copied ? (
                <Check className="h-4 w-4 mr-2 text-green-500" aria-hidden="true" />
              ) : (
                <Copy className="h-4 w-4 mr-2" aria-hidden="true" />
              )}
              {copied ? 'Copied' : 'Copy'}
            </Button>
          </div>
        </div>
      </Card>
    </div>
  );
}

// =============================================================================
// ToggleOption — Checkbox option row
// =============================================================================

function ToggleOption({
  label,
  checked,
  onChange,
  disabled = false,
}: {
  label: string;
  checked: boolean;
  onChange: (value: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <label
      className={`flex items-center gap-2 py-1 ${disabled ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
    >
      <input
        type="checkbox"
        checked={checked}
        onChange={(e) => onChange(e.target.checked)}
        disabled={disabled}
        className="rounded border-input h-4 w-4 text-primary focus:ring-ring"
        aria-label={label}
      />
      <span className="text-sm">{label}</span>
    </label>
  );
}

// =============================================================================
// Helpers
// =============================================================================

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}
