import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/strings_nl.dart';
import '../../../../services/local_translation_service.dart';
import '../../domain/models/jargon_entry.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class _DecoderState {
  const _DecoderState({
    this.query = '',
    this.selectedLanguage = 'nl',
    this.translatedEntries = const {},
    this.isTranslating = false,
    this.downloadProgress = const <String, double>{},
  });

  final String query;
  final String selectedLanguage;
  final Map<String, String> translatedEntries; // termKey → translated text
  final bool isTranslating;
  final Map<String, double> downloadProgress;

  _DecoderState copyWith({
    String? query,
    String? selectedLanguage,
    Map<String, String>? translatedEntries,
    bool? isTranslating,
    Map<String, double>? downloadProgress,
  }) =>
      _DecoderState(
        query: query ?? this.query,
        selectedLanguage: selectedLanguage ?? this.selectedLanguage,
        translatedEntries: translatedEntries ?? this.translatedEntries,
        isTranslating: isTranslating ?? this.isTranslating,
        downloadProgress: downloadProgress ?? this.downloadProgress,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class _DecoderNotifier extends StateNotifier<_DecoderState> {
  _DecoderNotifier(this._translationService) : super(const _DecoderState());

  final LocalTranslationService _translationService;

  void setQuery(String q) => state = state.copyWith(query: q);

  Future<void> setLanguage(String langCode) async {
    state = state.copyWith(selectedLanguage: langCode, translatedEntries: {});
    if (langCode == 'nl') return; // no translation needed for source language

    final isDownloaded = await _translationService.isModelDownloaded(langCode);
    if (!isDownloaded) {
      // Start download & show progress
      _translationService.downloadModel(langCode).listen((progress) {
        state = state.copyWith(
            downloadProgress: {...state.downloadProgress, langCode: progress});
        if (progress >= 1.0) _translateAll(langCode);
      });
    } else {
      await _translateAll(langCode);
    }
  }

  Future<void> _translateAll(String langCode) async {
    state = state.copyWith(isTranslating: true);
    final translated = <String, String>{};

    for (final entry in builtInGlossary) {
      final result = await _translationService.translate(
        text: '${entry.dutchExplanation}\n\n${entry.actionItem}',
        targetLanguage: langCode,
      );
      translated[entry.term] =
          result.text ?? '${entry.dutchExplanation}\n\n${entry.actionItem}';
    }

    state = state.copyWith(
      isTranslating: false,
      translatedEntries: translated,
    );
  }
}

final _decoderProvider =
    StateNotifierProvider<_DecoderNotifier, _DecoderState>((ref) {
  return _DecoderNotifier(ref.watch(localTranslationServiceProvider));
});

// ── Page ──────────────────────────────────────────────────────────────────────

/// # Smart System Decoder Page
///
/// Translates pathology jargon into plain-language Dutch "Action Items" with
/// optional on-device translation into any supported language.
///
/// Privacy note: Translation is performed ENTIRELY on-device using ML Kit.
/// An explicit notice reminds the user that no data is sent externally.
class DecoderPage extends ConsumerWidget {
  const DecoderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(_decoderProvider);
    final notifier = ref.read(_decoderProvider.notifier);
    final theme = Theme.of(context);

    final filtered = builtInGlossary
        .where((e) =>
            state.query.isEmpty ||
            e.term.toLowerCase().contains(state.query.toLowerCase()) ||
            e.dutchExplanation
                .toLowerCase()
                .contains(state.query.toLowerCase()))
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(StringsNl.decoderTitle,
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text(StringsNl.decoderSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.65),
                      )),
                  const SizedBox(height: 16),

                  // ── Language selector ────────────────────────────────────
                  _LanguageSelector(
                    selected: state.selectedLanguage,
                    downloadProgress: state.downloadProgress,
                    onChanged: notifier.setLanguage,
                  ),
                  const SizedBox(height: 8),

                  // ── Privacy note ─────────────────────────────────────────
                  _PrivacyNote(),
                  const SizedBox(height: 16),

                  // ── Search bar ───────────────────────────────────────────
                  Semantics(
                    label: 'Zoek op medische term',
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: StringsNl.decoderSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: state.query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                tooltip: 'Zoekopdracht wissen',
                                onPressed: () => notifier.setQuery(''),
                              )
                            : null,
                      ),
                      onChanged: notifier.setQuery,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Loading indicator ─────────────────────────────────────────────
          if (state.isTranslating)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text('Lokaal vertalen…', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),

          // ── Glossary list ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final entry = filtered[index];
                final translated = state.translatedEntries[entry.term];
                return _JargonCard(
                  entry: entry,
                  translatedContent: translated,
                  targetLanguage: state.selectedLanguage,
                ).animate().fadeIn(
                      delay: Duration(milliseconds: index * 50),
                      duration: 300.ms,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language selector ─────────────────────────────────────────────────────────

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({
    required this.selected,
    required this.downloadProgress,
    required this.onChanged,
  });

  final String selected;
  final Map<String, double> downloadProgress;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${StringsNl.decoderLanguageLabel}: geselecteerd $selected',
      child: Row(
        children: [
          Text('${StringsNl.decoderLanguageLabel}:',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
              items: supportedTranslationLanguages
                  .map(
                    (lang) => DropdownMenuItem(
                      value: lang.code,
                      child: Row(
                        children: [
                          Text(lang.label),
                          if ((downloadProgress[lang.code] ?? 0) > 0 &&
                              (downloadProgress[lang.code] ?? 0) < 1) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: downloadProgress[lang.code],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Privacy note ──────────────────────────────────────────────────────────────

class _PrivacyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1B7A3E)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF1B7A3E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              StringsNl.decoderPrivacyNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1B5E20),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Jargon card ───────────────────────────────────────────────────────────────

class _JargonCard extends StatefulWidget {
  const _JargonCard({
    required this.entry,
    required this.translatedContent,
    required this.targetLanguage,
  });

  final JargonEntry entry;
  final String? translatedContent;
  final String targetLanguage;

  @override
  State<_JargonCard> createState() => _JargonCardState();
}

class _JargonCardState extends State<_JargonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    // Split translated content back (explanation + action item)
    final parts = widget.translatedContent?.split('\n\n') ?? [];
    final explanation = parts.isNotEmpty ? parts.first : entry.dutchExplanation;
    final actionItem = parts.length > 1 ? parts.last : entry.actionItem;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Term header ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(entry.term, style: theme.textTheme.titleMedium),
                  ),
                  if (entry.category.isNotEmpty)
                    Chip(label: Text(entry.category)),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),

              // ── Expanded content ──────────────────────────────────────────
              AnimatedCrossFade(
                duration: 250.ms,
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(explanation, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    // Action item
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.task_alt,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Actiepunt',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                        color: theme.colorScheme.primary)),
                                const SizedBox(height: 4),
                                Text(actionItem,
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // IKNL ref
                    if (entry.iknlRef != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text('IKNL Richtlijn'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 36),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
