import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'app.dart';
import 'features/vault/data/models/medical_record_model.dart';
import 'services/local_vault_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Orientation lock (mobile portrait for senior usability) ────────────────
  if (!UniversalPlatform.isWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // ── Initialise Isar (mobile only) ──────────────────────────────────────────
  // Web uses RAM-only storage; no Isar instance is created.
  Isar? isar;
  if (!UniversalPlatform.isWeb) {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        MedicalRecordModelSchema,
        AppointmentModelSchema,
      ],
      directory: dir.path,
      name: 'vera_vault',
    );
  }

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
}
