import 'package:flutter/material.dart';
import 'language_manager.dart';
import 'localization_manager.dart';

class LanguageDropdown extends StatefulWidget {
  final VoidCallback onLanguageChanged;

  const LanguageDropdown({required this.onLanguageChanged, super.key});

  @override
  _LanguageDropdownState createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  String selectedLanguage = LanguageManager.selectedLanguage;
  final List<String> languages = ['English', 'Tagalog', 'Cebuano'];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedLanguage,
      icon: const Icon(Icons.language, color: Colors.white),
      dropdownColor: Colors.grey[900],
      underline: Container(height: 1, color: Colors.grey),
      items: languages.map((String language) {
        return DropdownMenuItem<String>(value: language, child: Text(language));
      }).toList(),
      onChanged: (String? newValue) async {
        if (newValue != null) {
          await LanguageManager.setLanguage(newValue);
          await LocalizationManager.loadLanguage();
          setState(() {
            selectedLanguage = newValue;
          });
          widget.onLanguageChanged();
        }
      },
    );
  }
}
