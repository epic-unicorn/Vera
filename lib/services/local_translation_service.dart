import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../core/constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/platform/platform_detector.dart';
import 'identity_shield_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final localTranslationServiceProvider = Provider<LocalTranslationService>((ref) {
  return LocalTranslationService(
    shieldService: ref.watch(identityShieldServiceProvider),
  );
});

// ── Supported languages ───────────────────────────────────────────────────────

/// Languages available for on-device translation.
/// Each entry is: (bcp47 code, display name in Dutch).
const List<({String code, String label})> supportedTranslationLanguages = [
  (code: 'nl', label: 'Nederlands'),
  (code: 'en', label: 'Engels'),
  (code: 'de', label: 'Duits'),
  (code: 'fr', label: 'Frans'),
  (code: 'ar', label: 'Arabisch'),
  (code: 'tr', label: 'Turks'),
  (code: 'pl', label: 'Pools'),
  (code: 'es', label: 'Spaans'),
  (code: 'pt', label: 'Portugees'),
  (code: 'ru', label: 'Russisch'),
  (code: 'zh', label: 'Chinees (vereenvoudigd)'),
];

// ── Translation cache entry ───────────────────────────────────────────────────

class _CacheEntry {
  _CacheEntry({required this.translation, required this.timestamp});
  final String translation;
  final DateTime timestamp;
  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

// ── Service ───────────────────────────────────────────────────────────────────

/// # LocalTranslationService
///
/// Provides on-device, privacy-safe translation of medical jargon into any
/// of the [supportedTranslationLanguages].
///
/// ## Privacy contract
/// 1. **No network calls for medical text** – uses ML Kit on-device models
///    exclusively. The only permitted network access is downloading the
///    translation model binary itself (a one-time operation per language).
/// 2. **PII pre-screening** – before passing any text to the ML Kit engine,
///    [IdentityShieldService.shield] is applied to strip personal identifiers.
///    This ensures even the on-device model never operates on raw PII.
/// 3. **Web fallback** – on web, ML Kit is unavailable. A safe stub is
///    returned prompting the user to use the mobile app for translation,
///    ensuring the Zero-Knowledge guarantee is never broken by a silent
///    fallback to a remote API.
///
/// ## Usage
/// ```dart
/// final result = await translationService.translate(
///   text: 'HER2-positief invasief ductaal carcinoom',
///   targetLanguage: 'en',
/// );
/// ```
class LocalTranslationService {
  LocalTranslationService({required this.shieldService});

  final IdentityShieldService shieldService;

  // Active translator instances keyed by target language code
  final Map<String, OnDeviceTranslator> _translators = {};

  // Model manager for download status queries
  final _modelManager = OnDeviceTranslatorModelManager();

  // In-memory LRU-ish translation cache to avoid re-translating same text
  final Map<String, _CacheEntry> _cache = {};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Translates [text] from Dutch to [targetLanguage].
  ///
  /// Returns a [TranslationResult] sealed type. Always call
  /// [TranslationFailure] handler in the caller to prevent silent degradation.
  Future<({String? text, Failure? failure})> translate({
    required String text,
    required String targetLanguage,
    String sourceLanguage = AppConstants.defaultSourceLanguage,
  }) async {
    if (text.trim().isEmpty) return (text: text, failure: null);

    // Early return: source == target, no translation needed
    if (sourceLanguage == targetLanguage) return (text: text, failure: null);

    // Web: return a clear failure – never silently call a remote API
    if (!PlatformDetector.isMlKitSupported) {
      return (
        text: null,
        failure: const TranslationFailure(
          'Op-apparaat vertaling is alleen beschikbaar op de mobiele app. '
          'Gebruik de Vera mobiele app om te vertalen zonder gegevenslek.',
        ),
      );
    }

    // Check translation cache
    final cacheKey = '$sourceLanguage:$targetLanguage:${text.hashCode}';
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return (text: cached.translation, failure: null);
    }

    // Verify model is downloaded
    final isDownloaded = await isModelDownloaded(targetLanguage);
    if (!isDownloaded) {
      return (
        text: null,
        failure: TranslationModelNotDownloadedFailure(
          'Taalmodel voor "$targetLanguage" niet gedownload. '
          'Gebruik downloadModel() om het model op te halen.',
        ),
      );
    }

    try {
      // PII shield BEFORE handing text to any processing engine
      final shieldedText = await shieldService.shield(text);

      final translator = _getOrCreateTranslator(sourceLanguage, targetLanguage);
      final translated = await translator.translateText(shieldedText);

      // Cache result
      _cache[cacheKey] = _CacheEntry(
        translation: translated,
        timestamp: DateTime.now(),
      );

      // Evict old cache entries if cache grows large
      if (_cache.length > 200) {
        final oldKeys = _cache.entries
            .where((e) => e.value.isExpired)
            .map((e) => e.key)
            .toList();
        for (final k in oldKeys) {
          _cache.remove(k);
        }
      }

      return (text: translated, failure: null);
    } catch (e) {
      return (text: null, failure: TranslationFailure(e.toString()));
    }
  }

  /// Checks whether the on-device model for [languageCode] is downloaded.
  Future<bool> isModelDownloaded(String languageCode) async {
    if (!PlatformDetector.isMlKitSupported) return false;
    try {
      return await _modelManager.isModelDownloaded(languageCode);
    } catch (_) {
      return false;
    }
  }

  /// Initiates model download for [targetLanguage].
  ///
  /// Returns a stream of download progress (0.0 – 1.0).
  /// The actual ML Kit download is atomic – this wrapper polls until done.
  Stream<double> downloadModel(
    String targetLanguage, {
    String sourceLanguage = AppConstants.defaultSourceLanguage,
  }) async* {
    if (!PlatformDetector.isMlKitSupported) return;

    yield 0.0;
    try {
      await _modelManager.downloadModel(targetLanguage);
      yield 1.0;
    } catch (e) {
      // Re-yield 0 on failure so UI can show error state
      yield 0.0;
    }
  }

  /// Deletes a downloaded model to free storage.
  Future<void> deleteModel(String languageCode) async {
    if (!PlatformDetector.isMlKitSupported) return;
    await _modelManager.deleteModel(languageCode);
    _translators[languageCode]?.close();
    _translators.remove(languageCode);
  }

  // ── Batch translation ──────────────────────────────────────────────────────

  /// Convenience: translates a list of [ActionItem] strings in one call.
  Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String sourceLanguage = AppConstants.defaultSourceLanguage,
  }) async {
    final results = <String>[];
    for (final text in texts) {
      final r = await translate(
        text: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );
      results.add(r.text ?? text); // fallback to original on failure
    }
    return results;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  OnDeviceTranslator _getOrCreateTranslator(
      String source, String target) {
    final key = '$source→$target';
    return _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.values.firstWhere(
          (l) => l.bcpCode == source,
          orElse: () => TranslateLanguage.dutch,
        ),
        targetLanguage: TranslateLanguage.values.firstWhere(
          (l) => l.bcpCode == target,
          orElse: () => TranslateLanguage.english,
        ),
      ),
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
    _cache.clear();
  }
}
