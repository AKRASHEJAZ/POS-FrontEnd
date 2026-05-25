import 'package:flutter/material.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class CatalogTableCard extends StatefulWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;

  const CatalogTableCard({
    super.key,
    required this.columns,
    required this.rows,
  });

  @override
  State<CatalogTableCard> createState() => _CatalogTableCardState();
}

class _CatalogTableCardState extends State<CatalogTableCard> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.soft.withValues(alpha: 0.4)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minTableWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 800.0;

            final table = DataTable(
              headingRowColor: WidgetStateProperty.all(
                AppColors.soft.withValues(alpha: 0.15),
              ),
              headingTextStyle: AppTheme.label(context)?.copyWith(fontSize: 13),
              dataTextStyle: AppTheme.body(context)?.copyWith(fontSize: 14),
              columns: widget.columns,
              rows: widget.rows,
            );

            final tableContent = ConstrainedBox(
              constraints: BoxConstraints(minWidth: minTableWidth),
              child: table,
            );

            // Vertical scroll must be outer when height is bounded.
            // Horizontal-inside-vertical gives the inner scroll unbounded height.
            if (constraints.hasBoundedHeight &&
                constraints.maxHeight.isFinite) {
              return Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: tableContent,
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: tableContent,
            );
          },
        ),
      ),
    );
  }
}

Widget catalogActionButtons({
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Edit',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined, color: AppColors.mid),
      ),
      IconButton(
        tooltip: 'Delete',
        onPressed: onDelete,
        icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
      ),
    ],
  );
}

String formatCatalogDate(DateTime? date) {
  if (date == null) return '—';
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
