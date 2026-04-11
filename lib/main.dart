import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'app.dart';
import 'features/vault/data/models/medical_record_model.dart';
import 'services/debug_logger.dart';
import 'services/local_vault_service.dart';

Future<void> main() async {
  // Initialize debug logging first
  DebugLogger().log('Starting main() function');

  try {
    WidgetsFlutterBinding.ensureInitialized();
    DebugLogger().log('✓ WidgetsFlutterBinding initialized');
  } catch (e, st) {
    DebugLogger().error('Failed to initialize WidgetsFlutterBinding', st);
    rethrow;
  }

  try {
    // ── Orientation lock (mobile portrait for senior usability) ────────────────
    if (!UniversalPlatform.isWeb) {
      DebugLogger().log('Setting portrait orientation lock');
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      DebugLogger().log('✓ Orientation locked to portrait');
    } else {
      DebugLogger().log('Web platform detected, skipping orientation lock');
    }
  } catch (e, st) {
    DebugLogger().error('Failed to set orientation', st);
    // Continue - this is not critical
  }

  // ── Initialise Isar (mobile only) ──────────────────────────────────────────
  // Web uses RAM-only storage; no Isar instance is created.
  Isar? isar;
  try {
    if (!UniversalPlatform.isWeb) {
      DebugLogger().log('Initializing Isar database...');
      final dir = await getApplicationDocumentsDirectory();
      DebugLogger().log('✓ App documents directory: ${dir.path}');

      isar = await Isar.open(
        [
          MedicalRecordModelSchema,
          AppointmentModelSchema,
        ],
        directory: dir.path,
        name: 'vera_vault',
      );
      DebugLogger().log('✓ Isar database opened successfully');
    } else {
      DebugLogger().log('Web platform detected, skipping Isar initialization');
    }
  } catch (e, st) {
    DebugLogger().error('Failed to initialize Isar database', st);
    rethrow;
  }

  try {
    DebugLogger().log('Starting ProviderScope and VeraApp...');
    runApp(
      ProviderScope(
        overrides: [
          // Override the isarProvider with the real instance on mobile.
          // On web, this override is skipped and any call to isarProvider
          // will throw UnimplementedError, which LocalVaultService guards via
          // PlatformDetector.isVaultSupported.
          if (isar != null) isarProvider.overrideWithValue(isar),
        ],
        child: const VeraApp(),
      ),
    );
    DebugLogger().log('✓ App started successfully');
  } catch (e, st) {
    DebugLogger().error('Failed to start app', st);
    rethrow;
  }
}
