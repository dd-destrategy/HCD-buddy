/**
 * Speaker model - ported from Core/Models/Speaker.swift
 *
 * Represents who is speaking in an utterance.
 */

/** Speaker roles in an interview */
export enum Speaker {
  Interviewer = 'interviewer',
  Participant = 'participant',
  Unknown = 'unknown',
}

/** Human-readable display names for speakers */
export const SpeakerDisplayName: Record<Speaker, string> = {
  [Speaker.Interviewer]: 'Interviewer',
  [Speaker.Participant]: 'Participant',
  [Speaker.Unknown]: 'Unknown',
};

/** Icon identifiers for speakers */
export const SpeakerIcon: Record<Speaker, string> = {
  [Speaker.Interviewer]: 'person.fill',
  [Speaker.Participant]: 'person.circle.fill',
  [Speaker.Unknown]: 'questionmark.circle.fill',
};

/** All possible speaker values */
export const allSpeakers: Speaker[] = [
  Speaker.Interviewer,
  Speaker.Participant,
  Speaker.Unknown,
];

/**
 * Get the display name for a speaker
 * @param speaker - The speaker to get the display name for
 * @returns Human-readable display name
 */
export function getSpeakerDisplayName(speaker: Speaker): string {
  return SpeakerDisplayName[speaker];
}

/**
 * Get the icon identifier for a speaker
 * @param speaker - The speaker to get the icon for
 * @returns Icon identifier string
 */
export function getSpeakerIcon(speaker: Speaker): string {
  return SpeakerIcon[speaker];
}
