import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorite_item.dart';

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  static const String _storageKey = 'favorite_terms';

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteEntries = prefs.getStringList(_storageKey) ?? [];
      
      final favorites = favoriteEntries
          .map((entry) => FavoriteItem.fromStorageString(entry))
          .where((item) => item.term.isNotEmpty)
          .toList();
      
      state = favorites;
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  Future<void> addFavorite(String term, String definition) async {
    if (term.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteEntries = prefs.getStringList(_storageKey) ?? [];
      
      // Remove existing entry if it exists
      favoriteEntries.removeWhere((entry) => entry.startsWith('$term|'));
      
      // Add new entry
      final newEntry = FavoriteItem(term: term, definition: definition).toStorageString();
      favoriteEntries.insert(0, newEntry);
      
      // Limit to 50 favorites
      if (favoriteEntries.length > 50) {
        favoriteEntries.removeRange(50, favoriteEntries.length);
      }
      
      await prefs.setStringList(_storageKey, favoriteEntries);
      
      // Update state
      final favorites = favoriteEntries
          .map((entry) => FavoriteItem.fromStorageString(entry))
          .where((item) => item.term.isNotEmpty)
          .toList();
      
      state = favorites;
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  Future<void> removeFavorite(String term) async {
    if (term.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteEntries = prefs.getStringList(_storageKey) ?? [];
      
      // Remove the entry
      favoriteEntries.removeWhere((entry) => entry.startsWith('$term|'));
      
      await prefs.setStringList(_storageKey, favoriteEntries);
      
      // Update state
      final favorites = favoriteEntries
          .map((entry) => FavoriteItem.fromStorageString(entry))
          .where((item) => item.term.isNotEmpty)
          .toList();
      
      state = favorites;
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  Future<void> clearAllFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      state = [];
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  Future<bool> isFavorited(String term) async {
    if (term.isEmpty) return false;
    return state.any((item) => item.term == term);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, List<FavoriteItem>>((ref) {
  return FavoritesNotifier();
});

final isFavoritedProvider = FutureProvider.family<bool, String>((ref, term) async {
  final favoritesNotifier = ref.read(favoritesProvider.notifier);
  return await favoritesNotifier.isFavorited(term);
});
