// ignore_for_file: invalid_annotation_target
import 'package:isar/isar.dart';

// IMPORTANT: After adding or changing this file run:
//   flutter pub run build_runner build --delete-conflicting-outputs
// This generates medical_record_model.g.dart (IsarCollection schema + adapter).

part 'medical_record_model.g.dart';

/// Isar-persisted model for a single encrypted vault record.
/// All sensitive fields are stored as AES-256-GCM ciphertext blobs
/// produced by [LocalVaultService]. Isar itself is NOT the encryption
/// boundary – it is an append-only local store. Encryption happens BEFORE
/// objects reach this layer.
@collection
class MedicalRecordModel {
  /// Isar auto-incremented integer primary key.
  Id id = Isar.autoIncrement;

  /// Application-level UUID (stable across migrations).
  @Index(unique: true)
  late String uuid;

  /// AES-256-GCM encrypted JSON blob of the anonymised FHIR payload.
  /// Format: base64(nonce || ciphertext || tag)
  late String encryptedPayload;

  /// FHIR ResourceType – NOT encrypted (used for index/filter).
  @Index()
  late String resourceType;

  /// ISO-8601 date – NOT encrypted (timeline ordering).
  @Index()
  late String dateRecorded;

  /// Short Dutch title – encrypted to prevent metadata leakage.
  late String encryptedTitle;

  /// Optional IKNL guideline reference URL – NOT encrypted.
  String? iknlGuidelineRef;

  /// FHIR status code – NOT encrypted.
  String? fhirStatus;

  /// Tags for filtering – stored as joined string (not encrypted).
  late String tagsCsv;
}

/// Isar-persisted model for an appointment in the navigator.
@collection
class AppointmentModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  /// Encrypted appointment title.
  late String encryptedTitle;

  /// Encrypted location / department.
  late String encryptedLocation;

  /// ISO-8601 datetime – NOT encrypted (calendar ordering).
  @Index()
  late String dateTimeIso;

  /// Encrypted voice-logged symptom notes.
  String? encryptedSymptomNotes;

  /// Encrypted pocket-guide markdown.
  String? encryptedPocketGuide;

  @Index()
  late bool isCompleted;
}
