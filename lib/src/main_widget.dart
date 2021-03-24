import 'dart:convert';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:independent_localization/src/Exceptions/language_not_defined_exception.dart';
import 'package:independent_localization/src/config.dart';
import 'package:independent_localization/src/logger.dart';

// extension yhhContext on BuildContext {
//   void trf() {}
// }

String tr(String key, [String defaultValue]) {
  String translated;
  try {
    translated = IndependentLocalizationWidget
        ._decodedLocaleJson[IndependentLocalizationWidget._currentLocale][key];
  } catch (e) {
    Logger.log('[E]' + e.toString());
  }
  if (translated == null) {
    Logger.log('[E] Empty translated value');
    return defaultValue ?? key;
  } else {
    return translated;
  }
}

changeLocale(Locale locale) {
  if (!IndependentLocalizationWidget._decodedLocaleJson.containsKey(locale))
    throw LanguageNotDefinedException();
  else
    IndependentLocalizationWidget._currentLocale = locale;
}

class IndependentLocalizationWidget extends StatelessWidget {
  /// e.g: ```{
  ///       Locale('en','US'):rootBundle.loadString(path)
  /// }```
  final Map<Locale, Future<String>> localesJson;

  final bool openLogChannel;

  final Locale fallbackLocale;

  final Widget child;

  static Map<Locale, Map<String, dynamic>> _decodedLocaleJson;
  static Locale _currentLocale;
  static Locale _fallbackLocale;

  IndependentLocalizationWidget(
      {this.localesJson,
      this.openLogChannel,
      this.fallbackLocale,
      this.child}) {
    Config.openLogChannel = this.openLogChannel ?? true;
  }

  Future<void> loadLocales() async {
    Logger.log("[i] Loading Locales...");
    if (localesJson != null && localesJson.isNotEmpty) {
      for (var j in localesJson.entries) {
        _decodedLocaleJson[j.key] = jsonDecode(await j.value);
      }
    }
    Logger.log("[i] Loading fallback Locale...");
    if (fallbackLocale == null)
      _fallbackLocale = _decodedLocaleJson.entries.first.key;

    Logger.log("[i] Determining current Locale...");
    if (_currentLocale == null) {
      final Locale l = await Devicelocale.currentAsLocale;
      if (!_decodedLocaleJson.keys.contains(l)) {
        _currentLocale = _fallbackLocale;
      } else {
        _currentLocale = l;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return child ?? Container();
  }
}
