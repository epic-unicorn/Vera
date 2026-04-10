/// Domain entity for a single event on the Vera Blueprint timeline.
library timeline_event;

enum TimelinePhase { completed, current, future }

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.dateIso,
    required this.phase,
    required this.fhirResourceType,
    this.iknlGuidelineRef,
    this.actionItems = const [],
    this.fhirStatus,
  });

  final String id;
  final String title;
  final String description;

  /// ISO-8601 date or period start date.
  final String dateIso;

  final TimelinePhase phase;
  final String fhirResourceType;
  final String? iknlGuidelineRef;

  /// Plain-language action items derived from the Decoder.
  final List<String> actionItems;
  final String? fhirStatus;

  static List<TimelineEvent> fromCarePlanActivities(
    List<Map<String, dynamic>> activities,
  ) {
    return activities.map((activity) {
      final detail = activity['detail'] as Map<String, dynamic>? ?? {};
      final code = (detail['code'] as Map<String, dynamic>?)?['text'] as String? ?? '';
      final status = detail['status'] as String? ?? 'unknown';
      final period = detail['scheduledPeriod'] as Map<String, dynamic>?;
      final startDate = period?['start'] as String? ?? '';

      final phase = switch (status) {
        'completed' => TimelinePhase.completed,
        'in-progress' || 'active' => TimelinePhase.current,
        _ => TimelinePhase.future,
      };

      return TimelineEvent(
        id: code.hashCode.toString(),
        title: code.split('–').first.trim(),
        description: (detail['description'] as String?) ?? code,
        dateIso: startDate,
        phase: phase,
        fhirResourceType: detail['kind'] as String? ?? 'ServiceRequest',
        fhirStatus: status,
      );
    }).toList();
  }
}
