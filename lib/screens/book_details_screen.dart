import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';
import '../services/favorites_manager.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;

  const BookDetailsScreen({Key? key, required this.book}) : super(key: key);

  @override
  _BookDetailsScreenState createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  void _checkFavoriteStatus() async {
    final isFav = await FavoritesManager.isFavorite(widget.book.id);
    setState(() {
      _isFavorite = isFav;
      _isLoadingFavorite = false;
    });
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
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails du livre'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          _isLoadingFavorite
              ? Padding(
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
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Card(
                elevation: 4,
                child: widget.book.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: widget.book.thumbnailUrl!,
                        width: 200,
                        height: 300,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 300,
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 300,
                          color: Colors.grey[300],
                          child: Icon(Icons.book, size: 64, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 200,
                        height: 300,
                        color: Colors.grey[300],
                        child: Icon(Icons.book, size: 64, color: Colors.grey),
                      ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              widget.book.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (widget.book.authors != null && widget.book.authors!.isNotEmpty)
              Text(
                'Par ${widget.book.authors!.join(', ')}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            SizedBox(height: 16),
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
            SizedBox(height: 16),
            Row(
              children: [
                if (widget.book.publishedDate != null)
                  _buildInfoItem(Icons.calendar_today, 
                      'Publié en ${widget.book.publishedDate!.split('-')[0]}'),
                if (widget.book.pageCount != null)
                  _buildInfoItem(Icons.menu_book, '${widget.book.pageCount} pages'),
                if (widget.book.averageRating != null)
                  _buildInfoItem(Icons.star, '${widget.book.averageRating}/5'),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Description',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              widget.book.description ?? 'Aucune description disponible',
              style: TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}