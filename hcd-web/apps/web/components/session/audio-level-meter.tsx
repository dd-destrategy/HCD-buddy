'use client';

import React, { useEffect, useRef, useState, useCallback } from 'react';
import { cn } from '@hcd/ui';
import { Badge } from '@hcd/ui';
import { Mic, MicOff } from 'lucide-react';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface AudioLevelMeterProps {
  /** The MediaStream to monitor (from getUserMedia) */
  stream: MediaStream | null;
  /** Whether the mic is muted */
  isMuted?: boolean;
  /** Orientation of the meter bar. Default: 'horizontal' */
  orientation?: 'horizontal' | 'vertical';
  /** Show dB label. Default: false */
  showDb?: boolean;
  className?: string;
}

// ---------------------------------------------------------------------------
// Thresholds
// ---------------------------------------------------------------------------

const THRESHOLD_GREEN = 0.4;
const THRESHOLD_YELLOW = 0.75;
// Above THRESHOLD_YELLOW = red zone

// ---------------------------------------------------------------------------
// Component
// ---------------------------------------------------------------------------

export function AudioLevelMeter({
  stream,
  isMuted = false,
  orientation = 'horizontal',
  showDb = false,
  className,
}: AudioLevelMeterProps) {
  const [level, setLevel] = useState(0);
  const [peak, setPeak] = useState(0);
  const [dbfs, setDbfs] = useState(-Infinity);

  const audioContextRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const sourceRef = useRef<MediaStreamAudioSourceNode | null>(null);
  const animFrameRef = useRef<number>(0);
  const peakDecayRef = useRef(0);
  const peakHoldTimerRef = useRef(0);

  const tick = useCallback(() => {
    const analyser = analyserRef.current;
    if (!analyser) return;

    const dataArray = new Float32Array(analyser.fftSize);
    analyser.getFloatTimeDomainData(dataArray);

    // Compute RMS
    let sumSquares = 0;
    let currentPeak = 0;
    for (let i = 0; i < dataArray.length; i++) {
      const sample = Math.abs(dataArray[i]);
      sumSquares += sample * sample;
      if (sample > currentPeak) currentPeak = sample;
    }
    const rms = Math.sqrt(sumSquares / dataArray.length);

    // Smoothed level (fast attack, slow release)
    setLevel((prev) => {
      const attack = 0.8;
      const release = 0.92;
      return rms > prev ? attack * rms + (1 - attack) * prev : release * prev;
    });

    // Peak hold with decay
    if (currentPeak >= peakDecayRef.current) {
      peakDecayRef.current = currentPeak;
      peakHoldTimerRef.current = 0;
    } else {
      peakHoldTimerRef.current++;
      if (peakHoldTimerRef.current > 30) {
        peakDecayRef.current *= 0.95;
      }
    }
    setPeak(peakDecayRef.current);

    // dBFS
    const db = rms > 0 ? 20 * Math.log10(rms) : -Infinity;
    setDbfs(db);

    animFrameRef.current = requestAnimationFrame(tick);
  }, []);

  // Set up Web Audio pipeline when stream changes
  useEffect(() => {
    if (!stream) {
      setLevel(0);
      setPeak(0);
      setDbfs(-Infinity);
      return;
    }

    const audioCtx = new AudioContext();
    const analyser = audioCtx.createAnalyser();
    analyser.fftSize = 2048;
    analyser.smoothingTimeConstant = 0.3;

    const source = audioCtx.createMediaStreamSource(stream);
    source.connect(analyser);
    // Do NOT connect analyser to destination to avoid feedback

    audioContextRef.current = audioCtx;
    analyserRef.current = analyser;
    sourceRef.current = source;

    animFrameRef.current = requestAnimationFrame(tick);

    return () => {
      cancelAnimationFrame(animFrameRef.current);
      source.disconnect();
      analyser.disconnect();
      audioCtx.close();
      audioContextRef.current = null;
      analyserRef.current = null;
      sourceRef.current = null;
    };
  }, [stream, tick]);

  // Clamp level to 0-1 for display
  const displayLevel = Math.min(1, Math.max(0, isMuted ? 0 : level));
  const displayPercent = displayLevel * 100;

  // Determine bar color based on level
  const barColor =
    displayLevel > THRESHOLD_YELLOW
      ? 'bg-red-500'
      : displayLevel > THRESHOLD_GREEN
        ? 'bg-yellow-400'
        : 'bg-green-500';

  const isHorizontal = orientation === 'horizontal';

  return (
    <div
      className={cn(
        'flex items-center gap-2',
        !isHorizontal && 'flex-col-reverse',
        className,
      )}
      role="meter"
      aria-label="Audio level"
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(displayPercent)}
      aria-valuetext={
        isMuted
          ? 'Muted'
          : `${Math.round(displayPercent)}% level${showDb && isFinite(dbfs) ? `, ${dbfs.toFixed(1)} dBFS` : ''}`
      }
    >
      {/* Mic icon */}
      <div className="flex-shrink-0">
        {isMuted ? (
          <MicOff className="h-4 w-4 text-red-500" aria-hidden="true" />
        ) : (
          <Mic
            className={cn(
              'h-4 w-4 transition-colors',
              displayLevel > 0.01 ? 'text-green-500' : 'text-muted-foreground',
            )}
            aria-hidden="true"
          />
        )}
      </div>

      {/* Level bar */}
      <div
        className={cn(
          'relative rounded-full bg-muted overflow-hidden',
          isHorizontal ? 'flex-1 h-3' : 'w-3 flex-1 min-h-[80px]',
        )}
      >
        {/* Active level */}
        <div
          className={cn(
            'absolute rounded-full transition-all duration-75',
            barColor,
            isHorizontal ? 'top-0 left-0 h-full' : 'bottom-0 left-0 w-full',
          )}
          style={
            isHorizontal
              ? { width: `${displayPercent}%` }
              : { height: `${displayPercent}%` }
          }
        />

        {/* Peak indicator */}
        {!isMuted && peak > 0.01 && (
          <div
            className={cn(
              'absolute bg-white/80',
              isHorizontal ? 'top-0 h-full w-0.5' : 'left-0 w-full h-0.5',
            )}
            style={
              isHorizontal
                ? { left: `${Math.min(100, peak * 100)}%` }
                : { bottom: `${Math.min(100, peak * 100)}%` }
            }
          />
        )}
      </div>

      {/* Muted badge */}
      {isMuted && (
        <Badge variant="destructive" className="text-xs">
          Muted
        </Badge>
      )}

      {/* dB display */}
      {showDb && !isMuted && (
        <span className="text-xs text-muted-foreground tabular-nums w-14 text-right">
          {isFinite(dbfs) ? `${dbfs.toFixed(1)} dB` : '-inf dB'}
        </span>
      )}
    </div>
  );
}
