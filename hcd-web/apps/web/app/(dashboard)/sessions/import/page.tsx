'use client';

import { useCallback, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import {
  Upload,
  FileJson,
  Check,
  X,
  AlertTriangle,
  Loader2,
  ArrowLeft,
  FileText,
  MessageSquare,
  Flag,
  BookOpen,
} from 'lucide-react';
import Link from 'next/link';
import { Button, Card, CardContent, Badge } from '@hcd/ui';

// =============================================================================
// Import Sessions Page — Upload JSON exports from macOS app
// =============================================================================

interface ParsedSession {
  session: {
    title: string;
    sessionMode?: string;
    startedAt?: string;
    endedAt?: string;
    durationSeconds?: number;
  };
  utterances?: Array<{ speaker: string; text: string; startTime: number }>;
  insights?: Array<{ source: string; note?: string; timestamp: number }>;
  topics?: Array<{ topicName: string; status: string }>;
  coachingEvents?: Array<{ promptType: string; promptText: string }>;
}

type ImportStatus = 'idle' | 'parsing' | 'preview' | 'importing' | 'success' | 'error';

export default function ImportSessionsPage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [status, setStatus] = useState<ImportStatus>('idle');
  const [file, setFile] = useState<File | null>(null);
  const [parsedData, setParsedData] = useState<ParsedSession | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [importResult, setImportResult] = useState<{
    sessionId: string;
    title: string;
    imported: { utterances: number; insights: number; topics: number; coachingEvents: number };
  } | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);

  // Parse file
  const parseFile = useCallback(async (f: File) => {
    setFile(f);
    setStatus('parsing');
    setError(null);

    try {
      if (!f.name.endsWith('.json')) {
        throw new Error('Only JSON files are supported.');
      }

      const text = await f.text();
      const data: ParsedSession = JSON.parse(text);

      if (!data.session || !data.session.title) {
        throw new Error('Invalid export format: missing session.title');
      }

      setParsedData(data);
      setStatus('preview');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to parse file');
      setStatus('error');
    }
  }, []);

  // Handle file input change
  const handleFileChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const f = e.target.files?.[0];
      if (f) parseFile(f);
    },
    [parseFile]
  );

  // Handle drag & drop
  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault();
      setIsDragOver(false);
      const f = e.dataTransfer.files[0];
      if (f) parseFile(f);
    },
    [parseFile]
  );

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  }, []);

  const handleDragLeave = useCallback(() => {
    setIsDragOver(false);
  }, []);

  // Import data
  const handleImport = useCallback(async () => {
    if (!file) return;

    setStatus('importing');
    setError(null);

    try {
      const formData = new FormData();
      formData.append('file', file);

      const res = await fetch('/api/import', {
        method: 'POST',
        body: formData,
      });

      if (!res.ok) {
        const errData = await res.json().catch(() => null);
        throw new Error(errData?.error || `Import failed with status ${res.status}`);
      }

      const data = await res.json();
      setImportResult(data.data);
      setStatus('success');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Import failed');
      setStatus('error');
    }
  }, [file]);

  // Reset
  const handleReset = useCallback(() => {
    setStatus('idle');
    setFile(null);
    setParsedData(null);
    setError(null);
    setImportResult(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  }, []);

  return (
    <div className="max-w-2xl mx-auto">
      {/* Back link */}
      <Link
        href="/sessions"
        className="inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-foreground transition-colors w-fit mb-6"
        aria-label="Back to sessions"
      >
        <ArrowLeft className="h-4 w-4" aria-hidden="true" />
        Back to sessions
      </Link>

      <h1 className="text-2xl font-semibold tracking-tight mb-2">Import Session</h1>
      <p className="text-sm text-muted-foreground mb-6">
        Upload a JSON export from the HCD Interview Coach macOS app.
      </p>

      {/* Upload zone */}
      {(status === 'idle' || status === 'error') && (
        <Card>
          <CardContent className="p-0">
            <div
              onDrop={handleDrop}
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onClick={() => fileInputRef.current?.click()}
              className={`
                flex flex-col items-center justify-center py-16 px-6 cursor-pointer rounded-xl transition-colors
                ${isDragOver ? 'bg-primary/5 border-primary' : 'hover:bg-muted/50'}
              `}
              role="button"
              tabIndex={0}
              aria-label="Upload JSON file. Click or drag and drop."
              onKeyDown={(e) => {
                if (e.key === 'Enter' || e.key === ' ') {
                  e.preventDefault();
                  fileInputRef.current?.click();
                }
              }}
            >
              <div className={`rounded-full p-4 mb-4 ${isDragOver ? 'bg-primary/10' : 'bg-muted'}`}>
                <Upload className="h-8 w-8 text-muted-foreground" aria-hidden="true" />
              </div>
              <p className="text-sm font-medium">
                {isDragOver ? 'Drop file here' : 'Click to upload or drag & drop'}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                JSON files only (from macOS app export)
              </p>

              <input
                ref={fileInputRef}
                type="file"
                accept=".json,application/json"
                onChange={handleFileChange}
                className="hidden"
                aria-label="File input"
              />
            </div>

            {/* Error display */}
            {status === 'error' && error && (
              <div className="flex items-center gap-2 bg-destructive/10 text-destructive p-4 border-t">
                <AlertTriangle className="h-4 w-4 shrink-0" aria-hidden="true" />
                <p className="text-sm">{error}</p>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={(e) => {
                    e.stopPropagation();
                    handleReset();
                  }}
                  className="ml-auto"
                >
                  Try again
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Parsing indicator */}
      {status === 'parsing' && (
        <Card className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" aria-label="Parsing file" />
          <p className="text-sm text-muted-foreground ml-3">Parsing file...</p>
        </Card>
      )}

      {/* Preview */}
      {status === 'preview' && parsedData && (
        <Card>
          <CardContent className="p-6 space-y-4">
            <div className="flex items-center gap-3">
              <div className="rounded-lg bg-muted p-2">
                <FileJson className="h-5 w-5 text-muted-foreground" aria-hidden="true" />
              </div>
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium">{file?.name}</p>
                <p className="text-xs text-muted-foreground">
                  {((file?.size || 0) / 1024).toFixed(1)} KB
                </p>
              </div>
              <Button variant="ghost" size="icon" onClick={handleReset} aria-label="Remove file">
                <X className="h-4 w-4" />
              </Button>
            </div>

            <div className="rounded-lg border divide-y">
              <PreviewRow
                icon={FileText}
                label="Title"
                value={parsedData.session.title}
              />
              <PreviewRow
                icon={FileText}
                label="Mode"
                value={parsedData.session.sessionMode || 'interview'}
              />
              <PreviewRow
                icon={MessageSquare}
                label="Utterances"
                value={`${parsedData.utterances?.length || 0} entries`}
              />
              <PreviewRow
                icon={Flag}
                label="Insights"
                value={`${parsedData.insights?.length || 0} entries`}
              />
              <PreviewRow
                icon={BookOpen}
                label="Topics"
                value={`${parsedData.topics?.length || 0} entries`}
              />
              {parsedData.session.durationSeconds && (
                <PreviewRow
                  icon={FileText}
                  label="Duration"
                  value={`${Math.floor(parsedData.session.durationSeconds / 60)} minutes`}
                />
              )}
            </div>

            {/* Utterance preview */}
            {parsedData.utterances && parsedData.utterances.length > 0 && (
              <div>
                <p className="text-xs font-medium text-muted-foreground mb-2">Transcript Preview (first 5)</p>
                <div className="rounded-lg border divide-y max-h-40 overflow-y-auto">
                  {parsedData.utterances.slice(0, 5).map((u, i) => (
                    <div key={i} className="flex items-start gap-2 px-3 py-2 text-xs">
                      <Badge
                        variant={u.speaker === 'interviewer' ? 'interviewer' : 'participant'}
                        className="shrink-0 text-[10px]"
                      >
                        {u.speaker === 'interviewer' ? 'INT' : 'PAR'}
                      </Badge>
                      <span className="line-clamp-2">{u.text}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="flex items-center gap-2 pt-2">
              <Button onClick={handleImport} className="flex-1" aria-label="Confirm and import session">
                <Upload className="h-4 w-4 mr-2" aria-hidden="true" />
                Import Session
              </Button>
              <Button variant="outline" onClick={handleReset} aria-label="Cancel import">
                Cancel
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Importing */}
      {status === 'importing' && (
        <Card className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-primary" aria-label="Importing session" />
          <p className="text-sm text-muted-foreground ml-3">Importing session data...</p>
        </Card>
      )}

      {/* Success */}
      {status === 'success' && importResult && (
        <Card>
          <CardContent className="p-6 text-center space-y-4">
            <div className="rounded-full bg-green-100 dark:bg-green-900/30 p-4 w-fit mx-auto">
              <Check className="h-8 w-8 text-green-600 dark:text-green-400" aria-hidden="true" />
            </div>
            <div>
              <h2 className="text-lg font-semibold">Import Successful</h2>
              <p className="text-sm text-muted-foreground mt-1">
                &ldquo;{importResult.title}&rdquo; has been imported.
              </p>
            </div>

            <div className="flex items-center justify-center gap-4 text-sm text-muted-foreground">
              <span>{importResult.imported.utterances} utterances</span>
              <span>{importResult.imported.insights} insights</span>
              <span>{importResult.imported.topics} topics</span>
            </div>

            <div className="flex items-center gap-2 justify-center pt-2">
              <Button
                onClick={() => router.push(`/sessions/${importResult.sessionId}`)}
                aria-label="View imported session"
              >
                View Session
              </Button>
              <Button variant="outline" onClick={handleReset} aria-label="Import another session">
                Import Another
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// =============================================================================
// PreviewRow — Key-value display in preview
// =============================================================================

function PreviewRow({
  icon: Icon,
  label,
  value,
}: {
  icon: typeof FileText;
  label: string;
  value: string;
}) {
  return (
    <div className="flex items-center justify-between px-4 py-2.5 text-sm">
      <div className="flex items-center gap-2 text-muted-foreground">
        <Icon className="h-3.5 w-3.5" aria-hidden="true" />
        <span>{label}</span>
      </div>
      <span className="font-medium">{value}</span>
    </div>
  );
}
