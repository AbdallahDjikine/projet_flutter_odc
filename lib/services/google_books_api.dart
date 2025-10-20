import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksApi {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const int maxResults = 40; // Changé de _maxResults à maxResults (public)
  static const Duration _timeoutDuration = Duration(seconds: 15);

  static Future<List<Book>> searchBooks(String query, {int startIndex = 0}) async {
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeQueryComponent(query);
    final url = '$_baseUrl?q=$encodedQuery&maxResults=$maxResults&startIndex=$startIndex&printType=books';
    
    print('🔍 Recherche API: $url');
    
    try {
      final response = await http.get(
        Uri.parse(url),
      ).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List?;
        
        if (items == null) {
          return [];
        }
        
        final books = <Book>[];
        for (var item in items) {
          try {
            final book = Book.fromJson(item);
            books.add(book);
          } catch (e) {
            continue;
          }
        }
        
        return books;
      } else {
        throw Exception('Erreur de chargement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  static Future<List<Book>> searchFrenchBooks(String query, {int startIndex = 0}) async {
    final encodedQuery = Uri.encodeQueryComponent('$query lang:fr');
    final url = '$_baseUrl?q=$encodedQuery&maxResults=$maxResults&startIndex=$startIndex&printType=books';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List?;
        
        if (items == null) return [];
        
        return items.map((item) => Book.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Book>> searchExactTitle(String query, {int startIndex = 0}) async {
    final encodedQuery = Uri.encodeQueryComponent('intitle:$query');
    final url = '$_baseUrl?q=$encodedQuery&maxResults=$maxResults&startIndex=$startIndex&printType=books';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List?;
        
        if (items == null) return [];
        
        return items.map((item) => Book.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Ajout des méthodes manquantes
  static Future<Map<String, dynamic>> getReadingButtonInfo(String bookId) async {
    // Simulation - à implémenter selon vos besoins
    return {
      'hasPreview': true,
      'webReaderLink': 'https://books.google.com/books?id=$bookId&hl=fr',
    };
  }

  static Future<String?> getBestReadingUrl(String bookId) async {
    // Simulation - à implémenter selon vos besoins
    return 'https://books.google.com/books?id=$bookId&hl=fr';
  }
}