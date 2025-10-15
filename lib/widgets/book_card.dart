import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookCard({
    Key? key,
    required this.book,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container image
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey[200],
                ),
                child: _buildBookImage(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (book.authors != null && book.authors!.isNotEmpty)
                      Text(
                        'Par ${book.authors!.join(', ')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    if (book.publishedDate != null)
                      Text(
                        'Publié: ${_formatPublishedDate(book.publishedDate!)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    if (book.averageRating != null)
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '${book.averageRating!.toStringAsFixed(1)}/5',
                            style: TextStyle(fontSize: 12),
                          ),
                          if (book.isbn != null) ...[
                            SizedBox(width: 8),
                            Text(
                              '• ISBN: ${book.isbn}',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
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

  Widget _buildBookImage() {
    if (book.thumbnailUrl == null || book.thumbnailUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: book.thumbnailUrl!,
        width: 80,
        height: 120,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, downloadProgress) => 
            _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) {
          print('❌ Erreur chargement image: $url');
          return _buildErrorPlaceholder();
        },
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
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
          Icon(Icons.book, color: Colors.grey[500], size: 30),
          SizedBox(height: 4),
          Text(
            'Image\nindisponible',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
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
          Icon(Icons.menu_book, color: Colors.grey[500], size: 30),
          SizedBox(height: 4),
          Text(
            'Pas de\ncouverture',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPublishedDate(String date) {
    try {
      if (RegExp(r'^\d{4}$').hasMatch(date)) {
        return date;
      }
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(date)) {
        return date.split('-')[0];
      }
      final parsedDate = DateTime.tryParse(date);
      if (parsedDate != null) {
        return '${parsedDate.year}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }
}