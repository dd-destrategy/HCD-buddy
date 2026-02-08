"use client";

import React, { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import { Card, CardContent } from "@hcd/ui";
import {
  Search,
  Plus,
  Users,
  User,
  Mail,
  Briefcase,
  Building,
  Award,
  Edit3,
  Trash2,
  Download,
  X,
  Check,
  ChevronRight,
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
  sessionCount: number;
}

// ─── Participants Page ──────────────────────────────────────────────────────

export default function ParticipantsPage() {
  const router = useRouter();
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [total, setTotal] = useState(0);

  // Add new participant dialog
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [newName, setNewName] = useState("");
  const [newEmail, setNewEmail] = useState("");
  const [newRole, setNewRole] = useState("");
  const [newDepartment, setNewDepartment] = useState("");
  const [newExperience, setNewExperience] = useState("");
  const [isSaving, setIsSaving] = useState(false);

  // Inline edit
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editFields, setEditFields] = useState<Partial<Participant>>({});

  // Delete confirmation
  const [deletingId, setDeletingId] = useState<string | null>(null);

  // ─── Fetch Participants ─────────────────────────────────────────────────

  const fetchParticipants = useCallback(async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      if (search) params.set("search", search);
      params.set("limit", "100");

      const response = await fetch(`/api/participants?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        setParticipants(data.participants);
        setTotal(data.total);
      }
    } catch (error) {
      console.error("Failed to fetch participants:", error);
    } finally {
      setIsLoading(false);
    }
  }, [search]);

  useEffect(() => {
    const debounce = setTimeout(fetchParticipants, 300);
    return () => clearTimeout(debounce);
  }, [fetchParticipants]);

  // ─── Add Participant ────────────────────────────────────────────────────

  const handleAdd = useCallback(async () => {
    if (!newName.trim()) return;

    setIsSaving(true);
    try {
      const response = await fetch("/api/participants", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newName.trim(),
          email: newEmail.trim() || null,
          role: newRole.trim() || null,
          department: newDepartment.trim() || null,
          experienceLevel: newExperience || null,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setParticipants((prev) => [
          { ...data.participant, sessionCount: 0 },
          ...prev,
        ]);
        setTotal((prev) => prev + 1);
        setShowAddDialog(false);
        setNewName("");
        setNewEmail("");
        setNewRole("");
        setNewDepartment("");
        setNewExperience("");
      }
    } catch (error) {
      console.error("Failed to create participant:", error);
    } finally {
      setIsSaving(false);
    }
  }, [newName, newEmail, newRole, newDepartment, newExperience]);

  // ─── Inline Edit ────────────────────────────────────────────────────────

  const startEdit = useCallback((participant: Participant) => {
    setEditingId(participant.id);
    setEditFields({
      name: participant.name,
      email: participant.email || "",
      role: participant.role || "",
      department: participant.department || "",
      experienceLevel: participant.experienceLevel || "",
    });
  }, []);

  const saveEdit = useCallback(async () => {
    if (!editingId) return;

    try {
      const response = await fetch(`/api/participants/${editingId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(editFields),
      });

      if (response.ok) {
        const data = await response.json();
        setParticipants((prev) =>
          prev.map((p) =>
            p.id === editingId ? { ...p, ...data.participant } : p
          )
        );
        setEditingId(null);
        setEditFields({});
      }
    } catch (error) {
      console.error("Failed to update participant:", error);
    }
  }, [editingId, editFields]);

  // ─── Delete Participant ─────────────────────────────────────────────────

  const handleDelete = useCallback(async (id: string) => {
    try {
      const response = await fetch(`/api/participants/${id}`, {
        method: "DELETE",
      });

      if (response.ok) {
        setParticipants((prev) => prev.filter((p) => p.id !== id));
        setTotal((prev) => prev - 1);
        setDeletingId(null);
      }
    } catch (error) {
      console.error("Failed to delete participant:", error);
    }
  }, []);

  // ─── Export ─────────────────────────────────────────────────────────────

  const handleExport = useCallback(() => {
    const exportData = participants.map((p) => ({
      name: p.name,
      email: p.email,
      role: p.role,
      department: p.department,
      experienceLevel: p.experienceLevel,
      sessionCount: p.sessionCount,
      createdAt: p.createdAt,
    }));

    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `participants-export-${format(new Date(), "yyyy-MM-dd")}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [participants]);

  const EXPERIENCE_LEVELS = ["Novice", "Intermediate", "Advanced", "Expert"];

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="border-b px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-2xl font-semibold">Participants</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Manage research participants and their data
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" onClick={handleExport}>
              <Download className="h-4 w-4 mr-1.5" />
              Export
            </Button>
            <Button size="sm" onClick={() => setShowAddDialog(true)}>
              <Plus className="h-4 w-4 mr-1.5" />
              Add Participant
            </Button>
          </div>
        </div>

        {/* Search */}
        <div className="relative max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name, email, or role..."
            className="pl-9"
            aria-label="Search participants"
          />
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto scrollbar-thin">
        {isLoading ? (
          <div className="flex items-center justify-center h-40">
            <div className="text-sm text-muted-foreground">Loading participants...</div>
          </div>
        ) : participants.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 text-center">
            <div className="rounded-full bg-muted p-4 mb-4">
              <Users className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-medium mb-1">No participants yet</h3>
            <p className="text-sm text-muted-foreground max-w-sm">
              Add participants to track their session history and consent records.
            </p>
            <Button size="sm" className="mt-4" onClick={() => setShowAddDialog(true)}>
              <Plus className="h-4 w-4 mr-1.5" />
              Add First Participant
            </Button>
          </div>
        ) : (
          <table className="w-full" role="table" aria-label="Participants list">
            <thead className="bg-muted/50 sticky top-0">
              <tr>
                <th className="text-left text-xs font-medium text-muted-foreground px-6 py-3">Name</th>
                <th className="text-left text-xs font-medium text-muted-foreground px-4 py-3">Email</th>
                <th className="text-left text-xs font-medium text-muted-foreground px-4 py-3">Role</th>
                <th className="text-left text-xs font-medium text-muted-foreground px-4 py-3">Department</th>
                <th className="text-left text-xs font-medium text-muted-foreground px-4 py-3">Experience</th>
                <th className="text-center text-xs font-medium text-muted-foreground px-4 py-3">Sessions</th>
                <th className="text-right text-xs font-medium text-muted-foreground px-6 py-3">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {participants.map((participant) => {
                const isEditing = editingId === participant.id;
                return (
                  <tr
                    key={participant.id}
                    className="group hover:bg-accent/30 transition-colors"
                  >
                    <td className="px-6 py-3">
                      {isEditing ? (
                        <Input
                          value={editFields.name || ""}
                          onChange={(e) => setEditFields((f) => ({ ...f, name: e.target.value }))}
                          className="h-8 text-sm"
                          aria-label="Participant name"
                        />
                      ) : (
                        <button
                          type="button"
                          onClick={() => router.push(`/participants/${participant.id}`)}
                          className="flex items-center gap-2 text-sm font-medium hover:text-primary transition-colors"
                        >
                          <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                            <User className="h-4 w-4 text-primary" />
                          </div>
                          {participant.name}
                        </button>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <Input
                          value={(editFields.email as string) || ""}
                          onChange={(e) => setEditFields((f) => ({ ...f, email: e.target.value }))}
                          className="h-8 text-sm"
                          aria-label="Email"
                        />
                      ) : (
                        <span className="text-sm text-muted-foreground">
                          {participant.email || "-"}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <Input
                          value={(editFields.role as string) || ""}
                          onChange={(e) => setEditFields((f) => ({ ...f, role: e.target.value }))}
                          className="h-8 text-sm"
                          aria-label="Role"
                        />
                      ) : (
                        <span className="text-sm">{participant.role || "-"}</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <Input
                          value={(editFields.department as string) || ""}
                          onChange={(e) => setEditFields((f) => ({ ...f, department: e.target.value }))}
                          className="h-8 text-sm"
                          aria-label="Department"
                        />
                      ) : (
                        <span className="text-sm text-muted-foreground">
                          {participant.department || "-"}
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {isEditing ? (
                        <select
                          value={(editFields.experienceLevel as string) || ""}
                          onChange={(e) => setEditFields((f) => ({ ...f, experienceLevel: e.target.value }))}
                          className="h-8 rounded-md border border-input bg-background px-2 text-sm"
                          aria-label="Experience level"
                        >
                          <option value="">-</option>
                          {EXPERIENCE_LEVELS.map((level) => (
                            <option key={level} value={level}>
                              {level}
                            </option>
                          ))}
                        </select>
                      ) : participant.experienceLevel ? (
                        <Badge variant="outline" className="text-xs">
                          {participant.experienceLevel}
                        </Badge>
                      ) : (
                        <span className="text-sm text-muted-foreground">-</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-center">
                      <Badge variant="secondary" className="text-xs">
                        {participant.sessionCount}
                      </Badge>
                    </td>
                    <td className="px-6 py-3 text-right">
                      {isEditing ? (
                        <div className="flex items-center justify-end gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7"
                            onClick={saveEdit}
                            aria-label="Save changes"
                          >
                            <Check className="h-3.5 w-3.5" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7"
                            onClick={() => {
                              setEditingId(null);
                              setEditFields({});
                            }}
                            aria-label="Cancel edit"
                          >
                            <X className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      ) : (
                        <div className="flex items-center justify-end gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7"
                            onClick={() => startEdit(participant)}
                            aria-label={`Edit ${participant.name}`}
                          >
                            <Edit3 className="h-3.5 w-3.5" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7 text-destructive hover:text-destructive"
                            onClick={() => setDeletingId(participant.id)}
                            aria-label={`Delete ${participant.name}`}
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7"
                            onClick={() => router.push(`/participants/${participant.id}`)}
                            aria-label={`View ${participant.name} details`}
                          >
                            <ChevronRight className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Add Participant Dialog */}
      <Dialog.Root open={showAddDialog} onOpenChange={setShowAddDialog}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50" />
          <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md rounded-xl border bg-card p-6 shadow-xl z-50 focus:outline-none">
            <Dialog.Title className="text-lg font-semibold mb-4">
              Add Participant
            </Dialog.Title>

            <div className="space-y-3">
              <div>
                <label htmlFor="new-name" className="text-sm font-medium mb-1 block">
                  Name *
                </label>
                <Input
                  id="new-name"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  placeholder="Full name"
                  aria-required="true"
                />
              </div>
              <div>
                <label htmlFor="new-email" className="text-sm font-medium mb-1 block">
                  Email
                </label>
                <Input
                  id="new-email"
                  type="email"
                  value={newEmail}
                  onChange={(e) => setNewEmail(e.target.value)}
                  placeholder="email@example.com"
                />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label htmlFor="new-role" className="text-sm font-medium mb-1 block">
                    Role
                  </label>
                  <Input
                    id="new-role"
                    value={newRole}
                    onChange={(e) => setNewRole(e.target.value)}
                    placeholder="e.g. Designer"
                  />
                </div>
                <div>
                  <label htmlFor="new-department" className="text-sm font-medium mb-1 block">
                    Department
                  </label>
                  <Input
                    id="new-department"
                    value={newDepartment}
                    onChange={(e) => setNewDepartment(e.target.value)}
                    placeholder="e.g. Product"
                  />
                </div>
              </div>
              <div>
                <label htmlFor="new-experience" className="text-sm font-medium mb-1 block">
                  Experience Level
                </label>
                <select
                  id="new-experience"
                  value={newExperience}
                  onChange={(e) => setNewExperience(e.target.value)}
                  className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 text-sm"
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

            <div className="flex justify-end gap-2 mt-6">
              <Dialog.Close asChild>
                <Button variant="ghost">Cancel</Button>
              </Dialog.Close>
              <Button onClick={handleAdd} disabled={!newName.trim() || isSaving}>
                {isSaving ? "Adding..." : "Add Participant"}
              </Button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>

      {/* Delete Confirmation Dialog */}
      <Dialog.Root open={!!deletingId} onOpenChange={() => setDeletingId(null)}>
        <Dialog.Portal>
          <Dialog.Overlay className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50" />
          <Dialog.Content className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-sm rounded-xl border bg-card p-6 shadow-xl z-50 focus:outline-none">
            <Dialog.Title className="text-lg font-semibold mb-2">
              Delete Participant?
            </Dialog.Title>
            <Dialog.Description className="text-sm text-muted-foreground mb-4">
              This will permanently delete this participant and all associated data
              including session transcripts, consent records, and highlights.
              This action complies with GDPR right to erasure and cannot be undone.
            </Dialog.Description>

            <div className="flex justify-end gap-2">
              <Dialog.Close asChild>
                <Button variant="ghost">Cancel</Button>
              </Dialog.Close>
              <Button
                variant="destructive"
                onClick={() => deletingId && handleDelete(deletingId)}
              >
                <Trash2 className="h-4 w-4 mr-1.5" />
                Delete All Data
              </Button>
            </div>
          </Dialog.Content>
        </Dialog.Portal>
      </Dialog.Root>
    </div>
  );
}
