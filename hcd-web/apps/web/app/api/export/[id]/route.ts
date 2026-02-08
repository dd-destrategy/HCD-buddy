import { NextRequest, NextResponse } from 'next/server';
import {
  db,
  sessions,
  utterances,
  insights,
  topicStatuses,
  coachingEvents,
  highlights,
  redactions,
  participants,
  studies,
} from '@hcd/db';
import { eq } from 'drizzle-orm';

// =============================================================================
// GET /api/export/[id] — Export session in Markdown, JSON, or CSV
// =============================================================================

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const { searchParams } = new URL(request.url);

    const format = searchParams.get('format') || 'markdown';
    const includeInsights = searchParams.get('includeInsights') !== 'false';
    const includeHighlights = searchParams.get('includeHighlights') !== 'false';
    const applyRedactions = searchParams.get('applyRedactions') === 'true';
    const includeTimestamps = searchParams.get('includeTimestamps') !== 'false';

    // Fetch session data
    const sessionRows = await db
      .select({
        id: sessions.id,
        title: sessions.title,
        sessionMode: sessions.sessionMode,
        status: sessions.status,
        startedAt: sessions.startedAt,
        endedAt: sessions.endedAt,
        durationSeconds: sessions.durationSeconds,
        participantName: participants.name,
        studyTitle: studies.title,
        summary: sessions.summary,
        coachingEnabled: sessions.coachingEnabled,
      })
      .from(sessions)
      .leftJoin(participants, eq(sessions.participantId, participants.id))
      .leftJoin(studies, eq(sessions.studyId, studies.id))
      .where(eq(sessions.id, id))
      .limit(1);

    if (sessionRows.length === 0) {
      return NextResponse.json({ error: 'Session not found' }, { status: 404 });
    }

    const session = sessionRows[0];

    // Fetch related data in parallel
    const [utteranceRows, insightRows, topicRows, highlightRows, redactionRows] =
      await Promise.all([
        db
          .select()
          .from(utterances)
          .where(eq(utterances.sessionId, id))
          .orderBy(utterances.startTime),
        includeInsights
          ? db
              .select()
              .from(insights)
              .where(eq(insights.sessionId, id))
              .orderBy(insights.timestamp)
          : Promise.resolve([]),
        db.select().from(topicStatuses).where(eq(topicStatuses.sessionId, id)),
        includeHighlights
          ? db
              .select()
              .from(highlights)
              .where(eq(highlights.sessionId, id))
              .orderBy(highlights.createdAt)
          : Promise.resolve([]),
        applyRedactions
          ? db
              .select()
              .from(redactions)
              .where(eq(redactions.sessionId, id))
          : Promise.resolve([]),
      ]);

    // Build a redaction map: utteranceId -> list of redactions
    const redactionMap = new Map<string, Array<{ originalText: string; replacement: string }>>();
    if (applyRedactions) {
      for (const r of redactionRows) {
        const list = redactionMap.get(r.utteranceId) || [];
        list.push({ originalText: r.originalText, replacement: r.replacement || '[REDACTED]' });
        redactionMap.set(r.utteranceId, list);
      }
    }

    // Helper: apply redactions to utterance text
    function redactText(utteranceId: string, text: string): string {
      if (!applyRedactions) return text;
      const rules = redactionMap.get(utteranceId);
      if (!rules) return text;
      let result = text;
      for (const rule of rules) {
        result = result.replaceAll(rule.originalText, rule.replacement);
      }
      return result;
    }

    // Helper: format seconds into mm:ss or hh:mm:ss
    function formatTime(seconds: number): string {
      const h = Math.floor(seconds / 3600);
      const m = Math.floor((seconds % 3600) / 60);
      const s = Math.floor(seconds % 60);
      if (h > 0) {
        return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
      }
      return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }

    switch (format) {
      case 'json': {
        const jsonData = {
          session: {
            title: session.title,
            sessionMode: session.sessionMode,
            status: session.status,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            durationSeconds: session.durationSeconds,
            participant: session.participantName,
            study: session.studyTitle,
            summary: session.summary,
          },
          utterances: utteranceRows.map((u) => ({
            speaker: u.speaker,
            text: redactText(u.id, u.text),
            startTime: u.startTime,
            endTime: u.endTime,
            sentimentPolarity: u.sentimentPolarity,
            questionType: u.questionType,
          })),
          ...(includeInsights && { insights: insightRows }),
          topics: topicRows.map((t) => ({
            topicName: t.topicName,
            status: t.status,
          })),
          ...(includeHighlights && {
            highlights: highlightRows.map((h) => ({
              title: h.title,
              category: h.category,
              textSelection: h.textSelection,
              notes: h.notes,
            })),
          }),
        };

        return new NextResponse(JSON.stringify(jsonData, null, 2), {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Content-Disposition': `attachment; filename="${slugify(session.title)}-export.json"`,
          },
        });
      }

      case 'csv': {
        const csvLines: string[] = [];
        // Header
        csvLines.push(
          includeTimestamps
            ? 'Timestamp,Speaker,Text,Sentiment,QuestionType'
            : 'Speaker,Text,Sentiment,QuestionType'
        );

        for (const u of utteranceRows) {
          const text = redactText(u.id, u.text).replace(/"/g, '""');
          const sentiment = u.sentimentPolarity || '';
          const questionType = u.questionType || '';

          if (includeTimestamps) {
            csvLines.push(
              `"${formatTime(u.startTime)}","${u.speaker}","${text}","${sentiment}","${questionType}"`
            );
          } else {
            csvLines.push(
              `"${u.speaker}","${text}","${sentiment}","${questionType}"`
            );
          }
        }

        const csvContent = csvLines.join('\n');

        return new NextResponse(csvContent, {
          status: 200,
          headers: {
            'Content-Type': 'text/csv; charset=utf-8',
            'Content-Disposition': `attachment; filename="${slugify(session.title)}-export.csv"`,
          },
        });
      }

      case 'markdown':
      default: {
        const lines: string[] = [];

        // Title and metadata
        lines.push(`# ${session.title}`);
        lines.push('');
        lines.push(`**Mode:** ${session.sessionMode}`);
        lines.push(`**Status:** ${session.status}`);
        if (session.participantName) {
          lines.push(`**Participant:** ${session.participantName}`);
        }
        if (session.studyTitle) {
          lines.push(`**Study:** ${session.studyTitle}`);
        }
        if (session.startedAt) {
          lines.push(`**Date:** ${new Date(session.startedAt).toLocaleDateString()}`);
        }
        if (session.durationSeconds) {
          lines.push(`**Duration:** ${formatTime(session.durationSeconds)}`);
        }
        lines.push('');

        // Topics
        if (topicRows.length > 0) {
          lines.push('## Topics');
          lines.push('');
          for (const topic of topicRows) {
            const icon =
              topic.status === 'covered'
                ? '[x]'
                : topic.status === 'partial'
                ? '[-]'
                : '[ ]';
            lines.push(`- ${icon} ${topic.topicName}`);
          }
          lines.push('');
        }

        // Transcript
        lines.push('## Transcript');
        lines.push('');

        for (const u of utteranceRows) {
          const text = redactText(u.id, u.text);
          const timestamp = includeTimestamps ? `[${formatTime(u.startTime)}] ` : '';
          const speaker = u.speaker === 'interviewer' ? '**Interviewer**' : '**Participant**';
          lines.push(`${timestamp}${speaker}: ${text}`);
          lines.push('');
        }

        // Insights
        if (includeInsights && insightRows.length > 0) {
          lines.push('## Insights');
          lines.push('');
          for (const ins of insightRows) {
            const time = formatTime(ins.timestamp);
            lines.push(`- [${time}] (${ins.source}) ${ins.note || 'Flagged'}`);
          }
          lines.push('');
        }

        // Highlights
        if (includeHighlights && highlightRows.length > 0) {
          lines.push('## Highlights');
          lines.push('');
          for (const h of highlightRows) {
            lines.push(`### ${h.title} (${h.category})`);
            lines.push(`> ${h.textSelection}`);
            if (h.notes) {
              lines.push(`_${h.notes}_`);
            }
            lines.push('');
          }
        }

        const markdownContent = lines.join('\n');

        return new NextResponse(markdownContent, {
          status: 200,
          headers: {
            'Content-Type': 'text/markdown; charset=utf-8',
            'Content-Disposition': `attachment; filename="${slugify(session.title)}-export.md"`,
          },
        });
      }
    }
  } catch (error) {
    console.error('[API] GET /api/export/[id] error:', error);
    return NextResponse.json(
      { error: 'Failed to export session' },
      { status: 500 }
    );
  }
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
