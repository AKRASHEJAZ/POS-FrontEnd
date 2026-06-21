import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/screen/auth/login.dart';
import 'package:web_end/screen/damage/damage_screen.dart';
import 'package:web_end/screen/reports/reports_screen.dart';
import 'package:web_end/screen/return/returns_screen.dart';
import 'package:web_end/screen/sale/sales_screen.dart';
import 'package:web_end/screen/dashboard/dashboard_screen.dart';
import 'package:web_end/screen/customer/customers_screen.dart';
import 'package:web_end/screen/product/product_screen.dart';
import 'package:web_end/screen/stock/stock_screen.dart';
import 'package:web_end/screen/users/users_screen.dart';
import 'package:web_end/services/auth/auth_service.dart';
import 'package:web_end/services/user/user_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/navigation/app_navigation.dart';
import 'package:web_end/widgets/navigation/profile_section.dart';
import 'package:web_end/widgets/navigation/rail_profile_trailing.dart';

/// Rail for tablet/desktop (>= 600px). Drawer for mobile.
const double kNavRailBreakpoint = 600;

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final _userService = UserService();
  final _authService = AuthService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  bool _isRailHovered = false;
  bool _isLoggingOut = false;
  UserModel? _currentUser;
  bool _loadingUser = true;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _userService.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _loadingUser = false;
    });
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await _authService.logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _handleRailMouseEnter() {
    _collapseTimer?.cancel();
    if (!_isRailHovered) setState(() => _isRailHovered = true);
  }

  void _handleRailMouseExit() {
    _collapseTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isRailHovered = false);
    });
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const SalesScreen();
      case 2:
        return const ProductScreen();
      case 3:
        return const StockScreen();
      case 4:
        return const DamageScreen();
      case 5:
        return const ReturnsScreen();
      case 6:
        return const CustomersScreen();
      case 7:
        return const UsersScreen();
      case 8:
        return const ReportsScreen();
      default:
        return const DashboardScreen();
    }
  }

  Widget _buildDrawerProfile() {
    return ProfileSection(
      user: _currentUser,
      isLoading: _loadingUser,
      isLoggingOut: _isLoggingOut,
      onLogout: _handleLogout,
    );
  }

  Widget _buildRailProfile(bool railExtended) {
    return RailProfileTrailing(
      user: _currentUser,
      railExtended: railExtended,
      isLoading: _loadingUser,
      isLoggingOut: _isLoggingOut,
      onLogout: _handleLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= kNavRailBreakpoint;

        if (useRail) {
          return _buildRailScaffold();
        }
        return _buildDrawerScaffold();
      },
    );
  }

  Widget _buildRailScaffold() {
    final extended = _isRailHovered;

    return Scaffold(
      body: Row(
        children: [
          MouseRegion(
            onEnter: (_) => _handleRailMouseEnter(),
            onExit: (_) => _handleRailMouseExit(),
            child: Column(
              children: [
                Expanded(
                  child: NavigationRail(
                    extended: extended,
                    indicatorColor: AppColors.soft,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: extended
                            ? Row(
                                key: const ValueKey('expanded_header'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.mid,
                                    child: Icon(
                                      Icons.point_of_sale,
                                      color: AppColors.light,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Smart POS',
                                    style: AppTheme.title(
                                      context,
                                    )?.copyWith(fontSize: 16),
                                  ),
                                ],
                              )
                            : const CircleAvatar(
                                key: ValueKey('collapsed_header'),
                                radius: 20,
                                backgroundColor: AppColors.mid,
                                child: Icon(
                                  Icons.point_of_sale,
                                  color: AppColors.light,
                                  size: 22,
                                ),
                              ),
                      ),
                    ),
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                    destinations: buildRailDestinations(context),
                  ),
                ),
                _buildRailProfile(extended),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent(context)),
        ],
      ),
    );
  }

  Widget _buildDrawerScaffold() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Smart POS'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.light,
        child: SafeArea(
          child: Column(
            children: [
              buildDrawerHeader(context, extended: true),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: buildDrawerDestinations(
                    context: context,
                    selectedIndex: _selectedIndex,
                    onSelected: _onDestinationSelected,
                  ),
                ),
              ),
              _buildDrawerProfile(),
            ],
          ),
        ),
      ),
      body: _buildContent(context),
    );
  }
}
