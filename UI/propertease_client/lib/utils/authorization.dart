class Authorization {
  static String? token;
  static int? userId;
  static String? username;
  static String? role;
  static int? roleId;
  static String? firstName;
  static String? lastName;
  static String? profilePhotoBytes;

  static bool get isLoggedIn => token != null && token!.isNotEmpty;

  static String get displayName {
    final parts = [firstName, lastName]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.join(' ') : (username ?? '');
  }

  static void clear() {
    token = null;
    userId = null;
    username = null;
    role = null;
    roleId = null;
    firstName = null;
    lastName = null;
    profilePhotoBytes = null;
  }
}
