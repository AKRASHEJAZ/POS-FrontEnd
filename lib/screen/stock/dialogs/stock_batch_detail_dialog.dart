import 'package:flutter/material.dart';
import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/read_only_field.dart';

class StockBatchDetailDialog extends StatelessWidget {
  final InventoryBatchModel batch;

  const StockBatchDetailDialog({super.key, required this.batch});

  static Future<void> show(BuildContext context, InventoryBatchModel batch) {
    return showDialog<void>(
      context: context,
      builder: (_) => StockBatchDetailDialog(batch: batch),
    );
  }

  String _formatMoney(double value) => value.toStringAsFixed(2);

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateOnly(String? value) {
    if (value == null || value.isEmpty) return '—';
    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.light,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth;

              return SingleChildScrollView(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Stock batch details',
                              style: AppTheme.title(
                                context,
                              )?.copyWith(fontSize: 22),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.deep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        batch.productName ?? 'Product',
                        style: AppTheme.subtitle(context),
                      ),
                      const SizedBox(height: 20),
                      UserFormGrid(
                        maxWidth: contentWidth,
                        children: [
                          ReadOnlyField(
                            label: 'Batch code',
                            value: batch.batchCode ?? '',
                          ),
                          ReadOnlyField(
                            label: 'Product',
                            value: batch.productName ?? '',
                          ),
                          ReadOnlyField(
                            label: 'Purchased amount',
                            value: _formatQuantity(batch.purchaseAmount),
                          ),
                          ReadOnlyField(
                            label: 'Available stock',
                            value: _formatQuantity(batch.availableStock),
                          ),
                          ReadOnlyField(
                            label: 'Sold',
                            value: _formatQuantity(batch.stocks?.sold ?? 0),
                          ),
                          ReadOnlyField(
                            label: 'Damaged',
                            value: _formatQuantity(batch.stocks?.damaged ?? 0),
                          ),
                          ReadOnlyField(
                            label: 'Returned',
                            value: _formatQuantity(batch.stocks?.returned ?? 0),
                          ),
                          ReadOnlyField(
                            label: 'Purchase date',
                            value: formatCatalogDate(batch.createdAt),
                          ),
                          ReadOnlyField(
                            label: 'Purchase price',
                            value: _formatMoney(batch.purchasePrice),
                          ),
                          ReadOnlyField(
                            label: 'Selling price',
                            value: _formatMoney(batch.sellingPrice),
                          ),
                          ReadOnlyField(
                            label: 'MFG date',
                            value: _formatDateOnly(batch.mfgDate),
                          ),
                          ReadOnlyField(
                            label: 'Expiry date',
                            value: _formatDateOnly(batch.expiryDate),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
