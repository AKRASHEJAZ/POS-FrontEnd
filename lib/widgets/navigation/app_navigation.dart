import 'package:flutter/material.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

const List<AppNavDestination> appNavDestinations = [
  AppNavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Dashboard',
  ),
  AppNavDestination(
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
    label: 'Sales',
  ),
  AppNavDestination(
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart,
    label: 'Product',
  ),
  AppNavDestination(
    icon: Icons.warehouse_outlined,
    selectedIcon: Icons.warehouse,
    label: 'Stock',
  ),
  AppNavDestination(
    icon: Icons.report_problem_outlined,
    selectedIcon: Icons.report_problem,
    label: 'Damage',
  ),
  AppNavDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    label: 'Customers',
  ),
  AppNavDestination(
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    label: 'Users',
  ),
];

List<NavigationRailDestination> buildRailDestinations(BuildContext context) {
  return appNavDestinations
      .map(
        (d) => NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon, color: AppColors.light),
          label: Text(d.label),
        ),
      )
      .toList();
}

Widget buildDrawerHeader(BuildContext context, {required bool extended}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.mid,
          child: Icon(Icons.point_of_sale, color: AppColors.light, size: 22),
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          Text(
            'Smart POS',
            style: AppTheme.title(context)?.copyWith(fontSize: 18),
          ),
        ],
      ],
    ),
  );
}

Widget buildDrawerDestinations({
  required BuildContext context,
  required int selectedIndex,
  required ValueChanged<int> onSelected,
}) {
  final baseStyle = AppTheme.body(context);

  return Column(
    children: List.generate(appNavDestinations.length, (index) {
      final dest = appNavDestinations[index];
      final selected = index == selectedIndex;

      return ListTile(
        leading: Icon(
          selected ? dest.selectedIcon : dest.icon,
          color: selected
              ? AppColors.mid
              : AppColors.deep.withValues(alpha: 0.6),
        ),
        title: Text(
          dest.label,
          style: baseStyle?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected
                ? AppColors.deep
                : AppColors.deep.withValues(alpha: 0.75),
          ),
        ),
        selected: selected,
        selectedTileColor: AppColors.soft.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => onSelected(index),
      );
    }),
  );
}
