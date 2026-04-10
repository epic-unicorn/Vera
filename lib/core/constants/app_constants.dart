/// App-wide constants for Vera.
/// All user-visible copy lives in [StringsNl]; this file holds
/// purely technical / behavioural constants.
library app_constants;

class AppConstants {
  AppConstants._();

  // ── Security ───────────────────────────────────────────────────────────────

  /// Maximum consecutive failed unlock attempts before vault self-destruct.
  static const int maxFailedAuthAttempts = 5;

  /// flutter_secure_storage key under which the AES vault key is stored.
  static const String vaultKeyStorageKey = 'vera_vault_key_v1';

  /// flutter_secure_storage key tracking consecutive failed attempts.
  static const String failedAttemptsKey = 'vera_failed_attempts';

  /// AES-256 key length in bytes.
  static const int aesKeyBytes = 32;

  /// GCM nonce (IV) length in bytes.
  static const int gcmNonceBytes = 12;

  /// GCM authentication tag length in bits.
  static const int gcmTagBits = 128;

  // ── Isar ──────────────────────────────────────────────────────────────────

  /// Isar database name (no extension).
  static const String isarDbName = 'vera_vault';

  // ── WebRTC Sync ────────────────────────────────────────────────────────────

  /// Default STUN server (no medical data passes through STUN).
  static const String stunServer = 'stun:stun.l.google.com:19302';

  /// Signalling WebSocket endpoint.
  /// In production this is a self-hosted, TLS-terminated relay that only
  /// forwards JSON SDP/ICE messages – never medical payload.
  static const String signalingWsUrl =
      'wss://signal.vera-app.nl/v1/session';

  /// QR code version / TTL (seconds). Session expires after this period.
  static const int qrSessionTtlSeconds = 300;

  // ── ML Kit ────────────────────────────────────────────────────────────────

  /// BCP-47 default source language for translation.
  static const String defaultSourceLanguage = 'nl';

  // ── FHIR ──────────────────────────────────────────────────────────────────

  /// Dutch IKNL Richtlijnendatabase base URL (guidelines reference only).
  static const String iknlGuidelinesBaseUrl =
      'https://www.iknl.nl/richtlijnen';

  /// Richtlijnendatabase API (anonymised guide lookups only).
  static const String richtlijnendatabaseApiUrl =
      'https://api.richtlijnendatabase.nl/fhir/r4';

  // ── UI ────────────────────────────────────────────────────────────────────

  /// Minimum touch-target size per WCAG 2.1 SC 2.5.5 (px).
  static const double minTouchTarget = 48.0;

  /// Minimum contrast ratio for normal text (WCAG 2.1 AA).
  static const double wcagAaContrastRatio = 4.5;

  /// Default page padding.
  static const double pagePadding = 20.0;

  // ── BSN Validation ────────────────────────────────────────────────────────

  /// Dutch BSN is 8 or 9 digits; validated via 11-proof.
  static final RegExp bsnPattern = RegExp(r'\b\d{8,9}\b');
}
