import 'package:flutter/material.dart';
import '../services/google_books_api.dart';
import '../models/book.dart';
import 'book_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Book> _books = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasSearched = false;
  String _lastQuery = '';
  int _currentPage = 0;
  bool _hasMore = true;
  int _totalItems = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isLoadingMore) {
      _loadMoreBooks();
    }
  }

  void _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
      _books.clear();
      _currentPage = 0;
      _hasMore = true;
      _totalItems = 0;
    });

    try {
      List<Book> books = await GoogleBooksApi.searchBooks(query, startIndex: 0);
      
      setState(() {
        _books = books;
        _isLoading = false;
        _hasMore = books.length == GoogleBooksApi.maxResults; // Correction ici
        _totalItems = books.length;
      });
      
      if (books.isEmpty) {
        _showSnackBar('Aucun livre trouvé pour "$query".');
      } else {
        _showSnackBar('${books.length} livre(s) trouvé(s) - Défilez pour plus de résultats');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de recherche: $e');
    }
  }

  void _loadMoreBooks() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final startIndex = nextPage * GoogleBooksApi.maxResults; // Correction ici
      
      final moreBooks = await GoogleBooksApi.searchBooks(_lastQuery, startIndex: startIndex);
      
      setState(() {
        _books.addAll(moreBooks);
        _isLoadingMore = false;
        _currentPage = nextPage;
        _hasMore = moreBooks.length == GoogleBooksApi.maxResults; // Correction ici
        _totalItems = _books.length;
      });

      if (moreBooks.isEmpty) {
        _showSnackBar('Tous les résultats ont été chargés');
      }
    } catch (e) {
      setState(() => _isLoadingMore = false);
      _showSnackBar('Erreur lors du chargement supplémentaire');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ... (le reste du code de _buildSearchInfo, _buildTip, etc. reste identique)

  Widget _buildSearchInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 60,
            color: Colors.blue[200],
          ),
          const SizedBox(height: 15),
          Text(
            'Bookify',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Votre bibliothèque numérique',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 Conseils de recherche',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800], 
                  ),
                ),
                const SizedBox(height: 10),
                _buildTip('🔍 Titre exact', 'Ex: "Le Petit Prince"'),
                _buildTip('👤 Auteur connu', 'Ex: "Victor Hugo"'),
                _buildTip('📚 Genre littéraire', 'Ex: "Science fiction"'),
                _buildTip('🔄 Défilement infini', 'Descendez pour plus de résultats'),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              'Harry Potter',
              'Stephen King', 
              'Amour',
              'Policier',
              'Jules Verne',
              'Mystère',
              'Science fiction',
              'Romance',
            ].map((example) {
              return FilterChip(
                label: Text(
                  example,
                  style: const TextStyle(fontSize: 12),
                ),
                onSelected: (_) {
                  _searchController.text = example;
                  _searchBooks();
                },
                backgroundColor: Colors.white,
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[700],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList() {
    return Column(
      children: [
        if (_books.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_totalItems livre(s) trouvé(s)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
                if (_hasMore)
                  Text(
                    'Défilez pour plus de résultats ↓',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
              ],
            ),
          ),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _books.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _books.length) {
                return _buildLoadingMoreIndicator();
              }
              final book = _books[index];
              return _buildBookListItem(book);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Chargement de plus de résultats...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookListItem(Book book) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailsScreen(book: book),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildBookImage(book),
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    if (book.authors != null && book.authors!.isNotEmpty)
                      Text(
                        book.authors!.join(', '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 6),
                    
                    if (book.description != null && book.description!.isNotEmpty)
                      Text(
                        _truncateDescription(book.description!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (book.averageRating != null)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                book.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        
                        if (book.publishedDate != null)
                          Text(
                            _formatYear(book.publishedDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        
                        if (book.pageCount != null)
                          Text(
                            '${book.pageCount} p.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookImage(Book book) {
    if (book.thumbnailUrl == null || book.thumbnailUrl!.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 24, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              'Pas de\ncouverture',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Image.network(
      book.thumbnailUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 24, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'Erreur\nimage',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _truncateDescription(String description) {
    if (description.length <= 100) return description;
    return '${description.substring(0, 100)}...';
  }

  String _formatYear(String date) {
    try {
      if (RegExp(r'^\d{4}$').hasMatch(date)) return date;
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(date)) return date.split('-')[0];
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate != null) return '${parsedDate.year}';
      return date;
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Bookify',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un livre, auteur ou genre...',
                      hintStyle: const TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[700], size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 18),
                    onPressed: _searchBooks,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(color: Colors.blue[700]),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Recherche en cours...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$_lastQuery"',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : _hasSearched
                    ? _books.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun résultat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pour "$_lastQuery"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _hasSearched = false;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[700],
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  ),
                                  child: const Text(
                                    'Nouvelle recherche',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildBookList()
                    : SingleChildScrollView(
                        child: _buildSearchInfo(),
                      ),
          ),
        ],
      ),
    );
  }
}