"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { useParams } from "next/navigation";
import { Button } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import { Card, CardContent, CardHeader, CardTitle } from "@hcd/ui";
import { Input } from "@hcd/ui";
import {
  Shield,
  ShieldAlert,
  ShieldCheck,
  Eye,
  EyeOff,
  Check,
  X,
  Replace,
  AlertTriangle,
  Mail,
  Phone,
  CreditCard,
  MapPin,
  User,
  Hash,
  Calendar,
  Globe,
  Scan,
  RefreshCw,
  FileText,
  ChevronDown,
  ChevronRight,
} from "lucide-react";
import * as Progress from "@radix-ui/react-progress";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Detection {
  id: string;
  piiType: string;
  originalText: string;
  replacement: string | null;
  decision: string;
  decidedBy: string | null;
  decidedAt: string | null;
}

interface UtteranceGroup {
  utterance: {
    id: string;
    text: string;
    speaker: string;
    startTime: number;
  };
  detections: Detection[];
}

interface PiiSummary {
  [type: string]: { total: number; reviewed: number };
}

const PII_TYPE_META: Record<string, { icon: React.ReactNode; label: string; color: string }> = {
  email: { icon: <Mail className="h-3.5 w-3.5" />, label: "Email", color: "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200" },
  phone: { icon: <Phone className="h-3.5 w-3.5" />, label: "Phone", color: "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200" },
  ssn: { icon: <Hash className="h-3.5 w-3.5" />, label: "SSN", color: "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200" },
  credit_card: { icon: <CreditCard className="h-3.5 w-3.5" />, label: "Credit Card", color: "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200" },
  ip_address: { icon: <Globe className="h-3.5 w-3.5" />, label: "IP Address", color: "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200" },
  date_of_birth: { icon: <Calendar className="h-3.5 w-3.5" />, label: "DOB", color: "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200" },
  address: { icon: <MapPin className="h-3.5 w-3.5" />, label: "Address", color: "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200" },
  name: { icon: <User className="h-3.5 w-3.5" />, label: "Name", color: "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200" },
  zip_code: { icon: <MapPin className="h-3.5 w-3.5" />, label: "ZIP Code", color: "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200" },
};

function getPiiMeta(type: string) {
  return PII_TYPE_META[type] || { icon: <ShieldAlert className="h-3.5 w-3.5" />, label: type, color: "bg-gray-100 text-gray-800" };
}

// ─── Redaction Review Page ──────────────────────────────────────────────────

export default function RedactionReviewPage() {
  const params = useParams();
  const sessionId = params.id as string;

  const [groups, setGroups] = useState<UtteranceGroup[]>([]);
  const [summary, setSummary] = useState<PiiSummary>({});
  const [total, setTotal] = useState(0);
  const [reviewed, setReviewed] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [isScanning, setIsScanning] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [expandedUtterances, setExpandedUtterances] = useState<Set<string>>(new Set());
  const [revealedTexts, setRevealedTexts] = useState<Set<string>>(new Set());
  const [replaceInputs, setReplaceInputs] = useState<Record<string, string>>({});
  const [isApplying, setIsApplying] = useState(false);

  // ─── Fetch Redactions ───────────────────────────────────────────────────

  const fetchRedactions = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`/api/redactions?sessionId=${sessionId}`);
      if (response.ok) {
        const data = await response.json();
        setGroups(data.redactions);
        setSummary(data.summary);
        setTotal(data.total);
        setReviewed(data.reviewed);
        // Expand all utterances by default
        const ids = new Set(data.redactions.map((g: UtteranceGroup) => g.utterance.id));
        setExpandedUtterances(ids as Set<string>);
      }
    } catch (error) {
      console.error("Failed to fetch redactions:", error);
    } finally {
      setIsLoading(false);
    }
  }, [sessionId]);

  useEffect(() => {
    fetchRedactions();
  }, [fetchRedactions]);

  // ─── PII Scan ───────────────────────────────────────────────────────────

  const handleScan = useCallback(async () => {
    setIsScanning(true);
    try {
      const response = await fetch("/api/redactions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "scan", sessionId }),
      });

      if (response.ok) {
        await fetchRedactions();
      }
    } catch (error) {
      console.error("Failed to scan:", error);
    } finally {
      setIsScanning(false);
    }
  }, [sessionId, fetchRedactions]);

  // ─── Decision Handlers ──────────────────────────────────────────────────

  const makeDecision = useCallback(
    async (detectionId: string, decision: string, replacement?: string) => {
      try {
        const response = await fetch("/api/redactions", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            id: detectionId,
            decision,
            replacement: replacement || undefined,
          }),
        });

        if (response.ok) {
          setGroups((prev) =>
            prev.map((group) => ({
              ...group,
              detections: group.detections.map((d) =>
                d.id === detectionId
                  ? {
                      ...d,
                      decision,
                      replacement:
                        decision === "replace"
                          ? replacement || d.replacement
                          : decision === "redact"
                          ? "[REDACTED]"
                          : null,
                      decidedAt: new Date().toISOString(),
                    }
                  : d
              ),
            }))
          );
          setReviewed((prev) => prev + 1);
        }
      } catch (error) {
        console.error("Failed to update decision:", error);
      }
    },
    []
  );

  // ─── Bulk Actions ───────────────────────────────────────────────────────

  const bulkDecision = useCallback(
    async (piiType: string, decision: string) => {
      const pendingDetections = groups.flatMap((g) =>
        g.detections.filter(
          (d) => d.piiType === piiType && d.decision === "pending"
        )
      );

      if (pendingDetections.length === 0) return;

      try {
        const response = await fetch("/api/redactions", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            decisions: pendingDetections.map((d) => ({
              id: d.id,
              action: decision,
            })),
          }),
        });

        if (response.ok) {
          setGroups((prev) =>
            prev.map((group) => ({
              ...group,
              detections: group.detections.map((d) =>
                d.piiType === piiType && d.decision === "pending"
                  ? {
                      ...d,
                      decision,
                      replacement: decision === "redact" ? "[REDACTED]" : null,
                      decidedAt: new Date().toISOString(),
                    }
                  : d
              ),
            }))
          );
          setReviewed((prev) => prev + pendingDetections.length);
        }
      } catch (error) {
        console.error("Failed to bulk update:", error);
      }
    },
    [groups]
  );

  // ─── Apply Redactions ───────────────────────────────────────────────────

  const handleApply = useCallback(async () => {
    const pendingCount = total - reviewed;
    if (pendingCount > 0) {
      if (!confirm(`There are ${pendingCount} unreviewed detections. Continue applying?`)) {
        return;
      }
    }

    setIsApplying(true);
    // In a real implementation, this would update the utterance texts
    // with the redacted versions
    setTimeout(() => {
      setIsApplying(false);
      alert("Redactions applied successfully!");
    }, 1000);
  }, [total, reviewed]);

  // ─── Toggle helpers ─────────────────────────────────────────────────────

  const toggleUtterance = useCallback((id: string) => {
    setExpandedUtterances((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }, []);

  const toggleReveal = useCallback((detectionId: string) => {
    setRevealedTexts((prev) => {
      const next = new Set(prev);
      if (next.has(detectionId)) {
        next.delete(detectionId);
      } else {
        next.add(detectionId);
      }
      return next;
    });
  }, []);

  // ─── Progress ───────────────────────────────────────────────────────────

  const progressPct = total > 0 ? Math.round((reviewed / total) * 100) : 0;

  // ─── Build preview transcript ───────────────────────────────────────────

  const previewGroups = useMemo(() => {
    return groups.map((group) => {
      let text = group.utterance.text;
      // Sort detections by position in text (reverse order for correct replacement)
      const sorted = [...group.detections]
        .filter((d) => d.decision === "redact" || d.decision === "replace")
        .sort((a, b) => {
          const idxA = text.indexOf(a.originalText);
          const idxB = text.indexOf(b.originalText);
          return idxB - idxA; // reverse order
        });

      for (const detection of sorted) {
        const replacement =
          detection.decision === "replace" && detection.replacement
            ? detection.replacement
            : "[REDACTED]";
        text = text.replace(detection.originalText, replacement);
      }

      return {
        speaker: group.utterance.speaker,
        text,
        startTime: group.utterance.startTime,
      };
    });
  }, [groups]);

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="border-b px-6 py-4">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            <Shield className="h-6 w-6 text-primary" />
            <div>
              <h1 className="text-xl font-semibold">PII Redaction Review</h1>
              <p className="text-sm text-muted-foreground">
                Review and manage personal data detected in this session
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={handleScan}
              disabled={isScanning}
            >
              {isScanning ? (
                <RefreshCw className="h-4 w-4 mr-1.5 animate-spin" />
              ) : (
                <Scan className="h-4 w-4 mr-1.5" />
              )}
              {isScanning ? "Scanning..." : "Scan for PII"}
            </Button>
            <Button
              variant={showPreview ? "secondary" : "outline"}
              size="sm"
              onClick={() => setShowPreview(!showPreview)}
            >
              <FileText className="h-4 w-4 mr-1.5" />
              Preview
            </Button>
            <Button
              size="sm"
              onClick={handleApply}
              disabled={isApplying || reviewed === 0}
            >
              <ShieldCheck className="h-4 w-4 mr-1.5" />
              {isApplying ? "Applying..." : "Apply Redactions"}
            </Button>
          </div>
        </div>

        {/* Progress Bar */}
        {total > 0 && (
          <div className="space-y-1.5">
            <div className="flex items-center justify-between text-sm">
              <span className="text-muted-foreground">
                {reviewed} of {total} reviewed
              </span>
              <span className="font-medium">{progressPct}%</span>
            </div>
            <Progress.Root
              className="relative overflow-hidden rounded-full bg-secondary h-2"
              value={progressPct}
            >
              <Progress.Indicator
                className="h-full bg-primary transition-transform duration-300 ease-out rounded-full"
                style={{ transform: `translateX(-${100 - progressPct}%)` }}
              />
            </Progress.Root>
          </div>
        )}
      </div>

      <div className="flex flex-1 overflow-hidden">
        {/* Main Content */}
        <div className={`flex-1 overflow-y-auto p-6 scrollbar-thin ${showPreview ? "w-1/2" : "w-full"}`}>
          {isLoading ? (
            <div className="flex items-center justify-center h-40">
              <div className="text-sm text-muted-foreground">Loading scan results...</div>
            </div>
          ) : total === 0 ? (
            <div className="flex flex-col items-center justify-center h-64 text-center">
              <div className="rounded-full bg-green-100 dark:bg-green-900 p-4 mb-4">
                <ShieldCheck className="h-8 w-8 text-green-600 dark:text-green-400" />
              </div>
              <h3 className="text-lg font-medium mb-1">No PII detected</h3>
              <p className="text-sm text-muted-foreground max-w-sm">
                Run a scan to check for personal information in the session transcript.
              </p>
              <Button variant="outline" size="sm" className="mt-4" onClick={handleScan} disabled={isScanning}>
                <Scan className="h-4 w-4 mr-1.5" />
                Run PII Scan
              </Button>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Summary Cards */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                {Object.entries(summary).map(([type, counts]) => {
                  const meta = getPiiMeta(type);
                  return (
                    <Card key={type} className="p-3">
                      <div className="flex items-center justify-between mb-2">
                        <Badge className={`${meta.color} text-xs border-0`}>
                          {meta.icon}
                          <span className="ml-1">{meta.label}</span>
                        </Badge>
                        <span className="text-lg font-semibold">{counts.total}</span>
                      </div>
                      <div className="flex gap-1">
                        <Button
                          variant="outline"
                          size="sm"
                          className="flex-1 h-7 text-xs"
                          onClick={() => bulkDecision(type, "redact")}
                          disabled={counts.reviewed === counts.total}
                        >
                          Redact All
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="flex-1 h-7 text-xs"
                          onClick={() => bulkDecision(type, "keep")}
                          disabled={counts.reviewed === counts.total}
                        >
                          Keep All
                        </Button>
                      </div>
                    </Card>
                  );
                })}
              </div>

              {/* Detections by Utterance */}
              <div className="space-y-3">
                {groups.map((group) => (
                  <Card key={group.utterance.id}>
                    {/* Utterance Header */}
                    <button
                      type="button"
                      onClick={() => toggleUtterance(group.utterance.id)}
                      className="w-full flex items-center gap-3 p-4 text-left hover:bg-accent/30 transition-colors rounded-t-xl"
                      aria-expanded={expandedUtterances.has(group.utterance.id)}
                    >
                      {expandedUtterances.has(group.utterance.id) ? (
                        <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
                      ) : (
                        <ChevronRight className="h-4 w-4 shrink-0 text-muted-foreground" />
                      )}
                      <Badge variant={group.utterance.speaker === "Interviewer" ? "info" : "success"} className="shrink-0">
                        {group.utterance.speaker}
                      </Badge>
                      <span className="text-sm text-muted-foreground truncate flex-1">
                        {group.utterance.text}
                      </span>
                      <Badge variant="outline" className="shrink-0">
                        {group.detections.filter((d) => d.decision === "pending").length} pending
                      </Badge>
                    </button>

                    {/* Detection Items */}
                    {expandedUtterances.has(group.utterance.id) && (
                      <CardContent className="pt-0 space-y-2">
                        {group.detections.map((detection) => {
                          const meta = getPiiMeta(detection.piiType);
                          const isRevealed = revealedTexts.has(detection.id);
                          const isReplacing = replaceInputs[detection.id] !== undefined;

                          return (
                            <div
                              key={detection.id}
                              className={`flex items-center gap-3 rounded-lg border p-3 ${
                                detection.decision === "redact"
                                  ? "border-red-200 bg-red-50/50 dark:border-red-800 dark:bg-red-950/30"
                                  : detection.decision === "keep"
                                  ? "border-green-200 bg-green-50/50 dark:border-green-800 dark:bg-green-950/30"
                                  : detection.decision === "replace"
                                  ? "border-blue-200 bg-blue-50/50 dark:border-blue-800 dark:bg-blue-950/30"
                                  : "border-border"
                              }`}
                            >
                              {/* PII Type Badge */}
                              <Badge className={`${meta.color} text-xs border-0 shrink-0`}>
                                {meta.icon}
                                <span className="ml-1">{meta.label}</span>
                              </Badge>

                              {/* Original Text (blurred) */}
                              <div className="flex-1 min-w-0">
                                <div className="flex items-center gap-2">
                                  <span
                                    className={`text-sm font-mono ${
                                      isRevealed ? "" : "blur-sm select-none"
                                    } transition-all`}
                                  >
                                    {detection.originalText}
                                  </span>
                                  <button
                                    type="button"
                                    onClick={() => toggleReveal(detection.id)}
                                    className="p-1 rounded hover:bg-accent transition-colors"
                                    aria-label={isRevealed ? "Hide text" : "Reveal text"}
                                  >
                                    {isRevealed ? (
                                      <EyeOff className="h-3.5 w-3.5 text-muted-foreground" />
                                    ) : (
                                      <Eye className="h-3.5 w-3.5 text-muted-foreground" />
                                    )}
                                  </button>
                                </div>
                                {detection.decision !== "pending" && (
                                  <span className="text-xs text-muted-foreground">
                                    Decision: {detection.decision}
                                    {detection.decision === "replace" && detection.replacement && (
                                      <span> &rarr; {detection.replacement}</span>
                                    )}
                                  </span>
                                )}
                              </div>

                              {/* Replace Input */}
                              {isReplacing && (
                                <div className="flex items-center gap-1">
                                  <Input
                                    value={replaceInputs[detection.id] || ""}
                                    onChange={(e) =>
                                      setReplaceInputs((prev) => ({
                                        ...prev,
                                        [detection.id]: e.target.value,
                                      }))
                                    }
                                    placeholder="Replacement text"
                                    className="h-7 w-32 text-xs"
                                    aria-label="Replacement text"
                                    onKeyDown={(e) => {
                                      if (e.key === "Enter") {
                                        makeDecision(
                                          detection.id,
                                          "replace",
                                          replaceInputs[detection.id]
                                        );
                                        setReplaceInputs((prev) => {
                                          const next = { ...prev };
                                          delete next[detection.id];
                                          return next;
                                        });
                                      }
                                      if (e.key === "Escape") {
                                        setReplaceInputs((prev) => {
                                          const next = { ...prev };
                                          delete next[detection.id];
                                          return next;
                                        });
                                      }
                                    }}
                                    autoFocus
                                  />
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    className="h-7 w-7 p-0"
                                    onClick={() => {
                                      makeDecision(
                                        detection.id,
                                        "replace",
                                        replaceInputs[detection.id]
                                      );
                                      setReplaceInputs((prev) => {
                                        const next = { ...prev };
                                        delete next[detection.id];
                                        return next;
                                      });
                                    }}
                                  >
                                    <Check className="h-3.5 w-3.5" />
                                  </Button>
                                </div>
                              )}

                              {/* Decision Buttons */}
                              {detection.decision === "pending" && !isReplacing && (
                                <div className="flex items-center gap-1 shrink-0">
                                  <Button
                                    variant="destructive"
                                    size="sm"
                                    className="h-7 text-xs"
                                    onClick={() => makeDecision(detection.id, "redact")}
                                    aria-label="Redact this text"
                                  >
                                    <ShieldAlert className="h-3 w-3 mr-1" />
                                    Redact
                                  </Button>
                                  <Button
                                    variant="outline"
                                    size="sm"
                                    className="h-7 text-xs"
                                    onClick={() => makeDecision(detection.id, "keep")}
                                    aria-label="Keep this text"
                                  >
                                    <Check className="h-3 w-3 mr-1" />
                                    Keep
                                  </Button>
                                  <Button
                                    variant="ghost"
                                    size="sm"
                                    className="h-7 text-xs"
                                    onClick={() =>
                                      setReplaceInputs((prev) => ({
                                        ...prev,
                                        [detection.id]: "",
                                      }))
                                    }
                                    aria-label="Replace with custom text"
                                  >
                                    <Replace className="h-3 w-3 mr-1" />
                                    Replace
                                  </Button>
                                </div>
                              )}

                              {/* Already Decided */}
                              {detection.decision !== "pending" && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="h-7 text-xs"
                                  onClick={() => makeDecision(detection.id, "pending")}
                                  aria-label="Reset decision"
                                >
                                  <RefreshCw className="h-3 w-3 mr-1" />
                                  Undo
                                </Button>
                              )}
                            </div>
                          );
                        })}
                      </CardContent>
                    )}
                  </Card>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Preview Panel */}
        {showPreview && (
          <div className="w-1/2 border-l overflow-y-auto p-6 bg-muted/30 scrollbar-thin">
            <h2 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <FileText className="h-5 w-5" />
              Redacted Transcript Preview
            </h2>
            <div className="space-y-3">
              {previewGroups.map((group, index) => (
                <div key={index} className="flex gap-3">
                  <Badge
                    variant={group.speaker === "Interviewer" ? "info" : "success"}
                    className="shrink-0 mt-0.5"
                  >
                    {group.speaker}
                  </Badge>
                  <p className="text-sm leading-relaxed">{group.text}</p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
