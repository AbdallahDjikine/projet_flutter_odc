import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/google_books_api.dart';
import '../services/cache_service.dart';
import '../models/book.dart';
import 'book_details_screen.dart';
import '../widgets/book_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Book> _books = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _currentQuery = '';
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    CacheService.clearOldCache();
  }

  void _searchBooks({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _hasSearched = true;
        _currentPage = 0;
        _books.clear();
      });
    }

    try {
      List<Book> books;
      
      if (!loadMore) {
        final cachedResults = await CacheService.getCachedSearchResults(_searchController.text);
        if (cachedResults != null) {
          books = cachedResults;
        } else {
          books = await GoogleBooksApi.searchBooks(_searchController.text, startIndex: _currentPage * 20);
          await CacheService.cacheSearchResults(_searchController.text, books);
        }
      } else {
        books = await GoogleBooksApi.searchBooks(_currentQuery, startIndex: _currentPage * 20);
      }

      setState(() {
        if (loadMore) {
          _books.addAll(books);
        } else {
          _books.clear();
          _books.addAll(books);
          _currentQuery = _searchController.text;
        }
        _hasMore = books.length == 20;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar(e.toString());
    }
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      setState(() {
        _currentPage++;
      });
      _searchBooks(loadMore: true);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookify - Bibliothèque numérique'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un livre...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onSubmitted: (_) => _searchBooks(),
            ),
          ),
          if (_isLoading && _books.isEmpty)
            Center(child: CircularProgressIndicator()),
          if (!_isLoading && _hasSearched && _books.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun livre trouvé',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          if (_books.isNotEmpty)
            Expanded(
              child: AnimationLimiter(
                child: ListView.builder(
                  itemCount: _books.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _books.length) {
                      return _hasMore 
                          ? Center(child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ))
                          : SizedBox.shrink();
                    }
                    
                    final book = _books[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 500),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: BookCard(
                            book: book,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsScreen(book: book),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _searchController.text.isNotEmpty
          ? FloatingActionButton(
              onPressed: _searchBooks,
              child: Icon(Icons.search),
              backgroundColor: Colors.blue[700],
            )
          : null,
    );
  }
}