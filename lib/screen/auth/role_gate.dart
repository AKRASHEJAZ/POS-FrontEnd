import 'package:flutter/material.dart';
import 'package:web_end/constants/user_roles.dart';
import 'package:web_end/screen/auth/login.dart';
import 'package:web_end/screen/cashier/cashier_shell.dart';
import 'package:web_end/services/auth/auth_service.dart';
import 'package:web_end/services/storage/token_storage.dart';
import 'package:web_end/services/user/user_service.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/sideBar.dart';

/// Routes authenticated users to Admin or Cashier home based on role.
class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  final _userService = UserService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _resolveHome();
  }

  Future<void> _resolveHome() async {
    final hasToken = await TokenStorage.hasToken();
    if (!hasToken) {
      _go(const LoginScreen());
      return;
    }

    final user = await _userService.getCurrentUser();
    if (!mounted) return;

    if (user == null) {
      await _authService.logout();
      if (!mounted) return;
      _go(const LoginScreen());
      return;
    }

    if (UserRoles.isAdmin(user.role)) {
      _go(const SideBar());
    } else {
      _go(CashierShell(user: user));
    }
  }

  void _go(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.mid),
      ),
    );
  }
}
