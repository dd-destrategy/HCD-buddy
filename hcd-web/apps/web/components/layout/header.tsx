"use client";

import { useState, useEffect, useRef, Fragment } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Search,
  Bell,
  ChevronRight,
  LogOut,
  Settings,
  Wifi,
  WifiOff,
  X,
} from "lucide-react";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { useAuth } from "@/lib/auth-client";

interface Breadcrumb {
  label: string;
  href?: string;
}

function getBreadcrumbs(pathname: string): Breadcrumb[] {
  const segments = pathname.split("/").filter(Boolean);
  const breadcrumbs: Breadcrumb[] = [];

  let currentPath = "";
  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i];
    currentPath += `/${segment}`;

    // Skip route groups
    if (segment.startsWith("(") && segment.endsWith(")")) continue;

    // Skip dynamic segments like [id] for now, but display them
    const label = segment.startsWith("[")
      ? "Details"
      : segment.charAt(0).toUpperCase() + segment.slice(1);

    breadcrumbs.push({
      label,
      href: i < segments.length - 1 ? currentPath : undefined,
    });
  }

  return breadcrumbs;
}

interface HeaderProps {
  /** Whether a live session WebSocket is connected */
  isConnected?: boolean;
}

export function Header({ isConnected }: HeaderProps) {
  const pathname = usePathname();
  const { user, signOut } = useAuth();
  const breadcrumbs = getBreadcrumbs(pathname);
  const [searchOpen, setSearchOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Keyboard shortcut: Cmd+F to open search
  useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
      if ((e.metaKey || e.ctrlKey) && e.key === "f") {
        // Only intercept on dashboard pages, not when in text inputs
        const activeEl = document.activeElement;
        const isInInput =
          activeEl instanceof HTMLInputElement ||
          activeEl instanceof HTMLTextAreaElement;
        if (!isInInput) {
          e.preventDefault();
          setSearchOpen(true);
        }
      }
      if (e.key === "Escape" && searchOpen) {
        setSearchOpen(false);
        setSearchQuery("");
      }
    }
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [searchOpen]);

  // Focus search input when opened
  useEffect(() => {
    if (searchOpen) {
      // Small delay to let the element render
      requestAnimationFrame(() => {
        searchInputRef.current?.focus();
      });
    }
  }, [searchOpen]);

  return (
    <header
      className="sticky top-0 z-30 flex h-14 items-center gap-4 border-b border-border bg-card/80 glass-toolbar px-4 lg:px-6"
      role="banner"
    >
      {/* Breadcrumbs */}
      <nav className="flex items-center gap-1 text-sm" aria-label="Breadcrumb">
        <ol className="flex items-center gap-1">
          {breadcrumbs.map((crumb, index) => (
            <Fragment key={index}>
              {index > 0 && (
                <li aria-hidden="true">
                  <ChevronRight className="h-3.5 w-3.5 text-muted-foreground" />
                </li>
              )}
              <li>
                {crumb.href ? (
                  <Link
                    href={crumb.href}
                    className="text-muted-foreground hover:text-foreground transition-colors"
                  >
                    {crumb.label}
                  </Link>
                ) : (
                  <span className="font-medium">{crumb.label}</span>
                )}
              </li>
            </Fragment>
          ))}
        </ol>
      </nav>

      {/* Spacer */}
      <div className="flex-1" />

      {/* Search */}
      {searchOpen ? (
        <div className="relative flex items-center">
          <Search className="absolute left-3 h-4 w-4 text-muted-foreground" />
          <input
            ref={searchInputRef}
            type="search"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search transcripts..."
            className="h-9 w-64 rounded-lg border border-input bg-background pl-9 pr-9 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            aria-label="Search transcripts"
          />
          <button
            onClick={() => {
              setSearchOpen(false);
              setSearchQuery("");
            }}
            className="absolute right-2 rounded p-0.5 text-muted-foreground hover:text-foreground transition-colors"
            aria-label="Close search"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      ) : (
        <button
          onClick={() => setSearchOpen(true)}
          className="flex h-9 items-center gap-2 rounded-lg border border-input bg-background px-3 text-sm text-muted-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
          aria-label="Search transcripts (Cmd+F)"
        >
          <Search className="h-4 w-4" />
          <span className="hidden sm:inline">Search...</span>
          <span className="kbd hidden lg:inline-flex" aria-hidden="true">
            F
          </span>
        </button>
      )}

      {/* Connection status */}
      {isConnected !== undefined && (
        <div
          className={`flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${
            isConnected
              ? "bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
              : "bg-muted text-muted-foreground"
          }`}
          role="status"
          aria-label={isConnected ? "Connected" : "Disconnected"}
        >
          {isConnected ? (
            <Wifi className="h-3 w-3" />
          ) : (
            <WifiOff className="h-3 w-3" />
          )}
          <span className="hidden sm:inline">
            {isConnected ? "Live" : "Offline"}
          </span>
        </div>
      )}

      {/* Notifications */}
      <button
        className="relative flex h-9 w-9 items-center justify-center rounded-lg text-muted-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
        aria-label="Notifications"
      >
        <Bell className="h-5 w-5" />
        {/* Notification badge placeholder */}
        {/* <span className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-destructive" /> */}
      </button>

      {/* User dropdown */}
      <DropdownMenu.Root>
        <DropdownMenu.Trigger asChild>
          <button
            className="flex h-8 w-8 items-center justify-center rounded-full bg-primary/10 text-primary text-xs font-semibold hover:bg-primary/20 transition-colors"
            aria-label="User menu"
          >
            {user?.name
              ? user.name
                  .split(" ")
                  .map((n) => n[0])
                  .join("")
                  .toUpperCase()
                  .slice(0, 2)
              : "?"}
          </button>
        </DropdownMenu.Trigger>
        <DropdownMenu.Portal>
          <DropdownMenu.Content
            className="z-50 min-w-[200px] rounded-xl border border-border bg-card p-1 shadow-lg animate-fade-in"
            side="bottom"
            align="end"
            sideOffset={8}
          >
            <DropdownMenu.Label className="px-2 py-1.5">
              <p className="text-sm font-medium">{user?.name || "User"}</p>
              <p className="text-xs text-muted-foreground">
                {user?.email || ""}
              </p>
            </DropdownMenu.Label>
            <DropdownMenu.Separator className="my-1 h-px bg-border" />
            <DropdownMenu.Item asChild>
              <Link
                href="/settings"
                className="flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-sm outline-none hover:bg-accent focus:bg-accent"
              >
                <Settings className="h-4 w-4" />
                Settings
              </Link>
            </DropdownMenu.Item>
            <DropdownMenu.Separator className="my-1 h-px bg-border" />
            <DropdownMenu.Item
              className="flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-sm text-destructive outline-none hover:bg-destructive/10 focus:bg-destructive/10"
              onSelect={() => signOut()}
            >
              <LogOut className="h-4 w-4" />
              Sign out
            </DropdownMenu.Item>
          </DropdownMenu.Content>
        </DropdownMenu.Portal>
      </DropdownMenu.Root>
    </header>
  );
}
