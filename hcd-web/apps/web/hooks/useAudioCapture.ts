'use client';

import { useState, useEffect, useRef, useCallback } from 'react';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface AudioCaptureOptions {
  /** Sample rate for AudioContext. Default: 24000 (for OpenAI Realtime API) */
  sampleRate?: number;
  /** Size of each audio chunk in samples. Default: 4800 (200ms at 24kHz) */
  chunkSize?: number;
  /** Whether to start capturing immediately on mount. Default: false */
  autoStart?: boolean;
  /** Callback invoked with base64-encoded PCM chunks */
  onAudioChunk?: (base64Chunk: string) => void;
  /** Callback invoked with RMS audio level (0-1) on each analysis frame */
  onAudioLevel?: (level: number) => void;
}

export interface AudioCaptureState {
  /** Whether mic permission has been granted */
  isPermissionGranted: boolean;
  /** Whether audio is currently being captured */
  isCapturing: boolean;
  /** The MediaStream from getUserMedia (for use with AudioLevelMeter etc.) */
  stream: MediaStream | null;
  /** Current RMS audio level (0-1) */
  audioLevel: number;
  /** Error message if any */
  error: string | null;
}

export interface AudioCaptureActions {
  /** Request mic permission and start capturing */
  start: () => Promise<void>;
  /** Stop capturing and release resources */
  stop: () => void;
  /** Toggle capturing on/off */
  toggle: () => Promise<void>;
}

export type UseAudioCaptureReturn = AudioCaptureState & AudioCaptureActions;

// ---------------------------------------------------------------------------
// Hook implementation
// ---------------------------------------------------------------------------

export function useAudioCapture(options: AudioCaptureOptions = {}): UseAudioCaptureReturn {
  const {
    sampleRate = 24000,
    chunkSize = 4800,
    autoStart = false,
    onAudioChunk,
    onAudioLevel,
  } = options;

  const [isPermissionGranted, setIsPermissionGranted] = useState(false);
  const [isCapturing, setIsCapturing] = useState(false);
  const [stream, setStream] = useState<MediaStream | null>(null);
  const [audioLevel, setAudioLevel] = useState(0);
  const [error, setError] = useState<string | null>(null);

  // Refs to hold audio pipeline objects so we can clean up properly
  const audioContextRef = useRef<AudioContext | null>(null);
  const sourceNodeRef = useRef<MediaStreamAudioSourceNode | null>(null);
  const processorRef = useRef<ScriptProcessorNode | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const animFrameRef = useRef<number>(0);

  // Store callbacks in refs to avoid re-creating the audio pipeline
  const onAudioChunkRef = useRef(onAudioChunk);
  onAudioChunkRef.current = onAudioChunk;
  const onAudioLevelRef = useRef(onAudioLevel);
  onAudioLevelRef.current = onAudioLevel;

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  const cleanup = useCallback(() => {
    cancelAnimationFrame(animFrameRef.current);

    if (processorRef.current) {
      processorRef.current.disconnect();
      processorRef.current.onaudioprocess = null;
      processorRef.current = null;
    }

    if (analyserRef.current) {
      analyserRef.current.disconnect();
      analyserRef.current = null;
    }

    if (sourceNodeRef.current) {
      sourceNodeRef.current.disconnect();
      sourceNodeRef.current = null;
    }

    if (audioContextRef.current) {
      audioContextRef.current.close().catch(() => {});
      audioContextRef.current = null;
    }

    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }

    setStream(null);
    setIsCapturing(false);
    setAudioLevel(0);
  }, []);

  // ---------------------------------------------------------------------------
  // Convert Float32 audio to base64-encoded Int16 PCM
  // ---------------------------------------------------------------------------

  const float32ToBase64PCM = useCallback((float32: Float32Array): string => {
    const int16 = new Int16Array(float32.length);
    for (let i = 0; i < float32.length; i++) {
      const clamped = Math.max(-1, Math.min(1, float32[i]));
      int16[i] = clamped < 0 ? clamped * 32768 : clamped * 32767;
    }

    const bytes = new Uint8Array(int16.buffer);
    let binary = '';
    for (let i = 0; i < bytes.length; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary);
  }, []);

  // ---------------------------------------------------------------------------
  // Audio level polling
  // ---------------------------------------------------------------------------

  const pollAudioLevel = useCallback(() => {
    const analyser = analyserRef.current;
    if (!analyser) return;

    const dataArray = new Float32Array(analyser.fftSize);
    analyser.getFloatTimeDomainData(dataArray);

    let sumSquares = 0;
    for (let i = 0; i < dataArray.length; i++) {
      sumSquares += dataArray[i] * dataArray[i];
    }
    const rms = Math.sqrt(sumSquares / dataArray.length);

    setAudioLevel(rms);
    onAudioLevelRef.current?.(rms);

    animFrameRef.current = requestAnimationFrame(pollAudioLevel);
  }, []);

  // ---------------------------------------------------------------------------
  // Start capturing
  // ---------------------------------------------------------------------------

  const start = useCallback(async () => {
    // Already capturing
    if (isCapturing) return;

    setError(null);

    try {
      // Request microphone access
      const mediaStream = await navigator.mediaDevices.getUserMedia({
        audio: {
          sampleRate: { ideal: sampleRate },
          channelCount: 1,
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        },
      });

      setIsPermissionGranted(true);
      streamRef.current = mediaStream;
      setStream(mediaStream);

      // Create AudioContext
      const audioCtx = new AudioContext({ sampleRate });
      audioContextRef.current = audioCtx;

      // Create source node from mic stream
      const source = audioCtx.createMediaStreamSource(mediaStream);
      sourceNodeRef.current = source;

      // Create analyser for level metering
      const analyser = audioCtx.createAnalyser();
      analyser.fftSize = 2048;
      analyser.smoothingTimeConstant = 0.3;
      analyserRef.current = analyser;
      source.connect(analyser);

      // Create ScriptProcessorNode for PCM extraction
      // Note: ScriptProcessorNode is deprecated but AudioWorklet requires
      // a separate module file. Using ScriptProcessor for simplicity.
      const bufferSize = chunkSize > 4096 ? 8192 : 4096;
      const processor = audioCtx.createScriptProcessor(bufferSize, 1, 1);
      processorRef.current = processor;

      // Accumulate samples to match desired chunk size
      let sampleBuffer = new Float32Array(0);

      processor.onaudioprocess = (event: AudioProcessingEvent) => {
        const inputData = event.inputBuffer.getChannelData(0);

        // Append to accumulation buffer
        const newBuffer = new Float32Array(sampleBuffer.length + inputData.length);
        newBuffer.set(sampleBuffer);
        newBuffer.set(inputData, sampleBuffer.length);
        sampleBuffer = newBuffer;

        // Emit chunks when we have enough samples
        while (sampleBuffer.length >= chunkSize) {
          const chunk = sampleBuffer.slice(0, chunkSize);
          sampleBuffer = sampleBuffer.slice(chunkSize);

          const base64 = float32ToBase64PCM(chunk);
          onAudioChunkRef.current?.(base64);
        }
      };

      source.connect(processor);
      // Connect processor to destination (required for it to process)
      processor.connect(audioCtx.destination);

      // Start audio level polling
      animFrameRef.current = requestAnimationFrame(pollAudioLevel);

      setIsCapturing(true);
    } catch (err) {
      cleanup();

      if (err instanceof DOMException) {
        switch (err.name) {
          case 'NotAllowedError':
            setError(
              'Microphone permission was denied. Please allow microphone access and try again.',
            );
            break;
          case 'NotFoundError':
            setError('No microphone found. Please connect a microphone and try again.');
            break;
          case 'NotReadableError':
            setError(
              'Microphone is in use by another application. Please close other apps and try again.',
            );
            break;
          default:
            setError(`Microphone error: ${err.message}`);
        }
      } else {
        setError(`Failed to start audio capture: ${err instanceof Error ? err.message : String(err)}`);
      }
    }
  }, [isCapturing, sampleRate, chunkSize, float32ToBase64PCM, pollAudioLevel, cleanup]);

  // ---------------------------------------------------------------------------
  // Stop capturing
  // ---------------------------------------------------------------------------

  const stop = useCallback(() => {
    cleanup();
  }, [cleanup]);

  // ---------------------------------------------------------------------------
  // Toggle
  // ---------------------------------------------------------------------------

  const toggle = useCallback(async () => {
    if (isCapturing) {
      stop();
    } else {
      await start();
    }
  }, [isCapturing, start, stop]);

  // ---------------------------------------------------------------------------
  // Auto-start
  // ---------------------------------------------------------------------------

  useEffect(() => {
    if (autoStart) {
      start();
    }
    // Cleanup on unmount
    return () => {
      cleanup();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return {
    isPermissionGranted,
    isCapturing,
    stream,
    audioLevel,
    error,
    start,
    stop,
    toggle,
  };
}
