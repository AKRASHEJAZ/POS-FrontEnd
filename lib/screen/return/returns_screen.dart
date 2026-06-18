import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_end/models/return_filters.dart';
import 'package:web_end/models/sale_filters.dart';
import 'package:web_end/models/sale_models.dart';
import 'package:web_end/models/sale_view_model.dart';
import 'package:web_end/screen/return/returns_history_tab.dart';
import 'package:web_end/services/return/return_service.dart';
import 'package:web_end/services/sale/sale_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_text_field.dart';
import 'package:web_end/widgets/common/responsive_page_padding.dart';

class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Padding(
        padding: responsivePagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Returns', style: AppTheme.title(context)),
            const SizedBox(height: 4),
            Text(
              'Record sale returns and review previous return records',
              style: AppTheme.subtitle(context),
            ),
            const SizedBox(height: 16),
            TabBar(
              labelColor: AppColors.deep,
              unselectedLabelColor: AppColors.deep.withValues(alpha: 0.55),
              indicatorColor: AppColors.mid,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'New return'),
                Tab(text: 'History'),
              ],
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [_ReturnCreateTab(), ReturnsHistoryTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnCreateTab extends StatefulWidget {
  const _ReturnCreateTab();

  @override
  State<_ReturnCreateTab> createState() => _ReturnCreateTabState();
}

class _ReturnCreateTabState extends State<_ReturnCreateTab> {
  final _formKey = GlobalKey<FormState>();
  final _saleService = SaleService();
  final _returnService = ReturnService();
  final _saleIdController = TextEditingController();
  final _reasonController = TextEditingController();

  SaleModel? _sale;
  Map<int, double> _previouslyReturned = {};
  final Set<int> _selectedBatchIds = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _notesControllers = {};
  bool _loadingSale = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _saleIdController.dispose();
    _reasonController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  double? _parseQuantity(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _clearReturnFields() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    _notesControllers.clear();
    _selectedBatchIds.clear();
    _previouslyReturned.clear();
  }

  Future<void> _loadSale() async {
    final saleId = int.tryParse(_saleIdController.text.trim());
    if (saleId == null || saleId <= 0) {
      setState(() => _error = 'Enter a valid sale ID.');
      return;
    }

    setState(() {
      _loadingSale = true;
      _error = null;
      _sale = null;
      _clearReturnFields();
    });

    final result = await _saleService.getSales(
      filters: SaleFilters(
        id: saleId,
        page: 1,
        pageSize: 1,
        includeActions: true,
        includeCustomer: true,
        includeUser: true,
        includeInventoryBatch: true,
      ),
    );

    if (!mounted) return;

    if (!result.isSuccess || result.data.items.isEmpty) {
      setState(() {
        _loadingSale = false;
        _error = result.message.isNotEmpty ? result.message : 'Sale not found.';
      });
      return;
    }

    final sale = result.data.items.first;

    // Fetch previous returns to calculate remaining quantities
    Map<int, double> returnedQuantities = {};
    String? fetchError;
    try {
      final returnsResult = await _returnService.getReturns(
        filters: ReturnFilters(
          customerId: sale.customerId ?? 0,
          page: 1,
          pageSize: 1000,
          includeActions: true,
          includeInventoryBatch: false,
          includeSale: false,
        ),
      );
      if (returnsResult.isSuccess) {
        for (var returnRecord in returnsResult.data.items) {
          if (returnRecord.saleId == sale.id) {
            for (var action in returnRecord.actions) {
              returnedQuantities[action.inventoryBatchId] =
                  (returnedQuantities[action.inventoryBatchId] ?? 0) +
                      action.quantity;
            }
          }
        }
      }
    } catch (e) {
      fetchError = 'Could not load previous returns info: $e';
    }

    setState(() {
      _loadingSale = false;
      _sale = sale;
      _clearReturnFields();
      _previouslyReturned = returnedQuantities;

      // Initialize controllers for each action
      for (final action in sale.actions) {
        final remaining = action.quantity - (returnedQuantities[action.inventoryBatchId] ?? 0);
        _quantityControllers[action.inventoryBatchId] = TextEditingController(
          text: remaining > 0 ? _formatQuantity(remaining) : '0',
        );
        _notesControllers[action.inventoryBatchId] = TextEditingController();
      }

      if (sale.actions.isEmpty) {
        _error = 'This sale has no returnable line items.';
      } else if (fetchError != null) {
        _error = fetchError;
      }
    });
  }

  String? _validateBeforeSubmit() {
    final sale = _sale;
    if (sale == null) return 'Load a sale before creating a return.';
    if (_selectedBatchIds.isEmpty) return 'Select at least one product to return.';
    if (_reasonController.text.trim().isEmpty) {
      return 'Reason for return is required.';
    }

    for (final batchId in _selectedBatchIds) {
      final action = sale.actions.firstWhere((a) => a.inventoryBatchId == batchId);
      final qtyText = _quantityControllers[batchId]?.text ?? '';
      final quantity = _parseQuantity(qtyText);
      if (quantity == null) {
        return 'Enter a valid return quantity for batch ${action.inventoryBatch?.batchCode ?? 'ID $batchId'}.';
      }
      final sold = action.quantity;
      final returned = _previouslyReturned[batchId] ?? 0;
      final available = sold - returned;
      if (quantity > available) {
        return 'Return quantity for ${action.inventoryBatch?.batchCode ?? 'batch ID $batchId'} cannot exceed available quantity (${_formatQuantity(available)}).';
      }
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

    final actions = _selectedBatchIds.map((batchId) {
      final qtyText = _quantityControllers[batchId]?.text ?? '0';
      return AddInventoryActionDto(
        inventoryBatchId: batchId,
        quantity: _parseQuantity(qtyText)!,
        notes: _notesControllers[batchId]?.text.trim(),
      );
    }).toList();

    final result = await _returnService.createReturn(
      AddReturnDto(
        saleId: _sale!.id,
        reason: _reasonController.text.trim(),
        inventoryActions: actions,
      ),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      _reasonController.clear();
      _clearReturnFields();
      setState(() => _submitting = false);
      await _loadSale();
      return;
    }

    setState(() {
      _submitting = false;
      _error = result.message;
    });
  }

  Widget _saleSummary(BuildContext context) {
    final sale = _sale;
    if (_loadingSale) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.mid),
        ),
      );
    }

    if (sale == null) {
      return _emptyPanel(
        context,
        icon: Icons.receipt_long_outlined,
        message: 'Load a sale to choose returned items.',
      );
    }

    final customer = sale.customer?.name ?? 'Customer ${sale.customerId ?? '-'}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.soft.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.soft.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          _summaryItem(context, 'Sale', '#${sale.id}'),
          _summaryItem(context, 'Customer', customer),
          _summaryItem(context, 'Returnable items', '${sale.actions.length}'),
        ],
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTheme.label(context)?.copyWith(fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.body(context)),
      ],
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

  Widget _qtyBadge(BuildContext context, String label, double value, Color color, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: ${_formatQuantity(value)}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _lineItems(BuildContext context) {
    if (_loadingSale) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.mid),
      );
    }
    if (_sale == null) {
      return _emptyPanel(
        context,
        icon: Icons.assignment_return_outlined,
        message: 'Returned items will appear here after sale lookup.',
      );
    }
    final actions = _sale!.actions;
    if (actions.isEmpty) {
      return _emptyPanel(
        context,
        icon: Icons.inventory_outlined,
        message: 'This sale has no line items.',
      );
    }

    return ListView.separated(
      itemCount: actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final action = actions[index];
        final batch = action.inventoryBatch;
        final product = batch?.product;
        final title = product?.name ?? 'Product';
        final batchCode = batch?.batchCode ?? 'Batch ${action.inventoryBatchId}';

        final sold = action.quantity;
        final returned = _previouslyReturned[action.inventoryBatchId] ?? 0;
        final available = sold - returned;
        final isFullyReturned = available <= 0;
        final isSelected = _selectedBatchIds.contains(action.inventoryBatchId);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected 
                  ? AppColors.mid 
                  : AppColors.soft.withValues(alpha: 0.35),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.mid,
                      onChanged: isFullyReturned || _submitting
                          ? null
                          : (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedBatchIds.add(action.inventoryBatchId);
                                  _error = null;
                                } else {
                                  _selectedBatchIds.remove(action.inventoryBatchId);
                                }
                              });
                            },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.body(context)?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Batch: $batchCode',
                            style: AppTheme.subtitle(context)?.copyWith(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 16,
                            runSpacing: 4,
                            children: [
                              _qtyBadge(context, 'Sold', sold, Colors.grey.shade700),
                              if (returned > 0)
                                _qtyBadge(context, 'Returned', returned, Colors.orange.shade700),
                              if (!isFullyReturned)
                                _qtyBadge(
                                  context, 
                                  'Available', 
                                  available, 
                                  isSelected ? AppColors.mid : Colors.green.shade700,
                                  isBold: true,
                                ),
                              if (isFullyReturned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Text(
                                    'Fully Returned',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected && !isFullyReturned) ...[
                  const Divider(height: 24, thickness: 0.5),
                  Padding(
                    padding: const EdgeInsets.only(left: 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _quantityControllers[action.inventoryBatchId],
                            enabled: !_submitting,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                            ],
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Return Quantity',
                              hintText: 'Max ${_formatQuantity(available)}',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            validator: (_) {
                              final quantity = _parseQuantity(
                                _quantityControllers[action.inventoryBatchId]?.text ?? '',
                              );
                              if (quantity == null) {
                                return 'Required';
                              }
                              if (quantity <= 0) {
                                return '> 0';
                              }
                              if (quantity > available) {
                                return 'Max ${_formatQuantity(available)}';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _notesControllers[action.inventoryBatchId],
                            enabled: !_submitting,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Item Notes',
                              hintText: 'Optional notes',
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'Create return',
                    style: AppTheme.title(context)?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Load the original sale, then enter the quantities being returned.',
                    style: AppTheme.subtitle(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _saleIdController,
                          label: 'Sale ID',
                          hint: 'e.g. 25',
                          prefixIcon: Icons.receipt_long_outlined,
                          keyboardType: TextInputType.number,
                          enabled: !_loadingSale && !_submitting,
                          onSubmitted: (_) => _loadSale(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _loadingSale || _submitting
                            ? null
                            : _loadSale,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.mid,
                        ),
                        icon: _loadingSale
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.light,
                                ),
                              )
                            : const Icon(Icons.search, size: 18),
                        label: const Text('Load'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _reasonController,
                    enabled: !_submitting,
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Reason is required.'
                        : null,
                    onChanged: (_) => setState(() => _error = null),
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Why is this sale being returned?',
                      prefixIcon: const Icon(
                        Icons.notes_outlined,
                        color: AppColors.mid,
                      ),
                      filled: true,
                      fillColor: AppColors.light,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _saleSummary(context),
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
                    label: 'Create return record',
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                  ),
                ],
              ),
            ),
          );

          final linesHeader = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sale line items', style: AppTheme.title(context)),
              const SizedBox(height: 4),
              Text(
                'Select products from the sale to return.',
                style: AppTheme.subtitle(context),
              ),
              const SizedBox(height: 12),
            ],
          );

          if (compact) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  formPanel,
                  const SizedBox(height: 16),
                  linesHeader,
                  SizedBox(height: 420, child: _lineItems(context)),
                ],
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 430,
                child: SingleChildScrollView(child: formPanel),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    linesHeader,
                    Expanded(child: _lineItems(context)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
