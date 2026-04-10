import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/strings_nl.dart';
import '../../../../services/mock_data_service.dart';
import '../../../../services/webrtc_sync_service.dart';
import '../../../../shared/widgets/privacy_sentinel.dart';

/// Mobile-side QR Share page.
/// Generates an ephemeral session QR code and manages the P2P data stream.
class QrSharePage extends ConsumerStatefulWidget {
  const QrSharePage({super.key});

  @override
  ConsumerState<QrSharePage> createState() => _QrSharePageState();
}

class _QrSharePageState extends ConsumerState<QrSharePage> {
  SyncSessionPayload? _payload;
  bool _isCreating = false;
  String? _error;
  WebRtcConnectionState _connectionState = WebRtcConnectionState.idle;

  @override
  void initState() {
    super.initState();
    _createSession();
  }

  Future<void> _createSession() async {
    setState(() {
      _isCreating = true;
      _error = null;
      _payload = null;
    });

    // Fetch mock data to share
    final mockService = ref.read(mockDataServiceProvider);
    final result = await mockService.fetchOncologyBundle();
    if (result.failure != null || result.bundle == null) {
      setState(() {
        _error = result.failure?.message ?? 'Fout bij laden gegevens';
        _isCreating = false;
      });
      return;
    }

    // Serialise (in production: encrypt before sending)
    final serialised = jsonEncode({
      'timestamp': result.bundle!.timestamp,
      'resources': result.bundle!.resources
          .map((r) => {'type': r.resourceType, 'id': r.id})
          .toList(),
    });

    final syncService = ref.read(webRtcSyncServiceProvider);

    // Listen to connection state changes
    syncService.connectionStateStream.listen((state) {
      if (mounted) setState(() => _connectionState = state);
    });

    final sessionResult = await syncService.createSession(serialised);

    if (sessionResult.failure != null) {
      setState(() {
        _error = sessionResult.failure!.message;
        _isCreating = false;
      });
      return;
    }

    setState(() {
      _payload = sessionResult.payload;
      _isCreating = false;
    });
  }

  Future<void> _hangUp() async {
    final syncService = ref.read(webRtcSyncServiceProvider);
    await syncService.hangUp();
    setState(() {
      _payload = null;
      _connectionState = WebRtcConnectionState.idle;
    });
    // Navigate back
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _payload?.expiresAt != null
        ? _payload!.expiresAt.difference(DateTime.now()).inSeconds
        : 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(StringsNl.syncTitle,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(StringsNl.syncSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),

              // ── Privacy sentinel – prominent placement ──────────────────
              const PrivacySentinel(),
              const SizedBox(height: 24),

              // ── QR / status area ────────────────────────────────────────
              Expanded(
                child: Center(
                  child: _buildContent(theme, remaining),
                ),
              ),

              const SizedBox(height: 16),
              // ── End session ──────────────────────────────────────────────
              if (_payload != null)
                OutlinedButton.icon(
                  onPressed: _hangUp,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Sessie beëindigen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, int remainingSeconds) {
    if (_isCreating) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          const SizedBox(height: 16),
          Text(StringsNl.syncConnecting, style: theme.textTheme.bodyMedium),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _createSession, child: const Text(StringsNl.retry)),
        ],
      );
    }

    if (_payload == null) return const SizedBox.shrink();

    final qrData = _payload!.toQrPayload();
    final isConnected = _connectionState == WebRtcConnectionState.connected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Connection status badge ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isConnected ? const Color(0xFFE8F5EE) : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected
                  ? const Color(0xFF1B7A3E)
                  : const Color(0xFFE07B00),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_find,
                size: 16,
                color: isConnected
                    ? const Color(0xFF1B7A3E)
                    : const Color(0xFFE07B00),
              ),
              const SizedBox(width: 8),
              Text(
                isConnected
                    ? StringsNl.syncConnected
                    : StringsNl.syncSessionActive,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isConnected
                      ? const Color(0xFF1B7A3E)
                      : const Color(0xFFE07B00),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── QR code ────────────────────────────────────────────────────────
        Semantics(
          label: 'QR-code voor veilig delen. Scan met de Vera Web Viewer.',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.colorScheme.outlineVariant, width: 1.5),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              semanticsLabel: 'QR code voor P2P sync',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Instruction ───────────────────────────────────────────────────
        Text(
          StringsNl.syncQrInstruction,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // ── Session TTL ────────────────────────────────────────────────────
        if (remainingSeconds > 0)
          Text(
            'Sessie verloopt over ${remainingSeconds}s',
            style: theme.textTheme.bodySmall?.copyWith(
              color: remainingSeconds < 60
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
      ],
    );
  }
}
