import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/error/failures.dart';
import 'package:vera/services/identity_shield_service.dart';
import 'package:vera/services/local_translation_service.dart';

void main() {
  group('LocalTranslationService', () {
    late LocalTranslationService translationService;

    setUp(() {
      // IdentityShieldService has no-arg constructor; on non-mobile it
      // skips ML Kit and runs regex-only. Safe to use directly in tests.
      translationService = LocalTranslationService(
        shieldService: IdentityShieldService(),
      );
    });

    tearDown(() => translationService.dispose());

    // ── Platform guard (non-mobile / test env) ───────────────────────────────

    group('Platform Guard (non-mobile)', () {
      test('translate returns TranslationFailure on non-mobile', () async {
        final result = await translationService.translate(
          text: 'invasief ductaal carcinoom',
          targetLanguage: 'en',
        );

        // On non-mobile (test env) ML Kit is unavailable → typed failure
        expect(result.failure, isA<TranslationFailure>());
        expect(result.text, isNull);
      });

      test('empty text bypasses platform check and returns empty', () async {
        final result = await translationService.translate(
          text: '',
          targetLanguage: 'en',
        );

        // Empty strings are returned immediately without platform check
        expect(result.failure, isNull);
        expect(result.text, equals(''));
      });

      test('source == target returns original text without translation',
          () async {
        const text = 'kanker';
        final result = await translationService.translate(
          text: text,
          targetLanguage: 'nl',
          sourceLanguage: 'nl',
        );

        expect(result.failure, isNull);
        expect(result.text, equals(text));
      });

      test('isModelDownloaded returns false on non-mobile', () async {
        final downloaded = await translationService.isModelDownloaded('en');
        expect(downloaded, isFalse);
      });

      test('downloadModel emits nothing on non-mobile', () async {
        final events = await translationService
            .downloadModel('en')
            .toList();
        expect(events, isEmpty);
      });

      test('deleteModel completes without error on non-mobile', () async {
        await expectLater(
          translationService.deleteModel('en'),
          completes,
        );
      });
    });

    // ── translateBatch ────────────────────────────────────────────────────────

    group('translateBatch', () {
      test('returns list with same length as input', () async {
        final texts = [
          'Radiotherapie',
          'Chemotherapie',
          'Immunotherapie',
        ];

        final results = await translationService.translateBatch(
          texts: texts,
          targetLanguage: 'en',
        );

        expect(results, hasLength(texts.length));
      });

      test('falls back to original text on translation failure', () async {
        // On non-mobile the translate() call fails, so translateBatch
        // falls back to the original text per its contract.
        final texts = ['Chirurgie', 'Bestraling'];

        final results = await translationService.translateBatch(
          texts: texts,
          targetLanguage: 'en',
        );

        // On non-mobile, originals are returned as fallback
        expect(results, equals(texts));
      });
    });

    // ── supportedTranslationLanguages constant ────────────────────────────────

    group('Supported Languages', () {
      test('supportedTranslationLanguages contains expected BCP47 codes', () {
        final codes = supportedTranslationLanguages.map((l) => l.code).toSet();

        expect(codes, containsAll(['nl', 'en', 'de', 'fr', 'ar', 'tr']));
        expect(codes, containsAll(['es', 'pt', 'ru', 'zh', 'pl']));
      });

      test('supportedTranslationLanguages has matching labels', () {
        for (final lang in supportedTranslationLanguages) {
          expect(lang.code, isNotEmpty);
          expect(lang.label, isNotEmpty);
        }
      });

      test('Dutch (nl) is included as source language', () {
        final codes = supportedTranslationLanguages.map((l) => l.code);
        expect(codes, contains('nl'));
      });
    });

    // ── Failure type contracts ─────────────────────────────────────────────────

    group('Failure Type Contracts', () {
      test('TranslationFailure carries supplied message', () {
        const msg = 'Vertaling niet beschikbaar';
        const failure = TranslationFailure(msg);
        expect(failure.message, equals(msg));
      });

      test('TranslationModelNotDownloadedFailure carries supplied message', () {
        const msg = 'Model niet gedownload';
        const failure = TranslationModelNotDownloadedFailure(msg);
        expect(failure.message, equals(msg));
      });
    });
  });
}
