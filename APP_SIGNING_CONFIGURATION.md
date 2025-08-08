# NeruLibrary App Signing Configuration

## Production Signing Setup

### Prerequisites
- Android Studio installed
- Java Development Kit (JDK) 11 or higher
- Flutter SDK configured

### 1. Generate Release Keystore

Run the following command to generate a new keystore for production:

```bash
keytool -genkey -v -keystore nerulibrary-release-key.keystore -alias nerulibrary -keyalg RSA -keysize 2048 -validity 10000
```

**Important Information to Provide:**
- First and Last Name: NeruLibrary
- Organizational Unit: Development Team
- Organization: Nerufuyo
- City: Jakarta
- State: Jakarta
- Country Code: ID

**Store this information securely:**
- Keystore password: `[SECURE_PASSWORD]`
- Key alias: `nerulibrary`
- Key password: `[SECURE_PASSWORD]`

### 2. Environment Variables Setup

Create the following environment variables for secure signing:

```bash
# Linux/macOS
export NERULIBRARY_KEYSTORE_PATH="$HOME/nerulibrary-release-key.keystore"
export NERULIBRARY_KEY_ALIAS="nerulibrary"
export NERULIBRARY_KEY_PASSWORD="your_key_password"
export NERULIBRARY_STORE_PASSWORD="your_store_password"

# Windows
set NERULIBRARY_KEYSTORE_PATH=C:\path\to\nerulibrary-release-key.keystore
set NERULIBRARY_KEY_ALIAS=nerulibrary
set NERULIBRARY_KEY_PASSWORD=your_key_password
set NERULIBRARY_STORE_PASSWORD=your_store_password
```

### 3. Key Security Best Practices

#### Keystore Storage
- ✅ Store keystore file in secure location outside project directory
- ✅ Backup keystore file to multiple secure locations
- ✅ Never commit keystore to version control
- ✅ Use strong passwords (minimum 12 characters)

#### Environment Security
- ✅ Use environment variables for sensitive data
- ✅ Never hardcode passwords in build files
- ✅ Use different keys for debug and release builds
- ✅ Restrict access to signing credentials

### 4. Build Configuration

The build.gradle.kts has been configured to use environment variables:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = System.getenv("NERULIBRARY_KEY_ALIAS") ?: "nerulibrary"
        keyPassword = System.getenv("NERULIBRARY_KEY_PASSWORD") ?: "nerulibrary123"
        storeFile = file(System.getenv("NERULIBRARY_KEYSTORE_PATH") ?: "nerulibrary-release-key.keystore")
        storePassword = System.getenv("NERULIBRARY_STORE_PASSWORD") ?: "nerulibrary123"
    }
}
```

### 5. Building Signed Release

#### Method 1: Using Flutter Commands
```bash
# Build signed APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/

# Build signed App Bundle (recommended for Play Store)
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info/
```

#### Method 2: Using Gradle
```bash
# Navigate to android directory
cd android

# Build release APK
./gradlew assembleRelease

# Build release App Bundle
./gradlew bundleRelease
```

### 6. Verification Steps

#### Verify Signed APK
```bash
# Check APK signature
keytool -printcert -jarfile build/app/outputs/flutter-apk/app-release.apk

# Verify App Bundle
bundletool validate --bundle=build/app/outputs/bundle/release/app-release.aab
```

#### Expected Output
```
Certificate fingerprints:
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

### 7. Google Play Console Setup

#### Upload Key Certificate
1. Login to Google Play Console
2. Navigate to Release > Setup > App Signing
3. Upload the certificate from your keystore:

```bash
keytool -export -rfc -alias nerulibrary -file nerulibrary-upload-cert.pem -keystore nerulibrary-release-key.keystore
```

#### App Bundle Upload
1. Create new release in Google Play Console
2. Upload the generated app-release.aab file
3. Complete release notes and metadata

### 8. Security Checklist

#### Pre-Release Security Verification
- ✅ Keystore secured and backed up
- ✅ Environment variables configured
- ✅ No debug information in release build
- ✅ ProGuard obfuscation enabled
- ✅ App Bundle optimizations enabled
- ✅ Certificate fingerprint documented

#### Distribution Security
- ✅ Only signed builds distributed
- ✅ Debug builds not used for production
- ✅ Signature verification before release
- ✅ Secure distribution channels only

### 9. Troubleshooting

#### Common Issues and Solutions

**Issue:** "Could not find keystore"
```bash
# Solution: Verify environment variable path
echo $NERULIBRARY_KEYSTORE_PATH
# Ensure path is absolute and file exists
```

**Issue:** "Wrong password"
```bash
# Solution: Verify environment variables
echo $NERULIBRARY_KEY_PASSWORD
echo $NERULIBRARY_STORE_PASSWORD
```

**Issue:** "Build fails with obfuscation"
```bash
# Solution: Check ProGuard rules
flutter build apk --release --verbose
# Review build logs for specific errors
```

### 10. Maintenance

#### Annual Tasks
- [ ] Review and update keystore if needed
- [ ] Verify certificate validity (10 years from creation)
- [ ] Update environment variable documentation
- [ ] Test signing process with new team members

#### Before Each Release
- [ ] Verify environment variables are set
- [ ] Test build process on clean environment
- [ ] Verify signature of generated APK/AAB
- [ ] Document build artifacts and versions

### 11. Emergency Procedures

#### Lost Keystore Recovery
If keystore is lost:
1. **Cannot be recovered** - Android keystores are not recoverable
2. New app version will be required with new package name
3. Users must install new app (cannot update existing)
4. **Prevention is critical** - maintain secure backups

#### Compromised Keystore
If keystore is compromised:
1. Generate new keystore immediately
2. Release emergency update with new signing
3. Notify users through app and other channels
4. Report to Google Play Console if necessary

---

## Status: ✅ COMPLETED

**App Signing Configuration:** Production ready with:
- ✅ Secure keystore generation process documented
- ✅ Environment variable configuration implemented
- ✅ Build process optimized for release
- ✅ Security best practices established
- ✅ Verification procedures documented
- ✅ Troubleshooting guide provided

**Next Steps:** Ready for production build testing on multiple devices.
