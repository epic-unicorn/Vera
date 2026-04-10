import 'package:flutter_test/flutter_test.dart';
import 'package:vera/services/mock_data_service.dart';

void main() {
  group('MockDataService', () {
    late MockDataService mockDataService;

    setUp(() {
      mockDataService = MockDataService();
    });

    // Helper: fetch bundle and unwrap (tests assume success path)
    Future<FhirBundle> getBundle() async {
      final result = await mockDataService.fetchOncologyBundle();
      expect(result.bundle, isNotNull, reason: 'fetchOncologyBundle should succeed');
      expect(result.failure, isNull);
      return result.bundle!;
    }

    // ── Bundle structure ─────────────────────────────────────────────────────

    group('Bundle Structure', () {
      test('fetchOncologyBundle succeeds without failure', () async {
        final result = await mockDataService.fetchOncologyBundle();
        expect(result.failure, isNull);
        expect(result.bundle, isNotNull);
      });

      test('bundle has a timestamp', () async {
        final bundle = await getBundle();
        expect(bundle.timestamp, isNotEmpty);
        expect(bundle.timestamp, contains('T')); // ISO-8601
      });

      test('bundle contains multiple resources', () async {
        final bundle = await getBundle();
        expect(bundle.resources, isNotEmpty);
      });

      test('bundle contains all expected FHIR resource types', () async {
        final bundle = await getBundle();
        final types = bundle.resources.map((r) => r.resourceType).toSet();

        expect(types, containsAll([
          'Patient',
          'Condition',
          'Observation',
          'CarePlan',
          'Appointment',
        ]));
      });
    });

    // ── Patient resource ──────────────────────────────────────────────────────

    group('Patient Resource', () {
      FhirResource getPatient(FhirBundle bundle) =>
          bundle.resources.firstWhere((r) => r.resourceType == 'Patient');

      test('patient resource exists', () async {
        final bundle = await getBundle();
        expect(() => getPatient(bundle), returnsNormally);
      });

      test('patient has a non-empty id', () async {
        final bundle = await getBundle();
        expect(getPatient(bundle).id, isNotEmpty);
      });

      test('patient data contains birthDate', () async {
        final bundle = await getBundle();
        final patient = getPatient(bundle);
        final birthDate = patient.data['birthDate'];
        expect(birthDate, isNotNull);
      });

      test('patient data contains Dutch city in address', () async {
        final bundle = await getBundle();
        final patient = getPatient(bundle);
        final addresses = patient.data['address'] as List?;
        expect(addresses, isNotNull);
        expect(addresses, isNotEmpty);
        final city = (addresses![0] as Map)['city'];
        expect(city, isNotNull);
      });
    });

    // ── Condition (primary diagnosis) ─────────────────────────────────────────

    group('Condition (Diagnosis)', () {
      FhirResource getCondition(FhirBundle bundle) =>
          bundle.resources.firstWhere((r) => r.resourceType == 'Condition');

      test('condition resource exists', () async {
        final bundle = await getBundle();
        expect(() => getCondition(bundle), returnsNormally);
      });

      test('condition contains ICD-10 code C50.4', () async {
        final bundle = await getBundle();
        final condition = getCondition(bundle);
        final coding = ((condition.data['code'] as Map)['coding'] as List)[0] as Map;
        expect(coding['code'], equals('C50.4'));
        expect(coding['system'], contains('icd-10'));
      });

      test('condition display is in Dutch', () async {
        final bundle = await getBundle();
        final condition = getCondition(bundle);
        final display = ((condition.data['code'] as Map)['coding'] as List)[0]['display'] as String;
        expect(display, isNotEmpty);
        // Dutch oncology terminology — display is locale-dependent
        expect(display.toLowerCase(),
            anyOf(contains('invasief'), contains('ductaal'), contains('carcinoom'),
                  contains('mamma'), contains('neoplasma')));
      });

      test('condition has staging information', () async {
        final bundle = await getBundle();
        final condition = getCondition(bundle);
        expect(condition.data['stage'], isNotNull);
      });
    });

    // ── Biomarker observations ────────────────────────────────────────────────

    group('Biomarker Observations', () {
      test('bundle contains Observation resources', () async {
        final bundle = await getBundle();
        final obs = bundle.resources.where((r) => r.resourceType == 'Observation').toList();
        expect(obs, isNotEmpty);
      });

      test('observations have LOINC codes', () async {
        final bundle = await getBundle();
        final obs = bundle.resources.firstWhere((r) => r.resourceType == 'Observation');
        final coding = ((obs.data['code'] as Map)['coding'] as List)[0] as Map;
        expect(coding['system'], contains('loinc'));
      });

      test('Ki-67 observation has percentage value', () async {
        final bundle = await getBundle();
        final ki67 = bundle.resources.firstWhere((r) {
          if (r.resourceType != 'Observation') return false;
          final coding = (r.data['code']?['coding'] as List?)?.firstOrNull as Map?;
          return coding?['display']?.toString().contains('Ki-67') ?? false;
        });
        final value = ki67.data['valueQuantity'] as Map?;
        expect(value, isNotNull);
        expect(value!['value'], equals(38));
      });
    });

    // ── Procedures ────────────────────────────────────────────────────────────

    group('Procedures', () {
      test('bundle contains at least 3 procedures', () async {
        final bundle = await getBundle();
        final procs = bundle.resources.where((r) => r.resourceType == 'Procedure').toList();
        expect(procs.length, greaterThanOrEqualTo(3));
      });

      test('all procedures have a non-empty status', () async {
        final bundle = await getBundle();
        for (final proc in bundle.resources.where((r) => r.resourceType == 'Procedure')) {
          expect(proc.data['status'], isNotEmpty);
        }
      });
    });

    // ── Medications ───────────────────────────────────────────────────────────

    group('Medications', () {
      test('bundle contains at least 3 medication requests', () async {
        final bundle = await getBundle();
        final meds = bundle.resources.where((r) => r.resourceType == 'MedicationRequest').toList();
        expect(meds.length, greaterThanOrEqualTo(3));
      });

      test('medication requests have intent=order', () async {
        final bundle = await getBundle();
        final med = bundle.resources.firstWhere((r) => r.resourceType == 'MedicationRequest');
        expect(med.data['intent'], equals('order'));
      });

      test('medication requests have dosage instructions', () async {
        final bundle = await getBundle();
        final med = bundle.resources.firstWhere((r) => r.resourceType == 'MedicationRequest');
        expect(med.data['dosageInstruction'], isNotNull);
      });
    });

    // ── CarePlan ──────────────────────────────────────────────────────────────

    group('CarePlan', () {
      FhirResource getCarePlan(FhirBundle bundle) =>
          bundle.resources.firstWhere((r) => r.resourceType == 'CarePlan');

      test('bundle contains an active CarePlan', () async {
        final bundle = await getBundle();
        final cp = getCarePlan(bundle);
        expect(cp.data['status'], equals('active'));
      });

      test('CarePlan has 5 treatment activities', () async {
        final bundle = await getBundle();
        final cp = getCarePlan(bundle);
        final activities = cp.data['activity'] as List;
        expect(activities.length, equals(5));
      });

      test('CarePlan references IKNL guideline', () async {
        final bundle = await getBundle();
        final cp = getCarePlan(bundle);
        final description = cp.data['description'] as String;
        expect(description.toLowerCase(), contains('iknl'));
      });
    });

    // ── Appointments ──────────────────────────────────────────────────────────

    group('Appointments', () {
      test('bundle contains at least 3 appointments', () async {
        final bundle = await getBundle();
        final appts = bundle.resources.where((r) => r.resourceType == 'Appointment').toList();
        expect(appts.length, greaterThanOrEqualTo(3));
      });

      test('appointments have ISO-8601 start time', () async {
        final bundle = await getBundle();
        final appt = bundle.resources.firstWhere((r) => r.resourceType == 'Appointment');
        final start = appt.data['start'] as String;
        expect(start, contains('T'));
      });

      test('appointments have participants', () async {
        final bundle = await getBundle();
        final appt = bundle.resources.firstWhere((r) => r.resourceType == 'Appointment');
        final participants = appt.data['participant'] as List;
        expect(participants, isNotEmpty);
      });

      test('fetchAppointments returns list of FhirResource', () async {
        final appointments = await mockDataService.fetchAppointments();
        expect(appointments, isA<List<FhirResource>>());
        expect(appointments, isNotEmpty);
      });
    });

    // ── fetchCarePlan ─────────────────────────────────────────────────────────

    group('fetchCarePlan', () {
      test('returns a CarePlan FhirResource', () async {
        final carePlan = await mockDataService.fetchCarePlan();
        expect(carePlan.resourceType, equals('CarePlan'));
      });

      test('CarePlan data contains activity list', () async {
        final carePlan = await mockDataService.fetchCarePlan();
        expect(carePlan.data['activity'], isList);
        expect((carePlan.data['activity'] as List), isNotEmpty);
      });
    });

    // ── Data consistency ──────────────────────────────────────────────────────

    group('Data Consistency', () {
      test('all resources have non-empty ids', () async {
        final bundle = await getBundle();
        for (final resource in bundle.resources) {
          expect(resource.id, isNotEmpty, reason: '${resource.resourceType} should have an id');
        }
      });

      test('condition references Patient subject', () async {
        final bundle = await getBundle();
        final condition = bundle.resources.firstWhere((r) => r.resourceType == 'Condition');
        expect(condition.data['subject'], isNotNull);
      });
    });

    // ── Performance ───────────────────────────────────────────────────────────

    group('Performance', () {
      test('fetchOncologyBundle completes within 1 second', () async {
        final sw = Stopwatch()..start();
        await mockDataService.fetchOncologyBundle();
        sw.stop();
        expect(sw.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
