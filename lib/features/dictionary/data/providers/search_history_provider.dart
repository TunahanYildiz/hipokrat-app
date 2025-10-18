import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadSearchHistory();
  }

  static const String _storageKey = 'search_history';
  static const int _maxHistoryItems = 20;

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_storageKey) ?? [];
      state = history;
    } catch (e) {
      print('Error loading search history: $e');
    }
  }

  Future<void> addSearchTerm(String term) async {
    if (term.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_storageKey) ?? [];
      
      // Remove existing entry if it exists
      history.remove(term);
      
      // Add to beginning
      history.insert(0, term);
      
      // Limit history size
      if (history.length > _maxHistoryItems) {
        history = history.sublist(0, _maxHistoryItems);
      }
      
      await prefs.setStringList(_storageKey, history);
      state = history;
    } catch (e) {
      print('Error adding search term: $e');
    }
  }

  Future<void> removeSearchTerm(String term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_storageKey) ?? [];
      
      history.remove(term);
      
      await prefs.setStringList(_storageKey, history);
      state = history;
    } catch (e) {
      print('Error removing search term: $e');
    }
  }

  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      state = [];
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }
}

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

