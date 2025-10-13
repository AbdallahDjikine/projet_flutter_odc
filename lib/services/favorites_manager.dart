import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class FavoritesManager {
  static const String _favoritesKey = 'favorites_books';

  static Future<void> addToFavorites(Book book) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    final bookJson = json.encode(book.toJson());
    
    if (!favorites.contains(bookJson)) {
      favorites.add(bookJson);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  static Future<void> removeFromFavorites(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    favorites.removeWhere((bookJson) {
      final bookMap = json.decode(bookJson);
      return bookMap['id'] == bookId;
    });
    
    await prefs.setStringList(_favoritesKey, favorites);
  }

  static Future<bool> isFavorite(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    return favorites.any((bookJson) {
      final bookMap = json.decode(bookJson);
      return bookMap['id'] == bookId;
    });
  }

  static Future<List<Book>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    
    return favorites.map((bookJson) {
      final bookMap = json.decode(bookJson);
      return Book.fromCacheJson(bookMap);
    }).toList();
  }

  static Future<void> toggleFavorite(Book book) async {
    final isFav = await isFavorite(book.id);
    if (isFav) {
      await removeFromFavorites(book.id);
    } else {
      await addToFavorites(book);
    }
  }
}