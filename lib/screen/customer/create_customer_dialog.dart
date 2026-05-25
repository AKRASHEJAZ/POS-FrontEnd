import 'package:flutter/material.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/services/customer/customer_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class CreateCustomerDialog extends StatefulWidget {
  const CreateCustomerDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateCustomerDialog(),
    );
  }

  @override
  State<CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<CreateCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = CustomerService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _walkIn = false;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final result = await _service.addCustomer(
      name: _nameController.text,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text,
      address:
          _addressController.text.trim().isEmpty ? null : _addressController.text,
      isWalkIn: _walkIn,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    setState(() {
      _submitting = false;
      _error = result.message;
    });
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
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Add customer',
                          style: AppTheme.title(context)?.copyWith(fontSize: 22),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _submitting ? null : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, color: AppColors.deep),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a new customer record',
                    style: AppTheme.subtitle(context),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return UserFormGrid(
                        maxWidth: constraints.maxWidth,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'Name',
                            hint: 'Customer name',
                            prefixIcon: Icons.person_outline,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          AppTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            hint: 'Optional',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Optional',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          AppTextField(
                            controller: _addressController,
                            label: 'Address',
                            hint: 'Optional',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _walkIn,
                    onChanged: _submitting ? null : (v) => setState(() => _walkIn = v == true),
                    contentPadding: EdgeInsets.zero,
                    title: Text('Walk-in customer', style: AppTheme.body(context)),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.mid,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: AppTheme.apply(
                          TextStyle(color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 400;
                      final cancel = AppButton(
                        label: 'Cancel',
                        isOutlined: true,
                        onPressed:
                            _submitting ? null : () => Navigator.of(context).pop(false),
                      );
                      final create = AppButton(
                        label: 'Add customer',
                        isLoading: _submitting,
                        onPressed: _submit,
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [create, const SizedBox(height: 10), cancel],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cancel),
                          const SizedBox(width: 12),
                          Expanded(child: create),
                        ],
                      );
                    },
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

