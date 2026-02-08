"use client";

import { useState, useCallback } from "react";
import Link from "next/link";
import {
  ArrowLeft,
  Brain,
  Clock,
  Radio,
  Globe,
  SlidersHorizontal,
  Save,
  Loader2,
  Info,
} from "lucide-react";
import * as Switch from "@radix-ui/react-switch";
import * as Select from "@radix-ui/react-select";
import * as Tooltip from "@radix-ui/react-tooltip";
import { toast } from "sonner";

// ─── Types ───────────────────────────────────────────────────────────────────

type AutoDismissPreset = "quick" | "standard" | "relaxed" | "extended" | "manual";
type DeliveryMode = "realtime" | "pull" | "scheduled";
type CulturalPreset = "western" | "east-asian" | "latin-american" | "middle-eastern" | "custom";

interface CulturalContext {
  silenceTolerance: number;   // 0-100: how long to wait before considering silence noteworthy
  formality: number;          // 0-100: expected formality level
  directness: number;         // 0-100: preference for direct vs indirect communication
  emotionalExpression: number; // 0-100: expected level of emotional expression
  hierarchyAwareness: number; // 0-100: sensitivity to power dynamics
}

interface CoachingSettings {
  enabled: boolean;
  autoDismissPreset: AutoDismissPreset;
  deliveryMode: DeliveryMode;
  culturalPreset: CulturalPreset;
  culturalContext: CulturalContext;
  maxPromptsPerSession: number;
  confidenceThreshold: number;
}

// ─── Preset Data ─────────────────────────────────────────────────────────────

const autoDismissOptions: { value: AutoDismissPreset; label: string; duration: string }[] = [
  { value: "quick", label: "Quick", duration: "5 seconds" },
  { value: "standard", label: "Standard", duration: "8 seconds" },
  { value: "relaxed", label: "Relaxed", duration: "15 seconds" },
  { value: "extended", label: "Extended", duration: "30 seconds" },
  { value: "manual", label: "Manual", duration: "Dismiss manually" },
];

const deliveryModes: { value: DeliveryMode; label: string; description: string }[] = [
  { value: "realtime", label: "Real-time", description: "Prompts appear automatically during the session" },
  { value: "pull", label: "Pull", description: "Prompts are queued; press a key to see the next one" },
  { value: "scheduled", label: "Scheduled", description: "Prompts appear at set intervals (e.g., every 5 minutes)" },
];

const culturalPresets: {
  value: CulturalPreset;
  label: string;
  description: string;
  context: CulturalContext;
}[] = [
  {
    value: "western",
    label: "Western",
    description: "North American / Western European norms",
    context: { silenceTolerance: 30, formality: 40, directness: 70, emotionalExpression: 60, hierarchyAwareness: 30 },
  },
  {
    value: "east-asian",
    label: "East Asian",
    description: "CJK cultural communication patterns",
    context: { silenceTolerance: 80, formality: 75, directness: 35, emotionalExpression: 30, hierarchyAwareness: 80 },
  },
  {
    value: "latin-american",
    label: "Latin American",
    description: "Latin American communication styles",
    context: { silenceTolerance: 20, formality: 50, directness: 55, emotionalExpression: 80, hierarchyAwareness: 55 },
  },
  {
    value: "middle-eastern",
    label: "Middle Eastern",
    description: "Middle Eastern / North African norms",
    context: { silenceTolerance: 40, formality: 70, directness: 40, emotionalExpression: 65, hierarchyAwareness: 75 },
  },
  {
    value: "custom",
    label: "Custom",
    description: "Define your own cultural context sliders",
    context: { silenceTolerance: 50, formality: 50, directness: 50, emotionalExpression: 50, hierarchyAwareness: 50 },
  },
];

// ─── Default Values ──────────────────────────────────────────────────────────

const defaultSettings: CoachingSettings = {
  enabled: false,
  autoDismissPreset: "standard",
  deliveryMode: "realtime",
  culturalPreset: "western",
  culturalContext: { silenceTolerance: 30, formality: 40, directness: 70, emotionalExpression: 60, hierarchyAwareness: 30 },
  maxPromptsPerSession: 3,
  confidenceThreshold: 85,
};

// ─── Component ───────────────────────────────────────────────────────────────

export default function CoachingSettingsPage() {
  const [settings, setSettings] = useState<CoachingSettings>(defaultSettings);
  const [isSaving, setIsSaving] = useState(false);

  const updateSettings = useCallback(
    <K extends keyof CoachingSettings>(key: K, value: CoachingSettings[K]) => {
      setSettings((prev) => ({ ...prev, [key]: value }));
    },
    []
  );

  const updateCulturalContext = useCallback(
    <K extends keyof CulturalContext>(key: K, value: number) => {
      setSettings((prev) => ({
        ...prev,
        culturalPreset: "custom" as CulturalPreset,
        culturalContext: { ...prev.culturalContext, [key]: value },
      }));
    },
    []
  );

  function handleCulturalPresetChange(preset: CulturalPreset) {
    const presetData = culturalPresets.find((p) => p.value === preset);
    if (presetData) {
      setSettings((prev) => ({
        ...prev,
        culturalPreset: preset,
        culturalContext: { ...presetData.context },
      }));
    }
  }

  async function handleSave() {
    setIsSaving(true);
    try {
      // Placeholder for saving coaching settings
      await new Promise((resolve) => setTimeout(resolve, 500));
      toast.success("Coaching settings saved");
    } catch {
      toast.error("Failed to save coaching settings");
    } finally {
      setIsSaving(false);
    }
  }

  return (
    <Tooltip.Provider delayDuration={300}>
      <div className="mx-auto max-w-3xl space-y-8">
        {/* Header with back link */}
        <div>
          <Link
            href="/settings"
            className="inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground transition-colors mb-4"
          >
            <ArrowLeft className="h-4 w-4" />
            Back to Settings
          </Link>
          <h1 className="text-2xl font-semibold tracking-tight flex items-center gap-2">
            <Brain className="h-6 w-6" />
            Coaching Settings
          </h1>
          <p className="mt-1 text-muted-foreground">
            Configure how the AI coaching assistant behaves during your sessions.
          </p>
        </div>

        {/* Enable/Disable Toggle */}
        <section className="rounded-xl border border-border bg-card p-6" aria-labelledby="coaching-toggle-heading">
          <div className="flex items-center justify-between">
            <div>
              <h2 id="coaching-toggle-heading" className="text-lg font-semibold">Coaching</h2>
              <p className="text-sm text-muted-foreground mt-0.5">
                Enable or disable AI coaching prompts during sessions.
              </p>
            </div>
            <Switch.Root
              checked={settings.enabled}
              onCheckedChange={(checked) => updateSettings("enabled", checked)}
              className="relative h-6 w-11 rounded-full bg-muted transition-colors data-[state=checked]:bg-primary"
              aria-label="Enable coaching"
            >
              <Switch.Thumb className="block h-5 w-5 translate-x-0.5 rounded-full bg-white shadow-sm transition-transform data-[state=checked]:translate-x-[22px]" />
            </Switch.Root>
          </div>
          {!settings.enabled && (
            <div className="mt-4 rounded-lg bg-muted/50 p-3 text-sm text-muted-foreground">
              <Info className="inline-block h-4 w-4 mr-1.5 -mt-0.5" />
              Coaching is disabled by default for first sessions. Participants will not see any AI-generated prompts.
            </div>
          )}
        </section>

        {/* Auto-Dismiss Preset */}
        <section className="rounded-xl border border-border bg-card" aria-labelledby="dismiss-heading">
          <div className="border-b border-border p-6">
            <h2 id="dismiss-heading" className="text-lg font-semibold flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Auto-Dismiss Timing
            </h2>
            <p className="text-sm text-muted-foreground mt-0.5">
              How long coaching prompts stay visible before auto-dismissing.
            </p>
          </div>
          <div className="p-6">
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              {autoDismissOptions.map((option) => (
                <button
                  key={option.value}
                  onClick={() => updateSettings("autoDismissPreset", option.value)}
                  className={`rounded-lg border px-4 py-3 text-left transition-colors ${
                    settings.autoDismissPreset === option.value
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border bg-card hover:bg-accent"
                  }`}
                  aria-pressed={settings.autoDismissPreset === option.value}
                >
                  <p className="text-sm font-medium">{option.label}</p>
                  <p className="text-xs text-muted-foreground mt-0.5">{option.duration}</p>
                </button>
              ))}
            </div>
          </div>
        </section>

        {/* Delivery Mode */}
        <section className="rounded-xl border border-border bg-card" aria-labelledby="delivery-heading">
          <div className="border-b border-border p-6">
            <h2 id="delivery-heading" className="text-lg font-semibold flex items-center gap-2">
              <Radio className="h-5 w-5" />
              Delivery Mode
            </h2>
            <p className="text-sm text-muted-foreground mt-0.5">
              How coaching prompts are delivered during a session.
            </p>
          </div>
          <div className="p-6">
            <div className="space-y-3">
              {deliveryModes.map((mode) => (
                <button
                  key={mode.value}
                  onClick={() => updateSettings("deliveryMode", mode.value)}
                  className={`w-full rounded-lg border px-4 py-3 text-left transition-colors ${
                    settings.deliveryMode === mode.value
                      ? "border-primary bg-primary/10"
                      : "border-border bg-card hover:bg-accent"
                  }`}
                  aria-pressed={settings.deliveryMode === mode.value}
                  role="radio"
                  aria-checked={settings.deliveryMode === mode.value}
                >
                  <p className={`text-sm font-medium ${
                    settings.deliveryMode === mode.value ? "text-primary" : ""
                  }`}>
                    {mode.label}
                  </p>
                  <p className="text-xs text-muted-foreground mt-0.5">{mode.description}</p>
                </button>
              ))}
            </div>
          </div>
        </section>

        {/* Cultural Context */}
        <section className="rounded-xl border border-border bg-card" aria-labelledby="cultural-heading">
          <div className="border-b border-border p-6">
            <h2 id="cultural-heading" className="text-lg font-semibold flex items-center gap-2">
              <Globe className="h-5 w-5" />
              Cultural Context
            </h2>
            <p className="text-sm text-muted-foreground mt-0.5">
              Adjust coaching sensitivity based on cultural communication norms.
            </p>
          </div>
          <div className="p-6 space-y-6">
            {/* Preset selector */}
            <div>
              <label className="mb-2 block text-sm font-medium">Preset</label>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {culturalPresets.map((preset) => (
                  <button
                    key={preset.value}
                    onClick={() => handleCulturalPresetChange(preset.value)}
                    className={`rounded-lg border px-4 py-3 text-left transition-colors ${
                      settings.culturalPreset === preset.value
                        ? "border-primary bg-primary/10 text-primary"
                        : "border-border bg-card hover:bg-accent"
                    }`}
                    aria-pressed={settings.culturalPreset === preset.value}
                  >
                    <p className="text-sm font-medium">{preset.label}</p>
                    <p className="text-xs text-muted-foreground mt-0.5">{preset.description}</p>
                  </button>
                ))}
              </div>
            </div>

            {/* Custom sliders */}
            <div className="space-y-5 pt-2">
              <h3 className="text-sm font-medium flex items-center gap-2">
                <SlidersHorizontal className="h-4 w-4" />
                Fine-Tune Context
                {settings.culturalPreset !== "custom" && (
                  <span className="text-xs text-muted-foreground font-normal">
                    (adjusting a slider switches to Custom)
                  </span>
                )}
              </h3>

              <ContextSlider
                label="Silence Tolerance"
                tooltip="How long to wait before considering silence as potentially awkward. Higher values mean more patience with pauses."
                value={settings.culturalContext.silenceTolerance}
                onChange={(v) => updateCulturalContext("silenceTolerance", v)}
                lowLabel="Low"
                highLabel="High"
              />

              <ContextSlider
                label="Formality Level"
                tooltip="Expected formality in communication. Higher values trigger more formal coaching language."
                value={settings.culturalContext.formality}
                onChange={(v) => updateCulturalContext("formality", v)}
                lowLabel="Casual"
                highLabel="Formal"
              />

              <ContextSlider
                label="Directness"
                tooltip="Preference for direct vs indirect communication styles. Lower values lead to softer, more suggestive prompts."
                value={settings.culturalContext.directness}
                onChange={(v) => updateCulturalContext("directness", v)}
                lowLabel="Indirect"
                highLabel="Direct"
              />

              <ContextSlider
                label="Emotional Expression"
                tooltip="Expected level of emotional expression. Affects how the AI interprets tone and sentiment."
                value={settings.culturalContext.emotionalExpression}
                onChange={(v) => updateCulturalContext("emotionalExpression", v)}
                lowLabel="Reserved"
                highLabel="Expressive"
              />

              <ContextSlider
                label="Hierarchy Awareness"
                tooltip="Sensitivity to power dynamics between interviewer and participant. Higher values lead to more cautious prompts."
                value={settings.culturalContext.hierarchyAwareness}
                onChange={(v) => updateCulturalContext("hierarchyAwareness", v)}
                lowLabel="Egalitarian"
                highLabel="Hierarchical"
              />
            </div>
          </div>
        </section>

        {/* Advanced: Max Prompts & Confidence */}
        <section className="rounded-xl border border-border bg-card" aria-labelledby="advanced-heading">
          <div className="border-b border-border p-6">
            <h2 id="advanced-heading" className="text-lg font-semibold flex items-center gap-2">
              <SlidersHorizontal className="h-5 w-5" />
              Advanced
            </h2>
          </div>
          <div className="p-6 space-y-6">
            {/* Max prompts per session */}
            <div>
              <label htmlFor="max-prompts" className="mb-1.5 flex items-center gap-2 text-sm font-medium">
                Max Prompts per Session
                <TooltipHelper content="The maximum number of coaching prompts that can be shown during a single session. Default is 3 to avoid interrupting the interview flow." />
              </label>
              <div className="flex items-center gap-4 max-w-xs">
                <input
                  id="max-prompts"
                  type="range"
                  min={1}
                  max={10}
                  step={1}
                  value={settings.maxPromptsPerSession}
                  onChange={(e) =>
                    updateSettings("maxPromptsPerSession", parseInt(e.target.value, 10))
                  }
                  className="flex-1 h-2 rounded-full appearance-none bg-muted [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-primary [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:cursor-pointer"
                  aria-label="Maximum prompts per session"
                />
                <span className="w-8 text-center text-sm font-medium tabular-nums">
                  {settings.maxPromptsPerSession}
                </span>
              </div>
              <p className="mt-1.5 text-xs text-muted-foreground">
                Recommended: 3 prompts. Higher values may disrupt interview flow.
              </p>
            </div>

            {/* Confidence threshold */}
            <div>
              <label htmlFor="confidence" className="mb-1.5 flex items-center gap-2 text-sm font-medium">
                Confidence Threshold
                <TooltipHelper content="Minimum confidence level (0-100%) required before the AI will display a coaching prompt. Higher values mean fewer but more relevant prompts." />
              </label>
              <div className="flex items-center gap-4 max-w-xs">
                <input
                  id="confidence"
                  type="range"
                  min={50}
                  max={100}
                  step={5}
                  value={settings.confidenceThreshold}
                  onChange={(e) =>
                    updateSettings("confidenceThreshold", parseInt(e.target.value, 10))
                  }
                  className="flex-1 h-2 rounded-full appearance-none bg-muted [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-primary [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:cursor-pointer"
                  aria-label="Confidence threshold percentage"
                />
                <span className="w-12 text-center text-sm font-medium tabular-nums">
                  {settings.confidenceThreshold}%
                </span>
              </div>
              <p className="mt-1.5 text-xs text-muted-foreground">
                Default: 85%. Only prompts with at least this confidence level will be shown.
              </p>
            </div>
          </div>
        </section>

        {/* Save button (sticky) */}
        <div className="sticky bottom-6 flex justify-end">
          <button
            onClick={handleSave}
            disabled={isSaving}
            className="inline-flex h-10 items-center gap-2 rounded-lg bg-primary px-6 text-sm font-medium text-primary-foreground shadow-lg hover:bg-primary/90 transition-colors disabled:opacity-50"
          >
            {isSaving ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Save className="h-4 w-4" />
            )}
            Save Coaching Settings
          </button>
        </div>
      </div>
    </Tooltip.Provider>
  );
}

// ─── Slider Component ────────────────────────────────────────────────────────

function ContextSlider({
  label,
  tooltip,
  value,
  onChange,
  lowLabel,
  highLabel,
}: {
  label: string;
  tooltip: string;
  value: number;
  onChange: (value: number) => void;
  lowLabel: string;
  highLabel: string;
}) {
  return (
    <div>
      <label className="mb-2 flex items-center gap-2 text-sm font-medium">
        {label}
        <TooltipHelper content={tooltip} />
      </label>
      <div className="flex items-center gap-3">
        <span className="w-20 text-xs text-muted-foreground text-right shrink-0">
          {lowLabel}
        </span>
        <input
          type="range"
          min={0}
          max={100}
          step={5}
          value={value}
          onChange={(e) => onChange(parseInt(e.target.value, 10))}
          className="flex-1 h-2 rounded-full appearance-none bg-muted [&::-webkit-slider-thumb]:h-4 [&::-webkit-slider-thumb]:w-4 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-primary [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:cursor-pointer"
          aria-label={label}
        />
        <span className="w-20 text-xs text-muted-foreground shrink-0">
          {highLabel}
        </span>
        <span className="w-8 text-center text-xs font-medium tabular-nums text-muted-foreground">
          {value}
        </span>
      </div>
    </div>
  );
}

// ─── Tooltip Helper ──────────────────────────────────────────────────────────

function TooltipHelper({ content }: { content: string }) {
  return (
    <Tooltip.Root>
      <Tooltip.Trigger asChild>
        <button
          type="button"
          className="inline-flex items-center justify-center rounded-full text-muted-foreground hover:text-foreground transition-colors"
          aria-label="More information"
        >
          <Info className="h-3.5 w-3.5" />
        </button>
      </Tooltip.Trigger>
      <Tooltip.Portal>
        <Tooltip.Content
          className="z-50 max-w-xs rounded-lg border border-border bg-card px-3 py-2 text-xs text-muted-foreground shadow-lg animate-fade-in"
          side="top"
          sideOffset={4}
        >
          {content}
          <Tooltip.Arrow className="fill-card" />
        </Tooltip.Content>
      </Tooltip.Portal>
    </Tooltip.Root>
  );
}
