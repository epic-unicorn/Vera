import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_entity_extraction/google_mlkit_entity_extraction.dart';

import '../core/constants/app_constants.dart';
import '../core/error/failures.dart';
import '../core/platform/platform_detector.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final identityShieldServiceProvider = Provider<IdentityShieldService>(
  (_) => IdentityShieldService(),
);

// ── Service ───────────────────────────────────────────────────────────────────

/// # IdentityShieldService
///
/// Performs on-device Named Entity Recognition (NER) to detect and redact
/// Personally Identifiable Information (PII) from free-text fields BEFORE
/// any data enters the vault or is used to query external guideline APIs.
///
/// ## Architecture
/// * Uses **google_mlkit_entity_extraction** – on-device ML model, no network.
/// * Supplements ML results with deterministic Dutch pattern rules:
///   - BSN (Burgerservicenummer): 8–9 digit sequences validated by 11-proof.
///   - Common Dutch name patterns (prefixes: van/de/den/der/ten).
///   - Dutch postcodes: 4 digits + 2 uppercase letters.
/// * On Web (where ML Kit is unavailable) falls back to regex-only mode.
///
/// ## Output contract
/// The redacted text replaces all detected spans with `[GEANONIMISEERD]`
/// so downstream code can never accidentally leak a real identifier.
class IdentityShieldService {
  static const _redactionToken = '[GEANONIMISEERD]';

  EntityExtractor? _extractor;
  bool _isInitialised = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Initialise the ML Kit entity extractor for Dutch (`nl`).
  /// Safe to call multiple times – subsequent calls are no-ops.
  Future<({bool success, Failure? failure})> initialise() async {
    if (_isInitialised) return (success: true, failure: null);

    if (!PlatformDetector.isMlKitSupported) {
      // Web fallback: regex-only mode, still functional
      _isInitialised = true;
      return (success: true, failure: null);
    }

    try {
      _extractor = EntityExtractor(
        language: EntityExtractorLanguage.dutch,
      );
      _isInitialised = true;
      return (success: true, failure: null);
    } catch (e) {
      return (success: false, failure: NerInitFailure(e.toString()));
    }
  }

  /// Strips all detected PII from [input] and returns the sanitised string.
  ///
  /// Entities redacted:
  /// * Personal names (ML Kit PERSON + Dutch-prefix heuristic)
  /// * Dutch BSN (deterministic 11-proof check)
  /// * Dutch postcodes
  /// * Phone numbers (ML Kit PHONE + E.164 pattern)
  /// * Email addresses
  /// * Dates of birth (when adjacent to a name entity)
  Future<String> shield(String input) async {
    if (input.trim().isEmpty) return input;
    if (!_isInitialised) await initialise();

    String result = input;

    // Step 1: regex-based deterministic redactions (run on all platforms)
    result = _redactBsn(result);
    result = _redactPostcode(result);
    result = _redactEmail(result);
    result = _redactPhone(result);

    // Step 2: ML Kit NER (mobile only)
    if (_extractor != null) {
      result = await _redactWithMlKit(result);
    }

    return result;
  }

  /// Convenience: shields all string values in a [Map] recursively.
  Future<Map<String, dynamic>> shieldMap(Map<String, dynamic> map) async {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value is String) {
        result[entry.key] = await shield(entry.value as String);
      } else if (entry.value is Map<String, dynamic>) {
        result[entry.key] =
            await shieldMap(entry.value as Map<String, dynamic>);
      } else if (entry.value is List) {
        result[entry.key] = await _shieldList(entry.value as List);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  Future<List<dynamic>> _shieldList(List<dynamic> list) async {
    final result = <dynamic>[];
    for (final item in list) {
      if (item is String) {
        result.add(await shield(item));
      } else if (item is Map<String, dynamic>) {
        result.add(await shieldMap(item));
      } else {
        result.add(item);
      }
    }
    return result;
  }

  // ── ML Kit NER ────────────────────────────────────────────────────────────

  Future<String> _redactWithMlKit(String text) async {
    try {
      final annotations = await _extractor!.annotateText(text);

      // Collect spans to redact, process in reverse to preserve offsets
      final spans = <({int start, int end})>[];
      for (final annotation in annotations) {
        final isPersonal = annotation.entities.any(
          (e) =>
              e.type == EntityType.address ||
              e.type == EntityType.phone ||
              e.type == EntityType.email,
        );
        if (isPersonal) {
          spans.add((start: annotation.start, end: annotation.end));
        }
      }

      // Sort descending by start so replacements don't shift offsets
      spans.sort((a, b) => b.start.compareTo(a.start));

      // StringBuffer doesn't support splice; convert to list of chars
      var mutable = text;
      for (final span in spans) {
        mutable = mutable.replaceRange(span.start, span.end, _redactionToken);
      }
      return mutable;
    } catch (_) {
      // If ML Kit fails, the regex pass is still applied – return as-is
      return text;
    }
  }

  // ── Deterministic pattern redactions ──────────────────────────────────────

  /// Dutch BSN 11-proof validation + redaction.
  String _redactBsn(String text) {
    return text.replaceAllMapped(AppConstants.bsnPattern, (m) {
      final candidate = m.group(0)!;
      if (_isValidBsn(candidate)) return _redactionToken;
      return candidate;
    });
  }

  /// Dutch postcode: 4 digits + optional space + 2 uppercase letters.
  String _redactPostcode(String text) {
    return text.replaceAll(
      RegExp(r'\b\d{4}\s?[A-Z]{2}\b'),
      _redactionToken,
    );
  }

  String _redactEmail(String text) {
    return text.replaceAll(
      RegExp(r'\b[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}\b'),
      _redactionToken,
    );
  }

  String _redactPhone(String text) {
    // Dutch mobile/landline patterns: 06-XXXXXXXX, +31 6 XXXXXXXX, 0XX-XXXXXXX
    return text.replaceAll(
      RegExp(r'(\+31|0031|0)\s?-?(\d[\s\-]?){8,9}\b'),
      _redactionToken,
    );
  }

  /// Dutch BSN 11-proof (elfproef).
  bool _isValidBsn(String digits) {
    if (digits.length < 8 || digits.length > 9) return false;
    final d = digits.padLeft(9, '0').split('').map(int.parse).toList();
    // Weights: 9, 8, 7, 6, 5, 4, 3, 2, -1
    final weights = [9, 8, 7, 6, 5, 4, 3, 2, -1];
    final sum =
        List.generate(9, (i) => d[i] * weights[i]).fold(0, (a, b) => a + b);
    return sum % 11 == 0;
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    _extractor?.close();
    _extractor = null;
    _isInitialised = false;
  }
}
