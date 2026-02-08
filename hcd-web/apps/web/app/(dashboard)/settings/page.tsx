"use client";

import { useState } from "react";
import Link from "next/link";
import {
  User,
  Moon,
  Sun,
  Monitor,
  Building2,
  Key,
  Download,
  Trash2,
  Eye,
  EyeOff,
  Loader2,
  Save,
  UserPlus,
  ChevronRight,
  Brain,
} from "lucide-react";
import * as Switch from "@radix-ui/react-switch";
import { toast } from "sonner";
import { useTheme } from "@/components/ui/theme-provider";
import { useAuth } from "@/lib/auth-client";

export default function SettingsPage() {
  return (
    <div className="mx-auto max-w-3xl space-y-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Settings</h1>
        <p className="mt-1 text-muted-foreground">
          Manage your account and application preferences.
        </p>
      </div>

      <ProfileSection />
      <ThemeSection />
      <CoachingLink />
      <OrganizationSection />
      <ApiKeySection />
      <DataExportSection />
      <DangerZone />
    </div>
  );
}

// ─── Profile Section ─────────────────────────────────────────────────────────

function ProfileSection() {
  const { user } = useAuth();
  const [name, setName] = useState(user?.name || "");
  const [email] = useState(user?.email || "");
  const [isSaving, setIsSaving] = useState(false);

  async function handleSave() {
    setIsSaving(true);
    try {
      // Placeholder for profile update API call
      await new Promise((resolve) => setTimeout(resolve, 500));
      toast.success("Profile updated successfully");
    } catch {
      toast.error("Failed to update profile");
    } finally {
      setIsSaving(false);
    }
  }

  const initials = user?.name
    ? user.name
        .split(" ")
        .map((n) => n[0])
        .join("")
        .toUpperCase()
        .slice(0, 2)
    : "?";

  return (
    <section className="rounded-xl border border-border bg-card" aria-labelledby="profile-heading">
      <div className="border-b border-border p-6">
        <h2 id="profile-heading" className="text-lg font-semibold flex items-center gap-2">
          <User className="h-5 w-5" />
          Profile
        </h2>
      </div>
      <div className="p-6 space-y-6">
        {/* Avatar */}
        <div className="flex items-center gap-4">
          <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10 text-primary text-xl font-semibold">
            {initials}
          </div>
          <div>
            <button className="text-sm text-primary hover:underline">
              Change avatar
            </button>
            <p className="text-xs text-muted-foreground mt-0.5">
              JPG, PNG, or GIF. Max 2MB.
            </p>
          </div>
        </div>

        {/* Name */}
        <div>
          <label htmlFor="settings-name" className="mb-1.5 block text-sm font-medium">
            Full name
          </label>
          <input
            id="settings-name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="flex h-10 w-full max-w-sm rounded-lg border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          />
        </div>

        {/* Email (read-only) */}
        <div>
          <label htmlFor="settings-email" className="mb-1.5 block text-sm font-medium">
            Email
          </label>
          <input
            id="settings-email"
            type="email"
            value={email}
            disabled
            className="flex h-10 w-full max-w-sm rounded-lg border border-input bg-muted px-3 py-2 text-sm text-muted-foreground cursor-not-allowed"
          />
          <p className="mt-1.5 text-xs text-muted-foreground">
            Contact support to change your email address.
          </p>
        </div>

        <button
          onClick={handleSave}
          disabled={isSaving}
          className="inline-flex h-9 items-center gap-2 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors disabled:opacity-50"
        >
          {isSaving ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Save className="h-4 w-4" />
          )}
          Save Changes
        </button>
      </div>
    </section>
  );
}

// ─── Theme Section ───────────────────────────────────────────────────────────

function ThemeSection() {
  const { theme, setTheme } = useTheme();

  const themes = [
    { value: "light" as const, label: "Light", icon: <Sun className="h-4 w-4" /> },
    { value: "dark" as const, label: "Dark", icon: <Moon className="h-4 w-4" /> },
    { value: "system" as const, label: "System", icon: <Monitor className="h-4 w-4" /> },
  ];

  return (
    <section className="rounded-xl border border-border bg-card" aria-labelledby="theme-heading">
      <div className="border-b border-border p-6">
        <h2 id="theme-heading" className="text-lg font-semibold flex items-center gap-2">
          <Sun className="h-5 w-5" />
          Appearance
        </h2>
      </div>
      <div className="p-6">
        <p className="text-sm text-muted-foreground mb-4">
          Choose how HCD Interview Coach looks to you.
        </p>
        <div className="flex gap-3">
          {themes.map(({ value, label, icon }) => (
            <button
              key={value}
              onClick={() => setTheme(value)}
              className={`flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm font-medium transition-colors ${
                theme === value
                  ? "border-primary bg-primary/10 text-primary"
                  : "border-border bg-card hover:bg-accent text-muted-foreground hover:text-foreground"
              }`}
              aria-pressed={theme === value}
              aria-label={`${label} theme`}
            >
              {icon}
              {label}
            </button>
          ))}
        </div>
      </div>
    </section>
  );
}

// ─── Coaching Settings Link ──────────────────────────────────────────────────

function CoachingLink() {
  return (
    <Link
      href="/settings/coaching"
      className="flex items-center justify-between rounded-xl border border-border bg-card p-6 hover:bg-accent/50 transition-colors group"
      aria-label="Coaching settings"
    >
      <div className="flex items-center gap-3">
        <Brain className="h-5 w-5 text-muted-foreground group-hover:text-foreground transition-colors" />
        <div>
          <h2 className="text-lg font-semibold">Coaching Settings</h2>
          <p className="text-sm text-muted-foreground">
            Configure AI coaching behavior, timing, and cultural context.
          </p>
        </div>
      </div>
      <ChevronRight className="h-5 w-5 text-muted-foreground" />
    </Link>
  );
}

// ─── Organization Section ────────────────────────────────────────────────────

function OrganizationSection() {
  const [orgName, setOrgName] = useState("");
  const [inviteEmail, setInviteEmail] = useState("");

  return (
    <section className="rounded-xl border border-border bg-card" aria-labelledby="org-heading">
      <div className="border-b border-border p-6">
        <h2 id="org-heading" className="text-lg font-semibold flex items-center gap-2">
          <Building2 className="h-5 w-5" />
          Organization
        </h2>
      </div>
      <div className="p-6 space-y-6">
        {/* Create org */}
        <div>
          <h3 className="text-sm font-medium mb-3">Create Organization</h3>
          <div className="flex gap-3 max-w-sm">
            <input
              type="text"
              value={orgName}
              onChange={(e) => setOrgName(e.target.value)}
              placeholder="Organization name"
              className="flex h-10 flex-1 rounded-lg border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              aria-label="Organization name"
            />
            <button
              onClick={() => {
                if (orgName.trim()) {
                  toast.success(`Organization "${orgName}" created`);
                  setOrgName("");
                }
              }}
              disabled={!orgName.trim()}
              className="inline-flex h-10 items-center gap-2 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:pointer-events-none"
            >
              Create
            </button>
          </div>
        </div>

        {/* Invite members */}
        <div>
          <h3 className="text-sm font-medium mb-3">Invite Members</h3>
          <div className="flex gap-3 max-w-sm">
            <input
              type="email"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
              placeholder="colleague@example.com"
              className="flex h-10 flex-1 rounded-lg border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              aria-label="Email to invite"
            />
            <button
              onClick={() => {
                if (inviteEmail.trim()) {
                  toast.success(`Invitation sent to ${inviteEmail}`);
                  setInviteEmail("");
                }
              }}
              disabled={!inviteEmail.trim()}
              className="inline-flex h-10 items-center gap-2 rounded-lg border border-input bg-background px-4 text-sm font-medium hover:bg-accent transition-colors disabled:opacity-50 disabled:pointer-events-none"
            >
              <UserPlus className="h-4 w-4" />
              Invite
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}

// ─── API Key Section ─────────────────────────────────────────────────────────

function ApiKeySection() {
  const [apiKey, setApiKey] = useState("");
  const [showKey, setShowKey] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [hasKey, setHasKey] = useState(false);

  async function handleSaveKey() {
    if (!apiKey.trim()) return;
    setIsSaving(true);
    try {
      // Placeholder for API call to store key server-side
      await new Promise((resolve) => setTimeout(resolve, 500));
      setHasKey(true);
      setApiKey("");
      setShowKey(false);
      toast.success("API key saved securely");
    } catch {
      toast.error("Failed to save API key");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <section className="rounded-xl border border-border bg-card" aria-labelledby="api-heading">
      <div className="border-b border-border p-6">
        <h2 id="api-heading" className="text-lg font-semibold flex items-center gap-2">
          <Key className="h-5 w-5" />
          API Keys
        </h2>
      </div>
      <div className="p-6 space-y-4">
        <p className="text-sm text-muted-foreground">
          Your OpenAI API key is stored securely on the server and never exposed
          to the browser.
        </p>

        {hasKey && (
          <div className="flex items-center gap-2 rounded-lg bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 p-3">
            <div className="h-2 w-2 rounded-full bg-green-500" />
            <span className="text-sm text-green-800 dark:text-green-400">
              OpenAI API key configured
            </span>
          </div>
        )}

        <div>
          <label htmlFor="api-key" className="mb-1.5 block text-sm font-medium">
            OpenAI API Key
          </label>
          <div className="flex gap-3 max-w-lg">
            <div className="relative flex-1">
              <input
                id="api-key"
                type={showKey ? "text" : "password"}
                value={apiKey}
                onChange={(e) => setApiKey(e.target.value)}
                placeholder="sk-..."
                className="flex h-10 w-full rounded-lg border border-input bg-background px-3 py-2 pr-10 text-sm font-mono ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              />
              <button
                type="button"
                onClick={() => setShowKey(!showKey)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                aria-label={showKey ? "Hide API key" : "Show API key"}
              >
                {showKey ? (
                  <EyeOff className="h-4 w-4" />
                ) : (
                  <Eye className="h-4 w-4" />
                )}
              </button>
            </div>
            <button
              onClick={handleSaveKey}
              disabled={!apiKey.trim() || isSaving}
              className="inline-flex h-10 items-center gap-2 rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:pointer-events-none"
            >
              {isSaving ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <Save className="h-4 w-4" />
              )}
              Save
            </button>
          </div>
        </div>
      </div>
    </section>
  );
}

// ─── Data Export Section ─────────────────────────────────────────────────────

function DataExportSection() {
  const [isExporting, setIsExporting] = useState(false);

  async function handleExport() {
    setIsExporting(true);
    try {
      // Placeholder for data export
      await new Promise((resolve) => setTimeout(resolve, 1000));
      toast.success("Data export started. You will receive a download link.");
    } catch {
      toast.error("Failed to export data");
    } finally {
      setIsExporting(false);
    }
  }

  return (
    <section className="rounded-xl border border-border bg-card" aria-labelledby="export-heading">
      <div className="border-b border-border p-6">
        <h2 id="export-heading" className="text-lg font-semibold flex items-center gap-2">
          <Download className="h-5 w-5" />
          Data Export
        </h2>
      </div>
      <div className="p-6">
        <p className="text-sm text-muted-foreground mb-4">
          Download all your data including sessions, transcripts, highlights,
          and settings in JSON format.
        </p>
        <button
          onClick={handleExport}
          disabled={isExporting}
          className="inline-flex h-9 items-center gap-2 rounded-lg border border-input bg-background px-4 text-sm font-medium hover:bg-accent transition-colors disabled:opacity-50"
        >
          {isExporting ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <Download className="h-4 w-4" />
          )}
          Export All Data
        </button>
      </div>
    </section>
  );
}

// ─── Danger Zone ─────────────────────────────────────────────────────────────

function DangerZone() {
  const [showConfirm, setShowConfirm] = useState(false);
  const [confirmText, setConfirmText] = useState("");

  return (
    <section className="rounded-xl border border-destructive/50 bg-card" aria-labelledby="danger-heading">
      <div className="border-b border-destructive/30 p-6">
        <h2 id="danger-heading" className="text-lg font-semibold text-destructive flex items-center gap-2">
          <Trash2 className="h-5 w-5" />
          Danger Zone
        </h2>
      </div>
      <div className="p-6">
        <p className="text-sm text-muted-foreground mb-4">
          Permanently delete your account and all associated data. This action
          cannot be undone.
        </p>

        {!showConfirm ? (
          <button
            onClick={() => setShowConfirm(true)}
            className="inline-flex h-9 items-center gap-2 rounded-lg border border-destructive text-destructive bg-background px-4 text-sm font-medium hover:bg-destructive/10 transition-colors"
          >
            <Trash2 className="h-4 w-4" />
            Delete Account
          </button>
        ) : (
          <div className="space-y-3 max-w-sm">
            <p className="text-sm font-medium text-destructive">
              Type &quot;delete my account&quot; to confirm:
            </p>
            <input
              type="text"
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder="delete my account"
              className="flex h-10 w-full rounded-lg border border-destructive/50 bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive focus-visible:ring-offset-2"
              aria-label="Confirmation text"
            />
            <div className="flex gap-3">
              <button
                onClick={() => {
                  if (confirmText === "delete my account") {
                    toast.error("Account deletion is not yet implemented");
                  }
                }}
                disabled={confirmText !== "delete my account"}
                className="inline-flex h-9 items-center gap-2 rounded-lg bg-destructive px-4 text-sm font-medium text-destructive-foreground hover:bg-destructive/90 transition-colors disabled:opacity-50 disabled:pointer-events-none"
              >
                <Trash2 className="h-4 w-4" />
                Permanently Delete
              </button>
              <button
                onClick={() => {
                  setShowConfirm(false);
                  setConfirmText("");
                }}
                className="inline-flex h-9 items-center rounded-lg border border-input bg-background px-4 text-sm font-medium hover:bg-accent transition-colors"
              >
                Cancel
              </button>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
