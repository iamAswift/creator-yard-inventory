//lib/core/app/app_refresh.dart

import 'package:flutter/foundation.dart';

class AppRefresh {
  AppRefresh._();

  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  static bool _resetRequested = false;

  static void refresh() {
    version.value++;
  }

  static void resetToInitialSetup() {
    _resetRequested = true;
    refresh();
  }

  static bool consumeResetRequest() {
    final requested = _resetRequested;
    _resetRequested = false;
    return requested;
  }
}
