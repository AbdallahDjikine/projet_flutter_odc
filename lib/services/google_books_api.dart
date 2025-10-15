import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class GoogleBooksApi {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';
  static const Duration _timeoutDuration = Duration(seconds: 15);

  static Future<List<Book>> searchBooks(String query, {int maxResults = 10}) async {
    if (query.isEmpty) return [];

    // Nettoyer et formater la requête pour plus de pertinence
    final cleanedQuery = _cleanSearchQuery(query);
    
    // Stratégies de recherche par ordre de pertinence
    final searchStrategies = [
      'intitle:"$cleanedQuery"', // Titre exact
      'intitle:$cleanedQuery', // Titre approximatif
      '$cleanedQuery+subject:french', // Sujet français
      cleanedQuery, // Recherche générale
    ];

    for (final strategy in searchStrategies) {
      final encodedQuery = Uri.encodeQueryComponent(strategy);
      final url = '$_baseUrl?q=$encodedQuery&maxResults=$maxResults&printType=books&orderBy=relevance';
      
      print('🔍 Essai recherche: $strategy');
      
      try {
        final response = await http.get(
          Uri.parse(url),
        ).timeout(_timeoutDuration);
        
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final items = data['items'] as List?;
          
          if (items != null && items.isNotEmpty) {
            final books = <Book>[];
            for (var item in items) {
              try {
                final book = Book.fromJson(item);
                
                // Filtrer les résultats non pertinents
                if (_isRelevantResult(book, cleanedQuery)) {
                  books.add(book);
                }
              } catch (e) {
                continue;
              }
            }
            
            if (books.isNotEmpty) {
              print('✅ ${books.length} livres pertinents trouvés avec: $strategy');
              return books;
            }
          }
        }
      } catch (e) {
        print('❌ Erreur avec stratégie $strategy: $e');
        continue;
      }
    }
    
    return [];
  }

  // Nettoyer la requête de recherche
  static String _cleanSearchQuery(String query) {
    // Supprimer la ponctuation et les caractères spéciaux
    var cleaned = query.replaceAll(RegExp(r'[^\w\s]'), ' ');
    // Supprimer les espaces multiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    // Mettre en minuscules pour la comparaison
    return cleaned.toLowerCase();
  }

  // Vérifier si le résultat est pertinent
  static bool _isRelevantResult(Book book, String originalQuery) {
    final queryWords = originalQuery.split(' ');
    final title = book.title.toLowerCase();
    final authors = book.authors?.join(' ')?.toLowerCase() ?? '';
    
    // Vérifier la correspondance avec le titre
    int titleMatches = 0;
    for (final word in queryWords) {
      if (word.length > 2 && title.contains(word)) {
        titleMatches++;
      }
    }
    
    // Si au moins 50% des mots correspondent au titre, c'est pertinent
    final titleRelevance = titleMatches / queryWords.length >= 0.5;
    
    // Vérifier la correspondance avec les auteurs
    bool authorMatch = false;
    for (final word in queryWords) {
      if (word.length > 2 && authors.contains(word)) {
        authorMatch = true;
        break;
      }
    }
    
    return titleRelevance || authorMatch;
  }

  static Future<List<Book>> searchFrenchBooks(String query) async {
    // Réduire le nombre de résultats pour plus de pertinence
    return searchBooks(query, maxResults: 15);
  }

  // Méthode pour la recherche par titre exact
  static Future<List<Book>> searchExactTitle(String title) async {
    final encodedQuery = Uri.encodeQueryComponent('intitle:"$title"');
    final url = '$_baseUrl?q=$encodedQuery&maxResults=5&printType=books';
    
    try {
      final response = await http.get(Uri.parse(url)).timeout(_timeoutDuration);
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final items = data['items'] as List?;
        
        if (items == null) return [];
        
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
      }
    } catch (e) {
      print('❌ Erreur recherche titre exact: $e');
    }
    
    return [];
  }
}