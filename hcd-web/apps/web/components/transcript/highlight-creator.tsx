"use client";

import React, { useState, useCallback, useEffect, useRef } from "react";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import {
  Highlighter,
  AlertTriangle,
  Heart,
  Lightbulb,
  Wrench,
  Sparkles,
  Quote,
  Star,
  X,
  Save,
} from "lucide-react";

// ─── Types ──────────────────────────────────────────────────────────────────

interface HighlightCategory {
  label: string;
  value: string;
  icon: React.ReactNode;
  color: string;
  bgColor: string;
}

interface HighlightCreatorProps {
  sessionId: string;
  utteranceId?: string;
  ownerId?: string;
  onCreated?: (highlight: any) => void;
  onClose?: () => void;
}

const CATEGORIES: HighlightCategory[] = [
  {
    label: "Pain Point",
    value: "Pain Point",
    icon: <AlertTriangle className="h-3.5 w-3.5" />,
    color: "text-red-600",
    bgColor: "bg-red-50 hover:bg-red-100 border-red-200 dark:bg-red-950 dark:hover:bg-red-900 dark:border-red-800",
  },
  {
    label: "User Need",
    value: "User Need",
    icon: <Heart className="h-3.5 w-3.5" />,
    color: "text-blue-600",
    bgColor: "bg-blue-50 hover:bg-blue-100 border-blue-200 dark:bg-blue-950 dark:hover:bg-blue-900 dark:border-blue-800",
  },
  {
    label: "Delight",
    value: "Delight",
    icon: <Sparkles className="h-3.5 w-3.5" />,
    color: "text-green-600",
    bgColor: "bg-green-50 hover:bg-green-100 border-green-200 dark:bg-green-950 dark:hover:bg-green-900 dark:border-green-800",
  },
  {
    label: "Workaround",
    value: "Workaround",
    icon: <Wrench className="h-3.5 w-3.5" />,
    color: "text-orange-600",
    bgColor: "bg-orange-50 hover:bg-orange-100 border-orange-200 dark:bg-orange-950 dark:hover:bg-orange-900 dark:border-orange-800",
  },
  {
    label: "Feature Request",
    value: "Feature Request",
    icon: <Lightbulb className="h-3.5 w-3.5" />,
    color: "text-purple-600",
    bgColor: "bg-purple-50 hover:bg-purple-100 border-purple-200 dark:bg-purple-950 dark:hover:bg-purple-900 dark:border-purple-800",
  },
  {
    label: "Key Quote",
    value: "Key Quote",
    icon: <Quote className="h-3.5 w-3.5" />,
    color: "text-indigo-600",
    bgColor: "bg-indigo-50 hover:bg-indigo-100 border-indigo-200 dark:bg-indigo-950 dark:hover:bg-indigo-900 dark:border-indigo-800",
  },
];

// ─── Highlight Creator Popover ──────────────────────────────────────────────

export function HighlightCreator({
  sessionId,
  utteranceId,
  ownerId,
  onCreated,
  onClose,
}: HighlightCreatorProps) {
  const [selectedText, setSelectedText] = useState("");
  const [title, setTitle] = useState("");
  const [category, setCategory] = useState<string>("");
  const [notes, setNotes] = useState("");
  const [isStarred, setIsStarred] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [popoverPosition, setPopoverPosition] = useState<{
    top: number;
    left: number;
  } | null>(null);
  const [isVisible, setIsVisible] = useState(false);

  const popoverRef = useRef<HTMLDivElement>(null);
  const titleInputRef = useRef<HTMLInputElement>(null);

  // ─── Detect Text Selection ──────────────────────────────────────────────

  useEffect(() => {
    function handleSelectionChange() {
      const selection = window.getSelection();
      if (!selection || selection.isCollapsed || !selection.toString().trim()) {
        return;
      }

      const text = selection.toString().trim();
      if (text.length < 3) return;

      // Check if selection is within a transcript area
      const range = selection.getRangeAt(0);
      const container = range.commonAncestorContainer as Element;
      const transcriptEl =
        container.closest?.("[data-transcript]") ||
        (container.parentElement?.closest?.("[data-transcript]"));

      if (!transcriptEl) return;

      // Position popover near selection
      const rect = range.getBoundingClientRect();
      setPopoverPosition({
        top: rect.bottom + window.scrollY + 8,
        left: Math.max(16, rect.left + window.scrollX + rect.width / 2 - 160),
      });
      setSelectedText(text);
      setTitle(text.length > 60 ? text.substring(0, 60) + "..." : text);
      setIsVisible(true);
    }

    document.addEventListener("mouseup", handleSelectionChange);
    return () => document.removeEventListener("mouseup", handleSelectionChange);
  }, []);

  // ─── Click Outside ──────────────────────────────────────────────────────

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        popoverRef.current &&
        !popoverRef.current.contains(event.target as Node)
      ) {
        handleClose();
      }
    }

    if (isVisible) {
      // Delay to avoid immediate close from the mouseup that opened it
      const timer = setTimeout(() => {
        document.addEventListener("mousedown", handleClickOutside);
      }, 100);
      return () => {
        clearTimeout(timer);
        document.removeEventListener("mousedown", handleClickOutside);
      };
    }
  }, [isVisible]);

  // Focus title input when visible
  useEffect(() => {
    if (isVisible && titleInputRef.current) {
      titleInputRef.current.focus();
    }
  }, [isVisible]);

  // ─── Handlers ───────────────────────────────────────────────────────────

  const handleClose = useCallback(() => {
    setIsVisible(false);
    setSelectedText("");
    setTitle("");
    setCategory("");
    setNotes("");
    setIsStarred(false);
    onClose?.();
  }, [onClose]);

  const handleSave = useCallback(async () => {
    if (!category || !selectedText || !title.trim()) return;

    setIsSaving(true);
    try {
      const response = await fetch("/api/highlights", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sessionId,
          utteranceId,
          ownerId,
          title: title.trim(),
          category,
          textSelection: selectedText,
          notes: notes.trim() || null,
          isStarred,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        onCreated?.(data.highlight);
        handleClose();
      }
    } catch (error) {
      console.error("Failed to create highlight:", error);
    } finally {
      setIsSaving(false);
    }
  }, [
    sessionId,
    utteranceId,
    ownerId,
    title,
    category,
    selectedText,
    notes,
    isStarred,
    onCreated,
    handleClose,
  ]);

  // ─── Render ─────────────────────────────────────────────────────────────

  if (!isVisible || !popoverPosition) return null;

  return (
    <div
      ref={popoverRef}
      className="fixed z-[100] w-80 rounded-xl border bg-card shadow-xl animate-in fade-in-0 zoom-in-95"
      style={{
        top: popoverPosition.top,
        left: popoverPosition.left,
      }}
      role="dialog"
      aria-label="Create highlight from selected text"
    >
      {/* Header */}
      <div className="flex items-center justify-between p-3 border-b">
        <div className="flex items-center gap-2 text-sm font-medium">
          <Highlighter className="h-4 w-4 text-primary" />
          Create Highlight
        </div>
        <button
          type="button"
          onClick={handleClose}
          className="rounded-md p-1 hover:bg-accent transition-colors"
          aria-label="Close highlight creator"
        >
          <X className="h-4 w-4" />
        </button>
      </div>

      <div className="p-3 space-y-3">
        {/* Selected Text Preview */}
        <div className="rounded-md bg-muted/50 p-2 text-sm italic text-muted-foreground line-clamp-3">
          &ldquo;{selectedText}&rdquo;
        </div>

        {/* Title Input */}
        <div>
          <label htmlFor="highlight-title" className="text-xs font-medium text-muted-foreground mb-1 block">
            Title
          </label>
          <Input
            ref={titleInputRef}
            id="highlight-title"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Give this highlight a title"
            className="h-8 text-sm"
          />
        </div>

        {/* Category Selector */}
        <div>
          <label className="text-xs font-medium text-muted-foreground mb-1.5 block">
            Category
          </label>
          <div className="grid grid-cols-2 gap-1.5" role="radiogroup" aria-label="Highlight category">
            {CATEGORIES.map((cat) => (
              <button
                key={cat.value}
                type="button"
                onClick={() => setCategory(cat.value)}
                className={`flex items-center gap-1.5 rounded-md border px-2.5 py-1.5 text-xs font-medium transition-colors ${
                  category === cat.value
                    ? `${cat.bgColor} ${cat.color} ring-1 ring-current`
                    : "border-border hover:bg-accent/50"
                }`}
                role="radio"
                aria-checked={category === cat.value}
              >
                <span className={category === cat.value ? cat.color : "text-muted-foreground"}>
                  {cat.icon}
                </span>
                {cat.label}
              </button>
            ))}
          </div>
        </div>

        {/* Notes */}
        <div>
          <label htmlFor="highlight-notes" className="text-xs font-medium text-muted-foreground mb-1 block">
            Notes (optional)
          </label>
          <textarea
            id="highlight-notes"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Add context or observations..."
            rows={2}
            className="flex w-full rounded-lg border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring resize-none"
          />
        </div>

        {/* Star Toggle + Save */}
        <div className="flex items-center justify-between pt-1">
          <button
            type="button"
            onClick={() => setIsStarred(!isStarred)}
            className={`flex items-center gap-1.5 rounded-md px-2 py-1 text-sm transition-colors ${
              isStarred
                ? "text-yellow-500"
                : "text-muted-foreground hover:text-yellow-500"
            }`}
            aria-label={isStarred ? "Unstar highlight" : "Star highlight"}
            aria-pressed={isStarred}
          >
            <Star
              className={`h-4 w-4 ${isStarred ? "fill-current" : ""}`}
            />
            {isStarred ? "Starred" : "Star"}
          </button>

          <Button
            size="sm"
            onClick={handleSave}
            disabled={!category || !title.trim() || isSaving}
            className="h-8"
          >
            <Save className="h-3.5 w-3.5 mr-1.5" />
            {isSaving ? "Saving..." : "Save"}
          </Button>
        </div>
      </div>
    </div>
  );
}
