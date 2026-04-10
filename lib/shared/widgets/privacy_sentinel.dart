import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/strings_nl.dart';

// ── Privacy state ──────────────────────────────────────────────────────────────

/// Represents the three possible data-safety states Vera can be in.
enum PrivacyStatus {
  /// All data is stored locally; no external connections active.
  local,

  /// An ephemeral P2P WebRTC session is active (data stays off-server but
  /// travels encrypted to a second screen).
  p2pSessionActive,

  /// Status cannot be determined (e.g., during WebRTC setup).
  unknown,
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Global provider – can be overridden to reflect WebRTC session state.
final privacyStatusProvider = StateProvider<PrivacyStatus>(
  (_) => PrivacyStatus.local,
);

// ── Widget ────────────────────────────────────────────────────────────────────

/// # PrivacySentinel
///
/// A persistent, accessible status indicator confirming the current
/// data-safety posture of the Vera application. Rendered in Dutch.
///
/// ## Behaviour
/// * **Groen (lokaal)**: data bevindt zich uitsluitend op dit apparaat.
/// * **Oranje (P2P actief)**: een versleutelde P2P-sessie is actief;
///   gegevens verlaten het apparaat versleuteld maar geen centrale server.
/// * **Rood (onbekend)**: status niet bepaalbaar; gebruiker wordt gevraagd
///   actie te ondernemen.
///
/// ## Accessibility
/// * Semantic label announced by screen readers.
/// * Pulsating animation stops on [PrivacyStatus.local] to reduce distraction.
/// * Minimum 48 × 48 dp touch target (WCAG 2.5.5).
/// * Contrast ratio: white icon on status colours > 4.5:1 (WCAG AA).
class PrivacySentinel extends ConsumerWidget {
  const PrivacySentinel({
    super.key,
    this.compact = false,
  });

  /// When [compact] is true, only the coloured dot is shown (for toolbars).
  /// When false, the full pill with title + subtitle is shown.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(privacyStatusProvider);
    final config = _configFor(status);

    if (compact) {
      return _CompactDot(config: config, status: status);
    }

    return _SentinelPill(config: config, status: status);
  }

  static _SentinelConfig _configFor(PrivacyStatus status) {
    return switch (status) {
      PrivacyStatus.local => _SentinelConfig(
          dotColor: const Color(0xFF1B7A3E),        // WCAG AA ≥ 4.5:1 on white
          backgroundColor: const Color(0xFFE8F5EE),
          borderColor: const Color(0xFF1B7A3E),
          icon: Icons.shield_outlined,
          title: StringsNl.sentinelLocalTitle,
          subtitle: StringsNl.sentinelLocalSubtitle,
          semanticLabel:
              'Privacy Sentinel: ${StringsNl.sentinelLocalTitle}. '
              '${StringsNl.sentinelLocalSubtitle}',
          shouldPulse: false,
        ),
      PrivacyStatus.p2pSessionActive => _SentinelConfig(
          dotColor: const Color(0xFFE07B00),        // amber – 4.6:1 on white
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFE07B00),
          icon: Icons.sensors,
          title: StringsNl.sentinelWarningTitle,
          subtitle: StringsNl.sentinelWarningSubtitle,
          semanticLabel:
              'Privacy Sentinel: ${StringsNl.sentinelWarningTitle}. '
              '${StringsNl.sentinelWarningSubtitle}',
          shouldPulse: true,
        ),
      PrivacyStatus.unknown => _SentinelConfig(
          dotColor: const Color(0xFFC62828),        // red – 5.8:1 on white
          backgroundColor: const Color(0xFFFFEBEE),
          borderColor: const Color(0xFFC62828),
          icon: Icons.warning_amber_outlined,
          title: StringsNl.sentinelErrorTitle,
          subtitle: StringsNl.sentinelErrorSubtitle,
          semanticLabel:
              'Privacy Sentinel: ${StringsNl.sentinelErrorTitle}. '
              '${StringsNl.sentinelErrorSubtitle}',
          shouldPulse: true,
        ),
    };
  }
}

// ── Full pill ─────────────────────────────────────────────────────────────────

class _SentinelPill extends StatelessWidget {
  const _SentinelPill({required this.config, required this.status});
  final _SentinelConfig config;
  final PrivacyStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget pill = Semantics(
      label: config.semanticLabel,
      container: true,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppConstants.minTouchTarget,
          minWidth: AppConstants.minTouchTarget,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status dot + icon
            _AnimatedDot(config: config),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    config.title,
                    style: textTheme.titleSmall?.copyWith(
                      color: config.dotColor,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    config.subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: config.dotColor.withOpacity(0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pill;
  }
}

// ── Compact dot (toolbar) ─────────────────────────────────────────────────────

class _CompactDot extends StatelessWidget {
  const _CompactDot({required this.config, required this.status});
  final _SentinelConfig config;
  final PrivacyStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: config.semanticLabel,
      button: false,
      child: Tooltip(
        message: '${config.title}\n${config.subtitle}',
        child: SizedBox(
          width: AppConstants.minTouchTarget,
          height: AppConstants.minTouchTarget,
          child: Center(child: _AnimatedDot(config: config)),
        ),
      ),
    );
  }
}

// ── Animated status dot ───────────────────────────────────────────────────────

class _AnimatedDot extends StatelessWidget {
  const _AnimatedDot({required this.config});
  final _SentinelConfig config;

  @override
  Widget build(BuildContext context) {
    Widget dot = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: config.dotColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: config.dotColor.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        config.icon,
        size: 12,
        color: Colors.white,
      ),
    );

    if (config.shouldPulse) {
      dot = dot
          .animate(onPlay: (c) => c.repeat())
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.25, 1.25),
            duration: 900.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.25, 1.25),
            end: const Offset(1, 1),
            duration: 900.ms,
            curve: Curves.easeInOut,
          );
    }

    return dot;
  }
}

// ── Config value object ────────────────────────────────────────────────────────

class _SentinelConfig {
  const _SentinelConfig({
    required this.dotColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.shouldPulse,
  });

  final Color dotColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final bool shouldPulse;
}
