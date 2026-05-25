import 'package:flutter/material.dart';
import 'package:web_end/models/customer_model.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

class CustomerDetailDialog extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailDialog({super.key, required this.customer});

  static Future<void> show(BuildContext context, CustomerModel customer) {
    return showDialog<void>(
      context: context,
      builder: (_) => CustomerDetailDialog(customer: customer),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.label(context)?.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: AppTheme.body(context),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime? date) {
    if (date == null) return '—';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.name,
                      style: AppTheme.title(context)?.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.deep),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Customer details', style: AppTheme.subtitle(context)),
              const SizedBox(height: 16),
              _row(context, 'Phone', customer.phone ?? ''),
              _row(context, 'Email', customer.email ?? ''),
              _row(context, 'Address', customer.address ?? ''),
              _row(context, 'Walk-in', customer.isWalkIn ? 'Yes' : 'No'),
              _row(context, 'Created', _date(customer.createdAt)),
            ],
          ),
        ),
      ),
    );
  }
}

