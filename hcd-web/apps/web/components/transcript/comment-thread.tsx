"use client";

import React, { useState, useEffect, useCallback, useRef } from "react";
import { Button } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import {
  MessageSquare,
  Send,
  Edit3,
  Trash2,
  X,
  Check,
  MoreVertical,
  Clock,
  User,
} from "lucide-react";
import { format, formatDistanceToNow } from "date-fns";
import * as Avatar from "@radix-ui/react-avatar";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";

// ─── Types ──────────────────────────────────────────────────────────────────

interface Author {
  id: string;
  name: string | null;
  email: string | null;
  image: string | null;
}

interface Comment {
  id: string;
  sessionId: string;
  utteranceId: string | null;
  authorId: string;
  text: string;
  timestamp: number | null;
  createdAt: string;
  updatedAt: string;
  author: Author;
}

interface CommentThreadProps {
  sessionId: string;
  utteranceId?: string;
  currentUserId: string;
  timestamp?: number;
  isLive?: boolean;
  onCommentCount?: (count: number) => void;
}

// ─── Comment Thread Component ───────────────────────────────────────────────

export function CommentThread({
  sessionId,
  utteranceId,
  currentUserId,
  timestamp,
  isLive = false,
  onCommentCount,
}: CommentThreadProps) {
  const [comments, setComments] = useState<Comment[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [newComment, setNewComment] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editText, setEditText] = useState("");
  const [isExpanded, setIsExpanded] = useState(false);

  const inputRef = useRef<HTMLTextAreaElement>(null);
  const threadRef = useRef<HTMLDivElement>(null);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // ─── Fetch Comments ─────────────────────────────────────────────────────

  const fetchComments = useCallback(async () => {
    try {
      const params = new URLSearchParams({ sessionId });
      if (utteranceId) params.set("utteranceId", utteranceId);

      const response = await fetch(`/api/comments?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        setComments(data.comments);
        onCommentCount?.(data.comments.length);
      }
    } catch (error) {
      console.error("Failed to fetch comments:", error);
    } finally {
      setIsLoading(false);
    }
  }, [sessionId, utteranceId, onCommentCount]);

  useEffect(() => {
    fetchComments();
  }, [fetchComments]);

  // ─── Real-time polling for live sessions ────────────────────────────────

  useEffect(() => {
    if (isLive) {
      pollingRef.current = setInterval(fetchComments, 5000);
      return () => {
        if (pollingRef.current) {
          clearInterval(pollingRef.current);
        }
      };
    }
  }, [isLive, fetchComments]);

  // Scroll to bottom on new comments
  useEffect(() => {
    if (threadRef.current && isExpanded) {
      threadRef.current.scrollTop = threadRef.current.scrollHeight;
    }
  }, [comments, isExpanded]);

  // ─── Add Comment ────────────────────────────────────────────────────────

  const handleSubmit = useCallback(async () => {
    if (!newComment.trim()) return;

    setIsSubmitting(true);
    try {
      const response = await fetch("/api/comments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sessionId,
          utteranceId: utteranceId || null,
          authorId: currentUserId,
          text: newComment.trim(),
          timestamp: timestamp || null,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setComments((prev) => [data.comment, ...prev]);
        setNewComment("");
        onCommentCount?.((comments.length || 0) + 1);
        inputRef.current?.focus();
      }
    } catch (error) {
      console.error("Failed to create comment:", error);
    } finally {
      setIsSubmitting(false);
    }
  }, [sessionId, utteranceId, currentUserId, timestamp, newComment, comments.length, onCommentCount]);

  // ─── Edit Comment ───────────────────────────────────────────────────────

  const startEdit = useCallback((comment: Comment) => {
    setEditingId(comment.id);
    setEditText(comment.text);
  }, []);

  const saveEdit = useCallback(async () => {
    if (!editingId || !editText.trim()) return;

    try {
      const response = await fetch("/api/comments", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          id: editingId,
          text: editText.trim(),
          authorId: currentUserId,
        }),
      });

      if (response.ok) {
        setComments((prev) =>
          prev.map((c) =>
            c.id === editingId
              ? { ...c, text: editText.trim(), updatedAt: new Date().toISOString() }
              : c
          )
        );
        setEditingId(null);
        setEditText("");
      }
    } catch (error) {
      console.error("Failed to update comment:", error);
    }
  }, [editingId, editText, currentUserId]);

  // ─── Delete Comment ─────────────────────────────────────────────────────

  const deleteComment = useCallback(
    async (commentId: string) => {
      try {
        const response = await fetch(
          `/api/comments?id=${commentId}&authorId=${currentUserId}`,
          { method: "DELETE" }
        );

        if (response.ok) {
          setComments((prev) => prev.filter((c) => c.id !== commentId));
          onCommentCount?.(Math.max(0, (comments.length || 0) - 1));
        }
      } catch (error) {
        console.error("Failed to delete comment:", error);
      }
    },
    [currentUserId, comments.length, onCommentCount]
  );

  // ─── Helper: initials from name ─────────────────────────────────────────

  function getInitials(name: string | null): string {
    if (!name) return "?";
    return name
      .split(" ")
      .map((n) => n[0])
      .join("")
      .toUpperCase()
      .slice(0, 2);
  }

  // ─── Collapsed view (just the count) ────────────────────────────────────

  if (!isExpanded) {
    return (
      <button
        type="button"
        onClick={() => setIsExpanded(true)}
        className={`inline-flex items-center gap-1.5 rounded-md px-2 py-1 text-xs transition-colors ${
          comments.length > 0
            ? "text-primary hover:bg-primary/10"
            : "text-muted-foreground hover:bg-accent"
        }`}
        aria-label={`${comments.length} comments. Click to expand.`}
      >
        <MessageSquare className="h-3.5 w-3.5" />
        {comments.length > 0 && <span>{comments.length}</span>}
      </button>
    );
  }

  // ─── Expanded view ──────────────────────────────────────────────────────

  return (
    <div className="w-80 rounded-lg border bg-card shadow-lg" role="region" aria-label="Comments thread">
      {/* Header */}
      <div className="flex items-center justify-between px-3 py-2 border-b">
        <div className="flex items-center gap-2 text-sm font-medium">
          <MessageSquare className="h-4 w-4" />
          Comments ({comments.length})
        </div>
        <button
          type="button"
          onClick={() => setIsExpanded(false)}
          className="p-1 rounded hover:bg-accent transition-colors"
          aria-label="Collapse comments"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>

      {/* Comment List */}
      <div
        ref={threadRef}
        className="max-h-64 overflow-y-auto p-2 space-y-2 scrollbar-thin"
      >
        {isLoading ? (
          <div className="text-xs text-muted-foreground text-center py-4">
            Loading comments...
          </div>
        ) : comments.length === 0 ? (
          <div className="text-xs text-muted-foreground text-center py-4">
            No comments yet. Be the first to add one.
          </div>
        ) : (
          // Reverse to show oldest first
          [...comments].reverse().map((comment) => {
            const isOwn = comment.authorId === currentUserId;
            const isEditingThis = editingId === comment.id;
            const wasEdited =
              comment.updatedAt &&
              comment.createdAt !== comment.updatedAt;

            return (
              <div key={comment.id} className="group flex gap-2">
                {/* Avatar */}
                <Avatar.Root className="h-7 w-7 rounded-full overflow-hidden shrink-0">
                  {comment.author.image ? (
                    <Avatar.Image
                      src={comment.author.image}
                      alt={comment.author.name || "User"}
                      className="h-full w-full object-cover"
                    />
                  ) : null}
                  <Avatar.Fallback className="flex h-full w-full items-center justify-center bg-primary/10 text-xs font-medium text-primary">
                    {getInitials(comment.author.name)}
                  </Avatar.Fallback>
                </Avatar.Root>

                {/* Comment Body */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-1.5">
                    <span className="text-xs font-medium truncate">
                      {comment.author.name || "Unknown"}
                    </span>
                    <span className="text-[10px] text-muted-foreground">
                      {formatDistanceToNow(new Date(comment.createdAt), {
                        addSuffix: true,
                      })}
                    </span>
                    {wasEdited && (
                      <span className="text-[10px] text-muted-foreground italic">
                        (edited)
                      </span>
                    )}
                  </div>

                  {isEditingThis ? (
                    <div className="mt-1 space-y-1">
                      <textarea
                        value={editText}
                        onChange={(e) => setEditText(e.target.value)}
                        className="flex w-full rounded-md border border-input bg-background px-2 py-1 text-xs ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring resize-none"
                        rows={2}
                        aria-label="Edit comment"
                        onKeyDown={(e) => {
                          if (e.key === "Enter" && !e.shiftKey) {
                            e.preventDefault();
                            saveEdit();
                          }
                          if (e.key === "Escape") {
                            setEditingId(null);
                            setEditText("");
                          }
                        }}
                        autoFocus
                      />
                      <div className="flex gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-6 text-xs px-2"
                          onClick={saveEdit}
                        >
                          <Check className="h-3 w-3 mr-1" />
                          Save
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-6 text-xs px-2"
                          onClick={() => {
                            setEditingId(null);
                            setEditText("");
                          }}
                        >
                          Cancel
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <p className="text-xs text-foreground/80 mt-0.5 whitespace-pre-wrap break-words">
                      {comment.text}
                    </p>
                  )}

                  {/* Timestamp anchor */}
                  {comment.timestamp !== null && !isEditingThis && (
                    <span className="inline-flex items-center gap-0.5 text-[10px] text-muted-foreground mt-0.5">
                      <Clock className="h-2.5 w-2.5" />
                      {Math.floor(comment.timestamp / 60)}:
                      {String(Math.floor(comment.timestamp % 60)).padStart(2, "0")}
                    </span>
                  )}
                </div>

                {/* Actions (own comments only) */}
                {isOwn && !isEditingThis && (
                  <DropdownMenu.Root>
                    <DropdownMenu.Trigger asChild>
                      <button
                        type="button"
                        className="p-0.5 rounded opacity-0 group-hover:opacity-100 transition-opacity hover:bg-accent"
                        aria-label="Comment actions"
                      >
                        <MoreVertical className="h-3.5 w-3.5 text-muted-foreground" />
                      </button>
                    </DropdownMenu.Trigger>
                    <DropdownMenu.Portal>
                      <DropdownMenu.Content
                        className="min-w-[120px] rounded-md border bg-card p-1 shadow-md z-[200]"
                        align="end"
                        sideOffset={4}
                      >
                        <DropdownMenu.Item
                          className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs cursor-pointer hover:bg-accent outline-none"
                          onSelect={() => startEdit(comment)}
                        >
                          <Edit3 className="h-3 w-3" />
                          Edit
                        </DropdownMenu.Item>
                        <DropdownMenu.Item
                          className="flex items-center gap-2 rounded-sm px-2 py-1.5 text-xs cursor-pointer hover:bg-accent text-destructive outline-none"
                          onSelect={() => deleteComment(comment.id)}
                        >
                          <Trash2 className="h-3 w-3" />
                          Delete
                        </DropdownMenu.Item>
                      </DropdownMenu.Content>
                    </DropdownMenu.Portal>
                  </DropdownMenu.Root>
                )}
              </div>
            );
          })
        )}
      </div>

      {/* Add Comment Input */}
      <div className="border-t p-2">
        <div className="flex items-end gap-2">
          <textarea
            ref={inputRef}
            value={newComment}
            onChange={(e) => setNewComment(e.target.value)}
            placeholder="Add a comment..."
            rows={1}
            className="flex-1 min-h-[32px] max-h-[80px] rounded-md border border-input bg-background px-2 py-1.5 text-xs ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring resize-none"
            aria-label="Add a comment"
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                handleSubmit();
              }
            }}
            onInput={(e) => {
              const target = e.target as HTMLTextAreaElement;
              target.style.height = "auto";
              target.style.height = Math.min(target.scrollHeight, 80) + "px";
            }}
          />
          <Button
            size="icon"
            className="h-8 w-8 shrink-0"
            onClick={handleSubmit}
            disabled={!newComment.trim() || isSubmitting}
            aria-label="Send comment"
          >
            <Send className="h-3.5 w-3.5" />
          </Button>
        </div>
      </div>

      {/* Live indicator */}
      {isLive && (
        <div className="px-3 pb-2">
          <div className="flex items-center gap-1.5 text-[10px] text-muted-foreground">
            <span className="h-1.5 w-1.5 rounded-full bg-green-500 animate-pulse" />
            Live updates enabled
          </div>
        </div>
      )}
    </div>
  );
}
