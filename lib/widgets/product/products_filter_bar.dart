import 'package:flutter/material.dart';
import 'package:web_end/models/category_model.dart';
import 'package:web_end/models/unit_model.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_dropdown.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class ProductsFilterBar extends StatelessWidget {
  final TextEditingController nameController;
  final String? categoryValue;
  final String? unitValue;
  final String? statusValue;
  final List<CategoryModel> categories;
  final List<UnitModel> units;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onUnitChanged;
  final ValueChanged<String?> onStatusChanged;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final bool isLoading;

  const ProductsFilterBar({
    super.key,
    required this.nameController,
    required this.categoryValue,
    required this.unitValue,
    required this.statusValue,
    required this.categories,
    required this.units,
    required this.onCategoryChanged,
    required this.onUnitChanged,
    required this.onStatusChanged,
    required this.pageSize,
    this.pageSizeOptions = kPageSizeOptions,
    required this.onPageSizeChanged,
    required this.onApply,
    required this.onClear,
    this.isLoading = false,
  });

  static const statusOptions = ['All', 'Active', 'Inactive'];

  Widget _pageSizeSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Rows'),
        const SizedBox(width: 8),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: pageSizeOptions.contains(pageSize)
                ? pageSize
                : pageSizeOptions.first,
            isDense: true,
            borderRadius: BorderRadius.circular(10),
            items: pageSizeOptions
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text('$size'),
                  ),
                )
                .toList(),
            onChanged: isLoading
                ? null
                : (size) {
                    if (size != null) onPageSizeChanged(size);
                  },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryItems = [
      const DropdownMenuItem(value: 'All', child: Text('All')),
      ...categories.map(
        (c) => DropdownMenuItem(value: '${c.id}', child: Text(c.name)),
      ),
    ];

    final unitItems = [
      const DropdownMenuItem(value: 'All', child: Text('All')),
      ...units.map(
        (u) => DropdownMenuItem(
          value: '${u.id}',
          child: Text('${u.name} (${u.symbol})'),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final fieldWidth = isWide ? 200.0 : constraints.maxWidth;

        final filters = [
          SizedBox(
            width: isWide ? 200 : fieldWidth,
            child: AppTextField(
              controller: nameController,
              label: 'Name',
              hint: 'Search by product name',
              prefixIcon: Icons.search,
              onSubmitted: isLoading ? null : (_) => onApply(),
            ),
          ),
          SizedBox(
            width: isWide ? 180 : fieldWidth,
            child: AppDropdown<String>(
              label: 'Category',
              value: categoryValue ?? 'All',
              items: categoryItems,
              onChanged: isLoading ? null : onCategoryChanged,
            ),
          ),
          SizedBox(
            width: isWide ? 180 : fieldWidth,
            child: AppDropdown<String>(
              label: 'Unit',
              value: unitValue ?? 'All',
              items: unitItems,
              onChanged: isLoading ? null : onUnitChanged,
            ),
          ),
          SizedBox(
            width: isWide ? 160 : fieldWidth,
            child: AppDropdown<String>(
              label: 'Status',
              value: statusValue ?? 'All',
              items: statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: isLoading ? null : onStatusChanged,
            ),
          ),
        ];

        final actions = [
          _pageSizeSelector(),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: isLoading ? null : onApply,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.mid,
              minimumSize: const Size(100, 44),
            ),
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Apply'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: isLoading ? null : onClear,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.deep,
              minimumSize: const Size(88, 44),
              side: BorderSide(color: AppColors.mid.withValues(alpha: 0.5)),
            ),
            child: const Text('Clear'),
          ),
        ];

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: filters,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...filters.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: f,
                )),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ],
        );
      },
    );
  }
}
