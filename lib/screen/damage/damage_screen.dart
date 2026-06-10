import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/models/sale_models.dart';
import 'package:web_end/models/stock_filters.dart';
import 'package:web_end/screen/damage/damage_history_tab.dart';
import 'package:web_end/services/damage/damage_service.dart';
import 'package:web_end/services/stock/stock_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/catalog/catalog_table_card.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_text_field.dart';
import 'package:web_end/widgets/common/responsive_page_padding.dart';
import 'package:web_end/widgets/product/product_search_picker.dart';

class DamageScreen extends StatelessWidget {
  const DamageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: responsivePagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Damage', style: AppTheme.title(context)),
            const SizedBox(height: 4),
            Text(
              'Record damaged stock and review previous damage records',
              style: AppTheme.subtitle(context),
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: AppColors.deep,
              unselectedLabelColor: AppColors.deep.withValues(alpha: 0.55),
              indicatorColor: AppColors.mid,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'New damage'),
                Tab(text: 'History'),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [_DamageCreateTab(), DamageHistoryTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DamageCreateTab extends StatefulWidget {
  const _DamageCreateTab();

  @override
  State<_DamageCreateTab> createState() => _DamageCreateTabState();
}

class _DamageCreateTabState extends State<_DamageCreateTab> {
  final _formKey = GlobalKey<FormState>();
  final _stockService = StockService();
  final _damageService = DamageService();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  ProductModel? _selectedProduct;
  InventoryBatchModel? _selectedBatch;
  List<InventoryBatchModel> _batches = [];
  bool _loadingBatches = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  double? _parseQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _onProductSelected(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      _selectedBatch = null;
      _batches = [];
      _error = null;
    });

    if (product != null) {
      _loadBatches(product.id);
    }
  }

  Future<void> _loadBatches(int productId) async {
    setState(() {
      _loadingBatches = true;
      _error = null;
    });

    final result = await _stockService.getBatches(
      filters: StockFilters(
        productId: productId,
        page: 1,
        pageSize: kPickerPageSize,
      ),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loadingBatches = false;
        _batches = [];
        _error = result.message;
      });
      return;
    }

    setState(() {
      _loadingBatches = false;
      _batches = result.data.items;
      if (_batches.isEmpty) {
        _error = 'No stock batches found for this product.';
      }
    });
  }

  String? _validateBeforeSubmit() {
    if (_selectedProduct == null) return 'Select a product first.';
    if (_selectedBatch == null) return 'Select a stock batch.';

    final quantity = _parseQuantity(_quantityController.text);
    if (quantity == null) return 'Damage quantity must be greater than zero.';

    if (_selectedBatch!.availableStock <= 0) {
      return 'Selected batch is out of stock.';
    }

    if (quantity > _selectedBatch!.availableStock) {
      return 'Only ${_formatQuantity(_selectedBatch!.availableStock)} available in this batch.';
    }

    if (_notesController.text.trim().isEmpty) {
      return 'Notes are required for damage records.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final validation = _validateBeforeSubmit();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await _damageService.createDamage(
      AddDamageDto(
        inventoryActions: [
          AddInventoryActionDto(
            inventoryBatchId: _selectedBatch!.id,
            quantity: double.parse(_quantityController.text.trim()),
            notes: _notesController.text.trim(),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      _quantityController.clear();
      _notesController.clear();
      final productId = _selectedProduct!.id;
      setState(() {
        _selectedBatch = null;
        _submitting = false;
      });
      await _loadBatches(productId);
      return;
    }

    setState(() {
      _submitting = false;
      _error = result.message;
    });
  }

  Widget _batchSection(BuildContext context) {
    if (_selectedProduct == null) {
      return _emptyPanel(
        context,
        icon: Icons.inventory_2_outlined,
        message: 'Search and select a product to view available batches.',
      );
    }

    if (_loadingBatches) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.mid),
        ),
      );
    }

    if (_batches.isEmpty) {
      return _emptyPanel(
        context,
        icon: Icons.inventory_outlined,
        message: 'No batches available for this product.',
      );
    }

    return CatalogTableCard(
      columns: const [
        DataColumn(label: Text('Batch')),
        DataColumn(label: Text('Available')),
        DataColumn(label: Text('Damaged')),
        DataColumn(label: Text('Select')),
      ],
      rows: _batches.map((batch) {
        final selected = _selectedBatch?.id == batch.id;
        final canSelect = batch.hasAvailableStock && !_submitting;

        return DataRow(
          selected: selected,
          cells: [
            DataCell(Text(batch.batchCode ?? 'Batch ${batch.id}')),
            DataCell(Text(_formatQuantity(batch.availableStock))),
            DataCell(Text(_formatQuantity(batch.stocks?.damaged ?? 0))),
            DataCell(
              IconButton(
                tooltip: selected ? 'Selected batch' : 'Select batch',
                onPressed: canSelect
                    ? () => setState(() {
                        _selectedBatch = batch;
                        _error = null;
                      })
                    : null,
                icon: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? AppColors.mid : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _emptyPanel(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.soft.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.soft.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.mid, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.subtitle(context),
          ),
        ],
      ),
    );
  }

  Widget _notesField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Damage notes',
          style: AppTheme.label(context)?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          enabled: !_submitting,
          minLines: 3,
          maxLines: 5,
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Notes are required.'
              : null,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            hintText: 'Explain why this batch is being marked as damaged',
            prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.mid),
            filled: true,
            fillColor: AppColors.light,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.soft.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.mid, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedBatch = _selectedBatch;

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;

          final formPanel = Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.soft.withValues(alpha: 0.35)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Record damage',
                    style: AppTheme.title(context)?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Admin-only stock adjustment for damaged inventory.',
                    style: AppTheme.subtitle(context),
                  ),
                  const SizedBox(height: 16),
                  ProductSearchPicker(
                    label: 'Product',
                    selected: _selectedProduct,
                    onSelected: _onProductSelected,
                    enabled: !_submitting,
                    allowClear: true,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _quantityController,
                    label: 'Damage quantity',
                    hint: selectedBatch == null
                        ? 'Select a batch first'
                        : 'Available: ${_formatQuantity(selectedBatch.availableStock)}',
                    prefixIcon: Icons.warning_amber_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => setState(() => _error = null),
                    validator: (value) {
                      final parsed = _parseQuantity(value);
                      if (parsed == null) {
                        return 'Enter a quantity greater than zero.';
                      }
                      if (selectedBatch != null &&
                          parsed > selectedBatch.availableStock) {
                        return 'Cannot exceed available stock.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _notesField(context),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Create damage record',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          );

          final batchHeader = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available batches', style: AppTheme.title(context)),
              const SizedBox(height: 4),
              Text(
                'Pick the exact batch so backend stock locks validate the right inventory.',
                style: AppTheme.subtitle(context),
              ),
              const SizedBox(height: 12),
            ],
          );

          final batchPanel = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              batchHeader,
              Expanded(
                child: SingleChildScrollView(child: _batchSection(context)),
              ),
            ],
          );

          if (compact) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  formPanel,
                  const SizedBox(height: 16),
                  batchHeader,
                  _batchSection(context),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 420, child: formPanel),
              const SizedBox(width: 16),
              Expanded(child: batchPanel),
            ],
          );
        },
      ),
    );
  }
}
