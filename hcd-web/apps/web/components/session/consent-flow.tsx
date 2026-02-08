"use client";

import React, { useState, useCallback, useMemo } from "react";
import { Button } from "@hcd/ui";
import { Input } from "@hcd/ui";
import { Badge } from "@hcd/ui";
import { Card, CardContent, CardHeader, CardTitle } from "@hcd/ui";
import {
  Shield,
  ShieldCheck,
  FileText,
  Mic,
  Video,
  Eye,
  Users,
  Database,
  Clock,
  ChevronRight,
  ChevronLeft,
  Check,
  Volume2,
  Globe,
  AlertCircle,
  CheckCircle2,
  XCircle,
  MessageSquare,
} from "lucide-react";
import * as Checkbox from "@radix-ui/react-checkbox";

// ─── Types ──────────────────────────────────────────────────────────────────

type ConsentStatus = "not_obtained" | "verbal_consent" | "written_consent" | "declined";

interface Permission {
  id: string;
  label: string;
  description: string;
  icon: React.ReactNode;
  required: boolean;
}

interface ConsentTemplate {
  id: string;
  name: string;
  description: string;
  language: string;
  permissions: Permission[];
}

interface ConsentFlowProps {
  sessionId: string;
  participantId?: string;
  onComplete?: (consentRecord: any) => void;
  onCancel?: () => void;
  initialStatus?: ConsentStatus;
}

type WizardStep = 1 | 2 | 3 | 4 | 5;

// ─── Default Templates ──────────────────────────────────────────────────────

const DEFAULT_PERMISSIONS: Permission[] = [
  {
    id: "audio_recording",
    label: "Audio Recording",
    description: "We will record the audio of our conversation so we can review it later.",
    icon: <Mic className="h-5 w-5" />,
    required: true,
  },
  {
    id: "video_recording",
    label: "Video Recording",
    description: "We may record video of the session for research purposes.",
    icon: <Video className="h-5 w-5" />,
    required: false,
  },
  {
    id: "note_taking",
    label: "Note Taking",
    description: "Observers may take notes during the session about what you say and do.",
    icon: <FileText className="h-5 w-5" />,
    required: true,
  },
  {
    id: "data_storage",
    label: "Data Storage",
    description: "Your responses will be stored securely and used only for this research project.",
    icon: <Database className="h-5 w-5" />,
    required: true,
  },
  {
    id: "team_access",
    label: "Team Access",
    description: "Members of the research team may review the session recordings and notes.",
    icon: <Users className="h-5 w-5" />,
    required: false,
  },
  {
    id: "anonymized_quotes",
    label: "Anonymous Quotes",
    description: "We may use anonymous quotes from this session in our reports and presentations.",
    icon: <MessageSquare className="h-5 w-5" />,
    required: false,
  },
];

const TEMPLATES: ConsentTemplate[] = [
  {
    id: "standard_en",
    name: "Standard Research Consent",
    description: "Standard consent form for UX research interviews",
    language: "en",
    permissions: DEFAULT_PERMISSIONS,
  },
  {
    id: "standard_es",
    name: "Consentimiento de Investigacion",
    description: "Formulario de consentimiento estandar para entrevistas de investigacion",
    language: "es",
    permissions: DEFAULT_PERMISSIONS.map((p) => ({
      ...p,
      label: {
        audio_recording: "Grabacion de Audio",
        video_recording: "Grabacion de Video",
        note_taking: "Toma de Notas",
        data_storage: "Almacenamiento de Datos",
        team_access: "Acceso del Equipo",
        anonymized_quotes: "Citas Anonimas",
      }[p.id] || p.label,
      description: {
        audio_recording: "Grabaremos el audio de nuestra conversacion para poder revisarla mas tarde.",
        video_recording: "Podemos grabar video de la sesion con fines de investigacion.",
        note_taking: "Los observadores pueden tomar notas durante la sesion sobre lo que dice y hace.",
        data_storage: "Sus respuestas se almacenaran de forma segura y se usaran solo para este proyecto.",
        team_access: "Los miembros del equipo de investigacion pueden revisar las grabaciones y notas.",
        anonymized_quotes: "Podemos usar citas anonimas de esta sesion en nuestros informes.",
      }[p.id] || p.description,
    })),
  },
  {
    id: "standard_fr",
    name: "Consentement de Recherche",
    description: "Formulaire de consentement standard pour les entretiens de recherche",
    language: "fr",
    permissions: DEFAULT_PERMISSIONS.map((p) => ({
      ...p,
      label: {
        audio_recording: "Enregistrement Audio",
        video_recording: "Enregistrement Video",
        note_taking: "Prise de Notes",
        data_storage: "Stockage des Donnees",
        team_access: "Acces de l'Equipe",
        anonymized_quotes: "Citations Anonymes",
      }[p.id] || p.label,
      description: {
        audio_recording: "Nous enregistrerons l'audio de notre conversation pour pouvoir le revoir plus tard.",
        video_recording: "Nous pouvons enregistrer une video de la session a des fins de recherche.",
        note_taking: "Les observateurs peuvent prendre des notes pendant la session sur ce que vous dites et faites.",
        data_storage: "Vos reponses seront stockees en toute securite et utilisees uniquement pour ce projet.",
        team_access: "Les membres de l'equipe de recherche peuvent examiner les enregistrements et les notes.",
        anonymized_quotes: "Nous pouvons utiliser des citations anonymes de cette session dans nos rapports.",
      }[p.id] || p.description,
    })),
  },
];

const LANGUAGE_LABELS: Record<string, string> = {
  en: "English",
  es: "Espanol",
  fr: "Francais",
};

const STATUS_META: Record<ConsentStatus, { label: string; icon: React.ReactNode; color: string }> = {
  not_obtained: { label: "Not Obtained", icon: <AlertCircle className="h-4 w-4" />, color: "text-muted-foreground" },
  verbal_consent: { label: "Verbal Consent", icon: <Volume2 className="h-4 w-4" />, color: "text-yellow-600" },
  written_consent: { label: "Written Consent", icon: <CheckCircle2 className="h-4 w-4" />, color: "text-green-600" },
  declined: { label: "Declined", icon: <XCircle className="h-4 w-4" />, color: "text-red-600" },
};

// ─── Consent Flow Component ─────────────────────────────────────────────────

export function ConsentFlow({
  sessionId,
  participantId,
  onComplete,
  onCancel,
  initialStatus = "not_obtained",
}: ConsentFlowProps) {
  const [step, setStep] = useState<WizardStep>(1);
  const [selectedTemplate, setSelectedTemplate] = useState<ConsentTemplate | null>(null);
  const [acknowledgedPermissions, setAcknowledgedPermissions] = useState<Set<string>>(new Set());
  const [signatureName, setSignatureName] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [status, setStatus] = useState<ConsentStatus>(initialStatus);
  const [isSpeaking, setIsSpeaking] = useState(false);

  // ─── Step Navigation ────────────────────────────────────────────────────

  const canProceed = useMemo(() => {
    switch (step) {
      case 1:
        return selectedTemplate !== null;
      case 2:
        return true; // Review step, always can proceed
      case 3: {
        if (!selectedTemplate) return false;
        const requiredPerms = selectedTemplate.permissions.filter((p) => p.required);
        return requiredPerms.every((p) => acknowledgedPermissions.has(p.id));
      }
      case 4:
        return signatureName.trim().length >= 2;
      case 5:
        return true;
      default:
        return false;
    }
  }, [step, selectedTemplate, acknowledgedPermissions, signatureName]);

  const goNext = useCallback(() => {
    if (step < 5) setStep((step + 1) as WizardStep);
  }, [step]);

  const goBack = useCallback(() => {
    if (step > 1) setStep((step - 1) as WizardStep);
  }, [step]);

  // ─── Permission Toggle ──────────────────────────────────────────────────

  const togglePermission = useCallback((permId: string) => {
    setAcknowledgedPermissions((prev) => {
      const next = new Set(prev);
      if (next.has(permId)) {
        next.delete(permId);
      } else {
        next.add(permId);
      }
      return next;
    });
  }, []);

  // ─── Read Aloud ─────────────────────────────────────────────────────────

  const readAloud = useCallback(
    (text: string) => {
      if (!("speechSynthesis" in window)) return;

      window.speechSynthesis.cancel();

      const utterance = new SpeechSynthesisUtterance(text);
      utterance.rate = 0.9;

      if (selectedTemplate) {
        utterance.lang =
          selectedTemplate.language === "es"
            ? "es-ES"
            : selectedTemplate.language === "fr"
            ? "fr-FR"
            : "en-US";
      }

      utterance.onstart = () => setIsSpeaking(true);
      utterance.onend = () => setIsSpeaking(false);
      utterance.onerror = () => setIsSpeaking(false);

      window.speechSynthesis.speak(utterance);
    },
    [selectedTemplate]
  );

  const stopSpeaking = useCallback(() => {
    window.speechSynthesis.cancel();
    setIsSpeaking(false);
  }, []);

  // ─── Save Consent ──────────────────────────────────────────────────────

  const handleSave = useCallback(async () => {
    if (!selectedTemplate) return;

    setIsSaving(true);
    try {
      const permissions: Record<string, boolean> = {};
      for (const perm of selectedTemplate.permissions) {
        permissions[perm.id] = acknowledgedPermissions.has(perm.id);
      }

      const response = await fetch("/api/sessions/" + sessionId, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          consentStatus: "written_consent",
        }),
      });

      // Also save the consent record
      const consentResponse = await fetch("/api/redactions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          // Using a generic endpoint; in production this would be /api/consent
          action: "consent",
          sessionId,
          participantId,
          templateVersion: selectedTemplate.id,
          status: "written_consent",
          permissions,
          signatureName,
        }),
      });

      setStatus("written_consent");
      setStep(5);
      onComplete?.({
        sessionId,
        participantId,
        templateVersion: selectedTemplate.id,
        status: "written_consent",
        permissions,
        signatureName,
        obtainedAt: new Date().toISOString(),
      });
    } catch (error) {
      console.error("Failed to save consent:", error);
    } finally {
      setIsSaving(false);
    }
  }, [sessionId, participantId, selectedTemplate, acknowledgedPermissions, signatureName, onComplete]);

  // ─── Render Steps ───────────────────────────────────────────────────────

  return (
    <div className="max-w-2xl mx-auto">
      {/* Step Indicator */}
      <div className="flex items-center justify-center gap-2 mb-6" role="progressbar" aria-valuenow={step} aria-valuemin={1} aria-valuemax={5}>
        {[1, 2, 3, 4, 5].map((s) => (
          <React.Fragment key={s}>
            <div
              className={`flex items-center justify-center h-8 w-8 rounded-full text-sm font-medium transition-colors ${
                s === step
                  ? "bg-primary text-primary-foreground"
                  : s < step
                  ? "bg-primary/20 text-primary"
                  : "bg-muted text-muted-foreground"
              }`}
              aria-label={`Step ${s}${s === step ? " (current)" : s < step ? " (completed)" : ""}`}
            >
              {s < step ? <Check className="h-4 w-4" /> : s}
            </div>
            {s < 5 && (
              <div
                className={`h-0.5 w-8 transition-colors ${
                  s < step ? "bg-primary" : "bg-muted"
                }`}
              />
            )}
          </React.Fragment>
        ))}
      </div>

      {/* Status Display */}
      {status !== "not_obtained" && step !== 5 && (
        <div className={`flex items-center gap-2 mb-4 p-2 rounded-lg border ${STATUS_META[status].color}`}>
          {STATUS_META[status].icon}
          <span className="text-sm font-medium">
            Current status: {STATUS_META[status].label}
          </span>
        </div>
      )}

      {/* Step 1: Select Template */}
      {step === 1 && (
        <div className="space-y-4">
          <div className="text-center mb-6">
            <h2 className="text-xl font-semibold mb-1">Select Consent Template</h2>
            <p className="text-sm text-muted-foreground">
              Choose a consent form or create a custom one
            </p>
          </div>

          <div className="space-y-3">
            {TEMPLATES.map((template) => (
              <Card
                key={template.id}
                className={`cursor-pointer transition-all hover:shadow-md ${
                  selectedTemplate?.id === template.id
                    ? "ring-2 ring-primary shadow-md"
                    : ""
                }`}
                onClick={() => setSelectedTemplate(template)}
                role="radio"
                aria-checked={selectedTemplate?.id === template.id}
                tabIndex={0}
                onKeyDown={(e) => {
                  if (e.key === "Enter" || e.key === " ") {
                    e.preventDefault();
                    setSelectedTemplate(template);
                  }
                }}
              >
                <CardContent className="p-4 flex items-center gap-4">
                  <div className={`rounded-lg p-2 ${selectedTemplate?.id === template.id ? "bg-primary/10" : "bg-muted"}`}>
                    <Globe className={`h-5 w-5 ${selectedTemplate?.id === template.id ? "text-primary" : "text-muted-foreground"}`} />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-medium text-sm">{template.name}</h3>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {template.description}
                    </p>
                  </div>
                  <Badge variant="outline" className="shrink-0">
                    {LANGUAGE_LABELS[template.language] || template.language}
                  </Badge>
                  {selectedTemplate?.id === template.id && (
                    <Check className="h-5 w-5 text-primary shrink-0" />
                  )}
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Step 2: Review Permissions */}
      {step === 2 && selectedTemplate && (
        <div className="space-y-4">
          <div className="text-center mb-6">
            <h2 className="text-xl font-semibold mb-1">Review Permissions</h2>
            <p className="text-sm text-muted-foreground">
              These are the permissions that will be requested
            </p>
          </div>

          <div className="space-y-3">
            {selectedTemplate.permissions.map((perm) => (
              <Card key={perm.id}>
                <CardContent className="p-4 flex items-start gap-3">
                  <div className="rounded-lg bg-muted p-2 shrink-0">
                    {perm.icon}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-medium text-sm">{perm.label}</h3>
                      {perm.required && (
                        <Badge variant="destructive" className="text-xs">
                          Required
                        </Badge>
                      )}
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {perm.description}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => readAloud(perm.description)}
                    className={`p-2 rounded-md transition-colors shrink-0 ${
                      isSpeaking
                        ? "text-primary bg-primary/10"
                        : "text-muted-foreground hover:bg-accent"
                    }`}
                    aria-label={`Read aloud: ${perm.label}`}
                  >
                    <Volume2 className="h-4 w-4" />
                  </button>
                </CardContent>
              </Card>
            ))}
          </div>

          {isSpeaking && (
            <Button variant="outline" size="sm" onClick={stopSpeaking} className="w-full">
              <Volume2 className="h-4 w-4 mr-1.5 animate-pulse" />
              Stop Reading
            </Button>
          )}
        </div>
      )}

      {/* Step 3: Acknowledge Permissions */}
      {step === 3 && selectedTemplate && (
        <div className="space-y-4">
          <div className="text-center mb-6">
            <h2 className="text-xl font-semibold mb-1">Acknowledge Permissions</h2>
            <p className="text-sm text-muted-foreground">
              Please check each permission you agree to
            </p>
          </div>

          <div className="space-y-2">
            {selectedTemplate.permissions.map((perm) => {
              const isChecked = acknowledgedPermissions.has(perm.id);
              return (
                <label
                  key={perm.id}
                  className={`flex items-start gap-3 rounded-lg border p-4 cursor-pointer transition-colors ${
                    isChecked
                      ? "border-primary/50 bg-primary/5"
                      : "hover:bg-accent/30"
                  }`}
                >
                  <Checkbox.Root
                    checked={isChecked}
                    onCheckedChange={() => togglePermission(perm.id)}
                    className={`flex h-5 w-5 shrink-0 items-center justify-center rounded border mt-0.5 ${
                      isChecked
                        ? "bg-primary border-primary text-primary-foreground"
                        : "border-input"
                    }`}
                    aria-label={`${perm.label}${perm.required ? " (required)" : ""}`}
                  >
                    <Checkbox.Indicator>
                      <Check className="h-3.5 w-3.5" />
                    </Checkbox.Indicator>
                  </Checkbox.Root>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-medium">{perm.label}</span>
                      {perm.required && (
                        <span className="text-xs text-destructive">*required</span>
                      )}
                    </div>
                    <p className="text-xs text-muted-foreground mt-0.5">
                      {perm.description}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={(e) => {
                      e.preventDefault();
                      readAloud(`${perm.label}. ${perm.description}`);
                    }}
                    className="p-1.5 rounded-md text-muted-foreground hover:bg-accent transition-colors shrink-0"
                    aria-label={`Read aloud: ${perm.label}`}
                  >
                    <Volume2 className="h-3.5 w-3.5" />
                  </button>
                </label>
              );
            })}
          </div>

          {/* Verbal Consent Option */}
          <div className="border-t pt-4 mt-4">
            <Button
              variant="outline"
              className="w-full"
              onClick={() => {
                setStatus("verbal_consent");
                onComplete?.({
                  sessionId,
                  participantId,
                  status: "verbal_consent",
                  permissions: {},
                  obtainedAt: new Date().toISOString(),
                });
              }}
            >
              <Volume2 className="h-4 w-4 mr-2" />
              Record Verbal Consent Only
            </Button>
          </div>
        </div>
      )}

      {/* Step 4: Digital Signature */}
      {step === 4 && (
        <div className="space-y-4">
          <div className="text-center mb-6">
            <h2 className="text-xl font-semibold mb-1">Digital Signature</h2>
            <p className="text-sm text-muted-foreground">
              Type your full name to sign the consent form
            </p>
          </div>

          <Card>
            <CardContent className="p-6 space-y-4">
              <div className="rounded-lg bg-muted/50 p-4 text-sm text-muted-foreground">
                <p className="mb-2">
                  By typing my name below, I confirm that:
                </p>
                <ul className="list-disc list-inside space-y-1 text-xs">
                  <li>I have read and understand the permissions listed above</li>
                  <li>I am participating voluntarily</li>
                  <li>I can stop at any time without giving a reason</li>
                  <li>My data will be handled as described</li>
                </ul>
              </div>

              <div>
                <label htmlFor="signature-name" className="text-sm font-medium mb-1.5 block">
                  Full Name
                </label>
                <Input
                  id="signature-name"
                  value={signatureName}
                  onChange={(e) => setSignatureName(e.target.value)}
                  placeholder="Type your full name"
                  className="text-lg font-serif italic"
                  aria-label="Type your full name as digital signature"
                  autoFocus
                />
              </div>

              {signatureName.trim().length >= 2 && (
                <div className="border-t pt-4 text-center">
                  <p className="text-xs text-muted-foreground mb-2">Signature preview:</p>
                  <p className="text-2xl font-serif italic text-foreground">
                    {signatureName}
                  </p>
                  <p className="text-xs text-muted-foreground mt-2">
                    {new Date().toLocaleDateString()}
                  </p>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Decline Option */}
          <div className="border-t pt-4 mt-4">
            <Button
              variant="ghost"
              className="w-full text-destructive hover:text-destructive"
              onClick={() => {
                setStatus("declined");
                setStep(5);
                onComplete?.({
                  sessionId,
                  participantId,
                  status: "declined",
                  permissions: {},
                  obtainedAt: new Date().toISOString(),
                });
              }}
            >
              <XCircle className="h-4 w-4 mr-2" />
              Decline Consent
            </Button>
          </div>
        </div>
      )}

      {/* Step 5: Confirmation */}
      {step === 5 && (
        <div className="text-center space-y-4">
          {status === "declined" ? (
            <>
              <div className="rounded-full bg-red-100 dark:bg-red-900 p-6 mx-auto w-fit">
                <XCircle className="h-12 w-12 text-red-600 dark:text-red-400" />
              </div>
              <h2 className="text-xl font-semibold">Consent Declined</h2>
              <p className="text-sm text-muted-foreground max-w-md mx-auto">
                The participant has declined to give consent. No data will be recorded for this session.
              </p>
            </>
          ) : (
            <>
              <div className="rounded-full bg-green-100 dark:bg-green-900 p-6 mx-auto w-fit">
                <ShieldCheck className="h-12 w-12 text-green-600 dark:text-green-400" />
              </div>
              <h2 className="text-xl font-semibold">Consent Obtained</h2>
              <p className="text-sm text-muted-foreground max-w-md mx-auto">
                {status === "written_consent"
                  ? `Written consent has been recorded. Signed by ${signatureName} on ${new Date().toLocaleDateString()}.`
                  : "Verbal consent has been recorded for this session."}
              </p>
              <Badge
                variant="success"
                className="mx-auto"
              >
                {STATUS_META[status].icon}
                <span className="ml-1">{STATUS_META[status].label}</span>
              </Badge>
            </>
          )}

          <div className="pt-4">
            <Button onClick={onCancel} variant="outline">
              Close
            </Button>
          </div>
        </div>
      )}

      {/* Navigation */}
      {step !== 5 && (
        <div className="flex items-center justify-between mt-6 pt-4 border-t">
          <Button
            variant="ghost"
            onClick={step === 1 ? onCancel : goBack}
          >
            {step === 1 ? (
              "Cancel"
            ) : (
              <>
                <ChevronLeft className="h-4 w-4 mr-1" />
                Back
              </>
            )}
          </Button>
          <Button
            onClick={step === 4 ? handleSave : goNext}
            disabled={!canProceed || (step === 4 && isSaving)}
          >
            {step === 4 ? (
              isSaving ? (
                "Saving..."
              ) : (
                <>
                  <ShieldCheck className="h-4 w-4 mr-1.5" />
                  Submit Consent
                </>
              )
            ) : (
              <>
                Next
                <ChevronRight className="h-4 w-4 ml-1" />
              </>
            )}
          </Button>
        </div>
      )}
    </div>
  );
}
