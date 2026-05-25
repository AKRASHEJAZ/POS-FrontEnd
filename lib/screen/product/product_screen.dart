import 'package:flutter/material.dart';
import 'package:web_end/screen/product/tabs/categories_tab.dart';
import 'package:web_end/screen/product/tabs/products_tab.dart';
import 'package:web_end/screen/product/tabs/units_tab.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products', style: AppTheme.title(context)),
            const SizedBox(height: 4),
            Text(
              'Manage products, categories, and units',
              style: AppTheme.subtitle(context),
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: AppColors.deep,
              unselectedLabelColor: AppColors.deep.withValues(alpha: 0.55),
              indicatorColor: AppColors.mid,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Products'),
                Tab(text: 'Categories'),
                Tab(text: 'Units'),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  ProductsTab(),
                  CategoriesTab(),
                  UnitsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
