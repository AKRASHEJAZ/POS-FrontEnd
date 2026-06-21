import 'package:flutter/material.dart';
import 'package:web_end/screen/reports/expired_products_report_screen.dart';

/// Reports screen — currently only hosts Expired Products report.
/// If more reports are added later, re-introduce the sub-nav from here.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExpiredProductsReportScreen();
  }
}
