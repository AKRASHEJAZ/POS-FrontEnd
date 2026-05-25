class UserRoles {
  static const String admin = 'Admin';
  static const String cashier = 'Cashier';

  static const List<String> options = [admin, cashier];

  static int idFor(String role) {
    switch (role) {
      case admin:
        return 1;
      case cashier:
        return 2;
      default:
        return 2;
    }
  }

  static bool isAdmin(String? role) =>
      role != null && role.toLowerCase() == admin.toLowerCase();

  static bool isCashier(String? role) =>
      role != null && role.toLowerCase() == cashier.toLowerCase();
}
