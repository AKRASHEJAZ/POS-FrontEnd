import 'package:flutter/material.dart';
import 'package:web_end/constants/user_roles.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/screen/users/user_form_grid.dart';
import 'package:web_end/services/user/user_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/app_button.dart';
import 'package:web_end/widgets/common/app_dropdown.dart';
import 'package:web_end/widgets/common/app_text_field.dart';

class UpdateUserDialog extends StatefulWidget {
  final UserModel user;

  const UpdateUserDialog({super.key, required this.user});

  static Future<bool?> show(BuildContext context, UserModel user) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateUserDialog(user: user),
    );
  }

  @override
  State<UpdateUserDialog> createState() => _UpdateUserDialogState();
}

class _UpdateUserDialogState extends State<UpdateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  late String _selectedRole;
  late String _selectedStatus;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const _statusActive = 'Active';
  static const _statusInactive = 'Inactive';
  static const _statusOptions = [_statusActive, _statusInactive];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role ?? UserRoles.cashier;
    if (!UserRoles.options.contains(_selectedRole)) {
      _selectedRole = UserRoles.cashier;
    }
    _selectedStatus = widget.user.isActive ? _statusActive : _statusInactive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.user.id == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await _userService.updateUser(
      id: widget.user.id!,
      name: _nameController.text,
      email: _emailController.text,
      roleId: UserRoles.idFor(_selectedRole),
      isActive: _selectedStatus == _statusActive,
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
                          'Update user',
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
                    'Edit details for ${widget.user.name}',
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
                          AppDropdown<String>(
                            label: 'Role',
                            value: _selectedRole,
                            items: UserRoles.options
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _selectedRole = value);
                                    }
                                  },
                          ),
                          AppDropdown<String>(
                            label: 'Status',
                            value: _selectedStatus,
                            items: _statusOptions
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() => _selectedStatus = value);
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
                      final save = AppButton(
                        label: 'Save changes',
                        isLoading: _isSubmitting,
                        onPressed: _submit,
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [save, const SizedBox(height: 10), cancel],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cancel),
                          const SizedBox(width: 12),
                          Expanded(child: save),
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
