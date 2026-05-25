import 'package:flutter/material.dart';
import 'package:web_end/models/unit_model.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class UnitFormDialog extends StatefulWidget {
  final UnitModel? unit;

  const UnitFormDialog({super.key, this.unit});

  static Future<bool?> show(BuildContext context, {UnitModel? unit}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UnitFormDialog(unit: unit),
    );
  }

  @override
  State<UnitFormDialog> createState() => _UnitFormDialogState();
}

class _UnitFormDialogState extends State<UnitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = CatalogService();
  late final TextEditingController _nameController;
  late final TextEditingController _symbolController;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.unit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit?.name ?? '');
    _symbolController = TextEditingController(text: widget.unit?.symbol ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = _isEdit
        ? await _service.updateUnit(
            widget.unit!.id, _nameController.text, _symbolController.text)
        : await _service.addUnit(_nameController.text, _symbolController.text);

    if (!mounted) return;
    if (result.isSuccess) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop(true);
      messenger.showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }
    setState(() { _loading = false; _error = result.message; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
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
                    _isEdit ? 'Update unit' : 'Create unit',
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
                          hint: 'Kilogram',
                          prefixIcon: Icons.straighten_outlined,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Name is required'
                              : null,
                        ),
                        AppTextField(
                          controller: _symbolController,
                          label: 'Symbol',
                          hint: 'kg',
                          prefixIcon: Icons.tag,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Symbol is required'
                              : null,
                        ),
                      ],
                    ),
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
