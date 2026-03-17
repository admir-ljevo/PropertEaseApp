class AppConfig {
  static String get serverBase => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:5000',
      );

  static String get apiBase => '$serverBase/api/';
}
