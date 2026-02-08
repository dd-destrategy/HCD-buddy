import { Mic } from "lucide-react";
import Link from "next/link";

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen auth-gradient flex flex-col">
      {/* Minimal header */}
      <header className="flex h-16 items-center px-6">
        <Link
          href="/"
          className="flex items-center gap-2 hover:opacity-80 transition-opacity"
          aria-label="Back to home page"
        >
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
            <Mic className="h-4 w-4 text-primary-foreground" />
          </div>
          <span className="text-lg font-semibold tracking-tight">
            HCD Interview Coach
          </span>
        </Link>
      </header>

      {/* Centered card container */}
      <main className="flex flex-1 items-center justify-center px-4 pb-16">
        <div className="w-full max-w-md">
          <div className="glass-card rounded-2xl border border-border bg-card p-8 shadow-lg">
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}
