import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'shared/theme/vera_theme.dart';

/// Root application widget.
///
/// Configures:
/// * Dutch-primary locale with 6 supported languages.
/// * WCAG-compliant Material 3 theme ([VeraTheme]).
/// * GoRouter via [appRouterProvider].
class VeraApp extends ConsumerWidget {
  const VeraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Vera',
      debugShowCheckedModeBanner: false,

      // ── Dutch primary locale ─────────────────────────────────────────────
      locale: const Locale('nl', 'NL'),
      supportedLocales: const [
        Locale('nl', 'NL'), // Default: Dutch
        Locale('en', 'US'),
        Locale('de', 'DE'),
        Locale('fr', 'FR'),
        Locale('ar'),
        Locale('tr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── WCAG-compliant themes ────────────────────────────────────────────
      theme: VeraTheme.lightTheme,
      darkTheme: VeraTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Accessibility ─────────────────────────────────────────────────────
      // Flutter respects the OS text-scale factor automatically.
      // No textScaleFactor cap is applied; see EAA / WCAG 1.4.4 requirement.

      // ── Router ───────────────────────────────────────────────────────────
      routerConfig: router,
    );
  }
}
