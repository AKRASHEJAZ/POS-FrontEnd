import 'package:flutter/material.dart';
import 'package:web_end/screen/sale/sale_pos_screen.dart';
import 'package:web_end/screen/sale/sales_history_tab.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sales', style: AppTheme.title(context)),
            const SizedBox(height: 4),
            Text(
              'Create sales and review sale history',
              style: AppTheme.subtitle(context),
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: AppColors.deep,
              unselectedLabelColor: AppColors.deep.withValues(alpha: 0.55),
              indicatorColor: AppColors.mid,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'New sale'),
                Tab(text: 'History'),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  SalePosScreen(),
                  SalesHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

