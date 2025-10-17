import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'localization_manager.dart';

class LanguageManager {
  static String selectedLanguage = 'English';
  // Notifier used by dashboard/bottom nav to rebuild when translations are ready
  static final ValueNotifier<String> selectedLanguageNotifier = ValueNotifier(
    selectedLanguage,
  );

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    // Ensure LocalizationManager has loaded translations for the selected language
    await LocalizationManager.loadLanguage();
    selectedLanguageNotifier.value = selectedLanguage;
  }

  static Future<void> setLanguage(String language) async {
    if (language == selectedLanguage) return;
    selectedLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
    // Load translations for the newly selected language BEFORE notifying listeners
    await LocalizationManager.loadLanguage();
    selectedLanguageNotifier.value = selectedLanguage;
  }
}
