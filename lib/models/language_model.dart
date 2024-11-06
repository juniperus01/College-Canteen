import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageModel extends ChangeNotifier {
  static const String LANGUAGE_CODE = 'languageCode';
  
  // Initialize with English as default
  Locale _locale = const Locale('en');
  
  // Getter for current locale
  Locale get locale => _locale;

  // Static map of language names
  static const Map<String, String> languageNames = {
    'en': 'English',
    'hi': 'हिंदी'
  };

  // Constructor
  LanguageModel() {
    _loadLanguage();
  }

  // Load saved language preference
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? languageCode = prefs.getString(LANGUAGE_CODE);
      if (languageCode != null) {
        _locale = Locale(languageCode);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading language preference: $e');
    }
  }

  // Set new locale
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    try {
      _locale = locale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(LANGUAGE_CODE, locale.languageCode);
      notifyListeners();
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  // Get current language name
  String getCurrentLanguageName() {
    return languageNames[_locale.languageCode] ?? 'English';
  }
}