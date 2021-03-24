import 'dart:convert';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:independent_localization/src/Exceptions/language_not_defined_exception.dart';
import 'package:independent_localization/src/config.dart';
import 'package:independent_localization/src/logger.dart';

String tr(String key, [String defaultValue]) {
  String translated;
  try {
    translated = IndependentLocalization
        ._decodedLocaleJson[IndependentLocalization._currentLocale][key];
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

class IndependentLocalization {
  /// e.g: ```{
  ///       Locale('en','US'): await rootBundle.loadString(path)
  /// }```
  final Map<Locale, String> localesJson;

  final bool openLogChannel;

  final Locale fallbackLocale;

  static Locale get currentLocale => _currentLocale;

  static IndependentLocalization _instance;
  static IndependentLocalization get instance => _instance;

  static Map<Locale, Map<String, dynamic>> _decodedLocaleJson;
  static Locale _currentLocale;
  static Locale _fallbackLocale;

  IndependentLocalization({
    this.localesJson,
    this.openLogChannel,
    this.fallbackLocale,
  }) {
    Config.openLogChannel = this.openLogChannel ?? true;
  }

  Future<IndependentLocalization> initialize() async {
    Logger.log("[i] Loading Locales...");
    if (localesJson != null && localesJson.isNotEmpty) {
      _decodedLocaleJson = {};
      for (var j in localesJson.entries) {
        _decodedLocaleJson[j.key] = jsonDecode(j.value);
      }
    }
    Logger.log("[i] Loading fallback Locale...");
    if (fallbackLocale == null &&
        _decodedLocaleJson != null &&
        _decodedLocaleJson.isNotEmpty)
      _fallbackLocale = _decodedLocaleJson.entries.first.key;

    Logger.log("[i] Determining current Locale...");
    if (_currentLocale == null) {
      final Locale l = await Devicelocale.currentAsLocale;
      if (_decodedLocaleJson != null && _decodedLocaleJson.isNotEmpty) {
        if (!_decodedLocaleJson.keys.contains(l)) {
          _currentLocale = _fallbackLocale;
        } else {
          _currentLocale = l;
        }
      } else {
        _currentLocale = Locale('en', 'US');
      }
    }
    _instance = this;
    return _instance;
  }

  static changeLocale(Locale locale) {
    if (!_decodedLocaleJson.containsKey(locale))
      throw LanguageNotDefinedException();
    else
      _currentLocale = locale;
  }
}
