import 'package:flutter/material.dart';
import 'package:web_end/constants/user_roles.dart';
import 'package:web_end/services/user/user_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_dropdown.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateUserDialog(),
    );
  }

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = UserRoles.cashier;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await _userService.createUser(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      roleId: UserRoles.idFor(_selectedRole),
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = false;
      _errorMessage = result.message;
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
                          'Create user',
                          style: AppTheme.title(context)?.copyWith(fontSize: 22),
                        ),
                      ),
                      IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, color: AppColors.deep),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a new team member to Smart POS',
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
                            label: 'Full name',
                            hint: 'Enter name',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Name is required' : null,
                          ),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'user@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Min. 6 characters',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          AppTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm password',
                            hint: 'Re-enter password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm password';
                              }
                              if (v != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          AppDropdown<String>(
                            label: 'Role',
                            value: _selectedRole,
                            items: UserRoles.options
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _selectedRole = value);
                                    }
                                  },
                          ),
                        ],
                      );
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
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
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                      );
                      final create = AppButton(
                        label: 'Create user',
                        isLoading: _isSubmitting,
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
