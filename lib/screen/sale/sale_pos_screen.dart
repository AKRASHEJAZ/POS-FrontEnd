import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_end/constants/app_pagination.dart';
import 'package:web_end/models/customer_filters.dart';
import 'package:web_end/models/customer_model.dart';
import 'package:web_end/models/inventory_batch_model.dart';
import 'package:web_end/models/sale_models.dart';
import 'package:web_end/models/stock_filters.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/screen/customer/create_customer_dialog.dart';
import 'package:web_end/services/customer/customer_service.dart';
import 'package:web_end/services/sale/sale_service.dart';
import 'package:web_end/services/stock/stock_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_text_field.dart';
import 'package:web_end/widgets/product/product_search_picker.dart';

class SalePosScreen extends StatefulWidget {
  const SalePosScreen({super.key});

  @override
  State<SalePosScreen> createState() => _SalePosScreenState();
}

class _CartItem {
  final InventoryBatchModel batch;
  double quantity;

  _CartItem({required this.batch, required this.quantity});

  double get lineTotal => batch.sellingPrice * quantity;
}

class _SalePosScreenState extends State<SalePosScreen> {
  final _customerService = CustomerService();
  final _stockService = StockService();
  final _saleService = SaleService();

  CustomerModel? _customer;
  bool _loadingCustomer = true;

  final List<_CartItem> _cart = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadWalkInCustomer();
  }

  Future<void> _loadWalkInCustomer() async {
    setState(() => _loadingCustomer = true);
    // Try to locate the seeded walk-in customer quickly.
    final result = await _customerService.getCustomers(
      filters: const CustomerFilters(
        name: 'walk',
        page: 1,
        pageSize: kPickerPageSize,
      ),
    );

    if (!mounted) return;

    CustomerModel? walkIn;
    if (result.isSuccess) {
      try {
        walkIn = result.data.items.firstWhere((c) => c.isWalkIn);
      } catch (_) {
        walkIn = null;
      }
    }

    setState(() {
      _customer = walkIn;
      _loadingCustomer = false;
    });
  }

  Future<void> _selectCustomer() async {
    final picked = await _CustomerPickerDialog.show(
      context,
      service: _customerService,
      initialQuery: _customer?.name,
    );
    if (!mounted || picked == null) return;
    setState(() => _customer = picked);
  }

  Future<void> _createCustomer() async {
    final ok = await CreateCustomerDialog.show(context);
    if (ok == true) {
      await _loadWalkInCustomer();
    }
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.lineTotal);

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _removeItem(_CartItem item) {
    setState(() => _cart.remove(item));
  }

  void _updateQty(_CartItem item, double qty) {
    if (qty <= 0) return;
    final available = item.batch.availableStock;
    if (qty > available) {
      setState(() => item.quantity = available);
      _showMessage(
        'Only ${_formatQuantity(available)} available in ${item.batch.batchCode ?? 'this batch'}.',
      );
      return;
    }
    setState(() => item.quantity = qty);
  }

  String? _cartValidationMessage() {
    for (final item in _cart) {
      if (item.quantity <= 0) {
        return 'Quantity must be greater than zero.';
      }

      final available = item.batch.availableStock;
      if (available <= 0) {
        return '${item.batch.batchCode ?? 'Selected batch'} is out of stock.';
      }

      if (item.quantity > available) {
        return 'Only ${_formatQuantity(available)} available in ${item.batch.batchCode ?? 'selected batch'}.';
      }
    }
    return null;
  }

  Future<void> _addProduct(ProductModel? product) async {
    if (product == null) return;

    final batch = await _BatchPickerDialog.show(
      context,
      stockService: _stockService,
      product: product,
    );

    if (!mounted || batch == null) return;

    if (!batch.hasAvailableStock) {
      _showMessage('${batch.batchCode ?? 'Selected batch'} is out of stock.');
      return;
    }

    final existing = _cart.where((i) => i.batch.id == batch.id).toList();
    if (existing.isNotEmpty) {
      final item = existing.first;
      final nextQty = item.quantity + 1;
      if (nextQty > item.batch.availableStock) {
        _showMessage(
          'Only ${_formatQuantity(item.batch.availableStock)} available in ${item.batch.batchCode ?? 'this batch'}.',
        );
        return;
      }
      setState(() => item.quantity = nextQty);
      return;
    }

    setState(() {
      _cart.add(_CartItem(batch: batch, quantity: 1));
    });
  }

  Future<void> _submitSale() async {
    if (_submitting) return;
    if (_customer?.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a customer first.')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to the sale.')),
      );
      return;
    }

    final validationMessage = _cartValidationMessage();
    if (validationMessage != null) {
      _showMessage(validationMessage);
      return;
    }

    setState(() => _submitting = true);

    final dto = AddSaleDto(
      customerId: _customer!.id!,
      inventoryActions: _cart
          .map(
            (i) => AddInventoryActionDto(
              inventoryBatchId: i.batch.id,
              quantity: i.quantity,
            ),
          )
          .toList(),
    );

    final result = await _saleService.createSale(dto);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {
        _submitting = false;
        _cart.clear();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    setState(() => _submitting = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Widget _cartPanel(BuildContext context, bool compact) {
    final header = Row(
      children: [
        Expanded(
          child: Text(
            'Sale',
            style: AppTheme.title(context)?.copyWith(fontSize: 20),
          ),
        ),
        FilledButton.icon(
          onPressed: _submitting ? null : _submitSale,
          style: FilledButton.styleFrom(backgroundColor: AppColors.mid),
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.light,
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Pay'),
        ),
      ],
    );

    final customerRow = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.soft.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.soft.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: AppColors.mid),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _loadingCustomer
                  ? 'Loading customer...'
                  : (_customer?.name.isNotEmpty == true
                        ? _customer!.name
                        : 'Select customer'),
              style: AppTheme.body(
                context,
              )?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: _loadingCustomer || _submitting ? null : _selectCustomer,
            child: const Text('Change'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Add customer',
            onPressed: _submitting ? null : _createCustomer,
            icon: const Icon(Icons.person_add_alt_1, color: AppColors.mid),
          ),
        ],
      ),
    );

    final cartList = _cart.isEmpty
        ? Center(child: Text('No items yet', style: AppTheme.subtitle(context)))
        : ListView.separated(
            itemCount: _cart.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.soft.withValues(alpha: 0.25),
            ),
            itemBuilder: (context, index) {
              final item = _cart[index];
              final name = item.batch.productName ?? 'Product';
              final code = item.batch.batchCode ?? 'Batch ${item.batch.id}';
              return ListTile(
                dense: true,
                title: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.body(
                    context,
                  )?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '$code · ${item.batch.sellingPrice.toStringAsFixed(2)} · Available: ${_formatQuantity(item.batch.availableStock)}',
                  style: AppTheme.subtitle(context)?.copyWith(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QtyField(
                      value: item.quantity,
                      enabled: !_submitting,
                      onChanged: (v) => _updateQty(item, v),
                      compact: compact,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.lineTotal.toStringAsFixed(2),
                      style: AppTheme.body(
                        context,
                      )?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: _submitting ? null : () => _removeItem(item),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          );

    final totals = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.light,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.soft.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Total',
              style: AppTheme.body(
                context,
              )?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            _total.toStringAsFixed(2),
            style: AppTheme.title(context)?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.soft.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            customerRow,
            const SizedBox(height: 12),
            Expanded(child: cartList),
            const SizedBox(height: 10),
            totals,
          ],
        ),
      ),
    );
  }

  Widget _productPanel(BuildContext context, bool compact) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.soft.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add items',
              style: AppTheme.title(context)?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            ProductSearchPicker(
              label: 'Product',
              selected: null,
              onSelected: _addProduct,
              enabled: !_submitting,
              allowClear: false,
            ),
            const SizedBox(height: 12),
            Text(
              'Pick a product, then choose a stock batch to sell from.',
              style: AppTheme.subtitle(context)?.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = width < 900;

        if (compact) {
          return Column(
            children: [
              Expanded(child: _cartPanel(context, true)),
              const SizedBox(height: 12),
              _productPanel(context, true),
            ],
          );
        }

        return Row(
          children: [
            Expanded(flex: 6, child: _cartPanel(context, false)),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: _productPanel(context, false)),
          ],
        );
      },
    );
  }
}

class _QtyField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final bool compact;

  const _QtyField({
    required this.value,
    required this.onChanged,
    required this.enabled,
    required this.compact,
  });

  @override
  State<_QtyField> createState() => _QtyFieldState();
}

class _QtyFieldState extends State<_QtyField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _QtyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final parsed = double.tryParse(v.trim());
      if (parsed != null && parsed > 0) widget.onChanged(parsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.compact ? 64.0 : 80.0;
    return SizedBox(
      width: w,
      child: TextField(
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: _onChanged,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _BatchPickerDialog extends StatefulWidget {
  final StockService stockService;
  final ProductModel product;

  const _BatchPickerDialog({required this.stockService, required this.product});

  static Future<InventoryBatchModel?> show(
    BuildContext context, {
    required StockService stockService,
    required ProductModel product,
  }) {
    return showDialog<InventoryBatchModel>(
      context: context,
      builder: (_) =>
          _BatchPickerDialog(stockService: stockService, product: product),
    );
  }

  @override
  State<_BatchPickerDialog> createState() => _BatchPickerDialogState();
}

class _BatchPickerDialogState extends State<_BatchPickerDialog> {
  bool _loading = true;
  String? _error;
  List<InventoryBatchModel> _batches = [];

  String _formatQuantity(double value) {
    if (value == value.truncateToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.stockService.getBatches(
      filters: StockFilters(
        productId: widget.product.id,
        page: 1,
        pageSize: 40,
      ),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.message;
        _batches = [];
      });
      return;
    }

    setState(() {
      _loading = false;
      _batches = result.data.items;
      if (_batches.isEmpty) {
        _error = 'No stock batches found for this product.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose batch',
                      style: AppTheme.title(context)?.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.deep),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.product.name, style: AppTheme.subtitle(context)),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.mid),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, style: AppTheme.body(context)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _batches.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: AppColors.soft.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (context, index) {
                      final b = _batches[index];
                      final code = b.batchCode ?? 'Batch ${b.id}';
                      final available = b.availableStock;
                      final hasStock = b.hasAvailableStock;
                      return ListTile(
                        enabled: hasStock,
                        title: Text(
                          code,
                          style: AppTheme.body(context)?.copyWith(
                            color: hasStock ? null : Colors.grey.shade600,
                          ),
                        ),
                        subtitle: Text(
                          'Sell: ${b.sellingPrice.toStringAsFixed(2)} · Available: ${_formatQuantity(available)} · Purchased: ${_formatQuantity(b.purchaseAmount)}',
                          style: AppTheme.subtitle(
                            context,
                          )?.copyWith(fontSize: 12),
                        ),
                        trailing: hasStock
                            ? const Icon(Icons.chevron_right)
                            : Text(
                                'Out',
                                style: AppTheme.subtitle(context)?.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                        onTap: hasStock
                            ? () => Navigator.of(context).pop(b)
                            : null,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 10),
              if (!_loading)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerPickerDialog extends StatefulWidget {
  final CustomerService service;
  final String? initialQuery;

  const _CustomerPickerDialog({required this.service, this.initialQuery});

  static Future<CustomerModel?> show(
    BuildContext context, {
    required CustomerService service,
    String? initialQuery,
  }) {
    return showDialog<CustomerModel>(
      context: context,
      builder: (_) =>
          _CustomerPickerDialog(service: service, initialQuery: initialQuery),
    );
  }

  @override
  State<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<CustomerModel> _items = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialQuery ?? '';
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.service.getCustomers(
      filters: CustomerFilters(
        name: _nameController.text.trim().isEmpty ? null : _nameController.text,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text,
        page: 1,
        pageSize: 30,
      ),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _error = result.message;
        _items = [];
      });
      return;
    }

    setState(() {
      _loading = false;
      _items = result.data.items;
      if (_items.isEmpty) _error = 'No customers found.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select customer',
                      style: AppTheme.title(context)?.copyWith(fontSize: 18),
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
                  final wide = constraints.maxWidth >= 520;
                  final nameField = AppTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Search name',
                    prefixIcon: Icons.person_outline,
                    onSubmitted: (_) => _load(),
                  );
                  final emailField = AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Search email',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _load(),
                  );

                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: nameField),
                        const SizedBox(width: 12),
                        Expanded(child: emailField),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      nameField,
                      const SizedBox(height: 12),
                      emailField,
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _load,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.mid),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.mid),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, style: AppTheme.body(context)),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: AppColors.soft.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (context, index) {
                      final c = _items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.soft.withValues(
                            alpha: 0.25,
                          ),
                          child: Text(
                            (c.name.isNotEmpty ? c.name[0] : '?').toUpperCase(),
                            style: const TextStyle(color: AppColors.deep),
                          ),
                        ),
                        title: Text(c.name, style: AppTheme.body(context)),
                        subtitle: Text(
                          [
                            if (c.isWalkIn) 'Walk-in',
                            if (c.email != null && c.email!.isNotEmpty) c.email,
                            if (c.phone != null && c.phone!.isNotEmpty) c.phone,
                          ].whereType<String>().join(' · '),
                          style: AppTheme.subtitle(
                            context,
                          )?.copyWith(fontSize: 12),
                        ),
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
