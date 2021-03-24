import 'dart:developer';

import 'package:independent_localization/src/config.dart';

class Logger {
  Logger.log(String o) {
    if (Config.openLogChannel) {
      log(o,name: "[Indep Locale]");
    }
  }
}
