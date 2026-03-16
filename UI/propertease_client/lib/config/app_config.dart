class AppConfig {
  static String get serverBase => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:5028',
      );

  static String get apiBase => '$serverBase/api/';
}
