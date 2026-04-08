// models/movie_model.dart

class MovieItem {
  final String title;
  final String url;
  final String thumbnail;
  final int duration;
  final int viewCount;
  final String channel;
  final String uploadDate;

  const MovieItem({
    required this.title,
    required this.url,
    required this.thumbnail,
    required this.duration,
    required this.viewCount,
    required this.channel,
    required this.uploadDate,
  });

  factory MovieItem.fromJson(Map<String, dynamic> j) => MovieItem(
    title:      j['title'] ?? '',
    url:        j['url'] ?? '',
    thumbnail:  j['thumbnail'] ?? '',
    duration:   (j['duration'] ?? 0) as int,
    viewCount:  (j['view_count'] ?? 0) as int,
    channel:    j['channel'] ?? '',
    uploadDate: j['upload_date'] ?? '',
  );

  String get durationFormatted {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class SearchResult {
  final String query;
  final String? mood;
  final String? genre;
  final String provider;
  final String category;
  final List<MovieItem> results;

  const SearchResult({
    required this.query,
    this.mood,
    this.genre,
    required this.provider,
    required this.category,
    required this.results,
  });

  factory SearchResult.fromJson(Map<String, dynamic> j) => SearchResult(
    query:    j['query'] ?? '',
    mood:     j['mood'],
    genre:    j['genre'],
    provider: j['provider'] ?? '',
    category: j['category'] ?? 'movies',
    results:  (j['results'] as List? ?? [])
        .map((e) => MovieItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
