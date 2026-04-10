import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/constants/strings_nl.dart';
import '../../../../core/platform/platform_detector.dart';
import '../../../../services/mock_data_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class _AppointmentState {
  const _AppointmentState({
    this.appointments = const [],
    this.isLoading = true,
    this.symptomNotes = '',
    this.isListening = false,
    this.pocketGuide,
    this.selectedAppointmentId,
  });

  final List<FhirResource> appointments;
  final bool isLoading;
  final String symptomNotes;
  final bool isListening;
  final String? pocketGuide;
  final String? selectedAppointmentId;

  _AppointmentState copyWith({
    List<FhirResource>? appointments,
    bool? isLoading,
    String? symptomNotes,
    bool? isListening,
    String? pocketGuide,
    String? selectedAppointmentId,
  }) =>
      _AppointmentState(
        appointments: appointments ?? this.appointments,
        isLoading: isLoading ?? this.isLoading,
        symptomNotes: symptomNotes ?? this.symptomNotes,
        isListening: isListening ?? this.isListening,
        pocketGuide: pocketGuide ?? this.pocketGuide,
        selectedAppointmentId:
            selectedAppointmentId ?? this.selectedAppointmentId,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class _AppointmentNotifier extends StateNotifier<_AppointmentState> {
  _AppointmentNotifier(this._mockService) : super(const _AppointmentState()) {
    _loadAppointments();
  }

  final MockDataService _mockService;
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();

  Future<void> _loadAppointments() async {
    final appointments = await _mockService.fetchAppointments();
    state = state.copyWith(appointments: appointments, isLoading: false);
  }

  void selectAppointment(String id) {
    state = state.copyWith(selectedAppointmentId: id, pocketGuide: null);
  }

  Future<void> generatePocketGuide(FhirResource appointment) async {
    final data = appointment.data;
    final serviceType =
        ((data['serviceType'] as List?)?.firstOrNull as Map?)?['text'] ?? '';
    final reasonCode =
        ((data['reasonCode'] as List?)?.firstOrNull as Map?)?['text'] ?? '';
    final location = (data['location'] as Map?)?['display'] ?? '';
    final comment = data['comment'] as String? ?? '';
    final start = data['start'] as String? ?? '';

    final dateStr = start.isNotEmpty
        ? DateFormat('d MMMM yyyy – HH:mm', 'nl_NL')
            .format(DateTime.parse(start))
        : '';

    final guide = '''
# Pocket Gids voor uw afspraak
**Datum:** $dateStr  
**Type:** $serviceType  
**Locatie:** $location

## Reden van bezoek
$reasonCode

## Uw ingesproken symptomen
${state.symptomNotes.isEmpty ? '(geen symptomen geregistreerd – gebruik de spraakfunctie)' : state.symptomNotes}

## Aanbevolen vragen voor uw arts
* Wat zijn de resultaten van mijn laatste LVEF-meting?
* Zijn er bijwerkingen die ik moet melden?
* Wanneer verwacht u de volgende behandelstap?
* Wat kan ik zelf doen om mijn herstel te bevorderen?
* Zijn er richtlijnwijzigingen die invloed hebben op mijn zorgplan?

## Memo / notities
$comment

---
*Gegenereerd door Vera – IKNL Richtlijn Borstkanker 2023*
''';

    state = state.copyWith(pocketGuide: guide);
  }

  Future<void> toggleVoiceLogging() async {
    if (!PlatformDetector.isSpeechSupported) return;

    if (state.isListening) {
      _speech.stop();
      state = state.copyWith(isListening: false);
      return;
    }

    final available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          state = state.copyWith(isListening: false);
        }
      },
      onError: (_) => state = state.copyWith(isListening: false),
    );

    if (!available) return;

    state = state.copyWith(isListening: true);
    _speech.listen(
      localeId: 'nl_NL',
      onResult: (result) {
        if (result.finalResult) {
          state = state.copyWith(
            symptomNotes:
                '${state.symptomNotes}\n${result.recognizedWords}'.trim(),
            isListening: false,
          );
        }
      },
    );
  }

  Future<void> readAloud(String text) async {
    await _tts.setLanguage('nl-NL');
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  void clearSymptomNotes() => state = state.copyWith(symptomNotes: '');

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

final _appointmentProvider =
    StateNotifierProvider<_AppointmentNotifier, _AppointmentState>((ref) {
  return _AppointmentNotifier(ref.watch(mockDataServiceProvider));
});

// ── Page ──────────────────────────────────────────────────────────────────────

class AppointmentNavigatorPage extends ConsumerWidget {
  const AppointmentNavigatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_appointmentProvider);
    final notifier = ref.read(_appointmentProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : CustomScrollView(
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(StringsNl.appointmentsTitle,
                            style: theme.textTheme.headlineMedium),
                        const SizedBox(height: 6),
                        Text(StringsNl.appointmentsSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.65),
                            )),
                      ],
                    ),
                  ),
                ),

                // ── Appointments list ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.builder(
                    itemCount: state.appointments.length,
                    itemBuilder: (context, index) {
                      final appt = state.appointments[index];
                      final isSelected = state.selectedAppointmentId == appt.id;
                      return _AppointmentCard(
                        appointment: appt,
                        isSelected: isSelected,
                        onTap: () => notifier.selectAppointment(appt.id),
                        onGenerateGuide: () =>
                            notifier.generatePocketGuide(appt),
                      ).animate().fadeIn(
                            delay: Duration(milliseconds: index * 80),
                            duration: 300.ms,
                          );
                    },
                  ),
                ),

                // ── Voice symptom logger ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _SymptomLogger(
                    notes: state.symptomNotes,
                    isListening: state.isListening,
                    onToggle: notifier.toggleVoiceLogging,
                    onClear: notifier.clearSymptomNotes,
                  ),
                ),

                // ── Pocket guide ────────────────────────────────────────────
                if (state.pocketGuide != null)
                  SliverToBoxAdapter(
                    child: _PocketGuidePanel(
                      markdown: state.pocketGuide!,
                      onReadAloud: () => notifier.readAloud(state.pocketGuide!),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
    );
  }
}

// ── Appointment card ──────────────────────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.isSelected,
    required this.onTap,
    required this.onGenerateGuide,
  });

  final FhirResource appointment;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onGenerateGuide;

  @override
  Widget build(BuildContext context) {
    final data = appointment.data;
    final theme = Theme.of(context);
    final serviceType =
        ((data['serviceType'] as List?)?.firstOrNull as Map?)?['text'] ??
            'Afspraak';
    final start = data['start'] as String?;
    final location = (data['location'] as Map?)?['display'] ?? '';
    final practitioner = ((data['participant'] as List?)?.firstOrNull
            as Map?)?['actor']?['display'] ??
        '';

    String dateStr = '';
    String timeStr = '';
    if (start != null) {
      final dt = DateTime.parse(start);
      dateStr = DateFormat('EEEE d MMMM yyyy', 'nl_NL').format(dt);
      timeStr = DateFormat('HH:mm', 'nl_NL').format(dt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_month,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(serviceType, style: theme.textTheme.titleSmall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (dateStr.isNotEmpty)
                Text('$dateStr om $timeStr',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    )),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(location,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    )),
              ],
              if (practitioner.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(practitioner,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    )),
              ],
              if (isSelected) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onGenerateGuide,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text(StringsNl.appointmentsPocketGuide),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Voice symptom logger ──────────────────────────────────────────────────────

class _SymptomLogger extends StatelessWidget {
  const _SymptomLogger({
    required this.notes,
    required this.isListening,
    required this.onToggle,
    required this.onClear,
  });

  final String notes;
  final bool isListening;
  final VoidCallback onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Text('Symptomen registreren', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (PlatformDetector.isSpeechSupported) ...[
            ElevatedButton.icon(
              onPressed: onToggle,
              icon: Icon(isListening ? Icons.stop : Icons.mic_none),
              label: Text(isListening
                  ? StringsNl.appointmentsVoiceStop
                  : StringsNl.appointmentsVoiceLog),
              style: ElevatedButton.styleFrom(
                backgroundColor: isListening ? const Color(0xFFC62828) : null,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            if (isListening)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.fiber_manual_record,
                            size: 14, color: Color(0xFFC62828))
                        .animate(onPlay: (c) => c.repeat())
                        .fadeIn(duration: 600.ms)
                        .then()
                        .fadeOut(duration: 600.ms),
                    const SizedBox(width: 8),
                    Text(StringsNl.appointmentsVoiceListening,
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ] else
            Text('Spraakregistratie is niet beschikbaar op dit platform.',
                style: theme.textTheme.bodySmall),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Geregistreerde symptomen:',
                          style: theme.textTheme.labelSmall),
                      const Spacer(),
                      TextButton(
                        onPressed: onClear,
                        style: TextButton.styleFrom(
                            minimumSize: const Size(48, 32)),
                        child: const Text('Wissen'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notes, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Pocket guide panel ────────────────────────────────────────────────────────

class _PocketGuidePanel extends StatelessWidget {
  const _PocketGuidePanel({
    required this.markdown,
    required this.onReadAloud,
  });

  final String markdown;
  final VoidCallback onReadAloud;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Render the markdown as plain paragraphs for simplicity.
    // Production: use `flutter_markdown` package.
    final lines = markdown.split('\n');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, size: 20),
              const SizedBox(width: 8),
              Text('Uw Pocket Gids', style: theme.textTheme.titleMedium),
              const Spacer(),
              Semantics(
                button: true,
                label: 'Pocket Gids voorlezen',
                child: IconButton(
                  icon: const Icon(Icons.volume_up_outlined),
                  tooltip: 'Voorlezen',
                  onPressed: onReadAloud,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        line,
                        style: line.startsWith('#')
                            ? theme.textTheme.titleSmall
                            : line.startsWith('**')
                                ? theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)
                                : theme.textTheme.bodySmall,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05);
  }
}
