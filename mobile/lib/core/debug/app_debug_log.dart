import 'package:flutter/foundation.dart';

/// Debug-only logging (no-op in release builds).
bool get appDebugLoggingEnabled => kDebugMode;

void appDebugLog(String tag, String message, [Object? detail]) {
  if (!appDebugLoggingEnabled) {
    return;
  }
  final buf = StringBuffer('[DEBUG][$tag] $message');
  if (detail != null) {
    buf.write(' | $detail');
  }
  debugPrint(buf.toString());
}

void appDebugError(
  String tag,
  Object error, [
  StackTrace? stackTrace,
  String? context,
]) {
  if (!appDebugLoggingEnabled) {
    return;
  }
  final buf = StringBuffer('[DEBUG][$tag][ERROR] $error');
  if (context != null) {
    buf.write(' | $context');
  }
  debugPrint(buf.toString());
  if (stackTrace != null) {
    debugPrint(stackTrace.toString());
  }
}
