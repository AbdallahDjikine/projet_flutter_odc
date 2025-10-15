import 'package:flutter/material.dart';
import '../services/google_books_api.dart';
import '../models/book.dart';
import 'book_details_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _books = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String _lastQuery = '';

  void _searchBooks() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _lastQuery = query;
      _books.clear();
    });

    try {
      List<Book> books;
      
      if (query.split(' ').length <= 3) {
        books = await GoogleBooksApi.searchExactTitle(query);
        if (books.isEmpty) {
          books = await GoogleBooksApi.searchFrenchBooks(query);
        }
      } else {
        books = await GoogleBooksApi.searchFrenchBooks(query);
      }
      
      setState(() {
        _books = books;
        _isLoading = false;
      });
      
      if (books.isEmpty) {
        _showSnackBar('Aucun livre pertinent trouvé pour "$query".');
      } else {
        _showSnackBar('${books.length} livre(s) trouvé(s)');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Erreur de recherche: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue[700],
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSearchInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book,
            size: 60,
            color: Colors.blue[200],
          ),
          SizedBox(height: 15),
          Text(
            'Bookify',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Votre bibliothèque numérique',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
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
                SizedBox(height: 10),
                _buildTip('🔍 Titre exact', 'Ex: "Le Petit Prince"'),
                _buildTip('👤 Auteur connu', 'Ex: "Victor Hugo"'),
                _buildTip('📚 Genre littéraire', 'Ex: "Science fiction"'),
              ],
            ),
          ),
          SizedBox(height: 15),
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
            ].map((example) {
              return FilterChip(
                label: Text(
                  example,
                  style: TextStyle(fontSize: 12),
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
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 6),
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
                SizedBox(height: 1),
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

  Widget _buildBookGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.55, // Ratio plus étroit pour des cartes plus petites
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return _buildBookGridItem(book);
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1400) return 6;  // Grand desktop
    if (screenWidth > 1200) return 5;  // Desktop
    if (screenWidth > 900) return 4;   // Large tablet
    if (screenWidth > 600) return 3;   // Tablet
    return 2; // Mobile
  }

  Widget _buildBookGridItem(Book book) {
    return Card(
      elevation: 2,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image du livre - plus petite
            Container(
              height: 120, // Hauteur réduite
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                child: _buildBookImage(book),
              ),
            ),
            // Contenu texte
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Titre
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    // Auteur
                    if (book.authors != null && book.authors!.isNotEmpty)
                      Text(
                        book.authors!.first,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    // Espace flexible
                    Spacer(),
                    // Rating et année
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (book.averageRating != null)
                          Row(
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.amber),
                              SizedBox(width: 1),
                              Text(
                                book.averageRating!.toStringAsFixed(1),
                                style: TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        if (book.publishedDate != null)
                          Text(
                            _formatYear(book.publishedDate!),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage(Book book) {
    if (book.thumbnailUrl == null || book.thumbnailUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        height: 120,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 24, color: Colors.grey[400]),
            SizedBox(height: 4),
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

    return Container(
      width: double.infinity,
      height: 120,
      child: Image.network(
        book.thumbnailUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
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
                SizedBox(height: 4),
                Text(
                  'Image\nindisponible',
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
      ),
    );
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
        title: Text(
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
          // Barre de recherche compacte
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un livre...',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[700], size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onSubmitted: (_) => _searchBooks(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.search, color: Colors.white, size: 18),
                    onPressed: _searchBooks,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
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
                        SizedBox(height: 12),
                        Text(
                          'Recherche en cours...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 6),
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
                                SizedBox(height: 12),
                                Text(
                                  'Aucun résultat',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Pour "$_lastQuery"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                SizedBox(height: 16),
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
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  ),
                                  child: Text(
                                    'Nouvelle recherche',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildBookGrid()
                    : SingleChildScrollView(
                        child: _buildSearchInfo(),
                      ),
          ),
        ],
      ),
    );
  }
}