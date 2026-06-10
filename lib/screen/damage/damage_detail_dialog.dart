import 'package:flutter/material.dart';
import 'package:web_end/models/damage_view_model.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';

class DamageDetailDialog extends StatelessWidget {
  final DamageModel damage;

  const DamageDetailDialog({super.key, required this.damage});

  static Future<void> show(BuildContext context, DamageModel damage) {
    return showDialog<void>(
      context: context,
      builder: (_) => DamageDetailDialog(damage: damage),
    );
  }

  String _date(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _kv(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.label(context)?.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTheme.body(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final rows = damage.actions.map((action) {
      final batch = action.inventoryBatch;
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
          DataCell(
            Text(
              (batch?.batchCode?.isNotEmpty ?? false)
                  ? batch!.batchCode!
                  : 'Batch ${action.inventoryBatchId}',
            ),
          ),
          DataCell(Text(productLabel)),
          DataCell(Text(_formatQuantity(action.quantity))),
          DataCell(Text(action.notes ?? '—')),
        ],
      );
    }).toList();

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
                      'Damage #${damage.id}',
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
              _kv(context, 'Date', _date(damage.damageDate)),
              _kv(
                context,
                'Total qty',
                _formatQuantity(damage.totalDamagedQuantity),
              ),
              _kv(context, 'Created by', damage.createdBy?.name ?? '—'),
              const SizedBox(height: 12),
              Text(
                'Damaged items',
                style: AppTheme.title(context)?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: CatalogTableCard(
                  columns: const [
                    DataColumn(label: Text('Batch')),
                    DataColumn(label: Text('Product')),
                    DataColumn(label: Text('Qty')),
                    DataColumn(label: Text('Notes')),
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
