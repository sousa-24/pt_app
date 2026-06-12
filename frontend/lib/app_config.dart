class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static String get wsBaseUrl {
    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    if (apiBaseUrl.startsWith('http://')) {
      return apiBaseUrl.replaceFirst('http://', 'ws://');
    }
    return apiBaseUrl;
  }

  static Uri apiUri(String endpoint) => Uri.parse('$apiBaseUrl$endpoint');

  static Uri websocketUri({required int userId, required String token}) {
    return Uri.parse('$wsBaseUrl/ws/$userId?token=$token');
  }
}
