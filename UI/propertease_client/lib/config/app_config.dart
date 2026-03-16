class AppConfig {
  static String get serverBase => const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://192.168.0.5:5028',
      );

  static String get apiBase => '$serverBase/api/';
}
