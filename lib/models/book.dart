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
  final String? previewLink;

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
    this.previewLink,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final volumeInfo = json['volumeInfo'] as Map<String, dynamic>? ?? {};
    
    // Extraction de l'ISBN pour Open Library
    String? isbn;
    final identifiers = volumeInfo['industryIdentifiers'] as List?;
    if (identifiers != null) {
      for (final id in identifiers) {
        final type = id['type'] as String?;
        final identifier = id['identifier'] as String?;
        if ((type == 'ISBN_13' || type == 'ISBN_10') && identifier != null) {
          isbn = identifier;
          break;
        }
      }
    }

    return Book(
      id: json['id'] as String? ?? 'unknown',
      title: volumeInfo['title'] as String? ?? 'Titre inconnu',
      authors: _parseAuthors(volumeInfo['authors']),
      description: _cleanDescription(volumeInfo['description'] as String?),
      thumbnailUrl: _generateReliableImageUrl(isbn, json['id']),
      publishedDate: volumeInfo['publishedDate'] as String?,
      pageCount: volumeInfo['pageCount'] as int?,
      averageRating: _parseRating(volumeInfo['averageRating']),
      categories: _parseCategories(volumeInfo['categories']),
      isbn: isbn,
      previewLink: volumeInfo['previewLink'] as String?,
    );
  }

  static String? _generateReliableImageUrl(String? isbn, String bookId) {
    // TOUJOURS utiliser Open Library en priorité
    if (isbn != null && isbn.isNotEmpty) {
      final openLibraryUrl = 'https://covers.openlibrary.org/b/isbn/$isbn-M.jpg';
      print('🖼️ URL Open Library: $openLibraryUrl');
      return openLibraryUrl;
    }

    // Si pas d'ISBN, utiliser Google Books mais avec un format simple
    final googleBooksUrl = 'https://books.google.com/books/publisher/content/images/frontcover/$bookId?fife=w400-h600';
    print('🖼️ URL Google Books (fallback): $googleBooksUrl');
    return googleBooksUrl;
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
      'previewLink': previewLink,
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
      previewLink: json['previewLink'],
    );
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