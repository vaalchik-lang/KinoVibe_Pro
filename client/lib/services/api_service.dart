import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Если тестируешь на том же устройстве в браузере/linux: 127.0.0.1
  // Если через эмулятор Android: 10.0.2.2
  // Для реального устройства: впиши свой локальный IP (напр. 192.168.1.5)
  static const String baseUrl = "http://127.0.0.1:8000";

  /// Выполнение AI-поиска
  static Future<Map<String, dynamic>> search(String query, {String category = "movies"}) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/search"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": query,
          "category": category,
        }),
      ).timeout(const Duration(seconds: 45)); // Даем время для AI + yt-dlp

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      return {"error": e.toString(), "items": []};
    }
  }

  /// Получение статуса ключей (для дашборда)
  static Future<Map<String, dynamic>> getPoolStatus() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/pool/status"));
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      throw Exception("Failed to fetch pool status");
    } catch (e) {
      return {"error": e.toString()};
    }
  }

  /// Проверка здоровья сервера
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/health"));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
