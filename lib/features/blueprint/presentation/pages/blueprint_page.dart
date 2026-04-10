import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/strings_nl.dart';
import '../../../../services/mock_data_service.dart';
import '../../../../shared/theme/vera_theme.dart';
import '../widgets/timeline_widget.dart';
import '../../domain/entities/timeline_event.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _carePlanProvider = FutureProvider<List<TimelineEvent>>((ref) async {
  final service = ref.read(mockDataServiceProvider);
  final carePlan = await service.fetchCarePlan();
  final activities = (carePlan.data['activity'] as List<dynamic>? ?? [])
      .cast<Map<String, dynamic>>();
  return TimelineEvent.fromCarePlanActivities(activities);
});

// ── Page ──────────────────────────────────────────────────────────────────────

/// # Blueprint Page (De Tijdlijn)
///
/// Renders the patient's personalised oncology timeline, sourced from an IKNL
/// richtlijn-aligned CarePlan FHIR resource, as a horizontal scrollable
/// interactive roadmap.
class BlueprintPage extends ConsumerWidget {
  const BlueprintPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(_carePlanProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(StringsNl.blueprintTitle,
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(StringsNl.blueprintSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                      )),
                  const SizedBox(height: 4),
                  // IKNL Source chip
                  Semantics(
                    label: 'Bron: IKNL Richtlijnendatabase',
                    child: Chip(
                      avatar: Icon(Icons.verified_outlined,
                          size: 16, color: theme.colorScheme.primary),
                      label: Text(StringsNl.blueprintIknlSource,
                          style: theme.textTheme.labelSmall),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Legend ──────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _Legend(),
            ),
          ),

          // ── Timeline ────────────────────────────────────────────────────────
          SliverFillRemaining(
            hasScrollBody: false,
            child: eventsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator.adaptive()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 12),
                      Text(e.toString(),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              data: (events) => events.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(StringsNl.blueprintNoData,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                      ),
                    )
                  : TimelineWidget(events: events),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
          color: VeraTheme.statusColor('completed'),
          label: StringsNl.blueprintPhaseCompleted,
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: VeraTheme.statusColor('in-progress'),
          label: StringsNl.blueprintPhaseCurrent,
        ),
        const SizedBox(width: 16),
        _LegendItem(
          color: VeraTheme.statusColor('scheduled'),
          label: StringsNl.blueprintPhaseFuture,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
