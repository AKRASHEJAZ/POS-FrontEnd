import 'package:flutter/material.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_text_field.dart';
import 'package:web_end/widgets/product/product_search_picker.dart';

class StockFilterBar extends StatelessWidget {
  final TextEditingController batchCodeController;
  final ProductModel? selectedProduct;
  final ValueChanged<ProductModel?> onProductSelected;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageSizeChanged;
  final bool isLoading;
  final VoidCallback onApply;
  final VoidCallback onClear;

  const StockFilterBar({
    super.key,
    required this.batchCodeController,
    required this.selectedProduct,
    required this.onProductSelected,
    required this.pageSize,
    this.pageSizeOptions = kPageSizeOptions,
    required this.onPageSizeChanged,
    required this.isLoading,
    required this.onApply,
    required this.onClear,
  });

  Widget _pageSizeSelector(BuildContext context) {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final isWide = maxWidth >= 720;
        final fieldWidth = isWide ? 280.0 : maxWidth;

        final batchField = SizedBox(
          width: isWide ? 240 : fieldWidth,
          child: AppTextField(
            controller: batchCodeController,
            label: 'Batch code',
            hint: 'Filter by batch code',
            prefixIcon: Icons.qr_code_2_outlined,
            onSubmitted: (_) => onApply(),
          ),
        );

        final productSearch = ProductSearchPicker(
          label: 'Product',
          selected: selectedProduct,
          onSelected: onProductSelected,
          enabled: !isLoading,
          allowClear: true,
        );

        final actions = [
          _pageSizeSelector(context),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  batchField,
                  const SizedBox(width: 16),
                  Expanded(child: productSearch),
                ],
              ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            batchField,
            const SizedBox(height: 12),
            productSearch,
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        );
      },
    );
  }
}
