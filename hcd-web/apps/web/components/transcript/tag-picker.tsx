"use client";

import React, { useState, useCallback, useRef, useEffect, useMemo } from "react";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import {
  Tag,
  Plus,
  Search,
  Check,
  ChevronRight,
  X,
  Palette,
} from "lucide-react";

// ─── Types ──────────────────────────────────────────────────────────────────

interface TagItem {
  id: string;
  name: string;
  color: string | null;
  parentId: string | null;
  organizationId: string | null;
  children: TagItem[];
}

interface TagPickerProps {
  organizationId: string;
  selectedTagIds: string[];
  onTagsChange: (tagIds: string[]) => void;
  utteranceId?: string;
  compact?: boolean;
}

const TAG_COLORS = [
  "#ef4444", // red
  "#f97316", // orange
  "#eab308", // yellow
  "#22c55e", // green
  "#06b6d4", // cyan
  "#3b82f6", // blue
  "#6366f1", // indigo
  "#a855f7", // purple
  "#ec4899", // pink
  "#6b7280", // gray
];

// ─── Tag Picker Component ───────────────────────────────────────────────────

export function TagPicker({
  organizationId,
  selectedTagIds,
  onTagsChange,
  utteranceId,
  compact = false,
}: TagPickerProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [tags, setTags] = useState<TagItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [newTagName, setNewTagName] = useState("");
  const [newTagColor, setNewTagColor] = useState(TAG_COLORS[6]);
  const [focusedIndex, setFocusedIndex] = useState(-1);

  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);
  const listRef = useRef<HTMLDivElement>(null);

  // ─── Fetch Tags ─────────────────────────────────────────────────────────

  const fetchTags = useCallback(async () => {
    setIsLoading(true);
    try {
      const response = await fetch(
        `/api/tags?organizationId=${organizationId}`
      );
      if (response.ok) {
        const data = await response.json();
        setTags(data.tags);
      }
    } catch (error) {
      console.error("Failed to fetch tags:", error);
    } finally {
      setIsLoading(false);
    }
  }, [organizationId]);

  useEffect(() => {
    if (isOpen) {
      fetchTags();
    }
  }, [isOpen, fetchTags]);

  // ─── Flatten tags for filtering ─────────────────────────────────────────

  const flattenedTags = useMemo(() => {
    const result: Array<TagItem & { depth: number; parentName?: string }> = [];

    function walk(items: TagItem[], depth: number, parentName?: string) {
      for (const item of items) {
        result.push({ ...item, depth, parentName });
        if (item.children && item.children.length > 0) {
          walk(item.children, depth + 1, item.name);
        }
      }
    }

    walk(tags, 0);
    return result;
  }, [tags]);

  const filteredTags = useMemo(() => {
    if (!search.trim()) return flattenedTags;
    const query = search.toLowerCase();
    return flattenedTags.filter(
      (tag) =>
        tag.name.toLowerCase().includes(query) ||
        tag.parentName?.toLowerCase().includes(query)
    );
  }, [flattenedTags, search]);

  // ─── Selection Handlers ─────────────────────────────────────────────────

  const toggleTag = useCallback(
    (tagId: string) => {
      const newIds = selectedTagIds.includes(tagId)
        ? selectedTagIds.filter((id) => id !== tagId)
        : [...selectedTagIds, tagId];
      onTagsChange(newIds);
    },
    [selectedTagIds, onTagsChange]
  );

  const removeTag = useCallback(
    (tagId: string) => {
      onTagsChange(selectedTagIds.filter((id) => id !== tagId));
    },
    [selectedTagIds, onTagsChange]
  );

  // ─── Create Tag ─────────────────────────────────────────────────────────

  const handleCreateTag = useCallback(async () => {
    if (!newTagName.trim()) return;

    try {
      const response = await fetch("/api/tags", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: newTagName.trim(),
          color: newTagColor,
          organizationId,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setTags((prev) => [...prev, { ...data.tag, children: [] }]);
        onTagsChange([...selectedTagIds, data.tag.id]);
        setNewTagName("");
        setIsCreating(false);
      }
    } catch (error) {
      console.error("Failed to create tag:", error);
    }
  }, [newTagName, newTagColor, organizationId, selectedTagIds, onTagsChange]);

  // ─── Keyboard Navigation ────────────────────────────────────────────────

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (!isOpen) {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          setIsOpen(true);
        }
        return;
      }

      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          setFocusedIndex((prev) =>
            Math.min(prev + 1, filteredTags.length - 1)
          );
          break;
        case "ArrowUp":
          e.preventDefault();
          setFocusedIndex((prev) => Math.max(prev - 1, 0));
          break;
        case "Enter":
          e.preventDefault();
          if (focusedIndex >= 0 && focusedIndex < filteredTags.length) {
            toggleTag(filteredTags[focusedIndex].id);
          }
          break;
        case "Escape":
          e.preventDefault();
          setIsOpen(false);
          setSearch("");
          setFocusedIndex(-1);
          break;
      }
    },
    [isOpen, filteredTags, focusedIndex, toggleTag]
  );

  // ─── Click Outside ──────────────────────────────────────────────────────

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (
        containerRef.current &&
        !containerRef.current.contains(event.target as Node)
      ) {
        setIsOpen(false);
        setSearch("");
        setIsCreating(false);
      }
    }

    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside);
      return () =>
        document.removeEventListener("mousedown", handleClickOutside);
    }
  }, [isOpen]);

  // Focus search when opened
  useEffect(() => {
    if (isOpen && searchInputRef.current) {
      searchInputRef.current.focus();
    }
  }, [isOpen]);

  // Scroll focused item into view
  useEffect(() => {
    if (focusedIndex >= 0 && listRef.current) {
      const items = listRef.current.querySelectorAll("[data-tag-item]");
      items[focusedIndex]?.scrollIntoView({ block: "nearest" });
    }
  }, [focusedIndex]);

  // ─── Selected tag objects ───────────────────────────────────────────────

  const selectedTags = useMemo(
    () => flattenedTags.filter((t) => selectedTagIds.includes(t.id)),
    [flattenedTags, selectedTagIds]
  );

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <div ref={containerRef} className="relative inline-block" onKeyDown={handleKeyDown}>
      {/* Trigger */}
      <button
        type="button"
        onClick={() => setIsOpen(!isOpen)}
        className="inline-flex items-center gap-1.5 rounded-md border border-input bg-background px-2 py-1 text-sm hover:bg-accent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        aria-label="Select tags"
        aria-expanded={isOpen}
        aria-haspopup="listbox"
      >
        <Tag className="h-3.5 w-3.5 text-muted-foreground" />
        {compact ? (
          selectedTagIds.length > 0 && (
            <span className="text-xs text-muted-foreground">
              {selectedTagIds.length}
            </span>
          )
        ) : selectedTags.length > 0 ? (
          <span className="flex items-center gap-1 flex-wrap">
            {selectedTags.slice(0, 3).map((tag) => (
              <span
                key={tag.id}
                className="inline-flex items-center gap-1 rounded-full bg-secondary px-1.5 py-0.5 text-xs"
              >
                <span
                  className="h-2 w-2 rounded-full shrink-0"
                  style={{ backgroundColor: tag.color || "#6366f1" }}
                />
                {tag.name}
                <button
                  type="button"
                  onClick={(e) => {
                    e.stopPropagation();
                    removeTag(tag.id);
                  }}
                  className="ml-0.5 hover:text-destructive"
                  aria-label={`Remove tag ${tag.name}`}
                >
                  <X className="h-2.5 w-2.5" />
                </button>
              </span>
            ))}
            {selectedTags.length > 3 && (
              <span className="text-xs text-muted-foreground">
                +{selectedTags.length - 3}
              </span>
            )}
          </span>
        ) : (
          <span className="text-muted-foreground text-xs">Add tags</span>
        )}
      </button>

      {/* Dropdown */}
      {isOpen && (
        <div
          className="absolute z-50 mt-1 w-64 rounded-lg border bg-card shadow-lg"
          role="listbox"
          aria-label="Available tags"
          aria-multiselectable="true"
        >
          {/* Search */}
          <div className="p-2 border-b">
            <div className="relative">
              <Search className="absolute left-2 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground" />
              <Input
                ref={searchInputRef}
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setFocusedIndex(-1);
                }}
                placeholder="Search tags..."
                className="h-8 pl-7 text-sm"
                aria-label="Search tags"
              />
            </div>
          </div>

          {/* Tag List */}
          <div ref={listRef} className="max-h-48 overflow-y-auto p-1 scrollbar-thin">
            {isLoading ? (
              <div className="p-3 text-sm text-muted-foreground text-center">
                Loading tags...
              </div>
            ) : filteredTags.length === 0 ? (
              <div className="p-3 text-sm text-muted-foreground text-center">
                {search ? "No tags match your search" : "No tags yet"}
              </div>
            ) : (
              filteredTags.map((tag, index) => {
                const isSelected = selectedTagIds.includes(tag.id);
                const isFocused = index === focusedIndex;
                return (
                  <button
                    key={tag.id}
                    type="button"
                    data-tag-item
                    onClick={() => toggleTag(tag.id)}
                    className={`w-full flex items-center gap-2 rounded-md px-2 py-1.5 text-sm text-left transition-colors ${
                      isFocused
                        ? "bg-accent"
                        : isSelected
                        ? "bg-accent/50"
                        : "hover:bg-accent/50"
                    }`}
                    role="option"
                    aria-selected={isSelected}
                    style={{ paddingLeft: `${(tag.depth * 16) + 8}px` }}
                  >
                    <span
                      className="h-3 w-3 rounded-full shrink-0 border border-black/10"
                      style={{ backgroundColor: tag.color || "#6366f1" }}
                    />
                    <span className="flex-1 truncate">
                      {tag.parentName && (
                        <span className="text-muted-foreground text-xs">
                          {tag.parentName}
                          <ChevronRight className="inline h-3 w-3 mx-0.5" />
                        </span>
                      )}
                      {tag.name}
                    </span>
                    {isSelected && (
                      <Check className="h-3.5 w-3.5 text-primary shrink-0" />
                    )}
                  </button>
                );
              })
            )}
          </div>

          {/* Create New Tag */}
          <div className="border-t p-2">
            {isCreating ? (
              <div className="space-y-2">
                <Input
                  value={newTagName}
                  onChange={(e) => setNewTagName(e.target.value)}
                  placeholder="Tag name"
                  className="h-8 text-sm"
                  aria-label="New tag name"
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      handleCreateTag();
                    }
                    if (e.key === "Escape") {
                      e.preventDefault();
                      setIsCreating(false);
                      setNewTagName("");
                    }
                  }}
                  autoFocus
                />
                {/* Color Picker */}
                <div className="flex items-center gap-1 flex-wrap" role="radiogroup" aria-label="Tag color">
                  {TAG_COLORS.map((color) => (
                    <button
                      key={color}
                      type="button"
                      onClick={() => setNewTagColor(color)}
                      className={`h-5 w-5 rounded-full border-2 transition-transform ${
                        newTagColor === color
                          ? "border-foreground scale-110"
                          : "border-transparent hover:scale-105"
                      }`}
                      style={{ backgroundColor: color }}
                      role="radio"
                      aria-checked={newTagColor === color}
                      aria-label={`Color ${color}`}
                    />
                  ))}
                </div>
                <div className="flex gap-1">
                  <Button
                    size="sm"
                    onClick={handleCreateTag}
                    disabled={!newTagName.trim()}
                    className="h-7 text-xs flex-1"
                  >
                    Create
                  </Button>
                  <Button
                    size="sm"
                    variant="ghost"
                    onClick={() => {
                      setIsCreating(false);
                      setNewTagName("");
                    }}
                    className="h-7 text-xs"
                  >
                    Cancel
                  </Button>
                </div>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => setIsCreating(true)}
                className="w-full flex items-center gap-2 rounded-md px-2 py-1.5 text-sm text-muted-foreground hover:bg-accent/50 transition-colors"
              >
                <Plus className="h-3.5 w-3.5" />
                Create new tag
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
