import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'language_manager.dart';
import 'localization_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
  }

  // Load saved language before running the app
  await LanguageManager.loadLanguage();

  // Load translations for that language
  await LocalizationManager.loadLanguage();

  runApp(const WeCareApp());
}

class WeCareApp extends StatefulWidget {
  const WeCareApp({super.key});

  @override
  State<WeCareApp> createState() => _WeCareAppState();
}

class _WeCareAppState extends State<WeCareApp> {
  @override
  void initState() {
    super.initState();
    // Optionally, listen for language changes here if needed
  }

  Future<void> _onLanguageChanged(String newLang) async {
    await LanguageManager.setLanguage(newLang);
    await LocalizationManager.loadLanguage();
    setState(() {}); // rebuild app with new language
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WeCare',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(onLanguageChanged: _onLanguageChanged),
    );
  }
}
