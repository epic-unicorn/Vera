# Vera – Platform Setup & Build Guide

This document provides comprehensive setup instructions for building Vera across Android, iOS, and Web platforms.

---

## 📋 Prerequisites

- **Flutter SDK:** ≥3.19.0
- **Dart SDK:** ≥3.3.0
- **IDE:** VS Code + Flutter/Dart extensions, or Android Studio, or Xcode

### Install Flutter
```bash
flutter doctor -v
```

---

## 🔧 Platform-Specific Setup

### Android (API Level 21+)

**Configuration Files:**
- `android/app/src/main/AndroidManifest.xml` — Contains `<uses-permission android:name="android.permission.USE_BIOMETRIC" />`
- `android/build.gradle.kts` — Build configuration
- `android/app/build.gradle.kts` — App-level Gradle config

**Required Permissions:**
✅ **Biometric** (`android.permission.USE_BIOMETRIC`) — Fingerprint/Face unlock for vault authentication

**Build Instructions:**

```bash
# For emulator
flutter run -d emulator-5554

# For physical device
flutter run -d <device_id>

# Release build
flutter build apk --release
# or for App Bundle (recommended for Play Store)
flutter build appbundle --release
```

**iOS Specifics:**
- Minimum API: API 21 (Android 5.0)
- Device capabilities: Fingerprint sensor recommended

---

### iOS (iOS 11.0+)

**Configuration Files:**
- `ios/Runner/Info.plist` — Contains Face ID + Touch ID usage descriptions:
  - `NSFaceIDUsageDescription` — Face ID access request
  - `NSBiometryUsageDescription` — Touch ID/Face ID general access

- `ios/Runner.xcodeproj/project.pbxproj` — Project configuration
- `ios/Podfile` — Dependency management (auto-generated on first `flutter pub get`)

**Required Permissions:**
✅ **Face ID** (`NSFaceIDUsageDescription`) — Facial recognition unlock  
✅ **Touch ID / Face ID** (`NSBiometryUsageDescription`) — Biometric authentication  
✅ **Keychain** — Automatic entitlement for secure key storage (Secure Enclave on A7+ chips)

**Xcode Setup:**
1. Open Xcode workspace:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Select **Runner** > **Signing & Capabilities**
   - Add **Keychain Sharing** capability (auto-enabled for `flutter_secure_storage`)
   - Verify Team ID is set

3. Set minimum deployment target:
   - Select **Runner** target
   - General → Minimum Deployments
   - iOS 11.0 (required for flutter_webrtc)

**Build Instructions:**

```bash
# For simulator
flutter run -d ios

# For physical device
flutter run -d <device_id>

# Release build
flutter build ios --release

# Create App Store Build Archive
flutter build ios --release
# Then use Xcode: Product > Archive > Distribute App
```

**Biometric Configuration:**
- **A7+ chips** (iPhone 5s & newer): Full Face ID + Touch ID support via Secure Enclave
- **Older devices**: Touch ID only
- Local vault key stored in Keychain (automatically encrypted in Secure Enclave)

---

### Web

**Configuration Files:**
- `web/index.html` — HTML entry point
- `web/manifest.json` — PWA manifest

**Platform Limitations:**
⚠️ **No Biometric Support** — Web uses RAM-only ephemeral data storage instead  
⚠️ **No Local Encryption** — Private data not persisted (security design choice for web viewers)  
✅ **P2P WebRTC** — Full mobile-to-web sync support via QR code connection

**Browser Requirements:**
- Chrome/Chromium 60+
- Firefox 55+
- Safari 11+ (WebRTC support)
- Edge 79+

**Build Instructions:**

```bash
# Debug build
flutter run -d chrome

# Release build
flutter build web --release

# Serve locally
flutter run -d chrome --release

# Deploy to hosting (output in build/web/)
# Upload build/web/* to your hosting provider
```

**WebRTC Note:**
- No TURN server required for local network sync
- For internet-remote sync, configure TURN server in production

---

## 🚀 Building All Platforms

### Full Build Sequence

```bash
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Generate code (Isar, Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Build for each platform
flutter build apk --release          # Android
flutter build ios --release          # iOS
flutter build web --release          # Web
```

### Platform-Specific Checks

```bash
# Verify platform readiness
flutter doctor -v

# Check which platforms are available
flutter run --list-emulators
```

---

## 🔐 Security Configuration

### Android Keystore
- Biometric key stored in **Android Keystore** (encrypted by TEE if available)
- Automatic hardware-backed encryption on compatible devices (API 21+)
- `flutter_secure_storage` handles all encryption transparently

### iOS Keychain & Secure Enclave
- Vault master key stored in **Keychain** with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- On A7+ devices: Key stored in **Secure Enclave** (tamper-resistant hardware)
- Biometric authentication gated by iOS Security Framework
- All encryption performed locally; no CloudKit sync

### Web (No Local Encryption)
- Data lives only in browser RAM
- Cleared on tab/browser close (intentional design for privacy)
- P2P sync via DTLS (WebRTC data-channel)

---

## 📦 Dependency Management

Key security-critical dependencies:

| Package | Version | Purpose |
|---------|---------|---------|
| `local_auth` | ^2.x | Biometric authentication |
| `flutter_secure_storage` | ^9.x | Secure key storage |
| `encrypt` | ^6.x | AES-256-GCM encryption |
| `flutter_webrtc` | ^0.x | P2P WebRTC sync |
| `isar` | ^3.x | Local encrypted database (mobile) |

All dependencies auto-handled by `flutter pub get`.

---

## 🧪 Testing on Real Devices

### Android Physical Device

```bash
# Enable USB debugging
# Settings > Developer Options > USB Debugging

flutter run -d <device_id>
```

### iOS Physical Device

```bash
# Trust developer certificate on device
# Settings > General > VPN & Device Management > [Your Team ID] > Trust

flutter run -d <device_id>
```

### Web

```bash
flutter run -d chrome
# Opens in default Chrome browser
```

---

## 📝 Troubleshooting

### Android
- **Biometric permission denied**: Ensure `android.permission.USE_BIOMETRIC` in AndroidManifest.xml ✓
- **Build failure**: Run `flutter clean && flutter pub get && flutter pub run build_runner build`

### iOS
- **Biometric always fails**: Check `NSFaceIDUsageDescription` + `NSBiometryUsageDescription` in Info.plist ✓
- **Keychain errors**: Verify Team ID in Xcode project settings
- **WebRTC incompatible**: Update Podfile deployment target to iOS 11.0+

### Web
- **QR scanner not working**: Ensure HTTPS (localhost:8080 OK for dev)
- **WebRTC connection fails**: Check browser console for STUN/signalling errors

---

## 📤 Release Deployment

### Android Play Store
```bash
flutter build appbundle --release
# Upload build/app/outputs/bundle/release/app-release.aab to Play Console
```

### iOS App Store
```bash
flutter build ios --release
# Use Xcode: Product > Archive > Distribute App > App Store
```

### Web Hosting
```bash
flutter build web --release
# Deploy build/web/* to Vercel, Netlify, Firebase Hosting, etc.
```

---

## ✅ Verification Checklist

- [x] Android: Biometric permission in `AndroidManifest.xml`
- [x] iOS: Face ID + Touch ID descriptions in `Info.plist`
- [x] iOS: Deployment target ≥ 11.0 for WebRTC
- [x] iOS: Keychain sharing capability in Xcode
- [x] Web: PWA manifest configured
- [x] All platforms: `flutter pub get` completed
- [x] All platforms: `build_runner` schema generated

---

## 📚 References

- [Flutter Android Documentation](https://flutter.dev/docs/deployment/android)
- [Flutter iOS Documentation](https://flutter.dev/docs/deployment/ios)
- [Flutter Web Documentation](https://flutter.dev/docs/get-started/web)
- [local_auth Package](https://pub.dev/packages/local_auth)
- [flutter_secure_storage Package](https://pub.dev/packages/flutter_secure_storage)
- [flutter_webrtc Package](https://pub.dev/packages/flutter_webrtc)

---

**Last Updated:** April 10, 2026  
**Vera Version:** 1.0.0  
**Flutter:** ≥3.19.0 | **Dart:** ≥3.3.0
