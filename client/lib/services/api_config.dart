// services/api_config.dart — Переключалка: Termux ↔ Yandex Cloud

class ApiConfig {
  // Локальный сервер (Termux на телефоне)
  static const String local = 'http://127.0.0.1:8000';

  // Внешний сервер (Yandex Cloud VM)
  // Замени <PUBLIC_IP> на реальный IP после деплоя
  static const String remote = 'http://<PUBLIC_IP>:8000';

  // Переключение через --dart-define=USE_REMOTE=true при сборке
  // flutter build apk --dart-define=USE_REMOTE=true
  static String get baseUrl =>
      const bool.fromEnvironment('USE_REMOTE', defaultValue: false)
          ? remote
          : local;
}
