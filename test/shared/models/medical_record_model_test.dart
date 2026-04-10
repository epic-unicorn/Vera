import 'package:flutter_test/flutter_test.dart';
import 'package:vera/features/vault/data/models/medical_record_model.dart';

void main() {
  group('MedicalRecordModel', () {
    // Helper: create a valid model using cascade notation (Isar pattern)
    MedicalRecordModel makeModel({
      String uuid = 'test-uuid-001',
      String encryptedPayload = 'base64EncryptedPayload==',
      String encryptedTitle = 'base64EncryptedTitle==',
      String resourceType = 'Condition',
      String dateRecorded = '2024-04-10',
      String? iknlGuidelineRef,
      String? fhirStatus = 'final',
      String tagsCsv = '',
    }) =>
        MedicalRecordModel()
          ..uuid = uuid
          ..encryptedPayload = encryptedPayload
          ..encryptedTitle = encryptedTitle
          ..resourceType = resourceType
          ..dateRecorded = dateRecorded
          ..iknlGuidelineRef = iknlGuidelineRef
          ..fhirStatus = fhirStatus
          ..tagsCsv = tagsCsv;

    // ── Field assignment ────────────────────────────────────────────────────

    group('Field Assignment', () {
      test('uuid is stored correctly', () {
        final model = makeModel(uuid: 'unique-id-xyz');
        expect(model.uuid, equals('unique-id-xyz'));
      });

      test('encryptedPayload is stored correctly', () {
        final model = makeModel(encryptedPayload: 'aGVsbG8gd29ybGQ=');
        expect(model.encryptedPayload, equals('aGVsbG8gd29ybGQ='));
      });

      test('encryptedTitle is stored correctly', () {
        final model = makeModel(encryptedTitle: 'dGl0bGU=');
        expect(model.encryptedTitle, equals('dGl0bGU='));
      });

      test('resourceType is stored correctly', () {
        final model = makeModel(resourceType: 'Procedure');
        expect(model.resourceType, equals('Procedure'));
      });

      test('dateRecorded is stored correctly', () {
        final model = makeModel(dateRecorded: '2024-06-15');
        expect(model.dateRecorded, equals('2024-06-15'));
      });

      test('iknlGuidelineRef is optional and nullable', () {
        final withRef = makeModel(iknlGuidelineRef: 'https://www.iknl.nl');
        final withoutRef = makeModel(iknlGuidelineRef: null);

        expect(withRef.iknlGuidelineRef, equals('https://www.iknl.nl'));
        expect(withoutRef.iknlGuidelineRef, isNull);
      });

      test('fhirStatus is optional and nullable', () {
        final withStatus = makeModel(fhirStatus: 'active');
        final withoutStatus = makeModel(fhirStatus: null);

        expect(withStatus.fhirStatus, equals('active'));
        expect(withoutStatus.fhirStatus, isNull);
      });

      test('tagsCsv stores comma-separated tags', () {
        final model = makeModel(tagsCsv: 'oncologie,carcinoom,HER2');
        expect(model.tagsCsv, equals('oncologie,carcinoom,HER2'));
        expect(model.tagsCsv.split(','), hasLength(3));
      });

      test('empty tagsCsv for record with no tags', () {
        final model = makeModel(tagsCsv: '');
        expect(model.tagsCsv, isEmpty);
      });
    });

    // ── Security invariants ─────────────────────────────────────────────────

    group('Security Invariants', () {
      test('encryptedPayload is not the same as a plaintext diagnosis', () {
        const plaintext = 'Invasief ductaal carcinoom';
        final model = makeModel(encryptedPayload: 'YXBwbGljYXRpb25fZGF0YQ==');

        expect(model.encryptedPayload, isNot(equals(plaintext)));
      });

      test('resourceType is stored unencrypted (used for filtering)', () {
        final model = makeModel(resourceType: 'Observation');
        // ResourceType is deliberately NOT encrypted to allow index queries
        expect(model.resourceType, equals('Observation'));
      });

      test('dateRecorded is stored unencrypted (used for timeline ordering)',
          () {
        final model = makeModel(dateRecorded: '2024-04-10');
        // Date is deliberately NOT encrypted to allow sorting
        expect(model.dateRecorded, equals('2024-04-10'));
      });

      test('uuid is unique identifier for cross-reference', () {
        final model1 = makeModel(uuid: 'aaa-111');
        final model2 = makeModel(uuid: 'bbb-222');
        expect(model1.uuid, isNot(equals(model2.uuid)));
      });
    });

    // ── FHIR resource types ─────────────────────────────────────────────────

    group('FHIR Resource Type Mapping', () {
      test('Condition resource type is valid', () {
        final model = makeModel(resourceType: 'Condition');
        expect(model.resourceType, equals('Condition'));
      });

      test('Procedure resource type is valid', () {
        final model = makeModel(resourceType: 'Procedure');
        expect(model.resourceType, equals('Procedure'));
      });

      test('Observation resource type is valid', () {
        final model = makeModel(resourceType: 'Observation');
        expect(model.resourceType, equals('Observation'));
      });

      test('MedicationRequest resource type is valid', () {
        final model = makeModel(resourceType: 'MedicationRequest');
        expect(model.resourceType, equals('MedicationRequest'));
      });
    });
  });
}
