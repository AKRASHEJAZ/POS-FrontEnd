import 'package:flutter/material.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class DamageFilterBar extends StatelessWidget {
  final TextEditingController damageIdController;
  final TextEditingController batchIdController;
  final TextEditingController productIdController;
  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final bool isLoading;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const DamageFilterBar({
    super.key,
    required this.damageIdController,
    required this.batchIdController,
    required this.productIdController,
    required this.pageSize,
    required this.onPageSizeChanged,
    required this.isLoading,
    required this.onApply,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final fields = [
      AppTextField(
        controller: damageIdController,
        label: 'Damage ID',
        hint: 'e.g. 12',
        prefixIcon: Icons.tag,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => onApply(),
      ),
      AppTextField(
        controller: batchIdController,
        label: 'Batch ID',
        hint: 'e.g. 5',
        prefixIcon: Icons.inventory_2_outlined,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => onApply(),
      ),
      AppTextField(
        controller: productIdController,
        label: 'Product ID',
        hint: 'e.g. 3',
        prefixIcon: Icons.shopping_cart_outlined,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => onApply(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: isLoading ? null : onClear,
              child: const Text('Clear'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: isLoading ? null : onApply,
              style: FilledButton.styleFrom(backgroundColor: AppColors.mid),
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Apply'),
            ),
          ],
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final field in fields) ...[
                Expanded(child: field),
                const SizedBox(width: 12),
              ],
              actions,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in fields) ...[field, const SizedBox(height: 12)],
            Align(alignment: Alignment.centerRight, child: actions),
          ],
        );
      },
    );
  }
}
