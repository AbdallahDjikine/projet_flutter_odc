import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksApi {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const int _maxResults = 20;

  static Future<List<Book>> searchBooks(String query, {int startIndex = 0}) async {
    if (query.isEmpty) return [];

    final url = '$_baseUrl?q=${Uri.encodeQueryComponent(query)}&maxResults=$_maxResults&startIndex=$startIndex';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List?;
        
        if (items == null) return [];
        
        return items.map((item) => Book.fromJson(item)).toList();
      } else {
        throw Exception('Erreur de chargement: ${response.statusCode}');
      }
    } catch (e) {
      log('Erreur API: $e');
      throw Exception('Erreur de connexion. Vérifiez votre connexion internet.');
    }
  }

  static Future<Book?> getBookDetails(String bookId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$bookId'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Book.fromJson(data);
      }
      return null;
    } catch (e) {
      log('Erreur détail livre: $e');
      return null;
    }
  }
}