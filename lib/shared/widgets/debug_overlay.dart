import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/debug_logger.dart';

/// Debug overlay widget that displays logs in a scrollable panel.
/// Call [DebugOverlay.show(context)] to display.
class DebugOverlay {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _DebugPanel(),
    );
  }
}

class _DebugPanel extends StatefulWidget {
  const _DebugPanel();

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  late ScrollController _scrollController;
  bool _showErrorsOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logger = DebugLogger();
    final logs = _showErrorsOnly ? logger.getErrors() : logger.getAllLogs();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFF1e1e1e),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2d2d2d),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🐛 Debug Logs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${logger.getAllLogs().split('\n').length} | Errors: ${logger.getErrors().split('\n').length}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _showErrorsOnly = !_showErrorsOnly);
                      },
                      icon: Icon(
                        _showErrorsOnly
                            ? Icons.filter_alt
                            : Icons.filter_alt_off,
                        color: _showErrorsOnly ? Colors.red : Colors.grey,
                      ),
                      label: Text(
                        _showErrorsOnly ? 'Errors' : 'All',
                        style: TextStyle(
                          color: _showErrorsOnly ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _copyToClipboard(context, logger.exportLogs());
                      },
                      icon: const Icon(Icons.copy, color: Colors.blue),
                      tooltip: 'Copy all logs',
                    ),
                    IconButton(
                      onPressed: () {
                        logger.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Clear logs',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logs area
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  logs.isEmpty ? '(No logs)' : logs,
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 11,
                    fontFamily: 'Courier',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          // Export button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _copyToClipboard(context, logger.exportLogs());
                },
                icon: const Icon(Icons.share),
                label: const Text('📋 Copy Logs for Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Logs copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    });
  }
}
