import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current locale and persists the user's choice.
class LocaleController extends ChangeNotifier {
  static const _localeKey = 'app_locale';

  Locale _locale = const Locale('pt');

  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    final next = _locale.languageCode == 'pt'
        ? const Locale('en')
        : const Locale('pt');
    await setLocale(next);
  }
}
