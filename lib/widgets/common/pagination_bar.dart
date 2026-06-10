import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final String itemLabel;
  final bool loading;
  final List<int> pageSizeOptions;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int>? onPageSizeChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    this.itemLabel = 'items',
    this.loading = false,
    this.pageSizeOptions = kPageSizeOptions,
    this.onPrevious,
    this.onNext,
    this.onPageSizeChanged,
  });

  int get _displayTotalPages => totalPages > 0 ? totalPages : 1;

  @override
  Widget build(BuildContext context) {
    final canGoBack = page > 1 && !loading;
    final canGoForward = totalPages > 0 && page < totalPages && !loading;
    final showPageSize = onPageSizeChanged != null;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: showPageSize ? 12 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: showPageSize ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.soft.withValues(alpha: 0.45)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          final pageSizeControl = showPageSize
              ? _PageSizeSelector(
                  value: pageSize,
                  options: pageSizeOptions,
                  enabled: !loading,
                  onChanged: onPageSizeChanged,
                  compact: compact,
                )
              : null;

          final statusText = Text(
            '$page / $_displayTotalPages · $totalItems $itemLabel',
            style: AppTheme.subtitle(context)?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.deep.withValues(alpha: 0.85),
            ),
            overflow: TextOverflow.ellipsis,
          );

          final nav = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PageNavElevatedButton(
                tooltip: 'Previous page',
                icon: Icons.chevron_left,
                enabled: canGoBack,
                onPressed: canGoBack ? onPrevious : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 150 : 240),
                  child: Center(child: statusText),
                ),
              ),
              _PageNavElevatedButton(
                tooltip: 'Next page',
                icon: Icons.chevron_right,
                enabled: canGoForward,
                onPressed: canGoForward ? onNext : null,
              ),
            ],
          );

          if (pageSizeControl == null) {
            return Center(child: nav);
          }

          if (compact) {
            return Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                nav,
                pageSizeControl,
              ],
            );
          }

          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              pageSizeControl,
              nav,
            ],
          );
        },
      ),
    );
  }
}

class _PageSizeSelector extends StatelessWidget {
  final int value;
  final List<int> options;
  final bool enabled;
  final ValueChanged<int>? onChanged;
  final bool compact;

  const _PageSizeSelector({
    required this.value,
    required this.options,
    required this.enabled,
    this.onChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          Text(
            'Rows',
            style: AppTheme.label(context)?.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 8),
        ],
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: options.contains(value) ? value : options.first,
            isDense: true,
            borderRadius: BorderRadius.circular(10),
            items: options
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text('$size'),
                  ),
                )
                .toList(),
            onChanged: enabled && onChanged != null
                ? (size) {
                    if (size != null) onChanged!(size);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _PageNavElevatedButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onPressed;

  const _PageNavElevatedButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? AppColors.light : AppColors.light.withValues(alpha: 0.8);
    final bg = enabled ? AppColors.mid : AppColors.soft.withValues(alpha: 0.9);

    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: enabled ? 1 : 0,
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          maximumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
