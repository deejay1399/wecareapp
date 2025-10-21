import 'dart:convert';
import 'package:flutter/services.dart';
import 'language_manager.dart';

class LocalizationManager {
  static Map<String, dynamic> _localizedStrings = {};
  static String _currentCode = 'en';

  /// Load the JSON file for the currently selected language
  static Future<void> loadLanguage() async {
    try {
      _currentCode = _getLanguageCode(LanguageManager.selectedLanguage);
      final String jsonString = await rootBundle.loadString(
        'assets/lang/$_currentCode.json',
      );
      _localizedStrings = json.decode(jsonString);
    } catch (e) {
      // fallback to English if file missing or error
      print('⚠️ Error loading language file ($_currentCode): $e');
      final String jsonString = await rootBundle.loadString(
        'assets/lang/en.json',
      );
      _localizedStrings = json.decode(jsonString);
      _currentCode = 'en';
    }
  }

  /// Main translation method with optional params for interpolation
  static String translate(String key, {Map<String, String>? params}) {
    if (_localizedStrings.isEmpty) {
      // Return key if localization not loaded yet
      return key;
    }

    String translation = _localizedStrings[key] ?? key;

    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }

    return translation;
  }

  /// Legacy compatibility wrapper
  static String translateWithArgs(String key, Map<String, String> args) {
    return translate(key, params: args);
  }

  /// Converts readable language name to code
  static String _getLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case 'tagalog':
        return 'tl';
      case 'cebuano':
      case 'ceb':
        return 'ceb';
      case 'english':
      case 'en':
      default:
        return 'en';
    }
  }

  /// Get the current language code
  static String get currentLanguageCode => _currentCode;
}
