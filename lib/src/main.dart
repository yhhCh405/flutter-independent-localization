import 'dart:async';
import 'dart:convert';
import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/material.dart';
import 'package:independent_localization/src/Exceptions/language_not_defined_exception.dart';
import 'package:independent_localization/src/config.dart';
import 'package:independent_localization/src/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

String tr(String key, [String? defaultValue]) =>
    IndependentLocalization.instance!.tr(key);

extension TrExt on String {
  String get tr => IndependentLocalization.instance!.tr(this);
}

class IndependentLocalization {
  /// e.g: ```{
  ///       Locale('en','US'): await rootBundle.loadString(path)
  /// }```
  final Map<Locale, String>? localesJson;

  final bool? openLogChannel;

  final Locale? fallbackLocale;

  final StreamController<Locale?> _currLangStreamCtrl =
      StreamController.broadcast();
  Stream<Locale?> get currentLangChanges => _currLangStreamCtrl.stream;

  Locale? get currentLocale => _currentLocale;

  static IndependentLocalization? _instance;
  static IndependentLocalization? get instance => _instance;

  Map<Locale, Map<String, dynamic>?>? _decodedLocaleJson;
  Locale? _currentLocale;
  Locale? _fallbackLocale;

  late SharedPreferences pref;

  IndependentLocalization({
    this.localesJson,
    this.openLogChannel,
    this.fallbackLocale,
  }) {
    Config.openLogChannel = this.openLogChannel ?? true;
  }

  Future<IndependentLocalization?> initialize() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    pref = await SharedPreferences.getInstance();
    Logger.log("[i] Loading Locales...");
    if (localesJson != null && localesJson!.isNotEmpty) {
      _decodedLocaleJson = {};
      for (var j in localesJson!.entries) {
        _decodedLocaleJson![j.key] = jsonDecode(j.value);
      }
    }
    Logger.log("[i] Loading fallback Locale...");
    if (fallbackLocale != null) {
      _fallbackLocale = fallbackLocale;
    } else if (fallbackLocale == null &&
        _decodedLocaleJson != null &&
        _decodedLocaleJson!.isNotEmpty)
      _fallbackLocale = _decodedLocaleJson!.entries.first.key;

    Logger.log("[i] Determining current Locale...");
    if (_currentLocale == null) {
      String? curLangCode = pref.getString("curLangCode");
      String? curCtryCode = pref.getString("curCtryCode");
      if (curLangCode != null) {
        _currentLocale = Locale(curLangCode, curCtryCode);
      } else {
        Locale? l;
        try {
          l = await Devicelocale.currentAsLocale;
        } catch (e) {}
        if (l == null) {
          l = Locale("en", "US");
        }
        if (_decodedLocaleJson != null && _decodedLocaleJson!.isNotEmpty) {
          if (!_decodedLocaleJson!.keys.contains(l)) {
            _currentLocale = _fallbackLocale;
          } else {
            _currentLocale = l;
          }
        } else {
          _currentLocale = Locale('en', 'US');
        }
      }
    }
    _instance = this;
    return _instance;
  }

  String tr(String key) {
    String? translated;
    try {
      translated = _decodedLocaleJson![_currentLocale!]![key];
    } catch (e) {
      Logger.log('[E]' + e.toString());
    }
    if (translated == null) {
      Logger.log('[E] Empty translated value');
      return key;
    } else {
      return translated;
    }
  }

  void changeLocale(Locale locale) {
    if (!_decodedLocaleJson!.containsKey(locale)) {
      throw LanguageNotDefinedException();
    } else {
      _currentLocale = locale;
      if (!_currLangStreamCtrl.isClosed) {
        _currLangStreamCtrl.add(_currentLocale);
      }
      pref.setString("curLangCode", _currentLocale!.languageCode);
      pref.setString("curCtryCode", _currentLocale!.countryCode!);
    }
  }

  void dispose() {
    _currLangStreamCtrl.close();
  }
}
