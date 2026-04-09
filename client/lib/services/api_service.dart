// services/api_service.dart — HTTP-клиент KinoVibe API

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/movie_model.dart';

class ApiService {
  static Future<SearchResult> search({
    required String query,
    String category = 'movies',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/search');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query, 'category': category}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode}');
    }
    return SearchResult.fromJson(jsonDecode(response.body));
  }

  /// Получить прямую ссылку на видеопоток по webpage_url
  static Future<String> getStreamUrl(String webpageUrl) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/stream')
        .replace(queryParameters: {'url': webpageUrl});
    final response = await http.get(uri).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Stream extraction failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body);
    final streamUrl = data['stream_url'] as String?;
    if (streamUrl == null || streamUrl.isEmpty) {
      throw Exception('Empty stream URL');
    }
    return streamUrl;
  }

  static Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/health');
      final r = await http.get(uri).timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
