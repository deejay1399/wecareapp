import 'dart:convert';
import 'package:flutter/services.dart';
import 'language_manager.dart';

class LocalizationManager {
  static Map<String, dynamic> _localizedStrings = {};

  static Future<void> loadLanguage() async {
    String code = _getLanguageCode(LanguageManager.selectedLanguage);
    String jsonString = await rootBundle.loadString('assets/lang/$code.json');
    _localizedStrings = json.decode(jsonString);
  }

  static String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  static String _getLanguageCode(String language) {
    switch (language) {
      case 'Tagalog':
        return 'tl';
      case 'Cebuano':
        return 'ceb';
      default:
        return 'en';
    }
  }

  static String translateWithArgs(String key, Map<String, String> args) {
    String text = translate(key);

    args.forEach((placeholder, value) {
      text = text.replaceAll('{{$placeholder}}', value);
    });

    return text;
  }
}
