import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';

class CacheService {
  static const String _searchCacheKey = 'search_cache';
  static const Duration _cacheDuration = Duration(days: 7);

  static Future<void> cacheSearchResults(String query, List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = prefs.getString(_searchCacheKey) ?? '{}';
    final Map<String, dynamic> cache = json.decode(cacheData);
    
    cache[query] = {
      'books': books.map((book) => book.toJson()).toList(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_searchCacheKey, json.encode(cache));
  }

  static Future<List<Book>?> getCachedSearchResults(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = prefs.getString(_searchCacheKey);
    
    if (cacheData != null) {
      final Map<String, dynamic> cache = json.decode(cacheData);
      
      if (cache.containsKey(query)) {
        final cachedResult = cache[query];
        final timestamp = cachedResult['timestamp'] as int;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        if (DateTime.now().difference(cacheTime) < _cacheDuration) {
          final booksJson = cachedResult['books'] as List;
          return booksJson.map((bookJson) => Book.fromCacheJson(bookJson)).toList();
        }
      }
    }
    
    return null;
  }

  static Future<void> clearOldCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = prefs.getString(_searchCacheKey);
    
    if (cacheData != null) {
      final Map<String, dynamic> cache = json.decode(cacheData);
      final now = DateTime.now();
      
      cache.removeWhere((key, value) {
        final timestamp = value['timestamp'] as int;
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return now.difference(cacheTime) > _cacheDuration;
      });
      
      await prefs.setString(_searchCacheKey, json.encode(cache));
    }
  }
}