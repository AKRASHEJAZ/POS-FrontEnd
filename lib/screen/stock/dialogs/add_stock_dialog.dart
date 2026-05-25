import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/services/stock/stock_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/utils/stock_entry_validation.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_text_field.dart';
import 'package:web_end/widgets/product/product_search_picker.dart';

class AddStockDialog extends StatefulWidget {
  const AddStockDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddStockDialog(),
    );
  }

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = StockService();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController();

  ProductModel? _selectedProduct;
  DateTime? _mfgDate;
  DateTime? _expiryDate;
  bool _loading = false;
  String? _error;
  String? _productNotice;

  bool get _requiresExpiry => _selectedProduct?.doesExpire ?? false;

  @override
  void dispose() {
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _onProductSelected(ProductModel? product) {
    setState(() {
      _selectedProduct = product;
      _productNotice = StockEntryValidation.productEligibility(product);
      if (product != null && !product.doesExpire) {
        _expiryDate = null;
      }
      _error = null;
    });
  }

  Future<void> _pickDate({
    required bool isMfg,
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? (isMfg ? today : today.add(const Duration(days: 1))),
      firstDate: isMfg ? DateTime(2000) : today.add(const Duration(days: 1)),
      lastDate: isMfg
          ? (_expiryDate != null
              ? DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day)
              : DateTime(2100))
          : DateTime(2100),
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isMfg) {
        _mfgDate = picked;
        if (_expiryDate != null &&
            !DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day)
                .isAfter(DateTime(picked.year, picked.month, picked.day))) {
          _expiryDate = null;
        }
      } else {
        _expiryDate = picked;
      }
      _error = null;
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  double? _parsePositive(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final n = double.tryParse(value.trim());
    if (n == null || n <= 0) return null;
    return n;
  }

  double? _parsePurchasePrice() {
    return double.tryParse(_purchasePriceController.text.trim());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qty = double.tryParse(_quantityController.text.trim());
    final purchase = _parsePurchasePrice();
    final selling = double.tryParse(_sellingPriceController.text.trim());

    final businessError = StockEntryValidation.validateAll(
      product: _selectedProduct,
      purchasedQuantity: qty,
      purchasePrice: purchase,
      sellingPrice: selling,
      mfgDate: _mfgDate,
      expiryDate: _expiryDate,
    );

    if (businessError != null) {
      setState(() => _error = businessError);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _service.addBatch(
      productId: _selectedProduct!.id,
      purchasePrice: purchase!,
      sellingPrice: selling!,
      purchasedQuantity: qty!,
      mfgDate: _mfgDate,
      expiryDate: _expiryDate,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.message),
        ),
      );
      return;
    }

    setState(() {
      _loading = false;
      _error = result.message;
    });
  }

  Widget _productBanner(BuildContext context) {
    if (_selectedProduct == null) return const SizedBox.shrink();

    if (_productNotice != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          _productNotice!,
          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
        ),
      );
    }

    if (_requiresExpiry) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.soft.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'This product expires — a future expiry date is required.',
          style: AppTheme.body(context)?.copyWith(fontSize: 13),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _dateField({
    required String label,
    required String value,
    required VoidCallback onPick,
    VoidCallback? onClear,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          required ? '$label *' : label,
          style: AppTheme.label(context)?.copyWith(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.soft.withValues(alpha: 0.5)),
                ),
                child: Text(value, style: AppTheme.body(context)),
              ),
            ),
            IconButton(
              tooltip: 'Pick date',
              onPressed: _loading ? null : onPick,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: AppColors.mid,
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: 'Clear',
                onPressed: _loading ? null : onClear,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: Icon(Icons.clear, color: Colors.grey.shade600),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedProduct != null && _productNotice == null;

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

              return Form(
                key: _formKey,
                child: SingleChildScrollView(
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
                                'Add stock',
                                style: AppTheme.title(context)
                                    ?.copyWith(fontSize: 22),
                              ),
                            ),
                            IconButton(
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close, color: AppColors.deep),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record a new inventory batch for a product',
                          style: AppTheme.subtitle(context),
                        ),
                        const SizedBox(height: 20),
                        ProductSearchPicker(
                          label: 'Product',
                          selected: _selectedProduct,
                          onSelected: _onProductSelected,
                          enabled: !_loading,
                          allowClear: true,
                        ),
                        _productBanner(context),
                        UserFormGrid(
                          maxWidth: contentWidth,
                          children: [
                            AppTextField(
                              controller: _quantityController,
                              label: 'Purchased amount',
                              hint: 'Quantity received',
                              prefixIcon: Icons.numbers,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              validator: (v) =>
                                  StockEntryValidation.purchasedQuantity(
                                    _parsePositive(v),
                                  ),
                            ),
                            AppTextField(
                              controller: _purchasePriceController,
                              label: 'Purchase price',
                              hint: '0.00',
                              prefixIcon: Icons.payments_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              onChanged: (_) => setState(() => _error = null),
                              validator: (v) =>
                                  StockEntryValidation.purchasePrice(
                                    _parsePositive(v),
                                  ),
                            ),
                            AppTextField(
                              controller: _sellingPriceController,
                              label: 'Selling price',
                              hint: '0.00',
                              prefixIcon: Icons.sell_outlined,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'),
                                ),
                              ],
                              validator: (v) {
                                final sell = _parsePositive(v);
                                final purchase = _parsePurchasePrice();
                                if (purchase == null) {
                                  return StockEntryValidation.sellingPrice(
                                    sell,
                                    0,
                                  );
                                }
                                return StockEntryValidation.sellingPrice(
                                  sell,
                                  purchase,
                                );
                              },
                            ),
                            _dateField(
                              label: 'MFG date (optional)',
                              value: _formatDate(_mfgDate),
                              onPick: () =>
                                  _pickDate(isMfg: true, initial: _mfgDate),
                              onClear: _mfgDate == null
                                  ? null
                                  : () => setState(() => _mfgDate = null),
                            ),
                            _dateField(
                              label: _requiresExpiry
                                  ? 'Expiry date'
                                  : 'Expiry date (optional)',
                              value: _formatDate(_expiryDate),
                              required: _requiresExpiry,
                              onPick: () => _pickDate(
                                isMfg: false,
                                initial: _expiryDate,
                              ),
                              onClear: _requiresExpiry
                                  ? null
                                  : () => setState(() => _expiryDate = null),
                            ),
                          ],
                        ),
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
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 400;
                            final cancel = AppButton(
                              label: 'Cancel',
                              isOutlined: true,
                              onPressed: _loading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            );
                            final submit = AppButton(
                              label: 'Add stock',
                              isLoading: _loading,
                              onPressed:
                                  _loading || !canSubmit ? null : _submit,
                            );

                            if (stacked) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  submit,
                                  const SizedBox(height: 10),
                                  cancel,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: cancel),
                                const SizedBox(width: 12),
                                Expanded(child: submit),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
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
