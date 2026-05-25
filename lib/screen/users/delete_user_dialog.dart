import 'package:flutter/material.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/services/user/user_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class DeleteUserDialog extends StatefulWidget {
  final UserModel user;

  const DeleteUserDialog({super.key, required this.user});

  static Future<bool?> show(BuildContext context, UserModel user) {
    return showDialog<bool>(
      context: context,
      builder: (_) => DeleteUserDialog(user: user),
    );
  }

  @override
  State<DeleteUserDialog> createState() => _DeleteUserDialogState();
}

class _DeleteUserDialogState extends State<DeleteUserDialog> {
  final _userService = UserService();
  bool _isDeleting = false;

  Future<void> _confirmDelete() async {
    if (widget.user.id == null) return;

    setState(() => _isDeleting = true);

    final result = await _userService.deleteUser(widget.user.id!);

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

    setState(() => _isDeleting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete user?', style: AppTheme.title(context)),
      content: Text(
        'Are you sure you want to delete "${widget.user.name}"? This cannot be undone.',
        style: AppTheme.body(context),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isDeleting ? null : _confirmDelete,
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          icon: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.light,
                  ),
                )
              : const Icon(Icons.delete_outline, size: 20),
          label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
        ),
      ],
    );
  }
}
