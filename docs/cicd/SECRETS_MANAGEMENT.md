# GitHub Secrets Management Guide

This document describes all required secrets for the CI/CD pipeline and how to configure them.

## Overview

GitHub Actions workflows require several secrets for code signing, notarization, and distribution. These secrets must be configured in your repository settings before running the release workflow.

**CRITICAL**: Never commit secrets to version control. Always use GitHub Secrets.

## Required Secrets

### Code Signing Secrets

#### 1. APPLE_CERTIFICATE

**Purpose**: Developer ID Application certificate with private key for code signing.

**Format**: Base64-encoded P12 file

**How to Generate**:

```bash
# Export certificate from Keychain
security find-identity -v -p codesigning

# Export certificate with private key (you'll be prompted for a password)
security export -k ~/Library/Keychains/login.keychain-db \
  -t identities \
  -f pkcs12 \
  -P "YOUR_EXPORT_PASSWORD" \
  -o developer_id.p12

# Encode as base64
base64 -i developer_id.p12 | pbcopy
```

The base64 string is now in your clipboard.

**How to Add**:
1. Go to GitHub repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `APPLE_CERTIFICATE`
4. Value: Paste the base64 string
5. Click **Add secret**

---

#### 2. APPLE_CERTIFICATE_PASSWORD

**Purpose**: Password used when exporting the P12 certificate.

**Format**: Plain text password

**How to Generate**:
This is the password you used in the `security export` command above.

**How to Add**:
1. Go to GitHub repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `APPLE_CERTIFICATE_PASSWORD`
4. Value: Your P12 export password
5. Click **Add secret**

**Best Practice**: Use a strong, randomly generated password:
```bash
openssl rand -base64 32
```

---

#### 3. APPLE_TEAM_ID

**Purpose**: Your Apple Developer Team ID for code signing.

**Format**: 10-character alphanumeric string (e.g., `ABC1234567`)

**How to Find**:
1. Log in to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Membership** in the sidebar
3. Copy your **Team ID**

**How to Add**:
1. Go to GitHub repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `APPLE_TEAM_ID`
4. Value: Your Team ID (e.g., `ABC1234567`)
5. Click **Add secret**

---

### Notarization Secrets

#### 4. APPLE_ID

**Purpose**: Apple ID email for notarization submission.

**Format**: Email address

**How to Find**:
This is your Apple Developer account email address.

**How to Add**:
1. Go to GitHub repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `APPLE_ID`
4. Value: Your Apple ID email (e.g., `developer@example.com`)
5. Click **Add secret**

---

#### 5. NOTARIZATION_PASSWORD

**Purpose**: App-specific password for notarization (NOT your Apple ID password).

**Format**: 16-character password with hyphens (format: `xxxx-xxxx-xxxx-xxxx`)

**How to Generate**:
1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Security > App-Specific Passwords**
4. Click **+** to generate a new password
5. Name it "GitHub Actions Notarization"
6. Copy the generated password (format: `abcd-efgh-ijkl-mnop`)

**How to Add**:
1. Go to GitHub repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `NOTARIZATION_PASSWORD`
4. Value: The app-specific password
5. Click **Add secret**

**Important**: Save this password immediately. You cannot view it again.

---

### Update Distribution Secrets

#### 6. SPARKLE_PRIVATE_KEY

**Purpose**: EdDSA private key for signing Sparkle updates.

**Format**: Base64-encoded private key

**How to Generate**:

```bash
# Install Sparkle tools
brew install sparkle

# Generate EdDSA key pair
generate_keys

# This creates:
# - sparkle_eddsa_private.key (keep secret)
# - sparkle_eddsa_public.key (embed in app)

# Encode private key as base64
base64 -i sparkle_eddsa_private.key | pbcopy
```

**How to Add**:
1. Go to GitHub repository **Settings > Secrets and variables > Actions**
2. Click **New repository secret**
3. Name: `SPARKLE_PRIVATE_KEY`
4. Value: Paste the base64-encoded private key
5. Click **Add secret**

**Important**:
- Keep the public key to add to your app's Info.plist
- NEVER commit the private key to version control
- Back up the private key securely offline

---

### Optional Secrets

#### 7. GITHUB_TOKEN

**Purpose**: Automatically provided by GitHub Actions for creating releases.

**Format**: Automatically generated token

**How to Configure**:
No action needed. This is automatically available in all workflows as `${{ secrets.GITHUB_TOKEN }}`.

**Permissions Required**:
Ensure your repository has the following permissions:
1. Go to **Settings > Actions > General**
2. Under **Workflow permissions**, select:
   - "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"

---

## Secrets Summary Table

| Secret Name | Purpose | Format | Required For |
|------------|---------|--------|--------------|
| `APPLE_CERTIFICATE` | Code signing certificate | Base64 P12 | Release workflow |
| `APPLE_CERTIFICATE_PASSWORD` | Certificate password | Plain text | Release workflow |
| `APPLE_TEAM_ID` | Developer team ID | 10 chars | Release workflow |
| `APPLE_ID` | Apple Developer email | Email | Notarization |
| `NOTARIZATION_PASSWORD` | App-specific password | xxxx-xxxx-xxxx-xxxx | Notarization |
| `SPARKLE_PRIVATE_KEY` | Update signing key | Base64 key | Release workflow |
| `GITHUB_TOKEN` | Release creation | Auto-generated | Release workflow |

---

## Verifying Secrets

After adding all secrets, verify they are configured:

1. Go to **Settings > Secrets and variables > Actions**
2. You should see all 6 secrets listed:
   - APPLE_CERTIFICATE
   - APPLE_CERTIFICATE_PASSWORD
   - APPLE_TEAM_ID
   - APPLE_ID
   - NOTARIZATION_PASSWORD
   - SPARKLE_PRIVATE_KEY

**Note**: You cannot view secret values after creation. You can only update or delete them.

---

## Testing Secrets

Test your secrets with a workflow run:

1. Create a test tag:
   ```bash
   git tag v0.0.1-test
   git push origin v0.0.1-test
   ```

2. Monitor the workflow:
   - Go to **Actions** tab
   - Watch the release workflow execute
   - Check for any authentication or signing errors

3. Common issues:
   - **Certificate import fails**: Check APPLE_CERTIFICATE and APPLE_CERTIFICATE_PASSWORD
   - **Code signing fails**: Verify APPLE_TEAM_ID
   - **Notarization fails**: Check APPLE_ID and NOTARIZATION_PASSWORD
   - **Missing signature**: Verify SPARKLE_PRIVATE_KEY

---

## Updating Secrets

### When to Update

Update secrets when:
- Certificate expires (annually for Developer ID)
- App-specific password is revoked
- Security breach or suspected compromise
- Team ID changes (rare)
- New Sparkle key pair generated

### How to Update

1. Go to **Settings > Secrets and variables > Actions**
2. Find the secret to update
3. Click on the secret name
4. Click **Update secret**
5. Enter the new value
6. Click **Update secret**

---

## Security Best Practices

### 1. Principle of Least Privilege

Only add secrets that are absolutely necessary for the workflow.

### 2. Regular Rotation

Rotate secrets periodically:
- App-specific passwords: Every 6 months
- Certificates: Before expiration (annually)
- Sparkle keys: Only if compromised

### 3. Access Control

**Repository Settings**:
- Limit who can manage secrets
- Use branch protection rules
- Require pull request reviews

**Organization Settings** (if applicable):
- Use organization-level secrets for shared values
- Restrict secret access to specific repositories

### 4. Audit Trail

Monitor secret usage:
- Review workflow runs regularly
- Check for failed authentication attempts
- Monitor notarization submissions

### 5. Backup Strategy

**What to back up**:
- Developer ID certificate (.p12 file)
- Sparkle private key
- App-specific password (in password manager)

**Where to back up**:
- Encrypted password manager (1Password, Bitwarden, etc.)
- Encrypted external drive (offline)
- Secure cloud storage (encrypted)

**Never back up to**:
- Version control (Git)
- Unencrypted cloud storage
- Email or messaging apps

---

## Environment Variables vs Secrets

### Use Secrets for:
- Passwords and API keys
- Certificates and private keys
- Any sensitive authentication data

### Use Environment Variables for:
- Public configuration values
- Non-sensitive build settings
- Feature flags

Example in workflow:

```yaml
env:
  APP_NAME: HCDInterviewCoach  # Public - can be env var
  MIN_MACOS_VERSION: "13.0"     # Public - can be env var

steps:
  - name: Code Sign
    env:
      CERTIFICATE: ${{ secrets.APPLE_CERTIFICATE }}  # Sensitive - must be secret
```

---

## Troubleshooting

### Secret Not Found

**Error**: `Secret APPLE_CERTIFICATE not found`

**Solution**:
1. Verify secret exists in repository settings
2. Check spelling (case-sensitive)
3. Ensure workflow has permission to access secrets

### Invalid Certificate

**Error**: `Unable to import certificate`

**Solution**:
1. Verify base64 encoding is correct
2. Check password matches the one used during export
3. Re-export and re-encode the certificate

### Notarization Authentication Failed

**Error**: `Error: HTTP status code: 401`

**Solution**:
1. Verify Apple ID is correct
2. Generate new app-specific password
3. Check Team ID matches your account

### Signature Verification Failed

**Error**: `EdDSA signature verification failed`

**Solution**:
1. Verify Sparkle private key is correct
2. Check public key in Info.plist matches private key
3. Re-generate key pair if necessary

---

## References

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Apple Certificates](https://developer.apple.com/support/certificates/)
- [App-Specific Passwords](https://support.apple.com/en-us/HT204397)
- [Notarization Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Sparkle Security](https://sparkle-project.org/documentation/security/)
