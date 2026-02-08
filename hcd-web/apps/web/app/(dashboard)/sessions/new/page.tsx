'use client';

import { useCallback, useEffect, useState, useRef } from 'react';
import { useRouter } from 'next/navigation';
import {
  MessageSquare,
  MousePointer,
  Compass,
  ChevronLeft,
  ChevronRight,
  Check,
  Mic,
  Video,
  Loader2,
  Search,
  Plus,
  FileText,
  Users,
  Shield,
} from 'lucide-react';
import { Button, Card, CardContent, CardHeader, CardTitle, Input, Badge } from '@hcd/ui';

// =============================================================================
// New Session Wizard — Multi-step session setup
// =============================================================================

type WizardStep = 1 | 2 | 3 | 4 | 5 | 6;

interface WizardData {
  sessionMode: 'interview' | 'usability_test' | 'discovery';
  templateId: string | null;
  templateName: string;
  participantId: string | null;
  participantName: string;
  newParticipantName: string;
  newParticipantEmail: string;
  audioSource: 'meeting' | 'local';
  meetingUrl: string;
  micPermissionGranted: boolean;
  audioLevel: number;
  consentEnabled: boolean;
  consentSignature: string;
  coachingEnabled: boolean;
  title: string;
}

interface Template {
  id: string;
  name: string;
  description: string | null;
  topics: string[];
}

interface Participant {
  id: string;
  name: string;
  email: string | null;
  role: string | null;
}

const INITIAL_DATA: WizardData = {
  sessionMode: 'interview',
  templateId: null,
  templateName: '',
  participantId: null,
  participantName: '',
  newParticipantName: '',
  newParticipantEmail: '',
  audioSource: 'meeting',
  meetingUrl: '',
  micPermissionGranted: false,
  audioLevel: 0,
  consentEnabled: false,
  consentSignature: '',
  coachingEnabled: false,
  title: '',
};

const STEPS: Array<{ label: string; icon: typeof MessageSquare }> = [
  { label: 'Type', icon: MessageSquare },
  { label: 'Template', icon: FileText },
  { label: 'Participant', icon: Users },
  { label: 'Audio', icon: Mic },
  { label: 'Consent', icon: Shield },
  { label: 'Review', icon: Check },
];

const SESSION_TYPES = [
  {
    id: 'interview' as const,
    label: 'Interview',
    description: 'Semi-structured or unstructured conversation',
    icon: MessageSquare,
  },
  {
    id: 'usability_test' as const,
    label: 'Usability Test',
    description: 'Task-based observation with think-aloud',
    icon: MousePointer,
  },
  {
    id: 'discovery' as const,
    label: 'Discovery',
    description: 'Exploratory research and contextual inquiry',
    icon: Compass,
  },
];

export default function NewSessionPage() {
  const router = useRouter();
  const [step, setStep] = useState<WizardStep>(1);
  const [data, setData] = useState<WizardData>(INITIAL_DATA);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Template & participant search
  const [templates, setTemplates] = useState<Template[]>([]);
  const [participants, setParticipants] = useState<Participant[]>([]);
  const [templateSearch, setTemplateSearch] = useState('');
  const [participantSearch, setParticipantSearch] = useState('');
  const [creatingParticipant, setCreatingParticipant] = useState(false);

  // Audio level meter
  const audioStreamRef = useRef<MediaStream | null>(null);
  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const animFrameRef = useRef<number | null>(null);

  // Fetch templates
  useEffect(() => {
    fetch('/api/templates')
      .then((r) => r.ok ? r.json() : { data: [] })
      .then((res) => setTemplates(res.data || []))
      .catch(() => setTemplates([]));
  }, []);

  // Fetch participants
  useEffect(() => {
    fetch('/api/participants')
      .then((r) => r.ok ? r.json() : { data: [] })
      .then((res) => setParticipants(res.data || []))
      .catch(() => setParticipants([]));
  }, []);

  // Cleanup audio on unmount
  useEffect(() => {
    return () => {
      if (audioStreamRef.current) {
        audioStreamRef.current.getTracks().forEach((t) => t.stop());
      }
      if (audioContextRef.current) {
        audioContextRef.current.close();
      }
      if (animFrameRef.current) {
        cancelAnimationFrame(animFrameRef.current);
      }
    };
  }, []);

  const update = useCallback((patch: Partial<WizardData>) => {
    setData((prev) => ({ ...prev, ...patch }));
  }, []);

  const goNext = useCallback(() => {
    setStep((s) => Math.min(6, s + 1) as WizardStep);
  }, []);

  const goBack = useCallback(() => {
    setStep((s) => Math.max(1, s - 1) as WizardStep);
  }, []);

  // Request microphone permission and start level meter
  const requestMic = useCallback(async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      audioStreamRef.current = stream;

      const ctx = new AudioContext();
      audioContextRef.current = ctx;
      const analyser = ctx.createAnalyser();
      analyserRef.current = analyser;
      analyser.fftSize = 256;

      const source = ctx.createMediaStreamSource(stream);
      source.connect(analyser);

      const dataArray = new Uint8Array(analyser.frequencyBinCount);

      const measure = () => {
        analyser.getByteFrequencyData(dataArray);
        const avg = dataArray.reduce((sum, v) => sum + v, 0) / dataArray.length;
        update({ audioLevel: avg / 255, micPermissionGranted: true });
        animFrameRef.current = requestAnimationFrame(measure);
      };

      measure();
    } catch {
      update({ micPermissionGranted: false });
    }
  }, [update]);

  // Submit session
  const handleSubmit = useCallback(async () => {
    setIsSubmitting(true);

    try {
      // If creating a new participant
      let participantId = data.participantId;
      if (creatingParticipant && data.newParticipantName) {
        const pRes = await fetch('/api/participants', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            name: data.newParticipantName,
            email: data.newParticipantEmail || undefined,
          }),
        });
        if (pRes.ok) {
          const pData = await pRes.json();
          participantId = pData.data?.id || null;
        }
      }

      const title = data.title || `${SESSION_TYPES.find((t) => t.id === data.sessionMode)?.label || 'Session'} - ${new Date().toLocaleDateString()}`;

      const res = await fetch('/api/sessions', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title,
          sessionMode: data.sessionMode,
          templateId: data.templateId,
          participantId,
          coachingEnabled: data.coachingEnabled,
          meetingUrl: data.audioSource === 'meeting' ? data.meetingUrl : undefined,
        }),
      });

      if (!res.ok) throw new Error('Failed to create session');
      const { data: session } = await res.json();

      // Navigate to live session
      router.push(`/sessions/${session.id}/live`);
    } catch (err) {
      console.error('Failed to create session:', err);
      setIsSubmitting(false);
    }
  }, [data, creatingParticipant, router]);

  // Filter templates and participants by search
  const filteredTemplates = templates.filter(
    (t) =>
      !templateSearch ||
      t.name.toLowerCase().includes(templateSearch.toLowerCase())
  );

  const filteredParticipants = participants.filter(
    (p) =>
      !participantSearch ||
      p.name.toLowerCase().includes(participantSearch.toLowerCase()) ||
      (p.email && p.email.toLowerCase().includes(participantSearch.toLowerCase()))
  );

  return (
    <div className="max-w-2xl mx-auto">
      {/* Progress indicator */}
      <nav className="flex items-center gap-1 mb-8" aria-label="Wizard progress">
        {STEPS.map((s, idx) => {
          const stepNum = (idx + 1) as WizardStep;
          const Icon = s.icon;
          const isActive = step === stepNum;
          const isComplete = step > stepNum;

          return (
            <div key={s.label} className="flex items-center">
              <button
                type="button"
                onClick={() => stepNum < step && setStep(stepNum)}
                disabled={stepNum > step}
                className={`
                  flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-colors
                  ${isActive ? 'bg-primary text-primary-foreground' : ''}
                  ${isComplete ? 'bg-primary/10 text-primary hover:bg-primary/20' : ''}
                  ${!isActive && !isComplete ? 'text-muted-foreground' : ''}
                `}
                aria-current={isActive ? 'step' : undefined}
                aria-label={`Step ${stepNum}: ${s.label}${isComplete ? ' (completed)' : ''}`}
              >
                {isComplete ? (
                  <Check className="h-3.5 w-3.5" aria-hidden="true" />
                ) : (
                  <Icon className="h-3.5 w-3.5" aria-hidden="true" />
                )}
                <span className="hidden sm:inline">{s.label}</span>
              </button>
              {idx < STEPS.length - 1 && (
                <div className={`w-6 h-px mx-1 ${isComplete ? 'bg-primary' : 'bg-border'}`} aria-hidden="true" />
              )}
            </div>
          );
        })}
      </nav>

      {/* Step content */}
      <Card>
        <CardContent className="p-6">
          {/* STEP 1: Session Type */}
          {step === 1 && (
            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold">What type of session?</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  This determines coaching prompts and analysis.
                </p>
              </div>
              <div className="grid gap-3">
                {SESSION_TYPES.map((type) => {
                  const Icon = type.icon;
                  const isSelected = data.sessionMode === type.id;

                  return (
                    <button
                      key={type.id}
                      type="button"
                      onClick={() => update({ sessionMode: type.id })}
                      className={`
                        flex items-start gap-4 rounded-xl border p-4 text-left transition-colors
                        ${isSelected ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'hover:bg-muted/50'}
                      `}
                      aria-pressed={isSelected}
                    >
                      <div className={`rounded-lg p-2 ${isSelected ? 'bg-primary text-primary-foreground' : 'bg-muted'}`}>
                        <Icon className="h-5 w-5" aria-hidden="true" />
                      </div>
                      <div>
                        <p className="font-medium">{type.label}</p>
                        <p className="text-sm text-muted-foreground mt-0.5">{type.description}</p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* STEP 2: Template Selection */}
          {step === 2 && (
            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold">Choose a template</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  Templates provide topic lists and coaching prompts. Optional.
                </p>
              </div>

              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" aria-hidden="true" />
                <Input
                  type="text"
                  placeholder="Search templates..."
                  value={templateSearch}
                  onChange={(e) => setTemplateSearch(e.target.value)}
                  className="pl-9"
                  aria-label="Search templates"
                />
              </div>

              <div className="space-y-2 max-h-64 overflow-y-auto scrollbar-thin">
                {/* No template option */}
                <button
                  type="button"
                  onClick={() => update({ templateId: null, templateName: '' })}
                  className={`
                    w-full flex items-center gap-3 rounded-lg border p-3 text-left transition-colors
                    ${data.templateId === null ? 'border-primary bg-primary/5' : 'hover:bg-muted/50'}
                  `}
                  aria-pressed={data.templateId === null}
                >
                  <FileText className="h-4 w-4 text-muted-foreground shrink-0" aria-hidden="true" />
                  <div>
                    <p className="text-sm font-medium">No template</p>
                    <p className="text-xs text-muted-foreground">Start with a blank session</p>
                  </div>
                </button>

                {filteredTemplates.map((tmpl) => (
                  <button
                    key={tmpl.id}
                    type="button"
                    onClick={() => update({ templateId: tmpl.id, templateName: tmpl.name })}
                    className={`
                      w-full flex items-start gap-3 rounded-lg border p-3 text-left transition-colors
                      ${data.templateId === tmpl.id ? 'border-primary bg-primary/5' : 'hover:bg-muted/50'}
                    `}
                    aria-pressed={data.templateId === tmpl.id}
                  >
                    <FileText className="h-4 w-4 text-muted-foreground shrink-0 mt-0.5" aria-hidden="true" />
                    <div className="min-w-0">
                      <p className="text-sm font-medium">{tmpl.name}</p>
                      {tmpl.description && (
                        <p className="text-xs text-muted-foreground mt-0.5 truncate">{tmpl.description}</p>
                      )}
                      {tmpl.topics.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-1.5">
                          {tmpl.topics.slice(0, 4).map((topic) => (
                            <Badge key={topic} variant="secondary" className="text-[10px]">
                              {topic}
                            </Badge>
                          ))}
                          {tmpl.topics.length > 4 && (
                            <Badge variant="outline" className="text-[10px]">
                              +{tmpl.topics.length - 4}
                            </Badge>
                          )}
                        </div>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* STEP 3: Participant */}
          {step === 3 && (
            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold">Who are you speaking with?</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  Select an existing participant or add a new one.
                </p>
              </div>

              {!creatingParticipant ? (
                <>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" aria-hidden="true" />
                    <Input
                      type="text"
                      placeholder="Search participants..."
                      value={participantSearch}
                      onChange={(e) => setParticipantSearch(e.target.value)}
                      className="pl-9"
                      aria-label="Search participants"
                    />
                  </div>

                  <div className="space-y-2 max-h-48 overflow-y-auto scrollbar-thin">
                    {filteredParticipants.map((p) => (
                      <button
                        key={p.id}
                        type="button"
                        onClick={() => update({ participantId: p.id, participantName: p.name })}
                        className={`
                          w-full flex items-center gap-3 rounded-lg border p-3 text-left transition-colors
                          ${data.participantId === p.id ? 'border-primary bg-primary/5' : 'hover:bg-muted/50'}
                        `}
                        aria-pressed={data.participantId === p.id}
                      >
                        <div className="h-8 w-8 rounded-full bg-emerald-100 dark:bg-emerald-900 flex items-center justify-center text-sm font-medium text-emerald-700 dark:text-emerald-300">
                          {p.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="text-sm font-medium">{p.name}</p>
                          {(p.email || p.role) && (
                            <p className="text-xs text-muted-foreground">
                              {[p.email, p.role].filter(Boolean).join(' - ')}
                            </p>
                          )}
                        </div>
                      </button>
                    ))}
                  </div>

                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setCreatingParticipant(true)}
                    className="w-full"
                    aria-label="Add new participant"
                  >
                    <Plus className="h-4 w-4 mr-2" aria-hidden="true" />
                    Add New Participant
                  </Button>
                </>
              ) : (
                <div className="space-y-3">
                  <div>
                    <label htmlFor="newName" className="text-sm font-medium mb-1 block">
                      Name <span className="text-red-500">*</span>
                    </label>
                    <Input
                      id="newName"
                      value={data.newParticipantName}
                      onChange={(e) => update({ newParticipantName: e.target.value })}
                      placeholder="Participant name"
                      aria-required="true"
                    />
                  </div>
                  <div>
                    <label htmlFor="newEmail" className="text-sm font-medium mb-1 block">
                      Email (optional)
                    </label>
                    <Input
                      id="newEmail"
                      type="email"
                      value={data.newParticipantEmail}
                      onChange={(e) => update({ newParticipantEmail: e.target.value })}
                      placeholder="email@example.com"
                    />
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => {
                      setCreatingParticipant(false);
                      update({ newParticipantName: '', newParticipantEmail: '' });
                    }}
                  >
                    Back to search
                  </Button>
                </div>
              )}
            </div>
          )}

          {/* STEP 4: Audio Source */}
          {step === 4 && (
            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold">Audio source</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  How will audio be captured for this session?
                </p>
              </div>

              <div className="grid gap-3">
                {/* Meeting link */}
                <button
                  type="button"
                  onClick={() => update({ audioSource: 'meeting' })}
                  className={`
                    flex items-start gap-4 rounded-xl border p-4 text-left transition-colors
                    ${data.audioSource === 'meeting' ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'hover:bg-muted/50'}
                  `}
                  aria-pressed={data.audioSource === 'meeting'}
                >
                  <div className={`rounded-lg p-2 ${data.audioSource === 'meeting' ? 'bg-primary text-primary-foreground' : 'bg-muted'}`}>
                    <Video className="h-5 w-5" aria-hidden="true" />
                  </div>
                  <div>
                    <p className="font-medium">Meeting Link</p>
                    <p className="text-sm text-muted-foreground mt-0.5">
                      Paste a Zoom, Google Meet, or Teams URL
                    </p>
                  </div>
                </button>

                {/* Local microphone */}
                <button
                  type="button"
                  onClick={() => update({ audioSource: 'local' })}
                  className={`
                    flex items-start gap-4 rounded-xl border p-4 text-left transition-colors
                    ${data.audioSource === 'local' ? 'border-primary bg-primary/5 ring-1 ring-primary/20' : 'hover:bg-muted/50'}
                  `}
                  aria-pressed={data.audioSource === 'local'}
                >
                  <div className={`rounded-lg p-2 ${data.audioSource === 'local' ? 'bg-primary text-primary-foreground' : 'bg-muted'}`}>
                    <Mic className="h-5 w-5" aria-hidden="true" />
                  </div>
                  <div>
                    <p className="font-medium">Local Microphone</p>
                    <p className="text-sm text-muted-foreground mt-0.5">
                      Use your browser microphone for in-person sessions
                    </p>
                  </div>
                </button>
              </div>

              {/* Meeting URL input */}
              {data.audioSource === 'meeting' && (
                <div className="mt-4">
                  <label htmlFor="meetingUrl" className="text-sm font-medium mb-1 block">
                    Meeting URL
                  </label>
                  <Input
                    id="meetingUrl"
                    type="url"
                    value={data.meetingUrl}
                    onChange={(e) => update({ meetingUrl: e.target.value })}
                    placeholder="https://zoom.us/j/... or https://meet.google.com/..."
                    aria-label="Meeting URL"
                  />
                  <p className="text-xs text-muted-foreground mt-1">
                    Supports Zoom, Google Meet, and Microsoft Teams links
                  </p>
                </div>
              )}

              {/* Local mic setup */}
              {data.audioSource === 'local' && (
                <div className="mt-4 space-y-3">
                  {!data.micPermissionGranted ? (
                    <Button onClick={requestMic} variant="outline" aria-label="Enable microphone">
                      <Mic className="h-4 w-4 mr-2" aria-hidden="true" />
                      Enable Microphone
                    </Button>
                  ) : (
                    <div className="space-y-2">
                      <div className="flex items-center gap-2 text-sm text-green-600 dark:text-green-400">
                        <Check className="h-4 w-4" aria-hidden="true" />
                        Microphone connected
                      </div>
                      {/* Audio level meter */}
                      <div>
                        <label className="text-xs text-muted-foreground block mb-1">Audio Level</label>
                        <div className="h-3 w-full rounded-full bg-muted overflow-hidden">
                          <div
                            className="h-full bg-green-500 transition-all duration-75"
                            style={{ width: `${Math.min(100, data.audioLevel * 100)}%` }}
                            role="meter"
                            aria-label="Audio input level"
                            aria-valuenow={Math.round(data.audioLevel * 100)}
                            aria-valuemin={0}
                            aria-valuemax={100}
                          />
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* STEP 5: Consent */}
          {step === 5 && (
            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold">Consent capture</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  Optionally capture participant consent before starting.
                </p>
              </div>

              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={data.consentEnabled}
                  onChange={(e) => update({ consentEnabled: e.target.checked })}
                  className="rounded border-input h-4 w-4 text-primary"
                  aria-label="Enable consent capture"
                />
                <span className="text-sm">Require consent before recording</span>
              </label>

              {data.consentEnabled && (
                <Card className="p-4 space-y-3 bg-muted/30">
                  <p className="text-sm">
                    By participating in this session, you consent to audio recording
                    and transcription for research purposes. Your data will be handled
                    according to our privacy policy.
                  </p>

                  <div>
                    <label htmlFor="consentSig" className="text-sm font-medium mb-1 block">
                      Participant name (as signature)
                    </label>
                    <Input
                      id="consentSig"
                      value={data.consentSignature}
                      onChange={(e) => update({ consentSignature: e.target.value })}
                      placeholder="Type full name to consent"
                      aria-label="Consent signature"
                    />
                  </div>
                </Card>
              )}

              <div className="border-t pt-4 mt-4">
                <label className="flex items-center gap-3 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={data.coachingEnabled}
                    onChange={(e) => update({ coachingEnabled: e.target.checked })}
                    className="rounded border-input h-4 w-4 text-primary"
                    aria-label="Enable AI coaching"
                  />
                  <div>
                    <span className="text-sm font-medium">Enable AI coaching</span>
                    <p className="text-xs text-muted-foreground">
                      Get real-time coaching prompts during the session
                    </p>
                  </div>
                </label>
              </div>
            </div>
          )}

          {/* STEP 6: Review */}
          {step === 6 && (
            <div className="space-y-4">
              <div>
                <h2 className="text-lg font-semibold">Review and start</h2>
                <p className="text-sm text-muted-foreground mt-1">
                  Confirm your session settings before starting.
                </p>
              </div>

              <div>
                <label htmlFor="sessionTitle" className="text-sm font-medium mb-1 block">
                  Session title
                </label>
                <Input
                  id="sessionTitle"
                  value={data.title}
                  onChange={(e) => update({ title: e.target.value })}
                  placeholder={`${SESSION_TYPES.find((t) => t.id === data.sessionMode)?.label || 'Session'} - ${new Date().toLocaleDateString()}`}
                  aria-label="Session title"
                />
              </div>

              <div className="rounded-lg border divide-y">
                <ReviewRow label="Type" value={SESSION_TYPES.find((t) => t.id === data.sessionMode)?.label || data.sessionMode} />
                <ReviewRow
                  label="Template"
                  value={data.templateName || 'None'}
                />
                <ReviewRow
                  label="Participant"
                  value={
                    creatingParticipant
                      ? data.newParticipantName || 'New participant'
                      : data.participantName || 'Not selected'
                  }
                />
                <ReviewRow
                  label="Audio"
                  value={
                    data.audioSource === 'meeting'
                      ? `Meeting: ${data.meetingUrl || 'No URL'}`
                      : `Local mic${data.micPermissionGranted ? ' (ready)' : ' (not enabled)'}`
                  }
                />
                <ReviewRow label="Consent" value={data.consentEnabled ? 'Enabled' : 'Skipped'} />
                <ReviewRow label="Coaching" value={data.coachingEnabled ? 'Enabled' : 'Disabled'} />
              </div>
            </div>
          )}
        </CardContent>

        {/* Navigation */}
        <div className="flex items-center justify-between p-6 pt-0">
          <Button
            variant="ghost"
            onClick={goBack}
            disabled={step === 1}
            aria-label="Go to previous step"
          >
            <ChevronLeft className="h-4 w-4 mr-1" aria-hidden="true" />
            Back
          </Button>

          {step < 6 ? (
            <Button onClick={goNext} aria-label="Go to next step">
              Next
              <ChevronRight className="h-4 w-4 ml-1" aria-hidden="true" />
            </Button>
          ) : (
            <Button
              onClick={handleSubmit}
              disabled={isSubmitting}
              aria-label="Start session"
            >
              {isSubmitting ? (
                <Loader2 className="h-4 w-4 mr-2 animate-spin" aria-hidden="true" />
              ) : (
                <Check className="h-4 w-4 mr-2" aria-hidden="true" />
              )}
              Start Session
            </Button>
          )}
        </div>
      </Card>
    </div>
  );
}

// =============================================================================
// ReviewRow — Key-value display row
// =============================================================================

function ReviewRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between px-4 py-2.5 text-sm">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-medium truncate max-w-[240px] text-right">{value}</span>
    </div>
  );
}
