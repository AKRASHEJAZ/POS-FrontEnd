import 'package:flutter/material.dart';
import 'package:web_end/services/product/catalog_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class CatalogDeleteDialog extends StatefulWidget {
  final String itemLabel;
  final Future<CatalogMutationResult> Function() onDelete;

  const CatalogDeleteDialog({
    super.key,
    required this.itemLabel,
    required this.onDelete,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String itemLabel,
    required Future<CatalogMutationResult> Function() onDelete,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => CatalogDeleteDialog(
        itemLabel: itemLabel,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<CatalogDeleteDialog> createState() => _CatalogDeleteDialogState();
}

class _CatalogDeleteDialogState extends State<CatalogDeleteDialog> {
  bool _isDeleting = false;

  Future<void> _confirm() async {
    setState(() => _isDeleting = true);
    final result = await widget.onDelete();
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
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
      title: Text('Delete?', style: AppTheme.title(context)),
      content: Text(
        'Delete "${widget.itemLabel}"? This cannot be undone.',
        style: AppTheme.body(context),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        IconButton(
          onPressed: _isDeleting ? null : _confirm,
          tooltip: 'Delete',
          icon: _isDeleting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.delete_outline, color: Colors.red.shade700),
        ),
      ],
    );
  }
}
