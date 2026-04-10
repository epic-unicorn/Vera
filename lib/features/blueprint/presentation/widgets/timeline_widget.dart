import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/vera_theme.dart';
import '../../domain/entities/timeline_event.dart';

/// Horizontal, interactive timeline mapping the patient's oncology journey.
/// Each node is a tappable card that expands on press to show details and
/// IKNL guideline references.
class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key, required this.events});

  final List<TimelineEvent> events;

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    // Auto-expand the current phase node
    _expandedId = widget.events
        .where((e) => e.phase == TimelinePhase.current)
        .firstOrNull
        ?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Horizontal scroll strip ──────────────────────────────────────────
        SizedBox(
          height: 120,
          child: ScrollConfiguration(
            behavior: _NoBounceScrollBehavior(),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: widget.events.length,
              itemBuilder: (context, index) {
                final event = widget.events[index];
                final isLast = index == widget.events.length - 1;
                return _TimelineNode(
                  event: event,
                  isLast: isLast,
                  isExpanded: _expandedId == event.id,
                  onTap: () => setState(() {
                    _expandedId = _expandedId == event.id ? null : event.id;
                  }),
                );
              },
            ),
          ),
        ),

        // ── Detail panel ─────────────────────────────────────────────────────
        if (_expandedId != null)
          _EventDetailPanel(
            event: widget.events.firstWhere((e) => e.id == _expandedId),
          ),
      ],
    );
  }
}

// ── Timeline node ─────────────────────────────────────────────────────────────

class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.event,
    required this.isLast,
    required this.isExpanded,
    required this.onTap,
  });

  final TimelineEvent event;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onTap;

  Color get _phaseColor => switch (event.phase) {
        TimelinePhase.completed => VeraTheme.statusColor('completed'),
        TimelinePhase.current => VeraTheme.statusColor('in-progress'),
        TimelinePhase.future => VeraTheme.statusColor('scheduled'),
      };

  String get _phaseLabel => switch (event.phase) {
        TimelinePhase.completed => 'Afgerond',
        TimelinePhase.current => 'Huidig',
        TimelinePhase.future => 'Gepland',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: '${event.title}. Status: $_phaseLabel. '
          'Tik voor details.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: 200.ms,
              width: 140,
              height: 100,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: isExpanded ? _phaseColor : _phaseColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _phaseColor,
                  width: isExpanded ? 2 : 1.5,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _phaseColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _phaseLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isExpanded ? Colors.white : _phaseColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isExpanded
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2),

          // ── Connector line ─────────────────────────────────────────────────
          if (!isLast)
            SizedBox(
              width: 24,
              height: 2,
              child: Container(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Detail panel ──────────────────────────────────────────────────────────────

class _EventDetailPanel extends StatelessWidget {
  const _EventDetailPanel({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted = _formatDate(event.dateIso);

    return AnimatedSize(
      duration: 300.ms,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child:
                          Text(event.title, style: theme.textTheme.titleMedium),
                    ),
                    if (event.fhirStatus != null)
                      _StatusBadge(status: event.fhirStatus!),
                  ],
                ),
                if (dateFormatted.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Gepland: $dateFormatted',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const Divider(height: 24),
                // Description
                Text(event.description, style: theme.textTheme.bodyMedium),

                // IKNL guideline link
                if (event.iknlGuidelineRef != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    link: true,
                    label: 'IKNL richtlijn raadplegen',
                    child: TextButton.icon(
                      onPressed: () {/* open URL in browser */},
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('IKNL Richtlijn raadplegen'),
                    ),
                  ),
                ],

                // Action items
                if (event.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Actiepunten:', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  ...event.actionItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(item, style: theme.textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.05),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('d MMMM yyyy', 'nl_NL').format(date);
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = VeraTheme.statusColor(status);
    final label = switch (status) {
      'completed' => 'Voltooid',
      'in-progress' => 'Actief',
      'scheduled' => 'Gepland',
      'active' => 'Actief',
      _ => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Scroll behaviour ─────────────────────────────────────────────────────────

class _NoBounceScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
