import 'package:flutter/foundation.dart';

class AppRefresh {
  AppRefresh._();

  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void refresh() {
    version.value++;
  }
}
