# Vera: The Trusted Patient Roadmap

### **The Vera Manifesto**

**Vision:** Transform cancer diagnosis data into a clear, personalized roadmap. Vera puts patient understanding first through privacy-focused design and seamless medical integration.

---

## **1. The Problem & Solution**

Patients are currently caught between complex clinical data (Guidelines, Scientific Reports) and generic internet advice. **Vera** uses AI to bridge this gap, connecting **IKNL’s trusted knowledge sources** directly to the individual patient's journey—without ever compromising their privacy.

## **2. Core Features**
*   **The Blueprint:** A visual, interactive timeline mapping the patient's specific diagnosis against national guidelines.
*   **Plain-Language Decoder:** Local NLP translates technical pathology and guideline jargon into understandable "Action Items."
*   **Regional Care-Mapping:** Uses the *Cancer Atlas* to highlight local expertise and support specific to the patient's area.
*   **Proactive "Next-Step" Prep:** Generates personalized questions for the doctor based on upcoming milestones in the *Richtlijnendatabase*.

## **3. Security & Radical Privacy**

Vera is built on a **Zero-Knowledge Architecture**. Your medical journey is yours alone.
*   **Local-First Processing (Edge AI):** All analysis happens in the user's browser or device via [TensorFlow.js](https://tensorflow.org) or [ONNX Runtime](https://onnxruntime.ai). Sensitive records never touch a central server.

*   **The Identity Shield:** Local **Named Entity Recognition (NER)** automatically redacts personal identifiers (names, BSNs) before the Blueprint is generated.

*   **Zero-Knowledge Storage:** Identifiable data stays in an encrypted **Local Vault**. Only anonymized medical markers are used to cross-reference national data.

## **4. Seamless Medical Sync**

Vera is a living system that stays in sync with your actual care via standardized data exchange.

*   **MedMij & FHIR Integration:** Vera uses the [MedMij framework](https://medmij.nl) and **HL7 FHIR R4** standards to securely "pull" updates directly from hospital Electronic Health Records (EPD).

*   **Real-Time Updating:** By using standardized **Oncology Data Models (ODM)**, Vera ensures that your roadmap shifts instantly when new results arrive.

## **5. The Vera Experience (User Journey)**

*   **The Clarity Timeline:** Instead of a list of documents, patients see a horizontal, interactive roadmap. Completed treatments are archived, the "Present" is highlighted with daily action items from **Kanker.nl**, and the "Future" is visualized based on **IKNL Guidelines**.

*   **The Appointment Navigator:** With one click, Vera generates a **"Contextual Pocket Guide"** for the patient’s next doctor visit. It summarizes record changes, logs patient-reported symptoms, and suggests questions based on national guidelines.

*   **The Privacy Sentinel:** A persistent status light confirms: *"Data is secured on this device. No personal records have left your vault."*

## **6. Technical Architecture**

1.  **Layer 1: The Local Secure Vault (Patient Device)**
    *   Raw data (FHIR records, pathology reports) is imported and analyzed locally.
    *   **Local AI (NER)** strips all personal identifiers before anything leaves the device.

2.  **Layer 2: The Vera Knowledge Engine (Anonymized)**
    *   Only medical markers (e.g., "Stage II, Region: Utrecht") are sent to query the trusted sources.
    *   **Semantic Mapping** aligns these markers with [IKNL Guidelines](https://iknl.nl).

3.  **Layer 3: Trusted Source Integration**
    *   Queries [Richtlijnendatabase](https://richtlijnendatabase.nl) and [Cancer Atlas](https://iknl.nl).
---

## **7. Getting Started – Development**

### **Requirements**

- **Flutter SDK:** ≥3.19.0
- **Dart SDK:** ≥3.3.0
- **Git**
- **IDE:** VS Code (recommended) + Flutter/Dart extensions, or Android Studio, or Xcode
- **Platform SDKs:**
  - **Android:** Android SDK 21+ (API level), Android Studio / Android CLI
  - **iOS:** Xcode 12+, CocoaPods
  - **Web:** Any modern browser (Chrome, Firefox, Safari, Edge)

### **Installation**

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/vera.git
cd vera

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate code (Isar schemas, Riverpod providers, build_runner artifacts)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Verify setup (check for any platform issues)
flutter doctor -v
```

### **Project Structure**

```
lib/
├── core/                         # Infrastructure & utilities
│   ├── constants/                # App-wide constants, strings (Dutch)
│   ├── error/                    # Error handling, sealed Failure classes
│   ├── router/                   # GoRouter navigation configuration
│   └── platform/                 # Platform detection utilities
│
├── services/                     # Domain services (crypto, translation, sync)
│   ├── local_vault_service.dart  # AES-256-GCM encryption + biometric auth
│   ├── identity_shield_service.dart  # NER-based PII redaction
│   ├── local_translation_service.dart # On-device ML translation
│   ├── mock_data_service.dart    # FHIR R4 mock bundle
│   └── webrtc_sync_service.dart  # P2P WebRTC sync
│
├── features/                     # Feature modules (Clean Architecture)
│   ├── auth/                     # Authentication (biometric, PIN, self-destruct)
│   ├── blueprint/                # Timeline UI (De Tijdlijn)
│   ├── decoder/                  # Jargon translator (Smart System Decoder)
│   ├── appointments/             # Appointment navigator + voice logging
│   └── sync/                     # Mobile/web P2P sync (QR share, viewer)
│
├── shared/                       # Shared UI components & theme
│   ├── widgets/                  # PrivacySentinel, AppShell, etc.
│   ├── theme/                    # Material 3 + WCAG AA theme
│   └── models/                   # Domain entities (TimelineEvent, JargonEntry)
│
├── main.dart                     # Entry point with platform-guarded Isar init
└── app.dart                      # Root widget (MaterialApp.router)
```

### **Development Workflow**

#### **Web Development (Quickest)**
```bash
# Hot reload in browser (Chrome by default)
flutter run -d chrome

# Edit any file and save → auto-hot-reload in browser
```

#### **Mobile (Android) Development**
```bash
# Run on emulator
flutter run -d emulator-5554

# Or on physical device (with USB debugging enabled)
flutter run -d <device_id>

# List available devices
flutter devices
```

#### **Mobile (iOS) Development**
```bash
# Run on simulator
flutter run -d ios

# Or on physical device (requires provisioning profile)
flutter run -d <device_id>

# View iOS project in Xcode
open ios/Runner.xcworkspace
```

### **Key Development Features**

**🔒 Local Vault (Mobile Only)**
- Encrypted AES-256-GCM storage in `flutter_secure_storage` (OS Keychain/Keystore)
- Biometric (fingerprint/Face ID) gate with 5-attempt self-destruct
- Access via `LocalVaultService` in your widgets:
  ```dart
  final vaultService = ref.watch(localVaultServiceProvider);
  final success = await vaultService.unlockWithBiometrics();
  ```

**🛡️ Identity Shield (Privacy by Default)**
- ML Kit Named Entity Recognition (NER) detects PII automatically
- Deterministic regex redaction (Dutch BSN, postcodes, emails)
- All data redacted before leaving device:
  ```dart
  final shield = ref.watch(identityShieldServiceProvider);
  final safe = await shield.shieldMap(unsafeData);
  ```

**🌐 Local Translation**
- On-device translation via ML Kit (11 languages supported)
- Download management with progress tracking
- Zero external API calls for medical text:
  ```dart
  final translator = ref.watch(localTranslationServiceProvider);
  final translated = await translator.translate('Medical jargon', targetLang);
  ```

**🎯 State Management (Riverpod)**
- All business logic in providers for testability
- FutureProviders for async data (FHIR bundles, timelines)
- StateNotifiers for complex features (vault auth, translation state)
- Example:
  ```dart
  final mockDataProvider = FutureProvider((ref) => 
    MockDataService().fetchOncologyBundle());
  ```

**♿ Accessibility (WCAG 2.1 Level AA)**
- Atkinson Hyperlegible font for low-vision users
- Verified 4.5:1+ contrast ratios on all UI elements
- 48dp minimum touch targets
- Semantic labels for screen readers
- See `lib/shared/theme/vera_theme.dart` for implementation

### **Running the App**

```bash
# Web
flutter run -d chrome --release

# Android
flutter run -d <device_id> --release

# iOS
flutter run -d <device_id> --release
```

### **Hot Reload & Debugging**

```bash
# Hot reload (preserves app state)
r        # in terminal after flutter run

# Full restart (restarts app)
R        # in terminal after flutter run

# View logs
flutter logs

# Attach debugger
flutter attach
```

### **Code Generation & Build Runner**

After editing Isar models or adding new Riverpod providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Or watch for changes:**
```bash
flutter pub run build_runner watch
```

### **Testing**

```bash
# Run all tests
flutter test

# Run tests in a specific file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

### **Building for Release**

**Android:**
```bash
# APK (for testing on devices)
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
# Then use Xcode: Product > Archive > Distribute App
```

**Web:**
```bash
flutter build web --release
# Deploy build/web/* to your hosting (Vercel, Netlify, Firebase, etc.)
```

### **Database Initialization (Mobile)**

Isar is auto-initialized on app startup:
```dart
// In main.dart
if (PlatformDetector.isMobileApp) {
  await Isar.initialize();
}
```

No manual setup required — schema generated by build_runner.

### **Mock Data**

For development/demo without connecting to real hospital EPDs:

```dart
final mockBundle = await MockDataService().fetchOncologyBundle();
// Returns complete FHIR R4 bundle with Dutch patient data
```

See `lib/services/mock_data_service.dart` for example oncology records.

---

## **8. Security Considerations**

- ✅ **Never log encryption keys or PII** — Use typed `Failure` classes instead
- ✅ **All secrets in `flutter_secure_storage`** — Never persist to Isar
- ✅ **Biometric gated before any vault unlock** — 5-attempt self-destruct active
- ✅ **Data redacted before external queries** — IdentityShieldService enforces this
- ✅ **Zero-cloud translation** — ML Kit models downloaded locally only
- ✅ **Ephemeral web data** — Cleared on browser close (by design)

---

## **9. Contributing**

1. Create a branch: `git checkout -b feature/your-feature`
2. Follow the Clean Architecture pattern (feature-first structure)
3. Use typed errors (`sealed Failure` classes) for all error paths
4. Ensure WCAG 2.1 AA accessibility (test with screen reader)
5. Add semantic labels to all interactive widgets
6. Test on both mobile & web before submitting PR
7. Commit: `git commit -am "feat: description"`
8. Push & create a pull request

---

## **10. Useful Commands Reference**

```bash
# Setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Development
flutter run -d chrome        # Web
flutter run -d emulator-5554 # Android
flutter run -d ios           # iOS
flutter logs

# Maintenance
flutter doctor -v
flutter pub upgrade
flutter pub outdated

# Building
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build web --release

# Testing
flutter test
flutter test --coverage

# Code quality
dart analyze
dart format lib/
```

---

## **11. Troubleshooting**

**"Biometric fails on device"**
- Verify `android.permission.USE_BIOMETRIC` in `AndroidManifest.xml` (✓ included)
- Verify `NSFaceIDUsageDescription` + `NSBiometryUsageDescription` in iOS `Info.plist` (✓ included)
- Device must have biometric hardware (fingerprint/Face ID scanner)

**"Web P2P connection fails"**
- Check HTTPS (required for WebRTC except localhost)
- Verify browser console for WebSocket signalling errors
- Ensure TURN server configured in production

**"Isar crashes on startup"**
- Run `flutter clean && flutter pub run build_runner build --delete-conflicting-outputs`
- Delete iOS build: `rm -rf ios/Pods/ ios/Podfile.lock`
- Re-run: `flutter pub get && flutter run`

**"ML Kit translation fails"**
- Verify platform: Translation only on mobile (web uses typed failure)
- Check device has internet for model download
- Models cached after first download

---

## **Resources**

- **Flutter Docs:** [flutter.dev/docs](https://flutter.dev/docs)
- **FHIR R4 Spec:** [hl7.org/fhir/r4](http://hl7.org/fhir/r4)
- **IKNL Guidelines:** [iknl.nl](https://iknl.nl)
- **Clean Architecture:** [resocoder.com](https://resocoder.com)
- **Riverpod Guide:** [riverpod.dev](https://riverpod.dev)
- **Material 3 Design:** [m3.material.io](https://m3.material.io)

---

**Last Updated:** April 10, 2026  
**License:** MIT  
**Maintainer:** Vera Team    *   Compiles a personalized, visual **Vera Blueprint** returned to the patient’s encrypted local sandbox.