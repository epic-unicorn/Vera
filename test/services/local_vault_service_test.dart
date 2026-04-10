import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/error/failures.dart';
import 'package:vera/features/vault/domain/entities/medical_record.dart';
import 'package:vera/services/local_vault_service.dart';

void main() {
  group('LocalVaultService', () {
    late LocalVaultService vaultService;

    setUp(() {
      // Pass null for isar – on the test platform (non-mobile) the vault
      // is never accessed, so no real Isar instance is needed.
      vaultService = LocalVaultService(isar: null);
    });

    // ── Platform guard ───────────────────────────────────────────────────────

    group('Platform Guard (non-mobile)', () {
      test('isVaultInitialised returns false on non-mobile', () async {
        final result = await vaultService.isVaultInitialised();
        expect(result, isFalse);
      });

      test('wipeVault completes without error on non-mobile', () async {
        await expectLater(vaultService.wipeVault(), completes);
      });

      test('createVault throws VaultNotSupportedFailure on non-mobile',
          () async {
        expect(
          () => vaultService.createVault(),
          throwsA(isA<VaultNotSupportedFailure>()),
        );
      });

      test(
          'unlockWithBiometrics throws VaultNotSupportedFailure on non-mobile',
          () async {
        expect(
          () => vaultService.unlockWithBiometrics(),
          throwsA(isA<VaultNotSupportedFailure>()),
        );
      });

      test('storeRecord throws VaultNotSupportedFailure on non-mobile',
          () async {
        final record = MedicalRecord(
          id: 'test-id',
          resourceType: 'Condition',
          title: 'Test record',
          dateRecorded: '2024-04-10',
          anonymisedPayloadJson: '{}',
        );
        expect(
          () => vaultService.storeRecord(record),
          throwsA(isA<VaultNotSupportedFailure>()),
        );
      });

      test('getAllRecords throws VaultNotSupportedFailure on non-mobile',
          () async {
        expect(
          () => vaultService.getAllRecords(),
          throwsA(isA<VaultNotSupportedFailure>()),
        );
      });

      test('deleteRecord throws VaultNotSupportedFailure on non-mobile',
          () async {
        expect(
          () => vaultService.deleteRecord('some-uuid'),
          throwsA(isA<VaultNotSupportedFailure>()),
        );
      });
    });

    // ── Vault state ──────────────────────────────────────────────────────────

    group('Vault State', () {
      test('isUnlocked is false on new instance', () {
        expect(vaultService.isUnlocked, isFalse);
      });

      test('lock() is idempotent on already-locked vault', () {
        vaultService.lock();
        expect(vaultService.isUnlocked, isFalse);
      });

      test('lock() and isUnlocked are consistent', () {
        expect(vaultService.isUnlocked, isFalse);
        vaultService.lock();
        expect(vaultService.isUnlocked, isFalse);
      });
    });

    // ── Failure type hierarchy ───────────────────────────────────────────────

    group('Failure Type Contracts', () {
      test('VaultNotSupportedFailure has correct message', () {
        const failure = VaultNotSupportedFailure();
        expect(failure.message, isNotEmpty);
      });

      test('VaultLockedFailure has correct message', () {
        const failure = VaultLockedFailure();
        expect(failure.message, isNotEmpty);
      });

      test('VaultSelfDestructFailure has correct message', () {
        const failure = VaultSelfDestructFailure();
        expect(failure.message, isNotEmpty);
      });

      test('VaultKeyNotFoundFailure has correct message', () {
        const failure = VaultKeyNotFoundFailure();
        expect(failure.message, isNotEmpty);
      });

      test('AuthBiometricFailure carries supplied message', () {
        const msg = 'Fingerprint sensor not available';
        const failure = AuthBiometricFailure(msg);
        expect(failure.message, equals(msg));
      });

      test('AuthMaxAttemptsFailure has correct message', () {
        const failure = AuthMaxAttemptsFailure();
        expect(failure.message, isNotEmpty);
      });

      test('VaultEncryptionFailure carries supplied message', () {
        const msg = 'Decryption failed: bad padding';
        const failure = VaultEncryptionFailure(msg);
        expect(failure.message, equals(msg));
      });
    });

    // ── MedicalRecord entity ─────────────────────────────────────────────────

    group('MedicalRecord Entity', () {
      test('constructs with required fields', () {
        const record = MedicalRecord(
          id: 'uuid-001',
          resourceType: 'Condition',
          title: 'Invasief ductaal carcinoom',
          dateRecorded: '2024-04-10',
          anonymisedPayloadJson: '{"code":"C50.4"}',
        );

        expect(record.id, equals('uuid-001'));
        expect(record.resourceType, equals('Condition'));
        expect(record.title, equals('Invasief ductaal carcinoom'));
        expect(record.tags, isEmpty);
      });

      test('constructs with optional fields', () {
        const record = MedicalRecord(
          id: 'uuid-002',
          resourceType: 'Procedure',
          title: 'Borstsparende operatie',
          dateRecorded: '2024-05-01',
          anonymisedPayloadJson: '{}',
          iknlGuidelineRef: 'https://richtlijn.nl/borstkanker',
          fhirStatus: 'completed',
          tags: ['surgery', 'oncology'],
        );

        expect(record.iknlGuidelineRef, isNotNull);
        expect(record.fhirStatus, equals('completed'));
        expect(record.tags, hasLength(2));
      });
    });
  });
}
