# Sparkle Auto-Update Integration Guide

This document describes how to integrate Sparkle framework for automatic updates in the HCD Interview Coach macOS application.

## Overview

Sparkle is the industry-standard auto-update framework for macOS applications distributed outside the Mac App Store. It provides:
- Automatic update checks
- Secure update downloads
- Delta updates support
- User-friendly update UI
- EdDSA signature verification

## Installation

### Add Sparkle via Swift Package Manager

1. Open your Xcode project
2. Go to **File > Add Package Dependencies**
3. Enter the Sparkle repository URL:
   ```
   https://github.com/sparkle-project/Sparkle
   ```
4. Select version: **2.6.0** or later
5. Add to your app target

### Manual Integration (Alternative)

If not using SPM, download from [Sparkle Releases](https://github.com/sparkle-project/Sparkle/releases):

1. Download `Sparkle-2.6.0.tar.xz`
2. Extract and add `Sparkle.framework` to your project
3. Embed the framework in your app bundle

## Configuration

### 1. Info.plist Setup

Add the following keys to your `Info.plist`:

```xml
<!-- Sparkle Feed URL - where to check for updates -->
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>

<!-- Public EdDSA key for signature verification -->
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>

<!-- Enable automatic update checks -->
<key>SUEnableAutomaticChecks</key>
<true/>

<!-- Check for updates every 24 hours (86400 seconds) -->
<key>SUScheduledCheckInterval</key>
<integer>86400</integer>

<!-- Show release notes in update dialog -->
<key>SUShowReleaseNotes</key>
<true/>

<!-- Allow automatic installation after download -->
<key>SUAutomaticallyUpdate</key>
<false/>

<!-- Send system profile (anonymous analytics) -->
<key>SUEnableSystemProfiling</key>
<false/>
```

### 2. AppDelegate Integration

Add Sparkle to your `AppDelegate.swift`:

```swift
import Cocoa
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    private var updaterController: SPUStandardUpdaterController!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    // Optional: Add menu item to check for updates
    @IBAction func checkForUpdates(_ sender: Any?) {
        updaterController.checkForUpdates(sender)
    }
}
```

### 3. Menu Integration

Add "Check for Updates" to your app menu:

In `MainMenu.xib` or programmatically:

```swift
let appMenu = NSMenu(title: "HCD Interview Coach")

let checkForUpdatesItem = NSMenuItem(
    title: "Check for Updates…",
    action: #selector(AppDelegate.checkForUpdates(_:)),
    keyEquivalent: ""
)
appMenu.addItem(checkForUpdatesItem)
```

## EdDSA Key Generation

Sparkle 2.x uses EdDSA signatures for security.

### Generate Key Pair

```bash
# Install Sparkle tools (if not already installed)
brew install sparkle

# Generate EdDSA key pair
# This will create two files: private_key and public_key
generate_keys

# Or if using Sparkle from source:
./bin/generate_keys
```

This generates:
- **Private key** (sparkle_eddsa_private.key): Keep this SECRET, use in CI/CD
- **Public key** (sparkle_eddsa_public.key): Embed in your app's Info.plist

### Save Keys Securely

```bash
# Copy public key to Info.plist
cat sparkle_eddsa_public.key
# Add to Info.plist as SUPublicEDKey value

# Save private key as GitHub Secret
cat sparkle_eddsa_private.key | base64
# Add to GitHub Secrets as SPARKLE_PRIVATE_KEY
```

**IMPORTANT**: Never commit the private key to version control!

## Appcast Configuration

The appcast.xml file contains information about available updates.

### Appcast Structure

Create `appcast.xml` on your web server:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>HCD Interview Coach Updates</title>
        <link>https://yourdomain.com/appcast.xml</link>
        <description>Most recent updates to HCD Interview Coach</description>
        <language>en</language>

        <!-- Latest version -->
        <item>
            <title>Version 1.0.0</title>
            <link>https://yourdomain.com/downloads/HCDInterviewCoach-1.0.0.dmg</link>
            <sparkle:version>1.0.0</sparkle:version>
            <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
            <description><![CDATA[
                <h2>What's New in Version 1.0.0</h2>
                <ul>
                    <li>Initial release</li>
                    <li>Interview practice with AI feedback</li>
                    <li>Audio recording and playback</li>
                </ul>
            ]]></description>
            <pubDate>Sat, 01 Feb 2026 12:00:00 +0000</pubDate>
            <enclosure
                url="https://yourdomain.com/downloads/HCDInterviewCoach-1.0.0.dmg"
                length="15728640"
                type="application/octet-stream"
                sparkle:edSignature="SIGNATURE_GOES_HERE" />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>

        <!-- Previous versions... -->
    </channel>
</rss>
```

### Appcast Fields

- **title**: Version display name
- **sparkle:version**: Build number (CFBundleVersion)
- **sparkle:shortVersionString**: Version string (CFBundleShortVersionString)
- **description**: Release notes (supports HTML)
- **pubDate**: Release date in RFC 822 format
- **enclosure url**: Direct download URL for the DMG
- **enclosure length**: File size in bytes
- **sparkle:edSignature**: EdDSA signature of the DMG
- **sparkle:minimumSystemVersion**: Minimum macOS version required

### Generate Signature

```bash
# Sign the DMG file
sign_update HCDInterviewCoach-1.0.0.dmg -f sparkle_eddsa_private.key

# Output format:
# sparkle:edSignature="SIGNATURE_HERE" length="FILE_SIZE"
```

Copy the signature to your appcast.xml.

## Hosting Appcast

### Option 1: GitHub Pages

1. Create a `gh-pages` branch
2. Add `appcast.xml` to the root
3. Update SUFeedURL to: `https://yourusername.github.io/hcd-buddy/appcast.xml`

### Option 2: Custom Server

1. Upload `appcast.xml` to your web server
2. Ensure it's accessible via HTTPS
3. Set proper CORS headers if needed:
   ```
   Access-Control-Allow-Origin: *
   ```

### Option 3: GitHub Releases (Alternative)

Point to latest release:
```
https://api.github.com/repos/yourusername/hcd-buddy/releases/latest
```

Requires custom Sparkle delegate to parse GitHub API response.

## Automated Appcast Generation

The release workflow includes appcast update logic:

```bash
# Install Sparkle tools
brew install sparkle

# Generate appcast from releases directory
generate_appcast /path/to/releases

# This creates/updates appcast.xml automatically
```

### Integrate in Release Workflow

Add to `.github/workflows/release.yml`:

```yaml
- name: Generate Appcast
  env:
    SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
  run: |
    # Save private key
    echo "$SPARKLE_PRIVATE_KEY" > sparkle_key

    # Download existing appcast
    curl -o appcast.xml https://yourdomain.com/appcast.xml || true

    # Add new release
    generate_appcast \
      --ed-key-file sparkle_key \
      --download-url-prefix https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/ \
      --output appcast.xml \
      ${{ runner.temp }}/

    # Upload updated appcast to server
    # (implementation depends on your hosting)
```

## Version Numbering

Sparkle compares versions to determine if an update is available.

### Semantic Versioning

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **MAJOR**: Incompatible API changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Xcode Configuration

In your project settings:

- **Version** (CFBundleShortVersionString): `1.0.0`
- **Build** (CFBundleVersion): `1` or `100` (incremental)

Sparkle uses `CFBundleVersion` for comparison if available, otherwise falls back to `CFBundleShortVersionString`.

### Git Tags

Tag releases in git:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This triggers the release workflow.

## Testing Updates

### Local Testing

1. Build and run your app
2. Change the version number to a lower value
3. Host a test appcast with a higher version
4. Check for updates manually

### Test Appcast

Create a test appcast for development:

```xml
<item>
    <title>Test Version 999.0.0</title>
    <sparkle:version>999</sparkle:version>
    <sparkle:shortVersionString>999.0.0</sparkle:shortVersionString>
    ...
</item>
```

Point `SUFeedURL` to your test appcast during development.

### Debugging

Enable Sparkle logging:

```swift
updaterController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: self,
    userDriverDelegate: nil
)

// Implement delegate for debugging
extension AppDelegate: SPUUpdaterDelegate {
    func feedURLString(for updater: SPUUpdater) -> String? {
        return "https://test.yourdomain.com/appcast.xml"
    }
}
```

## Delta Updates (Optional)

Sparkle supports delta updates for faster downloads.

### Generate Delta

```bash
# Create delta patch between versions
BinaryDelta create \
  HCDInterviewCoach-1.0.0.app \
  HCDInterviewCoach-1.1.0.app \
  HCDInterviewCoach-1.0.0-to-1.1.0.delta
```

### Add to Appcast

```xml
<item>
    <title>Version 1.1.0</title>
    ...
    <!-- Full update -->
    <enclosure
        url="https://yourdomain.com/downloads/HCDInterviewCoach-1.1.0.dmg"
        sparkle:edSignature="FULL_SIGNATURE"
        length="15728640"
        type="application/octet-stream" />

    <!-- Delta update from 1.0.0 -->
    <sparkle:deltas>
        <enclosure
            url="https://yourdomain.com/downloads/HCDInterviewCoach-1.0.0-to-1.1.0.delta"
            sparkle:edSignature="DELTA_SIGNATURE"
            sparkle:deltaFrom="1.0.0"
            length="2097152"
            type="application/octet-stream" />
    </sparkle:deltas>
</item>
```

## Security Best Practices

1. **Always use EdDSA signatures** - Required for Sparkle 2.x
2. **Keep private key secure** - Never commit to repository
3. **Use HTTPS for appcast and downloads** - Prevent man-in-the-middle attacks
4. **Verify signatures** - Public key in Info.plist
5. **Code sign all updates** - Required for notarization
6. **Test updates thoroughly** - Automated and manual testing

## Troubleshooting

### Updates Not Detected

- Verify SUFeedURL is correct and accessible
- Check appcast.xml is valid XML
- Ensure version numbers are incremented
- Confirm EdDSA signature is correct

### Signature Verification Failed

- Verify public key in Info.plist matches private key
- Ensure signature was generated with correct private key
- Check file wasn't modified after signing

### Update Download Fails

- Verify download URL is accessible
- Check file size matches enclosure length
- Ensure DMG is properly notarized
- Confirm HTTPS certificate is valid

## References

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [EdDSA Signatures](https://sparkle-project.org/documentation/api-reference/Classes/SUUpdater.html#/c:objc(cs)SUUpdater(py)publicEDKey)
- [Appcast Format](https://sparkle-project.org/documentation/publishing/)
- [Version Comparison](https://sparkle-project.org/documentation/publishing/#version-strings)
