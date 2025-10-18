import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  static const String _definitionLengthKey = 'definition_length';
  static const String _showDifficultyBarKey = 'show_difficulty_bar';
  static const String _isDarkModeKey = 'is_dark_mode';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final definitionLength = prefs.getDouble(_definitionLengthKey) ?? 1.0;
      final showDifficultyBar = prefs.getBool(_showDifficultyBarKey) ?? true;
      final isDarkMode = prefs.getBool(_isDarkModeKey) ?? false;
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        print('Warning: GEMINI_API_KEY not found in .env file');
      }

      state = AppSettings(
        definitionLength: definitionLength,
        apiKey: apiKey,
        showDifficultyBar: showDifficultyBar,
        isDarkMode: isDarkMode,
      );
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> updateDefinitionLength(double length) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_definitionLengthKey, length);

      state = state.copyWith(definitionLength: length);
    } catch (e) {
      print('Error updating definition length: $e');
    }
  }

  Future<void> updateApiKey(String? apiKey) async {
    state = state.copyWith(apiKey: apiKey);
  }

  Future<void> updateShowDifficultyBar(bool show) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showDifficultyBarKey, show);

      state = state.copyWith(showDifficultyBar: show);
    } catch (e) {
      print('Error updating show difficulty bar: $e');
    }
  }

  Future<void> updateDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isDarkModeKey, isDark);

      state = state.copyWith(isDarkMode: isDark);
    } catch (e) {
      print('Error updating dark mode: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
