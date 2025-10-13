class Book {
  final String id;
  final String title;
  final List<String>? authors;
  final String? description;
  final String? thumbnailUrl;
  final String? publishedDate;
  final int? pageCount;
  final double? averageRating;
  final List<String>? categories;

  Book({
    required this.id,
    required this.title,
    this.authors,
    this.description,
    this.thumbnailUrl,
    this.publishedDate,
    this.pageCount,
    this.averageRating,
    this.categories,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    
    return Book(
      id: json['id'] as String? ?? 'unknown',
      title: volumeInfo['title'] as String? ?? 'Titre inconnu',
      authors: _parseAuthors(volumeInfo['authors']),
      description: _cleanDescription(volumeInfo['description'] as String?),
      thumbnailUrl: _extractThumbnailUrl(volumeInfo),
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      averageRating: _parseRating(volumeInfo['averageRating']),
      categories: _parseCategories(volumeInfo['categories']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authors': authors,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'publishedDate': publishedDate,
      'pageCount': pageCount,
      'averageRating': averageRating,
      'categories': categories,
    };
  }

  static Book fromCacheJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      authors: List<String>.from(json['authors'] ?? []),
      description: _cleanDescription(json['description']),
      thumbnailUrl: json['thumbnailUrl'],
      publishedDate: json['publishedDate'],
      pageCount: json['pageCount'],
      averageRating: json['averageRating']?.toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
    );
  }

  static String? _extractThumbnailUrl(Map<String, dynamic> volumeInfo) {
    try {
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      if (imageLinks == null) {
        print('❌ Aucun imageLinks trouvé dans volumeInfo');
        return null;
      }

      print('🔍 Clés disponibles dans imageLinks: ${imageLinks.keys.toList()}');

      // Ordre de priorité pour les images
      final candidates = [
        'thumbnail',
        'smallThumbnail', 
        'medium',
        'large',
        'extraLarge',
        'small'
      ];

      for (final key in candidates) {
        final url = imageLinks[key];
        if (url is String && url.isNotEmpty) {
          print('✅ Image trouvée avec clé "$key": $url');
          return _processImageUrl(url);
        }
      }

      print('❌ Aucune URL d\'image valide trouvée dans les clés: $candidates');
      return null;
    } catch (e) {
      print('❌ Erreur lors de l\'extraction de l\'image: $e');
      return null;
    }
  }

  static String _processImageUrl(String url) {
    try {
      // Remplacer http par https
      url = url.replaceFirst('http://', 'https://');
      
      // Nettoyer l'URL des paramètres problématiques
      final uri = Uri.parse(url);
      
      // Garder seulement les paramètres essentiels
      final Map<String, String> cleanParams = {};
      if (uri.queryParameters.containsKey('fife')) {
        cleanParams['fife'] = uri.queryParameters['fife']!;
      }
      
      // Reconstruire l'URL sans les paramètres problématiques
      final cleanUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path,
        queryParameters: cleanParams.isEmpty ? null : cleanParams,
      );
      
      final processedUrl = cleanUri.toString();
      print('🔄 URL traitée: $processedUrl');
      return processedUrl;
    } catch (e) {
      print('❌ Erreur traitement URL: $e - URL originale: $url');
      return url;
    }
  }

  static List<String>? _parseAuthors(dynamic authors) {
    try {
      if (authors == null) return null;
      if (authors is List) {
        return List<String>.from(authors);
      }
      return [authors.toString()];
    } catch (e) {
      print('❌ Erreur parsing auteurs: $e');
      return null;
    }
  }

  static List<String>? _parseCategories(dynamic categories) {
    try {
      if (categories == null) return null;
      if (categories is List) {
        return List<String>.from(categories);
      }
      return [categories.toString()];
    } catch (e) {
      print('❌ Erreur parsing catégories: $e');
      return null;
    }
  }

  static double? _parseRating(dynamic rating) {
    try {
      if (rating == null) return null;
      if (rating is double) return rating;
      if (rating is int) return rating.toDouble();
      if (rating is String) return double.tryParse(rating);
      return null;
    } catch (e) {
      print('❌ Erreur parsing rating: $e');
      return null;
    }
  }

  static String _cleanDescription(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Aucune description disponible';
    }
    
    try {
      // Supprimer les balises HTML
      String cleaned = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'&[^;]+;'), ' ');
      
      // Nettoyer les espaces
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      return cleaned;
    } catch (e) {
      print('❌ Erreur nettoyage description: $e');
      return raw;
    }
  }

  @override
  String toString() {
    return 'Book{id: $id, title: $title, thumbnail: ${thumbnailUrl != null ? "OUI" : "NON"}';
  }
}