import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class CustomerFilterBar extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageSizeChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;
  final bool isLoading;

  const CustomerFilterBar({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.pageSize,
    this.pageSizeOptions = kPageSizeOptions,
    required this.onPageSizeChanged,
    required this.onApply,
    required this.onClear,
    this.isLoading = false,
  });

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final fieldWidth = isWide ? 240.0 : constraints.maxWidth;

        final filters = [
          SizedBox(
            width: isWide ? 240 : fieldWidth,
            child: AppTextField(
              controller: nameController,
              label: 'Name',
              hint: 'Search customer name',
              prefixIcon: Icons.person_outline,
              onSubmitted: isLoading ? null : (_) => onApply(),
            ),
          ),
          SizedBox(
            width: isWide ? 260 : fieldWidth,
            child: AppTextField(
              controller: emailController,
              label: 'Email',
              hint: 'Search email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: isLoading ? null : (_) => onApply(),
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
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ...filters.map((f) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: f,
                  )),
              const Spacer(),
              ...actions,
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

