import 'dart:async';
import 'package:flutter/foundation.dart';

/// Debug logging service that captures all startup and runtime logs.
/// Useful for diagnosing application startup issues.
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();

  factory DebugLogger() {
    return _instance;
  }

  DebugLogger._internal();

  final List<String> _logs = [];
  final List<String> _errors = [];

  bool _initialized = false;
  DateTime? _startTime;

  /// Initialize the debug logger with error zone handling.
  static Future<void> initialize() async {
    final logger = DebugLogger();
    if (logger._initialized) return;

    logger._startTime = DateTime.now();
    logger._initialized = true;
    logger.log('🚀 Application startup initialized');

    // Capture uncaught errors
    runZonedGuarded(() {
      // Main app runs here
    }, (error, stackTrace) {
      logger.error('Uncaught error: $error', stackTrace);
    });
  }

  /// Log a message with timestamp.
  void log(String message) {
    final timestamp = _getTimestamp();
    final entry = '[$timestamp] $message';
    _logs.add(entry);
    if (kDebugMode) {
      print(entry);
    }
  }

  /// Log an error with optional stack trace.
  void error(String message, [StackTrace? stackTrace]) {
    final timestamp = _getTimestamp();
    final entry = '[$timestamp] ❌ ERROR: $message';
    _logs.add(entry);
    _errors.add(entry);

    if (stackTrace != null) {
      _logs.add('Stack trace:\n$stackTrace');
    }

    if (kDebugMode) {
      print(entry);
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
    }
  }

  /// Log a warning.
  void warn(String message) {
    final timestamp = _getTimestamp();
    final entry = '[$timestamp] ⚠️  WARNING: $message';
    _logs.add(entry);
    if (kDebugMode) {
      print(entry);
    }
  }

  /// Get all logs as a formatted string.
  String getAllLogs() {
    return _logs.join('\n');
  }

  /// Get all errors as a formatted string.
  String getErrors() {
    return _errors.join('\n');
  }

  /// Export logs for sharing (includes basic device/app info).
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('═' * 60);
    buffer.writeln('VERA DEBUG LOG EXPORT');
    buffer.writeln('═' * 60);
    buffer.writeln('Timestamp: ${DateTime.now()}');
    buffer.writeln(
        'Duration: ${_startTime != null ? DateTime.now().difference(_startTime!) : 'N/A'}');
    buffer.writeln('─' * 60);
    buffer.writeln('LOGS:');
    buffer.writeln('─' * 60);
    buffer.writeln(_logs.join('\n'));

    if (_errors.isNotEmpty) {
      buffer.writeln('\n');
      buffer.writeln('─' * 60);
      buffer.writeln('ERRORS:');
      buffer.writeln('─' * 60);
      buffer.writeln(_errors.join('\n'));
    }

    buffer.writeln('\n' + '═' * 60);
    return buffer.toString();
  }

  /// Clear logs.
  void clear() {
    _logs.clear();
    _errors.clear();
  }

  String _getTimestamp() {
    if (_startTime == null) {
      return DateTime.now().toIso8601String().split('.')[0];
    }
    final elapsed = DateTime.now().difference(_startTime!);
    return '${elapsed.inSeconds}s';
  }
}
