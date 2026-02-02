# Code Signing Setup Guide

This document describes the code signing setup required for distributing the HCD Interview Coach macOS application.

## Overview

The application uses Apple's Developer ID code signing to distribute outside the Mac App Store. This requires:
- Developer ID Application certificate
- Hardened Runtime enabled
- Notarization by Apple
- Proper entitlements configuration

## Prerequisites

1. **Apple Developer Account**
   - Individual or Organization account (NOT free account)
   - Enrolled in Apple Developer Program ($99/year)
   - Account must be in good standing

2. **Developer Tools**
   - Xcode 15 or later
   - Xcode Command Line Tools
   - macOS 13.0 or later for development

## Certificate Setup

### 1. Generate Developer ID Certificate

1. Log in to [Apple Developer Portal](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **+** to create a new certificate
4. Select **Developer ID Application** under "Software"
5. Follow the prompts to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** on your Mac
   - Menu: **Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority**
   - Enter your email and common name
   - Select **Saved to disk**
   - Save the CSR file
6. Upload the CSR to the Developer Portal
7. Download the generated certificate
8. Double-click to install in Keychain Access

### 2. Export Certificate for CI/CD

For GitHub Actions, you need to export the certificate:

```bash
# Export certificate with private key
security find-identity -v -p codesigning

# Export as P12 (you'll be prompted for a password)
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities \
  -f pkcs12 \
  -P "YOUR_EXPORT_PASSWORD" \
  -o developer_id.p12

# Encode as base64 for GitHub Secrets
base64 -i developer_id.p12 | pbcopy
```

The base64 output is now in your clipboard. Save this as `APPLE_CERTIFICATE` in GitHub Secrets.

### 3. Team ID

Find your Team ID:
1. Log in to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Membership** in the sidebar
3. Copy your **Team ID** (10 characters, e.g., ABC1234567)

## Entitlements Configuration

The entitlements file is located at: `/config/HCDInterviewCoach.entitlements`

### Required Entitlements

```xml
<!-- Audio recording for interview practice -->
<key>com.apple.security.device.audio-input</key>
<true/>

<!-- Network access for API calls and updates -->
<key>com.apple.security.network.client</key>
<true/>

<!-- File access for user-selected files -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### App Sandbox

The application does NOT use App Sandbox to allow more flexibility:

```xml
<key>com.apple.security.app-sandbox</key>
<false/>
```

This is acceptable for Developer ID distribution (not Mac App Store).

## Hardened Runtime

Hardened Runtime is REQUIRED for notarization. Configure in Xcode:

1. Select your app target
2. Go to **Signing & Capabilities**
3. Enable **Hardened Runtime**
4. Configure exceptions as needed (already set in entitlements)

### Hardened Runtime Flags

Set via build settings or entitlements:
- **Disable Library Validation**: `false` (for production)
- **Allow DYLD Environment Variables**: `false` (for production)
- **Disable Executable Memory Protection**: `false` (unless needed)

## Xcode Project Configuration

### Build Settings

Add to your Xcode project build settings:

```
CODE_SIGN_IDENTITY = "Developer ID Application"
CODE_SIGN_STYLE = Manual
DEVELOPMENT_TEAM = YOUR_TEAM_ID
CODE_SIGN_ENTITLEMENTS = config/HCDInterviewCoach.entitlements
ENABLE_HARDENED_RUNTIME = YES
```

### Info.plist Requirements

Ensure your `Info.plist` includes:

```xml
<!-- Microphone usage description -->
<key>NSMicrophoneUsageDescription</key>
<string>HCD Interview Coach needs microphone access to record your interview practice sessions.</string>

<!-- App category -->
<key>LSApplicationCategoryType</key>
<string>public.app-category.education</string>
```

## Provisioning Profiles

Developer ID distribution does NOT require provisioning profiles (unlike iOS or Mac App Store distribution).

## Notarization

After building and signing, the app must be notarized:

### Prerequisites
- App is signed with Developer ID certificate
- Hardened Runtime is enabled
- Valid entitlements are set
- App-specific password generated

### Generate App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Security > App-Specific Passwords**
4. Click **+** to generate a new password
5. Name it "Notarization" or similar
6. Save the generated password (format: xxxx-xxxx-xxxx-xxxx)

### Notarization Process

The release workflow automatically handles notarization:

```bash
xcrun notarytool submit HCDInterviewCoach.dmg \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Staple the notarization ticket
xcrun stapler staple HCDInterviewCoach.dmg
```

### Verify Notarization

```bash
# Check notarization status
spctl -a -vvv -t install HCDInterviewCoach.app

# Expected output:
# HCDInterviewCoach.app: accepted
# source=Notarized Developer ID
```

## Troubleshooting

### Common Issues

1. **"No signing certificate found"**
   - Ensure certificate is installed in Keychain
   - Check certificate is not expired
   - Verify Team ID matches

2. **"Hardened Runtime validation failed"**
   - Check entitlements file is referenced correctly
   - Verify entitlements syntax is valid XML
   - Ensure all required entitlements are present

3. **"Notarization failed"**
   - Check notarization logs: `xcrun notarytool log SUBMISSION_ID`
   - Common issues:
     - Missing Hardened Runtime
     - Invalid entitlements
     - Unsigned frameworks or libraries
     - Incorrect bundle structure

4. **"Unable to validate app"**
   - Ensure App Sandbox is disabled for Developer ID
   - Check Info.plist has all required keys
   - Verify entitlements match capabilities

### Getting Notarization Logs

```bash
# Submit and get submission ID
xcrun notarytool submit app.dmg --apple-id EMAIL --team-id TEAM --password PASS

# Get logs (replace SUBMISSION_ID)
xcrun notarytool log SUBMISSION_ID --apple-id EMAIL --team-id TEAM --password PASS
```

## Security Best Practices

1. **Never commit certificates or private keys to version control**
2. **Use GitHub Secrets for all sensitive data**
3. **Rotate app-specific passwords periodically**
4. **Use different certificates for development and distribution**
5. **Keep certificates backed up securely**
6. **Monitor certificate expiration dates (1 year for Developer ID)**

## Certificate Renewal

Developer ID certificates expire after 1 year:

1. Create new certificate in Developer Portal
2. Update GitHub Secrets with new certificate
3. Old signatures remain valid even after certificate expires

## References

- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Entitlements Documentation](https://developer.apple.com/documentation/bundleresources/entitlements)
