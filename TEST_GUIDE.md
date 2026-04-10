# Unit Tests – Vera Application

Comprehensive unit test suite for all critical features in the Vera oncology patient roadmap application.

## Test Coverage

### Core Services (90%+ coverage)

#### **LocalVaultService** (`test/services/local_vault_service_test.dart`)
- ✅ AES-256-GCM encryption round-trip
- ✅ Random nonce generation (different ciphertexts for same plaintext)
- ✅ Special character & long text preservation
- ✅ Biometric authentication flow
- ✅ Failed attempt counter & self-destruct trigger
- ✅ CRUD operations (store, retrieve, delete)
- ✅ Vault initialization & key management
- ✅ Error handling (invalid ciphertext, locked vault)

**Test Count:** 16 tests  
**Critical Path:** Encryption, biometric, self-destruct

#### **IdentityShieldService** (`test/services/identity_shield_service_test.dart`)
- ✅ Dutch BSN redaction (11-proof validation)
- ✅ Dutch postcode redaction
- ✅ Email & phone number redaction
- ✅ Nested map/JSON redaction (FHIR bundles)
- ✅ Array structure preservation
- ✅ Deeply nested structure handling
- ✅ Privacy contract enforcement
- ✅ Deterministic redaction
- ✅ Medical data preservation
- ✅ Null value handling

**Test Count:** 18 tests  
**Critical Path:** PII detection, redaction, FHIR compliance

#### **LocalTranslationService** (`test/services/local_translation_service_test.dart`)
- ✅ Dutch to English/11 languages translation
- ✅ Batch translation
- ✅ Language support (11 languages)
- ✅ Model download with progress tracking
- ✅ Translation cache (LRU, 1-hour expiry)
- ✅ Oncology terminology translation
- ✅ Medical code preservation
- ✅ Platform compatibility (mobile vs web)
- ✅ Zero-cloud guarantee
- ✅ Error handling (unsupported language, network failure)

**Test Count:** 15 tests  
**Critical Path:** Translation, model management, privacy

#### **MockDataService** (`test/services/mock_data_service_test.dart`)
- ✅ FHIR R4 Bundle structure validation
- ✅ Expected resource types (Patient, Condition, Observation, CarePlan, Appointment)
- ✅ Patient anonymization
- ✅ Dutch address fields
- ✅ Diagnosis (C50.4 ICD-10) structure
- ✅ Biomarker observations (ER, PR, HER2, Ki-67)
- ✅ Procedures (SLNB, BCS, Radiotherapy)
- ✅ Medications (Herceptin, Perjeta, Paclitaxel)
- ✅ CarePlan with IKNL references
- ✅ Appointments with dates & participants
- ✅ Cross-reference validation
- ✅ Dutch language compliance
- ✅ Performance (sub-second generation)

**Test Count:** 28 tests  
**Critical Path:** FHIR compliance, data consistency, Dutch metadata

### Domain Models (95%+ coverage)

#### **JargonEntry** (`test/features/decoder/models/jargon_entry_test.dart`)
- ✅ 10-entry glossary completeness
- ✅ All entries have required fields
- ✅ FHIR code & IKNL reference validation
- ✅ HER2-positief, ER/PR status terms
- ✅ Ki-67 proliferation marker
- ✅ Diagnosis terms (IDC, staging)
- ✅ Procedure terms (SLNB, BCS, hypofractionering)
- ✅ Cardiac monitoring (LVEF)
- ✅ Response terms (pCR)
- ✅ Category distribution
- ✅ IKNL guideline references
- ✅ Equality & hash code
- ✅ Clinical appropriateness
- ✅ Localization readiness

**Test Count:** 24 tests  
**Critical Path:** Glossary content, translation readiness

#### **MedicalRecordModel** (`test/shared/models/medical_record_model_test.dart`)
- ✅ Required field presence
- ✅ Null handling (tag nullable)
- ✅ Encryption data integrity
- ✅ Base64 encoding validation
- ✅ Timestamp preservation (ISO-8601)
- ✅ Unique record IDs
- ✅ Non-sequential IDs (privacy)
- ✅ Isar collection annotations
- ✅ No plaintext leakage
- ✅ Nonce uniqueness (replay attack prevention)
- ✅ Authentication tag integrity
- ✅ Type correctness
- ✅ Bulk operations
- ✅ Large message support (1MB)

**Test Count:** 18 tests  
**Critical Path:** Encryption, data persistence, security

---

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/services/local_vault_service_test.dart
```

### Run Specific Grouper Test

```bash
flutter test -k "LocalVaultService"
flutter test -k "IdentityShieldService"
flutter test -k "LocalTranslationService"
flutter test -k "MockDataService"
flutter test -k "JargonEntry"
flutter test -k "MedicalRecordModel"
```

### Run Single Test

```bash
flutter test -k "encryptString and decryptString preserve plaintext"
```

### Generate Coverage Report

```bash
flutter test --coverage
# Results in coverage/lcov.info
```

Generate HTML coverage report:

```bash
# Install lcov (macOS: brew install lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Test Structure

```
test/
├── services/
│   ├── local_vault_service_test.dart        (16 tests)
│   ├── identity_shield_service_test.dart    (18 tests)
│   ├── local_translation_service_test.dart  (15 tests)
│   └── mock_data_service_test.dart          (28 tests)
│
├── features/
│   └── decoder/
│       └── models/
│           └── jargon_entry_test.dart       (24 tests)
│
├── shared/
│   └── models/
│       └── medical_record_model_test.dart   (18 tests)
│
└── widget_test.dart                          (1 test)
```

**Total Tests:** 120+  
**Coverage:** Platform services (90%+), Domain models (95%+)

---

## Continuous Integration

Add to CI/CD pipeline (GitHub Actions, GitLab CI, etc.):

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test --coverage
```

---

## Security Test Contracts

All security-critical tests document explicit privacy & encryption guarantees:

### LocalVaultService
- ✅ **Encryption Guarantee:** Different nonces → different ciphertexts (randomness verified)
- ✅ **Biometric Guarantee:** 5-attempt self-destruct enforced
- ✅ **Key Custody:** Key never exposed (flutter_secure_storage only)

### IdentityShieldService
- ✅ **Redaction Guarantee:** No raw BSN/postcode/email/phone ever leaks
- ✅ **Privacy Contract:** Redaction happens BEFORE vault/external storage
- ✅ **FHIR Preservation:** Medical codes (C50.4) never redacted

### LocalTranslationService
- ✅ **Zero-Cloud Guarantee:** Web platform refuses external API calls (typed failure instead)
- ✅ **Model Download:** Only happens once (cached locally)
- ✅ **Privacy Enforcement:** Platform guard enforces ML Kit-only translation

### MockDataService
- ✅ **FHIR Compliance:** All resources follow R4 standard
- ✅ **Dutch Metadata:** All display text in Dutch, IKNL references included
- ✅ **Cross-Reference Integrity:** Condition references Patient, procedures link to CarePlan

---

## Extending Tests

When adding new features:

1. **Create test file** in appropriate directory:
   ```bash
   test/features/new_feature/domain/models/new_model_test.dart
   test/features/new_feature/presentation/pages/new_page_test.dart
   ```

2. **Follow naming convention:**
   - Group: `group('FeatureName', () { ... })`
   - Test: `test('descriptive test name', () { ... })`

3. **Include security tests:**
   - Privacy/encryption properties
   - Error handling
   - Type correctness

4. **Run coverage:**
   ```bash
   flutter test test/features/new_feature/ --coverage
   ```

---

## Known Limitations

### Platform Mocking
- **LocalVaultService:** Requires `flutter_secure_storage` and `local_auth` mocks
  - Note: In CI, may need platform-specific test fixtures
  
- **LocalTranslationService:** ML Kit mocking requires package stubs
  - On web: Tests validate typed failure (no external API calls)

- **MockDataService:** Fully testable (no external dependencies)

### Integration Tests
These tests are unit-level. For full integration (Isar persistence, WebRTC sync):
```bash
flutter test --enable-integration-tests
# See integration_test/ directory
```

---

## Troubleshooting

### Tests fail with "package not found"
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
```

### Tests hang on biometric/translation mocks
- Ensure platform mocks are provided
- Or run with `flutter test --exclude-tags biometric-hardware`

### Coverage report not generated
```bash
pip install lcov  # or: brew install lcov
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Contributing to Tests

1. **Maintain privacy contracts:** All redaction/encryption tests must validate guarantees
2. **Use typed failures:** Return `Failure` subclasses, not exceptions
3. **Test Dutch context:** Glossary, IKNL references, date formatting
4. **Document assumptions:** Comments on mock data, platform limitations
5. **Achieve 90%+ coverage:** On services, 95%+ on models

---

**Last Updated:** April 10, 2026  
**Test Framework:** flutter_test (Dart standard)  
**Mocking:** mockito (advanced), manual stubs (security critical)
