/**
 * Consent Template model - ported from Core/Models/ConsentTemplate.swift
 *
 * Multi-language consent templates with permissions.
 * Defines consent templates with multi-language support, versioning,
 * and individual permission items at a 5th-grade reading level.
 */

// ---------------------------------------------------------------------------
// Consent Language
// ---------------------------------------------------------------------------

/** Supported languages for consent templates */
export enum ConsentLanguage {
  English = 'en',
  Spanish = 'es',
  French = 'fr',
  German = 'de',
  Japanese = 'ja',
  Chinese = 'zh',
}

/** English display names for consent languages */
export const ConsentLanguageDisplayName: Record<ConsentLanguage, string> = {
  [ConsentLanguage.English]: 'English',
  [ConsentLanguage.Spanish]: 'Spanish',
  [ConsentLanguage.French]: 'French',
  [ConsentLanguage.German]: 'German',
  [ConsentLanguage.Japanese]: 'Japanese',
  [ConsentLanguage.Chinese]: 'Chinese',
};

/** Native-script names for consent languages */
export const ConsentLanguageNativeName: Record<ConsentLanguage, string> = {
  [ConsentLanguage.English]: 'English',
  [ConsentLanguage.Spanish]: 'Espa\u00F1ol',
  [ConsentLanguage.French]: 'Fran\u00E7ais',
  [ConsentLanguage.German]: 'Deutsch',
  [ConsentLanguage.Japanese]: '\u65E5\u672C\u8A9E',
  [ConsentLanguage.Chinese]: '\u4E2D\u6587',
};

/** All supported consent languages */
export const allConsentLanguages: ConsentLanguage[] = [
  ConsentLanguage.English,
  ConsentLanguage.Spanish,
  ConsentLanguage.French,
  ConsentLanguage.German,
  ConsentLanguage.Japanese,
  ConsentLanguage.Chinese,
];

// ---------------------------------------------------------------------------
// Consent Permission
// ---------------------------------------------------------------------------

/**
 * A single permission item in the consent flow.
 * Each permission has a plain-language title and description written
 * at a 5th-grade reading level.
 */
export interface ConsentPermission {
  id: string;
  title: string;
  description: string;
  icon: string;
  isRequired: boolean;
  isAccepted: boolean;
}

/**
 * Create a new ConsentPermission with default values
 */
export function createConsentPermission(
  params: Omit<ConsentPermission, 'id' | 'isAccepted'> & {
    id?: string;
    isAccepted?: boolean;
  },
): ConsentPermission {
  return {
    id: params.id ?? crypto.randomUUID(),
    title: params.title,
    description: params.description,
    icon: params.icon,
    isRequired: params.isRequired,
    isAccepted: params.isAccepted ?? false,
  };
}

// ---------------------------------------------------------------------------
// Consent Template
// ---------------------------------------------------------------------------

/**
 * A versioned consent template containing an introduction, a set of permissions,
 * and closing text. Templates support multiple languages and can be customized.
 */
export interface ConsentTemplate {
  id: string;
  name: string;
  version: string;
  language: ConsentLanguage;
  introductionText: string;
  permissions: ConsentPermission[];
  closingText: string;
  isDefault: boolean;
  createdAt: string; // ISO 8601 date string
  updatedAt: string; // ISO 8601 date string
}

/** Whether all required permissions have been accepted */
export function allRequiredAccepted(template: ConsentTemplate): boolean {
  return template.permissions
    .filter((p) => p.isRequired)
    .every((p) => p.isAccepted);
}

/** Total number of permissions in this template */
export function permissionCount(template: ConsentTemplate): number {
  return template.permissions.length;
}

/** Number of permissions that have been accepted */
export function acceptedCount(template: ConsentTemplate): number {
  return template.permissions.filter((p) => p.isAccepted).length;
}

// ---------------------------------------------------------------------------
// Default Templates
// ---------------------------------------------------------------------------

/** Pre-built default English consent template at 5th-grade reading level */
export function defaultEnglishTemplate(): ConsentTemplate {
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    name: 'Standard Consent',
    version: '1.0.0',
    language: ConsentLanguage.English,
    introductionText:
      'Thank you for talking with us today. Before we start, we want to make sure you know what will happen. Please read each item below. You can say yes or no to each one. If you have questions, just ask.',
    permissions: [
      createConsentPermission({
        title: 'Record Our Talk',
        description: 'We will record what we say during this interview.',
        icon: 'mic.fill',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Use Your Words',
        description:
          'We may use quotes from you in our research. We won\'t use your name.',
        icon: 'text.quote',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Take Notes',
        description:
          'The computer will write down what we say as we talk.',
        icon: 'note.text',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Share Findings',
        description:
          'We may share what we learn with our team. Your name stays private.',
        icon: 'person.2.fill',
        isRequired: false,
      }),
      createConsentPermission({
        title: 'Save for Later',
        description: 'We may keep this recording to listen to again.',
        icon: 'archivebox.fill',
        isRequired: false,
      }),
    ],
    closingText:
      'You can change your mind at any time. Just let us know and we will stop. Your comfort matters most to us.',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  };
}

/** Pre-built default Spanish consent template at 5th-grade reading level */
export function defaultSpanishTemplate(): ConsentTemplate {
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    name: 'Consentimiento Est\u00E1ndar',
    version: '1.0.0',
    language: ConsentLanguage.Spanish,
    introductionText:
      'Gracias por hablar con nosotros hoy. Antes de empezar, queremos que sepas lo que va a pasar. Por favor lee cada punto. Puedes decir s\u00ED o no a cada uno. Si tienes preguntas, solo preg\u00FAntanos.',
    permissions: [
      createConsentPermission({
        title: 'Grabar Nuestra Charla',
        description:
          'Vamos a grabar lo que digamos durante esta entrevista.',
        icon: 'mic.fill',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Usar Tus Palabras',
        description:
          'Podemos usar citas tuyas en nuestra investigaci\u00F3n. No usaremos tu nombre.',
        icon: 'text.quote',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Tomar Notas',
        description:
          'La computadora escribir\u00E1 lo que digamos mientras hablamos.',
        icon: 'note.text',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Compartir Hallazgos',
        description:
          'Podemos compartir lo que aprendamos con nuestro equipo. Tu nombre se mantiene privado.',
        icon: 'person.2.fill',
        isRequired: false,
      }),
      createConsentPermission({
        title: 'Guardar para Despu\u00E9s',
        description:
          'Podemos guardar esta grabaci\u00F3n para escucharla de nuevo.',
        icon: 'archivebox.fill',
        isRequired: false,
      }),
    ],
    closingText:
      'Puedes cambiar de opini\u00F3n en cualquier momento. Solo d\u00EDnos y pararemos. Tu comodidad es lo m\u00E1s importante para nosotros.',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  };
}

/** Pre-built default French consent template at 5th-grade reading level */
export function defaultFrenchTemplate(): ConsentTemplate {
  const now = new Date().toISOString();
  return {
    id: crypto.randomUUID(),
    name: 'Consentement Standard',
    version: '1.0.0',
    language: ConsentLanguage.French,
    introductionText:
      'Merci de parler avec nous aujourd\u2019hui. Avant de commencer, nous voulons que vous sachiez ce qui va se passer. Veuillez lire chaque point. Vous pouvez dire oui ou non \u00E0 chacun. Si vous avez des questions, demandez-nous.',
    permissions: [
      createConsentPermission({
        title: 'Enregistrer Notre Discussion',
        description:
          'Nous allons enregistrer ce que nous disons pendant cet entretien.',
        icon: 'mic.fill',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Utiliser Vos Mots',
        description:
          'Nous pouvons utiliser vos citations dans notre recherche. Nous n\u2019utiliserons pas votre nom.',
        icon: 'text.quote',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Prendre des Notes',
        description:
          'L\u2019ordinateur \u00E9crira ce que nous disons pendant que nous parlons.',
        icon: 'note.text',
        isRequired: true,
      }),
      createConsentPermission({
        title: 'Partager les R\u00E9sultats',
        description:
          'Nous pouvons partager ce que nous apprenons avec notre \u00E9quipe. Votre nom reste priv\u00E9.',
        icon: 'person.2.fill',
        isRequired: false,
      }),
      createConsentPermission({
        title: 'Garder pour Plus Tard',
        description:
          'Nous pouvons garder cet enregistrement pour l\u2019\u00E9couter \u00E0 nouveau.',
        icon: 'archivebox.fill',
        isRequired: false,
      }),
    ],
    closingText:
      'Vous pouvez changer d\u2019avis \u00E0 tout moment. Dites-le nous et nous arr\u00EAterons. Votre confort est le plus important pour nous.',
    isDefault: true,
    createdAt: now,
    updatedAt: now,
  };
}
