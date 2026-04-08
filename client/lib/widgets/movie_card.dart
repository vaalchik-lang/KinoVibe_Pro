// widgets/movie_card.dart — Карточка фильма (горизонтальный список)

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie_model.dart';
import '../theme/app_theme.dart';

class MovieCard extends StatelessWidget {
  final MovieItem movie;
  final VoidCallback onTap;

  const MovieCard({super.key, required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: KinoColors.cardBg,
          border: Border.all(color: KinoColors.divider),
          boxShadow: [
            BoxShadow(
              color: KinoColors.bronze.withOpacity(0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Постер
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: movie.thumbnail.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: movie.thumbnail,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        height: 100,
                        color: KinoColors.surface,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1,
                            color: KinoColors.bronze,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        color: KinoColors.surface,
                        child: const Icon(
                          Icons.movie,
                          color: KinoColors.bronze,
                          size: 32,
                        ),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: KinoColors.surface,
                      child: const Icon(
                        Icons.movie,
                        color: KinoColors.bronze,
                        size: 32,
                      ),
                    ),
            ),

            // Инфо
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: KinoColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 10, color: KinoColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        movie.durationFormatted,
                        style: const TextStyle(
                          color: KinoColors.textSecondary,
                          fontSize: 10,
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
    );
  }
}
