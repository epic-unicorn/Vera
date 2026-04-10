/// Typed failure hierarchy for Vera.
/// Using a sealed class hierarchy keeps error-handling exhaustive.
library failures;

sealed class Failure {
  const Failure(this.message);
  final String message;
}

// ── Vault failures ─────────────────────────────────────────────────────────

final class VaultLockedFailure extends Failure {
  const VaultLockedFailure() : super('Kluis is vergrendeld.');
}

final class VaultKeyNotFoundFailure extends Failure {
  const VaultKeyNotFoundFailure()
      : super('Kluis-sleutel niet gevonden. Maak een nieuwe kluis aan.');
}

final class VaultEncryptionFailure extends Failure {
  const VaultEncryptionFailure(super.message);
}

final class VaultSelfDestructFailure extends Failure {
  const VaultSelfDestructFailure()
      : super('Kluis gewist na te veel mislukte pogingen.');
}

final class VaultNotSupportedFailure extends Failure {
  const VaultNotSupportedFailure()
      : super('Lokale kluis is niet beschikbaar op dit platform.');
}

// ── Auth failures ─────────────────────────────────────────────────────────

final class AuthBiometricFailure extends Failure {
  const AuthBiometricFailure(super.message);
}

final class AuthPinFailure extends Failure {
  const AuthPinFailure(super.message);
}

final class AuthMaxAttemptsFailure extends Failure {
  const AuthMaxAttemptsFailure()
      : super('Maximum aantal pogingen bereikt. Kluis wordt gewist.');
}

// ── Translation failures ───────────────────────────────────────────────────

final class TranslationModelNotDownloadedFailure extends Failure {
  const TranslationModelNotDownloadedFailure(super.message);
}

final class TranslationFailure extends Failure {
  const TranslationFailure(super.message);
}

// ── NER / PII failures ────────────────────────────────────────────────────

final class NerInitFailure extends Failure {
  const NerInitFailure(super.message);
}

// ── Sync failures ─────────────────────────────────────────────────────────

final class SyncConnectionFailure extends Failure {
  const SyncConnectionFailure(super.message);
}

final class SyncSessionExpiredFailure extends Failure {
  const SyncSessionExpiredFailure() : super('Sync-sessie verlopen.');
}

// ── FHIR / Data failures ──────────────────────────────────────────────────

final class FhirParseFailure extends Failure {
  const FhirParseFailure(super.message);
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
