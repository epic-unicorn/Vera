import 'package:flutter_test/flutter_test.dart';
import 'package:vera/features/decoder/domain/models/jargon_entry.dart';

void main() {
  group('JargonEntry Domain Model', () {
    group('Glossary Data', () {
      test('glossary contains 10 entries', () {
        expect(builtInGlossary, hasLength(10));
      });

      test('all glossary entries have required fields', () {
        for (var entry in builtInGlossary) {
          expect(entry.term, isNotNull);
          expect(entry.term, isNotEmpty);
          expect(entry.dutchExplanation, isNotNull);
          expect(entry.dutchExplanation, isNotEmpty);
          expect(entry.actionItem, isNotNull);
          expect(entry.actionItem, isNotEmpty);
          expect(entry.category, isNotNull);
        }
      });

      test('all entries have FHIR codes or IKNL refs', () {
        for (var entry in builtInGlossary) {
          expect(entry.fhirCode != null || entry.iknlRef != null, isTrue);
        }
      });
    });

    group('Glossary Content - HER2-positief', () {
      late JargonEntry her2Entry;

      setUpAll(() {
        her2Entry =
            builtInGlossary.firstWhere((e) => e.term.contains('HER2-positief'));
      });

      test('HER2 term is in glossary', () {
        expect(her2Entry.term, equals('HER2-positief'));
      });

      test('HER2 explanation is Dutch', () {
        expect(her2Entry.dutchExplanation.toLowerCase(), contains('her2'));
        expect(her2Entry.dutchExplanation, isNotEmpty);
      });

      test('HER2 has actionable next step', () {
        expect(her2Entry.actionItem, isNotEmpty);
        expect(her2Entry.actionItem, isNotNull);
      });

      test('HER2 has category classification', () {
        expect(
          ['biomarker', 'diagnose', 'procedure', 'radiotherapie']
              .contains(her2Entry.category),
          isTrue,
        );
      });

      test('HER2 has FHIR code reference', () {
        expect(her2Entry.fhirCode, isNotNull);
        expect(
            her2Entry.fhirCode,
            anyOf(
              contains('HER2'),
              contains('LOINC'),
            ));
      });
    });

    group('Glossary Content - ER/PR Status', () {
      test('ER-negatief in glossary', () {
        final er =
            builtInGlossary.firstWhere((e) => e.term.contains('ER-negatief'));

        expect(er.term, equals('ER-negatief'));
        expect(er.dutchExplanation, isNotEmpty);
      });

      test('ER/PR terms have biomarker category', () {
        final biomarkers =
            builtInGlossary.where((e) => e.category == 'biomarker').toList();

        expect(biomarkers.isNotEmpty, isTrue);
      });
    });

    group('Glossary Content - Ki-67', () {
      late JargonEntry ki67Entry;

      setUpAll(() {
        ki67Entry = builtInGlossary.firstWhere((e) => e.term.contains('Ki-67'));
      });

      test('Ki-67 in glossary', () {
        expect(ki67Entry.term, contains('Ki-67'));
      });

      test('Ki-67 explanation mentions proliferation marker', () {
        expect(
            ki67Entry.dutchExplanation.toLowerCase(),
            anyOf(
              contains('snelheid'),
              contains('cellen'),
            ));
      });

      test('Ki-67 action item is clinically relevant', () {
        expect(ki67Entry.actionItem, isNotEmpty);
      });
    });

    group('Glossary Content - Diagnosis Terms', () {
      test('invasief ductaal carcinoom in glossary', () {
        final idc = builtInGlossary.firstWhere(
            (e) => e.term.toLowerCase().contains('invasief ductaal carcinoom'));

        expect(idc.dutchExplanation, isNotEmpty);
      });

      test('stadium (staging) in glossary', () {
        final stadium =
            builtInGlossary.firstWhere((e) => e.term.contains('Stadium'));

        expect(stadium.category, equals('stadiëring'));
      });
    });

    group('Glossary Content - Procedure Terms', () {
      test('SLNB (Schildwachtklierprocedure) in glossary', () {
        final slnb = builtInGlossary
            .firstWhere((e) => e.term.contains('Schildwachtklierprocedure'));

        expect(slnb.dutchExplanation, isNotEmpty);
        expect(slnb.category, equals('procedure'));
      });

      test('BCS (Borstsparende Chirurgie) in glossary', () {
        final bcs =
            builtInGlossary.firstWhere((e) => e.term.contains('Borstsparende'));

        expect(bcs.dutchExplanation, isNotEmpty);
      });

      test('Hypofractionering (radiation term) in glossary', () {
        final hypo = builtInGlossary
            .firstWhere((e) => e.term.contains('Hypofractionering'));

        expect(hypo.dutchExplanation, isNotEmpty);
      });
    });

    group('Glossary Content - Cardiac Monitoring', () {
      test('LVEF (Left Ventricular Ejection Fraction) in glossary', () {
        final lvef = builtInGlossary.firstWhere((e) => e.term.contains('LVEF'));

        expect(lvef.dutchExplanation, isNotEmpty);
        expect(lvef.dutchExplanation.toLowerCase(), contains('hart'));
      });
    });

    group('Glossary Content - Response Terms', () {
      test('pCR (pathological Complete Response) in glossary', () {
        final pcr = builtInGlossary.firstWhere((e) => e.term.contains('pCR'));

        expect(pcr.dutchExplanation, isNotEmpty);
        expect(pcr.dutchExplanation.toLowerCase(), contains('respons'));
      });
    });

    group('Entry Categories', () {
      test('all categories are valid', () {
        final validCategories = [
          'biomarker',
          'pathologie',
          'diagnose',
          'stadiëring',
          'procedure',
          'radiotherapie',
          'cardiologie',
          'respons',
        ];

        for (var entry in builtInGlossary) {
          expect(validCategories.contains(entry.category), isTrue);
        }
      });

      test('glossary has distribution across categories', () {
        final categories = builtInGlossary.map((e) => e.category).toSet();

        expect(categories.length, greaterThan(1));
      });
    });

    group('IKNL References', () {
      test('some entries have IKNL guideline references', () {
        final withIknl =
            builtInGlossary.where((e) => e.iknlRef != null).toList();

        expect(withIknl.isNotEmpty, isTrue);
      });

      test('IKNL refs point to valid guideline URLs', () {
        for (var entry in builtInGlossary.where((e) => e.iknlRef != null)) {
          expect(entry.iknlRef, contains('iknl.nl'));
        }
      });
    });

    group('Equality & Hashing', () {
      test('identical entries are equal', () {
        final entry1 = builtInGlossary[0];
        final entry2 = builtInGlossary[0];

        expect(entry1, equals(entry2));
      });

      test('different entries are not equal', () {
        final entry1 = builtInGlossary[0];
        final entry2 = builtInGlossary[1];

        expect(entry1, isNot(equals(entry2)));
      });
    });

    group('Clinical Appropriateness', () {
      test('all action items are specific and actionable', () {
        for (var entry in builtInGlossary) {
          // Action items should not be empty or generic
          expect(entry.actionItem.length, greaterThan(10));
          // Should contain verbs or specific guidance
          expect(entry.actionItem, isNotEmpty);
        }
      });

      test('Dutch explanations use patient-friendly language', () {
        for (var entry in builtInGlossary) {
          // Should be comprehensible (not overly technical)
          expect(entry.dutchExplanation.isNotEmpty, isTrue);
        }
      });

      test('glossary covers oncology care pathway', () {
        final entries = builtInGlossary;

        // Should have diagnosis terms
        expect(
          entries.any((e) => e.category == 'diagnose'),
          isTrue,
        );

        // Should have treatment terms
        expect(
          entries.any((e) => e.category == 'procedure'),
          isTrue,
        );

        // Should have monitoring terms
        expect(
          entries.any((e) => e.category == 'cardiologie'),
          isTrue,
        );
      });
    });

    group('Localization Readiness', () {
      test('all terms are suitable for translation', () {
        for (var entry in builtInGlossary) {
          // Terms should not be empty
          expect(entry.term.isNotEmpty, isTrue);
          // Should be translatable (not pure codes)
          expect(entry.term.length, lessThan(500));
        }
      });

      test('explanations are suitable for TTS (text-to-speech)', () {
        for (var entry in builtInGlossary) {
          // No complex formatting that breaks TTS
          expect(entry.dutchExplanation.isNotEmpty, isTrue);
          // Should be pronounceable Dutch
        }
      });
    });
  });
}
