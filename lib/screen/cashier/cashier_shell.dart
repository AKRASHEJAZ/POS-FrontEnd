import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/screen/auth/login.dart';
import 'package:web_end/screen/cashier/cashier_products_screen.dart';
import 'package:web_end/screen/customer/customers_screen.dart';
import 'package:web_end/screen/stock/stock_screen.dart';
import 'package:web_end/services/auth/auth_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/navigation/profile_section.dart';
import 'package:web_end/widgets/navigation/rail_profile_trailing.dart';

const double kNavRailBreakpoint = 600;

class CashierShell extends StatefulWidget {
  final UserModel user;

  const CashierShell({super.key, required this.user});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  final _authService = AuthService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  bool _isRailHovered = false;
  bool _isLoggingOut = false;
  Timer? _collapseTimer;

  UserModel get _user => widget.user;

  static const _destinations = [
    _CashierNavItem(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Products',
    ),
    _CashierNavItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Customers',
    ),
    _CashierNavItem(
      icon: Icons.warehouse_outlined,
      selectedIcon: Icons.warehouse,
      label: 'Stock',
    ),
  ];

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
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

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: CashierProductsScreen(),
        );
      case 1:
        return const CustomersScreen();
      case 2:
        return const StockScreen(canAddStock: false);
      default:
        return const Padding(
          padding: EdgeInsets.all(24),
          child: CashierProductsScreen(),
        );
    }
  }

  String get _screenTitle {
    switch (_selectedIndex) {
      case 1:
        return 'Smart POS — Customers';
      case 2:
        return 'Smart POS — Stock';
      default:
        return 'Smart POS — Products';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kNavRailBreakpoint) {
          return _buildRailLayout(context);
        }
        return _buildDrawerLayout(context);
      },
    );
  }

  Widget _buildRailLayout(BuildContext context) {
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
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _onDestinationSelected,
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                      child: extended
                          ? Row(
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
                                  style: AppTheme.title(context)
                                      ?.copyWith(fontSize: 16),
                                ),
                              ],
                            )
                          : const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.mid,
                              child: Icon(
                                Icons.point_of_sale,
                                color: AppColors.light,
                                size: 22,
                              ),
                            ),
                    ),
                    destinations: _destinations
                        .map(
                          (d) => NavigationRailDestination(
                            icon: Icon(d.icon),
                            selectedIcon: Icon(
                              d.selectedIcon,
                              color: AppColors.light,
                            ),
                            label: Text(d.label),
                          ),
                        )
                        .toList(),
                  ),
                ),
                RailProfileTrailing(
                  user: _user,
                  railExtended: extended,
                  isLoading: false,
                  isLoggingOut: _isLoggingOut,
                  onLogout: _handleLogout,
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildDrawerLayout(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_screenTitle),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
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
                    Expanded(
                      child: Text(
                        'Smart POS',
                        style: AppTheme.title(context)?.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
              ...List.generate(_destinations.length, (index) {
                final dest = _destinations[index];
                final selected = index == _selectedIndex;
                return ListTile(
                  leading: Icon(
                    selected ? dest.selectedIcon : dest.icon,
                    color: selected
                        ? AppColors.mid
                        : AppColors.deep.withValues(alpha: 0.6),
                  ),
                  title: Text(
                    dest.label,
                    style: AppTheme.body(context)?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? AppColors.deep
                          : AppColors.deep.withValues(alpha: 0.75),
                    ),
                  ),
                  selected: selected,
                  selectedTileColor: AppColors.soft.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onTap: () => _onDestinationSelected(index),
                );
              }),
              const Spacer(),
              ProfileSection(
                user: _user,
                isLoading: false,
                isLoggingOut: _isLoggingOut,
                onLogout: _handleLogout,
              ),
            ],
          ),
        ),
      ),
      body: _buildContent(),
    );
  }
}

class _CashierNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _CashierNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
