import 'dart:convert';

/// Pure domain entity – no Isar or Flutter dependencies.
/// Represents a single encrypted medical record in the Vera vault.
class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.resourceType,
    required this.title,
    required this.dateRecorded,
    required this.anonymisedPayloadJson,
    this.iknlGuidelineRef,
    this.fhirStatus,
    this.tags = const [],
  });

  /// Internal UUID string (matches Isar long id via hash).
  final String id;

  /// FHIR R4 ResourceType string, e.g. "Condition", "Procedure".
  final String resourceType;

  /// Human-readable title (Dutch, already decoded/translated).
  final String title;

  /// ISO-8601 date string when this record was recorded/imported.
  final String dateRecorded;

  /// Anonymised JSON payload – PII has been stripped by IdentityShieldService
  /// before this entity is created. Stored encrypted in the vault.
  final String anonymisedPayloadJson;

  /// Optional reference to an IKNL guideline URL.
  final String? iknlGuidelineRef;

  /// FHIR status string, e.g. "active", "completed", "entered-in-error".
  final String? fhirStatus;

  /// Free-form tags for filtering/search.
  final List<String> tags;

  Map<String, dynamic> toJson() => {
        'id': id,
        'resourceType': resourceType,
        'title': title,
        'dateRecorded': dateRecorded,
        'anonymisedPayloadJson': anonymisedPayloadJson,
        'iknlGuidelineRef': iknlGuidelineRef,
        'fhirStatus': fhirStatus,
        'tags': tags,
      };

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => MedicalRecord(
        id: json['id'] as String,
        resourceType: json['resourceType'] as String,
        title: json['title'] as String,
        dateRecorded: json['dateRecorded'] as String,
        anonymisedPayloadJson: json['anonymisedPayloadJson'] as String,
        iknlGuidelineRef: json['iknlGuidelineRef'] as String?,
        fhirStatus: json['fhirStatus'] as String?,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  String toJsonString() => jsonEncode(toJson());

  factory MedicalRecord.fromJsonString(String s) =>
      MedicalRecord.fromJson(jsonDecode(s) as Map<String, dynamic>);

  MedicalRecord copyWith({
    String? id,
    String? resourceType,
    String? title,
    String? dateRecorded,
    String? anonymisedPayloadJson,
    String? iknlGuidelineRef,
    String? fhirStatus,
    List<String>? tags,
  }) =>
      MedicalRecord(
        id: id ?? this.id,
        resourceType: resourceType ?? this.resourceType,
        title: title ?? this.title,
        dateRecorded: dateRecorded ?? this.dateRecorded,
        anonymisedPayloadJson:
            anonymisedPayloadJson ?? this.anonymisedPayloadJson,
        iknlGuidelineRef: iknlGuidelineRef ?? this.iknlGuidelineRef,
        fhirStatus: fhirStatus ?? this.fhirStatus,
        tags: tags ?? this.tags,
      );
}
