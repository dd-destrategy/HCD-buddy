# HCD Interview Coach — Frequently Asked Questions

This document answers common questions about using HCD Interview Coach.

---

## Table of Contents

1. [Audio Setup](#audio-setup)
2. [Coaching Features](#coaching-features)
3. [Sessions and Data](#sessions-and-data)
4. [API and Costs](#api-and-costs)
5. [Troubleshooting](#troubleshooting)

---

## Audio Setup

### How do I set up BlackHole?

BlackHole is a free virtual audio driver that allows the app to capture system audio (the audio from your video conferencing tool).

**Installation Steps:**

1. **Install BlackHole via Homebrew:**
   ```bash
   brew install blackhole-2ch
   ```

   Alternatively, download from [existential.audio/blackhole](https://existential.audio/blackhole/).

2. **Create a Multi-Output Device:**
   - Open **Audio MIDI Setup** (Applications > Utilities > Audio MIDI Setup)
   - Click the **+** button in the bottom left corner
   - Select **Create Multi-Output Device**
   - Check both your speakers/headphones **AND** BlackHole 2ch
   - Optionally rename it to "Interview Audio" for clarity

3. **Set as System Output:**
   - Go to **System Settings > Sound > Output**
   - Select your new Multi-Output Device

4. **Verify in HCD Interview Coach:**
   - Open the app and go through the 6-screen audio setup wizard
   - The app will detect BlackHole and guide you through configuration

**Note:** You only need to do this setup once. The Multi-Output Device persists across restarts.

---

### Why can't the app hear my audio?

If the app shows no audio levels or transcription, check these common causes:

1. **Multi-Output Device not selected:**
   - Verify System Settings > Sound > Output shows your Multi-Output Device

2. **BlackHole not included in Multi-Output Device:**
   - Open Audio MIDI Setup and confirm BlackHole 2ch is checked in your Multi-Output Device

3. **Meeting audio not playing:**
   - Ensure your video conferencing app (Zoom, Meet, Teams) is outputting audio
   - Check that meeting participants are not muted

4. **Wrong input selected in app:**
   - In the app's audio setup, ensure BlackHole 2ch is selected as the input source

5. **Microphone permissions denied:**
   - Go to System Settings > Privacy & Security > Microphone
   - Ensure HCD Interview Coach has permission

6. **BlackHole not installed correctly:**
   - Reinstall BlackHole: `brew reinstall blackhole-2ch`
   - Restart CoreAudio: `sudo killall coreaudiod`

See [Troubleshooting](#troubleshooting) for more solutions.

---

## Coaching Features

### How do I enable coaching?

Coaching is **disabled by default** for your first session. This is intentional — we want you to experience the transcription first before adding AI suggestions.

**To enable coaching:**

1. Open the app and go to **Settings** (keyboard shortcut: **Cmd+,**)
2. Navigate to the **Coaching** tab
3. Toggle **Enable Coaching** to ON
4. Choose your coaching level:
   - **Minimal:** Very rare prompts, only when highly confident
   - **Balanced:** Moderate prompts with good confidence (recommended)
   - **Active:** More frequent suggestions

You can also toggle coaching during a session using **Cmd+M**.

---

### What's "silence-first" coaching?

"Silence-first" is our core coaching philosophy. It means the AI assistant stays **quiet unless genuinely needed**, respecting the natural flow of human conversation.

**How it works:**

- **No interruptions:** The AI never shows prompts while someone is speaking
- **5-second delay:** After any speech ends, the AI waits at least 5 seconds before considering a prompt
- **High confidence threshold:** Prompts only appear when the AI is 85%+ confident they're helpful
- **2-minute cooldown:** After showing a prompt, the AI waits at least 2 minutes before showing another
- **Session limits:** Maximum of 3 prompts per session (fewer for minimal level)
- **Auto-dismiss:** Prompts disappear after 8 seconds if not interacted with

**Why silence-first?**

In UX research interviews, the magic often happens in silence — when participants are thinking, formulating thoughts, or about to share something important. Interrupting with suggestions can break this flow and harm the research quality.

---

## Sessions and Data

### How do I export my session?

After completing an interview session:

1. The session ends and you'll see the **Post-Session Summary** view
2. Click **Export** or use keyboard shortcut **Cmd+S**
3. Choose your export format:
   - **Markdown (.md):** Human-readable format, great for sharing and review
   - **JSON (.json):** Structured data format, ideal for further analysis
4. Select a save location
5. The file will include:
   - Session metadata (participant, project, date, duration)
   - Full transcript with speaker labels and timestamps
   - Flagged insights
   - Topic coverage summary
   - Coaching events (if enabled)

**Tip:** Flag important moments during the interview with **Cmd+I** — these appear highlighted in exports.

---

### Is my data stored locally or in the cloud?

**All your data is stored locally on your Mac.** We prioritize your privacy and your participants' privacy.

**Local storage includes:**
- Session recordings metadata
- Transcripts
- Flagged insights
- Topic coverage data
- Coaching event history
- Your preferences and settings

**What goes to the cloud:**
- **Audio streams to OpenAI:** During active sessions, audio is streamed to OpenAI's Realtime API for transcription and coaching. This is required for the AI features to work.
- **No permanent cloud storage:** OpenAI processes the audio in real-time but does not permanently store your interview data.

**Security measures:**
- API keys are stored in macOS Keychain (not in plain text)
- App Sandbox enabled for additional security
- No analytics or telemetry data collection
- No cloud sync — your data stays on your machine

---

## API and Costs

### What API key do I need?

You need an **OpenAI API key** with access to the Realtime API.

**Getting your API key:**

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign in or create an account
3. Navigate to **API Keys** in the left sidebar
4. Click **Create new secret key**
5. Copy the key (you won't be able to see it again)

**Setting up in HCD Interview Coach:**

1. Open the app
2. Go to **Settings** (Cmd+,) > **API**
3. Paste your API key
4. The key is stored securely in your macOS Keychain

**Note:** The OpenAI Realtime API may require a paid account or specific tier access. Check OpenAI's documentation for current requirements.

---

### How much does the OpenAI API cost?

OpenAI charges based on usage. For the Realtime API used by HCD Interview Coach:

**Current pricing model (check OpenAI for latest):**
- **Audio input:** Charged per minute of audio streamed
- **Text output:** Charged per token for transcription and coaching responses

**Estimated costs for a typical interview session:**

| Session Length | Estimated Cost* |
|----------------|-----------------|
| 30 minutes     | $2 - $5         |
| 60 minutes     | $4 - $10        |
| 90 minutes     | $6 - $15        |

*Estimates based on typical usage patterns. Actual costs depend on:
- Amount of speech (silent periods cost less)
- Coaching frequency (more prompts = slightly higher cost)
- Audio quality and complexity

**Tips to manage costs:**
- Use transcription-only mode for lower-stakes interviews
- Reduce coaching level to minimize AI responses
- Monitor your OpenAI dashboard for usage tracking

**Important:** Pricing changes frequently. Always check [openai.com/pricing](https://openai.com/pricing) for current rates.

---

## Troubleshooting

### The app says "BlackHole not detected"

1. **Verify installation:**
   ```bash
   # Check if BlackHole is installed
   brew list blackhole-2ch
   ```

2. **Reinstall if needed:**
   ```bash
   brew reinstall blackhole-2ch
   ```

3. **Restart CoreAudio:**
   ```bash
   sudo killall coreaudiod
   ```

4. **Restart your Mac** if the above steps don't work

---

### Transcription is delayed or inaccurate

- **Check your internet connection:** The Realtime API requires a stable connection
- **Reduce background noise:** Close unnecessary applications and audio sources
- **Check audio levels:** Ensure the audio meter shows activity when people speak
- **Verify speaker distance:** Participants should speak clearly into their microphones

---

### Coaching prompts aren't appearing

1. **Verify coaching is enabled:** Settings > Coaching > Enable Coaching
2. **Check coaching level:** Minimal level shows very few prompts
3. **Session limit reached:** Maximum 3 prompts per session (2 for minimal level)
4. **Cooldown active:** 2-minute cooldown between prompts
5. **Confidence too low:** AI may not have high-confidence suggestions for your conversation

---

### The app crashes or freezes

1. **Check macOS version:** Requires macOS 13.0 (Ventura) or later
2. **Update the app:** Check for updates via the app menu
3. **Reset preferences:**
   ```bash
   defaults delete com.hcd.interviewcoach
   ```
4. **Check Console app:** Look for crash logs related to HCDInterviewCoach
5. **Report the issue:** File a bug report with crash logs at our GitHub Issues page

---

### Session won't start

- **API key not set:** Go to Settings > API and enter your OpenAI key
- **Network issues:** Check your internet connection
- **Audio not configured:** Complete the audio setup wizard
- **Previous session not ended:** If a session is stuck, force quit and restart the app

---

## Still Need Help?

- **GitHub Issues:** [github.com/dd-destrategy/HCD-buddy/issues](https://github.com/dd-destrategy/HCD-buddy/issues)
- **Documentation:** See the `/docs` folder for detailed guides
- **Architecture:** Review `CODEBASE_REVIEW.md` for technical details

---

**Last Updated:** February 2026
