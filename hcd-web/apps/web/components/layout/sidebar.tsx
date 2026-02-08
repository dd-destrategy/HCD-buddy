"use client";

import { useState, useEffect, useCallback } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Mic,
  LayoutList,
  BookOpen,
  BarChart3,
  Users,
  FolderOpen,
  Settings,
  ChevronsLeft,
  ChevronsRight,
  LogOut,
  ChevronDown,
  Building2,
  Plus,
  Check,
} from "lucide-react";
import * as DropdownMenu from "@radix-ui/react-dropdown-menu";
import { useAuth } from "@/lib/auth-client";

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
  shortcut?: string;
}

const navItems: NavItem[] = [
  {
    label: "Sessions",
    href: "/sessions",
    icon: <LayoutList className="h-5 w-5" />,
    shortcut: "1",
  },
  {
    label: "Library",
    href: "/library",
    icon: <BookOpen className="h-5 w-5" />,
    shortcut: "2",
  },
  {
    label: "Analytics",
    href: "/analytics",
    icon: <BarChart3 className="h-5 w-5" />,
    shortcut: "3",
  },
  {
    label: "Participants",
    href: "/participants",
    icon: <Users className="h-5 w-5" />,
    shortcut: "4",
  },
  {
    label: "Studies",
    href: "/studies",
    icon: <FolderOpen className="h-5 w-5" />,
    shortcut: "5",
  },
  {
    label: "Settings",
    href: "/settings",
    icon: <Settings className="h-5 w-5" />,
    shortcut: ",",
  },
];

// Placeholder organizations
const organizations = [
  { id: "personal", name: "Personal", role: "owner" },
];

export function Sidebar() {
  const pathname = usePathname();
  const { user, signOut } = useAuth();
  const [collapsed, setCollapsed] = useState(false);
  const [activeOrg, setActiveOrg] = useState(organizations[0]);

  // Keyboard shortcut: Cmd+B to toggle sidebar
  const handleKeyDown = useCallback(
    (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "b") {
        e.preventDefault();
        setCollapsed((prev) => !prev);
      }
    },
    []
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [handleKeyDown]);

  const isActive = (href: string) => {
    if (href === "/settings") {
      return pathname.startsWith("/settings");
    }
    return pathname === href || pathname.startsWith(href + "/");
  };

  return (
    <aside
      className={`fixed left-0 top-0 z-40 flex h-full flex-col border-r border-border bg-card transition-all duration-200 ${
        collapsed ? "w-16" : "w-64"
      }`}
      role="navigation"
      aria-label="Main navigation"
    >
      {/* Organization switcher */}
      <div className="flex h-14 items-center border-b border-border px-3">
        <DropdownMenu.Root>
          <DropdownMenu.Trigger asChild>
            <button
              className={`flex items-center gap-2 rounded-lg px-2 py-1.5 text-sm font-medium hover:bg-accent transition-colors w-full ${
                collapsed ? "justify-center" : ""
              }`}
              aria-label="Switch organization"
            >
              <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-md bg-primary text-primary-foreground">
                <Mic className="h-3.5 w-3.5" />
              </div>
              {!collapsed && (
                <>
                  <span className="truncate flex-1 text-left">
                    {activeOrg.name}
                  </span>
                  <ChevronDown className="h-4 w-4 shrink-0 text-muted-foreground" />
                </>
              )}
            </button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Portal>
            <DropdownMenu.Content
              className="z-50 min-w-[220px] rounded-xl border border-border bg-card p-1 shadow-lg animate-fade-in"
              side="bottom"
              align="start"
              sideOffset={4}
            >
              <DropdownMenu.Label className="px-2 py-1.5 text-xs font-medium text-muted-foreground">
                Organizations
              </DropdownMenu.Label>
              {organizations.map((org) => (
                <DropdownMenu.Item
                  key={org.id}
                  className="flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-sm outline-none hover:bg-accent focus:bg-accent"
                  onSelect={() => setActiveOrg(org)}
                >
                  <div className="flex h-6 w-6 items-center justify-center rounded bg-primary/10 text-primary">
                    <Building2 className="h-3.5 w-3.5" />
                  </div>
                  <span className="flex-1">{org.name}</span>
                  {org.id === activeOrg.id && (
                    <Check className="h-4 w-4 text-primary" />
                  )}
                </DropdownMenu.Item>
              ))}
              <DropdownMenu.Separator className="my-1 h-px bg-border" />
              <DropdownMenu.Item className="flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-sm outline-none hover:bg-accent focus:bg-accent text-muted-foreground">
                <Plus className="h-4 w-4" />
                Create organization
              </DropdownMenu.Item>
            </DropdownMenu.Content>
          </DropdownMenu.Portal>
        </DropdownMenu.Root>
      </div>

      {/* Navigation links */}
      <nav className="flex-1 overflow-y-auto p-2 scrollbar-thin" aria-label="Dashboard navigation">
        <ul className="space-y-1" role="list">
          {navItems.map((item) => {
            const active = isActive(item.href);
            return (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className={`flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors ${
                    active
                      ? "bg-primary/10 text-primary"
                      : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
                  } ${collapsed ? "justify-center px-2" : ""}`}
                  aria-current={active ? "page" : undefined}
                  aria-label={item.label}
                  title={collapsed ? item.label : undefined}
                >
                  <span className="shrink-0">{item.icon}</span>
                  {!collapsed && (
                    <>
                      <span className="flex-1">{item.label}</span>
                      {item.shortcut && (
                        <span className="kbd hidden lg:inline-flex" aria-hidden="true">
                          {item.shortcut}
                        </span>
                      )}
                    </>
                  )}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>

      {/* Collapse toggle */}
      <div className="border-t border-border p-2">
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-muted-foreground hover:bg-accent hover:text-accent-foreground transition-colors"
          aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          title={`${collapsed ? "Expand" : "Collapse"} sidebar (Cmd+B)`}
        >
          {collapsed ? (
            <ChevronsRight className="h-5 w-5 mx-auto" />
          ) : (
            <>
              <ChevronsLeft className="h-5 w-5" />
              <span className="flex-1 text-left">Collapse</span>
              <span className="kbd hidden lg:inline-flex" aria-hidden="true">
                B
              </span>
            </>
          )}
        </button>
      </div>

      {/* User menu */}
      <div className="border-t border-border p-2">
        <DropdownMenu.Root>
          <DropdownMenu.Trigger asChild>
            <button
              className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm hover:bg-accent transition-colors ${
                collapsed ? "justify-center px-2" : ""
              }`}
              aria-label="User menu"
            >
              <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-primary text-xs font-semibold">
                {user?.name
                  ? user.name
                      .split(" ")
                      .map((n) => n[0])
                      .join("")
                      .toUpperCase()
                      .slice(0, 2)
                  : "?"}
              </div>
              {!collapsed && (
                <div className="flex-1 overflow-hidden text-left">
                  <p className="truncate text-sm font-medium">
                    {user?.name || "User"}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {user?.email || ""}
                  </p>
                </div>
              )}
            </button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Portal>
            <DropdownMenu.Content
              className="z-50 min-w-[200px] rounded-xl border border-border bg-card p-1 shadow-lg animate-fade-in"
              side="top"
              align="start"
              sideOffset={4}
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
      </div>
    </aside>
  );
}
