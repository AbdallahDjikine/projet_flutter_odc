import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/book.dart';
import '../services/favorites_manager.dart';
import '../services/google_books_api.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({super.key, required this.book});

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isLoadingReadingUrl = false;
  String? _readingUrl;
  String _buttonText = 'Vérification du contenu...';
  Color _buttonColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadReadingUrl();
  }

  void _checkFavoriteStatus() async {
    final isFav = await FavoritesManager.isFavorite(widget.book.id);
    setState(() {
      _isFavorite = isFav;
      _isLoadingFavorite = false;
    });
  }

  void _loadReadingUrl() async {
    setState(() {
      _isLoadingReadingUrl = true;
      _buttonText = 'Vérification du contenu...';
      _buttonColor = Colors.grey;
    });

    try {
      // Utilisation des nouvelles méthodes que nous avons ajoutées
      final buttonInfo = await GoogleBooksApi.getReadingButtonInfo(widget.book.id);
      final bestUrl = await GoogleBooksApi.getBestReadingUrl(widget.book.id);
      
      setState(() {
        _readingUrl = bestUrl;
        _buttonText = buttonInfo['text'] ?? 'Lire le livre';
        _buttonColor = _getButtonColor(buttonInfo['color']);
      });
    } catch (e) {
      print('❌ Erreur chargement URL: $e');
      setState(() {
        _buttonText = '❌ Contenu non disponible';
        _buttonColor = Colors.grey;
      });
    } finally {
      setState(() {
        _isLoadingReadingUrl = false;
      });
    }
  }

  Color _getButtonColor(String? color) {
    switch (color) {
      case 'green':
        return Colors.green[700]!;
      case 'blue':
        return Colors.blue[700]!;
      case 'orange':
        return Colors.orange[700]!;
      case 'purple':
        return Colors.purple[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  void _toggleFavorite() async {
    setState(() {
      _isLoadingFavorite = true;
    });
    
    await FavoritesManager.toggleFavorite(widget.book);
    
    final newStatus = await FavoritesManager.isFavorite(widget.book.id);
    setState(() {
      _isFavorite = newStatus;
      _isLoadingFavorite = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openReadingUrl() async {
    if (_readingUrl == null) {
      _showError('Aucun contenu disponible pour ce livre');
      return;
    }

    print('🔄 Ouverture de: $_readingUrl');
    
    try {
      final Uri uri = Uri.parse(_readingUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        print('✅ URL ouverte avec succès');
      } else {
        _showError('Impossible d\'ouvrir le contenu');
      }
    } catch (e) {
      print('❌ Erreur ouverture: $e');
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du livre'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          _isLoadingFavorite
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Image
            Center(
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    child: SizedBox(
                      width: 200,
                      height: 300,
                      child: _buildBookImage(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Bouton principal de lecture
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingReadingUrl ? null : _openReadingUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: _isLoadingReadingUrl
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Chargement...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.menu_book, size: 24),
                                const SizedBox(width: 12),
                                Text(_buttonText),
                              ],
                            ),
                    ),
                  ),
                  
                  // Indicateur de statut
                  const SizedBox(height: 12),
                  _buildAccessStatus(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Informations du livre
            _buildBookInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessStatus() {
    if (_isLoadingReadingUrl) {
      return Text(
        'Recherche du contenu disponible...',
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      );
    }

    if (_readingUrl == null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.orange),
          const SizedBox(height: 8),
          const Text(
            'Contenu limité ou protégé',
            style: TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Essayez les bibliothèques ou librairies',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        const Icon(Icons.check_circle, size: 40, color: Colors.green),
        const SizedBox(height: 8),
        const Text(
          'Contenu disponible !',
          style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Cliquez sur le bouton pour lire',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBookInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.book.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        if (widget.book.authors != null && widget.book.authors!.isNotEmpty)
          Text(
            'Par ${widget.book.authors!.join(', ')}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
        
        const SizedBox(height: 16),
        
        if (widget.book.categories != null && widget.book.categories!.isNotEmpty)
          Wrap(
            spacing: 8,
            children: widget.book.categories!
                .map((category) => Chip(
                      label: Text(category),
                      backgroundColor: Colors.blue[50],
                    ))
                .toList(),
          ),
        
        const SizedBox(height: 16),
        
        // Métadonnées
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            if (widget.book.publishedDate != null)
              _buildInfoItem(Icons.calendar_today, _formatYear(widget.book.publishedDate!)),
            if (widget.book.pageCount != null)
              _buildInfoItem(Icons.menu_book, '${widget.book.pageCount} pages'),
            if (widget.book.averageRating != null)
              _buildInfoItem(Icons.star, '${widget.book.averageRating}/5'),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Description
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.book.description ?? 'Aucune description disponible',
          style: const TextStyle(fontSize: 16, height: 1.5),
          textAlign: TextAlign.justify,
        ),
      ],
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

  Widget _buildBookImage() {
    if (widget.book.thumbnailUrl == null || widget.book.thumbnailUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return Image.network(
      widget.book.thumbnailUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              'Chargement...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Image non disponible',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Pas de couverture',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
      ],
    );
  }
}