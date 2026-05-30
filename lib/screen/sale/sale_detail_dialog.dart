import 'package:flutter/material.dart';
import 'package:web_end/models/sale_view_model.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';

class SaleDetailDialog extends StatelessWidget {
  final SaleModel sale;

  const SaleDetailDialog({super.key, required this.sale});

  static Future<void> show(BuildContext context, SaleModel sale) {
    return showDialog<void>(
      context: context,
      builder: (_) => SaleDetailDialog(sale: sale),
    );
  }

  String _date(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: AppTheme.label(context)?.copyWith(fontSize: 12)),
          ),
          Expanded(child: Text(v.isEmpty ? '—' : v, style: AppTheme.body(context))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = sale.customer;
    final createdBy = sale.createdBy;

    final rows = sale.actions.map((a) {
      final batch = a.inventoryBatch;
      final product = batch?.product;
      final productLabel = product == null
          ? '—'
          : [
              product.name,
              if (product.unitSymbol != null && product.unitSymbol!.isNotEmpty)
                '(${product.unitSymbol})',
            ].join(' ');
      return DataRow(
        cells: [
          DataCell(Text((batch?.batchCode?.isNotEmpty ?? false)
              ? batch!.batchCode!
              : 'Batch ${a.inventoryBatchId}')),
          DataCell(Text(productLabel)),
          DataCell(Text(a.quantity.toString())),
          DataCell(Text((batch?.sellingPrice ?? 0).toStringAsFixed(2))),
          DataCell(Text(a.lineTotal.toStringAsFixed(2))),
        ],
      );
    }).toList();

    final computedTotal = sale.actions.isEmpty
        ? sale.totalAmount
        : sale.actions.fold<double>(0, (s, a) => s + a.lineTotal);

    return Dialog(
      backgroundColor: AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sale #${sale.id}',
                      style: AppTheme.title(context)?.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.deep),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final left = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _kv(context, 'Date', _date(sale.saleDate)),
                      _kv(context, 'Total', computedTotal.toStringAsFixed(2)),
                      _kv(context, 'Created by', createdBy?.name ?? '—'),
                    ],
                  );
                  final right = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _kv(context, 'Customer', customer?.name ?? '—'),
                      _kv(context, 'Email', customer?.email ?? '—'),
                      _kv(context, 'Phone', customer?.phone ?? '—'),
                    ],
                  );

                  if (!wide) return Column(children: [left, const SizedBox(height: 10), right]);

                  return Row(
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 12),
                      Expanded(child: right),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Text('Line items', style: AppTheme.title(context)?.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: CatalogTableCard(
                  columns: const [
                    DataColumn(label: Text('Batch')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: rows,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

