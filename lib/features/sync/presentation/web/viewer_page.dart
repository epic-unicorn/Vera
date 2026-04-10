import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/strings_nl.dart';
import '../../../../services/webrtc_sync_service.dart';

/// # Web Viewer Page
///
/// A Passive Viewer that connects to the mobile Data Source via WebRTC P2P.
/// All received data exists ONLY in RAM. On tab close, the browser GCs it.
///
/// ## Platform behaviour
/// * On **Web**: renders a QR scanner (camera) to read the session QR code,
///   then connects via WebRTC.
/// * On **Mobile**: shows the QR scanner to join a session from another device.
class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({super.key, this.sessionToken});

  /// Pre-filled from deep-link query param `?token=<base64>` on web.
  final String? sessionToken;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage> {
  WebRtcConnectionState _connectionState = WebRtcConnectionState.idle;
  String? _receivedData;
  String? _error;
  bool _scanning = true;
  bool _showEphemeralWarning = true;

  @override
  void initState() {
    super.initState();

    // Auto-connect if token arrived via deep link
    if (widget.sessionToken != null) {
      _connectFromToken(widget.sessionToken!);
    }
  }

  Future<void> _connectFromToken(String token) async {
    setState(() => _scanning = false);
    try {
      final decoded = utf8.decode(base64Decode(token));
      final payload = SyncSessionPayload.fromQrPayload(decoded);
      await _connect(payload);
    } catch (_) {
      setState(() => _error = 'Ongeldige QR-code of sessietoken.');
    }
  }

  Future<void> _connect(SyncSessionPayload payload) async {
    if (payload.isExpired) {
      setState(() => _error = StringsNl.syncSessionExpired);
      return;
    }

    final syncService = ref.read(webRtcSyncServiceProvider);

    syncService.connectionStateStream.listen((state) {
      if (mounted) setState(() => _connectionState = state);
    });

    syncService.incomingData.listen((data) {
      if (mounted) setState(() => _receivedData = data);
    });

    final result = await syncService.joinSession(payload);
    if (result.failure != null) {
      setState(() => _error = result.failure!.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(StringsNl.syncWebViewerTitle),
        actions: [
          if (_connectionState == WebRtcConnectionState.connected)
            TextButton.icon(
              onPressed: () => ref.read(webRtcSyncServiceProvider).hangUp(),
              icon: const Icon(Icons.close),
              label: const Text('Sessie sluiten'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Ephemeral data warning bar ──────────────────────────────────
            if (_showEphemeralWarning)
              _EphemeralWarningBar(
                onDismiss: () => setState(() => _showEphemeralWarning = false),
              ),

            Expanded(child: _buildBody(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    // ── Error state ─────────────────────────────────────────────────────────
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {
                  _error = null;
                  _scanning = true;
                }),
                child: const Text(StringsNl.retry),
              ),
            ],
          ),
        ),
      );
    }

    // ── Connected: show received data ───────────────────────────────────────
    if (_connectionState == WebRtcConnectionState.connected &&
        _receivedData != null) {
      return _ReceivedDataView(data: _receivedData!);
    }

    // ── Connecting ──────────────────────────────────────────────────────────
    if (_connectionState == WebRtcConnectionState.connecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator.adaptive(),
            const SizedBox(height: 16),
            Text(StringsNl.syncConnecting, style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }

    // ── QR scanner (idle state) ─────────────────────────────────────────────
    if (_scanning) {
      return _QrScannerView(
        onDetected: (qrPayload) async {
          setState(() => _scanning = false);
          try {
            final payload = SyncSessionPayload.fromQrPayload(qrPayload);
            await _connect(payload);
          } catch (_) {
            setState(() {
              _error = 'Ongeldige QR-code. Probeer opnieuw.';
              _scanning = true;
            });
          }
        },
      );
    }

    return const Center(child: CircularProgressIndicator.adaptive());
  }
}

// ── Ephemeral warning bar ─────────────────────────────────────────────────────

class _EphemeralWarningBar extends StatelessWidget {
  const _EphemeralWarningBar({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: StringsNl.syncEphemeralWarning,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFFFF3E0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined,
                size: 20, color: Color(0xFFE07B00)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                StringsNl.syncEphemeralWarning,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8D4A00),
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Sluiten',
              onPressed: onDismiss,
              color: const Color(0xFFE07B00),
            ),
          ],
        ),
      ),
    );
  }
}

// ── QR scanner ────────────────────────────────────────────────────────────────

class _QrScannerView extends StatelessWidget {
  const _QrScannerView({required this.onDetected});
  final void Function(String) onDetected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(StringsNl.syncWebViewerBody,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(StringsNl.syncScanQr,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.firstOrNull;
                  if (barcode?.rawValue != null) {
                    onDetected(barcode!.rawValue!);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ── Received data view ────────────────────────────────────────────────────────

class _ReceivedDataView extends StatelessWidget {
  const _ReceivedDataView({required this.data});
  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(data) as Map<String, dynamic>?;
    } catch (_) {}

    final resources = (parsed?['resources'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi, color: Color(0xFF1B7A3E), size: 20),
                  const SizedBox(width: 8),
                  Text(StringsNl.syncConnected,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1B7A3E),
                      )),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Gegevens bestaan uitsluitend in RAM. '
                'Sluiten van dit tabblad wist alle gegevens.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Resource summary table
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final r = resources[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    r['type'] as String? ?? 'Resource',
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    r['id'] as String? ?? '',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5EE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('RAM',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: const Color(0xFF1B5E20))),
                  ),
                ),
              ).animate().fadeIn(
                    delay: Duration(milliseconds: index * 50),
                    duration: 300.ms,
                  );
            },
          ),
        ),
      ],
    );
  }
}
