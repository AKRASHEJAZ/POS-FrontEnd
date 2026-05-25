import 'package:flutter/material.dart';
import 'package:web_end/models/category_model.dart';
import 'package:web_end/models/product_model.dart';
import 'package:web_end/models/unit_model.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_dropdown.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class ProductFormDialog extends StatefulWidget {
  final ProductModel? product;
  final List<CategoryModel> categories;
  final List<UnitModel> units;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.categories,
    required this.units,
  });

  static Future<bool?> show(
    BuildContext context, {
    ProductModel? product,
    required List<CategoryModel> categories,
    required List<UnitModel> units,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(
        product: product,
        categories: categories,
        units: units,
      ),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = CatalogService();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;

  late int? _categoryId;
  late int? _unitId;
  late bool _isActive;
  late bool _isSellable;
  late bool _isPurchasable;
  late bool _doesExpire;

  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _codeController = TextEditingController(text: p?.internalCode ?? '');
    _categoryId = p?.categoryId ??
        (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _unitId = p?.unitId ?? (widget.units.isNotEmpty ? widget.units.first.id : null);
    _isActive = p?.isActive ?? true;
    _isSellable = p?.isSellable ?? true;
    _isPurchasable = p?.isPurchasable ?? true;
    _doesExpire = p?.doesExpire ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null || _unitId == null) {
      setState(() => _error = 'Select category and unit first');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final result = _isEdit
          ? await _service.updateProduct(
              id: widget.product!.id,
              name: _nameController.text,
              categoryId: _categoryId!,
              unitId: _unitId!,
              internalCode: _codeController.text,
              isActive: _isActive,
              isSellable: _isSellable,
              isPurchasable: _isPurchasable,
              doesExpire: _doesExpire,
            )
          : await _service.addProduct(
              name: _nameController.text,
              categoryId: _categoryId!,
              unitId: _unitId!,
              internalCode: _codeController.text,
              isActive: _isActive,
              isSellable: _isSellable,
              isPurchasable: _isPurchasable,
              doesExpire: _doesExpire,
            );

      if (!mounted) return;

      if (result.isSuccess) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(true);
        messenger.showSnackBar(
          SnackBar(content: Text(result.message)),
        );
        return;
      }

      setState(() {
        _loading = false;
        _error = result.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: _loading ? null : onChanged,
      selectedColor: AppColors.soft.withValues(alpha: 0.4),
      checkmarkColor: AppColors.deep,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty || widget.units.isEmpty) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Create at least one category and one unit before adding products.',
            style: AppTheme.body(context),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.light,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isEdit ? 'Update product' : 'Create product',
                    style: AppTheme.title(context)?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, c) => UserFormGrid(
                      maxWidth: c.maxWidth,
                      children: [
                        AppTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Product name',
                          prefixIcon: Icons.inventory_2_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        AppTextField(
                          controller: _codeController,
                          label: 'Internal code',
                          hint: 'SKU-001',
                          prefixIcon: Icons.qr_code,
                        ),
                        AppDropdown<int>(
                          label: 'Category',
                          value: _categoryId,
                          items: widget.categories
                              .map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                        AppDropdown<int>(
                          label: 'Unit',
                          value: _unitId,
                          items: widget.units
                              .map((u) => DropdownMenuItem(
                                    value: u.id,
                                    child: Text('${u.name} (${u.symbol})'),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _unitId = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _toggle('Active', _isActive, (v) => setState(() => _isActive = v)),
                      _toggle('Sellable', _isSellable, (v) => setState(() => _isSellable = v)),
                      _toggle('Purchasable', _isPurchasable,
                          (v) => setState(() => _isPurchasable = v)),
                      _toggle('Expires', _doesExpire, (v) => setState(() => _doesExpire = v)),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Cancel',
                          isOutlined: true,
                          onPressed: _loading ? null : () => Navigator.pop(context, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: _isEdit ? 'Save' : 'Create',
                          isLoading: _loading,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
