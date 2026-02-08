"use client";

import React, { useState, useEffect, useCallback, useMemo } from "react";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import { Card, CardContent, CardHeader } from "@hcd/ui";
import {
  Search,
  Star,
  Grid3X3,
  List,
  Filter,
  AlertTriangle,
  Heart,
  Lightbulb,
  Wrench,
  Sparkles,
  Quote,
  Calendar,
  Download,
  Trash2,
  X,
  ChevronDown,
  Highlighter,
  SlidersHorizontal,
} from "lucide-react";
import { format } from "date-fns";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Highlight {
  id: string;
  sessionId: string;
  utteranceId: string | null;
  ownerId: string | null;
  title: string;
  category: string;
  textSelection: string;
  notes: string | null;
  isStarred: boolean;
  createdAt: string;
  sessionTitle: string | null;
}

type ViewMode = "grid" | "list";
type FilterTab = "all" | "starred";

const CATEGORIES = [
  { label: "Pain Point", value: "Pain Point", icon: AlertTriangle, color: "text-red-600", bg: "bg-red-100 dark:bg-red-900" },
  { label: "User Need", value: "User Need", icon: Heart, color: "text-blue-600", bg: "bg-blue-100 dark:bg-blue-900" },
  { label: "Delight", value: "Delight", icon: Sparkles, color: "text-green-600", bg: "bg-green-100 dark:bg-green-900" },
  { label: "Workaround", value: "Workaround", icon: Wrench, color: "text-orange-600", bg: "bg-orange-100 dark:bg-orange-900" },
  { label: "Feature Request", value: "Feature Request", icon: Lightbulb, color: "text-purple-600", bg: "bg-purple-100 dark:bg-purple-900" },
  { label: "Key Quote", value: "Key Quote", icon: Quote, color: "text-indigo-600", bg: "bg-indigo-100 dark:bg-indigo-900" },
];

function getCategoryMeta(category: string) {
  return CATEGORIES.find((c) => c.value === category) || CATEGORIES[0];
}

// ─── Library Page ───────────────────────────────────────────────────────────

export default function LibraryPage() {
  const [highlights, setHighlights] = useState<Highlight[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [total, setTotal] = useState(0);

  // Filters
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState<string>("");
  const [starredFilter, setStarredFilter] = useState<FilterTab>("all");
  const [dateFrom, setDateFrom] = useState("");
  const [dateTo, setDateTo] = useState("");
  const [sortBy, setSortBy] = useState("date");
  const [showFilters, setShowFilters] = useState(false);

  // View
  const [viewMode, setViewMode] = useState<ViewMode>("grid");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

  // ─── Fetch Highlights ───────────────────────────────────────────────────

  const fetchHighlights = useCallback(async () => {
    setIsLoading(true);
    try {
      const params = new URLSearchParams();
      if (search) params.set("search", search);
      if (categoryFilter) params.set("category", categoryFilter);
      if (starredFilter === "starred") params.set("starred", "true");
      if (dateFrom) params.set("dateFrom", dateFrom);
      if (dateTo) params.set("dateTo", dateTo);
      params.set("sortBy", sortBy);
      params.set("limit", "100");

      const response = await fetch(`/api/highlights?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        setHighlights(data.highlights);
        setTotal(data.total);
      }
    } catch (error) {
      console.error("Failed to fetch highlights:", error);
    } finally {
      setIsLoading(false);
    }
  }, [search, categoryFilter, starredFilter, dateFrom, dateTo, sortBy]);

  useEffect(() => {
    const debounce = setTimeout(fetchHighlights, 300);
    return () => clearTimeout(debounce);
  }, [fetchHighlights]);

  // ─── Selection Handlers ─────────────────────────────────────────────────

  const toggleSelect = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  }, []);

  const selectAll = useCallback(() => {
    if (selectedIds.size === highlights.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(highlights.map((h) => h.id)));
    }
  }, [selectedIds, highlights]);

  // ─── Star Toggle ────────────────────────────────────────────────────────

  const toggleStar = useCallback(
    async (id: string, currentStarred: boolean) => {
      try {
        const response = await fetch("/api/highlights", {
          method: "PATCH",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ id, isStarred: !currentStarred }),
        });

        if (response.ok) {
          setHighlights((prev) =>
            prev.map((h) =>
              h.id === id ? { ...h, isStarred: !currentStarred } : h
            )
          );
        }
      } catch (error) {
        console.error("Failed to toggle star:", error);
      }
    },
    []
  );

  // ─── Bulk Actions ───────────────────────────────────────────────────────

  const handleBulkDelete = useCallback(async () => {
    if (selectedIds.size === 0) return;
    if (!confirm(`Delete ${selectedIds.size} selected highlight(s)?`)) return;

    try {
      const ids = Array.from(selectedIds).join(",");
      const response = await fetch(`/api/highlights?ids=${ids}`, {
        method: "DELETE",
      });

      if (response.ok) {
        setHighlights((prev) => prev.filter((h) => !selectedIds.has(h.id)));
        setSelectedIds(new Set());
      }
    } catch (error) {
      console.error("Failed to delete highlights:", error);
    }
  }, [selectedIds]);

  const handleBulkExport = useCallback(() => {
    const selected = highlights.filter((h) => selectedIds.has(h.id));
    const exportData = selected.map((h) => ({
      title: h.title,
      category: h.category,
      quote: h.textSelection,
      notes: h.notes,
      session: h.sessionTitle,
      date: h.createdAt,
      starred: h.isStarred,
    }));

    const blob = new Blob([JSON.stringify(exportData, null, 2)], {
      type: "application/json",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `highlights-export-${format(new Date(), "yyyy-MM-dd")}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }, [selectedIds, highlights]);

  // ─── Render ─────────────────────────────────────────────────────────────

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="border-b px-6 py-4">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-2xl font-semibold">Quote Library</h1>
            <p className="text-sm text-muted-foreground mt-1">
              Browse and manage highlights across all sessions
            </p>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant={viewMode === "grid" ? "secondary" : "ghost"}
              size="icon"
              onClick={() => setViewMode("grid")}
              aria-label="Grid view"
            >
              <Grid3X3 className="h-4 w-4" />
            </Button>
            <Button
              variant={viewMode === "list" ? "secondary" : "ghost"}
              size="icon"
              onClick={() => setViewMode("list")}
              aria-label="List view"
            >
              <List className="h-4 w-4" />
            </Button>
          </div>
        </div>

        {/* Tabs + Search */}
        <div className="flex items-center gap-3 flex-wrap">
          {/* Filter Tabs */}
          <div className="flex rounded-lg border overflow-hidden" role="tablist">
            <button
              role="tab"
              aria-selected={starredFilter === "all"}
              className={`px-3 py-1.5 text-sm font-medium transition-colors ${
                starredFilter === "all"
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-accent"
              }`}
              onClick={() => setStarredFilter("all")}
            >
              All ({total})
            </button>
            <button
              role="tab"
              aria-selected={starredFilter === "starred"}
              className={`px-3 py-1.5 text-sm font-medium transition-colors flex items-center gap-1 ${
                starredFilter === "starred"
                  ? "bg-primary text-primary-foreground"
                  : "hover:bg-accent"
              }`}
              onClick={() => setStarredFilter("starred")}
            >
              <Star className="h-3.5 w-3.5" />
              Starred
            </button>
          </div>

          {/* Search */}
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search highlights..."
              className="pl-9"
              aria-label="Search highlights"
            />
          </div>

          {/* Filter Toggle */}
          <Button
            variant={showFilters ? "secondary" : "outline"}
            size="sm"
            onClick={() => setShowFilters(!showFilters)}
          >
            <SlidersHorizontal className="h-4 w-4 mr-1.5" />
            Filters
            {(categoryFilter || dateFrom || dateTo) && (
              <span className="ml-1.5 h-4 w-4 rounded-full bg-primary text-primary-foreground text-xs flex items-center justify-center">
                {[categoryFilter, dateFrom, dateTo].filter(Boolean).length}
              </span>
            )}
          </Button>

          {/* Sort */}
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value)}
            className="h-9 rounded-lg border border-input bg-background px-3 text-sm"
            aria-label="Sort highlights by"
          >
            <option value="date">Sort by Date</option>
            <option value="category">Sort by Category</option>
            <option value="session">Sort by Session</option>
          </select>
        </div>

        {/* Extended Filters */}
        {showFilters && (
          <div className="flex items-center gap-3 mt-3 pt-3 border-t flex-wrap">
            {/* Category filter */}
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">Category</label>
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="h-8 rounded-md border border-input bg-background px-2 text-sm"
                aria-label="Filter by category"
              >
                <option value="">All categories</option>
                {CATEGORIES.map((cat) => (
                  <option key={cat.value} value={cat.value}>
                    {cat.label}
                  </option>
                ))}
              </select>
            </div>

            {/* Date range */}
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">From</label>
              <input
                type="date"
                value={dateFrom}
                onChange={(e) => setDateFrom(e.target.value)}
                className="h-8 rounded-md border border-input bg-background px-2 text-sm"
                aria-label="Date from"
              />
            </div>
            <div>
              <label className="text-xs text-muted-foreground mb-1 block">To</label>
              <input
                type="date"
                value={dateTo}
                onChange={(e) => setDateTo(e.target.value)}
                className="h-8 rounded-md border border-input bg-background px-2 text-sm"
                aria-label="Date to"
              />
            </div>

            {/* Clear filters */}
            {(categoryFilter || dateFrom || dateTo) && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => {
                  setCategoryFilter("");
                  setDateFrom("");
                  setDateTo("");
                }}
                className="mt-4"
              >
                <X className="h-3.5 w-3.5 mr-1" />
                Clear
              </Button>
            )}
          </div>
        )}
      </div>

      {/* Bulk Actions Bar */}
      {selectedIds.size > 0 && (
        <div className="bg-muted/50 border-b px-6 py-2 flex items-center gap-3">
          <input
            type="checkbox"
            checked={selectedIds.size === highlights.length}
            onChange={selectAll}
            className="rounded"
            aria-label="Select all highlights"
          />
          <span className="text-sm text-muted-foreground">
            {selectedIds.size} selected
          </span>
          <div className="flex-1" />
          <Button variant="outline" size="sm" onClick={handleBulkExport}>
            <Download className="h-3.5 w-3.5 mr-1.5" />
            Export
          </Button>
          <Button variant="destructive" size="sm" onClick={handleBulkDelete}>
            <Trash2 className="h-3.5 w-3.5 mr-1.5" />
            Delete
          </Button>
        </div>
      )}

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-6 scrollbar-thin">
        {isLoading ? (
          <div className="flex items-center justify-center h-40">
            <div className="text-sm text-muted-foreground">Loading highlights...</div>
          </div>
        ) : highlights.length === 0 ? (
          /* Empty State */
          <div className="flex flex-col items-center justify-center h-64 text-center">
            <div className="rounded-full bg-muted p-4 mb-4">
              <Highlighter className="h-8 w-8 text-muted-foreground" />
            </div>
            <h3 className="text-lg font-medium mb-1">No highlights yet</h3>
            <p className="text-sm text-muted-foreground max-w-sm">
              {search || categoryFilter
                ? "No highlights match your current filters. Try adjusting your search criteria."
                : "Start by selecting text in a session transcript and creating your first highlight."}
            </p>
            {(search || categoryFilter) && (
              <Button
                variant="outline"
                size="sm"
                className="mt-4"
                onClick={() => {
                  setSearch("");
                  setCategoryFilter("");
                  setDateFrom("");
                  setDateTo("");
                  setStarredFilter("all");
                }}
              >
                Clear all filters
              </Button>
            )}
          </div>
        ) : viewMode === "grid" ? (
          /* Grid View */
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {highlights.map((highlight) => {
              const catMeta = getCategoryMeta(highlight.category);
              const CatIcon = catMeta.icon;
              return (
                <Card
                  key={highlight.id}
                  className={`group relative transition-shadow hover:shadow-md ${
                    selectedIds.has(highlight.id) ? "ring-2 ring-primary" : ""
                  }`}
                >
                  <CardHeader className="pb-2">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-2">
                        <input
                          type="checkbox"
                          checked={selectedIds.has(highlight.id)}
                          onChange={() => toggleSelect(highlight.id)}
                          className="rounded opacity-0 group-hover:opacity-100 transition-opacity"
                          aria-label={`Select ${highlight.title}`}
                        />
                        <Badge className={`${catMeta.bg} ${catMeta.color} border-0 text-xs`}>
                          <CatIcon className="h-3 w-3 mr-1" />
                          {highlight.category}
                        </Badge>
                      </div>
                      <button
                        type="button"
                        onClick={() => toggleStar(highlight.id, highlight.isStarred)}
                        className={`p-1 rounded-md transition-colors ${
                          highlight.isStarred
                            ? "text-yellow-500"
                            : "text-muted-foreground/40 hover:text-yellow-500"
                        }`}
                        aria-label={highlight.isStarred ? "Unstar" : "Star"}
                      >
                        <Star
                          className={`h-4 w-4 ${
                            highlight.isStarred ? "fill-current" : ""
                          }`}
                        />
                      </button>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <h3 className="font-medium text-sm mb-2 line-clamp-1">
                      {highlight.title}
                    </h3>
                    <blockquote className="text-sm text-muted-foreground italic border-l-2 border-muted pl-3 mb-3 line-clamp-3">
                      &ldquo;{highlight.textSelection}&rdquo;
                    </blockquote>
                    {highlight.notes && (
                      <p className="text-xs text-muted-foreground line-clamp-2 mb-2">
                        {highlight.notes}
                      </p>
                    )}
                    <div className="flex items-center justify-between text-xs text-muted-foreground pt-2 border-t">
                      <span className="truncate max-w-[120px]">
                        {highlight.sessionTitle || "Untitled session"}
                      </span>
                      <span>
                        {format(new Date(highlight.createdAt), "MMM d, yyyy")}
                      </span>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        ) : (
          /* List View */
          <div className="space-y-2">
            {highlights.map((highlight) => {
              const catMeta = getCategoryMeta(highlight.category);
              const CatIcon = catMeta.icon;
              return (
                <div
                  key={highlight.id}
                  className={`flex items-start gap-3 rounded-lg border p-3 transition-colors hover:bg-accent/30 ${
                    selectedIds.has(highlight.id) ? "ring-2 ring-primary bg-accent/20" : ""
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={selectedIds.has(highlight.id)}
                    onChange={() => toggleSelect(highlight.id)}
                    className="rounded mt-1"
                    aria-label={`Select ${highlight.title}`}
                  />
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <Badge className={`${catMeta.bg} ${catMeta.color} border-0 text-xs`}>
                        <CatIcon className="h-3 w-3 mr-1" />
                        {highlight.category}
                      </Badge>
                      <span className="font-medium text-sm truncate">
                        {highlight.title}
                      </span>
                    </div>
                    <p className="text-sm text-muted-foreground italic line-clamp-2">
                      &ldquo;{highlight.textSelection}&rdquo;
                    </p>
                    {highlight.notes && (
                      <p className="text-xs text-muted-foreground mt-1 line-clamp-1">
                        {highlight.notes}
                      </p>
                    )}
                  </div>
                  <div className="flex items-center gap-2 shrink-0">
                    <span className="text-xs text-muted-foreground">
                      {highlight.sessionTitle || "Untitled"}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      {format(new Date(highlight.createdAt), "MMM d")}
                    </span>
                    <button
                      type="button"
                      onClick={() => toggleStar(highlight.id, highlight.isStarred)}
                      className={`p-1 rounded-md transition-colors ${
                        highlight.isStarred
                          ? "text-yellow-500"
                          : "text-muted-foreground/40 hover:text-yellow-500"
                      }`}
                      aria-label={highlight.isStarred ? "Unstar" : "Star"}
                    >
                      <Star
                        className={`h-4 w-4 ${
                          highlight.isStarred ? "fill-current" : ""
                        }`}
                      />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
