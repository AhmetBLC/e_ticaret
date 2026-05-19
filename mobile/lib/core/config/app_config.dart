import 'dart:io';

import 'package:flutter/foundation.dart';

/// Backend REST API base URL including `/api`.
/// Android emulator: use `10.0.2.2` to reach host machine.
/// Override: `--dart-define=API_BASE_URL=http://192.168.1.x:3000/api`
class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) {
      return fromEnv;
    }
    if (kIsWeb) {
      return 'https://api.takasapp.info.tr/api';
    }
    if (Platform.isAndroid) {
      return 'https://api.takasapp.info.tr/api';
    }
    return 'https://api.takasapp.info.tr/api';
  }
}
