"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import { Card, CardContent, CardHeader, CardTitle } from "@hcd/ui";
import {
  User,
  Mail,
  Briefcase,
  Building,
  Award,
  Calendar,
  Clock,
  FileText,
  Shield,
  ShieldCheck,
  Edit3,
  Save,
  X,
  Trash2,
  Plus,
  ChevronLeft,
  AlertTriangle,
} from "lucide-react";
import { format } from "date-fns";
import * as Dialog from "@radix-ui/react-dialog";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Participant {
  id: string;
  organizationId: string | null;
  name: string;
  email: string | null;
  role: string | null;
  department: string | null;
  experienceLevel: string | null;
  metadata: Record<string, any>;
  createdAt: string;
  updatedAt: string;
}

interface SessionRecord {
  id: string;
  title: string;
  status: string;
  startedAt: string | null;
  endedAt: string | null;
  durationSeconds: number | null;
  consentStatus: string | null;
}

interface ConsentRecord {
  id: string;
  sessionId: string;
  templateVersion: string;
  status: string;
  permissions: Record<string, boolean>;
  signatureName: string | null;
  obtainedAt: string | null;
  createdAt: string;
}

const CONSENT_STATUS_META: Record<string, { label: string; variant: string }> = {
  not_obtained: { label: "Not Obtained", variant: "outline" },
  verbal_consent: { label: "Verbal", variant: "warning" },
  written_consent: { label: "Written", variant: "success" },
  declined: { label: "Declined", variant: "destructive" },
};

const EXPERIENCE_LEVELS = ["Novice", "Intermediate", "Advanced", "Expert"];

// ─── Participant Detail Page ────────────────────────────────────────────────

export default function ParticipantDetailPage() {
  const params = useParams();
  const router = useRouter();
  const participantId = params.id as string;

  const [participant, setParticipant] = useState<Participant | null>(null);
  const [sessions, setSessions] = useState<SessionRecord[]>([]);
  const [consentRecords, setConsentRecords] = useState<ConsentRecord[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editFields, setEditFields] = useState<Partial<Participant>>({});
  const [isSaving, setIsSaving] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  // Metadata editing
  const [metadataEntries, setMetadataEntries] = useState<Array<{ key: string; value: string }>>([]);

  // ─── Fetch Data ─────────────────────────────────────────────────────────

  const fetchParticipant = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`/api/participants/${participantId}`);
      if (response.ok) {
        const data = await response.json();
        setParticipant(data.participant);
        setSessions(data.sessions);
        setConsentRecords(data.consentRecords);

        // Initialize metadata entries
        const meta = data.participant.metadata || {};
        setMetadataEntries(
          Object.entries(meta).map(([key, value]) => ({
            key,
            value: String(value),
          }))
        );
      } else if (response.status === 404) {
        router.push("/participants");
      }
    } catch (error) {
      console.error("Failed to fetch participant:", error);
    } finally {
      setIsLoading(false);
    }
  }, [participantId, router]);

  useEffect(() => {
    fetchParticipant();
  }, [fetchParticipant]);

  // ─── Edit Handlers ──────────────────────────────────────────────────────

  const startEditing = useCallback(() => {
    if (!participant) return;
    setIsEditing(true);
    setEditFields({
      name: participant.name,
      email: participant.email || "",
      role: participant.role || "",
      department: participant.department || "",
      experienceLevel: participant.experienceLevel || "",
    });
  }, [participant]);

  const saveChanges = useCallback(async () => {
    if (!participant) return;

    setIsSaving(true);
    try {
      // Build metadata from entries
      const metadata: Record<string, string> = {};
      for (const entry of metadataEntries) {
        if (entry.key.trim()) {
          metadata[entry.key.trim()] = entry.value;
        }
      }

      const response = await fetch(`/api/participants/${participantId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...editFields, metadata }),
      });

      if (response.ok) {
        const data = await response.json();
        setParticipant(data.participant);
        setIsEditing(false);
        setEditFields({});
      }
    } catch (error) {
      console.error("Failed to save changes:", error);
    } finally {
      setIsSaving(false);
    }
  }, [participantId, editFields, metadataEntries, participant]);

  // ─── Delete Handler ─────────────────────────────────────────────────────

  const handleDelete = useCallback(async () => {
    setIsDeleting(true);
    try {
      const response = await fetch(`/api/participants/${participantId}`, {
        method: "DELETE",
      });

      if (response.ok) {
        router.push("/participants");
      }
    } catch (error) {
      console.error("Failed to delete participant:", error);
    } finally {
      setIsDeleting(false);
    }
  }, [participantId, router]);

  // ─── Metadata Helpers ───────────────────────────────────────────────────

  const addMetadataEntry = useCallback(() => {
    setMetadataEntries((prev) => [...prev, { key: "", value: "" }]);
  }, []);

  const removeMetadataEntry = useCallback((index: number) => {
    setMetadataEntries((prev) => prev.filter((_, i) => i !== index));
  }, []);

  const updateMetadataEntry = useCallback(
    (index: number, field: "key" | "value", val: string) => {
      setMetadataEntries((prev) =>
        prev.map((entry, i) =>
          i === index ? { ...entry, [field]: val } : entry
        )
      );
    },
    []
  );

  // ─── Loading State ──────────────────────────────────────────────────────

  if (isLoading || !participant) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-sm text-muted-foreground">Loading participant...</div>
      </div>
    );
  }

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <div className="max-w-4xl mx-auto p-6 space-y-6">
      {/* Back button */}
      <Button
        variant="ghost"
        size="sm"
        onClick={() => router.push("/participants")}
      >
        <ChevronLeft className="h-4 w-4 mr-1" />
        All Participants
      </Button>

      {/* Profile Header */}
      <Card>
        <CardContent className="p-6">
          <div className="flex items-start justify-between">
            <div className="flex items-start gap-4">
              <div className="h-16 w-16 rounded-full bg-primary/10 flex items-center justify-center">
                <User className="h-8 w-8 text-primary" />
              </div>
              <div>
                {isEditing ? (
                  <div className="space-y-2">
                    <Input
                      value={editFields.name || ""}
                      onChange={(e) =>
                        setEditFields((f) => ({ ...f, name: e.target.value }))
                      }
                      className="text-xl font-semibold h-10"
                      aria-label="Name"
                    />
                    <div className="grid grid-cols-2 gap-2">
                      <div className="flex items-center gap-2">
                        <Mail className="h-4 w-4 text-muted-foreground shrink-0" />
                        <Input
                          value={(editFields.email as string) || ""}
                          onChange={(e) =>
                            setEditFields((f) => ({ ...f, email: e.target.value }))
                          }
                          placeholder="Email"
                          className="h-8 text-sm"
                          aria-label="Email"
                        />
                      </div>
                      <div className="flex items-center gap-2">
                        <Briefcase className="h-4 w-4 text-muted-foreground shrink-0" />
                        <Input
                          value={(editFields.role as string) || ""}
                          onChange={(e) =>
                            setEditFields((f) => ({ ...f, role: e.target.value }))
                          }
                          placeholder="Role"
                          className="h-8 text-sm"
                          aria-label="Role"
                        />
                      </div>
                      <div className="flex items-center gap-2">
                        <Building className="h-4 w-4 text-muted-foreground shrink-0" />
                        <Input
                          value={(editFields.department as string) || ""}
                          onChange={(e) =>
                            setEditFields((f) => ({
                              ...f,
                              department: e.target.value,
                            }))
                          }
                          placeholder="Department"
                          className="h-8 text-sm"
                          aria-label="Department"
                        />
                      </div>
                      <div className="flex items-center gap-2">
                        <Award className="h-4 w-4 text-muted-foreground shrink-0" />
                        <select
                          value={(editFields.experienceLevel as string) || ""}
                          onChange={(e) =>
                            setEditFields((f) => ({
                              ...f,
                              experienceLevel: e.target.value,
                            }))
                          }
                          className="h-8 flex-1 rounded-md border border-input bg-background px-2 text-sm"
                          aria-label="Experience level"
                        >
                          <option value="">Select level</option>
                          {EXPERIENCE_LEVELS.map((level) => (
                            <option key={level} value={level}>
                              {level}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>
                  </div>
                ) : (
                  <>
                    <h1 className="text-2xl font-semibold">{participant.name}</h1>
                    <div className="flex flex-wrap items-center gap-x-4 gap-y-1 mt-2 text-sm text-muted-foreground">
                      {participant.email && (
                        <span className="flex items-center gap-1">
                          <Mail className="h-3.5 w-3.5" />
                          {participant.email}
                        </span>
                      )}
                      {participant.role && (
                        <span className="flex items-center gap-1">
                          <Briefcase className="h-3.5 w-3.5" />
                          {participant.role}
                        </span>
                      )}
                      {participant.department && (
                        <span className="flex items-center gap-1">
                          <Building className="h-3.5 w-3.5" />
                          {participant.department}
                        </span>
                      )}
                      {participant.experienceLevel && (
                        <Badge variant="outline">
                          <Award className="h-3 w-3 mr-1" />
                          {participant.experienceLevel}
                        </Badge>
                      )}
                    </div>
                  </>
                )}
              </div>
            </div>

            <div className="flex items-center gap-2">
              {isEditing ? (
                <>
                  <Button
                    size="sm"
                    onClick={saveChanges}
                    disabled={isSaving}
                  >
                    <Save className="h-4 w-4 mr-1.5" />
                    {isSaving ? "Saving..." : "Save"}
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setIsEditing(false);
                      setEditFields({});
                    }}
                  >
                    <X className="h-4 w-4 mr-1.5" />
                    Cancel
                  </Button>
                </>
              ) : (
                <>
                  <Button variant="outline" size="sm" onClick={startEditing}>
                    <Edit3 className="h-4 w-4 mr-1.5" />
                    Edit
                  </Button>
                  <Button
                    variant="destructive"
                    size="sm"
                    onClick={() => setShowDeleteDialog(true)}
                  >
                    <Trash2 className="h-4 w-4 mr-1.5" />
                    Delete All Data
                  </Button>
                </>
              )}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Custom Metadata */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Custom Metadata</CardTitle>
            {isEditing && (
              <Button variant="outline" size="sm" onClick={addMetadataEntry}>
                <Plus className="h-3.5 w-3.5 mr-1" />
                Add Field
              </Button>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {metadataEntries.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              {isEditing
                ? "Add custom fields to track additional participant information."
                : "No custom metadata."}
            </p>
          ) : (
            <div className="space-y-2">
              {metadataEntries.map((entry, index) => (
                <div key={index} className="flex items-center gap-2">
                  {isEditing ? (
                    <>
                      <Input
                        value={entry.key}
                        onChange={(e) => updateMetadataEntry(index, "key", e.target.value)}
                        placeholder="Key"
                        className="h-8 text-sm w-40"
                        aria-label="Metadata key"
                      />
                      <Input
                        value={entry.value}
                        onChange={(e) => updateMetadataEntry(index, "value", e.target.value)}
                        placeholder="Value"
                        className="h-8 text-sm flex-1"
                        aria-label="Metadata value"
                      />
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-7 w-7 shrink-0"
                        onClick={() => removeMetadataEntry(index)}
                        aria-label="Remove field"
                      >
                        <X className="h-3.5 w-3.5" />
                      </Button>
                    </>
                  ) : (
                    <div className="flex items-baseline gap-2">
                      <span className="text-sm font-medium text-muted-foreground min-w-[100px]">
                        {entry.key}:
                      </span>
                      <span className="text-sm">{entry.value}</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Session History */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">
            Session History ({sessions.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {sessions.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No sessions recorded with this participant.
            </p>
          ) : (
            <div className="space-y-2">
              {sessions.map((session) => (
                <button
                  key={session.id}
                  type="button"
                  onClick={() => router.push(`/sessions/${session.id}`)}
                  className="w-full flex items-center gap-3 rounded-lg border p-3 text-left hover:bg-accent/30 transition-colors"
                >
                  <FileText className="h-4 w-4 text-muted-foreground shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium truncate">
                        {session.title}
                      </span>
                      <Badge variant="outline" className="text-xs shrink-0">
                        {session.status}
                      </Badge>
                    </div>
                    <div className="flex items-center gap-3 text-xs text-muted-foreground mt-0.5">
                      {session.startedAt && (
                        <span className="flex items-center gap-1">
                          <Calendar className="h-3 w-3" />
                          {format(new Date(session.startedAt), "MMM d, yyyy")}
                        </span>
                      )}
                      {session.durationSeconds && (
                        <span className="flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {Math.round(session.durationSeconds / 60)} min
                        </span>
                      )}
                    </div>
                  </div>
                  {session.consentStatus && (
                    <Badge
                      variant={
                        (CONSENT_STATUS_META[session.consentStatus]?.variant as any) || "outline"
                      }
                      className="text-xs shrink-0"
                    >
                      <Shield className="h-3 w-3 mr-1" />
                      {CONSENT_STATUS_META[session.consentStatus]?.label || session.consentStatus}
                    </Badge>
                  )}
                </button>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Consent Records */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">
            Consent Records ({consentRecords.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {consentRecords.length === 0 ? (
            <p className="text-sm text-muted-foreground">
              No consent records for this participant.
            </p>
          ) : (
            <div className="space-y-2">
              {consentRecords.map((record) => {
                const statusMeta = CONSENT_STATUS_META[record.status];
                return (
                  <div
                    key={record.id}
                    className="flex items-center gap-3 rounded-lg border p-3"
                  >
                    <ShieldCheck className="h-4 w-4 text-muted-foreground shrink-0" />
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <Badge variant={(statusMeta?.variant as any) || "outline"} className="text-xs">
                          {statusMeta?.label || record.status}
                        </Badge>
                        <span className="text-xs text-muted-foreground">
                          Template: {record.templateVersion}
                        </span>
                      </div>
                      {record.signatureName && (
                        <p className="text-xs text-muted-foreground mt-0.5">
                          Signed by: {record.signatureName}
                        </p>
                      )}
                    </div>
                    <span className="text-xs text-muted-foreground">
                      {record.obtainedAt
                        ? format(new Date(record.obtainedAt), "MMM d, yyyy")
                        : format(new Date(record.createdAt), "MMM d, yyyy")}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Delete Dialog */}
      <Dialog.Root open={showDeleteDialog} onOpenChange={setShowDeleteDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50" />
          <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md rounded-xl border bg-card p-6 shadow-xl z-50 focus:outline-none">
            <div className="flex items-start gap-3 mb-4">
              <div className="rounded-full bg-red-100 dark:bg-red-900 p-2">
                <AlertTriangle className="h-5 w-5 text-red-600 dark:text-red-400" />
              </div>
              <div>
                <Dialog.Title className="text-lg font-semibold">
                  Delete All Data for {participant.name}?
                </Dialog.Title>
                <Dialog.Description className="text-sm text-muted-foreground mt-1">
                  This action permanently deletes:
                </Dialog.Description>
              </div>
            </div>

            <ul className="list-disc list-inside text-sm text-muted-foreground space-y-1 mb-4 ml-2">
              <li>Participant profile and metadata</li>
              <li>All session transcripts and recordings</li>
              <li>All consent records</li>
              <li>All highlights and annotations</li>
              <li>All redaction records</li>
            </ul>

            <p className="text-sm text-muted-foreground mb-4">
              This complies with GDPR Article 17 (Right to Erasure) and cannot be undone.
            </p>

            <div className="flex justify-end gap-2">
              <Dialog.Close asChild>
                <Button variant="ghost">Cancel</Button>
              </Dialog.Close>
              <Button
                variant="destructive"
                onClick={handleDelete}
                disabled={isDeleting}
              >
                <Trash2 className="h-4 w-4 mr-1.5" />
                {isDeleting ? "Deleting..." : "Permanently Delete All Data"}
              </Button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  );
}
