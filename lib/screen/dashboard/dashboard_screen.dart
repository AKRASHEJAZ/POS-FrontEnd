import 'package:flutter/material.dart';
import 'package:web_end/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Dashboard', style: AppTheme.body(context)),
    );
  }
}
