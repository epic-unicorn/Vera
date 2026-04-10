import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/blueprint/presentation/pages/blueprint_page.dart';
import '../../features/decoder/presentation/pages/decoder_page.dart';
import '../../features/appointments/presentation/pages/appointment_navigator_page.dart';
import '../../features/sync/presentation/mobile/qr_share_page.dart';
import '../../features/sync/presentation/web/viewer_page.dart';
import '../../shared/widgets/app_shell.dart';
import '../../core/platform/platform_detector.dart';

// ── Route names ──────────────────────────────────────────────────────────────

abstract final class AppRoute {
  static const String auth = '/auth';
  static const String home = '/';
  static const String blueprint = '/blueprint';
  static const String decoder = '/decoder';
  static const String appointments = '/appointments';
  static const String sync = '/sync';
  static const String webViewer = '/viewer';
}

// ── Provider ─────────────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation:
        PlatformDetector.isWeb ? AppRoute.webViewer : AppRoute.auth,
    debugLogDiagnostics: false,
    routes: [
      // ── Auth (Mobile) ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoute.auth,
        builder: (context, state) => const AuthPage(),
      ),

      // ── Main shell with bottom navigation (Mobile) ───────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoute.home,
            redirect: (_, __) => AppRoute.blueprint,
          ),
          GoRoute(
            path: AppRoute.blueprint,
            builder: (context, state) => const BlueprintPage(),
          ),
          GoRoute(
            path: AppRoute.decoder,
            builder: (context, state) => const DecoderPage(),
          ),
          GoRoute(
            path: AppRoute.appointments,
            builder: (context, state) => const AppointmentNavigatorPage(),
          ),
          GoRoute(
            path: AppRoute.sync,
            builder: (context, state) => const QrSharePage(),
          ),
        ],
      ),

      // ── Web Viewer (P2P passive viewer – no shell) ───────────────────────
      GoRoute(
        path: AppRoute.webViewer,
        builder: (context, state) {
          // Extract session token from QR deep-link query param
          final token = state.uri.queryParameters['token'];
          return ViewerPage(sessionToken: token);
        },
      ),
    ],

    // ── Global error page ────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Pagina niet gevonden',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.message ?? 'Onbekende fout',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoute.blueprint),
                child: const Text('Terug naar home'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
