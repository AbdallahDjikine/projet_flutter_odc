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
  final String? isbn;

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
    this.isbn,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    
    return Book(
      id: json['id'] as String? ?? 'unknown',
      title: volumeInfo['title'] as String? ?? 'Titre inconnu',
      authors: _parseAuthors(volumeInfo['authors']),
      description: _cleanDescription(volumeInfo['description'] as String?),
      thumbnailUrl: _extractThumbnailUrl(json['id'], volumeInfo),
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      averageRating: _parseRating(volumeInfo['averageRating']),
      categories: _parseCategories(volumeInfo['categories']),
      isbn: _extractIsbn(volumeInfo),
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
      'isbn': isbn,
    };
  }

  static Book fromCacheJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      authors: List<String>.from(json['authors'] ?? []),
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
      publishedDate: json['publishedDate'],
      pageCount: json['pageCount'],
      averageRating: json['averageRating']?.toDouble(),
      categories: List<String>.from(json['categories'] ?? []),
      isbn: json['isbn'],
    );
  }

  static String? _extractThumbnailUrl(String bookId, Map<String, dynamic>? volumeInfo) {
    if (volumeInfo == null) return null;
    
    // Essayer d'abord Open Library avec ISBN
    final isbn = _extractIsbn(volumeInfo);
    if (isbn != null && isbn.isNotEmpty) {
      final openLibraryUrl = _generateOpenLibraryUrl(isbn);
      print('🖼️ URL Open Library: $openLibraryUrl');
      return openLibraryUrl;
    }
    
    // Fallback: Google Books avec l'ID
    final googleBooksUrl = _generateGoogleBooksUrl(bookId);
    print('🖼️ URL Google Books: $googleBooksUrl');
    return googleBooksUrl;
  }

  static String? _extractIsbn(Map<String, dynamic> volumeInfo) {
    try {
      final identifiers = volumeInfo['industryIdentifiers'] as List?;
      if (identifiers != null) {
        for (final id in identifiers) {
          final type = id['type'] as String?;
          final identifier = id['identifier'] as String?;
          if (type == 'ISBN_13' && identifier != null) {
            return identifier;
          }
          if (type == 'ISBN_10' && identifier != null) {
            return identifier;
          }
        }
      }
    } catch (e) {
      print('❌ Erreur extraction ISBN: $e');
    }
    return null;
  }

  static String _generateOpenLibraryUrl(String isbn) {
    // Open Library - très fiable et accessible
    return 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg?default=false';
  }

  static String _generateGoogleBooksUrl(String bookId) {
    // Format Google Books amélioré
    return 'https://books.google.com/books/publisher/content/images/frontcover/$bookId?fife=w400-h600&source=gbs_api';
  }

  static List<String>? _parseAuthors(dynamic authors) {
    try {
      if (authors == null) return null;
      if (authors is List) {
        return List<String>.from(authors);
      }
      return [authors.toString()];
    } catch (e) {
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
      return null;
    }
  }

  static String _cleanDescription(String? raw) {
    if (raw == null) return 'Aucune description disponible';
    final withoutTags = raw.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}