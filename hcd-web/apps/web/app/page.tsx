import { redirect } from "next/navigation";
import { headers } from "next/headers";
import { auth } from "@hcd/auth";
import Link from "next/link";
import {
  Mic,
  Brain,
  FileText,
  Shield,
  ArrowRight,
  Sparkles,
} from "lucide-react";

async function getSession() {
  try {
    const headersList = await headers();
    const cookie = headersList.get("cookie");
    const response = await fetch(
      `${process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"}/api/auth/get-session`,
      {
        headers: cookie ? { cookie } : {},
      }
    );
    if (response.ok) {
      const data = await response.json();
      return data?.user ? data : null;
    }
    return null;
  } catch {
    return null;
  }
}

export default async function LandingPage() {
  const session = await getSession();

  if (session) {
    redirect("/sessions");
  }

  return (
    <div className="min-h-screen auth-gradient">
      {/* Header */}
      <header className="border-b border-border/40 glass-toolbar">
        <div className="container mx-auto flex h-16 items-center justify-between px-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
              <Mic className="h-4 w-4 text-primary-foreground" />
            </div>
            <span className="text-lg font-semibold tracking-tight">
              HCD Interview Coach
            </span>
          </div>
          <nav className="flex items-center gap-4">
            <Link
              href="/sign-in"
              className="text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
              aria-label="Sign in to your account"
            >
              Sign in
            </Link>
            <Link
              href="/sign-up"
              className="inline-flex h-9 items-center justify-center rounded-lg bg-primary px-4 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
              aria-label="Create a new account"
            >
              Get Started
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <main>
        <section className="container mx-auto px-4 py-24 text-center">
          <div className="mx-auto max-w-3xl">
            <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-border bg-card px-4 py-1.5 text-sm text-muted-foreground">
              <Sparkles className="h-3.5 w-3.5" />
              AI-powered UX research support
            </div>
            <h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">
              Conduct better
              <br />
              <span className="text-primary">research interviews</span>
            </h1>
            <p className="mt-6 text-lg text-muted-foreground max-w-2xl mx-auto">
              Real-time transcription, contextual coaching prompts, and
              intelligent analysis -- all designed with a silence-first
              philosophy that respects the natural flow of conversation.
            </p>
            <div className="mt-10 flex items-center justify-center gap-4">
              <Link
                href="/sign-up"
                className="inline-flex h-11 items-center justify-center gap-2 rounded-lg bg-primary px-8 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
                aria-label="Get started with HCD Interview Coach"
              >
                Get Started
                <ArrowRight className="h-4 w-4" />
              </Link>
              <Link
                href="/sign-in"
                className="inline-flex h-11 items-center justify-center rounded-lg border border-input bg-background px-8 text-sm font-medium hover:bg-accent hover:text-accent-foreground transition-colors"
                aria-label="Sign in to existing account"
              >
                Sign In
              </Link>
            </div>
          </div>
        </section>

        {/* Features */}
        <section className="container mx-auto px-4 pb-24">
          <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-4">
            <FeatureCard
              icon={<Mic className="h-6 w-6" />}
              title="Live Transcription"
              description="Capture and transcribe interviews in real time with speaker identification and timestamp tracking."
            />
            <FeatureCard
              icon={<Brain className="h-6 w-6" />}
              title="Silence-First Coaching"
              description="AI coaching that stays quiet unless genuinely needed, respecting the natural flow of your interviews."
            />
            <FeatureCard
              icon={<FileText className="h-6 w-6" />}
              title="Smart Analysis"
              description="Automatic topic tracking, sentiment analysis, and insight detection across all your sessions."
            />
            <FeatureCard
              icon={<Shield className="h-6 w-6" />}
              title="Privacy-First"
              description="PII detection and redaction, consent tracking, and secure local-first data storage."
            />
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-border/40 py-8">
        <div className="container mx-auto px-4 text-center text-sm text-muted-foreground">
          <p>HCD Interview Coach -- Built for UX researchers, by UX researchers.</p>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode;
  title: string;
  description: string;
}) {
  return (
    <div className="glass-card rounded-xl p-6">
      <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10 text-primary">
        {icon}
      </div>
      <h3 className="mb-2 text-lg font-semibold">{title}</h3>
      <p className="text-sm text-muted-foreground">{description}</p>
    </div>
  );
}
