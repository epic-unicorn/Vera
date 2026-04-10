import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/strings_nl.dart';
import '../../core/router/app_router.dart';
import 'privacy_sentinel.dart';

/// Shell widget that wraps main feature pages with persistent
/// bottom navigation and the [PrivacySentinel] status bar.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _indexFor(location);

    return Scaffold(
      // ── Privacy sentinel – always visible at top ──────────────────────────
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              StringsNl.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 4),
            Text(
              '·',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
            ),
          ],
        ),
        actions: const [
          // Compact sentinel dot always visible in app-bar
          PrivacySentinel(compact: true),
          SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: const PrivacySentinel(),
          ),
        ),
      ),

      body: child,

      // ── Bottom navigation ─────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _navigate(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: StringsNl.navBlueprint,
            tooltip: 'Uw persoonlijke oncologie tijdlijn',
          ),
          NavigationDestination(
            icon: Icon(Icons.translate_outlined),
            selectedIcon: Icon(Icons.translate),
            label: StringsNl.navDecoder,
            tooltip: 'Medische vaktaal decoder',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: StringsNl.navAppointments,
            tooltip: 'Afspraken en pocket-gids',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_outlined),
            selectedIcon: Icon(Icons.qr_code),
            label: StringsNl.navSync,
            tooltip: 'Veilig delen via P2P',
          ),
        ],
      ),
    );
  }

  int _indexFor(String path) {
    if (path.startsWith(AppRoute.blueprint)) return 0;
    if (path.startsWith(AppRoute.decoder)) return 1;
    if (path.startsWith(AppRoute.appointments)) return 2;
    if (path.startsWith(AppRoute.sync)) return 3;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoute.blueprint);
      case 1:
        context.go(AppRoute.decoder);
      case 2:
        context.go(AppRoute.appointments);
      case 3:
        context.go(AppRoute.sync);
    }
  }
}
