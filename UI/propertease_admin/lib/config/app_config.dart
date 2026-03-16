class AppConfig {
  static String get serverBase => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
      );

  static String get apiBase => '$serverBase/api/';
}
