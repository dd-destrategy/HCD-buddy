// =============================================================================
// Server-side Audio Processing Utilities
// Voice Activity Detection, format conversion, and audio level metering
// =============================================================================

/**
 * Configuration for Voice Activity Detection.
 */
export interface VADConfig {
  /** RMS energy threshold below which audio is considered silence (0.0 - 1.0). Default: 0.01 */
  energyThreshold: number;
  /** Number of consecutive silent frames before declaring silence. Default: 30 (~600ms at 50fps) */
  silenceFrames: number;
  /** Number of consecutive speech frames before declaring speech. Default: 3 (~60ms at 50fps) */
  speechFrames: number;
  /** Sample rate of the incoming audio. Default: 24000 */
  sampleRate: number;
  /** Frame size in samples for VAD analysis. Default: 480 (20ms at 24kHz) */
  frameSize: number;
}

const DEFAULT_VAD_CONFIG: VADConfig = {
  energyThreshold: 0.01,
  silenceFrames: 30,
  speechFrames: 3,
  sampleRate: 24000,
  frameSize: 480,
};

export type VADState = 'silence' | 'speech' | 'uncertain';

export interface VADResult {
  state: VADState;
  energy: number;
  isSpeech: boolean;
}

/**
 * Simple energy-based Voice Activity Detection.
 *
 * Analyzes PCM audio frames to determine whether speech is present.
 * Uses RMS energy with hysteresis (separate speech-start and silence-start thresholds)
 * to avoid rapid toggling.
 */
export class VoiceActivityDetector {
  private config: VADConfig;
  private consecutiveSilentFrames = 0;
  private consecutiveSpeechFrames = 0;
  private currentState: VADState = 'silence';
  private smoothedEnergy = 0;
  private readonly smoothingFactor = 0.3;

  constructor(config: Partial<VADConfig> = {}) {
    this.config = { ...DEFAULT_VAD_CONFIG, ...config };
  }

  /**
   * Process a single frame of PCM 16-bit LE audio and return the VAD result.
   * @param pcmData - Buffer of 16-bit signed little-endian PCM samples
   */
  processFrame(pcmData: Buffer): VADResult {
    const energy = this.calculateRMSEnergy(pcmData);
    // Exponential moving average to smooth energy
    this.smoothedEnergy =
      this.smoothingFactor * energy + (1 - this.smoothingFactor) * this.smoothedEnergy;

    const frameIsSpeech = this.smoothedEnergy > this.config.energyThreshold;

    if (frameIsSpeech) {
      this.consecutiveSpeechFrames++;
      this.consecutiveSilentFrames = 0;
    } else {
      this.consecutiveSilentFrames++;
      this.consecutiveSpeechFrames = 0;
    }

    // State transitions with hysteresis
    if (this.currentState === 'silence' || this.currentState === 'uncertain') {
      if (this.consecutiveSpeechFrames >= this.config.speechFrames) {
        this.currentState = 'speech';
      } else if (this.consecutiveSpeechFrames > 0) {
        this.currentState = 'uncertain';
      } else {
        this.currentState = 'silence';
      }
    } else {
      // Currently in speech
      if (this.consecutiveSilentFrames >= this.config.silenceFrames) {
        this.currentState = 'silence';
      }
    }

    return {
      state: this.currentState,
      energy: this.smoothedEnergy,
      isSpeech: this.currentState === 'speech',
    };
  }

  /**
   * Calculate RMS energy of a PCM 16-bit LE buffer.
   * Returns a value between 0.0 and 1.0.
   */
  private calculateRMSEnergy(pcmData: Buffer): number {
    const sampleCount = Math.floor(pcmData.length / 2);
    if (sampleCount === 0) return 0;

    let sumSquares = 0;
    for (let i = 0; i < sampleCount; i++) {
      const sample = pcmData.readInt16LE(i * 2);
      const normalized = sample / 32768;
      sumSquares += normalized * normalized;
    }

    return Math.sqrt(sumSquares / sampleCount);
  }

  /** Reset the detector state. */
  reset(): void {
    this.consecutiveSilentFrames = 0;
    this.consecutiveSpeechFrames = 0;
    this.currentState = 'silence';
    this.smoothedEnergy = 0;
  }

  /** Get the current VAD state without processing a new frame. */
  getState(): VADState {
    return this.currentState;
  }

  /** Get the current smoothed energy level. */
  getEnergy(): number {
    return this.smoothedEnergy;
  }
}

// =============================================================================
// Audio Format Conversion
// =============================================================================

/**
 * Convert a PCM 16-bit LE buffer to a base64-encoded string.
 * OpenAI Realtime API expects base64-encoded PCM audio.
 */
export function pcmToBase64(pcmBuffer: Buffer): string {
  return pcmBuffer.toString('base64');
}

/**
 * Convert a base64-encoded string back to a PCM buffer.
 */
export function base64ToPcm(base64: string): Buffer {
  return Buffer.from(base64, 'base64');
}

/**
 * Convert Float32 PCM samples to Int16 PCM buffer.
 * Useful when receiving audio from Web Audio API (float) and converting
 * for OpenAI Realtime API (int16).
 */
export function float32ToInt16(float32Array: Float32Array): Buffer {
  const int16Buffer = Buffer.alloc(float32Array.length * 2);
  for (let i = 0; i < float32Array.length; i++) {
    const clamped = Math.max(-1, Math.min(1, float32Array[i]));
    const int16 = clamped < 0 ? clamped * 32768 : clamped * 32767;
    int16Buffer.writeInt16LE(Math.round(int16), i * 2);
  }
  return int16Buffer;
}

/**
 * Convert Int16 PCM buffer to Float32 array.
 */
export function int16ToFloat32(int16Buffer: Buffer): Float32Array {
  const sampleCount = Math.floor(int16Buffer.length / 2);
  const float32 = new Float32Array(sampleCount);
  for (let i = 0; i < sampleCount; i++) {
    float32[i] = int16Buffer.readInt16LE(i * 2) / 32768;
  }
  return float32;
}

/**
 * Downsample audio from one sample rate to another using linear interpolation.
 * @param pcmData - Input PCM 16-bit LE buffer
 * @param fromRate - Source sample rate
 * @param toRate - Target sample rate
 * @returns Resampled PCM 16-bit LE buffer
 */
export function resamplePCM(pcmData: Buffer, fromRate: number, toRate: number): Buffer {
  if (fromRate === toRate) return pcmData;

  const inputSamples = Math.floor(pcmData.length / 2);
  const ratio = fromRate / toRate;
  const outputSamples = Math.floor(inputSamples / ratio);
  const output = Buffer.alloc(outputSamples * 2);

  for (let i = 0; i < outputSamples; i++) {
    const srcIndex = i * ratio;
    const srcFloor = Math.floor(srcIndex);
    const srcCeil = Math.min(srcFloor + 1, inputSamples - 1);
    const fraction = srcIndex - srcFloor;

    const sampleFloor = pcmData.readInt16LE(srcFloor * 2);
    const sampleCeil = pcmData.readInt16LE(srcCeil * 2);
    const interpolated = Math.round(sampleFloor + (sampleCeil - sampleFloor) * fraction);

    output.writeInt16LE(interpolated, i * 2);
  }

  return output;
}

// =============================================================================
// Audio Level Metering
// =============================================================================

export interface AudioLevel {
  /** RMS level (0.0 - 1.0) */
  rms: number;
  /** Peak level (0.0 - 1.0) */
  peak: number;
  /** Level in dBFS (decibels relative to full scale, typically -60 to 0) */
  dbfs: number;
  /** Quality assessment based on level */
  quality: 'silent' | 'low' | 'good' | 'loud' | 'clipping';
}

/**
 * Compute audio level metrics from a PCM 16-bit LE buffer.
 * Used for connection quality feedback and audio monitoring.
 */
export function measureAudioLevel(pcmData: Buffer): AudioLevel {
  const sampleCount = Math.floor(pcmData.length / 2);
  if (sampleCount === 0) {
    return { rms: 0, peak: 0, dbfs: -Infinity, quality: 'silent' };
  }

  let sumSquares = 0;
  let peak = 0;

  for (let i = 0; i < sampleCount; i++) {
    const sample = Math.abs(pcmData.readInt16LE(i * 2)) / 32768;
    sumSquares += sample * sample;
    if (sample > peak) {
      peak = sample;
    }
  }

  const rms = Math.sqrt(sumSquares / sampleCount);
  const dbfs = rms > 0 ? 20 * Math.log10(rms) : -Infinity;

  let quality: AudioLevel['quality'];
  if (rms < 0.001) {
    quality = 'silent';
  } else if (rms < 0.01) {
    quality = 'low';
  } else if (rms < 0.5) {
    quality = 'good';
  } else if (rms < 0.9) {
    quality = 'loud';
  } else {
    quality = 'clipping';
  }

  return { rms, peak, dbfs, quality };
}

/**
 * Audio level smoother for UI metering.
 * Applies attack/release smoothing to produce visually stable level readings.
 */
export class AudioLevelMeter {
  private currentLevel = 0;
  private peakHold = 0;
  private peakHoldTimer = 0;

  /** Attack coefficient (fast rise). Default: 0.8 */
  private readonly attack: number;
  /** Release coefficient (slow fall). Default: 0.95 */
  private readonly release: number;
  /** Peak hold duration in frames. Default: 50 (~1s at 50fps) */
  private readonly peakHoldDuration: number;

  constructor(attack = 0.8, release = 0.95, peakHoldDuration = 50) {
    this.attack = attack;
    this.release = release;
    this.peakHoldDuration = peakHoldDuration;
  }

  /**
   * Update the meter with a new audio level measurement.
   * @returns Smoothed level and held peak
   */
  update(level: AudioLevel): { smoothedLevel: number; peakLevel: number } {
    // Apply attack/release envelope
    if (level.rms > this.currentLevel) {
      this.currentLevel = this.attack * level.rms + (1 - this.attack) * this.currentLevel;
    } else {
      this.currentLevel = this.release * this.currentLevel;
    }

    // Peak hold logic
    if (level.peak >= this.peakHold) {
      this.peakHold = level.peak;
      this.peakHoldTimer = 0;
    } else {
      this.peakHoldTimer++;
      if (this.peakHoldTimer > this.peakHoldDuration) {
        this.peakHold *= 0.95;
      }
    }

    return {
      smoothedLevel: this.currentLevel,
      peakLevel: this.peakHold,
    };
  }

  /** Reset the meter state. */
  reset(): void {
    this.currentLevel = 0;
    this.peakHold = 0;
    this.peakHoldTimer = 0;
  }
}
