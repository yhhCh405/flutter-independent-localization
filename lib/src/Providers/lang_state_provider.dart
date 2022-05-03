import 'package:flutter/material.dart';

class LanguageStateProvider extends ChangeNotifier {
  Locale currentLocale;
  LanguageStateProvider(this.currentLocale);
}
