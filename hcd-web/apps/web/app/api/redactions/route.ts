import { NextRequest, NextResponse } from 'next/server';
import { db } from '@hcd/db';
import { redactions, utterances } from '@hcd/db';
import { eq, and, sql } from 'drizzle-orm';
import { requireAuth, isAuthError } from '@/lib/auth-middleware';

// ─── PII Detection Patterns ────────────────────────────────────────────────
// Local PII detection (fallback when @hcd/engine PIIDetector is not available)

const PII_PATTERNS: Array<{ type: string; pattern: RegExp; label: string }> = [
  { type: 'email', pattern: /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g, label: 'Email Address' },
  { type: 'phone', pattern: /(?:\+?1[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}/g, label: 'Phone Number' },
  { type: 'ssn', pattern: /\b\d{3}[-]?\d{2}[-]?\d{4}\b/g, label: 'SSN' },
  { type: 'credit_card', pattern: /\b(?:\d{4}[-\s]?){3}\d{4}\b/g, label: 'Credit Card' },
  { type: 'ip_address', pattern: /\b(?:\d{1,3}\.){3}\d{1,3}\b/g, label: 'IP Address' },
  { type: 'date_of_birth', pattern: /\b(?:0[1-9]|1[0-2])[\/\-](?:0[1-9]|[12]\d|3[01])[\/\-](?:19|20)\d{2}\b/g, label: 'Date of Birth' },
  { type: 'address', pattern: /\b\d{1,5}\s+[\w\s]+(?:Street|St|Avenue|Ave|Boulevard|Blvd|Drive|Dr|Lane|Ln|Road|Rd|Court|Ct|Way|Place|Pl)\b/gi, label: 'Street Address' },
  { type: 'name', pattern: /\b(?:my name is|I'm|I am|called)\s+([A-Z][a-z]+(?:\s+[A-Z][a-z]+)?)\b/g, label: 'Person Name' },
  { type: 'zip_code', pattern: /\b\d{5}(?:-\d{4})?\b/g, label: 'ZIP Code' },
];

function detectPII(text: string): Array<{ type: string; label: string; originalText: string; startIndex: number; endIndex: number }> {
  const detections: Array<{ type: string; label: string; originalText: string; startIndex: number; endIndex: number }> = [];

  for (const { type, pattern, label } of PII_PATTERNS) {
    const regex = new RegExp(pattern.source, pattern.flags);
    let match;
    while ((match = regex.exec(text)) !== null) {
      detections.push({
        type,
        label,
        originalText: match[0],
        startIndex: match.index,
        endIndex: match.index + match[0].length,
      });
    }
  }

  return detections;
}

// ─── GET /api/redactions ────────────────────────────────────────────────────
// List redactions for a session
export async function GET(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const { searchParams } = new URL(request.url);
    const sessionId = searchParams.get('sessionId');

    if (!sessionId) {
      return NextResponse.json(
        { error: 'sessionId is required' },
        { status: 400 }
      );
    }

    const results = await db
      .select({
        id: redactions.id,
        sessionId: redactions.sessionId,
        utteranceId: redactions.utteranceId,
        piiType: redactions.piiType,
        originalText: redactions.originalText,
        replacement: redactions.replacement,
        decision: redactions.decision,
        decidedBy: redactions.decidedBy,
        decidedAt: redactions.decidedAt,
        utteranceText: utterances.text,
        speaker: utterances.speaker,
        startTime: utterances.startTime,
      })
      .from(redactions)
      .leftJoin(utterances, eq(redactions.utteranceId, utterances.id))
      .where(eq(redactions.sessionId, sessionId));

    // Group by utterance
    const grouped: Record<string, { utterance: any; detections: any[] }> = {};
    for (const row of results) {
      const uid = row.utteranceId;
      if (!grouped[uid]) {
        grouped[uid] = {
          utterance: {
            id: uid,
            text: row.utteranceText,
            speaker: row.speaker,
            startTime: row.startTime,
          },
          detections: [],
        };
      }
      // Mask originalText for redacted detections — only show actual text for pending/keep
      const maskedOriginalText = row.decision === 'redact'
        ? '[REDACTED]'
        : row.originalText;
      grouped[uid].detections.push({
        id: row.id,
        piiType: row.piiType,
        originalText: maskedOriginalText,
        replacement: row.replacement,
        decision: row.decision,
        decidedBy: row.decidedBy,
        decidedAt: row.decidedAt,
      });
    }

    // Summary counts by PII type
    const summary: Record<string, { total: number; reviewed: number }> = {};
    for (const row of results) {
      if (!summary[row.piiType]) {
        summary[row.piiType] = { total: 0, reviewed: 0 };
      }
      summary[row.piiType].total++;
      if (row.decision !== 'pending') {
        summary[row.piiType].reviewed++;
      }
    }

    return NextResponse.json({
      redactions: Object.values(grouped),
      summary,
      total: results.length,
      reviewed: results.filter((r) => r.decision !== 'pending').length,
    });
  } catch (error) {
    console.error('Failed to fetch redactions:', error);
    return NextResponse.json(
      { error: 'Failed to fetch redactions' },
      { status: 500 }
    );
  }
}

// ─── POST /api/redactions ───────────────────────────────────────────────────
// Create redaction decisions (batch) or run PII scan
export async function POST(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const body = await request.json();

    // PII Scan mode
    if (body.action === 'scan') {
      const { sessionId } = body;

      if (!sessionId) {
        return NextResponse.json(
          { error: 'sessionId is required for scan' },
          { status: 400 }
        );
      }

      // Fetch all utterances for the session
      const sessionUtterances = await db
        .select()
        .from(utterances)
        .where(eq(utterances.sessionId, sessionId));

      const allDetections: Array<{
        sessionId: string;
        utteranceId: string;
        piiType: string;
        originalText: string;
      }> = [];

      for (const utt of sessionUtterances) {
        const detections = detectPII(utt.text);
        for (const detection of detections) {
          allDetections.push({
            sessionId,
            utteranceId: utt.id,
            piiType: detection.type,
            originalText: detection.originalText,
          });
        }
      }

      // Insert detections as pending redactions (skip duplicates)
      if (allDetections.length > 0) {
        // Check for existing redactions to avoid duplicates
        const existing = await db
          .select()
          .from(redactions)
          .where(eq(redactions.sessionId, sessionId));

        const existingSet = new Set(
          existing.map((r) => `${r.utteranceId}:${r.originalText}`)
        );

        const newDetections = allDetections.filter(
          (d) => !existingSet.has(`${d.utteranceId}:${d.originalText}`)
        );

        if (newDetections.length > 0) {
          await db.insert(redactions).values(
            newDetections.map((d) => ({
              sessionId: d.sessionId,
              utteranceId: d.utteranceId,
              piiType: d.piiType,
              originalText: d.originalText,
              replacement: '[REDACTED]',
              decision: 'pending',
            }))
          );
        }
      }

      return NextResponse.json({
        scanned: sessionUtterances.length,
        detected: allDetections.length,
        message: `Scanned ${sessionUtterances.length} utterances, found ${allDetections.length} PII instances`,
      });
    }

    // Batch create/update decisions mode
    const { decisions } = body;

    if (!Array.isArray(decisions) || decisions.length === 0) {
      return NextResponse.json(
        { error: 'decisions array is required' },
        { status: 400 }
      );
    }

    const results = [];
    for (const decision of decisions) {
      const { id, action: decisionAction, replacement, decidedBy } = decision;

      if (!id || !decisionAction) continue;

      const validActions = ['redact', 'keep', 'replace'];
      if (!validActions.includes(decisionAction)) continue;

      const updateData: Record<string, any> = {
        decision: decisionAction,
        decidedAt: new Date(),
      };

      if (decidedBy) updateData.decidedBy = decidedBy;
      if (decisionAction === 'replace' && replacement) {
        updateData.replacement = replacement;
      } else if (decisionAction === 'redact') {
        updateData.replacement = '[REDACTED]';
      } else if (decisionAction === 'keep') {
        updateData.replacement = null;
      }

      const [updated] = await db
        .update(redactions)
        .set(updateData)
        .where(eq(redactions.id, id))
        .returning();

      if (updated) results.push(updated);
    }

    return NextResponse.json({ updated: results.length, redactions: results });
  } catch (error) {
    console.error('Failed to process redactions:', error);
    return NextResponse.json(
      { error: 'Failed to process redactions' },
      { status: 500 }
    );
  }
}

// ─── PATCH /api/redactions ──────────────────────────────────────────────────
// Update a single redaction decision
export async function PATCH(request: NextRequest) {
  try {
    const authResult = await requireAuth(request);
    if (isAuthError(authResult)) return authResult;
    const { user } = authResult;

    const body = await request.json();
    const { id, decision, replacement, decidedBy } = body;

    if (!id || !decision) {
      return NextResponse.json(
        { error: 'id and decision are required' },
        { status: 400 }
      );
    }

    const validDecisions = ['pending', 'redact', 'keep', 'replace'];
    if (!validDecisions.includes(decision)) {
      return NextResponse.json(
        { error: `Invalid decision. Must be one of: ${validDecisions.join(', ')}` },
        { status: 400 }
      );
    }

    const updateData: Record<string, any> = {
      decision,
      decidedAt: decision === 'pending' ? null : new Date(),
    };

    if (decidedBy) updateData.decidedBy = decidedBy;
    if (replacement !== undefined) updateData.replacement = replacement;

    const [updated] = await db
      .update(redactions)
      .set(updateData)
      .where(eq(redactions.id, id))
      .returning();

    if (!updated) {
      return NextResponse.json(
        { error: 'Redaction not found' },
        { status: 404 }
      );
    }

    return NextResponse.json({ redaction: updated });
  } catch (error) {
    console.error('Failed to update redaction:', error);
    return NextResponse.json(
      { error: 'Failed to update redaction' },
      { status: 500 }
    );
  }
}
