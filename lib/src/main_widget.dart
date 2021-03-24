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
  if (!IndependentLocalizationWidget.loadedLocales) {
    Logger.log("[i] Localization currently not ready. Returned key instead.");
    return defaultValue ?? key;
  }
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

class IndependentLocalizationWidget extends StatefulWidget {
  /// e.g: ```{
  ///       Locale('en','US'): await rootBundle.loadString(path)
  /// }```
  final Map<Locale,String> localesJson;

  final bool openLogChannel;

  final Locale fallbackLocale;

  final Widget child;

  static Map<Locale, Map<String, dynamic>> _decodedLocaleJson;
  static Locale _currentLocale;
  static Locale _fallbackLocale;

  static bool loadedLocales = false;

  IndependentLocalizationWidget(
      {this.localesJson,
      this.openLogChannel,
      this.fallbackLocale,
      this.child}) {
    Config.openLogChannel = this.openLogChannel ?? true;
  }

  @override
  _IndependentLocalizationWidgetState createState() =>
      _IndependentLocalizationWidgetState();
}

class _IndependentLocalizationWidgetState
    extends State<IndependentLocalizationWidget> {
  Future<void> loadLocales() async {
    Logger.log("[i] Loading Locales...");
    if (widget.localesJson != null && widget.localesJson.isNotEmpty) {
      for (var j in widget.localesJson.entries) {
        IndependentLocalizationWidget._decodedLocaleJson[j.key] =
            jsonDecode(j.value);
      }
    }
    Logger.log("[i] Loading fallback Locale...");
    if (widget.fallbackLocale == null &&
        IndependentLocalizationWidget._decodedLocaleJson != null &&
        IndependentLocalizationWidget._decodedLocaleJson.isNotEmpty)
      IndependentLocalizationWidget._fallbackLocale =
          IndependentLocalizationWidget._decodedLocaleJson.entries.first.key;

    Logger.log("[i] Determining current Locale...");
    if (IndependentLocalizationWidget._currentLocale == null) {
      final Locale l = await Devicelocale.currentAsLocale;
      if (IndependentLocalizationWidget._decodedLocaleJson != null &&
          IndependentLocalizationWidget._decodedLocaleJson.isNotEmpty) {
        if (!IndependentLocalizationWidget._decodedLocaleJson.keys
            .contains(l)) {
          IndependentLocalizationWidget._currentLocale =
              IndependentLocalizationWidget._fallbackLocale;
        } else {
          IndependentLocalizationWidget._currentLocale = l;
        }
      } else {
        IndependentLocalizationWidget._currentLocale = Locale('en','US');
      }
    }
    IndependentLocalizationWidget.loadedLocales = true;
  }

  @override
  void initState() {
    loadLocales();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child ?? Container();
  }
}
